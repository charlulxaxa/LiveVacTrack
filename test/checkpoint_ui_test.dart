import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:livevactrack/core/errors/app_exception.dart';
import 'package:livevactrack/core/services/checkpoint_store.dart';
import 'package:livevactrack/data/enums/scan_result.dart';
import 'package:livevactrack/data/enums/user_role.dart';
import 'package:livevactrack/data/models/app_user.dart';
import 'package:livevactrack/data/models/verification.dart';
import 'package:livevactrack/pages/permit_verify_page.dart';
import 'package:livevactrack/ui/atoms/app_skeleton.dart';
import 'package:livevactrack/ui/molecules/scan_success_dialog.dart';
import 'package:livevactrack/ui/organisms/farmer_registry_view.dart';
import 'package:livevactrack/ui/organisms/permit_verifier_view.dart';
import 'package:livevactrack/ui/organisms/profile_view.dart';

VerificationOutcome _outcome(ScanResult result) => VerificationOutcome(
  result: result,
  message: 'Checked.',
  checkedAt: DateTime(2026, 11, 23, 9, 30),
  signatureValid: result == ScanResult.valid,
  offline: false,
);

Widget _app(Widget child, {double textScale = 1}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
}

void main() {
  group('PermitVerifyPage', () {
    testWidgets('verifies once on open and shows the verdict', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      await tester.pumpWidget(
        _app(
          PermitVerifyPage(
            permitId: 'PMT-1',
            signedCode: 'sig',
            checkpointName: 'San Jose Checkpoint',
            onVerify:
                ({
                  required String permitId,
                  required String signedCode,
                  required String checkpointName,
                }) async {
                  calls++;
                  expect(permitId, 'PMT-1');
                  expect(checkpointName, 'San Jose Checkpoint');
                  return _outcome(ScanResult.valid);
                },
          ),
        ),
      );

      expect(find.text('Checking permit PMT-1…'), findsOneWidget);
      await tester.pump();
      await tester.pump();

      expect(calls, 1);
      expect(find.text('VALID'), findsOneWidget);
      expect(find.text('Allow passage'), findsOneWidget);
      expect(find.text('Scan another permit'), findsOneWidget);
    });

    testWidgets('shows the error and retries on Try again', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      await tester.pumpWidget(
        _app(
          PermitVerifyPage(
            permitId: 'PMT-2',
            signedCode: 'sig',
            checkpointName: 'Gate',
            onVerify:
                ({
                  required String permitId,
                  required String signedCode,
                  required String checkpointName,
                }) async {
                  calls++;
                  if (calls == 1) {
                    throw const AppException('Server unreachable.');
                  }
                  return _outcome(ScanResult.revoked);
                },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Server unreachable.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();

      expect(calls, 2);
      expect(find.text('REVOKED'), findsOneWidget);
    });

    testWidgets('fits at large text size', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          PermitVerifyPage(
            permitId: 'PMT-3',
            signedCode: 'sig',
            checkpointName: 'A rather long checkpoint name for the test',
            onVerify: ({
              required String permitId,
              required String signedCode,
              required String checkpointName,
            }) async => _outcome(ScanResult.unverified),
          ),
          textScale: 1.3,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('UNVERIFIED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ScanSuccessDialog', () {
    Future<bool?> open(WidgetTester tester, String button) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async {
                result = await ScanSuccessDialog.show(
                  context,
                  permitId: 'PMT-9',
                  checkpointName: 'North Gate',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Permit scanned'), findsOneWidget);
      expect(find.text('PMT-9'), findsOneWidget);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('Continue returns true', (WidgetTester tester) async {
      expect(await open(tester, 'Continue'), isTrue);
    });

    testWidgets('Scan again returns false', (WidgetTester tester) async {
      expect(await open(tester, 'Scan again'), isFalse);
    });
  });

  group('PermitVerifierView', () {
    Future<List<String>> pumpView(WidgetTester tester) async {
      // Phone-sized portrait screen so the expanded form fits.
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final List<String> opened = <String>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: PermitVerifierView(
              offline: false,
              onOpenVerification:
                  ({
                    required String permitId,
                    required String signedCode,
                    required String checkpointName,
                  }) async {
                    opened.add('$permitId|$signedCode|$checkpointName');
                  },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return opened;
    }

    testWidgets('shows the saved checkpoint name', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'checkpoint_name': 'Bagulin Checkpoint',
      });
      await pumpView(tester);
      expect(find.text('At Bagulin Checkpoint'), findsOneWidget);
    });

    testWidgets('opening manual entry turns the camera off', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final List<String> opened = await pumpView(tester);
      expect(find.byType(MobileScanner), findsOneWidget);

      await tester.tap(find.text('Enter code manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MobileScanner), findsNothing);
      expect(find.text('Camera off while you enter a code'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'PMT-5');
      await tester.enterText(find.byType(TextFormField).at(1), 'code-5');
      await tester.ensureVisible(find.text('Verify permit'));
      await tester.pump();
      await tester.tap(find.text('Verify permit'));
      await tester.pump();
      expect(opened, <String>['PMT-5|code-5|${CheckpointStore.defaultName}']);

      await tester.ensureVisible(find.text('Use camera'));
      await tester.pump();
      await tester.tap(find.text('Use camera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('manual entry needs both fields', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final List<String> opened = await pumpView(tester);
      await tester.tap(find.text('Enter code manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('Verify permit'));
      await tester.pump();
      await tester.tap(find.text('Verify permit'));
      await tester.pump();
      expect(opened, isEmpty);
      expect(
        find.text('Enter both the permit ID and the signed code.'),
        findsOneWidget,
      );
    });
  });

  test('CheckpointStore saves and loads the name', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    expect(await CheckpointStore.load(), CheckpointStore.defaultName);
    await CheckpointStore.save('  East Gate  ');
    expect(await CheckpointStore.load(), 'East Gate');
  });

  group('ProfileView', () {
    const AppUser user = AppUser(
      id: 'uid-123',
      displayName: 'Test User',
      role: UserRole.vet,
    );

    Widget profile({required bool demoMode}) => _app(
      Scaffold(
        body: ProfileView(
          user: user,
          demoMode: demoMode,
          offlineSimulated: false,
          onOfflineChanged: (_) {},
          onSignOut: () {},
        ),
      ),
    );

    testWidgets('live mode hides developer details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(profile(demoMode: false));
      expect(find.text('uid-123'), findsNothing);
      expect(find.text('Simulate offline mode'), findsNothing);
      expect(find.text('Live Firebase'), findsNothing);
      expect(find.textContaining('CC105'), findsNothing);
    });

    testWidgets('demo mode keeps the testing tools', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(profile(demoMode: true));
      expect(find.text('uid-123'), findsOneWidget);
      expect(find.text('Simulate offline mode'), findsOneWidget);
      expect(find.text('Demo mode'), findsOneWidget);
    });
  });

  testWidgets('lists show skeletons only while loading', (
    WidgetTester tester,
  ) async {
    Widget farmers({required bool loading}) => _app(
      Scaffold(
        body: FarmerRegistryView(
          farmers: const [],
          loading: loading,
          limit: 20,
          onLoadMore: () {},
        ),
      ),
    );

    await tester.pumpWidget(farmers(loading: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SkeletonListTile), findsWidgets);

    await tester.pumpWidget(farmers(loading: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SkeletonListTile), findsNothing);
    expect(find.text('No farmers yet'), findsOneWidget);
  });
}
