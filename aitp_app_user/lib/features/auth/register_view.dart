import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../main_navigation.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> with SingleTickerProviderStateMixin {
   late AnimationController _controller;
   late Animation<Offset> _formOffset;
   final TextEditingController _nameController = TextEditingController();
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _formOffset = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
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
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.gray800),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Create Account ✈️',
                    style: GoogleFonts.fraunces(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.g900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join thousands of travelers planning with AI.',
                    style: TextStyle(color: AppColors.gray400, fontSize: 14),
                  ),
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
    return Positioned(
      bottom: -100,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.g50,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildTextField('Full Name', Icons.person_outline, controller: _nameController),
        const SizedBox(height: 16),
        _buildTextField('Email Address', Icons.email_outlined, controller: _emailController),
        const SizedBox(height: 16),
        _buildTextField('Password', Icons.lock_outline, isPassword: true, controller: _passwordController),
        const SizedBox(height: 24),
        _buildTerms(),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _handleRegister,
          child: const Text('Create Account'),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account?', style: TextStyle(color: AppColors.gray400, fontSize: 13)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Login', style: TextStyle(color: AppColors.g700, fontWeight: FontWeight.bold, fontSize: 13)),
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

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success) {
      // Navigate to main navigation on successful registration
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Please try again.')),
        );
      }
    }
  }

  Widget _buildTerms() {
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
        const Expanded(
          child: Text(
            'I agree to the Terms of Service and Privacy Policy.',
            style: TextStyle(color: AppColors.gray400, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
