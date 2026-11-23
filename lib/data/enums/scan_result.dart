enum ScanResult {
  valid,
  expired,
  revoked,
  invalid,
  unverified;

  static ScanResult fromWire(String? value) {
    switch (value) {
      case 'valid':
        return ScanResult.valid;
      case 'expired':
        return ScanResult.expired;
      case 'revoked':
        return ScanResult.revoked;
      case 'unverified':
        return ScanResult.unverified;
      default:
        return ScanResult.invalid;
    }
  }

  String get wire {
    switch (this) {
      case ScanResult.valid:
        return 'valid';
      case ScanResult.expired:
        return 'expired';
      case ScanResult.revoked:
        return 'revoked';
      case ScanResult.invalid:
        return 'invalid';
      case ScanResult.unverified:
        return 'unverified';
    }
  }

  String get label {
    switch (this) {
      case ScanResult.valid:
        return 'VALID';
      case ScanResult.expired:
        return 'EXPIRED';
      case ScanResult.revoked:
        return 'REVOKED';
      case ScanResult.invalid:
        return 'INVALID';
      case ScanResult.unverified:
        return 'UNVERIFIED';
    }
  }
}
