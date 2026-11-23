import 'dart:convert';

/// The QR payload printed on a permit. The signed code is produced by Cloud
/// Functions; the app only carries it to the checkpoint.
class PermitQrPayload {
  const PermitQrPayload({required this.permitId, required this.signedCode});

  final String permitId;
  final String signedCode;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'v': 1,
        'type': 'permit',
        'permitId': permitId,
        'signedCode': signedCode,
      };

  String encode() => jsonEncode(toMap());

  static PermitQrPayload? tryParse(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return null;

    // 1. JSON payload produced by this app.
    try {
      final dynamic decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        final String? id = decoded['permitId']?.toString();
        final String? code = decoded['signedCode']?.toString();
        if (id != null && code != null && id.isNotEmpty && code.isNotEmpty) {
          return PermitQrPayload(permitId: id, signedCode: code);
        }
      }
    } on FormatException {
      // Fall through to the other supported formats.
    }

    // 2. Compact pipe format: LVT|permitId|signedCode
    if (value.startsWith('LVT|')) {
      final List<String> parts = value.split('|');
      if (parts.length >= 3 && parts[1].isNotEmpty && parts[2].isNotEmpty) {
        return PermitQrPayload(permitId: parts[1], signedCode: parts[2]);
      }
    }

    // 3. Deep link: livevactrack://permit?permitId=...&signedCode=...
    final Uri? uri = Uri.tryParse(value);
    if (uri != null) {
      final String? id = uri.queryParameters['permitId'];
      final String? code = uri.queryParameters['signedCode'];
      if (id != null && code != null && id.isNotEmpty && code.isNotEmpty) {
        return PermitQrPayload(permitId: id, signedCode: code);
      }
    }

    return null;
  }
}
