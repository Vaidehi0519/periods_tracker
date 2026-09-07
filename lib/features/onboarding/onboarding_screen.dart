import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
import '../../providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _cycleController = TextEditingController(text: '28');
  final TextEditingController _periodController = TextEditingController(text: '5');
  int _pageIndex = 0;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _cycleController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppGradientBackground(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: SizedBox.shrink(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: index <= _pageIndex
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (value) => setState(() => _pageIndex = value),
                      children: [
                        _IntroStep(
                          title: 'A calmer way to track your cycle',
                          body:
                              'We will use your cycle history, symptoms, and a few baseline details to predict your next period, ovulation day, and fertile window.',
                          icon: Icons.favorite_rounded,
                          gradient: const [Color(0xFFE2749A), Color(0xFFF2B56A)],
                        ),
                        _IntroStep(
                          title: 'Predictions work better with a baseline',
                          body:
                              'Enter your usual cycle length and period duration. These will be used until enough real logs are available.',
                          icon: Icons.insights_rounded,
                          gradient: const [Color(0xFF6EC3B5), Color(0xFF7A8DE8)],
                          child: Column(
                            children: [
                              TextField(
                                controller: _cycleController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Average cycle length',
                                  hintText: 'Usually 26-32 days',
                                  suffixText: 'days',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _periodController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Period duration',
                                  hintText: 'Usually 4-6 days',
                                  suffixText: 'days',
                                ),
                              ),
                            ],
                          ),
                        ),
                        _IntroStep(
                          title: 'Tips to keep in mind',
                          body:
                              'Predictions are estimates, not medical advice. Logging start dates consistently matters more than perfect detail on every day.',
                          icon: Icons.lightbulb_rounded,
                          gradient: const [Color(0xFFF1AB62), Color(0xFFE27D8D)],
                          child: const Column(
                            children: [
                              TipRow(
                                icon: Icons.edit_calendar,
                                label: 'Log the first day of your period',
                                body: 'That date drives cycle length, ovulation, and fertile window calculations.',
                              ),
                              SizedBox(height: 12),
                              TipRow(
                                icon: Icons.monitor_heart_outlined,
                                label: 'Use insights as patterns',
                                body: 'Look for trends over time rather than expecting each cycle to match exactly.',
                              ),
                              SizedBox(height: 12),
                              TipRow(
                                icon: Icons.local_hospital_outlined,
                                label: 'Check with a clinician when needed',
                                body: 'Irregular bleeding, severe pain, or sudden changes should not rely on app predictions alone.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_pageIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : _goBack,
                            child: const Text('Back'),
                          ),
                        ),
                      if (_pageIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : (_pageIndex == 2 ? _finish : _goNext),
                          child: Text(_saving ? 'Saving...' : _pageIndex == 2 ? 'Start tracking' : 'Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final cycleLength = int.tryParse(_cycleController.text.trim());
    final periodDuration = int.tryParse(_periodController.text.trim());

    if (cycleLength == null || cycleLength < 21 || cycleLength > 45) {
      _showError('Enter a cycle length between 21 and 45 days.');
      return;
    }
    if (periodDuration == null || periodDuration < 2 || periodDuration > 10) {
      _showError('Enter a period duration between 2 and 10 days.');
      return;
    }

    setState(() => _saving = true);
    final current = ref.read(settingsProvider);
    final next = current.copyWith(
      onboardingCompleted: true,
      baselineCycleLength: cycleLength,
      baselinePeriodDuration: periodDuration,
    );
    await ref.read(settingsProvider.notifier).update(next);
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.title,
    required this.body,
    required this.icon,
    required this.gradient,
    this.child,
  });

  final String title;
  final String body;
  final IconData icon;
  final List<Color> gradient;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedEntrance(
          child: HighlightCard(
            title: title,
            subtitle: body,
            primaryValue: 'Private by default',
            secondaryValue: 'Your logs stay on-device.',
            icon: icon,
            gradient: gradient,
          ),
        ),
        if (child != null) ...[
          const SizedBox(height: 18),
          AnimatedEntrance(
            child: AppSectionCard(child: child!),
          ),
        ],
      ],
    );
  }
}
