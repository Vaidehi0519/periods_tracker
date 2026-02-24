import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Dark mode'),
              value: settings.darkMode,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(darkMode: value));
              },
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Period reminders'),
              value: settings.periodReminders,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(periodReminders: value));
              },
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Ovulation reminders'),
              value: settings.ovulationReminders,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(ovulationReminders: value));
              },
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Daily symptom reminder'),
              value: settings.dailyLogReminder,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(dailyLogReminder: value));
              },
            ),
          ),
          Card(
            child: SwitchListTile(
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
                await ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(pinEnabled: value));
              },
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Use biometric unlock'),
              subtitle: const Text('Requires PIN to be enabled'),
              value: settings.biometricEnabled,
              onChanged: settings.pinEnabled
                  ? (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .update(settings.copyWith(biometricEnabled: value));
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: settings.pinEnabled
                ? () async {
                    final pin = await _askPin(context);
                    if (pin == null) {
                      return;
                    }
                    await ref
                        .read(settingsProvider.notifier)
                        .update(settings.copyWith(pinCode: pin));
                  }
                : null,
            child: const Text('Change PIN'),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Privacy: All cycle and symptom data is stored locally on your device.',
              ),
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
}
