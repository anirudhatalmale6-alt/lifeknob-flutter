import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await AuthService().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
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
      backgroundColor: LKTheme.bg,
      appBar: AppBar(
        backgroundColor: LKTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LKTheme.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: LKTheme.gold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Join LifeKnob to stay connected', style: TextStyle(fontSize: 16, color: LKTheme.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: LKTheme.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LKTheme.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: LKTheme.red, fontSize: 14), textAlign: TextAlign.center),
                  ),

                _buildField(controller: _nameController, label: 'Name', icon: Icons.person_outlined, maxLength: 50,
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null),
                const SizedBox(height: 14),

                _buildField(controller: _emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, maxLength: 100,
                  validator: (v) { if (v == null || v.isEmpty) return 'Please enter your email'; if (!v.contains('@')) return 'Please enter a valid email'; return null; }),
                const SizedBox(height: 14),

                _buildField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, maxLength: 20,
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter your phone number' : null),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  maxLength: 50,
                  style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password', counterText: '',
                    prefixIcon: const Icon(Icons.lock_outlined, size: 24, color: LKTheme.gold),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 24, color: LKTheme.textMuted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) { if (v == null || v.isEmpty) return 'Please enter a password'; if (v.length < 6) return 'Password must be at least 6 characters'; return null; },
                ),
                const SizedBox(height: 14),

                _buildField(controller: _confirmPasswordController, label: 'Confirm Password', icon: Icons.lock_outlined, obscureText: true, maxLength: 50,
                  validator: (v) { if (v != _passwordController.text) return 'Passwords do not match'; return null; }),
                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 3))
                        : const Text('Create Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 16, color: LKTheme.textSecondary),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(text: 'Sign In', style: TextStyle(color: LKTheme.gold, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
      decoration: InputDecoration(labelText: label, counterText: '', prefixIcon: Icon(icon, size: 24, color: LKTheme.gold)),
      validator: validator,
    );
  }
}
