import '../../data/enums/permit_status.dart';
import '../../data/models/permit.dart';
import '../services/psgc_location_service.dart';
import 'date_utils.dart';

/// Who a quarantine affects.
///
/// A quarantine is declared on a barangay but covers its whole municipality
/// or city:
/// - new permits are blocked for animals registered in, or moving from,
///   that municipality, and
/// - permits for animals registered in, or moving from, that municipality
///   and issued within the last
///   [revokeWindowDays] days (counting the quarantine day) are revoked.
///   Older permits still in effect are left valid.
class QuarantineScope {
  const QuarantineScope._();

  static const int revokeWindowDays = 5;

  /// Municipality/city key for a barangay id. Official ids are PSGC barangay
  /// codes, so this is the city's PSGC code (e.g. 0500504042 -> 0500504000).
  /// The offline demo areas (`AppConfig.areas`) have no municipality, so each
  /// counts as its own area; otherwise the seeded demo quarantine would block
  /// every demo animal.
  static String municipalityOf(String areaId) =>
      PsgcLocationService.cityCodeForBarangay(areaId) ?? areaId;

  static bool sameMunicipality(String areaA, String areaB) =>
      municipalityOf(areaA) == municipalityOf(areaB);

  /// Permits issued on or after this moment are revoked: the start of the day
  /// [revokeWindowDays] days before the quarantine. A quarantine on the 25th
  /// revokes permits issued from the 20th onwards.
  static DateTime revokeCutoff(DateTime quarantineAt) =>
      dateOnly(quarantineAt).subtract(const Duration(days: revokeWindowDays));

  /// Whether a quarantine on [quarantineAreaId] starting at [quarantineAt]
  /// revokes [permit].
  static bool revokes(
    Permit permit, {
    required String quarantineAreaId,
    required DateTime quarantineAt,
  }) {
    if (permit.status != PermitStatus.issued) return false;
    // Covered if the animal's home barangay or the origin is in the
    // quarantined municipality.
    final bool inArea = permit.quarantineAreaIds
        .any((String area) => sameMunicipality(area, quarantineAreaId));
    if (!inArea) return false;
    final DateTime issued = permit.issuedAt ?? permit.createdAt ?? quarantineAt;
    return !issued.isBefore(revokeCutoff(quarantineAt));
  }
}
