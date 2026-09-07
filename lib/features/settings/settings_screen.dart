import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);
    final lock = ref.watch(lockPreferencesProvider);
    final lockPreferences = lock.preferences;

    return AppGradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            title: 'Settings',
            subtitle: 'Notifications, lock, and app appearance',
          ),
          const SizedBox(height: 14),
          _SettingGroup(
            title: 'Account',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.firebaseUser == null
                      ? 'No account is signed in.'
                      : 'Signed in as ${((auth.firebaseUser!.displayName ?? '').isEmpty ? auth.firebaseUser!.email : auth.firebaseUser!.displayName)}\n${auth.firebaseUser!.email ?? ''}',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: auth.firebaseUser == null
                        ? null
                        : () async {
                            await ref.read(authProvider.notifier).logout();
                          },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: auth.firebaseUser == null
                        ? null
                        : () async {
                            final nextName = await _askDisplayName(
                              context,
                              initialValue:
                                  auth.firebaseUser?.displayName ?? '',
                            );
                            if (nextName == null) {
                              return;
                            }
                            final ok = await ref
                                .read(authProvider.notifier)
                                .updateDisplayName(nextName);
                            if (context.mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated.'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Edit profile name'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: auth.firebaseUser == null
                        ? null
                        : () async {
                            final reason = await _askDeletionReason(context);
                            if (reason == null) {
                              return;
                            }
                            final ok = await ref
                                .read(authProvider.notifier)
                                .requestAccountDeletion(reason: reason);
                            if (context.mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Deletion request submitted. Complete cleanup with your backend process.',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Request account deletion'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SettingGroup(
            title: 'Appearance',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode'),
              value: settings.darkMode,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(darkMode: value));
              },
            ),
          ),
          const SizedBox(height: 10),
          _SettingGroup(
            title: 'Cycle Baseline',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cycle length: ${settings.baselineCycleLength} days\nPeriod duration: ${settings.baselinePeriodDuration} days',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(settingsProvider.notifier)
                          .update(
                            settings.copyWith(onboardingCompleted: false),
                          );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Revisit onboarding'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SettingGroup(
            title: 'Reminders',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Period reminders'),
                  value: settings.periodReminders,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .update(settings.copyWith(periodReminders: value));
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ovulation reminders'),
                  value: settings.ovulationReminders,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .update(settings.copyWith(ovulationReminders: value));
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily symptom reminder'),
                  value: settings.dailyLogReminder,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .update(settings.copyWith(dailyLogReminder: value));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SettingGroup(
            title: 'Privacy Lock',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable PIN lock'),
                  value: lockPreferences.pinEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final pin = await _askPin(context);
                      if (pin == null) {
                        return;
                      }
                      await ref
                          .read(lockPreferencesProvider.notifier)
                          .enablePin(pin);
                      return;
                    }
                    await ref
                        .read(lockPreferencesProvider.notifier)
                        .disablePin();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use biometric unlock'),
                  subtitle: const Text('Requires PIN to be enabled'),
                  value: lockPreferences.biometricEnabled,
                  onChanged: lockPreferences.pinEnabled
                      ? (value) {
                          ref
                              .read(lockPreferencesProvider.notifier)
                              .setBiometricEnabled(value);
                        }
                      : null,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: lockPreferences.pinEnabled
                        ? () async {
                            final pin = await _askPin(context);
                            if (pin == null) {
                              return;
                            }
                            await ref
                                .read(lockPreferencesProvider.notifier)
                                .enablePin(pin);
                          }
                        : null,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Change PIN'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const AppSectionCard(
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your account uses Firebase Auth and your cycle data syncs with Firestore. PIN lock settings stay local to this device.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _askPin(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set 6-digit PIN'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              validator: (value) {
                if (value == null || value.length != 6) {
                  return 'Enter 6 digits';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, controller.text);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return pin;
  }

  Future<String?> _askDisplayName(
    BuildContext context, {
    required String initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update profile name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Display name'),
              validator: (value) {
                if ((value ?? '').trim().length < 2) {
                  return 'Enter at least 2 characters';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return name;
  }

  Future<String?> _askDeletionReason(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request account deletion'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Optional note for your backend support flow',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return reason;
  }
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
