import '../../core/utils/date_utils.dart';

class Farmer {
  const Farmer({
    required this.id,
    required this.fullName,
    required this.barangay,
    required this.areaId,
    this.contactNo,
    this.registeredBy,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String barangay;
  final String areaId;
  final String? contactNo;
  final String? registeredBy;
  final DateTime? createdAt;

  String get initials {
    final List<String> parts =
        fullName.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  Farmer copyWith({
    String? fullName,
    String? barangay,
    String? areaId,
    String? contactNo,
  }) {
    return Farmer(
      id: id,
      fullName: fullName ?? this.fullName,
      barangay: barangay ?? this.barangay,
      areaId: areaId ?? this.areaId,
      contactNo: contactNo ?? this.contactNo,
      registeredBy: registeredBy,
      createdAt: createdAt,
    );
  }

  factory Farmer.fromMap(String id, Map<String, dynamic> map) {
    return Farmer(
      id: id,
      fullName: (map['fullName'] as String?) ?? 'Unnamed farmer',
      barangay: (map['barangay'] as String?) ?? '',
      areaId: (map['areaId'] as String?) ?? '',
      contactNo: map['contactNo'] as String?,
      registeredBy: map['registeredBy'] as String?,
      createdAt: dateFromValue(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'fullName': fullName,
        'barangay': barangay,
        'areaId': areaId,
        if (contactNo != null && contactNo!.isNotEmpty) 'contactNo': contactNo,
        'registeredBy': registeredBy,
        'createdAt': createdAt ?? DateTime.now(),
      };
}
