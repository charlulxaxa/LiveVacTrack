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

  Future<void> activateQuarantine({
    required String quarantineId,
    required AppUser officer,
  });

  Future<void> liftQuarantine({
    required String quarantineId,
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

    final Quarantine? existing = _store.activeQuarantineFor(areaId);
    if (existing != null) {
      throw AppException(
        'This municipality is already under quarantine '
        '(${existing.areaName}).',
      );
    }

    final DateTime now = DateTime.now();
    final int revoked = _store.revokePermitsForArea(areaId, quarantineAt: now);
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

  @override
  Future<void> activateQuarantine({
    required String quarantineId,
    required AppUser officer,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _store.activateQuarantine(quarantineId);
  }

  @override
  Future<void> liftQuarantine({
    required String quarantineId,
    required AppUser officer,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _store.liftQuarantine(quarantineId);
  }
}
