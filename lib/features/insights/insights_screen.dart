import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
import '../../providers/app_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycles = ref.watch(cyclesProvider);
    final cycleLengths = ref.watch(cycleLengthsProvider);
    final prediction = ref.watch(predictionProvider);
    final symptomCounts = ref.watch(symptomCountsProvider);
    final phaseBreakdown = ref.watch(phaseSymptomBreakdownProvider);
    final prePeriodSymptoms = ref.watch(prePeriodSymptomCountsProvider);
    final phaseLengths = ref.watch(phaseLengthSummaryProvider);
    final cycleStatus = ref.watch(cycleStatusProvider);
    final strongestSymptom = symptomCounts.entries.isEmpty
        ? null
        : (symptomCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;

    return AppGradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnimatedEntrance(
            child: ScreenHeader(
              title: 'Insights',
              subtitle: 'Cycle consistency and symptom trends',
            ),
          ),
          const SizedBox(height: 14),
          AnimatedEntrance(
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Cycles Logged',
                    value: '${cycles.length}',
                    icon: Icons.event_note,
                    color: const Color(0xFF7B8AE2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Avg Length',
                    value: '${prediction.averageCycleLength} days',
                    icon: Icons.av_timer,
                    color: const Color(0xFFE7749B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AnimatedEntrance(
            child: AppSectionCard(
              child: Row(
                children: [
                  const Icon(Icons.multiline_chart_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period Regularity',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(_regularityLabel(prediction.regularityScore)),
                      ],
                    ),
                  ),
                  Text('${(prediction.regularityScore * 100).round()}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedEntrance(
            child: AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Phase',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cycleStatus.phase,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(cycleStatus.summary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedEntrance(
            child: AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fertility Prediction',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prediction.ovulationDate == null
                        ? 'Log more periods to improve predictions.'
                        : 'Ovulation: ${prediction.ovulationDate!.month}/${prediction.ovulationDate!.day}\n'
                              'Fertile: ${prediction.fertileStart!.month}/${prediction.fertileStart!.day}'
                              ' - ${prediction.fertileEnd!.month}/${prediction.fertileEnd!.day}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedEntrance(
            child: AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cycle Trend Chart',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 14),
                  cycleLengths.isEmpty
                      ? const Text('Need at least 2 logged periods.')
                      : _CycleLengthChart(values: cycleLengths),
                  if (strongestSymptom != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Most logged symptom: ${strongestSymptom.key} (${strongestSymptom.value}x)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Estimated follicular phase: ${phaseLengths.follicularDays} days\nEstimated luteal phase: ${phaseLengths.lutealDays} days',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Symptom Trends',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (symptomCounts.isEmpty)
            const AppSectionCard(child: Text('No symptom logs yet.'))
          else ...[
            AnimatedEntrance(
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top symptoms',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    ..._topSymptoms(symptomCounts).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SymptomMeter(
                          label: entry.key,
                          value: entry.value,
                          maxValue: _maxCount(symptomCounts),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedEntrance(
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common before-period symptoms',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    if (prePeriodSymptoms.isEmpty)
                      const Text(
                        'Log a few cycles and symptoms to find pre-period patterns.',
                      )
                    else
                      ..._topSymptoms(prePeriodSymptoms).map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SymptomMeter(
                            label: entry.key,
                            value: entry.value,
                            maxValue: _maxCount(prePeriodSymptoms),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedEntrance(
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Symptoms by phase',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    ...phaseBreakdown.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PhaseSection(
                          phase: entry.key,
                          symptoms: entry.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<MapEntry<String, int>> _topSymptoms(Map<String, int> symptomCounts) {
    final sorted = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList(growable: false);
  }

  int _maxCount(Map<String, int> symptomCounts) {
    if (symptomCounts.isEmpty) {
      return 1;
    }
    return symptomCounts.values.reduce(math.max);
  }

  String _regularityLabel(double score) {
    if (score >= 0.7) {
      return 'Regular';
    }
    if (score >= 0.4) {
      return 'Moderately regular';
    }
    return 'Irregular';
  }
}

class _CycleLengthChart extends StatelessWidget {
  const _CycleLengthChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce(math.max).toDouble();
    final minValue = values.reduce(math.min).toDouble();
    final spread = math.max(1.0, maxValue - minValue);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ...List.generate(values.length, (index) {
            final value = values[index].toDouble();
            final normalized = ((value - minValue) / spread).clamp(0.18, 1.0);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == values.length - 1 ? 0 : 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${values[index]}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 320 + (index * 40)),
                          curve: Curves.easeOutCubic,
                          height: 110 * normalized,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xFFDA6D8F), Color(0xFF6FC2B5)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'C${index + 1}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SymptomMeter extends StatelessWidget {
  const _SymptomMeter({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final widthFactor = (value / math.max(1, maxValue)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            Text('${value}x'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: widthFactor,
            minHeight: 10,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDA6D8F)),
          ),
        ),
      ],
    );
  }
}

class _PhaseSection extends StatelessWidget {
  const _PhaseSection({required this.phase, required this.symptoms});

  final String phase;
  final Map<String, int> symptoms;

  @override
  Widget build(BuildContext context) {
    final sorted = symptoms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(phase, style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Text(
            'No symptom logs in this phase yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sorted
                .take(4)
                .map((entry) {
                  return Chip(label: Text('${entry.key} ${entry.value}x'));
                })
                .toList(growable: false),
          ),
      ],
    );
  }
}
