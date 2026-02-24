import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_shell.dart';
import '../providers/app_providers.dart';
import 'theme.dart';

class PeriodsTrackerApp extends ConsumerWidget {
  const PeriodsTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Periods Tracker',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeShell(),
    );
  }
}
