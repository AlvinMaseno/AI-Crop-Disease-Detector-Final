import 'dart:convert';

enum UserRole { farmer, expert, admin }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? password; // Only for local validation demo

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.farmer,
    this.password,
  });

  // Convert User to Map (for saving)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last, // 'UserRole.farmer' -> 'farmer'
      'password': password,
    };
  }

  // Create User from Map (for loading)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.farmer,
      ),
      password: map['password'],
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));
}