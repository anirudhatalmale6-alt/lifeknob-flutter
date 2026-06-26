import 'package:flutter/material.dart';

class LKTheme {
  static const Color bg = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF141929);
  static const Color bgCardLight = Color(0xFF1C2237);
  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFE8C96A);
  static const Color goldDark = Color(0xFFB08930);
  static const Color teal = Color(0xFF4ECDC4);
  static const Color red = Color(0xFFE74C3C);
  static const Color redDark = Color(0xFFC0392B);
  static const Color blue = Color(0xFF3498DB);
  static const Color green = Color(0xFF27AE60);
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF8892A0);
  static const Color textMuted = Color(0xFF5A6270);
  static const Color border = Color(0xFF2A3040);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C96A), Color(0xFFD4A843), Color(0xFFB08930)],
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
}
