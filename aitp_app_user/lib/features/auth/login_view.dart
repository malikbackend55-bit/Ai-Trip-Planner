import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_localization.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/trip_provider.dart';
import '../../core/widgets/beautiful_text_field.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      backgroundColor: context.appScaffoldColor,
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(strings)
                      .animate()
                      .fade(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  const SizedBox(height: 32),
                  _buildForm(strings)
                      .animate()
                      .fade(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDarkMode
              ? [const Color(0xff143024), context.appScaffoldColor]
              : [AppColors.g100, AppColors.white],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.g200.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.g600, AppColors.g800],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.g600.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('🌍', style: TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${strings.tr('auth.welcomeBack')} 👋',
          style:
              (context.appLanguage.isRtl
              ? GoogleFonts.notoKufiArabic
              : GoogleFonts.fraunces)(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: context.appTextColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.tr('auth.loginSubtitle'),
          style: TextStyle(color: context.appMutedTextColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildForm(AppStrings strings) {
    return Column(
      children: [
        BeautifulTextField(
          label: strings.tr('common.email'),
          hintText: strings.tr('common.email'),
          icon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 16),
        BeautifulTextField(
          label: strings.tr('common.password'),
          hintText: strings.tr('common.password'),
          icon: Icons.lock_outline,
          controller: _passwordController,
          isPassword: true,
          onSubmitted: (_) => _handleLogin(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(
              '/forgot-password',
              extra: _emailController.text.trim(),
            ),
            child: Text(
              strings.tr('auth.forgotPassword'),
              style: TextStyle(
                color: context.isDarkMode ? AppColors.g300 : AppColors.g700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _handleLogin,
          child: Text(strings.tr('auth.login')),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              strings.tr('auth.noAccount'),
              style: TextStyle(color: context.appMutedTextColor, fontSize: 13),
            ),
            TextButton(
              onPressed: () => context.push('/register'),
              child: Text(
                strings.tr('auth.signUp'),
                style: TextStyle(
                  color: context.isDarkMode ? AppColors.g300 : AppColors.g700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    final auth = ref.read(authProvider);
    final errorMessage = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (errorMessage == null) {
      await ref.read(tripProvider).fetchTrips();
      if (mounted) {
        context.go('/home');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}
