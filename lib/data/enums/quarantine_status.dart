enum QuarantineStatus {
  active,
  lifted;

  static QuarantineStatus fromWire(String? value) {
    return value == 'lifted' ? QuarantineStatus.lifted : QuarantineStatus.active;
  }

  String get wire => this == QuarantineStatus.active ? 'active' : 'lifted';

  String get label => this == QuarantineStatus.active ? 'Active' : 'Lifted';
}
