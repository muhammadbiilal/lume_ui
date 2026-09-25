/// Prayer Tracker over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/praytrack_repository.dart';

final Provider<PrayTrackRepository> prayTrackRepositoryProvider =
    Provider<PrayTrackRepository>(
      (Ref ref) => PrayTrackRepository(ref.watch(recordRepositoryProvider)),
    );
