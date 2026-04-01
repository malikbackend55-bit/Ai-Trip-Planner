import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dashboard_provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool emailNotif = true;
  bool pushNotif = true;
  bool smsNotif = false;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider).refresh();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(dashboardProvider);
    final profile = provider.adminProfile;

    return FadeTransition(
      opacity: _anim,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < AppBreakpoints.tablet;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              if (isNarrow) ...[
                _buildPrimaryColumn(profile),
                const SizedBox(height: 24),
                _buildSecondaryColumn(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildPrimaryColumn(profile)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildSecondaryColumn()),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryColumn(Map<String, dynamic> profile) {
    return Column(
      children: [
        _buildProfileSection(profile),
        const SizedBox(height: 24),
        _buildNotificationsSection(),
        const SizedBox(height: 24),
        _buildDangerZone(),
      ],
    );
  }

  Widget _buildSecondaryColumn() {
    return Column(
      children: [
        _buildSystemInfo(),
        const SizedBox(height: 24),
        _buildAppearanceSection(),
      ],
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> profile) {
    final name = profile['name']?.toString() ?? 'Admin User';
    final email = profile['email']?.toString() ?? 'admin@aitripplanner.com';
    final role = (profile['role']?.toString() ?? 'admin').toUpperCase();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    final isMobile = AppBreakpoints.isMobile(context);

    return _buildCard(
      'Profile Information',
      Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileAvatar(initial),
                const SizedBox(height: 16),
                _profileText(name, email, role),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile editing coming soon.'),
                      ),
                    );
                  },
                  child: const Text('Edit Profile'),
                ),
              ],
            )
          else
            Row(
              children: [
                _profileAvatar(initial),
                const SizedBox(width: 20),
                Expanded(child: _profileText(name, email, role)),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile editing coming soon.'),
                      ),
                    );
                  },
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          const SizedBox(height: 20),
          _buildTextField('Full Name', name),
          const SizedBox(height: 12),
          _buildTextField('Email Address', email),
          const SizedBox(height: 12),
          _buildTextField('Phone', profile['phone']?.toString() ?? 'Not set'),
        ],
      ),
    );
  }

  Widget _profileAvatar(String initial) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _profileText(String name, String email, String role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(fontSize: 13, color: AppColors.textDim),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildCard(
      'Notifications',
      Column(
        children: [
          _buildToggle(
            'Email Notifications',
            'Receive trip updates via email',
            emailNotif,
            (value) => setState(() => emailNotif = value),
          ),
          const Divider(height: 24, color: AppColors.border),
          _buildToggle(
            'Push Notifications',
            'Get real-time push alerts',
            pushNotif,
            (value) => setState(() => pushNotif = value),
          ),
          const Divider(height: 24, color: AppColors.border),
          _buildToggle(
            'SMS Alerts',
            'Receive critical alerts via SMS',
            smsNotif,
            (value) => setState(() => smsNotif = value),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textDim),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfo() {
    final provider = ref.watch(dashboardProvider);
    final totalUsers = provider.users.length;
    final totalTrips = provider.trips.length;

    return _buildCard(
      'System Information',
      Column(
        children: [
          _buildInfoRow('App Version', 'v1.0.0'),
          const SizedBox(height: 10),
          _buildInfoRow('Total Users', totalUsers.toString()),
          const SizedBox(height: 10),
          _buildInfoRow('Total Trips', totalTrips.toString()),
          const SizedBox(height: 10),
          _buildInfoRow('Platform', 'Web / Desktop'),
          const SizedBox(height: 10),
          _buildInfoRow('Timezone', 'UTC+3'),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'API Key',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDim,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'sk-****-****-****-7f3a',
                    style: TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.textDim,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textDim),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildCard(
      'Appearance',
      Column(
        children: [
          _buildToggle(
            'Dark Mode',
            'Switch to dark theme',
            darkMode,
            (value) => setState(() => darkMode = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Accent Color',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ...[
                AppColors.primary,
                AppColors.accent,
                Colors.blue,
                Colors.purple,
              ].map(
                (color) => Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: color == AppColors.primary
                        ? Border.all(color: AppColors.textMain, width: 2)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          _buildDangerRow(
            title: 'Export All Data',
            subtitle: 'Download a copy of all system data',
            action: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export feature not implemented.'),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
              ),
              child: const Text('Export'),
            ),
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),
          _buildDangerRow(
            title: 'Reset All Data',
            subtitle: 'This action cannot be undone',
            action: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Reset functionality disabled in demo mode.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(100, 40),
              ),
              child: const Text('Reset'),
            ),
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerRow({
    required String title,
    required String subtitle,
    required Widget action,
    required bool isMobile,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 12),
          action,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textDim),
              ),
            ],
          ),
        ),
        action,
      ],
    );
  }

  Widget _buildCard(String title, Widget child) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      width: double.infinity,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
