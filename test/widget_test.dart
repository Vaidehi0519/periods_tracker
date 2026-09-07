import 'package:periods_tracker/core/utils/date_helpers.dart';
import 'package:periods_tracker/data/models/app_settings.dart';
import 'package:periods_tracker/data/models/period_log.dart';
import 'package:periods_tracker/data/models/symptoms.dart';
import 'package:periods_tracker/domain/services/cycle_predictor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppSettings does not serialize local lock secrets or preferences', () {
    final settings = AppSettings.defaults().copyWith(
      darkMode: true,
      onboardingCompleted: true,
      baselineCycleLength: 30,
      baselinePeriodDuration: 4,
    );

    final map = settings.toMap();

    expect(map['darkMode'], isTrue);
    expect(map['onboardingCompleted'], isTrue);
    expect(map['baselineCycleLength'], 30);
    expect(map['baselinePeriodDuration'], 4);
    expect(map.containsKey('pinCode'), isFalse);
    expect(map.containsKey('pinEnabled'), isFalse);
    expect(map.containsKey('biometricEnabled'), isFalse);
  });

  test('PeriodLog normalizes reversed date ranges', () {
    final log = PeriodLog(
      startDate: DateTime(2026, 2, 8, 18),
      endDate: DateTime(2026, 2, 4, 9),
    ).normalized();

    expect(log.startDate, DateTime(2026, 2, 4));
    expect(log.endDate, DateTime(2026, 2, 8));
    expect(log.periodDuration, 5);
    expect(dateKey(log.startDate), '2026-02-04');
  });

  test('Symptoms normalizes date, trims notes, and deduplicates items', () {
    final entry = Symptoms(
      date: DateTime(2026, 3, 12, 22, 15),
      mood: MoodType.tired,
      items: const ['cramps', ' cramps ', '', 'headache'],
      flow: FlowIntensity.heavy,
      notes: '  Needed rest  ',
    ).normalized();

    expect(entry.date, DateTime(2026, 3, 12));
    expect(entry.items, ['cramps', 'headache']);
    expect(entry.notes, 'Needed rest');
  });

  test(
    'CyclePredictor weights recent cycle lengths and derives fertile window',
    () {
      final logs = [
        PeriodLog(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 5),
        ),
        PeriodLog(
          startDate: DateTime(2026, 1, 29),
          endDate: DateTime(2026, 2, 2),
        ),
        PeriodLog(
          startDate: DateTime(2026, 2, 28),
          endDate: DateTime(2026, 3, 3),
        ),
      ];

      final prediction = CyclePredictor.fromPeriodLogs(logs);

      expect(prediction.cycleLengths, [28, 30]);
      expect(prediction.averageCycleLength, 29);
      expect(prediction.averagePeriodDuration, 5);
      expect(prediction.hasPrediction, isTrue);
      expect(
        prediction.fertileStart,
        prediction.ovulationDate?.subtract(const Duration(days: 5)),
      );
      expect(prediction.fertileEnd, prediction.ovulationDate);
    },
  );
}
