import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the inspector's checkpoint name on this device, so it does not
/// have to be typed again for every scan or after restarting the app.
class CheckpointStore {
  const CheckpointStore._();

  static const String defaultName = 'San Jose Checkpoint';
  static const String _key = 'checkpoint_name';

  /// Falls back to [defaultName] when nothing is saved or storage is
  /// unavailable.
  static Future<String> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(_key)?.trim();
      return saved == null || saved.isEmpty ? defaultName : saved;
    } catch (_) {
      return defaultName;
    }
  }

  static Future<void> save(String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, trimmed);
    } catch (_) {
      // Not saving only means the name is asked for again next launch.
    }
  }
}
