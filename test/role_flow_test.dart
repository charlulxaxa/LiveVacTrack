import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livevactrack/app.dart';
import 'package:livevactrack/state/app_providers.dart';

Future<void> _signIn(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'demo1234');
  await tester.tap(find.text('Sign in').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [initialDemoModeProvider.overrideWithValue(true)],
    child: const LiveVacTrackApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('super admin account opens staff provisioning', (tester) async {
    await _pumpApp(tester);
    await _signIn(tester, 'admin@livevactrack.test');

    expect(find.text('Super admin'), findsOneWidget);
    expect(find.text('Add staff account'), findsWidgets);
  });

  testWidgets('registry account opens the farmer registry', (tester) async {
    await _pumpApp(tester);
    await _signIn(tester, 'registry@livevactrack.test');

    expect(find.text('Registry office'), findsOneWidget);
    expect(find.text('Farmers'), findsWidgets);
  });

  testWidgets('vet account opens the vaccination workspace', (tester) async {
    await _pumpApp(tester);
    await _signIn(tester, 'vet@livevactrack.test');

    expect(find.text('Veterinary office'), findsOneWidget);
    expect(find.text('Vaccinate'), findsWidgets);
  });

  testWidgets('clerk account opens the permit office', (tester) async {
    await _pumpApp(tester);
    await _signIn(tester, 'clerk@livevactrack.test');

    expect(find.text('Permit office'), findsOneWidget);
    expect(find.text('Issue'), findsWidgets);
  });

  testWidgets('disease control account opens quarantine tools', (tester) async {
    await _pumpApp(tester);
    await _signIn(tester, 'disease@livevactrack.test');

    expect(find.text('Disease control'), findsOneWidget);
    expect(find.text('Declare'), findsWidgets);
  });

  testWidgets('inspector account opens the checkpoint scanner', (tester) async {
    await _pumpApp(tester);
    await _signIn(tester, 'inspector@livevactrack.test');

    expect(find.text('Checkpoint'), findsOneWidget);
    expect(find.text('Scan permit QR'), findsOneWidget);
  });

  testWidgets('bad password keeps the sign-in screen', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'clerk@livevactrack.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.text('Sign in').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.text('Permit office'), findsNothing);
  });
}
