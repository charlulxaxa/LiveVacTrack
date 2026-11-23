import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livevactrack/app.dart';

void main() {
  testWidgets('demo mode shows the sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LiveVacTrackApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('DEMO ACCOUNTS'), findsOneWidget);
  });
}
