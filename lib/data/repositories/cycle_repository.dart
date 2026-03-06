import 'package:hive/hive.dart';

import '../../core/utils/date_helpers.dart';
import '../models/period_log.dart';

class CycleRepository {
  CycleRepository(this._box);

  final Box<dynamic> _box;

  List<PeriodLog> getPeriodLogs() {
    final dedupedByStart = <String, PeriodLog>{};
    for (final value in _box.values) {
      try {
        final log = PeriodLog.fromMap(Map<dynamic, dynamic>.from(value as Map));
        dedupedByStart[dateKey(log.startDate)] = log;
      } catch (_) {
        // Ignore malformed records so one bad row does not break all tracking.
      }
    }
    return dedupedByStart.values.toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<void> addPeriodLog(PeriodLog periodLog) async {
    final normalized = periodLog.normalized();
    await _box.put(dateKey(normalized.startDate), normalized.toMap());
  }
}
