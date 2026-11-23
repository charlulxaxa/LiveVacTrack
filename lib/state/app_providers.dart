import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
