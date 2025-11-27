class User {
  final String id;
  final String name;
  final String email;
  final String role; // Storing as simple String for Firestore

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // Send data to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  // Receive data from Firestore
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'farmer',
    );
  }
  
  // Helper for UI
  String get roleDisplayName {
    if (role.isEmpty) return 'Farmer';
    return role[0].toUpperCase() + role.substring(1);
  }
}

// Helper Enum for your UI logic
enum UserRole { farmer, expert, admin }

extension UserRoleExtension on UserRole {
  String get displayName {
    return toString().split('.').last;
  }
}