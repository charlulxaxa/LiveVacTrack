class Validators {
  const Validators._();

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final RegExp pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? minLength(String? value, int length, [String label = 'Value']) {
    if (value == null || value.isEmpty) return '$label is required';
    if (value.length < length) return '$label must be at least $length characters';
    return null;
  }

  static String? positiveNumber(String? value, [String label = 'Value']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return '$label must be a positive number';
    return null;
  }

  /// The end date must be strictly after the start date.
  static String? dateAfter(
    DateTime? end,
    DateTime? start, {
    String message = 'End date must be after the start date',
  }) {
    if (end == null) return 'Date is required';
    if (start != null && !end.isAfter(start)) return message;
    return null;
  }

  static String? notInPast(DateTime? value, {String message = 'Date cannot be in the past'}) {
    if (value == null) return 'Date is required';
    final DateTime today = DateTime.now();
    final DateTime day = DateTime(value.year, value.month, value.day);
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    if (day.isBefore(todayOnly)) return message;
    return null;
  }
}
