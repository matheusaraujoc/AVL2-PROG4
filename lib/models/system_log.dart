class SystemLog {
  final String id;
  final String action;
  final String userId;
  final String userName;
  final String details;
  final DateTime timestamp;

  SystemLog({
    required this.id,
    required this.action,
    required this.userId,
    required this.userName,
    required this.details,
    required this.timestamp,
  });

  factory SystemLog.fromJson(String id, Map<String, dynamic> json) {
    return SystemLog(
      id: id,
      action: json['action'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      details: json['details'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'userId': userId,
      'userName': userName,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
