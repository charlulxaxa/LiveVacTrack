import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/firestore_paths.dart';
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

/// Which Firestore data set the signed-in account uses: demo accounts get the
/// `demo_*` collections, official accounts the plain ones. Repositories watch
/// this, so they switch automatically when a different account signs in.
final Provider<FirestorePaths> firestorePathsProvider =
    Provider<FirestorePaths>((Ref ref) {
  final bool isDemo = ref.watch(
    currentUserProvider.select((AppUser? user) => user?.isDemo ?? false),
  );
  return FirestorePaths.forUser(isDemo: isDemo);
});
