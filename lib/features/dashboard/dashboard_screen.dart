import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_helpers.dart';
import '../../data/models/cycle_record.dart';
import '../../providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _showAddCycleDialog(BuildContext context, WidgetRef ref) async {
    DateTimeRange? selected;
    selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 3)),
        end: DateTime.now(),
      ),
    );

    if (selected == null) {
      return;
    }

    await ref.read(cyclesProvider.notifier).addCycle(
          CycleRecord(startDate: selected.start, endDate: selected.end),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(predictionProvider);
    final cycles = ref.watch(cyclesProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'My Cycle Dashboard',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Next period'),
              subtitle: Text(
                prediction.nextPeriodDate == null
                    ? 'Add at least one cycle'
                    : formatPretty(prediction.nextPeriodDate!),
              ),
              trailing: const Icon(Icons.favorite_outline),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Predicted ovulation'),
              subtitle: Text(
                prediction.ovulationDate == null
                    ? 'Needs cycle history'
                    : formatPretty(prediction.ovulationDate!),
              ),
              trailing: const Icon(Icons.eco_outlined),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Average cycle length'),
              subtitle: Text('${prediction.averageCycleLength} days'),
              trailing: const Icon(Icons.timeline),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _showAddCycleDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Log period dates'),
          ),
          const SizedBox(height: 24),
          Text('Recent cycles', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (cycles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No cycle entries yet.'),
              ),
            )
          else
            ...cycles.reversed.take(5).map(
                  (cycle) => Card(
                    child: ListTile(
                      title: Text(
                        '${formatPretty(cycle.startDate)} - ${formatPretty(cycle.endDate)}',
                      ),
                      subtitle: Text('${cycle.periodLength} day period'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
