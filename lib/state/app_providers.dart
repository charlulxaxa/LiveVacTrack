import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demo mode as saved on the device; main() overrides this before the app
/// starts so the login screen opens in the mode last used.
final Provider<bool> initialDemoModeProvider =
    Provider<bool>((Ref ref) => false);

/// The login screen's "Demo mode" switch.
///
/// On: the built-in demo accounts and sample data run entirely offline from
/// the in-memory demo store; nothing touches Firebase or the network.
/// Off: official accounts sign in through Firebase.
class DemoModeController extends Notifier<bool> {
  static const String _key = 'demo_mode';

  @override
  bool build() => ref.read(initialDemoModeProvider);

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
    } catch (_) {
      // Only a convenience; the switch still works for this session.
    }
  }

  static Future<bool> loadSaved() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }
}

final NotifierProvider<DemoModeController, bool> demoModeProvider =
    NotifierProvider<DemoModeController, bool>(DemoModeController.new);

class OfflineSimulator extends Notifier<bool> {
  @override
  bool build() => false;

  void setValue(bool value) => state = value;

  void toggle() => state = !state;
}

final NotifierProvider<OfflineSimulator, bool> offlineSimulatorProvider =
    NotifierProvider<OfflineSimulator, bool>(OfflineSimulator.new);

final StreamProvider<bool> connectivityProvider = StreamProvider<bool>((Ref ref) {
  return _connectivityStream();
});

Stream<bool> _connectivityStream() async* {
  final Connectivity connectivity = Connectivity();
  yield _isOnline(await connectivity.checkConnectivity());
  await for (final List<ConnectivityResult> results
      in connectivity.onConnectivityChanged) {
    yield _isOnline(results);
  }
}

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((ConnectivityResult result) =>
      result != ConnectivityResult.none);
}

/// True when the device is offline or the user enabled the demo offline switch.
final Provider<bool> isOfflineProvider = Provider<bool>((Ref ref) {
  final bool simulated = ref.watch(offlineSimulatorProvider);
  final bool online = ref.watch(connectivityProvider).value ?? true;
  return simulated || !online;
});

class LastSynced extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void markNow() => state = DateTime.now();
}

final NotifierProvider<LastSynced, DateTime?> lastSyncedProvider =
    NotifierProvider<LastSynced, DateTime?>(LastSynced.new);
