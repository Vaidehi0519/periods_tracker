import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
            title: 'Appearance',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode'),
              value: settings.darkMode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).update(settings.copyWith(darkMode: value));
              },
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
                    ref.read(settingsProvider.notifier).update(settings.copyWith(periodReminders: value));
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ovulation reminders'),
                  value: settings.ovulationReminders,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).update(settings.copyWith(ovulationReminders: value));
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily symptom reminder'),
                  value: settings.dailyLogReminder,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).update(settings.copyWith(dailyLogReminder: value));
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
                  value: settings.pinEnabled,
                  onChanged: (value) async {
                    if (value && settings.pinCode.isEmpty) {
                      final pin = await _askPin(context);
                      if (pin == null) {
                        return;
                      }
                      await ref.read(settingsProvider.notifier).update(
                            settings.copyWith(pinEnabled: true, pinCode: pin),
                          );
                      return;
                    }
                    await ref.read(settingsProvider.notifier).update(settings.copyWith(pinEnabled: value));
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use biometric unlock'),
                  subtitle: const Text('Requires PIN to be enabled'),
                  value: settings.biometricEnabled,
                  onChanged: settings.pinEnabled
                      ? (value) {
                          ref.read(settingsProvider.notifier).update(settings.copyWith(biometricEnabled: value));
                        }
                      : null,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: settings.pinEnabled
                        ? () async {
                            final pin = await _askPin(context);
                            if (pin == null) {
                              return;
                            }
                            await ref.read(settingsProvider.notifier).update(settings.copyWith(pinCode: pin));
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
                  child: Text('All period and symptom data stays locally on your device.'),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
