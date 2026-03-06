import '../../core/utils/date_helpers.dart';

enum MoodType { happy, sad, anxious, tired }

enum FlowIntensity { light, medium, heavy }

class Symptoms {
  Symptoms({
    required this.date,
    required this.mood,
    required this.items,
    required this.flow,
    required this.notes,
  });

  final DateTime date;
  final MoodType mood;
  final List<String> items;
  final FlowIntensity flow;
  final String notes;

  Symptoms normalized() {
    return Symptoms(
      date: normalizeDate(date),
      mood: mood,
      items: items.map((item) => item.trim()).where((item) => item.isNotEmpty).toSet().toList(),
      flow: flow,
      notes: notes.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    final normalized = this.normalized();
    return {
      'date': normalized.date.toIso8601String(),
      'mood': normalized.mood.name,
      'symptoms': normalized.items,
      'flow': normalized.flow.name,
      'notes': normalized.notes,
    };
  }

  factory Symptoms.fromMap(Map<dynamic, dynamic> map) {
    MoodType readMood() {
      final raw = map['mood'] as String?;
      return MoodType.values.where((value) => value.name == raw).firstOrNull ?? MoodType.happy;
    }

    FlowIntensity readFlow() {
      final raw = map['flow'] as String?;
      return FlowIntensity.values.where((value) => value.name == raw).firstOrNull ?? FlowIntensity.medium;
    }

    final dateValue = map['date'] as String?;
    return Symptoms(
      date: dateValue == null ? DateTime.now() : DateTime.parse(dateValue),
      mood: readMood(),
      items: List<String>.from((map['symptoms'] as List<dynamic>? ?? const <dynamic>[])),
      flow: readFlow(),
      notes: (map['notes'] as String?) ?? '',
    ).normalized();
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
