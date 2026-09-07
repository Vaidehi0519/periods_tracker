import '../../core/utils/date_helpers.dart';
import '../../data/models/cycle.dart';
import '../../data/models/period_log.dart';
import '../../data/models/symptoms.dart';

class CyclePrediction {
  const CyclePrediction({
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.cycleLengths,
    required this.nextPeriodStart,
    required this.nextPeriodEnd,
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
    required this.regularityScore,
    required this.trendDelta,
  });

  final int averageCycleLength;
  final int averagePeriodDuration;
  final List<int> cycleLengths;
  final DateTime? nextPeriodStart;
  final DateTime? nextPeriodEnd;
  final DateTime? ovulationDate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
  final double regularityScore;
  final int trendDelta;

  bool get hasPrediction => nextPeriodStart != null;

  DateTime? get nextPeriodDate => nextPeriodStart;
}

class CycleAnalytics {
  const CycleAnalytics({
    required this.prediction,
    required this.cycles,
    required this.symptomCounts,
  });

  final CyclePrediction prediction;
  final List<Cycle> cycles;
  final Map<String, int> symptomCounts;
}

class CyclePredictor {
  static const int _defaultCycleLength = 28;
  static const int _defaultPeriodDuration = 5;
  static const int _lutealPhaseLength = 14;

  static CyclePrediction fromPeriodLogs(
    List<PeriodLog> logs, {
    int? fallbackCycleLength,
    int? fallbackPeriodDuration,
  }) {
    final safeCycleLength = _sanitizeCycleLength(fallbackCycleLength);
    final safePeriodDuration = _sanitizePeriodDuration(fallbackPeriodDuration);
    final normalized = logs.map((log) => log.normalized()).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (normalized.isEmpty) {
      return CyclePrediction(
        averageCycleLength: safeCycleLength,
        averagePeriodDuration: safePeriodDuration,
        cycleLengths: <int>[],
        nextPeriodStart: null,
        nextPeriodEnd: null,
        ovulationDate: null,
        fertileStart: null,
        fertileEnd: null,
        regularityScore: 0,
        trendDelta: 0,
      );
    }

    final deduped = <String, PeriodLog>{};
    for (final log in normalized) {
      deduped[dateKey(log.startDate)] = log;
    }
    final sorted = deduped.values.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final cycleLengths = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      final days = sorted[i].startDate
          .difference(sorted[i - 1].startDate)
          .inDays;
      if (days >= 15 && days <= 60) {
        cycleLengths.add(days);
      }
    }

    final weightedCycleLength = cycleLengths.isEmpty
        ? safeCycleLength
        : _weightedAverage(cycleLengths.takeLast(6));

    final periodDurations = sorted
        .map((log) => log.periodDuration)
        .where((days) => days >= 1 && days <= 14)
        .toList();
    final averagePeriodDuration = periodDurations.isEmpty
        ? safePeriodDuration
        : (periodDurations.reduce((a, b) => a + b) / periodDurations.length)
              .round();

    final lastPeriodStart = sorted.last.startDate;
    final today = normalizeDate(DateTime.now());
    var nextPeriodStart = normalizeDate(
      lastPeriodStart.add(Duration(days: weightedCycleLength)),
    );
    while (!nextPeriodStart.isAfter(today)) {
      nextPeriodStart = normalizeDate(
        nextPeriodStart.add(Duration(days: weightedCycleLength)),
      );
    }

    final nextPeriodEnd = normalizeDate(
      nextPeriodStart.add(Duration(days: averagePeriodDuration - 1)),
    );
    final ovulation = nextPeriodStart.subtract(
      const Duration(days: _lutealPhaseLength),
    );
    final fertileStart = ovulation.subtract(const Duration(days: 5));

    return CyclePrediction(
      averageCycleLength: weightedCycleLength,
      averagePeriodDuration: averagePeriodDuration,
      cycleLengths: cycleLengths,
      nextPeriodStart: nextPeriodStart,
      nextPeriodEnd: nextPeriodEnd,
      ovulationDate: ovulation,
      fertileStart: fertileStart,
      fertileEnd: ovulation,
      regularityScore: _regularityScore(cycleLengths),
      trendDelta: _trendDelta(cycleLengths),
    );
  }

  static CycleAnalytics buildAnalytics({
    required List<PeriodLog> periodLogs,
    required List<Symptoms> symptomLogs,
    int? fallbackCycleLength,
    int? fallbackPeriodDuration,
  }) {
    final prediction = fromPeriodLogs(
      periodLogs,
      fallbackCycleLength: fallbackCycleLength,
      fallbackPeriodDuration: fallbackPeriodDuration,
    );

    final sortedPeriods =
        periodLogs.map((period) => period.normalized()).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final sortedSymptoms =
        symptomLogs.map((entry) => entry.normalized()).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final cycles = <Cycle>[];
    for (var i = 0; i < sortedPeriods.length; i++) {
      final period = sortedPeriods[i];
      final nextStart = i < sortedPeriods.length - 1
          ? sortedPeriods[i + 1].startDate
          : null;
      final cycleLength = nextStart?.difference(period.startDate).inDays;
      final cycleEnd = nextStart == null
          ? period.endDate
          : nextStart.subtract(const Duration(days: 1));
      final entries = sortedSymptoms
          .where(
            (symptom) =>
                !symptom.date.isBefore(period.startDate) &&
                !symptom.date.isAfter(cycleEnd),
          )
          .toList(growable: false);
      cycles.add(
        Cycle.fromPeriodLog(
          log: period,
          cycleLength: cycleLength,
          symptoms: entries,
        ),
      );
    }

    final counts = <String, int>{};
    for (final symptom in sortedSymptoms) {
      for (final item in symptom.items) {
        counts.update(item, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    return CycleAnalytics(
      prediction: prediction,
      cycles: cycles,
      symptomCounts: counts,
    );
  }

  static int _weightedAverage(List<int> values) {
    var denominator = 0;
    var numerator = 0;
    for (var i = 0; i < values.length; i++) {
      final weight = i + 1;
      numerator += values[i] * weight;
      denominator += weight;
    }
    return (numerator / denominator).round();
  }

  static double _regularityScore(List<int> cycleLengths) {
    if (cycleLengths.length < 2) {
      return 1;
    }

    final avg = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final variance =
        cycleLengths
            .map((value) => (value - avg) * (value - avg))
            .reduce((a, b) => a + b) /
        cycleLengths.length;
    final stdDev = variance.sqrt();

    final normalized = 1 - (stdDev / 8.0);
    return normalized.clamp(0.0, 1.0);
  }

  static int _trendDelta(List<int> cycleLengths) {
    if (cycleLengths.length < 2) {
      return 0;
    }
    final slice = cycleLengths.takeLast(4);
    return slice.last - slice.first;
  }

  static int _sanitizeCycleLength(int? value) {
    final candidate = value ?? _defaultCycleLength;
    return candidate.clamp(21, 45);
  }

  static int _sanitizePeriodDuration(int? value) {
    final candidate = value ?? _defaultPeriodDuration;
    return candidate.clamp(2, 10);
  }
}

extension _TakeLast<E> on List<E> {
  List<E> takeLast(int count) {
    if (isEmpty) {
      return <E>[];
    }
    if (length <= count) {
      return [...this];
    }
    return sublist(length - count);
  }
}

extension on double {
  double sqrt() {
    if (this <= 0) {
      return 0;
    }
    var root = this / 2;
    for (var i = 0; i < 12; i++) {
      root = 0.5 * (root + this / root);
    }
    return root;
  }
}
