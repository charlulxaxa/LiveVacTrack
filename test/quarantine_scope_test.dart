import 'package:flutter_test/flutter_test.dart';
import 'package:livevactrack/core/utils/quarantine_scope.dart';
import 'package:livevactrack/data/enums/permit_status.dart';
import 'package:livevactrack/data/models/permit.dart';

Permit _permit({
  required String areaId,
  required DateTime issuedAt,
  PermitStatus status = PermitStatus.issued,
  String? originAreaId,
}) {
  return Permit(
    id: 'PMT-TEST',
    animalId: 'a1',
    farmerId: 'f1',
    origin: 'Origin',
    destination: 'Destination',
    travelDate: issuedAt,
    requestedBy: 'clerk',
    areaId: areaId,
    status: status,
    signedCode: 'code',
    validUntil: issuedAt.add(const Duration(days: 30)),
    issuedAt: issuedAt,
    createdAt: issuedAt,
    originAreaId: originAreaId,
  );
}

void main() {
  // Guinobatan, Albay: two barangays in the same municipality.
  const String quibongbongan = '0500504042';
  const String otherGuinobatanBarangay = '0500504001';
  // A barangay in a different municipality (Adams, Ilocos Norte).
  const String adams = '0102801001';

  final DateTime declaredAt = DateTime(2026, 11, 25, 14, 30);

  test('a barangay maps to its municipality/city', () {
    expect(QuarantineScope.municipalityOf(quibongbongan), '0500504000');
    expect(
      QuarantineScope.sameMunicipality(quibongbongan, otherGuinobatanBarangay),
      isTrue,
    );
    expect(QuarantineScope.sameMunicipality(quibongbongan, adams), isFalse);
    // Offline demo areas each count as their own area.
    expect(QuarantineScope.sameMunicipality('poblacion', 'san-jose'), isFalse);
  });

  test('cutoff is the start of the day 5 days before the quarantine', () {
    expect(QuarantineScope.revokeCutoff(declaredAt), DateTime(2026, 11, 20));
  });

  test('revokes permits issued in the last 5 days anywhere in the municipality',
      () {
    expect(
      QuarantineScope.revokes(
        _permit(
          areaId: otherGuinobatanBarangay,
          issuedAt: DateTime(2026, 11, 20, 8),
        ),
        quarantineAreaId: quibongbongan,
        quarantineAt: declaredAt,
      ),
      isTrue,
    );
    expect(
      QuarantineScope.revokes(
        _permit(areaId: quibongbongan, issuedAt: DateTime(2026, 11, 25, 9)),
        quarantineAreaId: quibongbongan,
        quarantineAt: declaredAt,
      ),
      isTrue,
    );
  });

  test('revokes a permit moving out of the quarantined municipality, even if '
      'the animal is registered elsewhere', () {
    // The real case: animal registered in Bantay, Ilocos Sur, moving from
    // Binogsacan Lower, Guinobatan, which is under quarantine.
    expect(
      QuarantineScope.revokes(
        _permit(
          areaId: '0102903003',
          originAreaId: '0500504005',
          issuedAt: DateTime(2026, 11, 25, 10),
        ),
        quarantineAreaId: '0500504005',
        quarantineAt: declaredAt,
      ),
      isTrue,
    );
  });

  test('keeps permits issued more than 5 days before the quarantine', () {
    expect(
      QuarantineScope.revokes(
        _permit(areaId: quibongbongan, issuedAt: DateTime(2026, 11, 19, 23)),
        quarantineAreaId: quibongbongan,
        quarantineAt: declaredAt,
      ),
      isFalse,
    );
  });

  test('keeps permits from other municipalities and already revoked ones', () {
    expect(
      QuarantineScope.revokes(
        _permit(areaId: adams, issuedAt: DateTime(2026, 11, 24)),
        quarantineAreaId: quibongbongan,
        quarantineAt: declaredAt,
      ),
      isFalse,
    );
    expect(
      QuarantineScope.revokes(
        _permit(
          areaId: quibongbongan,
          issuedAt: DateTime(2026, 11, 24),
          status: PermitStatus.revoked,
        ),
        quarantineAreaId: quibongbongan,
        quarantineAt: declaredAt,
      ),
      isFalse,
    );
  });
}
