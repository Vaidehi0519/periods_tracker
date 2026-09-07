import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/date_helpers.dart';
import '../models/symptoms.dart';

class FirebaseSymptomRepository {
  FirebaseSymptomRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('symptoms');
  }

  Stream<Map<String, Symptoms>> watchEntries(String userId) {
    return _collection(userId).snapshots().map((snapshot) {
      final entries = <String, Symptoms>{};
      for (final doc in snapshot.docs) {
        try {
          final symptom = Symptoms.fromMap(doc.data());
          entries[dateKey(symptom.date)] = symptom;
        } catch (_) {
          // Ignore malformed documents to keep the rest of the app responsive.
        }
      }
      return entries;
    });
  }

  Future<void> upsertEntry(String userId, Symptoms entry) async {
    final normalized = entry.normalized();
    await _collection(
      userId,
    ).doc(dateKey(normalized.date)).set(normalized.toMap());
  }
}
