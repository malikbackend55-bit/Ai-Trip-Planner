import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dashboard_provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';

class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView({super.key});

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < AppBreakpoints.mobile;
          final isNarrow = width < AppBreakpoints.tablet;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Advanced Analytics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  if (provider.isLoading)
                    const CircularProgressIndicator(),
                ],
              ),
              const SizedBox(height: 24),
              _buildKpiGrid(stats, width),
              const SizedBox(height: 24),
              if (isNarrow) ...[
                _buildRevenueChart(stats),
                const SizedBox(height: 24),
                _buildTopDestinations(stats),
                const SizedBox(height: 24),
                _buildConversionFunnel(stats),
                const SizedBox(height: 24),
                _buildMonthlyComparison(stats),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildRevenueChart(stats)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTopDestinations(stats)),
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
              if (isMobile) const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> stats, double width) {
    final cards = [
      _KpiData('Conversion Rate', stats['conversionRate'] ?? '4.2%', '+0.3%',
          true, Icons.trending_up),
      _KpiData('Avg. Trip Value', '\$1,250', '+\$85', true,
          Icons.attach_money_outlined),
      _KpiData('Retention', '${stats['userRetention'] ?? 84}%', '+1.5%', true,
          Icons.replay),
      _KpiData('Active Users', stats['totalUsers']?.toString() ?? '0', '+5.4',
          true, Icons.people_outline),
    ];

    final columns = width >= 1400
        ? 4
        : width >= AppBreakpoints.mobile
            ? 2
            : 1;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: width < AppBreakpoints.mobile ? 2.1 : 1.75,
      physics: const NeverScrollableScrollPhysics(),
      children: cards.map((card) => _KpiCard(data: card)).toList(),
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> stats) {
    final trends = stats['monthlyTrends'] as List? ?? [];

    return _Panel(
      height: 380,
      title: 'Trip Growth',
      subtitle: 'New trips created recently',
      child: trends.isEmpty
          ? const Center(child: Text('Not enough data'))
          : BarChart(
              BarChartData(
                barGroups: List.generate(trends.length, (index) {
                  final count =
                      double.tryParse(trends[index]['count']?.toString() ?? '0') ??
                          0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        color: AppColors.primary,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < trends.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              trends[value.toInt()]['month'] ?? '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textDim,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.border, strokeWidth: 1),
                ),
              ),
            ),
    );
  }

  Widget _buildTopDestinations(Map<String, dynamic> stats) {
    final destinations = stats['topDestinations'] as List? ?? [];
    final maxCount = destinations.isEmpty
        ? 1
        : double.tryParse(destinations.first['count']?.toString() ?? '1') ?? 1;

    return _Panel(
      height: 380,
      title: 'Top Destinations',
      subtitle: 'By number of bookings',
      child: destinations.isEmpty
          ? const Center(
              child: Text(
                'No destination data',
                style: TextStyle(color: AppColors.textDim),
              ),
            )
          : ListView(
              children: destinations.map((destination) {
                final count =
                    double.tryParse(destination['count']?.toString() ?? '0') ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              destination['destination'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${count.toInt()}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: count / maxCount,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

    return _Panel(
      title: 'Conversion Funnel',
      child: Column(
        children: stages
            .map(
              (stage) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: stage.$3 * 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stage.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        stage.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMonthlyComparison(Map<String, dynamic> stats) {
    return _Panel(
      title: 'Real-time Metrics',
      child: Column(
        children: [
          _buildComparisonRow(
            'Total Users',
            stats['totalUsers']?.toString() ?? '0',
            'Growing',
            true,
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            'Revenue',
            '\$${stats['totalRevenue'] ?? 0}',
            'Live',
            true,
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            'Retention',
            '${stats['userRetention'] ?? 84}%',
            'Healthy',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    String current,
    String previous,
    bool improved,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              current,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              previous,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textDim,
              ),
            ),
          ),
          Icon(
            improved ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: improved ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final double? height;

  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      height: height,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textDim),
            ),
          ],
          const SizedBox(height: 20),
          if (height != null)
            Expanded(child: child)
          else
            child,
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;

  const _KpiData(
    this.title,
    this.value,
    this.change,
    this.isPositive,
    this.icon,
  );
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(data.icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.change,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: data.isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
