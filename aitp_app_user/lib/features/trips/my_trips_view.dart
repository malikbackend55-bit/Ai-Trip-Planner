import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_localization.dart';
import '../../core/theme.dart';
import '../../core/trip_provider.dart';

class MyTripsView extends ConsumerStatefulWidget {
  const MyTripsView({super.key});

  @override
  ConsumerState<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends ConsumerState<MyTripsView> {
  String _selectedTab = 'Upcoming';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider).fetchTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripProvider);
    final filteredTrips = tripsState.trips.where((trip) {
      final status = (trip['status'] ?? 'Upcoming').toString();
      return status == _selectedTab;
    }).toList();

    return Scaffold(
      backgroundColor: context.appScaffoldColor,
      body: Column(
        children: [
          _buildHeader()
              .animate()
              .fade(duration: 400.ms)
              .slideY(begin: -0.1, curve: Curves.easeOutQuart),
          _buildTabs()
              .animate()
              .fade(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutQuart),
          Expanded(
            child: tripsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTrips.isEmpty
                ? Center(
                    child: Text(
                      context.tr(
                        'myTrips.noTripsForFilter',
                        params: {
                          'filter': context.strings.tripStatusLabel(
                            _selectedTab,
                          ),
                        },
                      ),
                      style: TextStyle(color: context.appMutedTextColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      return _MyTripCard(trip: filteredTrips[index])
                          .animate()
                          .fade(duration: 400.ms, delay: (100 + index * 50).ms)
                          .slideY(
                            begin: 0.1,
                            duration: 400.ms,
                            delay: (100 + index * 50).ms,
                            curve: Curves.easeOutQuart,
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${context.tr('myTrips.title')} ✈️',
            style:
                (context.appLanguage.isRtl
                ? GoogleFonts.notoKufiArabic
                : GoogleFonts.fraunces)(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.appTextColor,
                ),
          ),
          GestureDetector(
            onTap: () => context.push('/create-trip'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.g500, AppColors.g700],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurfaceAltColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TabItem(
            label: context.strings.tripStatusLabel('Upcoming'),
            isActive: _selectedTab == 'Upcoming',
            onTap: () => setState(() => _selectedTab = 'Upcoming'),
          ),
          _TabItem(
            label: context.strings.tripStatusLabel('Active'),
            isActive: _selectedTab == 'Active',
            onTap: () => setState(() => _selectedTab = 'Active'),
          ),
          _TabItem(
            label: context.strings.tripStatusLabel('Past'),
            isActive: _selectedTab == 'Past',
            onTap: () => setState(() => _selectedTab = 'Past'),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? context.appSurfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: context.appShadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.g700 : context.appMutedTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _MyTripCard extends StatelessWidget {
  final dynamic trip;

  const _MyTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final tripData = Map<String, dynamic>.from(trip as Map);
    final name =
        (trip['destination'] ?? context.tr('common.unknownDestination'))
            .toString();
    final startDate = trip['start_date']?.toString().split('T').first ?? '';
    final budget =
        '\$${(double.tryParse(trip['budget']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final status = (trip['status'] ?? 'Upcoming').toString();
    final isPast = status == 'Past' || status == 'Completed';
    final isActive = status == 'Active';
    final progress = _tripProgress(trip);
    final emoji = _getEmojiForDestination(name);
    final color = isPast
        ? AppColors.gray600
        : (isActive ? AppColors.coral : AppColors.g700);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
        boxShadow: [
          BoxShadow(
            color: context.appShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      startDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${context.tr('common.budget')}: $budget',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appMutedTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isPast
                          ? context.tr('myTrips.completed')
                          : context.tr(
                              'myTrips.activeProgress',
                              params: {
                                'progress': '${(progress * 100).toInt()}',
                              },
                            ),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appMutedTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: context.appBorderColor,
                  valueColor: AlwaysStoppedAnimation(
                    isPast
                        ? AppColors.gray400
                        : (progress < 0.2 ? Colors.amber : AppColors.g500),
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.push('/itinerary', extra: tripData),
                        child: _BtnSm(
                          label: '👁️ ${context.tr('myTrips.view')}',
                          isPrimary: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          context.push('/create-trip', extra: tripData),
                      child: _BtnSm(label: '✏️ ${context.tr('myTrips.edit')}'),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.push('/chat', extra: tripData),
                      child: _BtnSm(label: '🤖 ${context.tr('myTrips.ai')}'),
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

  String _getEmojiForDestination(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains('paris')) return '🗼';
    if (lower.contains('bali')) return '🌴';
    if (lower.contains('tokyo')) return '⛩️';
    if (lower.contains('new york')) return '🗽';
    if (lower.contains('london')) return '💂';
    return '🌏';
  }
}

double _tripProgress(dynamic trip) {
  final startDate = DateTime.tryParse(trip['start_date']?.toString() ?? '');
  final endDate = DateTime.tryParse(trip['end_date']?.toString() ?? '');

  if (startDate == null || endDate == null) {
    return 0.0;
  }

  final today = DateTime.now();
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  final current = DateTime(today.year, today.month, today.day);

  if (current.isBefore(start)) {
    return 0.0;
  }
  if (current.isAfter(end)) {
    return 1.0;
  }

  final totalDays = end.difference(start).inDays + 1;
  final completedDays = current.difference(start).inDays + 1;
  return (completedDays / totalDays).clamp(0.05, 1.0);
}

class _BtnSm extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _BtnSm({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.g50 : context.appSurfaceAltColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPrimary ? AppColors.g300 : context.appBorderStrongColor,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isPrimary ? AppColors.g700 : context.appSubtextColor,
        ),
      ),
    );
  }
}
