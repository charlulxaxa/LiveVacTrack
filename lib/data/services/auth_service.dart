import 'dart:async';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../enums/user_role.dart';

/// Shown when a deactivated or removed staff account tries to sign in.
const String deactivatedMessage =
    'This account has been deactivated. Contact the super admin.';

abstract class AuthService {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();
}

class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.user,
  });

  final String email;
  final String password;
  final AppUser user;
}

class DemoAuthService implements AuthService {
  DemoAuthService();

  static final List<DemoAccount> accounts = <DemoAccount>[
    DemoAccount(
      email: 'admin@livevactrack.test',
      password: AppConfig.demoPassword,
      user: const AppUser(
        id: 'u-admin',
        displayName: 'Super Admin',
        role: UserRole.admin,
        areaId: 'poblacion',
      ),
    ),
    DemoAccount(
      email: 'registry@livevactrack.test',
      password: AppConfig.demoPassword,
      user: const AppUser(
        id: 'u-registry',
        displayName: 'Rita Reyes',
        role: UserRole.registry,
        areaId: 'poblacion',
      ),
    ),
    DemoAccount(
      email: 'vet@livevactrack.test',
      password: AppConfig.demoPassword,
      user: const AppUser(
        id: 'u-vet',
        displayName: 'Dr. Vic Santos',
        role: UserRole.vet,
        areaId: 'poblacion',
      ),
    ),
    DemoAccount(
      email: 'clerk@livevactrack.test',
      password: AppConfig.demoPassword,
      user: const AppUser(
        id: 'u-clerk',
        displayName: 'Carla Dizon',
        role: UserRole.clerk,
        areaId: 'poblacion',
      ),
    ),
    DemoAccount(
      email: 'inspector@livevactrack.test',
      password: AppConfig.demoPassword,
      user: const AppUser(
        id: 'u-inspector',
        displayName: 'Insp. Noel Garcia',
        role: UserRole.inspector,
        areaId: 'san-jose',
      ),
    ),
    DemoAccount(
      email: 'disease@livevactrack.test',
      password: AppConfig.demoPassword,
      user: const AppUser(
        id: 'u-disease',
        displayName: 'Dr. Maya Lim',
        role: UserRole.diseaseControl,
        areaId: 'poblacion',
      ),
    ),
  ];

  /// Accounts the super admin deactivated in demo mode.
  static final Set<String> disabledIds = <String>{};

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final String normalised = email.trim().toLowerCase();
    for (final DemoAccount account in accounts) {
      if (account.email == normalised && account.password == password) {
        if (disabledIds.contains(account.user.id)) {
          throw const AppException(deactivatedMessage);
        }
        _current = account.user;
        _controller.add(_current);
        return account.user;
      }
    }
    throw const AppException('Email or password is incorrect.');
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}
