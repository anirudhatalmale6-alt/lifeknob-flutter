import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _currentUser = user;
  }

  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
      return _currentUser;
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<User> login(String email, String password) async {
    final response = await ApiService().login(email, password);
    final token = response['token'] ?? response['data']?['token'] ?? '';
    final userData = response['user'] ?? response['data']?['user'] ?? response['data'] ?? {};

    await _saveToken(token);
    final user = User.fromJson(userData);
    await _saveUser(user);
    return user;
  }

  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await ApiService().register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    final token = response['token'] ?? response['data']?['token'] ?? '';
    final userData = response['user'] ?? response['data']?['user'] ?? response['data'] ?? {};

    await _saveToken(token);
    final user = User.fromJson(userData);
    await _saveUser(user);
    return user;
  }

  Future<User> refreshProfile() async {
    final response = await ApiService().getProfile();
    final userData = response['user'] ?? response['data'] ?? response;
    final user = User.fromJson(userData);
    await _saveUser(user);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _currentUser = null;
  }
}
