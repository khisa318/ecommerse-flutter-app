import 'package:intl/intl.dart';

String formatKsh(
  double amount, {
  int decimalDigits = 2,
}) {
  final formatter = NumberFormat.currency(
    symbol: 'KSh ',
    decimalDigits: decimalDigits,
    locale: 'en_KE', // Kenya uses standard grouping
  );
  return formatter.format(amount);
}
