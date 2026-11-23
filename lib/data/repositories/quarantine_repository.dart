import '../../core/errors/app_exception.dart';
import '../demo/demo_store.dart';
import '../enums/quarantine_status.dart';
import '../models/app_user.dart';
import '../models/quarantine.dart';

abstract class QuarantineRepository {
  Stream<List<Quarantine>> watchQuarantines();

  Future<int> declareQuarantine({
    required String areaId,
    required String areaName,
    required String reason,
    required AppUser officer,
  });
}

class DemoQuarantineRepository implements QuarantineRepository {
  DemoQuarantineRepository(this._store);

  final DemoStore _store;

  @override
  Stream<List<Quarantine>> watchQuarantines() => _store.watchQuarantines();

  @override
  Future<int> declareQuarantine({
    required String areaId,
    required String areaName,
    required String reason,
    required AppUser officer,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_store.activeQuarantineFor(areaId) != null) {
      throw AppException('$areaName already has an active quarantine.');
    }

    final DateTime now = DateTime.now();
    final int revoked = _store.revokePermitsForArea(areaId);
    _store.addQuarantine(
      Quarantine(
        id: 'QTN-${now.millisecondsSinceEpoch}',
        areaId: areaId,
        areaName: areaName,
        reason: reason.trim(),
        status: QuarantineStatus.active,
        startedAt: now,
        declaredBy: officer.id,
        sourceMessageId: 'das-${now.millisecondsSinceEpoch}',
      ),
    );
    return revoked;
  }
}
