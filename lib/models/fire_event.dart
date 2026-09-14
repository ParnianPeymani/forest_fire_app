/// Represents a single fire/hotspot detection point, as reported by
/// NASA FIRMS (Fire Information for Resource Management System).
///
/// FIRMS gives us satellite-detected thermal anomalies. Not every
/// detection is a dangerous wildfire (some are agricultural burns or
/// industrial heat sources), so we keep the raw `confidence` and
/// `frp` (Fire Radiative Power) values and use them to classify risk.
class FireEvent {
  final double latitude;
  final double longitude;
  final DateTime detectedAt;

  /// Fire Radiative Power in megawatts — roughly, how intense the fire is.
  final double frp;

  /// Detection confidence. FIRMS reports this either as a word
  /// (low/nominal/high) for VIIRS or a 0-100 number for MODIS.
  /// We normalize both into [confidencePercent].
  final int confidencePercent;

  /// Which satellite/sensor reported this detection (e.g. "VIIRS_SNPP_NRT").
  final String satellite;

  /// Day or night detection.
  final bool isDaytime;

  const FireEvent({
    required this.latitude,
    required this.longitude,
    required this.detectedAt,
    required this.frp,
    required this.confidencePercent,
    required this.satellite,
    required this.isDaytime,
  });

  /// Risk classification used for marker color + dashboard stats.
  /// This is a simple heuristic combining intensity (FRP) and confidence —
  /// tune the thresholds as you gather more real-world data.
  FireRiskLevel get riskLevel {
    if (confidencePercent < 40) return FireRiskLevel.low;
    if (frp >= 50 || confidencePercent >= 90) return FireRiskLevel.critical;
    if (frp >= 15 || confidencePercent >= 70) return FireRiskLevel.high;
    return FireRiskLevel.moderate;
  }

  /// Parses one row of a NASA FIRMS CSV response.
  /// Expected header order (VIIRS NRT product):
  /// latitude,longitude,bright_ti4,scan,track,acq_date,acq_time,
  /// satellite,instrument,confidence,version,bright_ti5,frp,daynight
  factory FireEvent.fromCsvRow(Map<String, String> row) {
    final rawConfidence = row['confidence']?.trim() ?? '0';
    int confidence;
    // MODIS gives a numeric 0-100 confidence; VIIRS gives l/n/h.
    switch (rawConfidence.toLowerCase()) {
      case 'l':
        confidence = 30;
        break;
      case 'n':
        confidence = 65;
        break;
      case 'h':
        confidence = 90;
        break;
      default:
        confidence = int.tryParse(rawConfidence) ?? 50;
    }

    final acqDate = row['acq_date'] ?? '2000-01-01';
    final acqTimeRaw = (row['acq_time'] ?? '0000').padLeft(4, '0');
    final hour = int.tryParse(acqTimeRaw.substring(0, 2)) ?? 0;
    final minute = int.tryParse(acqTimeRaw.substring(2, 4)) ?? 0;
    final dateParts = acqDate.split('-').map(int.parse).toList();

    return FireEvent(
      latitude: double.tryParse(row['latitude'] ?? '') ?? 0,
      longitude: double.tryParse(row['longitude'] ?? '') ?? 0,
      detectedAt: DateTime.utc(
          dateParts[0], dateParts[1], dateParts[2], hour, minute),
      frp: double.tryParse(row['frp'] ?? '') ?? 0,
      confidencePercent: confidence,
      satellite: row['satellite'] ?? row['instrument'] ?? 'unknown',
      isDaytime: (row['daynight'] ?? 'D').toUpperCase() == 'D',
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'detectedAt': detectedAt.toIso8601String(),
        'frp': frp,
        'confidencePercent': confidencePercent,
        'satellite': satellite,
        'isDaytime': isDaytime,
      };

  factory FireEvent.fromJson(Map<String, dynamic> json) => FireEvent(
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        frp: json['frp'] as double,
        confidencePercent: json['confidencePercent'] as int,
        satellite: json['satellite'] as String,
        isDaytime: json['isDaytime'] as bool,
      );
}

enum FireRiskLevel { low, moderate, high, critical }
