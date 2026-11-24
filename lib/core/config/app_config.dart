/// Application-wide configuration.
///
/// Demo mode is switched on the login screen (see `demoModeProvider`). It
/// runs offline with the built-in demo accounts and sample data; with it off,
/// official accounts use Firebase.
class AppConfig {
  const AppConfig._();

  static const String appName = 'LiveVacTrack';
  static const String appTagline = 'Vaccination and movement permit tracker';

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

  /// Offline destinations for permits in demo mode (live mode lists every
  /// barangay in the country from the PSGC service).
  static const List<AreaOption> demoDestinations = <AreaOption>[
    ...areas,
    AreaOption(id: 'legazpi', name: 'Legazpi City'),
    AreaOption(id: 'daraga', name: 'Daraga'),
    AreaOption(id: 'sorsogon', name: 'Sorsogon City'),
    AreaOption(id: 'naga', name: 'Naga City'),
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
