import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  static const String _baseUrl = 'https://lifeknob.com/api';
  static const String _cacheKeyPrefix = 'translations_';
  static const String _langKey = 'selected_language';

  Map<String, String> _strings = {};
  String _currentLang = 'en';
  List<Map<String, String>> _availableLanguages = [];

  Map<String, String> _logos = {};

  String get currentLang => _currentLang;
  List<Map<String, String>> get availableLanguages => _availableLanguages;
  Map<String, String> get logos => _logos;

  String? logoUrl(String key) {
    final path = _logos[key];
    if (path == null || path.isEmpty) return null;
    return 'https://lifeknob.com$path';
  }

  String t(String key) => _strings[key] ?? key;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLang = prefs.getString(_langKey) ?? 'en';

    final cachedLangs = prefs.getString('available_languages');
    if (cachedLangs != null) {
      _availableLanguages = (jsonDecode(cachedLangs) as List)
          .map((e) => Map<String, String>.from(e))
          .toList();
    }

    final cached = prefs.getString('$_cacheKeyPrefix$_currentLang');
    if (cached != null) {
      _strings = Map<String, String>.from(jsonDecode(cached));
    }

    if (_strings.isEmpty) {
      await _fetchTranslations(_currentLang);
    } else {
      _fetchTranslations(_currentLang);
    }

    if (_availableLanguages.isEmpty) {
      await _fetchLanguages();
    } else {
      _fetchLanguages();
    }

    await _fetchLogos();
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode == _currentLang) return;
    _currentLang = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);

    final cached = prefs.getString('$_cacheKeyPrefix$langCode');
    if (cached != null) {
      _strings = Map<String, String>.from(jsonDecode(cached));
      _fetchTranslations(langCode);
    } else {
      await _fetchTranslations(langCode);
    }
  }

  Future<void> preloadAll() async {
    final savedLang = _currentLang;
    final savedStrings = Map<String, String>.from(_strings);
    for (final lang in _availableLanguages) {
      final code = lang['code']!;
      if (code == savedLang) continue;
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cacheKeyPrefix$code');
      if (cached == null) {
        await Future.delayed(const Duration(milliseconds: 2000));
        await _fetchTranslations(code);
      }
    }
    _currentLang = savedLang;
    _strings = savedStrings;
  }

  Future<void> _fetchLanguages() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/languages'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == 'success') {
          _availableLanguages = (data['data'] as List)
              .map((e) => {'code': e['code'] as String, 'name': e['name'] as String})
              .toList();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('available_languages', jsonEncode(_availableLanguages));
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchLogos() async {
    try {
      final cacheBust = DateTime.now().millisecondsSinceEpoch;
      final resp = await http.get(Uri.parse('$_baseUrl/logos?v=$cacheBust'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == 'success') {
          _logos = Map<String, String>.from(data['data']);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchTranslations(String langCode) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/translations/$langCode'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == 'success') {
          _strings = Map<String, String>.from(data['data']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('$_cacheKeyPrefix$langCode', jsonEncode(_strings));
        }
      }
    } catch (_) {}
  }
}
