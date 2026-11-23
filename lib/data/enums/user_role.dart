enum UserRole {
  admin,
  registry,
  vet,
  clerk,
  inspector,
  diseaseControl,
  unknown;

  static UserRole fromWire(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'registry':
        return UserRole.registry;
      case 'vet':
        return UserRole.vet;
      case 'clerk':
        return UserRole.clerk;
      case 'inspector':
        return UserRole.inspector;
      case 'disease_control':
      case 'diseaseControl':
        return UserRole.diseaseControl;
      default:
        return UserRole.unknown;
    }
  }

  String get wire {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.registry:
        return 'registry';
      case UserRole.vet:
        return 'vet';
      case UserRole.clerk:
        return 'clerk';
      case UserRole.inspector:
        return 'inspector';
      case UserRole.diseaseControl:
        return 'disease_control';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Super admin';
      case UserRole.registry:
        return 'Registry staff';
      case UserRole.vet:
        return 'Veterinarian';
      case UserRole.clerk:
        return 'Permit clerk';
      case UserRole.inspector:
        return 'Checkpoint inspector';
      case UserRole.diseaseControl:
        return 'Disease control officer';
      case UserRole.unknown:
        return 'Unassigned';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.registry:
        return 'Registry';
      case UserRole.vet:
        return 'Vet';
      case UserRole.clerk:
        return 'Clerk';
      case UserRole.inspector:
        return 'Inspector';
      case UserRole.diseaseControl:
        return 'Disease control';
      case UserRole.unknown:
        return 'Unassigned';
    }
  }
}
