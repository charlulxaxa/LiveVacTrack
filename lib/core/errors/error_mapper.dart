import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

/// Turns Firebase errors into messages a field officer can act on.
class ErrorMapper {
  const ErrorMapper._();

  static AppException auth(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return const AppException('That email address is not valid.');
        case 'user-disabled':
          return const AppException('This account has been disabled.');
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return const AppException('Email or password is incorrect.');
        case 'too-many-requests':
          return const AppException('Too many attempts. Try again later.');
        case 'network-request-failed':
          return const AppException('No connection. Check your signal.');
        default:
          return AppException(error.message ?? 'Sign in failed.');
      }
    }
    // Signed in, but loading the user profile from Firestore failed.
    if (error is FirebaseException) {
      return AppException(
        'Signed in, but your profile could not be loaded '
        '(${error.code}): ${error.message ?? ''}',
      );
    }
    return const AppException('Sign in failed. Please try again.');
  }

  static AppException firestore(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const AppException(
            'Your role is not allowed to do that. Contact the vet office admin.',
          );
        case 'unavailable':
          return const AppException(
            'You are offline. This change will sync when you reconnect.',
          );
        case 'failed-precondition':
          return const AppException(
            'The database needs an index for this query. Check the Firebase console.',
          );
        default:
          return AppException(error.message ?? 'The request could not be completed.');
      }
    }
    return const AppException('The request could not be completed.');
  }

  static AppException functions(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unauthenticated':
          return const AppException('Please sign in again.');
        case 'permission-denied':
          return const AppException('Your role is not allowed to do that.');
        case 'failed-precondition':
          return AppException(error.message ?? 'The permit cannot be issued.');
        case 'invalid-argument':
          return AppException(error.message ?? 'Check the details you entered.');
        case 'unavailable':
          return const AppException(
            'The permit service is unreachable. Try again when you have signal.',
          );
        case 'deadline-exceeded':
          return const AppException('The permit service took too long. Try again.');
        case 'not-found':
          return const AppException(
            'This server function is not deployed. Deploy the Cloud Functions '
            '(firebase deploy --only functions) and try again.',
          );
        default:
          return AppException(error.message ?? 'The permit service failed.');
      }
    }
    return const AppException('The permit service failed.');
  }
}
