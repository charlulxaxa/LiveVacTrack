import '../../core/errors/app_exception.dart';
import '../enums/user_role.dart';
import '../models/app_user.dart';
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
}

/// Demo mode: appends the account to [DemoAuthService.accounts] so it can be
/// used to sign in immediately.
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
      ),
    );

    return StaffAccountResult(uid: id, email: normalised);
  }
}
