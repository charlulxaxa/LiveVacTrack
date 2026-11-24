/// Firestore collection names.
///
/// `users` is shared. Every other collection exists twice: the official data
/// set (`farmers`, ...) used by official accounts, and the demo data set
/// (`demo_farmers`, ...) used only by the built-in demo accounts. Use
/// [FirestorePaths.forUser] to get the right set for the signed-in account.
class FirestorePaths {
  const FirestorePaths._(this.prefix);

  /// Official data set.
  static const FirestorePaths official = FirestorePaths._('');

  /// Demo data set.
  static const FirestorePaths demo = FirestorePaths._('demo_');

  static FirestorePaths forUser({required bool isDemo}) =>
      isDemo ? demo : official;

  static const String users = 'users';

  final String prefix;

  bool get isDemo => prefix.isNotEmpty;

  String get farmers => '${prefix}farmers';
  String get animals => '${prefix}animals';
  String get vaccinations => '${prefix}vaccinations';
  String get permits => '${prefix}permits';
  String get quarantines => '${prefix}quarantines';
  String get verifications => '${prefix}verifications';
}
