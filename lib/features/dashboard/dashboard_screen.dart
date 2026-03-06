import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/models/period_log.dart';
import '../../providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _showAddCycleDialog(BuildContext context, WidgetRef ref) async {
    final selected = await showDateRangePicker(
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
          PeriodLog(startDate: selected.start, endDate: selected.end),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(predictionProvider);
    final cycles = ref.watch(cyclesProvider);

    return AppGradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Dashboard',
            subtitle: 'Track your cycle with private, local data',
            action: FilledButton.tonalIcon(
              onPressed: () => _showAddCycleDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Next Period',
                  value: prediction.nextPeriodStart == null
                      ? '--'
                      : formatPretty(prediction.nextPeriodStart!),
                  icon: Icons.favorite_border,
                  color: const Color(0xFFE7749B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Ovulation',
                  value: prediction.ovulationDate == null
                      ? '--'
                      : formatPretty(prediction.ovulationDate!),
                  icon: Icons.eco_outlined,
                  color: const Color(0xFF46A89D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Average Cycle',
                  value: '${prediction.averageCycleLength} days',
                  icon: Icons.timelapse,
                  color: const Color(0xFF7B8AE2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Period Duration',
                  value: '${prediction.averagePeriodDuration} days',
                  icon: Icons.hourglass_bottom,
                  color: const Color(0xFF8E6FCB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Recent Period Logs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (cycles.isEmpty)
            const AppSectionCard(child: Text('No cycle entries yet.'))
          else
            ...cycles.reversed.take(6).map(
                  (cycle) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppSectionCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${formatPretty(cycle.startDate)} - ${formatPretty(cycle.endDate)}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text('${cycle.periodDuration} day period'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
