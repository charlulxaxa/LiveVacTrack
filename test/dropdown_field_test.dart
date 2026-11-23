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

  group('menu dropdown with subtitles (Owner / Animal pickers)', () {
    const List<DropdownOption<String>> owners = <DropdownOption<String>>[
      DropdownOption<String>(
        value: 'f1',
        label: 'Juan Dela Cruz',
        subtitle: 'Barangay Poblacion',
      ),
      DropdownOption<String>(
        value: 'f2',
        label: 'Maria Clara Santos de los Reyes y Bautista',
        subtitle: 'Bagutot, Bacnotan, La Union, a long barangay description',
      ),
    ];

    Widget owner({String? value, double textScale = 1}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownField<String>(
                label: 'Owner',
                value: value,
                items: owners,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    for (final double scale in <double>[1, 1.3]) {
      testWidgets('menu rows fit at text scale $scale', (tester) async {
        await tester.pumpWidget(owner(textScale: scale));
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Juan Dela Cruz'), findsWidgets);
        expect(find.text('Barangay Poblacion'), findsWidgets);
      });
    }

    testWidgets('closed field shows only the label', (tester) async {
      await tester.pumpWidget(owner(value: 'f1'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Juan Dela Cruz'), findsOneWidget);
      expect(find.text('Barangay Poblacion'), findsNothing);
    });
  });

  testWidgets('searchable sheet fits a short screen with the keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownField<String>(
              label: 'Province',
              value: null,
              searchable: true,
              items: <DropdownOption<String>>[
                for (int i = 0; i < 30; i++)
                  DropdownOption<String>(
                    value: 'p$i',
                    label: 'Province $i',
                    subtitle: 'Region $i',
                  ),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Select an option'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Province'), findsWidgets);
  });
}
