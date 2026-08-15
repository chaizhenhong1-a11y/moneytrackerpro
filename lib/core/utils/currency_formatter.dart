abstract final class CurrencyFormatter {
  static String myr(double value, {bool showSign = false}) {
    final sign = showSign && value > 0 ? '+' : '';
    final absolute = value.abs().toStringAsFixed(2);
    final parts = absolute.split('.');
    final digits = parts.first;
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final negative = value < 0 ? '-' : '';
    return '$sign${negative}RM $formatted.${parts.last}';
  }
}
