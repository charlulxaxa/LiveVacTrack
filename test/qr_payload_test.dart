import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:livevactrack/core/utils/qr_payload.dart';

void main() {
  group('PermitQrPayload', () {
    test('round-trips through JSON', () {
      const PermitQrPayload payload = PermitQrPayload(
        permitId: 'PMT-1001',
        signedCode: 'abc123',
      );
      final PermitQrPayload? parsed = PermitQrPayload.tryParse(payload.encode());
      expect(parsed, isNotNull);
      expect(parsed!.permitId, 'PMT-1001');
      expect(parsed.signedCode, 'abc123');
    });

    test('parses the compact pipe format', () {
      final PermitQrPayload? parsed =
          PermitQrPayload.tryParse('LVT|PMT-2002|deadbeef');
      expect(parsed?.permitId, 'PMT-2002');
      expect(parsed?.signedCode, 'deadbeef');
    });

    test('parses a deep link', () {
      final PermitQrPayload? parsed = PermitQrPayload.tryParse(
        'livevactrack://permit?permitId=PMT-3003&signedCode=cafe',
      );
      expect(parsed?.permitId, 'PMT-3003');
      expect(parsed?.signedCode, 'cafe');
    });

    test('rejects unrelated QR content', () {
      expect(PermitQrPayload.tryParse('https://example.com'), isNull);
      expect(PermitQrPayload.tryParse(''), isNull);
      expect(PermitQrPayload.tryParse(jsonEncode(<String, String>{})), isNull);
    });
  });
}
