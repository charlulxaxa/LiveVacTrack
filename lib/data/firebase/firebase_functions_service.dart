import 'package:cloud_functions/cloud_functions.dart';

import '../../core/errors/error_mapper.dart';

/// Thin wrapper around the callable Cloud Functions.
class FirebaseFunctionsService {
  FirebaseFunctionsService(this._functions);

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> issuePermit({
    required String animalId,
    required String origin,
    required String destination,
    required DateTime travelDate,
  }) async {
    final HttpsCallableResult<dynamic> result = await _call(
      'issuePermit',
      <String, dynamic>{
        'animalId': animalId,
        'origin': origin,
        'destination': destination,
        'travelDate': travelDate.toIso8601String(),
      },
    );
    return _asMap(result.data);
  }

  Future<Map<String, dynamic>> verifyPermit({
    required String permitId,
    required String signedCode,
    required String checkpointName,
  }) async {
    final HttpsCallableResult<dynamic> result = await _call(
      'verifyPermit',
      <String, dynamic>{
        'permitId': permitId,
        'signedCode': signedCode,
        'checkpointName': checkpointName,
      },
    );
    return _asMap(result.data);
  }

  Future<int> declareQuarantine({
    required String areaId,
    required String areaName,
    required String reason,
  }) async {
    final HttpsCallableResult<dynamic> result = await _call(
      'declareQuarantine',
      <String, dynamic>{
        'areaId': areaId,
        'areaName': areaName,
        'reason': reason,
      },
    );
    final Map<String, dynamic> data = _asMap(result.data);
    return (data['revokedCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> activateQuarantine({
    required String quarantineId,
  }) async {
    await _call(
      'activateQuarantine',
      <String, dynamic>{
        'quarantineId': quarantineId,
      },
    );
  }

  Future<void> liftQuarantine({
    required String quarantineId,
  }) async {
    await _call(
      'liftQuarantine',
      <String, dynamic>{
        'quarantineId': quarantineId,
      },
    );
  }

  Future<Map<String, dynamic>> createStaffAccount({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String areaId,
    required String areaName,
  }) async {
    final HttpsCallableResult<dynamic> result = await _call(
      'createStaffAccount',
      <String, dynamic>{
        'email': email,
        'password': password,
        'displayName': displayName,
        'role': role,
        'areaId': areaId,
        'areaName': areaName,
      },
    );
    return _asMap(result.data);
  }

  /// Calls a callable function and maps failures to readable messages, so the
  /// UI never shows a raw FirebaseFunctionsException with its stack trace.
  Future<HttpsCallableResult<dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _functions.httpsCallable(name).call(data);
    } catch (error) {
      throw ErrorMapper.functions(error);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
