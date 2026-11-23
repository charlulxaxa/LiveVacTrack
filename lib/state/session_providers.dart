import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import 'repository_providers.dart';

// Riverpod 3 retries failed providers automatically (up to 10 times with
// backoff). Each retry resubscribes and puts the gate back on the splash, so a
// failing profile load looked like an endless loading loop. Surface the error
// immediately instead; the error screen has its own "Try again" button.
final StreamProvider<AppUser?> authStateProvider = StreamProvider<AppUser?>(
  (Ref ref) {
    return ref.watch(authServiceProvider).authStateChanges();
  },
  retry: (int retryCount, Object error) => null,
);

final Provider<AppUser?> currentUserProvider = Provider<AppUser?>((Ref ref) {
  return ref.watch(authStateProvider).value;
});
