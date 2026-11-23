import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Converts Firestore timestamps, ISO strings and epoch values to [DateTime].
DateTime? dateFromValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59);

DateTime? minDate(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isBefore(b) ? a : b;
}

String formatDate(DateTime? value) {
  if (value == null) return 'Not set';
  return DateFormat('MMM d, yyyy').format(value);
}

String formatDateTime(DateTime? value) {
  if (value == null) return 'Not set';
  return DateFormat('MMM d, yyyy • h:mm a').format(value);
}

String formatTime(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('h:mm a').format(value);
}

String formatRelative(DateTime value) {
  final Duration diff = DateTime.now().difference(value);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return formatDate(value);
}

String lastSyncedLabel(DateTime? value) =>
    value == null ? 'Not synced yet' : 'Last synced ${formatTime(value)}';
