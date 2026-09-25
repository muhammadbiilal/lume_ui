/// Pregnancy over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/pregnancy_repository.dart';

final Provider<PregnancyRepository> pregnancyRepositoryProvider =
    Provider<PregnancyRepository>(
      (Ref ref) => PregnancyRepository(ref.watch(recordRepositoryProvider)),
    );
