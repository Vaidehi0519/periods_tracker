import 'package:hive/hive.dart';

import '../models/cycle_record.dart';

class CycleRepository {
  CycleRepository(this._box);

  final Box<dynamic> _box;

  List<CycleRecord> getCycles() {
    return _box.values
        .map((value) => CycleRecord.fromMap(Map<dynamic, dynamic>.from(value)))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<void> addCycle(CycleRecord cycle) async {
    await _box.add(cycle.toMap());
  }
}
