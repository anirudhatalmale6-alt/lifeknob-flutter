class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String userCode;
  final String plan; // 'free' or 'paid'
  final int maxConnections;
  final int usedConnections;
  final String? sosNumber;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userCode,
    this.plan = 'free',
    this.maxConnections = 1,
    this.usedConnections = 0,
    this.sosNumber,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userCode: json['user_code'] ?? '',
      plan: json['plan'] ?? 'free',
      maxConnections: json['max_connections'] ?? 1,
      usedConnections: json['used_connections'] ?? 0,
      sosNumber: json['sos_number'],
      quietHoursEnabled: json['quiet_hours_enabled'] == true || json['quiet_hours_enabled'] == 1,
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'user_code': userCode,
      'plan': plan,
      'max_connections': maxConnections,
      'used_connections': usedConnections,
      'sos_number': sosNumber,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
    };
  }

  bool get isFree => plan == 'free';
  bool get isPaid => plan == 'paid';
  bool get canAddConnection => usedConnections < maxConnections;
}
