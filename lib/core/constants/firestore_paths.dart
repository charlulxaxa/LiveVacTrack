/// Firestore collection names. Only official accounts use Firestore; demo
/// mode runs offline on the in-memory demo store.
class FirestorePaths {
  const FirestorePaths._();

  static const String users = 'users';
  static const String farmers = 'farmers';
  static const String animals = 'animals';
  static const String vaccinations = 'vaccinations';
  static const String permits = 'permits';
  static const String quarantines = 'quarantines';
  static const String verifications = 'verifications';
}
