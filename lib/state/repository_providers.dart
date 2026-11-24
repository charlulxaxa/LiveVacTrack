import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/psgc_location_service.dart';
import '../data/demo/demo_store.dart';
import '../data/firebase/firebase_auth_service.dart';
import '../data/firebase/firebase_functions_service.dart';
import '../data/firebase/firebase_permit_repository.dart';
import '../data/firebase/firebase_quarantine_repository.dart';
import '../data/firebase/firebase_registry_repository.dart';
import '../data/firebase/firebase_staff_account_service.dart';
import '../data/firebase/firebase_vaccination_repository.dart';
import '../data/repositories/permit_repository.dart';
import '../data/repositories/quarantine_repository.dart';
import '../data/repositories/registry_repository.dart';
import '../data/repositories/vaccination_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/staff_account_service.dart';
import 'app_providers.dart';

final Provider<DemoStore> demoStoreProvider =
    Provider<DemoStore>((Ref ref) => DemoStore.instance);

final Provider<AuthService> authServiceProvider = Provider<AuthService>((Ref ref) {
  if (ref.watch(demoModeProvider)) return DemoAuthService();
  return FirebaseAuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final Provider<RegistryRepository> registryRepositoryProvider =
    Provider<RegistryRepository>((Ref ref) {
  if (ref.watch(demoModeProvider)) {
    return DemoRegistryRepository(ref.watch(demoStoreProvider));
  }
  return FirebaseRegistryRepository(
    FirebaseFirestore.instance,
  );
});

final Provider<VaccinationRepository> vaccinationRepositoryProvider =
    Provider<VaccinationRepository>((Ref ref) {
  if (ref.watch(demoModeProvider)) {
    return DemoVaccinationRepository(ref.watch(demoStoreProvider));
  }
  return FirebaseVaccinationRepository(
    FirebaseFirestore.instance,
  );
});

final Provider<PermitRepository> permitRepositoryProvider =
    Provider<PermitRepository>((Ref ref) {
  if (ref.watch(demoModeProvider)) {
    return DemoPermitRepository(ref.watch(demoStoreProvider));
  }
  return FirebasePermitRepository(
    FirebaseFirestore.instance,
    FirebaseFunctionsService(FirebaseFunctions.instance),
  );
});

final Provider<QuarantineRepository> quarantineRepositoryProvider =
    Provider<QuarantineRepository>((Ref ref) {
  if (ref.watch(demoModeProvider)) {
    return DemoQuarantineRepository(ref.watch(demoStoreProvider));
  }
  return FirebaseQuarantineRepository(
    FirebaseFirestore.instance,
    FirebaseFunctionsService(FirebaseFunctions.instance),
  );
});

final Provider<StaffAccountService> staffAccountServiceProvider =
    Provider<StaffAccountService>((Ref ref) {
  if (ref.watch(demoModeProvider)) return DemoStaffAccountService();
  return FirebaseStaffAccountService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final Provider<PsgcLocationService> psgcLocationServiceProvider =
    Provider<PsgcLocationService>((Ref ref) => PsgcLocationService());
