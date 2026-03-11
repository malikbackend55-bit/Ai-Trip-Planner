import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool emailNotif = true;
  bool pushNotif = true;
  bool smsNotif = false;
  bool darkMode = false;

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
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: Column(children: [_buildProfileSection(), const SizedBox(height: 24), _buildNotificationsSection(), const SizedBox(height: 24), _buildDangerZone()])),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: Column(children: [_buildSystemInfo(), const SizedBox(height: 24), _buildAppearanceSection()])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildCard(
      'Profile Information',
      Column(
        children: [
          Row(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('👨‍💻', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('admin@aitripplanner.com', style: TextStyle(fontSize: 13, color: AppColors.textDim)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Super Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              OutlinedButton(onPressed: () {}, child: const Text('Edit Profile', style: TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('Full Name', 'Admin User'),
          const SizedBox(height: 12),
          _buildTextField('Email Address', 'admin@aitripplanner.com'),
          const SizedBox(height: 12),
          _buildTextField('Phone', '+1 (555) 123-4567'),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
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
          _buildToggle('Email Notifications', 'Receive trip updates via email', emailNotif, (v) => setState(() => emailNotif = v)),
          const Divider(height: 24, color: AppColors.border),
          _buildToggle('Push Notifications', 'Get real-time push alerts', pushNotif, (v) => setState(() => pushNotif = v)),
          const Divider(height: 24, color: AppColors.border),
          _buildToggle('SMS Alerts', 'Receive critical alerts via SMS', smsNotif, (v) => setState(() => smsNotif = v)),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary.withValues(alpha: 0.4), thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null)),
      ],
    );
  }

  Widget _buildSystemInfo() {
    return _buildCard(
      'System Information',
      Column(
        children: [
          _buildInfoRow('App Version', 'v1.0.0'),
          const SizedBox(height: 10),
          _buildInfoRow('Flutter SDK', '3.11.0'),
          const SizedBox(height: 10),
          _buildInfoRow('Dart SDK', '3.6.0'),
          const SizedBox(height: 10),
          _buildInfoRow('Platform', 'Windows'),
          const SizedBox(height: 10),
          _buildInfoRow('Timezone', 'UTC+3'),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          const Text('API Key', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Expanded(child: Text('sk-****-****-****-7f3a', style: TextStyle(fontSize: 13, fontFamily: 'monospace'))),
                IconButton(icon: const Icon(Icons.copy, size: 16, color: AppColors.textDim), onPressed: () {}),
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
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textDim)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildCard(
      'Appearance',
      Column(
        children: [
          _buildToggle('Dark Mode', 'Switch to dark theme', darkMode, (v) => setState(() => darkMode = v)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Accent Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              ...[AppColors.primary, AppColors.accent, Colors.blue, Colors.purple].map((c) => Container(
                margin: const EdgeInsets.only(left: 8),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                  border: c == AppColors.primary ? Border.all(color: AppColors.textMain, width: 2) : null,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
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
          const Text('Danger Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Export All Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Text('Download a copy of all system data', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                  ],
                ),
              ),
              OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent), child: const Text('Export')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reset All Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Text('This action cannot be undone', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                  ],
                ),
              ),
              ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(100, 40)), child: const Text('Reset')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
