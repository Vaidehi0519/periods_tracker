import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('cycles');
  await Hive.openBox<dynamic>('symptoms');
  await Hive.openBox<dynamic>('settings');
  await Hive.openBox<dynamic>('auth');

  FirebaseAppStatus firebaseStatus;
  try {
    await Firebase.initializeApp();
    firebaseStatus = const FirebaseAppStatus(isReady: true);
  } catch (error) {
    firebaseStatus = FirebaseAppStatus(
      isReady: false,
      errorMessage: error.toString(),
    );
  }

  final container = ProviderContainer(
    overrides: [
      firebaseAppStatusProvider.overrideWithValue(firebaseStatus),
    ],
  );
  await container.read(notificationServiceProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PeriodsTrackerApp(),
    ),
  );
}
