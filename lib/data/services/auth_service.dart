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

  /// Changes the signed-in account's password after checking
  /// [currentPassword]. Throws an [AppException] with a readable message.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

/// Shared password rules for every place a password is set.
String? validateNewPassword(String newPassword, {String? currentPassword}) {
  if (newPassword.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  if (currentPassword != null && newPassword == currentPassword) {
    return 'The new password must be different from the current one.';
  }
  return null;
}

class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.user,
    this.isDemo = true,
  });

  final String email;
  final String password;
  final AppUser user;

  /// True for the seeded demo accounts listed on the login screen. Accounts
  /// created by the super admin are real staff accounts and set this false.
  final bool isDemo;
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
        isDemo: true,
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
        isDemo: true,
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
        isDemo: true,
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
        isDemo: true,
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
        isDemo: true,
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
        isDemo: true,
      ),
    ),
  ];

  /// Seeded demo accounts only (excludes accounts created by the admin).
  static List<DemoAccount> get demoAccounts =>
      accounts.where((DemoAccount a) => a.isDemo).toList();

  /// Whether [userId] belongs to a seeded demo account.
  static bool isDemoUser(String userId) =>
      accounts.any((DemoAccount a) => a.isDemo && a.user.id == userId);

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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final AppUser? current = _current;
    final int index = current == null
        ? -1
        : accounts.indexWhere((DemoAccount a) => a.user.id == current.id);
    if (index < 0) {
      throw const AppException('Sign in again to change your password.');
    }
    final DemoAccount account = accounts[index];
    if (account.password != currentPassword) {
      throw const AppException('Your current password is incorrect.');
    }
    final String? problem =
        validateNewPassword(newPassword, currentPassword: currentPassword);
    if (problem != null) throw AppException(problem);
    accounts[index] = DemoAccount(
      email: account.email,
      password: newPassword,
      user: account.user,
      isDemo: account.isDemo,
    );
  }
}
