import 'package:flutter/foundation.dart';
import '../models/fire_event.dart';
import 'fire_service.dart';

enum LoadStatus { initial, loading, loaded, error }

/// Holds the current set of fire events + loading state, shared between
/// the map screen and the dashboard screen so they always show the same
/// data without re-fetching twice.
class FireDataProvider extends ChangeNotifier {
  FireDataProvider(this._service);

  final FireService _service;

  List<FireEvent> _events = [];
  LoadStatus _status = LoadStatus.initial;
  String? _errorMessage;
  DateTime? _lastUpdated;

  List<FireEvent> get events => _events;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> load({int dayRange = 3}) async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final events = await _service.fetchRecentFires(dayRange: dayRange);
      _events = events;
      _lastUpdated = await _service.lastUpdated();
      _status = LoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  // ----- Derived stats used by the dashboard -----

  int get totalCount => _events.length;

  int countForRisk(FireRiskLevel level) =>
      _events.where((e) => e.riskLevel == level).length;

  /// Fire counts bucketed by calendar day (most recent last), for the
  /// trend chart. Only looks at the days actually present in the data.
  Map<DateTime, int> get countsByDay {
    final map = <DateTime, int>{};
    for (final e in _events) {
      final day =
          DateTime.utc(e.detectedAt.year, e.detectedAt.month, e.detectedAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    final sortedEntries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final entry in sortedEntries) entry.key: entry.value};
  }

  /// Average Fire Radiative Power across all current detections —
  /// a rough proxy for "how intense is this wave of fires overall".
  double get averageFrp {
    if (_events.isEmpty) return 0;
    final sum = _events.fold<double>(0, (acc, e) => acc + e.frp);
    return sum / _events.length;
  }
}
