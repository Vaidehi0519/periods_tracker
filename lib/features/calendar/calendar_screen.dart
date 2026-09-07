import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/ui/app_shell.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/models/symptoms.dart';
import '../../providers/app_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final periodDays = ref.watch(periodDayKeysProvider);
    final predictedPeriodDays = ref.watch(predictedPeriodDayKeysProvider);
    final fertileDays = ref.watch(fertileDayKeysProvider);
    final ovulationDay = ref.watch(ovulationDayKeyProvider);
    final prediction = ref.watch(predictionProvider);
    final selectedEntry = ref.watch(symptomsProvider)[dateKey(_selectedDay)];

    return AppGradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnimatedEntrance(
            child: ScreenHeader(
              title: 'Calendar',
              subtitle: 'Period, ovulation, and fertile window view',
            ),
          ),
          const SizedBox(height: 14),
          AnimatedEntrance(
            child: AppSectionCard(
              child: TableCalendar<void>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2035),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _openDayDetails(context, selectedDay);
                },
                availableGestures: AvailableGestures.all,
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  prioritizedBuilder: (context, day, focusedDay) {
                    final key = dateKey(day);
                    if (periodDays.contains(key)) {
                      return _statusDay(
                        context,
                        day,
                        bgColor: const Color(0xFFE53935),
                        showOvulationIcon: false,
                      );
                    }
                    if (predictedPeriodDays.contains(key)) {
                      return _statusDay(
                        context,
                        day,
                        bgColor: const Color(0xFFFFCDD2),
                        textColor: const Color(0xFFB71C1C),
                        showOvulationIcon: false,
                      );
                    }
                    if (ovulationDay == key) {
                      return _statusDay(
                        context,
                        day,
                        bgColor: const Color(0xFF1B5E20),
                        showOvulationIcon: true,
                      );
                    }
                    if (fertileDays.contains(key)) {
                      return _statusDay(
                        context,
                        day,
                        bgColor: const Color(0xFFA5D6A7),
                        textColor: const Color(0xFF1B5E20),
                        showOvulationIcon: false,
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const AnimatedEntrance(
            child: AppSectionCard(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _LegendChip(label: 'Period', color: Color(0xFFE53935)),
                  _LegendChip(
                    label: 'Predicted period',
                    color: Color(0xFFFFCDD2),
                  ),
                  _LegendChip(
                    label: 'Fertile window',
                    color: Color(0xFFA5D6A7),
                  ),
                  _LegendChip(
                    label: 'Ovulation',
                    color: Color(0xFF1B5E20),
                    icon: Icons.auto_awesome,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedEntrance(
            child: AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Day',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatPretty(_selectedDay),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dayLabels(
                      day: _selectedDay,
                      periodDays: periodDays,
                      predictedPeriodDays: predictedPeriodDays,
                      fertileDays: fertileDays,
                      ovulationDay: ovulationDay,
                    ),
                  ),
                  if (selectedEntry != null) ...[
                    const SizedBox(height: 12),
                    _QuickLogPreview(entry: selectedEntry),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openDayDetails(context, _selectedDay),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Day Details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedEntrance(
            child: AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predictions from logged cycles',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prediction.ovulationDate == null
                        ? 'Log at least one period to generate predictions.'
                        : 'Next period: ${formatPretty(prediction.nextPeriodStart!)} - ${formatPretty(prediction.nextPeriodEnd!)}\n'
                              'Ovulation: ${formatPretty(prediction.ovulationDate!)}\n'
                              'Fertile window: ${formatPretty(prediction.fertileStart!)} - ${formatPretty(prediction.fertileEnd!)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _dayLabels({
    required DateTime day,
    required Set<String> periodDays,
    required Set<String> predictedPeriodDays,
    required Set<String> fertileDays,
    required String? ovulationDay,
  }) {
    final key = dateKey(day);
    final labels = <Widget>[];

    if (periodDays.contains(key)) {
      labels.add(const Chip(label: Text('Period logged')));
    }
    if (predictedPeriodDays.contains(key)) {
      labels.add(const Chip(label: Text('Predicted period')));
    }
    if (fertileDays.contains(key)) {
      labels.add(const Chip(label: Text('Fertile window')));
    }
    if (ovulationDay == key) {
      labels.add(const Chip(label: Text('Ovulation day')));
    }
    if (labels.isEmpty) {
      labels.add(const Chip(label: Text('No cycle event')));
    }
    return labels;
  }

  Future<void> _openDayDetails(BuildContext context, DateTime day) async {
    final periodDays = ref.read(periodDayKeysProvider);
    final predictedPeriodDays = ref.read(predictedPeriodDayKeysProvider);
    final fertileDays = ref.read(fertileDayKeysProvider);
    final ovulationDay = ref.read(ovulationDayKeyProvider);
    final prediction = ref.read(predictionProvider);
    final cycleStatus = ref.read(cycleStatusProvider);
    final entry = ref.read(symptomsProvider)[dateKey(day)];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.48,
          maxChildSize: 0.9,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    formatPretty(day),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _sheetSummary(
                      day: day,
                      cycleStatus: cycleStatus,
                      periodDays: periodDays,
                      predictedPeriodDays: predictedPeriodDays,
                      fertileDays: fertileDays,
                      ovulationDay: ovulationDay,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dayLabels(
                      day: day,
                      periodDays: periodDays,
                      predictedPeriodDays: predictedPeriodDays,
                      fertileDays: fertileDays,
                      ovulationDay: ovulationDay,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (entry != null) ...[
                    AppSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logged symptoms',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 10),
                          _QuickLogPreview(entry: entry),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cycle forecast',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prediction.ovulationDate == null
                              ? 'Add more data to improve forecasting.'
                              : 'Estimated ovulation: ${formatPretty(prediction.ovulationDate!)}\n'
                                    'Estimated fertile window: ${formatPretty(prediction.fertileStart!)} - ${formatPretty(prediction.fertileEnd!)}\n'
                                    'Next predicted period: ${formatPretty(prediction.nextPeriodStart!)} - ${formatPretty(prediction.nextPeriodEnd!)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _sheetSummary({
    required DateTime day,
    required CycleStatus cycleStatus,
    required Set<String> periodDays,
    required Set<String> predictedPeriodDays,
    required Set<String> fertileDays,
    required String? ovulationDay,
  }) {
    final key = dateKey(day);
    if (periodDays.contains(key)) {
      return 'This day is part of a logged period.';
    }
    if (ovulationDay == key) {
      return 'This is the estimated ovulation day for your current predicted cycle.';
    }
    if (fertileDays.contains(key)) {
      return 'This day falls within your estimated fertile window.';
    }
    if (predictedPeriodDays.contains(key)) {
      return 'This day is inside the next predicted period range.';
    }
    return 'Current phase: ${cycleStatus.phase}. Use this view to compare logs with predictions.';
  }

  Widget _statusDay(
    BuildContext context,
    DateTime day, {
    required Color bgColor,
    required bool showOvulationIcon,
    Color textColor = Colors.white,
    Color? borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showOvulationIcon)
            const Icon(Icons.auto_awesome, size: 11, color: Colors.white),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        radius: 10,
        backgroundColor: color,
        child: icon == null ? null : Icon(icon, size: 12, color: Colors.white),
      ),
      label: Text(label),
    );
  }
}

class _QuickLogPreview extends StatelessWidget {
  const _QuickLogPreview({required this.entry});

  final Symptoms entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mood: ${entry.mood.name}'),
        Text('Flow: ${entry.flow.name}'),
        if (entry.items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.items
                .map((item) => Chip(label: Text(item)))
                .toList(growable: false),
          ),
        ],
        if (entry.notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(entry.notes),
        ],
      ],
    );
  }
}
