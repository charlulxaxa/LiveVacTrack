import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/config/app_config.dart';

/// Demo-only mirror of the Cloud Functions signer. The production secret lives
/// in the Functions environment and never ships inside the app.
String signPermitId(
  String permitId, {
  String secret = AppConfig.demoSigningSecret,
}) {
  return Hmac(sha256, utf8.encode(secret))
      .convert(utf8.encode(permitId))
      .toString();
}

bool verifyPermitSignature(
  String permitId,
  String signedCode, {
  String secret = AppConfig.demoSigningSecret,
}) {
  final String expected = signPermitId(permitId, secret: secret);
  return expected == signedCode;
}
