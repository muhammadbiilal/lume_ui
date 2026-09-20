/// Committee's repository. Ids come from a secure random source and
/// creation instants from the device clock; a test overrides both.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/committee_repository.dart';

final Provider<CommitteeRepository> committeeRepositoryProvider =
    Provider<CommitteeRepository>(
      (Ref ref) => CommitteeRepository(ref.watch(recordRepositoryProvider)),
    );
