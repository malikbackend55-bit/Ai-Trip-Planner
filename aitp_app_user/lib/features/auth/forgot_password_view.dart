import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_localization.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/beautiful_text_field.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordView({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      backgroundColor: context.appScaffoldColor,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back, color: context.appTextColor),
                  ),
                  const SizedBox(height: 40),
                  Text(
                        strings.tr('auth.resetPassword'),
                        style:
                            (context.appLanguage.isRtl
                            ? GoogleFonts.notoKufiArabic
                            : GoogleFonts.fraunces)(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: context.appTextColor,
                            ),
                      )
                      .animate()
                      .fade(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  const SizedBox(height: 8),
                  Text(
                        strings.tr('auth.resetSubtitle'),
                        style: TextStyle(
                          color: context.appMutedTextColor,
                          fontSize: 14,
                        ),
                      )
                      .animate()
                      .fade(duration: 500.ms, delay: 200.ms)
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

  Widget _buildBackground() {
    return Positioned(
      top: -80,
      right: -60,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.g100.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      ),
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
        ),
        const SizedBox(height: 16),
        BeautifulTextField(
          label: strings.tr('common.phone'),
          hintText: strings.tr('common.phone'),
          icon: Icons.phone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        BeautifulTextField(
          label: strings.tr('auth.newPassword'),
          hintText: strings.tr('auth.newPassword'),
          icon: Icons.lock_outline,
          controller: _passwordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        BeautifulTextField(
          label: strings.tr('auth.confirmPassword'),
          hintText: strings.tr('auth.confirmPassword'),
          icon: Icons.lock_reset_outlined,
          controller: _confirmPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _handleReset,
          child: Text(strings.tr('auth.resetPassword')),
        ),
      ],
    );
  }

  Future<void> _handleReset() async {
    if (_emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('auth.fillAllFields'))));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('auth.passwordMismatch'))),
      );
      return;
    }

    final auth = ref.read(authProvider);
    final errorMessage = await auth.forgotPassword(
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text,
      _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('auth.passwordResetSuccess'))),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}
