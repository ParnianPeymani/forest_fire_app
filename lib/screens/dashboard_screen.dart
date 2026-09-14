import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/fire_event.dart';
import '../services/fire_data_provider.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FireDataProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('داشبورد ریسک')),
          body: provider.status == LoadStatus.loading && provider.totalCount == 0
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.load(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryRow(provider: provider),
                      const SizedBox(height: 20),
                      const _SectionTitle('روند تشخیص در روزهای اخیر'),
                      const SizedBox(height: 12),
                      _TrendChart(provider: provider),
                      const SizedBox(height: 24),
                      const _SectionTitle('توزیع سطح ریسک'),
                      const SizedBox(height: 12),
                      _RiskBreakdown(provider: provider),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.provider});
  final FireDataProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'مجموع نقاط داغ',
            value: '${provider.totalCount}',
            icon: Icons.local_fire_department,
            color: AppColors.emberOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'میانگین شدت (FRP)',
            value: provider.averageFrp.toStringAsFixed(1),
            icon: Icons.speed,
            color: AppColors.amber,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.provider});
  final FireDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final byDay = provider.countsByDay;

    if (byDay.isEmpty) {
      return const _EmptyChartPlaceholder();
    }

    final days = byDay.keys.toList();
    final maxY = byDay.values.fold<int>(0, (m, v) => v > m ? v : m).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY <= 0 ? 1 : maxY * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('MM/dd').format(days[index]),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < days.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: byDay[days[i]]!.toDouble(),
                        color: AppColors.emberOrange,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RiskBreakdown extends StatelessWidget {
  const _RiskBreakdown({required this.provider});
  final FireDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final levels = FireRiskLevel.values;
    final counts = {for (final l in levels) l: provider.countForRisk(l)};
    final total = provider.totalCount == 0 ? 1 : provider.totalCount;

    if (provider.totalCount == 0) {
      return const _EmptyChartPlaceholder();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 34,
                  sections: [
                    for (final l in levels)
                      if (counts[l]! > 0)
                        PieChartSectionData(
                          value: counts[l]!.toDouble(),
                          color: AppColors.forRisk(l),
                          title: '${((counts[l]! / total) * 100).round()}%',
                          radius: 46,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final l in levels) _LegendDot(level: l, count: counts[l]!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.level, required this.count});
  final FireRiskLevel level;
  final int count;

  String _label(FireRiskLevel level) {
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: AppColors.forRisk(level), shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('${_label(level)} ($count)',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'داده‌ای برای نمایش نیست',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
