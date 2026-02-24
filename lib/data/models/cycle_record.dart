class CycleRecord {
  CycleRecord({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  int get periodLength => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory CycleRecord.fromMap(Map<dynamic, dynamic> map) {
    return CycleRecord(
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
    );
  }
}
