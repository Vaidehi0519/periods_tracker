enum MoodType { happy, sad, anxious, tired }

enum FlowIntensity { light, medium, heavy }

class SymptomEntry {
  SymptomEntry({
    required this.date,
    required this.mood,
    required this.symptoms,
    required this.flow,
    required this.notes,
  });

  final DateTime date;
  final MoodType mood;
  final List<String> symptoms;
  final FlowIntensity flow;
  final String notes;

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'mood': mood.name,
      'symptoms': symptoms,
      'flow': flow.name,
      'notes': notes,
    };
  }

  factory SymptomEntry.fromMap(Map<dynamic, dynamic> map) {
    final rawSymptoms = map['symptoms'];
    final symptoms = switch (rawSymptoms) {
      List<dynamic>() => rawSymptoms.map((e) => e.toString()).toList(),
      String() => rawSymptoms
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      _ => <String>[],
    };

    return SymptomEntry(
      date: DateTime.parse(map['date'] as String),
      mood: MoodType.values.firstWhere((e) => e.name == map['mood']),
      symptoms: symptoms,
      flow: FlowIntensity.values.firstWhere((e) => e.name == map['flow']),
      notes: (map['notes'] as String?) ?? '',
    );
  }
}
