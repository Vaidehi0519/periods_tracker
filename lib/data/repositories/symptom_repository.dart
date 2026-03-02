import 'package:hive/hive.dart';

import '../../core/utils/date_helpers.dart';
import '../models/symptom_entry.dart';

class SymptomRepository {
  SymptomRepository(this._box);

  final Box<dynamic> _box;

  Map<String, SymptomEntry> getEntries() {
    final result = <String, SymptomEntry>{};
    for (final item in _box.toMap().entries) {
      try {
        final key = item.key.toString();
        final value = Map<dynamic, dynamic>.from(item.value as Map);
        result[key] = SymptomEntry.fromMap(value);
      } catch (_) {
        // Skip malformed legacy data instead of breaking Insights loading.
      }
    }
    return result;
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
