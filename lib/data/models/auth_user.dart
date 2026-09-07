class AuthUser {
  const AuthUser({
    required this.email,
    required this.name,
    required this.password,
    required this.createdAt,
  });

  final String email;
  final String name;
  final String password;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthUser.fromMap(Map<dynamic, dynamic> map) {
    return AuthUser(
      email: (map['email'] as String? ?? '').trim().toLowerCase(),
      name: (map['name'] as String? ?? '').trim(),
      password: map['password'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
