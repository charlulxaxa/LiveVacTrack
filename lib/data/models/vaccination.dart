import '../../core/utils/date_utils.dart';

class Vaccination {
  const Vaccination({
    required this.id,
    required this.animalId,
    required this.vaccineName,
    required this.batchNo,
    required this.dateGiven,
    required this.validUntil,
    required this.vetUid,
    required this.vetName,
    this.createdAt,
  });

  final String id;
  final String animalId;
  final String vaccineName;
  final String batchNo;
  final DateTime dateGiven;
  final DateTime validUntil;
  final String vetUid;
  final String vetName;
  final DateTime? createdAt;

  factory Vaccination.fromMap(String id, Map<String, dynamic> map) {
    return Vaccination(
      id: id,
      animalId: (map['animalId'] as String?) ?? '',
      vaccineName: (map['vaccineName'] as String?) ?? '',
      batchNo: (map['batchNo'] as String?) ?? '',
      dateGiven: dateFromValue(map['dateGiven']) ?? DateTime.now(),
      validUntil: dateFromValue(map['validUntil']) ?? DateTime.now(),
      vetUid: (map['vetUid'] as String?) ?? '',
      vetName: (map['vetName'] as String?) ?? '',
      createdAt: dateFromValue(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'animalId': animalId,
        'vaccineName': vaccineName,
        'batchNo': batchNo,
        'dateGiven': dateGiven,
        'validUntil': validUntil,
        'vetUid': vetUid,
        'vetName': vetName,
        'createdAt': createdAt ?? DateTime.now(),
      };
}
