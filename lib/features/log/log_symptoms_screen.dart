import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_shell.dart';
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
  final TextEditingController _newSymptomController = TextEditingController();

  static const _initialSymptoms = ['cramps', 'headache', 'bloating', 'acne'];
  final Set<String> _allSymptoms = _initialSymptoms.toSet();

  @override
  void dispose() {
    _noteController.dispose();
    _newSymptomController.dispose();
    super.dispose();
  }

  void _hydrateFromEntry(SymptomEntry? entry) {
    _symptoms.clear();
    _noteController.clear();
    if (entry == null) {
      _mood = MoodType.happy;
      _flow = FlowIntensity.medium;
      return;
    }
    _mood = entry.mood;
    _flow = entry.flow;
    _symptoms.addAll(entry.symptoms);
    _noteController.text = entry.notes;
  }

  void _addNewSymptom() {
    final newSymptom = _newSymptomController.text.trim();
    if (newSymptom.isNotEmpty && !_allSymptoms.contains(newSymptom)) {
      setState(() {
        _allSymptoms.add(newSymptom);
        _symptoms.add(newSymptom);
      });
      _newSymptomController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(symptomsProvider)[dateKey(_selectedDate)];
    if (_noteController.text.isEmpty && _symptoms.isEmpty) {
      _hydrateFromEntry(entry);
    }

    return AppGradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            title: 'Log Symptoms',
            subtitle: 'Daily mood, flow, and symptoms in one place',
          ),
          const SizedBox(height: 14),
          AppSectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Selected Date'),
              subtitle: Text(formatPretty(_selectedDate)),
              trailing: IconButton.filledTonal(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: _selectedDate,
                  );
                  if (picked == null) {
                    return;
                  }
                  setState(() {
                    _selectedDate = picked;
                    _hydrateFromEntry(ref.read(symptomsProvider)[dateKey(picked)]);
                  });
                },
                icon: const Icon(Icons.calendar_month),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mood', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: MoodType.values
                      .map(
                        (mood) => ChoiceChip(
                          label: Text(mood.name),
                          selected: _mood == mood,
                          onSelected: (_) => setState(() => _mood = mood),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Text('Symptoms', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flow Intensity', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<FlowIntensity>(
                  segments: FlowIntensity.values
                      .map(
                        (flow) => ButtonSegment<FlowIntensity>(
                          value: flow,
                          label: Text(flow.name),
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
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Anything else you want to remember today...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Custom Symptom', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newSymptomController,
                        decoration: const InputDecoration(
                          labelText: 'New Symptom',
                          hintText: 'Enter a symptom',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addNewSymptom,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
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
                    const SnackBar(content: Text('Log saved')),
                  );
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Today\'s Log'),
            ),
          ),
        ],
      ),
    );
  }
}
