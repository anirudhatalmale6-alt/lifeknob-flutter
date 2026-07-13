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
    if (!mounted) return;
    // Load translations + admin logos app-wide before navigating, so /home
    // (returning users, who skip onboarding) also gets the admin logos.
    try { await TranslationService().init(); } catch (_) {}
    if (!mounted) return;
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('debug')) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    if (uri.queryParameters.containsKey('reset') || uri.queryParameters.containsKey('preview')) {
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
      backgroundColor: LKTheme.navy,
      body: const SizedBox.shrink(),
    );
  }
}
