import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../core/app_localization.dart';
import '../core/theme.dart';
import 'chat/chat_view.dart';
import 'explore/explore_view.dart';
import 'home/home_view.dart';
import 'profile/profile_view.dart';
import 'trips/my_trips_view.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeView(),
    ExploreView(),
    MyTripsView(),
    ChatView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.appNavBarColor,
          boxShadow: [
            BoxShadow(
              color: context.appShadowColor,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, context.tr('nav.home'), '🏠'),
                _buildNavItem(1, context.tr('nav.explore'), '🔍'),
                _buildNavItem(2, context.tr('nav.myTrips'), '✈️'),
                _buildNavItem(3, context.tr('nav.aiChat'), '🤖'),
                _buildNavItem(4, context.tr('nav.profile'), '👤'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String icon) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isActive ? 1.2 : 1.0,
            child: Text(
              icon,
              style: TextStyle(
                fontSize: 22,
                shadows: isActive
                    ? [
                        Shadow(
                          color: AppColors.g500.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.g600 : context.appMutedTextColor,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 1),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.g500,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
