import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/trip_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final trips = ref.watch(tripProvider);
    final user = auth.user;
    final tripList = trips.trips;
    final tripCount = tripList.length;

    final uniqueCountries = <String>{};
    for (final trip in tripList) {
      if (trip != null && trip['destination'] != null) {
        final destination = trip['destination'].toString();
        final parts = destination.split(',');
        uniqueCountries.add(parts.last.trim());
      }
    }
    final countryCount = uniqueCountries.length;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(user)
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: -0.1, curve: Curves.easeOutQuart),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStats(tripCount, countryCount)
                      .animate()
                      .fade(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  const SizedBox(height: 24),
                  _buildMenuSection('Settings', const [
                    _MenuItem(icon: '🔔', title: 'Notifications', trailing: _Toggle(initialValue: true)),
                    _MenuItem(icon: '🌙', title: 'Dark Mode', trailing: _Toggle(initialValue: false)),
                    _MenuItem(icon: '🌐', title: 'Language'),
                    _MenuItem(icon: '🔒', title: 'Privacy & Security'),
                  ])
                      .animate()
                      .fade(duration: 400.ms, delay: 200.ms)
                      .slideX(begin: 0.05, curve: Curves.easeOutQuart),
                  const SizedBox(height: 24),
                  _buildLogoutButton(context, ref)
                      .animate()
                      .fade(duration: 400.ms, delay: 300.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    final name = user?['name'] ?? 'Traveler';
    final email = user?['email'] ?? 'No email';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40),
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
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.g400, AppColors.g600]),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text('👤', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 12, color: AppColors.g300),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int tripCount, int countryCount) {
    return Row(
      children: [
        _StatCard(num: tripCount.toString(), label: 'Trips'),
        const SizedBox(width: 8),
        _StatCard(num: countryCount.toString(), label: 'Countries'),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.gray400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final auth = ref.read(authProvider);
        await auth.logout();
        ref.read(tripProvider).clearTrips();
        if (context.mounted) {
          context.go('/login');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: const Text(
          '🚪 Logout',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String num;
  final String label;

  const _StatCard({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              num,
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.g700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String icon;
  final String title;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.gray700,
            ),
          ),
          const Spacer(),
          trailing ?? const Icon(Icons.chevron_right, color: AppColors.gray200, size: 20),
        ],
      ),
    );
  }
}

class _Toggle extends StatefulWidget {
  final bool initialValue;

  const _Toggle({required this.initialValue});

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isOn = !isOn;
        });
      },
      child: Container(
        width: 34,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isOn ? AppColors.g500 : AppColors.gray200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
