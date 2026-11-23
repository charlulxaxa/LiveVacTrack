import '../../core/utils/date_utils.dart';
import '../enums/vax_status.dart';

class Animal {
  const Animal({
    required this.id,
    required this.tagNo,
    required this.species,
    required this.breed,
    required this.farmerId,
    required this.farmerName,
    required this.barangay,
    required this.areaId,
    required this.vaxStatus,
    this.vaccinatedUntil,
    this.registeredBy,
    this.registeredAt,
  });

  final String id;
  final String tagNo;
  final String species;
  final String breed;
  final String farmerId;
  final String farmerName;
  final String barangay;
  final String areaId;
  final VaxStatus vaxStatus;
  final DateTime? vaccinatedUntil;
  final String? registeredBy;
  final DateTime? registeredAt;

  bool get hasCurrentVaccination =>
      vaxStatus == VaxStatus.valid &&
      vaccinatedUntil != null &&
      vaccinatedUntil!.isAfter(DateTime.now());

  bool isVaccinatedFor(DateTime travelDate) =>
      vaxStatus == VaxStatus.valid &&
      vaccinatedUntil != null &&
      !vaccinatedUntil!.isBefore(dateOnly(travelDate));

  Animal copyWith({
    VaxStatus? vaxStatus,
    DateTime? vaccinatedUntil,
    String? farmerName,
    String? barangay,
    String? areaId,
  }) {
    return Animal(
      id: id,
      tagNo: tagNo,
      species: species,
      breed: breed,
      farmerId: farmerId,
      farmerName: farmerName ?? this.farmerName,
      barangay: barangay ?? this.barangay,
      areaId: areaId ?? this.areaId,
      vaxStatus: vaxStatus ?? this.vaxStatus,
      vaccinatedUntil: vaccinatedUntil ?? this.vaccinatedUntil,
      registeredBy: registeredBy,
      registeredAt: registeredAt,
    );
  }

  factory Animal.fromMap(String id, Map<String, dynamic> map) {
    return Animal(
      id: id,
      tagNo: (map['tagNo'] as String?) ?? '',
      species: (map['species'] as String?) ?? '',
      breed: (map['breed'] as String?) ?? '',
      farmerId: (map['farmerId'] as String?) ?? '',
      farmerName: (map['farmerName'] as String?) ?? '',
      barangay: (map['barangay'] as String?) ?? '',
      areaId: (map['areaId'] as String?) ?? '',
      vaxStatus: VaxStatus.fromWire(map['vaxStatus'] as String?),
      vaccinatedUntil: dateFromValue(map['vaccinatedUntil']),
      registeredBy: map['registeredBy'] as String?,
      registeredAt: dateFromValue(map['registeredAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'tagNo': tagNo,
        'species': species,
        'breed': breed,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'barangay': barangay,
        'areaId': areaId,
        'vaxStatus': vaxStatus.wire,
        'vaccinatedUntil': vaccinatedUntil,
        'registeredBy': registeredBy,
        'registeredAt': registeredAt ?? DateTime.now(),
      };
}
