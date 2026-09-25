/// Vaccinations over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/vaccines_repository.dart';

final Provider<VaccinesRepository> vaccinesRepositoryProvider = Provider<VaccinesRepository>(
  (Ref ref) => VaccinesRepository(ref.watch(recordRepositoryProvider)),
);
