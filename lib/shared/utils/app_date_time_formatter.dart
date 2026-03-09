class AppDateTimeFormatter {
  AppDateTimeFormatter._();

  // Global app date-time format: dd/MM/yyyy hh:mm a
  static String formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final hour = hour12.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year $hour:$minute $period';
  }

  static String formatString(String raw, {String fallback = '-'}) {
    final value = raw.trim();
    if (value.isEmpty) {
      return fallback;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return formatDateTime(parsed);
  }
}
