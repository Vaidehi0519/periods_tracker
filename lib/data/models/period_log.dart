import '../../core/utils/date_helpers.dart';

class PeriodLog {
  PeriodLog({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  int get periodDuration => normalizeDate(endDate).difference(normalizeDate(startDate)).inDays + 1;

  PeriodLog normalized() {
    final normalizedStart = normalizeDate(startDate);
    final normalizedEnd = normalizeDate(endDate);
    return normalizedStart.isAfter(normalizedEnd)
        ? PeriodLog(startDate: normalizedEnd, endDate: normalizedStart)
        : PeriodLog(startDate: normalizedStart, endDate: normalizedEnd);
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': normalizeDate(startDate).toIso8601String(),
      'endDate': normalizeDate(endDate).toIso8601String(),
    };
  }

  factory PeriodLog.fromMap(Map<dynamic, dynamic> map) {
    final startRaw = map['startDate'];
    final endRaw = map['endDate'];
    final start = DateTime.parse((startRaw ?? endRaw) as String);
    final end = DateTime.parse((endRaw ?? startRaw) as String);
    return PeriodLog(startDate: start, endDate: end).normalized();
  }
}
