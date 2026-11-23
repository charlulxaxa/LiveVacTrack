import 'package:flutter_test/flutter_test.dart';

import 'package:livevactrack/core/errors/app_exception.dart';
import 'package:livevactrack/core/utils/date_utils.dart';
import 'package:livevactrack/data/demo/demo_signing.dart';
import 'package:livevactrack/data/demo/demo_store.dart';
import 'package:livevactrack/data/enums/scan_result.dart';
import 'package:livevactrack/data/enums/user_role.dart';
import 'package:livevactrack/data/models/animal.dart';
import 'package:livevactrack/data/models/app_user.dart';
import 'package:livevactrack/data/models/verification.dart';
import 'package:livevactrack/data/repositories/permit_repository.dart';

const AppUser inspector = AppUser(
  id: 'u-inspector',
  displayName: 'Insp. Noel Garcia',
  role: UserRole.inspector,
  areaId: 'san-jose',
);

const AppUser clerk = AppUser(
  id: 'u-clerk',
  displayName: 'Carla Dizon',
  role: UserRole.clerk,
  areaId: 'poblacion',
);

void main() {
  late DemoPermitRepository repository;

  setUp(() {
    repository = DemoPermitRepository(DemoStore.instance);
  });

  group('signing', () {
    test('signed code is stable and verifiable', () {
      final String code = signPermitId('PMT-1001');
      expect(code, hasLength(64));
      expect(verifyPermitSignature('PMT-1001', code), isTrue);
      expect(verifyPermitSignature('PMT-1001', 'tampered'), isFalse);
      expect(verifyPermitSignature('PMT-1002', code), isFalse);
    });
  });

  group('verifyPermit', () {
    test('returns VALID for a genuine, in-date permit', () async {
      final VerificationOutcome outcome = await repository.verifyPermit(
        permitId: 'PMT-1001',
        signedCode: signPermitId('PMT-1001'),
        checkpointName: 'San Jose Checkpoint',
        inspector: inspector,
        offline: false,
      );

      expect(outcome.result, ScanResult.valid);
      expect(outcome.signatureValid, isTrue);
      expect(outcome.isAuthoritative, isTrue);
      expect(outcome.permit?.id, 'PMT-1001');
    });

    test('returns INVALID when the signed code is altered', () async {
      final VerificationOutcome outcome = await repository.verifyPermit(
        permitId: 'PMT-1001',
        signedCode: 'f' * 64,
        checkpointName: 'San Jose Checkpoint',
        inspector: inspector,
        offline: false,
      );

      expect(outcome.result, ScanResult.invalid);
      expect(outcome.signatureValid, isFalse);
    });

    test('returns REVOKED for a revoked permit', () async {
      final VerificationOutcome outcome = await repository.verifyPermit(
        permitId: 'PMT-1002',
        signedCode: signPermitId('PMT-1002'),
        checkpointName: 'San Jose Checkpoint',
        inspector: inspector,
        offline: false,
      );

      expect(outcome.result, ScanResult.revoked);
      expect(outcome.signatureValid, isTrue);
    });

    test('returns EXPIRED for a permit past its valid-until date', () async {
      final VerificationOutcome outcome = await repository.verifyPermit(
        permitId: 'PMT-1003',
        signedCode: signPermitId('PMT-1003'),
        checkpointName: 'San Jose Checkpoint',
        inspector: inspector,
        offline: false,
      );

      expect(outcome.result, ScanResult.expired);
    });

    test('never returns VALID while offline', () async {
      final VerificationOutcome outcome = await repository.verifyPermit(
        permitId: 'PMT-1001',
        signedCode: signPermitId('PMT-1001'),
        checkpointName: 'San Jose Checkpoint',
        inspector: inspector,
        offline: true,
      );

      expect(outcome.result, ScanResult.unverified);
      expect(outcome.isAuthoritative, isFalse);
      expect(outcome.offline, isTrue);
      expect(outcome.signatureValid, isFalse);
    });

    test('returns INVALID for an unknown permit', () async {
      final VerificationOutcome outcome = await repository.verifyPermit(
        permitId: 'PMT-9999',
        signedCode: signPermitId('PMT-9999'),
        checkpointName: 'San Jose Checkpoint',
        inspector: inspector,
        offline: false,
      );

      expect(outcome.result, ScanResult.invalid);
    });

    test('scans are listed per animal, newest first', () async {
      await repository.verifyPermit(
        permitId: 'PMT-1001',
        signedCode: signPermitId('PMT-1001'),
        checkpointName: 'North Gate',
        inspector: inspector,
        offline: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.verifyPermit(
        permitId: 'PMT-1001',
        signedCode: signPermitId('PMT-1001'),
        checkpointName: 'South Gate',
        inspector: inspector,
        offline: false,
      );

      final List<Verification> history =
          await repository.watchVerificationsForAnimal('a1').first;
      expect(history, isNotEmpty);
      expect(history.first.checkpointName, 'South Gate');
      expect(history.first.animalId, 'a1');
      expect(history.every((Verification v) => v.animalId == 'a1'), isTrue);

      final List<Verification> unrelated =
          await repository.watchVerificationsForAnimal('a3').first;
      expect(unrelated, isEmpty);
    });
  });

  group('issuePermit', () {
    test('signs a permit for an eligible animal', () async {
      final Animal animal = DemoStore.instance.animalById('a1')!;
      final DateTime travelDate = DateTime.now().add(const Duration(days: 1));
      final permit = await repository.issuePermit(
        animal: animal,
        origin: 'Poblacion',
        destination: 'Legazpi City',
        travelDate: travelDate,
        clerk: clerk,
      );

      expect(permit.id, startsWith('PMT-'));
      expect(permit.signedCode, signPermitId(permit.id));
      expect(permit.effectiveStatus(), permit.status);
      expect(permit.validUntil, endOfDay(travelDate));
    });

    test('blocks an animal in a quarantined area', () async {
      final Animal animal = DemoStore.instance.animalById('a2')!;
      expect(
        () => repository.issuePermit(
          animal: animal,
          origin: 'San Jose',
          destination: 'Legazpi City',
          travelDate: DateTime.now().add(const Duration(days: 1)),
          clerk: clerk,
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('blocks an animal without a current vaccination', () async {
      final Animal animal = DemoStore.instance.animalById('a4')!;
      expect(
        () => repository.issuePermit(
          animal: animal,
          origin: 'Poblacion',
          destination: 'Legazpi City',
          travelDate: DateTime.now().add(const Duration(days: 1)),
          clerk: clerk,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
