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

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                        '${strings.tr('auth.createAccount')} ✈️',
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
                        strings.tr('auth.joinTravelers'),
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
      bottom: -100,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.g500.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildForm(AppStrings strings) {
    return Column(
      children: [
        BeautifulTextField(
          label: strings.tr('common.fullName'),
          hintText: strings.tr('common.fullName'),
          icon: Icons.person_outline,
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
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
          label: strings.tr('common.password'),
          hintText: strings.tr('common.password'),
          icon: Icons.lock_outline,
          controller: _passwordController,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _buildTerms(strings),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _handleRegister,
          child: Text(strings.tr('auth.createAccount')),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              strings.tr('auth.alreadyHaveAccount'),
              style: TextStyle(color: context.appMutedTextColor, fontSize: 13),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                strings.tr('auth.login'),
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

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('auth.fillAllFields'))),
        );
      }
      return;
    }

    final auth = ref.read(authProvider);
    final errorMessage = await auth.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
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

  Widget _buildTerms(AppStrings strings) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.g500,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            strings.tr('auth.terms'),
            style: TextStyle(color: context.appMutedTextColor, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
