import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dashboard_provider.dart';
import '../../core/theme.dart';

class OverviewView extends ConsumerStatefulWidget {
  const OverviewView({super.key});

  @override
  ConsumerState<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends ConsumerState<OverviewView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
    
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAnimatedSection(0.0, _buildSectionHeader('Overview Stats')),
            if (provider.isLoading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 20),
        _buildAnimatedSection(0.1, _buildStatsGrid(provider)),
        const SizedBox(height: 32),
        _buildAnimatedSection(0.2, _buildSectionHeader('Analytics & Growth')),
        const SizedBox(height: 20),
        _buildAnimatedSection(0.3, _buildChartsRow(provider)),
        const SizedBox(height: 32),
        _buildAnimatedSection(0.4, _buildSectionHeader('Recent Activity')),
        const SizedBox(height: 20),
        _buildAnimatedSection(0.5, _buildActivityList(provider)),
      ],
    );
  }

  Widget _buildAnimatedSection(double delay, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeIn),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
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
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
    );
  }

  Widget _buildStatsGrid(DashboardProvider provider) {
    final stats = provider.stats;
    final totalTrips = provider.trips.length.toString();
    final totalUsers = stats['totalUsers']?.toString() ?? '0';
    final totalRevenue = '\$${(double.tryParse(stats['totalRevenue']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final completedTrips = provider.completedTripCount.toString();

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(title: 'Total Trips', value: totalTrips, icon: '✈️', trend: '+12%', isPositive: true),
        _StatCard(title: 'Active Users', value: totalUsers, icon: '👥', trend: '+5.4%', isPositive: true),
        _StatCard(title: 'Revenue', value: totalRevenue, icon: '💰', trend: '+1.2%', isPositive: true),
        _StatCard(title: 'Completed', value: completedTrips, icon: '✅', trend: '+8.7%', isPositive: true),
      ],
    );
  }

  Widget _buildChartsRow(DashboardProvider provider) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildMainChart(provider)),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildDistributionChart(provider)),
      ],
    );
  }

  Widget _buildMainChart(DashboardProvider provider) {
    final trends = provider.stats['monthlyTrends'] as List? ?? [];
    final spots = trends.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final count = double.tryParse(entry.value['count']?.toString() ?? '0') ?? 0;
      return FlSpot(index, count);
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Volume Over Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 40),
          Expanded(
            child: spots.isEmpty
                ? const Center(child: Text('Insufficient data for trends', style: TextStyle(color: AppColors.textDim)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1)),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
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
                          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(DashboardProvider provider) {
    final destinations = provider.stats['topDestinations'] as List? ?? [];
    
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Destinations Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 40),
          Expanded(
            child: destinations.isEmpty
                ? const Center(child: Text('No destination data', style: TextStyle(color: AppColors.textDim)))
                : PieChart(
                    PieChartData(
                      sections: destinations.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.g400, AppColors.g200];
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: double.tryParse(data['count']?.toString() ?? '0') ?? 0,
                          title: data['destination']?.split(',').first ?? '',
                          radius: 50 - (index * 2).toDouble(),
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(DashboardProvider provider) {
    final trips = provider.trips;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: trips.isEmpty 
        ? const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('No recent activity', style: TextStyle(color: AppColors.textDim))),
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trips.length > 5 ? 5 : trips.length,
            separatorBuilder: (_, a) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final trip = trips[index];
              final destination = trip['destination'] ?? 'Unkown';
              final date = trip['start_date']?.toString().split('T').first ?? '';
              
              return ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.background, child: Text('✈️', style: TextStyle(fontSize: 18))),
                title: Text('New trip planned to $destination', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Start date: $date', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                trailing: const Text('View →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              );
            },
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(trend, style: TextStyle(color: isPositive ? AppColors.success : AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
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
