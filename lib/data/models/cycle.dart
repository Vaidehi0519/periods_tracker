import 'period_log.dart';
import 'symptoms.dart';

class Cycle {
  const Cycle({
    required this.startDate,
    required this.endDate,
    required this.periodDuration,
    required this.cycleLength,
    required this.symptoms,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int periodDuration;
  final int? cycleLength;
  final List<Symptoms> symptoms;

  factory Cycle.fromPeriodLog({
    required PeriodLog log,
    required int? cycleLength,
    required List<Symptoms> symptoms,
  }) {
    final normalized = log.normalized();
    return Cycle(
      startDate: normalized.startDate,
      endDate: normalized.endDate,
      periodDuration: normalized.periodDuration,
      cycleLength: cycleLength,
      symptoms: symptoms,
    );
  }
}
