enum VaxStatus {
  valid,
  expired,
  none;

  static VaxStatus fromWire(String? value) {
    switch (value) {
      case 'valid':
        return VaxStatus.valid;
      case 'expired':
        return VaxStatus.expired;
      default:
        return VaxStatus.none;
    }
  }

  String get wire {
    switch (this) {
      case VaxStatus.valid:
        return 'valid';
      case VaxStatus.expired:
        return 'expired';
      case VaxStatus.none:
        return 'none';
    }
  }

  String get label {
    switch (this) {
      case VaxStatus.valid:
        return 'Vaccinated';
      case VaxStatus.expired:
        return 'Expired';
      case VaxStatus.none:
        return 'Not vaccinated';
    }
  }
}
