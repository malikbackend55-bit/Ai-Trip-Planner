import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';

class OverviewView extends StatefulWidget {
  const OverviewView({super.key});

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(0.0, _buildSectionHeader('Overview Stats')),
        const SizedBox(height: 20),
        _buildAnimatedSection(0.1, _buildStatsGrid()),
        const SizedBox(height: 32),
        _buildAnimatedSection(0.2, _buildSectionHeader('Analytics & Growth')),
        const SizedBox(height: 20),
        _buildAnimatedSection(0.3, _buildChartsRow()),
        const SizedBox(height: 32),
        _buildAnimatedSection(0.4, _buildSectionHeader('Recent Activity')),
        const SizedBox(height: 20),
        _buildAnimatedSection(0.5, _buildActivityList()),
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

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _StatCard(title: 'Total Trips', value: '12,450', icon: '✈️', trend: '+12%', isPositive: true),
        _StatCard(title: 'Active Users', value: '8,210', icon: '👥', trend: '+5.4%', isPositive: true),
        _StatCard(title: 'Revenue', value: '\$142,500', icon: '💰', trend: '-2.1%', isPositive: false),
        _StatCard(title: 'Completed', value: '9,840', icon: '✅', trend: '+8.7%', isPositive: true),
      ],
    );
  }

  Widget _buildChartsRow() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildMainChart()),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildDistributionChart()),
      ],
    );
  }

  Widget _buildMainChart() {
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1)),
                titlesData: FlTitlesData(show: true, rightTitles: const AxisTitles(), topTitles: const AxisTitles(), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textDim))))),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 3), FlSpot(2, 2), FlSpot(4, 5), FlSpot(6, 3.1), FlSpot(8, 4), FlSpot(10, 3), FlSpot(12, 7)],
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

  Widget _buildDistributionChart() {
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
          const Text('User Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 40),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(color: AppColors.primary, value: 40, title: '40%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppColors.secondary, value: 30, title: '30%', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppColors.accent, value: 20, title: '20%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppColors.textDim, value: 10, title: '10%', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, _a) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final activities = [
            ('Alice Johnson', 'planned a trip to Paris', '2 min ago'),
            ('Bob Smith', 'completed a trip to Tokyo', '15 min ago'),
            ('Charlie Brown', 'booked a flight to Bali', '1 hour ago'),
            ('Diana Prince', 'updated her itinerary for London', '3 hours ago'),
            ('Evan Wright', 'cancelled a trip to Dubai', '5 hours ago'),
          ];
          final (name, action, time) = activities[index];
          return ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.background, child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
            title: Text('$name $action', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
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
