import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_localization.dart';
import '../../core/app_settings_provider.dart';
import '../../core/auth_provider.dart';
import '../../core/chat_provider.dart';
import '../../core/explore_provider.dart';
import '../../core/language_provider.dart';
import '../../core/theme.dart';
import '../../core/trip_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final trips = ref.watch(tripProvider);
    final settings = ref.watch(appSettingsProvider);
    final user = auth.user;
    final language = ref.watch(languageProvider);
    final tripList = trips.trips;
    final tripCount = tripList.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final uniqueCountries = <String>{};
    for (final trip in tripList) {
      if (trip != null && trip['destination'] != null) {
        final parts = trip['destination'].toString().split(',');
        uniqueCountries.add(parts.last.trim());
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff07110c) : AppColors.gray50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, user)
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: -0.1, curve: Curves.easeOutQuart),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStats(
                        context,
                        tripCount,
                        uniqueCountries.length,
                        isDark,
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  const SizedBox(height: 24),
                  _MenuItem(
                        icon: Icons.edit_outlined,
                        title: context.tr('profile.editProfile'),
                        isDark: isDark,
                        onTap: () => _showEditProfileSheet(context, ref, user),
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: 150.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  const SizedBox(height: 24),
                  _buildMenuSection(
                        context,
                        context.tr('common.settings'),
                        isDark,
                        [
                          _MenuItem(
                            icon: Icons.notifications_active_outlined,
                            title: context.tr('profile.notifications'),
                            isDark: isDark,
                            onTap: () async {
                              final nextValue = !settings.notificationsEnabled;
                              await ref
                                  .read(appSettingsProvider.notifier)
                                  .setNotificationsEnabled(nextValue);
                              await ref.read(tripProvider).syncNotifications();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    nextValue
                                        ? context.tr(
                                            'profile.notificationStatusOn',
                                          )
                                        : context.tr(
                                            'profile.notificationStatusOff',
                                          ),
                                  ),
                                ),
                              );
                            },
                            trailing: _Toggle(
                              value: settings.notificationsEnabled,
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.dark_mode_outlined,
                            title: context.tr('profile.darkMode'),
                            isDark: isDark,
                            trailing: _Toggle(
                              value: settings.themeMode == ThemeMode.dark,
                            ),
                            onTap: () async {
                              final currentMode = settings.themeMode;
                              ThemeMode newMode = currentMode == ThemeMode.dark
                                  ? ThemeMode.light
                                  : ThemeMode.dark;
                              await ref
                                  .read(appSettingsProvider.notifier)
                                  .setThemeMode(newMode);
                            },
                          ),
                          _LanguageToggleCard(
                            icon: Icons.translate_outlined,
                            title: context.tr('common.language'),
                            value: language,
                            isDark: isDark,
                            onChanged: (value) async {
                              await ref
                                  .read(languageProvider.notifier)
                                  .setLanguage(value);
                              ref.invalidate(chatProvider);
                              ref.invalidate(exploreProvider);
                            },
                          ),
                          _MenuItem(
                            icon: Icons.shield_outlined,
                            title: context.tr('profile.privacy'),
                            isDark: isDark,
                            onTap: () => _showPrivacyDialog(context),
                          ),
                        ],
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: 200.ms)
                      .slideX(begin: 0.05, curve: Curves.easeOutQuart),
                  const SizedBox(height: 24),
                  _buildLogoutButton(context, ref, isDark)
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

  Widget _buildHeader(BuildContext context, dynamic user) {
    final name = user?['name']?.toString() ?? context.tr('home.traveler');
    final email = user?['email']?.toString() ?? context.tr('profile.noEmail');
    final phone =
        user?['phone']?.toString() ?? context.tr('profile.phoneMissing');
    final initials = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .join();

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
              gradient: const LinearGradient(
                colors: [AppColors.g400, AppColors.g600],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.3),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'U' : initials,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style:
                (context.appLanguage.isRtl
                ? GoogleFonts.notoKufiArabic
                : GoogleFonts.fraunces)(
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
          const SizedBox(height: 4),
          Text(
            phone,
            style: const TextStyle(fontSize: 12, color: AppColors.g200),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context,
    int tripCount,
    int countryCount,
    bool isDark,
  ) {
    return Row(
      children: [
        _StatCard(
          num: tripCount.toString(),
          label: context.tr('common.trips'),
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _StatCard(
          num: countryCount.toString(),
          label: context.tr('common.countries'),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    bool isDark,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.g200 : AppColors.gray400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isDark) {
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
          color: isDark ? const Color(0xff101717) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Text(
          context.tr('common.logout'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? user,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: user?['name']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: user?['email']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: user?['phone']?.toString() ?? '',
    );
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff101717) : AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('profile.editProfile'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: context.tr('common.fullName'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('auth.fillAllFields');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: context.tr('common.email'),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('auth.fillAllFields');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: context.tr('common.phone'),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('auth.fillAllFields');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                setSheetState(() => isSaving = true);
                                final error = await ref
                                    .read(authProvider)
                                    .updateProfile(
                                      nameController.text.trim(),
                                      emailController.text.trim(),
                                      phoneController.text.trim(),
                                    );

                                if (!context.mounted) {
                                  return;
                                }

                                if (error != null) {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                  return;
                                }

                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr('profile.updateSuccess'),
                                    ),
                                  ),
                                );
                              },
                        child: Text(context.tr('common.saveChanges')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPrivacyDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.tr('profile.privacy')),
          content: Text(dialogContext.tr('profile.privacyMessage')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).okButtonLabel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.num,
    required this.label,
    required this.isDark,
  });

  final String num;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff101717) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.06)
                : AppColors.gray100,
          ),
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
              style:
                  (context.appLanguage.isRtl
                  ? GoogleFonts.notoKufiArabic
                  : GoogleFonts.fraunces)(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.g700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.g200 : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.isDark,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff101717) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.06)
                : AppColors.gray100,
          ),
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
            Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.g200 : AppColors.g700,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.gray700,
              ),
            ),
            const Spacer(),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.g200 : AppColors.gray200,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggleCard extends StatelessWidget {
  const _LanguageToggleCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final AppLanguage value;
  final bool isDark;
  final Future<void> Function(AppLanguage value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff101717) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.gray100,
        ),
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
          Icon(icon, size: 20, color: isDark ? AppColors.g200 : AppColors.g700),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.gray700,
            ),
          ),
          const Spacer(),
          _LanguageSegment(
            label: 'EN',
            isSelected: value == AppLanguage.english,
            onTap: () => onChanged(AppLanguage.english),
          ),
          const SizedBox(width: 6),
          _LanguageSegment(
            label: 'KU',
            isSelected: value == AppLanguage.sorani,
            onTap: () => onChanged(AppLanguage.sorani),
          ),
        ],
      ),
    );
  }
}

class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.g600 : AppColors.gray50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.g600 : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppColors.white : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 20,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? AppColors.g500 : AppColors.gray200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
