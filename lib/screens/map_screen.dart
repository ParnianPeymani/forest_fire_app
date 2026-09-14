import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/fire_event.dart';
import '../services/fire_data_provider.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Centered roughly on Bulgaria.
  static const LatLng _bulgariaCenter = LatLng(42.7339, 25.4858);

  final MapController _mapController = MapController();
  FireEvent? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    return Consumer<FireDataProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('نقشه‌ی آتش‌سوزی — بلغارستان'),
            actions: [
              IconButton(
                tooltip: 'به‌روزرسانی',
                icon: provider.status == LoadStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.status == LoadStatus.loading
                    ? null
                    : () => provider.load(),
              ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _bulgariaCenter,
                  initialZoom: 7,
                  minZoom: 5,
                  maxZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.riskmap.app',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final event in provider.events)
                        Marker(
                          point: LatLng(event.latitude, event.longitude),
                          width: 28,
                          height: 28,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedEvent = event),
                            child: _FireDot(event: event),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (provider.status == LoadStatus.error)
                _ErrorBanner(message: provider.errorMessage ?? 'خطای ناشناخته')
              else
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _StatusPill(provider: provider),
                ),
              if (_selectedEvent != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _EventDetailsCard(
                    event: _selectedEvent!,
                    onClose: () => setState(() => _selectedEvent = null),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FireDot extends StatelessWidget {
  const _FireDot({required this.event});
  final FireEvent event;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forRisk(event.riskLevel);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.85),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(Icons.local_fire_department,
          size: 16, color: Colors.white),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.provider});
  final FireDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final updated = provider.lastUpdated;
    final text = provider.status == LoadStatus.loading
        ? 'در حال دریافت داده‌های ماهواره‌ای...'
        : updated != null
            ? '${provider.totalCount} نقطه‌ی داغ · به‌روزرسانی ${DateFormat('HH:mm').format(updated.toLocal())}'
            : '${provider.totalCount} نقطه‌ی داغ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.forestDark.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emberOrange.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.emberRed.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'دریافت داده ناموفق بود — نمایش داده‌ی ذخیره‌شده (در صورت وجود).\n$message',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDetailsCard extends StatelessWidget {
  const _EventDetailsCard({required this.event, required this.onClose});
  final FireEvent event;
  final VoidCallback onClose;

  String _riskLabel(FireRiskLevel level) {
    switch (level) {
      case FireRiskLevel.low:
        return 'کم';
      case FireRiskLevel.moderate:
        return 'متوسط';
      case FireRiskLevel.high:
        return 'بالا';
      case FireRiskLevel.critical:
        return 'بحرانی';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forRisk(event.riskLevel);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('سطح ریسک: ${_riskLabel(event.riskLevel)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'شدت آتش (FRP): ${event.frp.toStringAsFixed(1)} MW\n'
              'اطمینان تشخیص: ${event.confidencePercent}%\n'
              'ماهواره: ${event.satellite}\n'
              'زمان تشخیص: ${DateFormat('yyyy-MM-dd HH:mm').format(event.detectedAt.toLocal())}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
