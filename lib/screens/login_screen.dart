import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await AuthService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Could not connect. Please check your internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKTheme.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LKTheme.goldGradient,
                      boxShadow: [
                        BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 3),
                      ],
                    ),
                    child: const Icon(Icons.favorite, color: Color(0xFF5A3D10), size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text('LifeKnob', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: LKTheme.gold))),
                const SizedBox(height: 8),
                Center(child: Text('Welcome back', style: TextStyle(fontSize: 16, color: LKTheme.textSecondary))),
                const SizedBox(height: 48),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: LKTheme.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LKTheme.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(_errorMessage!, style: TextStyle(color: LKTheme.red, fontSize: 14), textAlign: TextAlign.center),
                  ),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 100,
                  style: TextStyle(fontSize: 18, color: LKTheme.textPrimary),
                  decoration: InputDecoration(labelText: 'Email', counterText: '', prefixIcon: Icon(Icons.email_outlined, size: 24, color: LKTheme.gold)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  maxLength: 50,
                  style: TextStyle(fontSize: 18, color: LKTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outlined, size: 24, color: LKTheme.gold),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 24, color: LKTheme.textMuted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 3))
                        : const Text('Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, color: LKTheme.textSecondary),
                        children: [
                          TextSpan(text: "Don't have an account? "),
                          TextSpan(text: 'Sign Up', style: TextStyle(color: LKTheme.gold, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
