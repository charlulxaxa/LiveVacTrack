import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livevactrack/core/services/psgc_location_service.dart';
import 'package:livevactrack/ui/molecules/dropdown_field.dart';
import 'package:livevactrack/ui/molecules/location_picker.dart';

void main() {
  testWidgets('searchable dropdown filters a long list', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownField<String>(
              label: 'Barangay',
              value: null,
              searchable: true,
              items: const <DropdownOption<String>>[
                DropdownOption<String>(value: 'poblacion', label: 'Poblacion'),
                DropdownOption<String>(value: 'san-jose', label: 'San Jose'),
                DropdownOption<String>(value: 'sta-cruz', label: 'Sta. Cruz'),
              ],
              onChanged: (String? value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Select an option'));
    await tester.pumpAndSettle();
    expect(find.text('Poblacion'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'jose');
    await tester.pumpAndSettle();
    expect(find.text('Poblacion'), findsNothing);
    expect(find.text('San Jose'), findsOneWidget);

    await tester.tap(find.text('San Jose'));
    await tester.pumpAndSettle();
    expect(selected, 'san-jose');
  });

  testWidgets('demo location picker returns a seeded area', (tester) async {
    AreaSelection? selection;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LocationPicker(
                onChanged: (AreaSelection? value) => selection = value,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barangay San Jose').last);
    await tester.pumpAndSettle();

    expect(selection?.id, 'san-jose');
    expect(selection?.name, 'Barangay San Jose');
  });
}
