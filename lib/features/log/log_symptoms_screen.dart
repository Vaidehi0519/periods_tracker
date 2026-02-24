import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_helpers.dart';
import '../../data/models/symptom_entry.dart';
import '../../providers/app_providers.dart';

class LogSymptomsScreen extends ConsumerStatefulWidget {
  const LogSymptomsScreen({super.key});

  @override
  ConsumerState<LogSymptomsScreen> createState() => _LogSymptomsScreenState();
}

class _LogSymptomsScreenState extends ConsumerState<LogSymptomsScreen> {
  DateTime _selectedDate = DateTime.now();
  MoodType _mood = MoodType.happy;
  FlowIntensity _flow = FlowIntensity.medium;
  final Set<String> _symptoms = <String>{};
  final _noteController = TextEditingController();

  static const _allSymptoms = ['cramps', 'headache', 'bloating', 'acne'];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(symptomsProvider)[dateKey(_selectedDate)];
    if (entry != null && _noteController.text.isEmpty && _symptoms.isEmpty) {
      _mood = entry.mood;
      _flow = entry.flow;
      _symptoms.addAll(entry.symptoms);
      _noteController.text = entry.notes;
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Log Symptoms', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Date'),
              subtitle: Text(formatPretty(_selectedDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: _selectedDate,
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _symptoms.clear();
                    _noteController.clear();
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Text('Mood', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: MoodType.values
                .map(
                  (m) => ChoiceChip(
                    label: Text(m.name),
                    selected: _mood == m,
                    onSelected: (_) => setState(() => _mood = m),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text('Symptoms', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: _allSymptoms
                .map(
                  (symptom) => FilterChip(
                    label: Text(symptom),
                    selected: _symptoms.contains(symptom),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _symptoms.add(symptom);
                        } else {
                          _symptoms.remove(symptom);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text('Flow intensity', style: Theme.of(context).textTheme.titleMedium),
          SegmentedButton<FlowIntensity>(
            segments: FlowIntensity.values
                .map(
                  (f) => ButtonSegment<FlowIntensity>(
                    value: f,
                    label: Text(f.name),
                  ),
                )
                .toList(),
            selected: {_flow},
            onSelectionChanged: (selection) {
              setState(() {
                _flow = selection.first;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Notes',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref.read(symptomsProvider.notifier).upsert(
                    SymptomEntry(
                      date: _selectedDate,
                      mood: _mood,
                      symptoms: _symptoms.toList(),
                      flow: _flow,
                      notes: _noteController.text.trim(),
                    ),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved')),
                );
              }
            },
            child: const Text('Save Log'),
          ),
        ],
      ),
    );
  }
}
