import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livevactrack/data/enums/scan_result.dart';
import 'package:livevactrack/data/models/verification.dart';
import 'package:livevactrack/ui/molecules/verification_result_panel.dart';

void main() {
  testWidgets('offline outcome is labelled UNVERIFIED, never VALID', (
    tester,
  ) async {
    final VerificationOutcome outcome = VerificationOutcome(
      result: ScanResult.unverified,
      message: 'You are offline.',
      checkedAt: DateTime.now(),
      signatureValid: false,
      offline: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VerificationResultPanel(outcome: outcome)),
      ),
    );

    expect(find.text('UNVERIFIED'), findsOneWidget);
    expect(find.text('VALID'), findsNothing);
    expect(find.text('Offline result'), findsOneWidget);
    expect(find.text('Signature not verified'), findsOneWidget);
  });

  testWidgets('online valid outcome is labelled VALID', (tester) async {
    final VerificationOutcome outcome = VerificationOutcome(
      result: ScanResult.valid,
      message: 'Signed code verified.',
      checkedAt: DateTime.now(),
      signatureValid: true,
      offline: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VerificationResultPanel(outcome: outcome)),
      ),
    );

    expect(find.text('VALID'), findsOneWidget);
    expect(find.text('Server checked'), findsOneWidget);
  });
}
