import 'symptoms.dart';

export 'symptoms.dart' show FlowIntensity, MoodType, Symptoms;

class SymptomEntry extends Symptoms {
  SymptomEntry({
    required super.date,
    required super.mood,
    required List<String> symptoms,
    required super.flow,
    required super.notes,
  }) : super(items: symptoms);

  List<String> get symptoms => items;

  factory SymptomEntry.fromMap(Map<dynamic, dynamic> map) {
    final symptom = Symptoms.fromMap(map);
    return SymptomEntry(
      date: symptom.date,
      mood: symptom.mood,
      symptoms: symptom.items,
      flow: symptom.flow,
      notes: symptom.notes,
    );
  }
}
