import 'user.dart';

class Room {
  final String id;
  final String name;
  final String roomNumber;
  final String type;
  final int floor;
  final int capacity;
  final Department? department;
  final User? invigilator;

  Room({
    required this.id,
    required this.name,
    required this.roomNumber,
    required this.type,
    this.floor = 1,
    this.capacity = 0,
    this.department,
    this.invigilator,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      type: json['type'] ?? 'classroom',
      floor: json['floor'] ?? 1,
      capacity: json['capacity'] ?? 0,
      department: json['department'] != null && json['department'] is Map
          ? Department.fromJson(json['department'])
          : null,
      invigilator: json['invigilator'] != null && json['invigilator'] is Map
          ? User.fromJson(json['invigilator'])
          : null,
    );
  }
}
