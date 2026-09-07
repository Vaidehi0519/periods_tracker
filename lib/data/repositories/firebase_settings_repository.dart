import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_settings.dart';

class FirebaseSettingsRepository {
  FirebaseSettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String userId) {
    return _firestore.collection('users').doc(userId).collection('meta').doc('settings');
  }

  Stream<AppSettings> watchSettings(String userId) {
    return _document(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return AppSettings.defaults();
      }
      return AppSettings.fromMap(data);
    });
  }

  Future<void> saveSettings(String userId, AppSettings settings) async {
    await _document(userId).set(settings.toMap());
  }
}
