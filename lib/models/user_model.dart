class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String role; // "user" or "admin"
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.role,
    required this.createdAt,
  }) {
    // Validate role
    if (role != 'user' && role != 'admin') {
      throw ArgumentError('Role must be either "user" or "admin"');
    }
  }

  /// Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt(dynamic value) {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is DateTime) {
        return value;
      } else if (value != null && value.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    // Normalize role to lowercase for consistency
    final roleString = json['role'] as String? ?? 'user';
    final normalizedRole = roleString.toLowerCase() == 'admin' ? 'admin' : 'user';
    
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      role: normalizedRole,
      createdAt: parseCreatedAt(json['createdAt']),
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if user is an admin
  bool get isAdmin => role == 'admin';

  /// Check if user is a regular user
  bool get isUser => role == 'user';

  /// Get user's initials for avatar display
  String get initials {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// User role constants for type safety
class UserRole {
  static const String user = 'user';
  static const String admin = 'admin';
}

