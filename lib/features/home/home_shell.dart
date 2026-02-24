import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../calendar/calendar_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../insights/insights_screen.dart';
import '../lock/lock_screen.dart';
import '../log/log_symptoms_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _unlocked = !settings.pinEnabled;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (previous, next) {
      if (next.pinEnabled && !(_unlocked && previous?.pinEnabled == true)) {
        setState(() {
          _unlocked = false;
        });
      }
      if (!next.pinEnabled && !_unlocked) {
        setState(() {
          _unlocked = true;
        });
      }
    });
    ref.listen(reminderPayloadProvider, (previous, next) {
      ref.read(notificationServiceProvider).updateCyclePredictionReminders(
            periodEnabled: next.periodEnabled,
            ovulationEnabled: next.ovulationEnabled,
            nextPeriod: next.nextPeriodDate,
            ovulation: next.ovulationDate,
          );
    });

    final settings = ref.watch(settingsProvider);
    if (settings.pinEnabled && !_unlocked) {
      return LockScreen(
        onUnlocked: () {
          setState(() {
            _unlocked = true;
          });
        },
      );
    }

    final screens = const [
      DashboardScreen(),
      CalendarScreen(),
      LogSymptomsScreen(),
      InsightsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
