import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Advanced Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 24),
          _buildKpiRow(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRevenueChart()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildTopDestinations()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildConversionFunnel()),
              const SizedBox(width: 24),
              Expanded(child: _buildMonthlyComparison()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        _buildKpiCard('Conversion Rate', '4.8%', '+0.3%', true, Icons.trending_up),
        const SizedBox(width: 16),
        _buildKpiCard('Avg. Trip Value', '\$1,250', '+\$85', true, Icons.attach_money),
        const SizedBox(width: 16),
        _buildKpiCard('Bounce Rate', '32%', '-2.1%', true, Icons.swap_vert),
        const SizedBox(width: 16),
        _buildKpiCard('Retention', '78%', '+1.5%', true, Icons.replay),
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

  Widget _buildRevenueChart() {
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
          const Text('Monthly Revenue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Revenue breakdown by month', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: List.generate(12, (i) {
                  final values = [12, 15, 11, 18, 22, 19, 25, 28, 20, 24, 30, 35];
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: values[i].toDouble(), color: i == 11 ? AppColors.primary : AppColors.secondary.withValues(alpha: 0.6), width: 18, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                  ]);
                }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, m) => Text('\$${v.toInt()}k', style: const TextStyle(fontSize: 10, color: AppColors.textDim)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                    return Text(months[v.toInt()], style: const TextStyle(fontSize: 10, color: AppColors.textDim));
                  })),
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

  Widget _buildTopDestinations() {
    final destinations = [
      ('Paris, France', 2450, 0.92),
      ('Tokyo, Japan', 1820, 0.78),
      ('Bali, Indonesia', 1560, 0.65),
      ('London, UK', 1340, 0.55),
      ('New York, USA', 1120, 0.45),
    ];

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
          ...destinations.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${d.$2}', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: d.$3,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildConversionFunnel() {
    final stages = [
      ('Website Visits', '45,200', 1.0),
      ('Trip Searches', '18,400', 0.41),
      ('Trip Created', '8,900', 0.20),
      ('Booking Completed', '4,800', 0.11),
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

  Widget _buildMonthlyComparison() {
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
          const Text('This Month vs Last Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildComparisonRow('New Users', '1,240', '1,080', true),
          const SizedBox(height: 12),
          _buildComparisonRow('Trips Booked', '890', '920', false),
          const SizedBox(height: 12),
          _buildComparisonRow('Revenue', '\$35,400', '\$31,200', true),
          const SizedBox(height: 12),
          _buildComparisonRow('Cancellations', '45', '62', true),
          const SizedBox(height: 12),
          _buildComparisonRow('Avg Rating', '4.7', '4.5', true),
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
