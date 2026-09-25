/// Taraweeh over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/taraweeh_repository.dart';

final Provider<TaraweehRepository> taraweehRepositoryProvider =
    Provider<TaraweehRepository>(
      (Ref ref) => TaraweehRepository(ref.watch(recordRepositoryProvider)),
    );
