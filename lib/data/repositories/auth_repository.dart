import 'package:hive/hive.dart';

import '../models/auth_user.dart';

class AuthRepository {
  AuthRepository(this._box);

  final Box<dynamic> _box;

  static const String _sessionKey = 'current_user_email';

  AuthUser? getUserByEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final record = _box.get('user::$normalizedEmail');
    if (record == null) {
      return null;
    }
    return AuthUser.fromMap(Map<dynamic, dynamic>.from(record as Map));
  }

  Future<void> saveUser(AuthUser user) async {
    await _box.put('user::${user.email}', user.toMap());
  }

  String? getCurrentUserEmail() {
    return _box.get(_sessionKey) as String?;
  }

  Future<void> saveCurrentUserEmail(String email) async {
    await _box.put(_sessionKey, email.trim().toLowerCase());
  }

  Future<void> clearSession() async {
    await _box.delete(_sessionKey);
  }
}
