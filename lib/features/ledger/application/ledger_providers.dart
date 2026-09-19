/// The Ledger over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/ledger_repository.dart';

/// Ledger's repository. Ids come from a secure random source and creation
/// instants from the device clock; a test overrides both.
final Provider<LedgerRepository> ledgerRepositoryProvider =
    Provider<LedgerRepository>(
      (Ref ref) => LedgerRepository(ref.watch(recordRepositoryProvider)),
    );
