enum UserRole {
  farmer,
  officer,
  admin,
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImage;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
  });

  String get roleDisplayName {
    switch (role) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.officer:
        return 'Agricultural Officer';
      case UserRole.admin:
        return 'Admin';
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
      ),
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
    };
  }
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.officer:
        return 'Agricultural Officer';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
