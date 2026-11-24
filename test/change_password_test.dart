import 'package:flutter_test/flutter_test.dart';
import 'package:livevactrack/core/config/app_config.dart';
import 'package:livevactrack/core/errors/app_exception.dart';
import 'package:livevactrack/data/services/auth_service.dart';

void main() {
  const String email = 'vet@livevactrack.test';

  tearDown(() async {
    // Accounts are static; put the demo password back for other tests.
    final int i =
        DemoAuthService.accounts.indexWhere((DemoAccount a) => a.email == email);
    final DemoAccount a = DemoAuthService.accounts[i];
    DemoAuthService.accounts[i] = DemoAccount(
      email: a.email,
      password: AppConfig.demoPassword,
      user: a.user,
      isDemo: a.isDemo,
    );
  });

  test('wrong current password is rejected', () async {
    final DemoAuthService auth = DemoAuthService();
    await auth.signIn(email: email, password: AppConfig.demoPassword);
    expect(
      () => auth.changePassword(
        currentPassword: 'not-it',
        newPassword: 'newpass123',
      ),
      throwsA(isA<AppException>().having(
        (AppException e) => e.message,
        'message',
        'Your current password is incorrect.',
      )),
    );
  });

  test('short or unchanged new passwords are rejected', () {
    expect(validateNewPassword('short'), isNotNull);
    expect(
      validateNewPassword('samepass1', currentPassword: 'samepass1'),
      isNotNull,
    );
    expect(validateNewPassword('newpass123', currentPassword: 'old'), isNull);
  });

  test('password change takes effect at the next sign in', () async {
    final DemoAuthService auth = DemoAuthService();
    await auth.signIn(email: email, password: AppConfig.demoPassword);
    await auth.changePassword(
      currentPassword: AppConfig.demoPassword,
      newPassword: 'newpass123',
    );
    await auth.signOut();

    expect(
      () => auth.signIn(email: email, password: AppConfig.demoPassword),
      throwsA(isA<AppException>()),
    );
    final user = await auth.signIn(email: email, password: 'newpass123');
    expect(user.isDemo, isTrue);
  });
}
