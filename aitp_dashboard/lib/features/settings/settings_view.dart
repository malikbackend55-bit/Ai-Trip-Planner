import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_service.dart';
import '../../core/dashboard_provider.dart';
import '../../core/export_file.dart';
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
  final ApiService _apiService = ApiService();
  bool _isExporting = false;
  bool _isResetting = false;

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
              _buildPrimaryColumn(profile),
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
        _buildDangerZone(),
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


  Future<void> _handleExport() async {
    if (_isExporting) {
      return;
    }

    setState(() => _isExporting = true);

    try {
      final response = await _apiService.exportAdminData();
      final exportData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{'data': response.data};
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final fileName = 'aitp-dashboard-export-$timestamp.json';
      final content = const JsonEncoder.withIndent('  ').convert(exportData);
      final result = await saveExportFile(fileName, content);

      if (!mounted) {
        return;
      }

      final message = result == 'Download started'
          ? 'Export download started.'
          : 'Export saved to $result';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export failed. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleReset() async {
    if (_isResetting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will delete all trips and all non-admin users. Admin accounts will be kept. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isResetting = true);

    try {
      final response = await _apiService.resetAdminData();
      await ref.read(dashboardProvider).refresh();

      if (!mounted) {
        return;
      }

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final deletedUsers = data['deletedUsers']?.toString() ?? '0';
      final deletedTrips = data['deletedTrips']?.toString() ?? '0';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reset complete. Deleted $deletedTrips trips and $deletedUsers users.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset failed. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  Widget _buildDangerZone() {
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
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
              onPressed: _isExporting ? null : _handleExport,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
              ),
              child: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Export'),
            ),
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),
          _buildDangerRow(
            title: 'Reset All Data',
            subtitle: 'Delete all trips and all non-admin users',
            action: ElevatedButton(
              onPressed: _isResetting ? null : _handleReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(100, 40),
              ),
              child: _isResetting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Reset'),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textDim),
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
