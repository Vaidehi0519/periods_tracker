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

    return AppGradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            title: 'Insights',
            subtitle: 'Cycle consistency and symptom trends',
          ),
          const SizedBox(height: 14),
          Row(
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
          const SizedBox(height: 10),
          AppSectionCard(
            child: Row(
              children: [
                const Icon(Icons.multiline_chart_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Period Regularity', style: Theme.of(context).textTheme.titleSmall),
                      Text(_regularityLabel(prediction.regularityScore)),
                    ],
                  ),
                ),
                Text('${(prediction.regularityScore * 100).round()}%'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fertility Prediction', style: Theme.of(context).textTheme.titleSmall),
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
          const SizedBox(height: 10),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cycle Length History', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  cycleLengths.isEmpty
                      ? 'Need at least 2 logged periods.'
                      : cycleLengths.map((d) => '$d d').join(' • '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Symptom Trends', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (symptomCounts.isEmpty)
            const AppSectionCard(child: Text('No symptom logs yet.'))
          else
            ...(() {
              final sorted = symptomCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return sorted
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppSectionCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('${entry.value}x'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList();
            })(),
        ],
      ),
    );
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
