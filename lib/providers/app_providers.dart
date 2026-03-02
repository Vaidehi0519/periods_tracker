import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

import '../core/services/lock_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/date_helpers.dart';
import '../data/models/app_settings.dart';
import '../data/models/cycle_record.dart';
import '../data/models/symptom_entry.dart';
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

class CycleController extends StateNotifier<List<CycleRecord>> {
  CycleController(this._repository) : super([]) {
    load();
  }

  final CycleRepository _repository;

  void load() {
    state = _repository.getCycles();
  }

  Future<void> addCycle(CycleRecord cycle) async {
    await _repository.addCycle(cycle);
    load();
  }
}

final cyclesProvider = StateNotifierProvider<CycleController, List<CycleRecord>>(
  (ref) => CycleController(ref.watch(cycleRepositoryProvider)),
);

class SymptomController extends StateNotifier<Map<String, SymptomEntry>> {
  SymptomController(this._repository) : super({}) {
    load();
  }

  final SymptomRepository _repository;

  void load() {
    state = _repository.getEntries();
  }

  SymptomEntry? getByDate(DateTime date) {
    return state[dateKey(date)];
  }

  Future<void> upsert(SymptomEntry entry) async {
    await _repository.upsertEntry(entry);
    load();
  }
}

final symptomsProvider =
    StateNotifierProvider<SymptomController, Map<String, SymptomEntry>>(
  (ref) => SymptomController(ref.watch(symptomRepositoryProvider)),
);

final symptomEntriesProvider = Provider<List<SymptomEntry>>((ref) {
  final entries = ref.watch(symptomsProvider).values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return entries;
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._repository, this._notifications)
      : super(AppSettings.defaults()) {
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

final predictionProvider = Provider<CyclePrediction>((ref) {
  final cycles = ref.watch(cyclesProvider);
  return CyclePredictor.fromCycles(cycles);
});

final periodDayKeysProvider = Provider<Set<String>>((ref) {
  final cycles = ref.watch(cyclesProvider);
  final keys = <String>{};

  for (final cycle in cycles) {
    var day = normalizeDate(cycle.startDate);
    final end = normalizeDate(cycle.endDate);
    while (!day.isAfter(end)) {
      keys.add(dateKey(day));
      day = day.add(const Duration(days: 1));
    }
  }
  return keys;
});

final symptomCountsProvider = Provider<Map<String, int>>((ref) {
  final entries = ref.watch(symptomEntriesProvider);
  final counts = <String, int>{};
  for (final entry in entries) {
    for (final symptom in entry.symptoms) {
      counts.update(symptom, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  return counts;
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
    nextPeriodDate: prediction.nextPeriodDate,
    ovulationDate: prediction.ovulationDate,
  );
});
