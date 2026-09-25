/// Daily Streak over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/streak_repository.dart';

final Provider<StreakRepository> streakRepositoryProvider =
    Provider<StreakRepository>(
      (Ref ref) => StreakRepository(ref.watch(recordRepositoryProvider)),
    );
