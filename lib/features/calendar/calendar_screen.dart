import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Calendar', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar<void>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2035),
                focusedDay: _focusedDay,
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final key = dateKey(day);
                    if (periodDays.contains(key)) {
                      return _dotDay(context, day, Colors.pink.shade300, 'P');
                    }
                    if (prediction.ovulationDate != null &&
                        isSameDay(day, prediction.ovulationDate)) {
                      return _dotDay(context, day, Colors.green.shade300, 'O');
                    }
                    if (prediction.fertileStart != null &&
                        prediction.fertileEnd != null &&
                        !day.isBefore(prediction.fertileStart!) &&
                        !day.isAfter(prediction.fertileEnd!)) {
                      return _dotDay(context, day, Colors.teal.shade200, 'F');
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _LegendChip(label: 'P Period', color: Colors.pink),
              _LegendChip(label: 'O Ovulation', color: Colors.green),
              _LegendChip(label: 'F Fertile', color: Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dotDay(BuildContext context, DateTime day, Color color, String label) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(
        '${day.day}\n$label',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              height: 1.1,
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
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      label: Text(label),
    );
  }
}
