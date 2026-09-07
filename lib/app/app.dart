import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_screen.dart';
import '../features/auth/firebase_setup_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_shell.dart';
import '../features/splash/animated_splash_screen.dart';
import '../providers/app_providers.dart';
import 'theme.dart';

class PeriodsTrackerApp extends ConsumerStatefulWidget {
  const PeriodsTrackerApp({super.key});

  @override
  ConsumerState<PeriodsTrackerApp> createState() => _PeriodsTrackerAppState();
}

class _PeriodsTrackerAppState extends ConsumerState<PeriodsTrackerApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseStatus = ref.watch(firebaseAppStatusProvider);
    final auth = ref.watch(authProvider);
    final settingsLoaded = ref.watch(settingsLoadedProvider);
    final settings = auth.isLoggedIn && auth.isEmailVerified && firebaseStatus.isReady
        ? ref.watch(settingsProvider)
        : null;

    return MaterialApp(
      title: 'Periods Tracker',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: (settings?.darkMode ?? false) ? ThemeMode.dark : ThemeMode.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showSplash
            ? const AnimatedSplashScreen()
            : !firebaseStatus.isReady
                ? const FirebaseSetupScreen()
                : auth.isLoading || (auth.isLoggedIn && !settingsLoaded)
                    ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                    : !auth.isLoggedIn || !auth.isEmailVerified
                        ? const AuthScreen()
                        : settings!.onboardingCompleted
                            ? const HomeShell()
                            : const OnboardingScreen(),
      ),
    );
  }
}
