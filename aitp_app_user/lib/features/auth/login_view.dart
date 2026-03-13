import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'register_view.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../main_navigation.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
   late AnimationController _controller;
   late Animation<Offset> _formOffset;
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _formOffset = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 32),
                  SlideTransition(
                    position: _formOffset,
                    child: FadeTransition(
                      opacity: _controller,
                      child: _buildForm(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.g100, AppColors.white],
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
                color: AppColors.g200.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.g600, AppColors.g800]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.g600.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Center(child: Text('🌍', style: TextStyle(fontSize: 32))),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome back 👋',
          style: GoogleFonts.fraunces(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.g900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Login to continue planning your adventures.',
          style: TextStyle(color: AppColors.gray400, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildTextField('Email Address', Icons.email_outlined),
        _buildTextField('Email Address', Icons.email_outlined, controller: _emailController), // Pass controller
        const SizedBox(height: 16),
        _buildTextField('Password', Icons.lock_outline, isPassword: true, controller: _passwordController), // Pass controller
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('Forgot Password?', style: TextStyle(color: AppColors.g700, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _handleLogin, // Call _handleLogin
          child: const Text('Login'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.gray200)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR', style: TextStyle(color: AppColors.gray400, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: AppColors.gray200)),
          ],
        ),
        const SizedBox(height: 24),
        _buildSocialButton('Continue with Google', '🔍'),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Don\'t have an account?', style: TextStyle(color: AppColors.gray400, fontSize: 13)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView()));
              },
              child: const Text('Sign Up', style: TextStyle(color: AppColors.g700, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool isPassword = false, TextEditingController? controller}) {
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

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success) {
      // Navigate to main navigation on successful login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      // Show error message (you can use a dialog or snack bar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please check your credentials.')),
        );
      }
    }
  }

  Widget _buildSocialButton(String label, String icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gray800)),
        ],
      ),
    );
  }
}
