import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _useBiometric() async {
    final settings = ref.read(settingsProvider);
    if (!settings.biometricEnabled) {
      return;
    }
    final ok = await ref.read(lockServiceProvider).authenticateWithBiometrics();
    if (ok && mounted) {
      widget.onUnlocked();
    }
  }

  void _unlock() {
    final settings = ref.read(settingsProvider);
    if (_controller.text == settings.pinCode) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _error = 'Incorrect PIN';
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter PIN to unlock'),
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _controller,
                    maxLength: 6,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      errorText: _error,
                      hintText: '6-digit PIN',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _unlock, child: const Text('Unlock')),
                if (settings.biometricEnabled)
                  TextButton(
                    onPressed: _useBiometric,
                    child: const Text('Use biometrics'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
