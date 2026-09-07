import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/date_helpers.dart';
import '../models/period_log.dart';

class FirebaseCycleRepository {
  FirebaseCycleRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('period_logs');
  }

  Stream<List<PeriodLog>> watchPeriodLogs(String userId) {
    return _collection(userId).snapshots().map((snapshot) {
      final values = <String, PeriodLog>{};
      for (final doc in snapshot.docs) {
        try {
          final log = PeriodLog.fromMap(doc.data());
          values[dateKey(log.startDate)] = log;
        } catch (_) {
          // Ignore malformed documents so one bad record does not break rendering.
        }
      }
      return values.values.toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
    });
  }

  Future<void> addPeriodLog(String userId, PeriodLog log) async {
    final normalized = log.normalized();
    await _collection(
      userId,
    ).doc(dateKey(normalized.startDate)).set(normalized.toMap());
  }
}
