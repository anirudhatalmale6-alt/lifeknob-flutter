import 'package:flutter/material.dart';

class LKTheme {
  static const Color bg = Color(0xFF080C16);
  static const Color bgCard = Color(0xFF111827);
  static const Color bgCardLight = Color(0xFF1A2235);
  static const Color bgCardHover = Color(0xFF1F2942);
  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFEDD87C);
  static const Color goldDark = Color(0xFFB08930);
  static const Color goldSoft = Color(0xFF3D2E14);
  static const Color teal = Color(0xFF4ECDC4);
  static const Color tealDark = Color(0xFF2B9E96);
  static const Color red = Color(0xFFE74C3C);
  static const Color redDark = Color(0xFFC0392B);
  static const Color blue = Color(0xFF3498DB);
  static const Color green = Color(0xFF27AE60);
  static const Color greenSoft = Color(0xFF1A3D2A);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDD87C), Color(0xFFD4A843), Color(0xFFB08930)],
  );

  static const LinearGradient coinGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEDD87C),
      Color(0xFFD4A843),
      Color(0xFFB08930),
      Color(0xFFD4A843),
      Color(0xFFEDD87C),
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE85B5B), Color(0xFFC43434)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B9BD5), Color(0xFF2E6BAE)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF111827), Color(0xFF080C16)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF141D2E), Color(0xFF0F1623)],
  );

  static BoxDecoration get premiumCard => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border, width: 0.5),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
    ],
  );

  static BoxDecoration glassCard({double radius = 20, Color? borderColor}) => BoxDecoration(
    color: const Color(0xFF111827).withValues(alpha: 0.85),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? const Color(0xFF1E293B), width: 0.5),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
    ],
  );
}
