import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
import '../../providers/app_providers.dart';

class FirebaseSetupScreen extends ConsumerWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(firebaseAppStatusProvider);

    return Scaffold(
      body: AppGradientBackground(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HighlightCard(
              title: 'Firebase setup required',
              subtitle:
                  'The app code is wired for Firebase Auth and Firestore, but this build is missing Firebase project configuration.',
              primaryValue: 'Next step',
              secondaryValue:
                  'Run FlutterFire configuration and add your platform Firebase files.',
              icon: Icons.cloud_off_rounded,
              gradient: [Color(0xFF7A8DE8), Color(0xFFDA6D8F)],
            ),
            const SizedBox(height: 18),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you need to do',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text('1. Create a Firebase project.'),
                  const Text(
                    '2. Enable Email/Password in Firebase Authentication.',
                  ),
                  const Text('3. Create a Firestore database.'),
                  const Text('4. Run FlutterFire configure for this app.'),
                  const Text('5. Deploy firestore.rules and firebase.json.'),
                  const SizedBox(height: 12),
                  Text(
                    'Current error',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(status.errorMessage ?? 'Firebase failed to initialize.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
