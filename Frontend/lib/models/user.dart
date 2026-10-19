class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final Department? department;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.department,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      department: json['department'] != null && json['department'] is Map
          ? Department.fromJson(json['department'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'department': department?.toJson(),
      };
}

class Department {
  final String id;
  final String name;
  final String code;
  final String? description;

  Department({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'description': description,
      };
}
