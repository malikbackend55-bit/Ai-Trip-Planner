import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();

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
    return Scaffold(
      backgroundColor: AppColors.white,
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
                    child: const Icon(Icons.arrow_back, color: AppColors.gray800),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Reset Password',
                    style: GoogleFonts.fraunces(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.g900,
                    ),
                  ).animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  const SizedBox(height: 8),
                  const Text(
                    'Use your email and phone number to set a new password.',
                    style: TextStyle(color: AppColors.gray400, fontSize: 14),
                  ).animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  const SizedBox(height: 32),
                  _buildForm().animate().fade(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
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

  Widget _buildForm() {
    return Column(
      children: [
        _buildTextField('Email Address', Icons.email_outlined, controller: _emailController),
        const SizedBox(height: 16),
        _buildTextField('Phone Number', Icons.phone_outlined, controller: _phoneController),
        const SizedBox(height: 16),
        _buildTextField('New Password', Icons.lock_outline, controller: _passwordController, isPassword: true),
        const SizedBox(height: 16),
        _buildTextField('Confirm Password', Icons.lock_reset_outlined, controller: _confirmPasswordController, isPassword: true),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _handleReset,
          child: const Text('Reset Password'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, {required TextEditingController controller, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gray600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray200),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              icon: Icon(icon, color: AppColors.gray400, size: 20),
              border: InputBorder.none,
              hintText: label,
              hintStyle: const TextStyle(color: AppColors.gray200, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleReset() async {
    if (_emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
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
        const SnackBar(content: Text('Password reset successful. Log in with your new password.')),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
}
