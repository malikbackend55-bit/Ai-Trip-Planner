import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dashboard_provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';

class OverviewView extends ConsumerStatefulWidget {
  const OverviewView({super.key});

  @override
  ConsumerState<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends ConsumerState<OverviewView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider).refresh();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(dashboardProvider);
    final isMobile = AppBreakpoints.isMobile(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedSection(
                    0.0,
                    _buildSectionHeader('Overview Stats'),
                  ),
                ),
                if (provider.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAnimatedSection(0.1, _buildStatsGrid(provider, width)),
            const SizedBox(height: 32),
            _buildAnimatedSection(0.2, _buildSectionHeader('Analytics & Growth')),
            const SizedBox(height: 20),
            _buildAnimatedSection(0.3, _buildChartsSection(provider, width)),
            const SizedBox(height: 32),
            _buildAnimatedSection(0.4, _buildSectionHeader('Recent Activity')),
            const SizedBox(height: 20),
            _buildAnimatedSection(
              0.5,
              _buildActivityList(provider, compact: isMobile),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedSection(double delay, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeIn),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.4, curve: Curves.easeOutQuart),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildStatsGrid(DashboardProvider provider, double width) {
    final stats = provider.stats;
    final totalTrips = provider.trips.length.toString();
    final totalUsers = stats['totalUsers']?.toString() ?? '0';
    final totalRevenue =
        '\$${(double.tryParse(stats['totalRevenue']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final completedTrips = provider.completedTripCount.toString();

    final columns = width >= 1400
        ? 4
        : width >= AppBreakpoints.mobile
            ? 2
            : 1;
    final aspectRatio = width < AppBreakpoints.mobile ? 2.2 : 2.0;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: aspectRatio,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          title: 'Total Trips',
          value: totalTrips,
          icon: Icons.flight_takeoff_outlined,
          trend: '+12%',
          isPositive: true,
        ),
        _StatCard(
          title: 'Active Users',
          value: totalUsers,
          icon: Icons.group_outlined,
          trend: '+5.4%',
          isPositive: true,
        ),
        _StatCard(
          title: 'Revenue',
          value: totalRevenue,
          icon: Icons.attach_money_rounded,
          trend: '+1.2%',
          isPositive: true,
        ),
        _StatCard(
          title: 'Completed',
          value: completedTrips,
          icon: Icons.check_circle_outline,
          trend: '+8.7%',
          isPositive: true,
        ),
      ],
    );
  }

  Widget _buildChartsSection(DashboardProvider provider, double width) {
    if (width < AppBreakpoints.tablet) {
      return Column(
        children: [
          _buildMainChart(provider),
          const SizedBox(height: 20),
          _buildDistributionChart(provider),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildMainChart(provider)),
        const SizedBox(width: 24),
        Expanded(child: _buildDistributionChart(provider)),
      ],
    );
  }

  Widget _buildMainChart(DashboardProvider provider) {
    final trends = provider.stats['monthlyTrends'] as List? ?? [];
    final spots = trends.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final count =
          double.tryParse(entry.value['count']?.toString() ?? '0') ?? 0;
      return FlSpot(index, count);
    }).toList();

    return _ChartCard(
      title: 'Trip Volume Over Time',
      child: spots.isEmpty
          ? const Center(
              child: Text(
                'Insufficient data for trends',
                style: TextStyle(color: AppColors.textDim),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
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
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDistributionChart(DashboardProvider provider) {
    final destinations = provider.stats['topDestinations'] as List? ?? [];

    return _ChartCard(
      title: 'Top Destinations Distribution',
      child: destinations.isEmpty
          ? const Center(
              child: Text(
                'No destination data',
                style: TextStyle(color: AppColors.textDim),
              ),
            )
          : PieChart(
              PieChartData(
                sections: destinations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final colors = [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.accent,
                    AppColors.g400,
                    AppColors.g200,
                  ];

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value:
                        double.tryParse(data['count']?.toString() ?? '0') ?? 0,
                    title: data['destination']?.split(',').first ?? '',
                    radius: 52 - (index * 2).toDouble(),
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildActivityList(DashboardProvider provider, {required bool compact}) {
    final trips = provider.trips;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: trips.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: AppColors.textDim),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trips.length > 5 ? 5 : trips.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final trip = trips[index];
                final destination = trip['destination'] ?? 'Unknown';
                final date = trip['start_date']?.toString().split('T').first ?? '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.background,
                    child: Icon(
                      Icons.flight_takeoff_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'New trip planned to $destination',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Start date: $date',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDim,
                    ),
                  ),
                  trailing: compact
                      ? const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.primary,
                        )
                      : const Text(
                          'View',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                );
              },
            ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      height: isMobile ? 320 : 400,
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 32),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final bool isPositive;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      trend,
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
