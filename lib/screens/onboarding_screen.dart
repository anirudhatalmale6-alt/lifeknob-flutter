import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;
  String? _userCode;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  void _loadCode() {
    final user = AuthService().currentUser;
    if (user != null) {
      setState(() => _userCode = user.userCode);
    }
  }

  void _next() {
    if (_page < 2) {
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter your name');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService().updateSettings({
        'name': name,
        'phone': _phoneController.text.trim(),
      });
      await ApiService().updateProfile({'name': name, 'phone': _phoneController.text.trim()});
      await AuthService().refreshProfile();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: LKTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_rounded, size: 56, color: LKTheme.gold),
              const SizedBox(height: 16),
              Text(msg, style: const TextStyle(fontSize: 20, color: LKTheme.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  width: i == _page ? 28 : 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: i == _page ? LKTheme.gold : LKTheme.border,
                  ),
                )),
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _page == 0
                    ? _buildWelcome()
                    : _page == 1
                        ? _buildCode()
                        : _buildDetails(),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LKTheme.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 3))
                        : Text(
                            _page == 2 ? 'START' : 'NEXT',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF5A3D10), letterSpacing: 1),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LKTheme.goldGradient,
              boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 4)],
            ),
            child: const Icon(Icons.favorite, color: Color(0xFF5A3D10), size: 50),
          ),
          const SizedBox(height: 32),
          const Text('Welcome to', style: TextStyle(fontSize: 20, color: LKTheme.textSecondary)),
          const SizedBox(height: 4),
          const Text('LifeKnob', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 1)),
          const SizedBox(height: 24),
          const Text(
            'Press "I AM OKAY" every day\nto let your family know\nyou are fine.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: LKTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'If you stop pressing,\nyour family will know\nsomething is wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: LKTheme.teal, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCode() {
    return Padding(
      key: const ValueKey('code'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge_rounded, size: 60, color: LKTheme.gold),
          const SizedBox(height: 20),
          const Text('Your Personal Code', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: LKTheme.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LKTheme.gold, width: 2),
              boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.15), blurRadius: 16)],
            ),
            child: Text(
              _userCode ?? '........',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'This is YOUR unique code.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: LKTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Share this code with your family\nso they can connect to you\nand see your status.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: LKTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if (_userCode != null) {
                Clipboard.setData(ClipboardData(text: _userCode!));
                _showMessage('Code copied!');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LKTheme.gold.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 18, color: LKTheme.gold),
                  SizedBox(width: 8),
                  Text('Copy Code', style: TextStyle(fontSize: 16, color: LKTheme.gold, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return SingleChildScrollView(
      key: const ValueKey('details'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.person_rounded, size: 60, color: LKTheme.gold),
          const SizedBox(height: 16),
          const Text('Tell us about you', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('So your family can see your name', style: TextStyle(fontSize: 16, color: LKTheme.textSecondary)),
          const SizedBox(height: 32),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Your Name', style: TextStyle(fontSize: 15, color: LKTheme.gold, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            maxLength: 50,
            style: const TextStyle(fontSize: 22, color: LKTheme.textPrimary, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'e.g. Grandma Rose',
              counterText: '',
              prefixIcon: Icon(Icons.person_rounded, color: LKTheme.gold, size: 24),
            ),
          ),
          const SizedBox(height: 24),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Phone Number (optional)', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 22, color: LKTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: '+61 400 000 000',
              counterText: '',
              prefixIcon: Icon(Icons.phone_rounded, color: LKTheme.textMuted, size: 24),
            ),
          ),
          const SizedBox(height: 16),
          Text('You can add more details later in Systems.', style: TextStyle(fontSize: 14, color: LKTheme.textMuted)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
