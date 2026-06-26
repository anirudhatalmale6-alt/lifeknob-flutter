import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'status': 'success', 'data': []};
      }
      throw ApiException(statusCode: response.statusCode, message: 'Empty response from server');
    }
    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      throw ApiException(statusCode: response.statusCode, message: 'Invalid response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: body is Map ? (body['message'] ?? body['error'] ?? 'Something went wrong') : 'Something went wrong',
      );
    }
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('login')),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('register')),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> autoRegister(String deviceId) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('autoRegister')),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'device_id': deviceId}),
    );
    return _handleResponse(response);
  }

  // Check-In
  Future<Map<String, dynamic>> checkIn({String type = 'ok'}) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('checkIn')),
      headers: await _headers(),
      body: jsonEncode({'type': type}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getHistory({int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.getUrl('history')}?page=$page'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  // Connections
  Future<Map<String, dynamic>> connect(String code) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('connect')),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> disconnect(int connectionId) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('disconnect')),
      headers: await _headers(),
      body: jsonEncode({'connection_id': connectionId}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> acceptRequest(int connectionId) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('acceptRequest')),
      headers: await _headers(),
      body: jsonEncode({'connection_id': connectionId}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> rejectRequest(int connectionId) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('rejectRequest')),
      headers: await _headers(),
      body: jsonEncode({'connection_id': connectionId}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse(ApiConfig.getUrl('pendingRequests')),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateConnectionName(int connectionId, String name) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('updateConnection')),
      headers: await _headers(),
      body: jsonEncode({'connection_id': connectionId, 'name': name}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getSiteSettings() async {
    final response = await http.get(
      Uri.parse(ApiConfig.getUrl('siteSettings')),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getConnections() async {
    final response = await http.get(
      Uri.parse(ApiConfig.getUrl('connections')),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  // Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse(ApiConfig.getUrl('profile')),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('updateProfile')),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUrl('updateSettings')),
      headers: await _headers(),
      body: jsonEncode(settings),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadAvatar(List<int> bytes, String filename) async {
    final token = await AuthService().getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.getUrl('uploadAvatar')),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'avatar',
      bytes,
      filename: filename,
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
