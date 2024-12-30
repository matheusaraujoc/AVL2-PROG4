class Reservation {
  final String id;
  final String spaceId;
  final String userId;
  final String userName;
  final String timeSlot;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.userName,
    required this.timeSlot,
    required this.createdAt,
  });

  factory Reservation.fromJson(String id, Map<String, dynamic> json) {
    return Reservation(
      id: id,
      spaceId: json['spaceId'],
      userId: json['userId'],
      userName: json['userName'],
      timeSlot: json['timeSlot'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spaceId': spaceId,
      'userId': userId,
      'userName': userName,
      'timeSlot': timeSlot,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
