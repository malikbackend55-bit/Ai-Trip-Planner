import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dashboard_provider.dart';
import '../../core/theme.dart';

class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView({super.key});

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider).refresh();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(dashboardProvider);
    final stats = provider.stats;

    return FadeTransition(
      opacity: _anim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Advanced Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              if (provider.isLoading) const CircularProgressIndicator(),
            ],
          ),
          const SizedBox(height: 24),
          _buildKpiRow(stats),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRevenueChart(stats)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildTopDestinations(stats)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildConversionFunnel(stats)),
              const SizedBox(width: 24),
              Expanded(child: _buildMonthlyComparison(stats)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildKpiCard('Conversion Rate', stats['conversionRate'] ?? '4.2%', '+0.3%', true, Icons.trending_up),
        const SizedBox(width: 16),
        _buildKpiCard('Avg. Trip Value', '\$1,250', '+\$85', true, Icons.attach_money),
        const SizedBox(width: 16),
        _buildKpiCard('Retention', '${stats['userRetention'] ?? 84}%', '+1.5%', true, Icons.replay),
        const SizedBox(width: 16),
        _buildKpiCard('Active Users', stats['totalUsers']?.toString() ?? '0', '+5.4', true, Icons.people),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String change, bool isPositive, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(change, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPositive ? AppColors.success : AppColors.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> stats) {
    final trends = stats['monthlyTrends'] as List? ?? [];
    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Growth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('New trips created recently', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
          const SizedBox(height: 24),
          Expanded(
            child: trends.isEmpty
                ? const Center(child: Text('Not enough data'))
                : BarChart(
                    BarChartData(
                      barGroups: List.generate(trends.length, (i) {
                        final count = double.tryParse(trends[i]['count']?.toString() ?? '0') ?? 0;
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(toY: count, color: AppColors.primary, width: 18, borderRadius: BorderRadius.circular(4)),
                        ]);
                      }),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textDim)))),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, m) {
                              if (v.toInt() < trends.length) {
                                return Text(trends[v.toInt()]['month'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textDim));
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDestinations(Map<String, dynamic> stats) {
    final destinations = stats['topDestinations'] as List? ?? [];
    final maxCount = destinations.isEmpty ? 1 : double.tryParse(destinations.first['count']?.toString() ?? '1') ?? 1;

    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Destinations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('By number of bookings', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
          const SizedBox(height: 20),
          ...destinations.map((d) {
            final count = double.tryParse(d['count']?.toString() ?? '0') ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(d['destination'] ?? 'Unknown', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text('${count.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: count / maxCount,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConversionFunnel(Map<String, dynamic> stats) {
    final provider = ref.read(dashboardProvider);
    final totalTrips = provider.trips.length;
    final stages = [
      ('Website Visits', '45,200', 1.0),
      ('Trip Created', totalTrips.toString(), 0.20),
      ('Booking Completed', provider.completedTripCount.toString(), 0.11),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conversion Funnel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          ...stages.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: s.$3 * 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(s.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparison(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Real-time Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildComparisonRow('Total Users', stats['totalUsers']?.toString() ?? '0', 'Growing', true),
          const SizedBox(height: 12),
          _buildComparisonRow('Revenue', '\$${stats['totalRevenue'] ?? 0}', 'Live', true),
          const SizedBox(height: 12),
          _buildComparisonRow('Retention', '${stats['userRetention'] ?? 84}%', 'Healthy', true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String current, String prev, bool improved) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(child: Text(current, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
          Expanded(child: Text(prev, style: const TextStyle(fontSize: 12, color: AppColors.textDim))),
          Icon(improved ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: improved ? AppColors.success : AppColors.error),
        ],
      ),
    );
  }
}
