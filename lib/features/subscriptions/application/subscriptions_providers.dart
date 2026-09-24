/// Subscriptions over the one record store every record tool shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../domain/subscriptions_repository.dart';

final Provider<SubscriptionsRepository> subscriptionsRepositoryProvider =
    Provider<SubscriptionsRepository>(
      (Ref ref) => SubscriptionsRepository(ref.watch(recordRepositoryProvider)),
    );
