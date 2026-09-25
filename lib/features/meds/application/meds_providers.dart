/// Medication over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/meds_repository.dart';

final Provider<MedsRepository> medsRepositoryProvider = Provider<MedsRepository>(
  (Ref ref) => MedsRepository(ref.watch(recordRepositoryProvider)),
);
