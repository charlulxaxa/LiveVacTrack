import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../enums/user_role.dart';
import '../models/staff_member.dart';
import '../services/staff_account_service.dart';

/// Live mode: creates staff accounts directly from the admin's device, so it
/// works on the free Spark plan without the `createStaffAccount` Cloud
/// Function.
///
/// `createUserWithEmailAndPassword` signs the new user in on whichever
/// FirebaseAuth instance runs it. Running it on a separate, named FirebaseApp
/// keeps the admin signed in on the main app.
///
/// The role lives in the `users/{uid}` document, which the app reads at sign
/// in. Custom claims cannot be set from a client; that needs the Admin SDK.
class FirebaseStaffAccountService implements StaffAccountService {
  FirebaseStaffAccountService(
    this._auth,
    this._firestore, {
    required this.viewerIsDemo,
  });

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// The demo admin sees only demo accounts; an official admin sees only
  /// official accounts.
  final bool viewerIsDemo;

  static const String _provisioningAppName = 'staff-provisioning';

  static const Set<UserRole> _staffRoles = <UserRole>{
    UserRole.registry,
    UserRole.vet,
    UserRole.clerk,
    UserRole.inspector,
    UserRole.diseaseControl,
  };

  Future<FirebaseApp> _provisioningApp() async {
    for (final FirebaseApp app in Firebase.apps) {
      if (app.name == _provisioningAppName) return app;
    }
    return Firebase.initializeApp(
      name: _provisioningAppName,
      options: Firebase.app().options,
    );
  }

  @override
  Future<StaffAccountResult> createStaffAccount({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String areaId,
    required String areaName,
  }) async {
    final String normalisedEmail = email.trim().toLowerCase();
    final String name = displayName.trim();
    final String area = areaId.trim();
    final UserRole userRole = UserRole.fromWire(role);

    if (normalisedEmail.isEmpty || name.isEmpty || area.isEmpty) {
      throw const AppException('Email, display name and area are required.');
    }
    if (!_staffRoles.contains(userRole)) {
      throw const AppException('Select a valid staff role.');
    }
    if (password.length < 8) {
      throw const AppException('Password must be at least 8 characters.');
    }

    final FirebaseAuth provisioningAuth =
        FirebaseAuth.instanceFor(app: await _provisioningApp());

    final User newUser;
    try {
      final UserCredential credential =
          await provisioningAuth.createUserWithEmailAndPassword(
        email: normalisedEmail,
        password: password,
      );
      newUser = credential.user!;
    } on FirebaseAuthException catch (error) {
      throw _mapCreateError(error);
    }

    try {
      await newUser.updateDisplayName(name);
      // Written with the admin's session on the main app.
      await _firestore.collection(FirestorePaths.users).doc(newUser.uid).set(
        <String, dynamic>{
          'displayName': name,
          'email': normalisedEmail,
          'role': userRole.wire,
          'areaId': area,
          'areaName': areaName.trim().isEmpty ? area : areaName.trim(),
          // Accounts created by an admin are always official accounts.
          'isDemo': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (error) {
      // Without the profile document the account has no role, so remove the
      // half-created login rather than leave an orphan behind.
      try {
        await newUser.delete();
      } catch (_) {}
      throw ErrorMapper.firestore(error);
    } finally {
      await provisioningAuth.signOut();
    }

    return StaffAccountResult(uid: newUser.uid, email: normalisedEmail);
  }

  @override
  Stream<List<StaffMember>> watchStaff() {
    return _firestore
        .collection(FirestorePaths.users)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<StaffMember> members = snapshot.docs
          .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              doc.data()['removed'] != true &&
              (doc.data()['isDemo'] == true) == viewerIsDemo)
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              StaffMember.fromMap(doc.id, doc.data()))
          .where((StaffMember m) => m.role != UserRole.admin)
          .toList()
        ..sort((StaffMember a, StaffMember b) => a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase()));
      return members;
    });
  }

  /// Clients cannot set another user's password (that needs the Admin SDK),
  /// so this sends Firebase's reset email and the staff member picks a new
  /// password themselves.
  @override
  Future<String> resetPassword(StaffMember member) async {
    final String? email = member.email;
    if (email == null || email.isEmpty) {
      throw const AppException(
        'No email is stored for this account. Reset it from the Firebase '
        'console under Authentication.',
      );
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw ErrorMapper.auth(error);
    }
    return 'Password reset email sent to $email.';
  }

  @override
  Future<void> setDisabled(StaffMember member, {required bool disabled}) async {
    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(member.id)
          .update(<String, dynamic>{
        'disabled': disabled,
        'disabledAt': disabled ? FieldValue.serverTimestamp() : null,
      });
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
  }

  /// The sign-in itself can only be deleted with the Admin SDK (or in the
  /// Firebase console), so the profile is kept as a tombstone: disabled and
  /// hidden. Deleting the document instead would let accounts that carry a
  /// role custom claim fall back to that claim and keep their access.
  @override
  Future<void> removeStaff(StaffMember member) async {
    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(member.id)
          .update(<String, dynamic>{
        'disabled': true,
        'removed': true,
        'removedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
  }

  AppException _mapCreateError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return const AppException('That email is already registered.');
      case 'invalid-email':
        return const AppException('That email address is not valid.');
      case 'weak-password':
        return const AppException('That password is too weak.');
      case 'operation-not-allowed':
        return const AppException(
          'Email/password sign-in is disabled in the Firebase console.',
        );
      case 'network-request-failed':
        return const AppException('No connection. Check your signal.');
      default:
        return AppException(error.message ?? 'Could not create the account.');
    }
  }
}
