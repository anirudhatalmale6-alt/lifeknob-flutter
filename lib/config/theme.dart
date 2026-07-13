import 'package:flutter/material.dart';

class LKTheme {
  // --- Admin-controllable palette -------------------------------------------
  // These 5 colours can be overridden from the admin panel (site_settings:
  // color_bg / color_accent / color_text / color_alert / color_ok) via
  // applyRemote() at startup. They are NON-const so they can change at runtime;
  // the const *_Default values below back them and are used for defaults.
  static const Color _bgDefault   = Color(0xFF080B14); // main app screens (near-black navy)
  static const Color _onbgDefault = Color(0xFF003049); // onboarding screens (brand blue)
  static const Color _goldDefault = Color(0xFFD4A843);
  static const Color _textDefault = Color(0xFFE8DCC8);
  static const Color _redDefault  = Color(0xFFE74C3C);
  static const Color _okDefault   = Color(0xFF27AE60);
  static const Color _textSecDefault = Color(0xFF8A7E6A); // 2nd text colour (secondary)

  static Color bg = _bgDefault;
  static Color navy = _onbgDefault; // the visible blue screen background (home/onboarding/login/…)
  static Color gold = _goldDefault;
  static Color red = _redDefault;
  static Color green = _okDefault;
  static Color textPrimary = _textDefault;   // "Text 1" — main letters (color_text)
  static Color textSecondary = _textSecDefault; // "Text 2" — secondary letters (color_text2)
  // --------------------------------------------------------------------------

  static const Color bgCard = Color(0xFF0C1120);
  static const Color bgCardLight = Color(0xFF111827);
  static const Color bgCardHover = Color(0xFF1A2235);
  static const Color goldLight = Color(0xFFF0D97C);
  static const Color goldDark = Color(0xFFB08930);
  static const Color goldShadow = Color(0xFF6B4D1E);
  static const Color silver = Color(0xFFADB5C0);
  static const Color silverLight = Color(0xFFCCD2DA);
  static const Color silverDark = Color(0xFF8690A0);
  static const Color teal = Color(0xFF4ECDC4);
  static const Color tealDark = Color(0xFF2B9E96);
  static const Color redDark = Color(0xFFC0392B);
  static const Color blue = Color(0xFF3498DB);
  static const Color textMuted = Color(0xFF4A4A5A);
  static const Color border = Color(0xFF1E293B);
  static const Color borderGold = Color(0xFF2A2218);

  /// Parse a "#RRGGBB" (or "RRGGBB") hex string; return [fallback] if invalid.
  static Color _parseHex(dynamic raw, Color fallback) {
    if (raw is! String) return fallback;
    final h = raw.replaceAll('#', '').trim();
    if (h.length != 6) return fallback;
    final v = int.tryParse('FF$h', radix: 16);
    return v == null ? fallback : Color(v);
  }

  /// Apply admin-panel colours from the /api/site-settings map. Missing or
  /// invalid values fall back to the built-in defaults, so a bad value can
  /// never break rendering.
  static void applyRemote(Map<String, dynamic> s) {
    // A single "Background" control unifies both app backgrounds. When the admin
    // leaves it unset each keeps its own designed default (bg = near-black,
    // navy = brand blue); when set, both follow the chosen colour.
    bg   = _parseHex(s['color_bg'], _bgDefault);
    navy = s['color_bg'] != null ? _parseHex(s['color_bg'], _onbgDefault) : _onbgDefault;
    gold          = _parseHex(s['color_accent'], _goldDefault);
    textPrimary   = _parseHex(s['color_text'],   _textDefault);
    textSecondary = _parseHex(s['color_text2'],  _textSecDefault);
    red           = _parseHex(s['color_alert'],  _redDefault);
    green         = _parseHex(s['color_ok'],     _okDefault);
  }

  static TextStyle heading({double size = 20, FontWeight weight = FontWeight.w700, Color color = _textDefault}) {
    return TextStyle(fontFamily: 'Cinzel', fontSize: size, fontWeight: weight, color: color, letterSpacing: 3);
  }

  static TextStyle body({double size = 16, FontWeight weight = FontWeight.w500, Color color = _textDefault}) {
    return TextStyle(fontFamily: 'CormorantGaramond', fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle label({double size = 12, FontWeight weight = FontWeight.w600, Color color = _goldDefault}) {
    return TextStyle(fontFamily: 'Cinzel', fontSize: size, fontWeight: weight, color: color, letterSpacing: 2);
  }

  // Lighten (amt>0) or darken (amt<0) a colour in HSL space.
  static Color _shift(Color c, double amt) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amt).clamp(0.0, 1.0)).toColor();
  }

  // The gold gradients derive from [gold], so changing the accent colour in the
  // admin panel repaints buttons, the knob and coins to match — not just flat
  // gold text. (Getters, so they always reflect the current [gold].)
  static LinearGradient get goldGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_shift(gold, 0.12), gold, _shift(gold, -0.10)],
  );

  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCCD2DA), Color(0xFFADB5C0), Color(0xFF8690A0)],
  );

  static LinearGradient get coinGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_shift(gold, 0.14), gold, _shift(gold, -0.10), gold, _shift(gold, 0.14)],
    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
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

  // Popup/dialog frame — solid gold border on every dialog (per client design).
  static BoxDecoration dialogFrame({double radius = 24}) => BoxDecoration(
    color: const Color(0xFF0C1120),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: gold, width: 2),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
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
