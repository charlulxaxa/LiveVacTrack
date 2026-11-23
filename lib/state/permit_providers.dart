import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/permit.dart';
import '../data/models/verification.dart';
import 'repository_providers.dart';

class PermitLimit extends Notifier<int> {
  @override
  int build() => AppConfig.pageSize;

  void loadMore() => state += AppConfig.pageSize;

  void reset() => state = AppConfig.pageSize;
}

final NotifierProvider<PermitLimit, int> permitLimitProvider =
    NotifierProvider<PermitLimit, int>(PermitLimit.new);

final StreamProvider<List<Permit>> permitsProvider =
    StreamProvider<List<Permit>>((Ref ref) {
  final int limit = ref.watch(permitLimitProvider);
  return ref.watch(permitRepositoryProvider).watchPermits(limit: limit);
});

final permitProvider =
    StreamProvider.family<Permit?, String>((Ref ref, String id) {
  return ref.watch(permitRepositoryProvider).watchPermit(id);
});

final verificationsProvider =
    StreamProvider.family<List<Verification>, String>((Ref ref, String uid) {
  return ref.watch(permitRepositoryProvider).watchVerifications(uid);
});

final animalVerificationsProvider =
    StreamProvider.family<List<Verification>, String>((Ref ref, String animalId) {
  return ref
      .watch(permitRepositoryProvider)
      .watchVerificationsForAnimal(animalId);
});
