enum PermitStatus {
  issued,
  revoked,
  expired;

  static PermitStatus fromWire(String? value) {
    switch (value) {
      case 'revoked':
        return PermitStatus.revoked;
      case 'expired':
        return PermitStatus.expired;
      default:
        return PermitStatus.issued;
    }
  }

  String get wire {
    switch (this) {
      case PermitStatus.issued:
        return 'issued';
      case PermitStatus.revoked:
        return 'revoked';
      case PermitStatus.expired:
        return 'expired';
    }
  }

  String get label {
    switch (this) {
      case PermitStatus.issued:
        return 'Issued';
      case PermitStatus.revoked:
        return 'Revoked';
      case PermitStatus.expired:
        return 'Expired';
    }
  }
}
