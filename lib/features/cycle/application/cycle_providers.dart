/// Cycle Tracker over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/cycle_repository.dart';

final Provider<CycleRepository> cycleRepositoryProvider =
    Provider<CycleRepository>(
      (Ref ref) => CycleRepository(ref.watch(recordRepositoryProvider)),
    );
