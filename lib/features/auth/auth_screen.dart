import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
import '../../providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;
  bool _isSubmitting = false;
  bool _isResettingPassword = false;
  bool _isSendingVerification = false;
  bool _isRefreshingVerification = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          const AppGradientBackground(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: SizedBox.shrink(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AnimatedEntrance(
                          child: HighlightCard(
                            title: 'Customer login',
                            subtitle: 'Authenticate with Firebase and keep your health data synced per account in real time.',
                            primaryValue: 'Realtime + secure',
                            secondaryValue: 'Each customer account gets isolated cloud data and live updates.',
                            icon: Icons.favorite_rounded,
                            gradient: [
                              Color(0xFFDA6D8F),
                              Color(0xFFE79A74),
                              Color(0xFF6FC2B5),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (authState.isLoggedIn && !authState.isEmailVerified)
                          AnimatedEntrance(
                            child: AppSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Verify your email', style: Theme.of(context).textTheme.headlineSmall),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Your account is signed in, but email verification is still pending. Customers should verify their email before using the app.',
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.tonal(
                                          onPressed: _isSendingVerification
                                              ? null
                                              : () async {
                                                  final messenger = ScaffoldMessenger.of(context);
                                                  setState(() => _isSendingVerification = true);
                                                  final ok = await ref.read(authProvider.notifier).sendEmailVerification();
                                                  if (mounted) {
                                                    setState(() => _isSendingVerification = false);
                                                    if (ok) {
                                                      messenger.showSnackBar(
                                                        const SnackBar(content: Text('Verification email sent.')),
                                                      );
                                                    }
                                                  }
                                                },
                                          child: Text(_isSendingVerification ? 'Sending...' : 'Resend verification'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isRefreshingVerification
                                              ? null
                                              : () async {
                                                  setState(() => _isRefreshingVerification = true);
                                                  await ref.read(authProvider.notifier).reloadUser();
                                                  if (mounted) {
                                                    setState(() => _isRefreshingVerification = false);
                                                  }
                                                },
                                          child: Text(_isRefreshingVerification ? 'Checking...' : 'I verified'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await ref.read(authProvider.notifier).logout();
                                      },
                                      icon: const Icon(Icons.logout),
                                      label: const Text('Use another account'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          AnimatedEntrance(
                            child: AppSectionCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLoginMode ? 'Sign in' : 'Create account',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isLoginMode
                                          ? 'Use your Firebase account to unlock the app.'
                                          : 'Create your customer account with Firebase Authentication.',
                                    ),
                                    if (!_isLoginMode) ...[
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'Name',
                                          hintText: 'Your name',
                                        ),
                                        validator: (value) {
                                          if (_isLoginMode) {
                                            return null;
                                          }
                                          if (value == null || value.trim().length < 2) {
                                            return 'Enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'name@example.com',
                                      ),
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (!text.contains('@') || !text.contains('.')) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        hintText: 'At least 6 characters',
                                      ),
                                      validator: (value) {
                                        if ((value ?? '').trim().length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: _isSubmitting || authState.isLoading ? null : _submit,
                                        child: Text(
                                          _isSubmitting
                                              ? 'Please wait...'
                                              : _isLoginMode
                                                  ? 'Login'
                                                  : 'Create account',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (_isLoginMode)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: _isResettingPassword ? null : _resetPassword,
                                          child: Text(_isResettingPassword ? 'Sending reset...' : 'Forgot password?'),
                                        ),
                                      ),
                                    Center(
                                      child: TextButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : () {
                                                setState(() {
                                                  _isLoginMode = !_isLoginMode;
                                                });
                                              },
                                        child: Text(
                                          _isLoginMode
                                              ? 'Need an account? Sign up'
                                              : 'Already have an account? Login',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final auth = ref.read(authProvider.notifier);
    final ok = _isLoginMode
        ? await auth.login(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await auth.register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (ok) {
        FocusScope.of(context).unfocus();
        if (!_isLoginMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created. Check your email for verification.')),
          );
        }
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first to reset the password.')),
      );
      return;
    }

    setState(() => _isResettingPassword = true);
    final ok = await ref.read(authProvider.notifier).sendPasswordResetEmail(email);
    if (mounted) {
      setState(() => _isResettingPassword = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    }
  }
}
