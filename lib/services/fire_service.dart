import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fire_event.dart';

/// Fetches active fire / thermal-anomaly data for Bulgaria from
/// NASA FIRMS (https://firms.modaps.eosdis.nasa.gov).
///
/// FIRMS requires a free MAP_KEY. Get one at:
/// https://firms.modaps.eosdis.nasa.gov/api/area/
/// Then pass it in, e.g. via --dart-define=FIRMS_MAP_KEY=xxxxxxxx
/// (see README for the exact run command).
class FireService {
  FireService({required this.mapKey});

  final String mapKey;

  static const _cacheKey = 'cached_fire_events_v1';
  static const _cacheTimeKey = 'cached_fire_events_time_v1';

  /// Bulgaria bounding box: west,south,east,north
  static const String _bulgariaBBox = '22.0,41.1,28.7,44.3';

  /// VIIRS NOAA-20 is a good balance of resolution + coverage; you can
  /// switch to 'VIIRS_SNPP_NRT' or 'MODIS_NRT' if you want a different source.
  static const String _source = 'VIIRS_NOAA20_NRT';

  Uri _buildUri({int dayRange = 3}) {
    return Uri.parse(
      'https://firms.modaps.eosdis.nasa.gov/api/area/csv/'
      '$mapKey/$_source/$_bulgariaBBox/$dayRange',
    );
  }

  /// Fetches the latest fire detections. Falls back to the last
  /// successfully-cached result if the network call fails (useful
  /// when the API or network is flaky), and throws only if there is
  /// neither a fresh response nor a cache to fall back on.
  Future<List<FireEvent>> fetchRecentFires({int dayRange = 3}) async {
    try {
      final response = await http
          .get(_buildUri(dayRange: dayRange))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw FireServiceException(
            'FIRMS returned HTTP ${response.statusCode}');
      }

      // FIRMS sometimes returns a plain-text error message with 200 OK
      // (e.g. an invalid map key) instead of CSV — detect that here.
      if (!response.body.trim().startsWith('latitude')) {
        throw FireServiceException(
            'Unexpected FIRMS response: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
      }

      final events = _parseCsv(response.body);
      await _saveToCache(events);
      return events;
    } catch (e) {
      final cached = await _loadFromCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  List<FireEvent> _parseCsv(String csvBody) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvBody);
    if (rows.isEmpty) return [];

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final events = <FireEvent>[];

    for (final row in rows.skip(1)) {
      if (row.length != header.length) continue;
      final map = <String, String>{
        for (var i = 0; i < header.length; i++) header[i]: row[i].toString(),
      };
      events.add(FireEvent.fromCsvRow(map));
    }

    // Most recent first.
    events.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return events;
  }

  Future<void> _saveToCache(List<FireEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = events.map((e) => e.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonList));
    await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
  }

  Future<List<FireEvent>?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => FireEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// When the cached data was last refreshed successfully, or null.
  Future<DateTime?> lastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheTimeKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}

class FireServiceException implements Exception {
  FireServiceException(this.message);
  final String message;

  @override
  String toString() => 'FireServiceException: $message';
}
