String formatKsh(
  double amount, {
  int decimalDigits = 2,
}) {
  return 'KSh ${amount.toStringAsFixed(decimalDigits)}';
}
