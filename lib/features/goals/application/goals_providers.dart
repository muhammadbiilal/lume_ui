/// Goals over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/goals_repository.dart';

/// Goals' repository. Ids come from a secure random source and creation
/// instants from the device clock; a test overrides both.
final Provider<GoalsRepository> goalsRepositoryProvider = Provider<GoalsRepository>(
  (Ref ref) => GoalsRepository(ref.watch(recordRepositoryProvider)),
);
