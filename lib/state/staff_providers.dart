import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/staff_member.dart';
import 'repository_providers.dart';

final StreamProvider<List<StaffMember>> staffMembersProvider =
    StreamProvider<List<StaffMember>>((Ref ref) {
  return ref.watch(staffAccountServiceProvider).watchStaff();
});
