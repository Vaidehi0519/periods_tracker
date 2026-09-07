import 'package:intl/intl.dart';

String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

DateTime normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String formatPretty(DateTime date) => DateFormat('EEE, MMM d').format(date);
