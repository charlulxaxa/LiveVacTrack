import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firestore_paths.dart';
import '../enums/user_role.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      return _loadUser(user);
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential =
        await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User? user = credential.user;
    if (user == null) {
      throw const AuthFailure('Sign in did not return a user.');
    }
    return _loadUser(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _loadUser(User user) async {
    // Without a timeout, an unreachable Firestore backend leaves the app on
    // the loading spinner forever instead of showing an error.
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .get()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
            message: 'Could not reach Cloud Firestore. Check the internet '
                'connection and that the Firestore database exists.',
          ),
        );

    if (snapshot.exists) {
      return AppUser.fromMap(user.uid, snapshot.data()!);
    }

    // Fallback to custom claims when the profile document has not been created.
    // Forcing a refresh hits the network, so it needs a timeout too.
    final IdTokenResult token = await user.getIdTokenResult(true).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Timed out refreshing the sign-in token.',
          ),
        );
    return AppUser(
      id: user.uid,
      displayName: user.displayName ?? user.email ?? 'Staff member',
      role: UserRole.fromWire(token.claims?['role'] as String?),
    );
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
