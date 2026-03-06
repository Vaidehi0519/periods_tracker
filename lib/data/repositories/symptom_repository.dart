import 'package:hive/hive.dart';

import '../../core/utils/date_helpers.dart';
import '../models/symptoms.dart';

class SymptomRepository {
  SymptomRepository(this._box);

  final Box<dynamic> _box;

  Map<String, Symptoms> getEntries() {
    return _box.toMap().map(
      (key, value) => MapEntry(
        key as String,
        Symptoms.fromMap(Map<dynamic, dynamic>.from(value as Map)),
      ),
    );
  }

  Future<void> upsertEntry(Symptoms entry) async {
    final normalized = entry.normalized();
    await _box.put(dateKey(normalized.date), normalized.toMap());
  }

  Symptoms? getByDate(DateTime date) {
    final item = _box.get(dateKey(normalizeDate(date)));
    if (item == null) {
      return null;
    }
    return Symptoms.fromMap(Map<dynamic, dynamic>.from(item as Map));
  }
}
