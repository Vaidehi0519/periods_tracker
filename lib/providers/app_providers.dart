import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

import '../core/services/lock_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/date_helpers.dart';
import '../data/models/app_settings.dart';
import '../data/models/period_log.dart';
import '../data/models/symptoms.dart';
import '../data/repositories/cycle_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/symptom_repository.dart';
import '../domain/services/cycle_predictor.dart';

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  return CycleRepository(Hive.box<dynamic>('cycles'));
});

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  return SymptomRepository(Hive.box<dynamic>('symptoms'));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(Hive.box<dynamic>('settings'));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});

final lockServiceProvider = Provider<LockService>((ref) {
  return LockService(LocalAuthentication());
});

class CycleController extends StateNotifier<List<PeriodLog>> {
  CycleController(this._repository) : super(const <PeriodLog>[]) {
    load();
  }

  final CycleRepository _repository;

  void load() {
    state = _repository.getPeriodLogs();
  }

  Future<void> addCycle(PeriodLog cycle) async {
    final normalized = cycle.normalized();
    await _repository.addPeriodLog(normalized);

    final next = [...state.where((item) => dateKey(item.startDate) != dateKey(normalized.startDate)), normalized]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    state = next;
  }
}

final cyclesProvider = StateNotifierProvider<CycleController, List<PeriodLog>>(
  (ref) => CycleController(ref.watch(cycleRepositoryProvider)),
);

class SymptomController extends StateNotifier<Map<String, Symptoms>> {
  SymptomController(this._repository) : super(const <String, Symptoms>{}) {
    load();
  }

  final SymptomRepository _repository;

  void load() {
    state = _repository.getEntries();
  }

  Symptoms? getByDate(DateTime date) {
    return state[dateKey(normalizeDate(date))];
  }

  Future<void> upsert(Symptoms entry) async {
    final normalized = entry.normalized();
    await _repository.upsertEntry(normalized);
    state = {...state, dateKey(normalized.date): normalized};
  }
}

final symptomsProvider = StateNotifierProvider<SymptomController, Map<String, Symptoms>>(
  (ref) => SymptomController(ref.watch(symptomRepositoryProvider)),
);

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._repository, this._notifications) : super(AppSettings.defaults()) {
    load();
  }

  final SettingsRepository _repository;
  final NotificationService _notifications;

  Future<void> load() async {
    state = _repository.getSettings();
    await _notifications.scheduleDailyLogReminder(state.dailyLogReminder);
  }

  Future<void> update(AppSettings next) async {
    state = next;
    await _repository.saveSettings(next);
    await _notifications.scheduleDailyLogReminder(next.dailyLogReminder);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(
    ref.watch(settingsRepositoryProvider),
    ref.watch(notificationServiceProvider),
  ),
);

final analyticsProvider = Provider<CycleAnalytics>((ref) {
  final periods = ref.watch(cyclesProvider);
  final symptoms = ref.watch(symptomsProvider).values.toList(growable: false);
  return CyclePredictor.buildAnalytics(periodLogs: periods, symptomLogs: symptoms);
});

final predictionProvider = Provider<CyclePrediction>((ref) {
  return ref.watch(analyticsProvider).prediction;
});

final cycleLengthsProvider = Provider<List<int>>((ref) {
  return ref.watch(predictionProvider).cycleLengths;
});

final periodDayKeysProvider = Provider<Set<String>>((ref) {
  final periods = ref.watch(cyclesProvider);
  final keys = <String>{};

  for (final period in periods) {
    var day = normalizeDate(period.startDate);
    final end = normalizeDate(period.endDate);
    while (!day.isAfter(end)) {
      keys.add(dateKey(day));
      day = day.add(const Duration(days: 1));
    }
  }
  return keys;
});

final predictedPeriodDayKeysProvider = Provider<Set<String>>((ref) {
  final prediction = ref.watch(predictionProvider);
  final start = prediction.nextPeriodStart;
  final end = prediction.nextPeriodEnd;
  if (start == null || end == null) {
    return const <String>{};
  }

  final keys = <String>{};
  var day = normalizeDate(start);
  while (!day.isAfter(normalizeDate(end))) {
    keys.add(dateKey(day));
    day = day.add(const Duration(days: 1));
  }
  return keys;
});

final ovulationDayKeyProvider = Provider<String?>((ref) {
  final ovulationDate = ref.watch(predictionProvider).ovulationDate;
  if (ovulationDate == null) {
    return null;
  }
  return dateKey(normalizeDate(ovulationDate));
});

final fertileDayKeysProvider = Provider<Set<String>>((ref) {
  final prediction = ref.watch(predictionProvider);
  final start = prediction.fertileStart;
  final end = prediction.fertileEnd;
  if (start == null || end == null) {
    return const <String>{};
  }

  final keys = <String>{};
  var current = normalizeDate(start);
  final last = normalizeDate(end);
  while (!current.isAfter(last)) {
    keys.add(dateKey(current));
    current = current.add(const Duration(days: 1));
  }
  return keys;
});

final symptomCountsProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(analyticsProvider).symptomCounts;
});

class ReminderPayload {
  const ReminderPayload({
    required this.periodEnabled,
    required this.ovulationEnabled,
    required this.nextPeriodDate,
    required this.ovulationDate,
  });

  final bool periodEnabled;
  final bool ovulationEnabled;
  final DateTime? nextPeriodDate;
  final DateTime? ovulationDate;
}

final reminderPayloadProvider = Provider<ReminderPayload>((ref) {
  final settings = ref.watch(settingsProvider);
  final prediction = ref.watch(predictionProvider);
  return ReminderPayload(
    periodEnabled: settings.periodReminders,
    ovulationEnabled: settings.ovulationReminders,
    nextPeriodDate: prediction.nextPeriodStart,
    ovulationDate: prediction.ovulationDate,
  );
});
