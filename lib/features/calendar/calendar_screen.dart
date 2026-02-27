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

  @override
  Widget build(BuildContext context) {
    final periodDays = ref.watch(periodDayKeysProvider);
    final prediction = ref.watch(predictionProvider);

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
              availableGestures: AvailableGestures.all,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final key = dateKey(day);
                  if (periodDays.contains(key)) {
                    return _statusDay(context, day, const Color(0xFFE7749B), 'P');
                  }
                  if (prediction.ovulationDate != null &&
                      isSameDay(day, prediction.ovulationDate)) {
                    return _statusDay(context, day, const Color(0xFF46A89D), 'O');
                  }
                  if (prediction.fertileStart != null &&
                      prediction.fertileEnd != null &&
                      !day.isBefore(prediction.fertileStart!) &&
                      !day.isAfter(prediction.fertileEnd!)) {
                    return _statusDay(context, day, const Color(0xFF70C4B8), 'F');
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
                _LegendChip(label: 'P  Period', color: Color(0xFFE7749B)),
                _LegendChip(label: 'O  Ovulation', color: Color(0xFF46A89D)),
                _LegendChip(label: 'F  Fertile', color: Color(0xFF70C4B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDay(BuildContext context, DateTime day, Color color, String label) {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}\n$label',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.08,
            ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(radius: 8, backgroundColor: color),
      label: Text(label),
    );
  }
}
