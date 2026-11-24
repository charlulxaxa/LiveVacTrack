import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Demo mode uses an in-memory store so the app runs without a Firebase
  // project. Live mode requires the setup described in README.md.
  if (!AppConfig.demoMode) {
    await initFirebase();
  }

  // Disable Riverpod's automatic retry app-wide: Firestore streams already
  // reconnect on their own, and retrying terminal errors (permission-denied,
  // missing index) just loops the loading spinner instead of showing the error.
  runApp(ProviderScope(
    retry: (int retryCount, Object error) => null,
    child: const LiveVacTrackApp(),
  ));
}
