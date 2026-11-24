import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/firebase/firebase_bootstrap.dart';
import 'state/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialising Firebase is local (no network round trip), so it does not
  // slow demo mode down. Demo mode never uses Firebase after this; if setup
  // fails, demo mode still works and official sign-in shows the error.
  try {
    await initFirebase();
  } catch (_) {}

  final bool demoMode = await DemoModeController.loadSaved();

  // Disable Riverpod's automatic retry app-wide: Firestore streams already
  // reconnect on their own, and retrying terminal errors (permission-denied,
  // missing index) just loops the loading spinner instead of showing the error.
  runApp(ProviderScope(
    retry: (int retryCount, Object error) => null,
    overrides: [initialDemoModeProvider.overrideWithValue(demoMode)],
    child: const LiveVacTrackApp(),
  ));
}
