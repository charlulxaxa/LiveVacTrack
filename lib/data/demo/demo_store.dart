import 'dart:async';

import '../../core/config/app_config.dart';
import '../enums/permit_status.dart';
import '../enums/vax_status.dart';
import '../models/animal.dart';
import '../models/farmer.dart';
import '../models/permit.dart';
import '../models/quarantine.dart';
import '../models/vaccination.dart';
import '../models/verification.dart';
import 'demo_seed.dart';

/// In-memory stand-in for Firestore used by demo mode. Streams behave like
/// Firestore snapshots: every listener receives the current value and then all
/// subsequent changes.
class DemoStore {
  DemoStore._() {
    DemoSeed.seed(this);
  }

  static final DemoStore instance = DemoStore._();

  final StreamController<void> _changes = StreamController<void>.broadcast();

  final List<Farmer> _farmers = <Farmer>[];
  final List<Animal> _animals = <Animal>[];
  final List<Vaccination> _vaccinations = <Vaccination>[];
  final List<Permit> _permits = <Permit>[];
  final List<Quarantine> _quarantines = <Quarantine>[];
  final List<Verification> _verifications = <Verification>[];

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final void _ in _changes.stream) {
      yield read();
    }
  }

  void _notify() => _changes.add(null);

  // ---------------------------------------------------------------- farmers

  Stream<List<Farmer>> watchFarmers({int limit = 20}) => _watch<List<Farmer>>(
        () {
          final List<Farmer> rows = _farmers.toList()
            ..sort((Farmer a, Farmer b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
          return List<Farmer>.unmodifiable(rows.take(limit));
        },
      );

  List<Farmer> get farmers => List<Farmer>.unmodifiable(_farmers);

  Farmer? farmerById(String id) {
    for (final Farmer farmer in _farmers) {
      if (farmer.id == id) return farmer;
    }
    return null;
  }

  void addFarmer(Farmer farmer) {
    _farmers.insert(0, farmer);
    _notify();
  }

  // ----------------------------------------------------------------- animals

  Stream<List<Animal>> watchAnimals({int limit = 20}) => _watch<List<Animal>>(
        () => List<Animal>.unmodifiable(_animals.take(limit)),
      );

  Stream<Animal?> watchAnimal(String id) =>
      _watch<Animal?>(() => animalById(id));

  List<Animal> get animals => List<Animal>.unmodifiable(_animals);

  Animal? animalById(String id) {
    for (final Animal animal in _animals) {
      if (animal.id == id) return animal;
    }
    return null;
  }

  void addAnimal(Animal animal) {
    _animals.add(animal);
    _animals.sort((Animal a, Animal b) => a.tagNo.compareTo(b.tagNo));
    _notify();
  }

  void _replaceAnimal(Animal animal) {
    final int index = _animals.indexWhere((Animal a) => a.id == animal.id);
    if (index >= 0) {
      _animals[index] = animal;
      _notify();
    }
  }

  // ------------------------------------------------------------- vaccinations

  Stream<List<Vaccination>> watchVaccinations(String animalId) =>
      _watch<List<Vaccination>>(() {
        final List<Vaccination> rows = _vaccinations
            .where((Vaccination v) => v.animalId == animalId)
            .toList()
          ..sort((Vaccination a, Vaccination b) => b.dateGiven.compareTo(a.dateGiven));
        return List<Vaccination>.unmodifiable(rows);
      });

  void addVaccination(Vaccination vaccination) {
    _vaccinations.insert(0, vaccination);
    final Animal? animal = animalById(vaccination.animalId);
    if (animal != null) {
      final VaxStatus status = vaccination.validUntil.isAfter(DateTime.now())
          ? VaxStatus.valid
          : VaxStatus.expired;
      _replaceAnimal(animal.copyWith(
        vaccinatedUntil: vaccination.validUntil,
        vaxStatus: status,
      ));
    }
    _notify();
  }

  // ----------------------------------------------------------------- permits

  Stream<List<Permit>> watchPermits({int limit = 20}) => _watch<List<Permit>>(
        () {
          final List<Permit> rows = _permits.toList()
            ..sort((Permit a, Permit b) {
              final DateTime aDate = a.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final DateTime bDate = b.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });
          return List<Permit>.unmodifiable(rows.take(limit));
        },
      );

  Stream<Permit?> watchPermit(String id) =>
      _watch<Permit?>(() => permitById(id));

  List<Permit> get permits => List<Permit>.unmodifiable(_permits);

  Permit? permitById(String id) {
    for (final Permit permit in _permits) {
      if (permit.id == id) return permit;
    }
    return null;
  }

  void addPermit(Permit permit) {
    _permits.insert(0, permit);
    _notify();
  }

  int revokePermitsForArea(String areaId) {
    int count = 0;
    for (int i = 0; i < _permits.length; i++) {
      final Permit permit = _permits[i];
      if (permit.areaId == areaId && permit.status != PermitStatus.revoked) {
        _permits[i] = permit.copyWith(status: PermitStatus.revoked);
        count++;
      }
    }
    if (count > 0) _notify();
    return count;
  }

  // -------------------------------------------------------------- quarantines

  Stream<List<Quarantine>> watchQuarantines() => _watch<List<Quarantine>>(() {
        final List<Quarantine> rows = _quarantines.toList()
          ..sort((Quarantine a, Quarantine b) => b.startedAt.compareTo(a.startedAt));
        return List<Quarantine>.unmodifiable(rows);
      });

  Quarantine? activeQuarantineFor(String areaId) {
    for (final Quarantine quarantine in _quarantines) {
      if (quarantine.areaId == areaId && quarantine.isActive) return quarantine;
    }
    return null;
  }

  Set<String> get activeQuarantineAreas => _quarantines
      .where((Quarantine q) => q.isActive)
      .map((Quarantine q) => q.areaId)
      .toSet();

  void addQuarantine(Quarantine quarantine) {
    _quarantines.insert(0, quarantine);
    _notify();
  }

  // ------------------------------------------------------------ verifications

  Stream<List<Verification>> watchVerifications(String inspectorUid) =>
      _watch<List<Verification>>(() {
        final List<Verification> rows = _verifications
            .where((Verification v) => v.inspectorUid == inspectorUid)
            .toList()
          ..sort((Verification a, Verification b) => b.scannedAt.compareTo(a.scannedAt));
        return List<Verification>.unmodifiable(rows);
      });

  void addVerification(Verification verification) {
    _verifications.insert(0, verification);
    _notify();
  }

  /// Scans recorded against one animal, newest first.
  Stream<List<Verification>> watchVerificationsForAnimal(String animalId) =>
      _watch<List<Verification>>(() {
        final List<Verification> rows = _verifications
            .where((Verification v) => v.animalId == animalId)
            .toList()
          ..sort((Verification a, Verification b) =>
              b.scannedAt.compareTo(a.scannedAt));
        return List<Verification>.unmodifiable(
          rows.take(AppConfig.pageSize),
        );
      });
}
