import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // Load admin-configured colours before the first frame so the app paints in
  // the right palette. Applies cached colours instantly, then tries the network
  // (short timeout); either way it never blocks startup for long.
  await _loadRemoteColours();

  runApp(const LifeKnobApp());
}

const _kColourCacheKey = 'lk_theme_colours';
const _kColourKeys = ['color_bg', 'color_accent', 'color_text', 'color_alert', 'color_ok'];

Future<void> _loadRemoteColours() async {
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kColourCacheKey);
    if (cached != null) {
      LKTheme.applyRemote(Map<String, dynamic>.from(jsonDecode(cached)));
    }
  } catch (_) {/* ignore cache errors, defaults stay */}

  try {
    final resp = await http
        .get(Uri.parse('https://lifeknob.com/api/site-settings'))
        .timeout(const Duration(seconds: 3));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data['data'] is Map) {
        final all = Map<String, dynamic>.from(data['data']);
        final colours = {for (final k in _kColourKeys) if (all[k] != null) k: all[k]};
        LKTheme.applyRemote(colours);
        try {
          await prefs?.setString(_kColourCacheKey, jsonEncode(colours));
        } catch (_) {}
      }
    }
  } catch (_) {/* offline / timeout: keep cached or default colours */}
}

class LifeKnobApp extends StatelessWidget {
  const LifeKnobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeKnob',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: LKTheme.gold,
        scaffoldBackgroundColor: LKTheme.bg,
        colorScheme: ColorScheme.dark(
          primary: LKTheme.gold,
          secondary: LKTheme.teal,
          surface: LKTheme.bgCard,
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontFamily: 'OpenSans', fontSize: 32, fontWeight: FontWeight.w500, color: LKTheme.textPrimary),
          headlineMedium: TextStyle(fontFamily: 'OpenSans', fontSize: 24, fontWeight: FontWeight.w500, color: LKTheme.textPrimary),
          bodyLarge: TextStyle(fontFamily: 'OpenSans', fontSize: 18, color: LKTheme.textPrimary),
          bodyMedium: TextStyle(fontFamily: 'OpenSans', fontSize: 16, color: LKTheme.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: LKTheme.gold,
            foregroundColor: const Color(0xFF5A3D10),
            textStyle: const TextStyle(fontFamily: 'OpenSans', fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: LKTheme.bgCardLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LKTheme.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: LKTheme.gold.withValues(alpha: 0.15))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: LKTheme.gold, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(fontFamily: 'OpenSans', fontSize: 16, color: LKTheme.textSecondary),
          hintStyle: const TextStyle(fontFamily: 'OpenSans', fontSize: 16, color: LKTheme.textMuted),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}
