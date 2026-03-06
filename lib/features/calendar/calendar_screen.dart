import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/ui/app_shell.dart';
import '../../core/utils/date_helpers.dart';
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
    final fertileDays = ref.watch(fertileDayKeysProvider);
    final ovulationDay = ref.watch(ovulationDayKeyProvider);
    final prediction = ref.watch(predictionProvider);
    final predictedPeriodDay = prediction.nextPeriodDate == null
        ? null
        : dateKey(
            DateTime(
              prediction.nextPeriodDate!.year,
              prediction.nextPeriodDate!.month,
              prediction.nextPeriodDate!.day,
            ),
          );

    return AppGradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            title: 'Calendar',
            subtitle: 'Period, ovulation, and fertile window view',
          ),
          const SizedBox(height: 14),
          AppSectionCard(
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
              },
              availableGestures: AvailableGestures.all,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
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
                  if (predictedPeriodDay == key) {
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
          const SizedBox(height: 12),
          const AppSectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _LegendChip(label: 'Period', color: Color(0xFFE53935)),
                _LegendChip(label: 'Predicted period', color: Color(0xFFFFCDD2)),
                _LegendChip(label: 'Fertile window', color: Color(0xFFA5D6A7)),
                _LegendChip(
                  label: 'Ovulation',
                  color: Color(0xFF1B5E20),
                  icon: Icons.auto_awesome,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
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
                      : 'Ovulation: ${formatPretty(prediction.ovulationDate!)}\n'
                          'Fertile window: ${formatPretty(prediction.fertileStart!)} - '
                          '${formatPretty(prediction.fertileEnd!)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        border: borderColor == null ? null : Border.all(color: borderColor, width: 1.2),
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
            const Icon(
              Icons.auto_awesome,
              size: 11,
              color: Colors.white,
            ),
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
