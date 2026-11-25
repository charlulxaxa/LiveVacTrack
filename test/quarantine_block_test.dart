import 'package:flutter_test/flutter_test.dart';

import 'package:livevactrack/core/errors/app_exception.dart';
import 'package:livevactrack/data/demo/demo_store.dart';
import 'package:livevactrack/data/enums/quarantine_status.dart';
import 'package:livevactrack/data/enums/user_role.dart';
import 'package:livevactrack/data/models/animal.dart';
import 'package:livevactrack/data/models/app_user.dart';
import 'package:livevactrack/data/models/permit.dart';
import 'package:livevactrack/data/models/quarantine.dart';
import 'package:livevactrack/data/repositories/permit_repository.dart';
import 'package:livevactrack/data/repositories/quarantine_repository.dart';
import 'package:livevactrack/state/quarantine_providers.dart';
import 'package:livevactrack/core/utils/quarantine_scope.dart';

const AppUser clerk = AppUser(
  id: 'u-clerk',
  displayName: 'Carla Dizon',
  role: UserRole.clerk,
  areaId: 'poblacion',
);

const AppUser officer = AppUser(
  id: 'u-disease',
  displayName: 'Dr. Maya Lim',
  role: UserRole.diseaseControl,
  areaId: 'poblacion',
);

void main() {
  final DemoStore store = DemoStore.instance;
  final DemoPermitRepository permits = DemoPermitRepository(store);
  final DemoQuarantineRepository quarantines = DemoQuarantineRepository(store);

  Future<Permit> issueFor(Animal animal) => permits.issuePermit(
        animal: animal,
        origin: animal.barangay,
        destination: 'Legazpi City',
        travelDate: DateTime.now().add(const Duration(days: 1)),
        clerk: clerk,
      );

  test('no permit for an animal moving out of a quarantined area', () async {
    // a1 is registered in Poblacion (no quarantine) but leaves from San Jose,
    // which has the seeded active quarantine.
    final Animal animal = store.animalById('a1')!;
    await expectLater(
      permits.issuePermit(
        animal: animal,
        origin: 'Barangay San Jose',
        destination: 'Legazpi City',
        travelDate: DateTime.now().add(const Duration(days: 1)),
        clerk: clerk,
        originAreaId: 'san-jose',
      ),
      throwsA(isA<AppException>().having(
        (AppException e) => e.message,
        'message',
        contains('origin'),
      )),
    );
  });

  test('no permit while the quarantine is active; allowed once lifted',
      () async {
    // Seeded: an active quarantine on San Jose; a2 is a vaccinated animal there.
    final Quarantine active = store.activeQuarantineFor('san-jose')!;
    final Animal animal = store.animalById('a2')!;

    await expectLater(
      issueFor(animal),
      throwsA(isA<AppException>().having(
        (AppException e) => e.message,
        'message',
        contains('quarantine'),
      )),
    );

    await quarantines.liftQuarantine(quarantineId: active.id, officer: officer);
    expect(store.activeQuarantineFor('san-jose'), isNull);

    final Permit permit = await issueFor(animal);
    expect(permit.animalId, 'a2');
  });

  test('a quarantine on one barangay blocks every barangay in its municipality',
      () {
    // Two barangays of Guinobatan, Albay, and one of Adams, Ilocos Norte.
    store.addQuarantine(
      Quarantine(
        id: 'q-guinobatan',
        areaId: '0500504042',
        areaName: 'Quibongbongan, Guinobatan, Albay',
        reason: 'Test',
        status: QuarantineStatus.active,
        startedAt: DateTime.now(),
      ),
    );

    expect(store.activeQuarantineFor('0500504001'), isNotNull);
    expect(store.activeQuarantineFor('0102801001'), isNull);

    // The same check the clerk's form and animal screen use.
    final Set<String> quarantined = <String>{
      QuarantineScope.municipalityOf('0500504042'),
    };
    expect(isAreaQuarantined(quarantined, '0500504001'), isTrue);
    expect(isAreaQuarantined(quarantined, '0102801001'), isFalse);

    store.liftQuarantine('q-guinobatan');
    expect(store.activeQuarantineFor('0500504001'), isNull);
  });
}
