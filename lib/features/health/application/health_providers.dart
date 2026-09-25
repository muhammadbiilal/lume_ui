/// Health Records over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/health_repository.dart';

final Provider<HealthRepository> healthRepositoryProvider = Provider<HealthRepository>(
  (Ref ref) => HealthRepository(ref.watch(recordRepositoryProvider)),
);
