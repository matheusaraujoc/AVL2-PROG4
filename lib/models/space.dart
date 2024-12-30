class Space {
  final String id;
  final String name;
  final int capacity;
  final bool isActive;
  final List<String> availableSlots;

  Space({
    required this.id,
    required this.name,
    required this.capacity,
    required this.isActive,
    required this.availableSlots,
  });

  factory Space.fromJson(String id, Map<String, dynamic> json) {
    return Space(
      id: id,
      name: json['name'],
      capacity: json['capacity'],
      isActive: json['isActive'],
      availableSlots: List<String>.from(json['availableSlots']),
    );
  }

  Space copyWith({
    String? id,
    String? name,
    int? capacity,
    bool? isActive,
    List<String>? availableSlots,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      availableSlots: availableSlots ?? this.availableSlots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'capacity': capacity,
      'isActive': isActive,
      'availableSlots': availableSlots,
    };
  }
}
