import '../../core/utils/date_utils.dart';
import '../enums/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.role,
    this.areaId,
    this.areaName,
    this.createdAt,
    this.isDemo = false,
  });

  final String id;
  final String displayName;
  final UserRole role;
  final String? areaId;

  /// Human-readable area stored when the account was provisioned, because
  /// area ids are PSGC barangay codes in live mode.
  final String? areaName;
  final DateTime? createdAt;

  /// Built-in demo account. Demo accounts only see and write the demo data
  /// set (`demo_*` collections) and show "Demo mode" on their profile.
  final bool isDemo;

  String get initials {
    final List<String> parts =
        displayName.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      displayName: (map['displayName'] as String?)?.trim().isNotEmpty == true
          ? map['displayName'] as String
          : 'Unnamed user',
      role: UserRole.fromWire(map['role'] as String?),
      areaId: map['areaId'] as String?,
      areaName: map['areaName'] as String?,
      createdAt: dateFromValue(map['createdAt']),
      isDemo: map['isDemo'] == true,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'displayName': displayName,
        'role': role.wire,
        if (areaId != null) 'areaId': areaId,
        if (areaName != null) 'areaName': areaName,
        'createdAt': createdAt ?? DateTime.now(),
        'isDemo': isDemo,
      };
}
