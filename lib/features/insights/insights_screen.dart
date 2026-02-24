import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycles = ref.watch(cyclesProvider);
    final prediction = ref.watch(predictionProvider);
    final symptomCounts = ref.watch(symptomCountsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Cycle Insights', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Cycles logged'),
              subtitle: Text('${cycles.length} total entries'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Average cycle length'),
              subtitle: Text('${prediction.averageCycleLength} days'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Period regularity'),
              subtitle: Text(_regularityLabel(prediction.regularityScore)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Symptom trends', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (symptomCounts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No symptom logs yet.'),
              ),
            )
          else
            ...(() {
              final sorted = symptomCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return sorted
                  .map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(entry.key),
                        trailing: Text('${entry.value}x'),
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
