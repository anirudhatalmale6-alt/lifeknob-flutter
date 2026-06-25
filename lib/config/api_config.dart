class ApiConfig {
  static const String baseUrl = 'https://lifeknob.com/api';

  static const Map<String, String> endpoints = {
    'login': '/auth/login',
    'register': '/auth/register',
    'checkIn': '/checkin',
    'history': '/checkin/history',
    'connect': '/connections/connect',
    'disconnect': '/connections/disconnect',
    'connections': '/connections',
    'profile': '/user/profile',
    'updateSettings': '/user/settings',
  };

  static String getUrl(String endpoint) {
    return '$baseUrl${endpoints[endpoint] ?? endpoint}';
  }
}
