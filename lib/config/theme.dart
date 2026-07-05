import 'package:flutter/material.dart';

class LKTheme {
  static const Color bg = Color(0xFF080B14);
  static const Color bgCard = Color(0xFF0C1120);
  static const Color bgCardLight = Color(0xFF111827);
  static const Color bgCardHover = Color(0xFF1A2235);
  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFF0D97C);
  static const Color goldDark = Color(0xFFB08930);
  static const Color goldShadow = Color(0xFF6B4D1E);
  static const Color silver = Color(0xFFADB5C0);
  static const Color silverLight = Color(0xFFCCD2DA);
  static const Color silverDark = Color(0xFF8690A0);
  static const Color teal = Color(0xFF4ECDC4);
  static const Color tealDark = Color(0xFF2B9E96);
  static const Color red = Color(0xFFE74C3C);
  static const Color redDark = Color(0xFFC0392B);
  static const Color blue = Color(0xFF3498DB);
  static const Color green = Color(0xFF27AE60);
  static const Color textPrimary = Color(0xFFE8DCC8);
  static const Color textSecondary = Color(0xFF8A7E6A);
  static const Color textMuted = Color(0xFF4A4A5A);
  static const Color border = Color(0xFF1E293B);
  static const Color borderGold = Color(0xFF2A2218);

  static TextStyle heading({double size = 20, FontWeight weight = FontWeight.w700, Color color = textPrimary}) {
    return TextStyle(fontFamily: 'Cinzel', fontSize: size, fontWeight: weight, color: color, letterSpacing: 3);
  }

  static TextStyle body({double size = 16, FontWeight weight = FontWeight.w500, Color color = textPrimary}) {
    return TextStyle(fontFamily: 'CormorantGaramond', fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle label({double size = 12, FontWeight weight = FontWeight.w600, Color color = gold}) {
    return TextStyle(fontFamily: 'Cinzel', fontSize: size, fontWeight: weight, color: color, letterSpacing: 2);
  }

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0D97C), Color(0xFFD4A843), Color(0xFFB08930)],
  );

  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCCD2DA), Color(0xFFADB5C0), Color(0xFF8690A0)],
  );

  static const LinearGradient coinGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDD87C), Color(0xFFD4A843), Color(0xFFB08930), Color(0xFFD4A843), Color(0xFFEDD87C)],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A1515), Color(0xFF251010)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF162035), Color(0xFF0E1525)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C1120), Color(0xFF080B14)],
  );

  static BoxDecoration get premiumCard => BoxDecoration(
    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF111827), Color(0xFF0C1120)]),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFF1A1A28), width: 0.5),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
  );

  static BoxDecoration glassCard({double radius = 20, Color? borderColor}) => BoxDecoration(
    color: const Color(0xFF0C1120).withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? const Color(0xFF1A1A28), width: 0.5),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
  );

  static BoxDecoration get goldBorderCard => BoxDecoration(
    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF111827), Color(0xFF0C1120)]),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: gold.withValues(alpha: 0.15), width: 1),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
      BoxShadow(color: gold.withValues(alpha: 0.03), blurRadius: 20),
    ],
  );
}
