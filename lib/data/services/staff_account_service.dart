import 'dart:async';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../enums/user_role.dart';
import '../models/app_user.dart';
import '../models/staff_member.dart';
import 'auth_service.dart';

/// Result returned after a staff account has been created.
class StaffAccountResult {
  const StaffAccountResult({required this.uid, required this.email});

  final String uid;
  final String email;
}

abstract class StaffAccountService {
  Future<StaffAccountResult> createStaffAccount({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String areaId,
    required String areaName,
  });

  /// Staff accounts for the super admin's Staff tab. Excludes admins and
  /// removed accounts.
  Stream<List<StaffMember>> watchStaff();

  /// Starts a password reset for [member]. Returns a message for the admin
  /// describing what happened.
  Future<String> resetPassword(StaffMember member);

  /// Deactivated accounts cannot sign in until reactivated.
  Future<void> setDisabled(StaffMember member, {required bool disabled});

  /// Permanently blocks the account and hides it from the Staff tab.
  Future<void> removeStaff(StaffMember member);
}

/// Demo mode: appends the account to [DemoAuthService.accounts] so it can be
/// used to sign in immediately. Created accounts are flagged `isDemo: false`
/// so they are not listed as demo accounts on the login screen.
class DemoStaffAccountService implements StaffAccountService {
  @override
  Future<StaffAccountResult> createStaffAccount({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String areaId,
    required String areaName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final String normalised = email.trim().toLowerCase();
    if (normalised.isEmpty) {
      throw const AppException('Email is required.');
    }
    if (!normalised.contains('@') || normalised.endsWith('@')) {
      throw const AppException('Enter a valid email address.');
    }
    if (displayName.trim().isEmpty) {
      throw const AppException('Display name is required.');
    }
    if (password.length < 8) {
      throw const AppException('Password must be at least 8 characters.');
    }
    if (DemoAuthService.accounts
        .any((DemoAccount account) => account.email == normalised)) {
      throw const AppException('That email is already registered.');
    }

    final String id = 'u-${DateTime.now().microsecondsSinceEpoch}';
    DemoAuthService.accounts.add(
      DemoAccount(
        email: normalised,
        password: password,
        user: AppUser(
          id: id,
          displayName: displayName.trim(),
          role: UserRole.fromWire(role),
          areaId: areaId,
          areaName: areaName,
        ),
        isDemo: false,
      ),
    );

    _changes.add(null);
    return StaffAccountResult(uid: id, email: normalised);
  }

  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  List<StaffMember> _snapshot() {
    final List<StaffMember> members = DemoAuthService.accounts
        .where((DemoAccount a) => a.user.role != UserRole.admin)
        .map((DemoAccount a) => StaffMember(
              id: a.user.id,
              displayName: a.user.displayName,
              role: a.user.role,
              email: a.email,
              areaName: a.user.areaName ?? a.user.areaId,
              disabled: DemoAuthService.disabledIds.contains(a.user.id),
            ))
        .toList()
      ..sort((StaffMember a, StaffMember b) => a.displayName
          .toLowerCase()
          .compareTo(b.displayName.toLowerCase()));
    return members;
  }

  @override
  Stream<List<StaffMember>> watchStaff() async* {
    yield _snapshot();
    await for (final void _ in _changes.stream) {
      yield _snapshot();
    }
  }

  @override
  Future<String> resetPassword(StaffMember member) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final int index = DemoAuthService.accounts
        .indexWhere((DemoAccount a) => a.user.id == member.id);
    if (index < 0) throw const AppException('That account no longer exists.');
    final DemoAccount account = DemoAuthService.accounts[index];
    DemoAuthService.accounts[index] = DemoAccount(
      email: account.email,
      password: AppConfig.demoPassword,
      user: account.user,
      isDemo: account.isDemo,
    );
    return 'Demo mode: password for ${account.email} reset to '
        '${AppConfig.demoPassword}.';
  }

  @override
  Future<void> setDisabled(StaffMember member, {required bool disabled}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (disabled) {
      DemoAuthService.disabledIds.add(member.id);
    } else {
      DemoAuthService.disabledIds.remove(member.id);
    }
    _changes.add(null);
  }

  @override
  Future<void> removeStaff(StaffMember member) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    DemoAuthService.accounts
        .removeWhere((DemoAccount a) => a.user.id == member.id);
    DemoAuthService.disabledIds.remove(member.id);
    _changes.add(null);
  }
}
