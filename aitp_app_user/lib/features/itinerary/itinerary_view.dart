import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class ItineraryView extends StatefulWidget {
  final Map<String, dynamic> trip;
  const ItineraryView({super.key, required this.trip});

  @override
  State<ItineraryView> createState() => _ItineraryViewState();
}

class _ItineraryViewState extends State<ItineraryView> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat'),
        backgroundColor: AppColors.g600,
        child: const Text('🤖', style: TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_currentTab == 1) {
      return const Center(child: Text('Map View Coming Soon 🗺️', style: TextStyle(color: AppColors.gray400)));
    } else if (_currentTab == 2) {
      return const Center(child: Text('Budget View Coming Soon 💰', style: TextStyle(color: AppColors.gray400)));
    }

    final itineraries = widget.trip['itineraries'] as List? ?? [];
    if (itineraries.isEmpty) {
      return const Center(child: Text('No itinerary generated for this trip.', style: TextStyle(color: AppColors.gray400)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itineraries.length,
      itemBuilder: (context, index) {
        final day = itineraries[index];
        final activities = day['activities'] as List? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDayHeader('Day ${day['day_number']}', 'Schedule', '☀️ 24°C'),
            ...activities.map((act) => _ActivityCard(
                  time: _getEmojiForTime(act['time_slot']),
                  name: act['title'] ?? 'Activity',
                  place: '📍 ${act['location'] ?? 'Various locations'}',
                  meta: [act['time_slot'] ?? 'Anytime', '⏱ 2h'],
                  cost: 'Free',
                  color: _getColorForTime(act['time_slot']),
                )),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _getEmojiForTime(String? slot) {
    switch (slot?.toLowerCase()) {
      case 'morning': return '🌅';
      case 'afternoon': return '☀️';
      case 'evening': return '🌙';
      default: return '📍';
    }
  }

  Color _getColorForTime(String? slot) {
    switch (slot?.toLowerCase()) {
      case 'morning': return AppColors.sand;
      case 'afternoon': return const Color(0xfffef3c7);
      case 'evening': return const Color(0xffede9fe);
      default: return AppColors.gray100;
    }
  }

  Widget _buildHeader(BuildContext context) {
    final destination = widget.trip['destination'] ?? 'Unknown';
    final startDate = widget.trip['start_date']?.toString().split('T').first ?? '';
    final endDate = widget.trip['end_date']?.toString().split('T').first ?? '';

    return Hero(
      tag: 'trip_${widget.trip['id']}',
      child: Material(
        color: AppColors.g800,
        child: Container(
          padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back, color: AppColors.white)),
                  const Text('⬆️ Share', style: TextStyle(color: AppColors.g300, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '🌏 $destination',
                style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '📅 $startDate – $endDate  ·  👥 2 people',
                style: const TextStyle(fontSize: 11, color: AppColors.g300, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 16),
              _buildTabs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          _TabItem(label: 'Overview', isActive: _currentTab == 0, onTap: () => setState(() => _currentTab = 0)),
          _TabItem(label: 'Map 🗺️', isActive: _currentTab == 1, onTap: () => setState(() => _currentTab = 1)),
          _TabItem(label: 'Budget 💰', isActive: _currentTab == 2, onTap: () => setState(() => _currentTab = 2)),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String label, String date, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.g600, borderRadius: BorderRadius.circular(999)),
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.white)),
          ),
          const SizedBox(width: 10),
          Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray600)),
          const Spacer(),
          Text(status, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String time;
  final String name;
  final String place;
  final List<String> meta;
  final String cost;
  final Color color;

  const _ActivityCard({required this.time, required this.name, required this.place, required this.meta, required this.cost, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gray100)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(time, style: const TextStyle(fontSize: 16)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gray800)),
                Text(place, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                const SizedBox(height: 8),
                Row(
                  children: meta.map((m) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.gray100)),
                    child: Text(m, style: const TextStyle(fontSize: 9, color: AppColors.gray600, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ],
            ),
          ),
          Text(cost, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.g700)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  const _TabItem({required this.label, this.isActive = false, this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8), 
        decoration: BoxDecoration(color: isActive ? AppColors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)), 
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? AppColors.g800 : AppColors.white.withValues(alpha: 0.6)))
      )
    )
  );
}
