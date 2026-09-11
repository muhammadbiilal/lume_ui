/// What the shell needs to know about the user, until there is a profile.
///
/// `app-store.js` owns country, region, city, language, faith, units, currency
/// and interests, and defaults `country` to `PK`. The profile store itself is
/// F4 work; the shell needs exactly one field out of it — the country, because
/// the tab set is personalised by it — plus the two things that decorate a
/// destination. So that is what this holds, and nothing more, so that when the
/// real store arrives these three providers are replaced rather than unpicked.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/lume_destination.dart';

/// The user's country, as an ISO 3166-1 alpha-2 code.
///
/// Pakistan by default, matching `app-store.js`. It decides one thing in this
/// layer: whether Trains is a tab. It decides **nothing** about language,
/// direction or faith — those are separate dimensions and are read from
/// elsewhere.
final StateProvider<String> countryCodeProvider = StateProvider<String>(
  (Ref ref) => 'PK',
);

/// Counts on destinations. Empty until the notification engine exists.
final StateProvider<Map<LumeDestinationId, int>> destinationBadgesProvider =
    StateProvider<Map<LumeDestinationId, int>>(
      (Ref ref) => const <LumeDestinationId, int>{},
    );

/// Unread markers with no number.
final StateProvider<Set<LumeDestinationId>> destinationDotsProvider =
    StateProvider<Set<LumeDestinationId>>(
      (Ref ref) => const <LumeDestinationId>{},
    );
