/// The one record store every record tool reads — `records.js` `createRecords`.
///
/// In memory and declared not durable (C74): the reference writes browser
/// storage, and this build takes no storage package. Dayroz overrides this
/// provider with its durable, encrypted store behind the same interface.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/lume_build_profile.dart';
import '../../features/records/data/memory_record_repository.dart';
import '../../features/records/data/record_seeds.dart';
import '../../features/records/domain/record_repository.dart';

final Provider<LumeRecordRepository> recordRepositoryProvider =
    Provider<LumeRecordRepository>((Ref ref) {
      // Only the build that reproduces the reference gets the two families
      // whose seeds would be an account of the reader's own life
      // ([kLumeParityOnlySeeds]).
      final bool parity = ref.watch(buildProfileProvider).reproducesReference;
      final LumeMemoryRecordRepository store = LumeMemoryRecordRepository(
        seeds: (String collection, DateTime now) =>
            lumeRecordSeeds(collection, now, reproducesReference: parity),
      );
      ref.onDispose(store.dispose);
      return store;
    });
