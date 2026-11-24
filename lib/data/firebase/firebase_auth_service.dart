import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
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
      try {
        return await _loadUser(user);
      } on AppException catch (error) {
        // A deactivated account was signed out in _loadUser. Treat it as
        // signed out so the login page stays up; signIn() reports the reason.
        if (error.message == deactivatedMessage) return null;
        rethrow;
      }
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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final User? user = _auth.currentUser;
    final String? email = user?.email;
    if (user == null || email == null) {
      throw const AppException('Sign in again to change your password.');
    }
    final String? problem =
        validateNewPassword(newPassword, currentPassword: currentPassword);
    if (problem != null) throw AppException(problem);

    // Firebase only lets a recently signed-in user change the password, and
    // this is also where the current password is checked.
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          throw const AppException('Your current password is incorrect.');
        case 'too-many-requests':
          throw const AppException(
            'Too many attempts. Wait a few minutes and try again.',
          );
        case 'network-request-failed':
          throw const AppException('No connection. Check your signal.');
        default:
          throw AppException(error.message ?? 'Could not check your password.');
      }
    }

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'weak-password') {
        throw const AppException('That password is too weak.');
      }
      throw AppException(error.message ?? 'Could not change your password.');
    }
  }

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
      final Map<String, dynamic> data = snapshot.data()!;
      // Deactivated or removed by the super admin. The Firebase sign-in still
      // exists (only the Admin SDK can disable it), so end the session here.
      if (data['disabled'] == true || data['removed'] == true) {
        await _auth.signOut();
        throw const AppException(deactivatedMessage);
      }
      return AppUser.fromMap(user.uid, data);
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
