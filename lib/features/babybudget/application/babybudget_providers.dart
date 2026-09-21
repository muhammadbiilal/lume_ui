/// Baby Budget's repository. Ids come from a secure random source and
/// creation instants from the device clock; a test overrides both.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/babybudget_repository.dart';

final Provider<BabyBudgetRepository> babyBudgetRepositoryProvider =
    Provider<BabyBudgetRepository>(
      (Ref ref) => BabyBudgetRepository(ref.watch(recordRepositoryProvider)),
    );
