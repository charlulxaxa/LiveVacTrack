/// Application-wide configuration.
///
/// The app runs in demo mode by default so the full flow can be demonstrated
/// without a Firebase project. Build with
/// `--dart-define=DEMO_MODE=false` after completing the Firebase setup in the
/// README to use the real Authentication, Firestore and Cloud Functions.
class AppConfig {
  const AppConfig._();

  static const String appName = 'LiveVacTrack';
  static const String appTagline = 'Vaccination and movement permit tracker';

  /// Demo mode uses an in-memory data store and a local HMAC signer.
  static const bool demoMode =
      bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  static const int pageSize = 20;
  static const String demoPassword = 'demo1234';

  /// Demo-only signing secret. The real secret lives in Cloud Functions.
  static const String demoSigningSecret = 'livevactrack-demo-secret';

  static const List<AreaOption> areas = <AreaOption>[
    AreaOption(id: 'poblacion', name: 'Barangay Poblacion'),
    AreaOption(id: 'san-jose', name: 'Barangay San Jose'),
    AreaOption(id: 'sta-cruz', name: 'Barangay Sta. Cruz'),
    AreaOption(id: 'bagong-sikat', name: 'Barangay Bagong Sikat'),
  ];

  static String areaName(String id) {
    for (final AreaOption area in areas) {
      if (area.id == id) return area.name;
    }
    return id;
  }
}

class AreaOption {
  const AreaOption({required this.id, required this.name});

  final String id;
  final String name;
}
