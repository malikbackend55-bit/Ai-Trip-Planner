import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_localization.dart';
import '../../core/explore_provider.dart';
import '../../core/theme.dart';

class ExploreView extends ConsumerStatefulWidget {
  const ExploreView({super.key});

  @override
  ConsumerState<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends ConsumerState<ExploreView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(exploreProvider);

    return Scaffold(
      backgroundColor: context.appScaffoldColor,
      body: Column(
        children: [
          _buildHeader(provider),
          _buildFilterChips(provider),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.g600),
                  )
                : provider.destinations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('explore.noDestinations'),
                          style: TextStyle(
                            color: context.appMutedTextColor,
                            fontSize: 14,
                          ),
                        ),
                        if (provider.searchQuery.isNotEmpty ||
                            provider.activeFilter != 'All')
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(exploreProvider).setSearchQuery('');
                              ref.read(exploreProvider).setFilter('All');
                            },
                            child: Text(context.tr('common.clearFilters')),
                          ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children:
                        [
                              ...provider.destinations.map((destination) {
                                return _ExploreCard(
                                  name: destination.name,
                                  sub: destination.subtitle,
                                  price: destination.price,
                                  emoji: destination.emoji,
                                  rating: destination.rating,
                                  color: destination.color,
                                  onTap: () => context.push(
                                    '/create-trip',
                                    extra: {'destination': destination.name},
                                  ),
                                );
                              }),
                              const SizedBox(height: 80),
                            ]
                            .animate(interval: 100.ms)
                            .fade(duration: 400.ms)
                            .slideY(
                              begin: 0.1,
                              duration: 400.ms,
                              curve: Curves.easeOutQuart,
                            ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ExploreProvider provider) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${context.tr('explore.title')} 🌍',
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
                onTap: () => ref.read(exploreProvider).fetchDestinations(),
                child: Icon(Icons.refresh, color: context.appSubtextColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.appSurfaceAltColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appBorderStrongColor),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(exploreProvider).setSearchQuery(value),
              decoration: InputDecoration(
                icon: const Icon(
                  Icons.search,
                  color: AppColors.gray400,
                  size: 20,
                ),
                hintText: context.tr('explore.searchHint'),
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: context.appMutedTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ExploreProvider provider) {
    final filters = ['All', 'Beach', 'City', 'Nature', 'Budget', 'Luxury'];
    final icons = {
      'All': '🌍',
      'Beach': '🏖️',
      'City': '🏙️',
      'Nature': '⛰️',
      'Budget': '💰',
      'Luxury': '✨',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isActive = provider.activeFilter == filter;
          final label =
              '${icons[filter]} ${context.strings.filterLabel(filter)}';
          return GestureDetector(
            onTap: () => ref.read(exploreProvider).setFilter(filter),
            child: _Chip(label: label, isActive: isActive),
          );
        }).toList(),
      ).animate().fade(duration: 400.ms, delay: 200.ms),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _Chip({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.g600 : context.appSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? AppColors.g600 : context.appBorderStrongColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.white : context.appSubtextColor,
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final String name;
  final String sub;
  final String price;
  final String emoji;
  final String rating;
  final Color color;
  final VoidCallback onTap;

  const _ExploreCard({
    required this.name,
    required this.sub,
    required this.price,
    required this.emoji,
    required this.rating,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.appSurfaceColor,
          borderRadius: BorderRadius.circular(20),
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
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              color: color.withValues(alpha: 0.15),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appMutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.coral,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.coral,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          context.tr(
                            'common.fromPrice',
                            params: {'price': price},
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.g700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
