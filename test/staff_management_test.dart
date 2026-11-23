import 'package:flutter_test/flutter_test.dart';
import 'package:livevactrack/core/config/app_config.dart';
import 'package:livevactrack/core/errors/app_exception.dart';
import 'package:livevactrack/data/enums/user_role.dart';
import 'package:livevactrack/data/models/staff_member.dart';
import 'package:livevactrack/data/services/auth_service.dart';
import 'package:livevactrack/data/services/staff_account_service.dart';

void main() {
  final DemoStaffAccountService staff = DemoStaffAccountService();
  final DemoAuthService auth = DemoAuthService();

  Future<StaffMember> create(String email) async {
    await staff.createStaffAccount(
      email: email,
      password: 'original-pass',
      displayName: 'Test Person',
      role: 'vet',
      areaId: 'poblacion',
      areaName: 'Barangay Poblacion',
    );
    final List<StaffMember> members = await staff.watchStaff().first;
    return members.firstWhere((StaffMember m) => m.email == email);
  }

  test('staff list excludes the super admin', () async {
    final List<StaffMember> members = await staff.watchStaff().first;
    expect(members, isNotEmpty);
    expect(members.any((StaffMember m) => m.role == UserRole.admin), isFalse);
  });

  test('deactivated accounts cannot sign in until reactivated', () async {
    final StaffMember member = await create('deactivate@livevactrack.test');

    await staff.setDisabled(member, disabled: true);
    final StaffMember listed = (await staff.watchStaff().first)
        .firstWhere((StaffMember m) => m.id == member.id);
    expect(listed.disabled, isTrue);
    await expectLater(
      auth.signIn(email: member.email!, password: 'original-pass'),
      throwsA(isA<AppException>().having(
          (AppException e) => e.message, 'message', deactivatedMessage)),
    );

    await staff.setDisabled(member, disabled: false);
    final user =
        await auth.signIn(email: member.email!, password: 'original-pass');
    expect(user.id, member.id);
  });

  test('reset password sets the demo password', () async {
    final StaffMember member = await create('reset@livevactrack.test');
    await staff.resetPassword(member);
    final user = await auth.signIn(
      email: member.email!,
      password: AppConfig.demoPassword,
    );
    expect(user.id, member.id);
  });

  test('removed accounts disappear and cannot sign in', () async {
    final StaffMember member = await create('remove@livevactrack.test');
    await staff.removeStaff(member);
    final List<StaffMember> members = await staff.watchStaff().first;
    expect(members.any((StaffMember m) => m.id == member.id), isFalse);
    await expectLater(
      auth.signIn(email: member.email!, password: 'original-pass'),
      throwsA(isA<AppException>()),
    );
  });
}
