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
import '../../features/onboarding/domain/islamic_migration.dart';
import '../../features/onboarding/domain/onboarding_state.dart';
import '../../features/onboarding/domain/profile_repository.dart';

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

/// Where onboarding's record lives.
///
/// In memory for now: this repository is the interface, and persistence is a
/// Dayroz provider's job at integration. Overriding this one provider is all
/// that swap takes — the flow, the steps and the state machine never see it.
final Provider<LumeOnboardingStore> onboardingStoreProvider =
    Provider<LumeOnboardingStore>((Ref ref) => LumeMemoryOnboardingStore());

/// The durable profile contract, as this build can supply it.
///
/// [LumeMemoryProfileRepository.isDurable] is `false` and it reports a fresh
/// installation, which is the truth about a process that starts with nothing.
/// Dayroz overrides this provider with an implementation that survives a
/// restart and can name the cohort it is looking at; until then the first-run
/// gate stays unbuilt rather than built on a store that forgets.
final Provider<LumeProfileRepository> profileRepositoryProvider =
    Provider<LumeProfileRepository>((Ref ref) => LumeMemoryProfileRepository());

/// Runs the one-shot profile migrations at startup, before anything reads a
/// preference.
final Provider<LumeProfileMigrator> profileMigratorProvider =
    Provider<LumeProfileMigrator>(
      (Ref ref) => LumeProfileMigrator(ref.watch(profileRepositoryProvider)),
    );
