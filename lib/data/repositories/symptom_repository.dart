import 'package:hive/hive.dart';

import '../../core/utils/date_helpers.dart';
import '../models/symptom_entry.dart';

class SymptomRepository {
  SymptomRepository(this._box);

  final Box<dynamic> _box;

  Map<String, SymptomEntry> getEntries() {
    return _box.toMap().map(
          (key, value) => MapEntry(
            key as String,
            SymptomEntry.fromMap(Map<dynamic, dynamic>.from(value)),
          ),
        );
  }

  Future<void> upsertEntry(SymptomEntry entry) async {
    await _box.put(dateKey(entry.date), entry.toMap());
  }

  SymptomEntry? getByDate(DateTime date) {
    final item = _box.get(dateKey(date));
    if (item == null) {
      return null;
    }
    return SymptomEntry.fromMap(Map<dynamic, dynamic>.from(item));
  }
}
