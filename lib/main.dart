import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
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

  runApp(const LifeKnobApp());
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
        colorScheme: const ColorScheme.dark(
          primary: LKTheme.gold,
          secondary: LKTheme.teal,
          surface: LKTheme.bgCard,
        ),
        textTheme: GoogleFonts.cinzelTextTheme(const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: LKTheme.textPrimary),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LKTheme.textPrimary),
          bodyLarge: TextStyle(fontSize: 18, color: LKTheme.textPrimary),
          bodyMedium: TextStyle(fontSize: 16, color: LKTheme.textPrimary),
        )),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: LKTheme.gold,
            foregroundColor: const Color(0xFF5A3D10),
            textStyle: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: LKTheme.bgCardLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LKTheme.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: LKTheme.gold.withValues(alpha: 0.15))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LKTheme.gold, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: GoogleFonts.cormorantGaramond(fontSize: 16, color: LKTheme.textSecondary),
          hintStyle: GoogleFonts.cormorantGaramond(fontSize: 16, color: LKTheme.textMuted),
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
