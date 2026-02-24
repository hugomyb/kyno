import 'package:intl/intl.dart';

final NumberFormat _decimalFr = NumberFormat('0.##', 'fr_FR');

String formatDecimalFr(num value) {
  return _decimalFr.format(value);
}
