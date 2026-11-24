import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:livevactrack/app.dart';
import 'package:livevactrack/state/app_providers.dart';
import 'package:livevactrack/ui/organisms/login_form.dart';

void main() {
  testWidgets('demo mode shows the sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialDemoModeProvider.overrideWithValue(true)],
        child: const LiveVacTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('DEMO ACCOUNTS'), findsOneWidget);
  });

  testWidgets('demo accounts are listed only while demo mode is on',
      (WidgetTester tester) async {
    bool demoMode = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                rebuild = setState;
                return LoginForm(
                  onSubmit: (String email, String password) async {},
                  demoMode: demoMode,
                  onDemoModeChanged: (bool value) =>
                      rebuild(() => demoMode = value),
                  demoPassword: 'demo1234',
                  demoCredentials: const <LoginDemoCredential>[
                    LoginDemoCredential(
                      email: 'vet@livevactrack.test',
                      roleLabel: 'Vet',
                      name: 'Dr. Vic Santos',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Demo mode (offline)'), findsOneWidget);
    expect(find.text('DEMO ACCOUNTS'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(demoMode, isTrue);
    expect(find.text('DEMO ACCOUNTS'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('DEMO ACCOUNTS'), findsNothing);
  });
}
