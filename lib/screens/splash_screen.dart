import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutBack),
    );

    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();
    _initApp();
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_id');
    if (deviceId == null || deviceId.isEmpty) {
      final rand = Random();
      deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(999999).toString().padLeft(6, '0')}';
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    await TranslationService().init();
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('debug')) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    if (uri.queryParameters.containsKey('reset')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final isLoggedIn = await AuthService().isLoggedIn();
    if (isLoggedIn) {
      final user = await AuthService().getSavedUser();
      if (!mounted) return;
      if (user != null && user.name.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003049),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) {
                    return Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: LKTheme.gold.withValues(alpha: _glowAnim.value * 0.4),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: SvgPicture.asset('assets/images/lifeknoblogo.svg', colorFilter: const ColorFilter.mode(LKTheme.gold, BlendMode.srcIn), fit: BoxFit.contain),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Silence is the alarm',
                  style: TextStyle(
                    fontSize: 16,
                    color: LKTheme.textSecondary.withValues(alpha: 0.7),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: LKTheme.gold.withValues(alpha: 0.6),
                    strokeWidth: 2.5,
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
