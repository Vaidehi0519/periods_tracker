import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
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
    final lock = ref.read(lockPreferencesProvider).preferences;
    if (!lock.biometricEnabled) {
      return;
    }
    final ok = await ref.read(lockServiceProvider).authenticateWithBiometrics();
    if (ok && mounted) {
      widget.onUnlocked();
    }
  }

  Future<void> _unlock() async {
    final ok = await ref
        .read(lockPreferencesProvider.notifier)
        .verifyPin(_controller.text);
    if (ok && mounted) {
      widget.onUnlocked();
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _error = 'Incorrect PIN';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(lockPreferencesProvider).preferences;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3F8), Color(0xFFF8FBFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppSectionCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 34),
                    const SizedBox(height: 10),
                    Text(
                      'Private Access',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text('Enter your PIN to unlock your tracker'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      maxLength: 6,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        errorText: _error,
                        hintText: '6-digit PIN',
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _unlock,
                        child: const Text('Unlock'),
                      ),
                    ),
                    if (lock.biometricEnabled)
                      TextButton.icon(
                        onPressed: _useBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Use biometrics'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
