class Connection {
  final int id;
  final int userId;
  final String name;
  final String userCode;
  final String? avatar;
  final String status;
  final DateTime? lastCheckIn;
  final String? lastCheckInType;

  Connection({
    required this.id,
    required this.userId,
    required this.name,
    required this.userCode,
    this.avatar,
    this.status = 'accepted',
    this.lastCheckIn,
    this.lastCheckInType,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      userCode: json['user_code'] ?? '',
      avatar: json['avatar'],
      status: json['status'] ?? 'accepted',
      lastCheckIn: json['last_check_in'] != null
          ? DateTime.parse(json['last_check_in'])
          : null,
      lastCheckInType: json['last_check_in_type'],
    );
  }

  String get lastCheckInText {
    if (lastCheckIn == null) return 'Waiting for first check-in';
    final diff = DateTime.now().difference(lastCheckIn!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastCheckIn!.day}/${lastCheckIn!.month}/${lastCheckIn!.year}';
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  static int alertThresholdDays = 2;

  bool get isOverdue {
    if (!isAccepted) return false;
    if (lastCheckIn == null) return false;
    return DateTime.now().difference(lastCheckIn!).inHours > (alertThresholdDays * 24);
  }
}
