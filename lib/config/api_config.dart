class ApiConfig {
  static const String baseUrl = 'https://lifeknob.com/api';

  static const Map<String, String> endpoints = {
    'login': '/auth/login',
    'register': '/auth/register',
    'checkIn': '/checkin',
    'history': '/checkin/history',
    'latestConnections': '/checkin/connections',
    'connect': '/connection/connect',
    'disconnect': '/connection/disconnect',
    'connections': '/connection/mine',
    'watchers': '/connection/watchers',
    'connectionInfo': '/connection/info',
    'profile': '/profile',
    'updateProfile': '/profile',
    'settings': '/settings',
    'updateSettings': '/settings',
    'alerts': '/alerts',
    'activeAlerts': '/alerts/active',
    'uploadAvatar': '/profile/avatar',
  };

  static String getUrl(String endpoint) {
    return '$baseUrl${endpoints[endpoint] ?? endpoint}';
  }
}
