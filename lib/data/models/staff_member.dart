import '../../core/utils/date_utils.dart';
import '../enums/user_role.dart';

/// A staff account as the super admin sees it on the Staff tab.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.displayName,
    required this.role,
    this.email,
    this.areaName,
    this.disabled = false,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final UserRole role;

  /// Missing on accounts provisioned before the email was stored on the
  /// profile; password reset needs it.
  final String? email;
  final String? areaName;
  final bool disabled;
  final DateTime? createdAt;

  String get initials {
    final List<String> parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  factory StaffMember.fromMap(String id, Map<String, dynamic> map) {
    final String? name = (map['displayName'] as String?)?.trim();
    return StaffMember(
      id: id,
      displayName: name == null || name.isEmpty ? 'Unnamed user' : name,
      role: UserRole.fromWire(map['role'] as String?),
      email: map['email'] as String?,
      areaName: (map['areaName'] as String?) ?? (map['areaId'] as String?),
      disabled: map['disabled'] == true,
      createdAt: dateFromValue(map['createdAt']),
    );
  }
}
