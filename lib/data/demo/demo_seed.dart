import '../enums/permit_status.dart';
import '../enums/quarantine_status.dart';
import '../enums/scan_result.dart';
import '../enums/vax_status.dart';
import '../models/animal.dart';
import '../models/farmer.dart';
import '../models/permit.dart';
import '../models/quarantine.dart';
import '../models/vaccination.dart';
import '../models/verification.dart';
import 'demo_signing.dart';
import 'demo_store.dart';

/// Synthetic data used by demo mode. No real farmer information is stored.
class DemoSeed {
  const DemoSeed._();

  static void seed(DemoStore store) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // ------------------------------------------------------------- farmers
    final List<Farmer> farmers = <Farmer>[
      Farmer(
        id: 'f1',
        fullName: 'Maria Santos',
        barangay: 'Poblacion',
        areaId: 'poblacion',
        contactNo: '0917 000 0001',
        registeredBy: 'u-registry',
        createdAt: today.subtract(const Duration(days: 120)),
      ),
      Farmer(
        id: 'f2',
        fullName: 'Jose Dela Cruz',
        barangay: 'San Jose',
        areaId: 'san-jose',
        contactNo: '0917 000 0002',
        registeredBy: 'u-registry',
        createdAt: today.subtract(const Duration(days: 110)),
      ),
      Farmer(
        id: 'f3',
        fullName: 'Ana Reyes',
        barangay: 'Sta. Cruz',
        areaId: 'sta-cruz',
        contactNo: '0917 000 0003',
        registeredBy: 'u-registry',
        createdAt: today.subtract(const Duration(days: 95)),
      ),
      Farmer(
        id: 'f4',
        fullName: 'Pedro Bautista',
        barangay: 'Poblacion',
        areaId: 'poblacion',
        contactNo: '0917 000 0004',
        registeredBy: 'u-registry',
        createdAt: today.subtract(const Duration(days: 80)),
      ),
      Farmer(
        id: 'f5',
        fullName: 'Liza Mendoza',
        barangay: 'San Jose',
        areaId: 'san-jose',
        contactNo: '0917 000 0005',
        registeredBy: 'u-registry',
        createdAt: today.subtract(const Duration(days: 60)),
      ),
    ];
    for (final Farmer farmer in farmers) {
      store.addFarmer(farmer);
    }

    // ------------------------------------------------------------- animals
    final List<Animal> animals = <Animal>[
      Animal(
        id: 'a1',
        tagNo: 'LV-001',
        species: 'Cattle',
        breed: 'Brahman',
        farmerId: 'f1',
        farmerName: 'Maria Santos',
        barangay: 'Poblacion',
        areaId: 'poblacion',
        vaxStatus: VaxStatus.valid,
        vaccinatedUntil: today.add(const Duration(days: 180)),
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 120)),
      ),
      Animal(
        id: 'a2',
        tagNo: 'LV-002',
        species: 'Cattle',
        breed: 'Holstein',
        farmerId: 'f2',
        farmerName: 'Jose Dela Cruz',
        barangay: 'San Jose',
        areaId: 'san-jose',
        vaxStatus: VaxStatus.valid,
        vaccinatedUntil: today.add(const Duration(days: 45)),
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 110)),
      ),
      Animal(
        id: 'a3',
        tagNo: 'LV-003',
        species: 'Goat',
        breed: 'Boer',
        farmerId: 'f3',
        farmerName: 'Ana Reyes',
        barangay: 'Sta. Cruz',
        areaId: 'sta-cruz',
        vaxStatus: VaxStatus.expired,
        vaccinatedUntil: today.subtract(const Duration(days: 12)),
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 95)),
      ),
      Animal(
        id: 'a4',
        tagNo: 'LV-004',
        species: 'Carabao',
        breed: 'Murrah',
        farmerId: 'f1',
        farmerName: 'Maria Santos',
        barangay: 'Poblacion',
        areaId: 'poblacion',
        vaxStatus: VaxStatus.none,
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 90)),
      ),
      Animal(
        id: 'a5',
        tagNo: 'LV-005',
        species: 'Swine',
        breed: 'Landrace',
        farmerId: 'f4',
        farmerName: 'Pedro Bautista',
        barangay: 'Poblacion',
        areaId: 'poblacion',
        vaxStatus: VaxStatus.valid,
        vaccinatedUntil: today.add(const Duration(days: 90)),
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 80)),
      ),
      Animal(
        id: 'a6',
        tagNo: 'LV-006',
        species: 'Goat',
        breed: 'Nubian',
        farmerId: 'f5',
        farmerName: 'Liza Mendoza',
        barangay: 'San Jose',
        areaId: 'san-jose',
        vaxStatus: VaxStatus.valid,
        vaccinatedUntil: today.add(const Duration(days: 8)),
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 60)),
      ),
      Animal(
        id: 'a7',
        tagNo: 'LV-007',
        species: 'Cattle',
        breed: 'Brahman',
        farmerId: 'f2',
        farmerName: 'Jose Dela Cruz',
        barangay: 'San Jose',
        areaId: 'san-jose',
        vaxStatus: VaxStatus.expired,
        vaccinatedUntil: today.subtract(const Duration(days: 60)),
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 150)),
      ),
      Animal(
        id: 'a8',
        tagNo: 'LV-008',
        species: 'Swine',
        breed: 'Duroc',
        farmerId: 'f3',
        farmerName: 'Ana Reyes',
        barangay: 'Sta. Cruz',
        areaId: 'sta-cruz',
        vaxStatus: VaxStatus.valid,
        vaccinatedUntil: today.add(const Duration(days: 120)),
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 70)),
      ),
      Animal(
        id: 'a9',
        tagNo: 'LV-009',
        species: 'Carabao',
        breed: 'Philippine Carabao',
        farmerId: 'f5',
        farmerName: 'Liza Mendoza',
        barangay: 'San Jose',
        areaId: 'san-jose',
        vaxStatus: VaxStatus.none,
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 45)),
      ),
      Animal(
        id: 'a10',
        tagNo: 'LV-010',
        species: 'Goat',
        breed: 'Anglo-Nubian',
        farmerId: 'f4',
        farmerName: 'Pedro Bautista',
        barangay: 'Poblacion',
        areaId: 'poblacion',
        vaxStatus: VaxStatus.valid,
        vaccinatedUntil: today.add(const Duration(days: 200)),
        registeredBy: 'u-registry',
        registeredAt: today.subtract(const Duration(days: 30)),
      ),
    ];
    for (final Animal animal in animals) {
      store.addAnimal(animal);
    }

    // -------------------------------------------------------- vaccinations
    final List<Vaccination> vaccinations = <Vaccination>[
      Vaccination(
        id: 'v1',
        animalId: 'a1',
        vaccineName: 'FMD Vaccine',
        batchNo: 'FMD-2026-01',
        dateGiven: today.subtract(const Duration(days: 10)),
        validUntil: today.add(const Duration(days: 180)),
        vetUid: 'u-vet',
        vetName: 'Dr. Vic Santos',
      ),
      Vaccination(
        id: 'v2',
        animalId: 'a2',
        vaccineName: 'FMD Vaccine',
        batchNo: 'FMD-2026-02',
        dateGiven: today.subtract(const Duration(days: 30)),
        validUntil: today.add(const Duration(days: 45)),
        vetUid: 'u-vet',
        vetName: 'Dr. Vic Santos',
      ),
      Vaccination(
        id: 'v3',
        animalId: 'a5',
        vaccineName: 'Hog Cholera Vaccine',
        batchNo: 'HC-2026-11',
        dateGiven: today.subtract(const Duration(days: 5)),
        validUntil: today.add(const Duration(days: 90)),
        vetUid: 'u-vet',
        vetName: 'Dr. Vic Santos',
      ),
      Vaccination(
        id: 'v4',
        animalId: 'a6',
        vaccineName: 'PPR Vaccine',
        batchNo: 'PPR-2026-07',
        dateGiven: today.subtract(const Duration(days: 20)),
        validUntil: today.add(const Duration(days: 8)),
        vetUid: 'u-vet',
        vetName: 'Dr. Vic Santos',
      ),
      Vaccination(
        id: 'v5',
        animalId: 'a8',
        vaccineName: 'FMD Vaccine',
        batchNo: 'FMD-2026-03',
        dateGiven: today.subtract(const Duration(days: 15)),
        validUntil: today.add(const Duration(days: 120)),
        vetUid: 'u-vet',
        vetName: 'Dr. Vic Santos',
      ),
      Vaccination(
        id: 'v6',
        animalId: 'a10',
        vaccineName: 'PPR Vaccine',
        batchNo: 'PPR-2026-08',
        dateGiven: today.subtract(const Duration(days: 7)),
        validUntil: today.add(const Duration(days: 200)),
        vetUid: 'u-vet',
        vetName: 'Dr. Vic Santos',
      ),
    ];
    for (final Vaccination vaccination in vaccinations) {
      store.addVaccination(vaccination);
    }

    // -------------------------------------------------------------- permits
    final List<Permit> permits = <Permit>[
      Permit(
        id: 'PMT-1001',
        animalId: 'a1',
        farmerId: 'f1',
        origin: 'Poblacion',
        destination: 'Legazpi City',
        travelDate: today.add(const Duration(days: 2)),
        requestedBy: 'u-clerk',
        areaId: 'poblacion',
        status: PermitStatus.issued,
        signedCode: signPermitId('PMT-1001'),
        validUntil: today.add(const Duration(days: 180)),
        issuedAt: today.subtract(const Duration(hours: 5)),
        createdAt: today.subtract(const Duration(hours: 5)),
      ),
      Permit(
        id: 'PMT-1002',
        animalId: 'a2',
        farmerId: 'f2',
        origin: 'San Jose',
        destination: 'Legazpi City',
        travelDate: today.add(const Duration(days: 1)),
        requestedBy: 'u-clerk',
        areaId: 'san-jose',
        status: PermitStatus.revoked,
        signedCode: signPermitId('PMT-1002'),
        validUntil: today.add(const Duration(days: 45)),
        issuedAt: today.subtract(const Duration(days: 3)),
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      Permit(
        id: 'PMT-1003',
        animalId: 'a5',
        farmerId: 'f4',
        origin: 'Poblacion',
        destination: 'Daraga',
        travelDate: today.subtract(const Duration(days: 3)),
        requestedBy: 'u-clerk',
        areaId: 'poblacion',
        status: PermitStatus.issued,
        signedCode: signPermitId('PMT-1003'),
        validUntil: today.subtract(const Duration(days: 5)),
        issuedAt: today.subtract(const Duration(days: 6)),
        createdAt: today.subtract(const Duration(days: 6)),
      ),
      Permit(
        id: 'PMT-1004',
        animalId: 'a6',
        farmerId: 'f5',
        origin: 'San Jose',
        destination: 'Legazpi City',
        travelDate: today.add(const Duration(days: 1)),
        requestedBy: 'u-clerk',
        areaId: 'san-jose',
        status: PermitStatus.revoked,
        signedCode: signPermitId('PMT-1004'),
        validUntil: today.add(const Duration(days: 8)),
        issuedAt: today.subtract(const Duration(days: 1)),
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      Permit(
        id: 'PMT-1005',
        animalId: 'a8',
        farmerId: 'f3',
        origin: 'Sta. Cruz',
        destination: 'Legazpi City',
        travelDate: today.add(const Duration(days: 5)),
        requestedBy: 'u-clerk',
        areaId: 'sta-cruz',
        status: PermitStatus.issued,
        signedCode: signPermitId('PMT-1005'),
        validUntil: today.add(const Duration(days: 120)),
        issuedAt: today.subtract(const Duration(hours: 20)),
        createdAt: today.subtract(const Duration(hours: 20)),
      ),
      Permit(
        id: 'PMT-1006',
        animalId: 'a10',
        farmerId: 'f4',
        origin: 'Poblacion',
        destination: 'Sorsogon',
        travelDate: today.add(const Duration(days: 3)),
        requestedBy: 'u-clerk',
        areaId: 'poblacion',
        status: PermitStatus.issued,
        signedCode: signPermitId('PMT-1006'),
        validUntil: today.add(const Duration(days: 200)),
        issuedAt: today.subtract(const Duration(hours: 2)),
        createdAt: today.subtract(const Duration(hours: 2)),
      ),
    ];
    for (final Permit permit in permits) {
      store.addPermit(permit);
    }

    // ---------------------------------------------------------- quarantines
    store.addQuarantine(
      Quarantine(
        id: 'q1',
        areaId: 'san-jose',
        areaName: 'Barangay San Jose',
        reason: 'Suspected African Swine Fever detected in the barangay.',
        status: QuarantineStatus.active,
        startedAt: today.subtract(const Duration(days: 2)),
        declaredBy: 'u-disease',
        sourceMessageId: 'das-2026-001',
      ),
    );
    store.addQuarantine(
      Quarantine(
        id: 'q2',
        areaId: 'poblacion',
        areaName: 'Barangay Poblacion',
        reason: 'Routine surveillance; no positive cases found.',
        status: QuarantineStatus.lifted,
        startedAt: today.subtract(const Duration(days: 30)),
        liftedAt: today.subtract(const Duration(days: 20)),
        declaredBy: 'u-disease',
        sourceMessageId: 'das-2026-000',
      ),
    );

    // --------------------------------------------------------- verifications
    store.addVerification(
      Verification(
        id: 'ver1',
        permitId: 'PMT-1001',
        animalId: 'a1',
        result: ScanResult.valid,
        inspectorUid: 'u-inspector',
        checkpointName: 'San Jose Checkpoint',
        scannedAt: now.subtract(const Duration(days: 1)),
        wasOffline: false,
        signatureValid: true,
      ),
    );
    store.addVerification(
      Verification(
        id: 'ver2',
        permitId: 'PMT-1002',
        animalId: 'a2',
        result: ScanResult.revoked,
        inspectorUid: 'u-inspector',
        checkpointName: 'San Jose Checkpoint',
        scannedAt: now.subtract(const Duration(hours: 2)),
        wasOffline: false,
        signatureValid: true,
      ),
    );
  }
}
