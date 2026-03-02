import '../../data/models/cycle_record.dart';

class CyclePrediction {
  const CyclePrediction({
    required this.averageCycleLength,
    required this.nextPeriodDate,
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
    required this.regularityScore,
  });

  final int averageCycleLength;
  final DateTime? nextPeriodDate;
  final DateTime? ovulationDate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
  final double regularityScore;
}

class CyclePredictor {
  static CyclePrediction fromCycles(List<CycleRecord> cycles) {
    if (cycles.isEmpty) {
      return const CyclePrediction(
        averageCycleLength: 28,
        nextPeriodDate: null,
        ovulationDate: null,
        fertileStart: null,
        fertileEnd: null,
        regularityScore: 0,
      );
    }

    final sorted = [...cycles]..sort((a, b) => a.startDate.compareTo(b.startDate));
    final gaps = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      gaps.add(sorted[i].startDate.difference(sorted[i - 1].startDate).inDays);
    }

    final average = gaps.isEmpty
        ? 28
        : (gaps.reduce((a, b) => a + b) / gaps.length).round();
    final last = sorted.last.startDate;
    final nextPeriod = last.add(Duration(days: average));
    final ovulation = nextPeriod.subtract(const Duration(days: 14));
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation;

    final regularity = _regularityScore(gaps);

    return CyclePrediction(
      averageCycleLength: average,
      nextPeriodDate: nextPeriod,
      ovulationDate: ovulation,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      regularityScore: regularity,
    );
  }

  static double _regularityScore(List<int> values) {
    if (values.length < 2) {
      return 1.0;
    }
    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
            values.length;
    final stdDev = variance.sqrt();
    final normalized = (1 - (stdDev / 10)).clamp(0.0, 1.0);
    return normalized;
  }
}

extension on double {
  double sqrt() {
    if (this <= 0) {
      return 0;
    }
    var x = this;
    var root = 1.0;
    for (var i = 0; i < 20; i++) {
      root = 0.5 * (root + x / root);
    }
    return root;
  }
}
