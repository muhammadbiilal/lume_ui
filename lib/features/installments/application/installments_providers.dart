/// Installments over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/installments_repository.dart';

/// Installments' repository. Ids come from a secure random source and
/// creation instants from the device clock; a test overrides both.
final Provider<InstallmentsRepository> installmentsRepositoryProvider =
    Provider<InstallmentsRepository>(
      (Ref ref) => InstallmentsRepository(ref.watch(recordRepositoryProvider)),
    );
