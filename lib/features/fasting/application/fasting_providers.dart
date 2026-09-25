/// Fasting Tracker over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/fasting_repository.dart';

final Provider<FastingRepository> fastingRepositoryProvider =
    Provider<FastingRepository>(
      (Ref ref) => FastingRepository(ref.watch(recordRepositoryProvider)),
    );
