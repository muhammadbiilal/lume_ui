/// The one record store every record tool reads — `records.js` `createRecords`.
///
/// In memory and declared not durable (C74): the reference writes browser
/// storage, and this build takes no storage package. Dayroz overrides this
/// provider with its durable, encrypted store behind the same interface.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/records/data/memory_record_repository.dart';
import '../../features/records/data/record_seeds.dart';
import '../../features/records/domain/record_repository.dart';

final Provider<LumeRecordRepository> recordRepositoryProvider =
    Provider<LumeRecordRepository>((Ref ref) {
      final LumeMemoryRecordRepository store = LumeMemoryRecordRepository(
        seeds: lumeRecordSeeds,
      );
      ref.onDispose(store.dispose);
      return store;
    });
