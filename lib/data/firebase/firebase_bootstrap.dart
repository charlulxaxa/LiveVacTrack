import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Initialises Firebase for live mode. Demo mode never calls this, so the app
/// runs without a Firebase project during development and demos.
Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Verbose Firestore logs in debug builds to diagnose connection problems.
    if (kDebugMode) FirebaseFirestore.setLoggingEnabled(true);
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    rethrow;
  }
}