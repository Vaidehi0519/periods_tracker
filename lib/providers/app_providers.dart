import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/services/lock_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/date_helpers.dart';
import '../data/models/app_settings.dart';
import '../data/models/period_log.dart';
import '../data/models/symptoms.dart';
import '../data/repositories/firebase_cycle_repository.dart';
import '../data/repositories/firebase_settings_repository.dart';
import '../data/repositories/firebase_symptom_repository.dart';
import '../domain/services/cycle_predictor.dart';

class FirebaseAppStatus {
  const FirebaseAppStatus({
    required this.isReady,
    this.errorMessage,
  });

  final bool isReady;
  final String? errorMessage;
}

final firebaseAppStatusProvider = Provider<FirebaseAppStatus>((ref) {
  return const FirebaseAppStatus(isReady: false, errorMessage: 'Firebase is not initialized.');
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final cycleRepositoryProvider = Provider<FirebaseCycleRepository>((ref) {
  return FirebaseCycleRepository(ref.watch(firestoreProvider));
});

final symptomRepositoryProvider = Provider<FirebaseSymptomRepository>((ref) {
  return FirebaseSymptomRepository(ref.watch(firestoreProvider));
});

final settingsRepositoryProvider = Provider<FirebaseSettingsRepository>((ref) {
  return FirebaseSettingsRepository(ref.watch(firestoreProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});

final lockServiceProvider = Provider<LockService>((ref) {
  return LockService(LocalAuthentication());
});

class AuthState {
  const AuthState({
    required this.isLoading,
    required this.isLoggedIn,
    required this.firebaseUser,
    required this.isEmailVerified,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final User? firebaseUser;
  final bool isEmailVerified;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    User? firebaseUser,
    bool? isEmailVerified,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory AuthState.initial() {
    return const AuthState(
      isLoading: true,
      isLoggedIn: false,
      firebaseUser: null,
      isEmailVerified: false,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, this._auth) : super(AuthState.initial()) {
    final firebaseStatus = _ref.read(firebaseAppStatusProvider);
    if (!firebaseStatus.isReady || _auth == null) {
      state = AuthState(
        isLoading: false,
        isLoggedIn: false,
        firebaseUser: null,
        isEmailVerified: false,
        errorMessage: firebaseStatus.errorMessage,
      );
      return;
    }

    _subscription = _auth.authStateChanges().listen((user) {
      state = AuthState(
        isLoading: false,
        isLoggedIn: user != null,
        firebaseUser: user,
        isEmailVerified: user?.emailVerified ?? false,
      );
    });
  }

  final Ref _ref;
  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _subscription;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_auth == null) {
      state = state.copyWith(errorMessage: 'Firebase Auth is not available.');
      return false;
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.sendEmailVerification();
      state = AuthState(
        isLoading: false,
        isLoggedIn: credential.user != null,
        firebaseUser: credential.user,
        isEmailVerified: credential.user?.emailVerified ?? false,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(errorMessage: error.message ?? 'Unable to create account.');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (_auth == null) {
      state = state.copyWith(errorMessage: 'Firebase Auth is not available.');
      return false;
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = AuthState(
        isLoading: false,
        isLoggedIn: credential.user != null,
        firebaseUser: credential.user,
        isEmailVerified: credential.user?.emailVerified ?? false,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(errorMessage: error.message ?? 'Unable to sign in.');
      return false;
    }
  }

  Future<void> logout() async {
    if (_auth == null) {
      return;
    }
    await _auth.signOut();
    state = const AuthState(
      isLoading: false,
      isLoggedIn: false,
      firebaseUser: null,
      isEmailVerified: false,
    );
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    if (_auth == null) {
      state = state.copyWith(errorMessage: 'Firebase Auth is not available.');
      return false;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(errorMessage: error.message ?? 'Unable to send reset email.');
      return false;
    }
  }

  Future<bool> sendEmailVerification() async {
    if (_auth == null) {
      state = state.copyWith(errorMessage: 'Firebase Auth is not available.');
      return false;
    }
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(errorMessage: error.message ?? 'Unable to send verification email.');
      return false;
    }
  }

  Future<void> reloadUser() async {
    if (_auth == null) {
      return;
    }
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    state = AuthState(
      isLoading: false,
      isLoggedIn: user != null,
      firebaseUser: user,
      isEmailVerified: user?.emailVerified ?? false,
    );
  }

  Future<bool> updateDisplayName(String name) async {
    if (_auth == null) {
      state = state.copyWith(errorMessage: 'Firebase Auth is not available.');
      return false;
    }
    final trimmed = name.trim();
    if (trimmed.length < 2) {
      state = state.copyWith(errorMessage: 'Name must be at least 2 characters.');
      return false;
    }

    try {
      await _auth.currentUser?.updateDisplayName(trimmed);
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      state = AuthState(
        isLoading: false,
        isLoggedIn: user != null,
        firebaseUser: user,
        isEmailVerified: user?.emailVerified ?? false,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(errorMessage: error.message ?? 'Unable to update profile.');
      return false;
    }
  }

  Future<bool> requestAccountDeletion({required String reason}) async {
    if (_auth == null) {
      state = state.copyWith(errorMessage: 'Firebase is not available.');
      return false;
    }
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(errorMessage: 'No signed-in account found.');
      return false;
    }

    try {
      await _ref.read(firestoreProvider).collection('users').doc(user.uid).collection('meta').doc('deletion_request').set({
        'requestedAt': FieldValue.serverTimestamp(),
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'reason': reason.trim(),
        'status': 'requested',
      });
      return true;
    } on FirebaseException catch (error) {
      state = state.copyWith(errorMessage: error.message ?? 'Unable to create deletion request.');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final firebaseStatus = ref.watch(firebaseAppStatusProvider);
    return AuthController(
      ref,
      firebaseStatus.isReady ? ref.watch(firebaseAuthProvider) : null,
    );
  },
);

final settingsLoadedProvider = StateProvider<bool>((ref) => false);

class CycleController extends StateNotifier<List<PeriodLog>> {
  CycleController(this._ref, this._repository) : super(const <PeriodLog>[]) {
    final auth = _ref.read(authProvider);
    _watchUser(auth.firebaseUser?.uid);
  }

  final Ref _ref;
  final FirebaseCycleRepository _repository;
  StreamSubscription<List<PeriodLog>>? _subscription;

  void _watchUser(String? userId) {
    _subscription?.cancel();
    if (userId == null) {
      state = const <PeriodLog>[];
      return;
    }

    _subscription = _repository.watchPeriodLogs(userId).listen((logs) {
      state = logs;
    });
  }

  void onAuthChanged(String? userId) {
    _watchUser(userId);
  }

  Future<void> addCycle(PeriodLog cycle) async {
    final userId = _ref.read(authProvider).firebaseUser?.uid;
    if (userId == null) {
      return;
    }
    await _repository.addPeriodLog(userId, cycle);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final cyclesProvider = StateNotifierProvider<CycleController, List<PeriodLog>>(
  (ref) {
    final controller = CycleController(ref, ref.watch(cycleRepositoryProvider));
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.firebaseUser?.uid != next.firebaseUser?.uid) {
        controller.onAuthChanged(next.firebaseUser?.uid);
      }
    });
    return controller;
  },
);

class SymptomController extends StateNotifier<Map<String, Symptoms>> {
  SymptomController(this._ref, this._repository) : super(const <String, Symptoms>{}) {
    final auth = _ref.read(authProvider);
    _watchUser(auth.firebaseUser?.uid);
  }

  final Ref _ref;
  final FirebaseSymptomRepository _repository;
  StreamSubscription<Map<String, Symptoms>>? _subscription;

  void _watchUser(String? userId) {
    _subscription?.cancel();
    if (userId == null) {
      state = const <String, Symptoms>{};
      return;
    }

    _subscription = _repository.watchEntries(userId).listen((entries) {
      state = entries;
    });
  }

  void onAuthChanged(String? userId) {
    _watchUser(userId);
  }

  Symptoms? getByDate(DateTime date) {
    return state[dateKey(normalizeDate(date))];
  }

  Future<void> upsert(Symptoms entry) async {
    final userId = _ref.read(authProvider).firebaseUser?.uid;
    if (userId == null) {
      return;
    }
    await _repository.upsertEntry(userId, entry);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final symptomsProvider = StateNotifierProvider<SymptomController, Map<String, Symptoms>>(
  (ref) {
    final controller = SymptomController(ref, ref.watch(symptomRepositoryProvider));
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.firebaseUser?.uid != next.firebaseUser?.uid) {
        controller.onAuthChanged(next.firebaseUser?.uid);
      }
    });
    return controller;
  },
);

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._ref, this._repository, this._notifications) : super(AppSettings.defaults()) {
    final auth = _ref.read(authProvider);
    _watchUser(auth.firebaseUser?.uid);
  }

  final Ref _ref;
  final FirebaseSettingsRepository _repository;
  final NotificationService _notifications;
  StreamSubscription<AppSettings>? _subscription;

  void _watchUser(String? userId) {
    _subscription?.cancel();
    _ref.read(settingsLoadedProvider.notifier).state = false;

    if (userId == null) {
      state = AppSettings.defaults();
      _ref.read(settingsLoadedProvider.notifier).state = true;
      return;
    }

    _subscription = _repository.watchSettings(userId).listen((settings) async {
      state = settings;
      _ref.read(settingsLoadedProvider.notifier).state = true;
      await _notifications.scheduleDailyLogReminder(state.dailyLogReminder);
    });
  }

  void onAuthChanged(String? userId) {
    _watchUser(userId);
  }

  Future<void> update(AppSettings next) async {
    final userId = _ref.read(authProvider).firebaseUser?.uid;
    if (userId == null) {
      return;
    }

    state = next;
    await _repository.saveSettings(userId, next);
    await _notifications.scheduleDailyLogReminder(next.dailyLogReminder);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) {
    final controller = SettingsController(
      ref,
      ref.watch(settingsRepositoryProvider),
      ref.watch(notificationServiceProvider),
    );
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.firebaseUser?.uid != next.firebaseUser?.uid) {
        controller.onAuthChanged(next.firebaseUser?.uid);
      }
    });
    return controller;
  },
);

final analyticsProvider = Provider<CycleAnalytics>((ref) {
  final periods = ref.watch(cyclesProvider);
  final symptoms = ref.watch(symptomsProvider).values.toList(growable: false);
  final settings = ref.watch(settingsProvider);
  return CyclePredictor.buildAnalytics(
    periodLogs: periods,
    symptomLogs: symptoms,
    fallbackCycleLength: settings.baselineCycleLength,
    fallbackPeriodDuration: settings.baselinePeriodDuration,
  );
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

final phaseSymptomBreakdownProvider = Provider<Map<String, Map<String, int>>>((ref) {
  final cycles = ref.watch(analyticsProvider).cycles;
  final breakdown = <String, Map<String, int>>{
    'Menstrual': <String, int>{},
    'Follicular': <String, int>{},
    'Ovulation': <String, int>{},
    'Luteal': <String, int>{},
  };

  for (final cycle in cycles) {
    final cycleLength = cycle.cycleLength ?? ref.watch(predictionProvider).averageCycleLength;
    final ovulationOffset = cycleLength - 14;
    final cycleStart = normalizeDate(cycle.startDate);
    final periodEnd = normalizeDate(cycle.endDate);
    final ovulationDay = cycleStart.add(Duration(days: ovulationOffset.clamp(0, cycleLength)));
    final fertileStart = ovulationDay.subtract(const Duration(days: 5));

    for (final symptom in cycle.symptoms) {
      final date = normalizeDate(symptom.date);
      final phase = !date.isBefore(cycleStart) && !date.isAfter(periodEnd)
          ? 'Menstrual'
          : dateKey(date) == dateKey(ovulationDay)
              ? 'Ovulation'
              : !date.isBefore(fertileStart) && date.isBefore(ovulationDay)
                  ? 'Follicular'
                  : date.isBefore(ovulationDay)
                      ? 'Follicular'
                      : 'Luteal';

      final bucket = breakdown[phase]!;
      for (final item in symptom.items) {
        bucket.update(item, (value) => value + 1, ifAbsent: () => 1);
      }
    }
  }

  return breakdown;
});

final prePeriodSymptomCountsProvider = Provider<Map<String, int>>((ref) {
  final cycles = ref.watch(analyticsProvider).cycles;
  final counts = <String, int>{};

  for (var i = 1; i < cycles.length; i++) {
    final currentStart = normalizeDate(cycles[i].startDate);
    final windowStart = currentStart.subtract(const Duration(days: 5));
    final previousCycle = cycles[i - 1];

    for (final symptom in previousCycle.symptoms) {
      final date = normalizeDate(symptom.date);
      if (date.isBefore(windowStart) || !date.isBefore(currentStart)) {
        continue;
      }
      for (final item in symptom.items) {
        counts.update(item, (value) => value + 1, ifAbsent: () => 1);
      }
    }
  }

  return counts;
});

class PhaseLengthSummary {
  const PhaseLengthSummary({
    required this.follicularDays,
    required this.lutealDays,
  });

  final int follicularDays;
  final int lutealDays;
}

final phaseLengthSummaryProvider = Provider<PhaseLengthSummary>((ref) {
  final prediction = ref.watch(predictionProvider);
  const lutealDays = 14;
  final follicularDays = (prediction.averageCycleLength - lutealDays).clamp(7, 25);
  return PhaseLengthSummary(
    follicularDays: follicularDays,
    lutealDays: lutealDays,
  );
});

class CycleStatus {
  const CycleStatus({
    required this.phase,
    required this.summary,
    required this.tipTitle,
    required this.tipBody,
    required this.daysUntilNextPeriod,
    required this.daysUntilOvulation,
  });

  final String phase;
  final String summary;
  final String tipTitle;
  final String tipBody;
  final int? daysUntilNextPeriod;
  final int? daysUntilOvulation;
}

final cycleStatusProvider = Provider<CycleStatus>((ref) {
  final prediction = ref.watch(predictionProvider);
  final cycles = ref.watch(cyclesProvider);
  final today = normalizeDate(DateTime.now());

  if (cycles.isEmpty) {
    return const CycleStatus(
      phase: 'Getting started',
      summary: 'Add a couple of period logs to unlock cycle-aware guidance.',
      tipTitle: 'Build your baseline',
      tipBody: 'Logging start dates consistently improves period, ovulation, and fertile window accuracy.',
      daysUntilNextPeriod: null,
      daysUntilOvulation: null,
    );
  }

  final lastPeriod = cycles.last;
  final lastPeriodStart = normalizeDate(lastPeriod.startDate);
  final lastPeriodEnd = normalizeDate(lastPeriod.endDate);
  final nextPeriod = prediction.nextPeriodStart;
  final ovulation = prediction.ovulationDate;
  final fertileStart = prediction.fertileStart;
  final fertileEnd = prediction.fertileEnd;

  if (!today.isBefore(lastPeriodStart) && !today.isAfter(lastPeriodEnd)) {
    return CycleStatus(
      phase: 'Menstrual',
      summary: 'You are currently in your period window.',
      tipTitle: 'Recovery first',
      tipBody: 'Prioritize hydration, iron-rich meals, and lower-intensity movement if energy feels reduced.',
      daysUntilNextPeriod: nextPeriod?.difference(today).inDays,
      daysUntilOvulation: ovulation?.difference(today).inDays,
    );
  }

  if (fertileStart != null && fertileEnd != null && !today.isBefore(fertileStart) && !today.isAfter(fertileEnd)) {
    final isOvulationDay = ovulation != null && dateKey(today) == dateKey(ovulation);
    return CycleStatus(
      phase: isOvulationDay ? 'Ovulation' : 'Fertile window',
      summary: isOvulationDay ? 'Today is your estimated ovulation day.' : 'You are in your estimated fertile window.',
      tipTitle: 'Watch your body signals',
      tipBody: 'Cervical mucus, libido changes, and mild pelvic discomfort can line up with this part of the cycle.',
      daysUntilNextPeriod: nextPeriod?.difference(today).inDays,
      daysUntilOvulation: ovulation?.difference(today).inDays,
    );
  }

  final preOvulation = ovulation != null && today.isBefore(ovulation);
  if (preOvulation) {
    return CycleStatus(
      phase: 'Follicular',
      summary: 'Energy often trends upward between your period and ovulation.',
      tipTitle: 'Good time to plan',
      tipBody: 'This phase can be a useful window for exercise consistency, meal prep, and habit-building.',
      daysUntilNextPeriod: nextPeriod?.difference(today).inDays,
      daysUntilOvulation: ovulation.difference(today).inDays,
    );
  }

  return CycleStatus(
    phase: 'Luteal',
    summary: 'You are in the time between ovulation and your next period.',
    tipTitle: 'Support mood and recovery',
    tipBody: 'Prioritize sleep, steady meals, and symptom logging here because PMS patterns often show up in this phase.',
    daysUntilNextPeriod: nextPeriod?.difference(today).inDays,
    daysUntilOvulation: ovulation?.difference(today).inDays,
  );
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
