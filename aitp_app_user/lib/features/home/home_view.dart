import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_localization.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/trip_provider.dart';
import '../main_navigation.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider).fetchTrips();
    });
  }

  void _switchTab(int index) {
    final navState = context.findAncestorStateOfType<MainNavigationState>();
    navState?.switchTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripProvider);

    return Scaffold(
      backgroundColor: context.appScaffoldColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedSection(0.1, _buildQuickActions(context)),
                  const SizedBox(height: 24),
                  _buildAnimatedSection(
                    0.2,
                    _buildSectionHeader(
                      context.tr('home.yourTrips'),
                      context.tr('common.seeAll'),
                      onTap: () => _switchTab(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedSection(0.3, _buildTripSection(trips)),
                  const SizedBox(height: 24),
                  _buildAnimatedSection(
                    0.4,
                    _buildSectionHeader(
                      context.tr('home.suggestedForYou'),
                      context.tr('common.more'),
                      onTap: () => _switchTab(1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedSection(
                    0.5,
                    _buildSuggestedDestinations(trips),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(double delay, Widget child) {
    return child
        .animate()
        .fade(duration: 400.ms, delay: (delay * 1000).ms)
        .slideY(
          begin: 0.1,
          duration: 400.ms,
          delay: (delay * 1000).ms,
          curve: Curves.easeOutQuart,
        );
  }

  Widget _buildTripSection(TripProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.g600),
      );
    }

    if (provider.trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.appSurfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Column(
          children: [
            const Text('⛰️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              context.tr('home.noTripsYet'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('home.startAdventure'),
              style: TextStyle(color: context.appMutedTextColor, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push('/create-trip'),
              child: Text(context.tr('home.createTrip')),
            ),
          ],
        ),
      );
    }

    return _TripCard(trip: provider.trips.first);
  }

  Widget _buildHeader(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userName = auth.user?['name'] ?? context.tr('home.traveler');

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 18, right: 18, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.g800, AppColors.g700],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.tr('home.welcomeBackLabel')} ✈️',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.g300,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$userName 👋',
            style:
                (context.appLanguage.isRtl
                ? GoogleFonts.notoKufiArabic
                : GoogleFonts.fraunces)(
                  fontSize: 24,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _switchTab(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('home.whereToGo'),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.push('/create-trip'),
          child: _QuickAction(icon: '✈️', label: context.tr('home.newTrip')),
        ),
        GestureDetector(
          onTap: () => _switchTab(1),
          child: _QuickAction(icon: '🗺️', label: context.tr('nav.explore')),
        ),
        GestureDetector(
          onTap: () => _switchTab(3),
          child: _QuickAction(icon: '🤖', label: context.tr('nav.aiChat')),
        ),
        GestureDetector(
          onTap: () => _switchTab(2),
          child: _QuickAction(icon: '📅', label: context.tr('nav.myTrips')),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.appTextColor,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.g600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedDestinations(TripProvider provider) {
    final destinations = <String>{};
    for (final trip in provider.trips) {
      if (trip['destination'] != null) {
        destinations.add(trip['destination'].toString());
      }
    }

    final suggestions = [
      _DestData(
        name: 'Tokyo',
        price: '\$2,800',
        emoji: '🗼',
        color: Colors.amber,
      ),
      _DestData(
        name: 'Bali',
        price: '\$1,200',
        emoji: '🌴',
        color: Colors.teal,
      ),
      _DestData(
        name: 'New York',
        price: '\$3,800',
        emoji: '🗽',
        color: Colors.blue,
      ),
      _DestData(
        name: 'Paris',
        price: '\$2,500',
        emoji: '🗼',
        color: Colors.orange,
      ),
      _DestData(
        name: 'London',
        price: '\$2,900',
        emoji: '💂',
        color: Colors.indigo,
      ),
    ];

    final filtered = suggestions.where((item) {
      return !destinations.any(
        (tripDestination) =>
            tripDestination.toLowerCase().contains(item.name.toLowerCase()),
      );
    }).toList();

    final display = filtered.isEmpty ? suggestions : filtered;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: display.take(4).map((item) {
          return _DestCard(
            name: item.name,
            price: item.price,
            emoji: item.emoji,
            color: item.color,
          );
        }).toList(),
      ),
    );
  }
}

class _DestData {
  final String name;
  final String price;
  final String emoji;
  final Color color;

  const _DestData({
    required this.name,
    required this.price,
    required this.emoji,
    required this.color,
  });
}

class _QuickAction extends StatelessWidget {
  final String icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.appShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.appSubtextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final dynamic trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final destination =
        (trip['destination'] ?? context.tr('common.unknownDestination'))
            .toString();
    final budget = double.tryParse(trip['budget']?.toString() ?? '0') ?? 0;
    final status = (trip['status'] ?? 'Upcoming').toString();
    final startDate = trip['start_date']?.toString().split('T').first ?? '';

    return Hero(
      tag: 'trip_${trip['id']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/itinerary', extra: trip),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: context.appSurfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: context.appShadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.g700, AppColors.g500],
                    ),
                  ),
                  child: const Center(
                    child: Text('✈️', style: TextStyle(fontSize: 48)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📅 $startDate · ${context.strings.tripStatusLabel(status)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appMutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('home.estimatedBudget'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.appMutedTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: 1.0,
                                  backgroundColor: context.appBorderColor,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.g500,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  minHeight: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '\$${budget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.g700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DestCard extends StatelessWidget {
  final String name;
  final String price;
  final String emoji;
  final Color color;

  const _DestCard({
    required this.name,
    required this.price,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
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
            height: 75,
            width: double.infinity,
            color: color.withValues(alpha: 0.2),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  context.tr('common.fromPrice', params: {'price': price}),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.g600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
