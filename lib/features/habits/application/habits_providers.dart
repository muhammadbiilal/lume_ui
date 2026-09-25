/// Habits over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/habits_repository.dart';

final Provider<HabitsRepository> habitsRepositoryProvider =
    Provider<HabitsRepository>(
      (Ref ref) => HabitsRepository(ref.watch(recordRepositoryProvider)),
    );
