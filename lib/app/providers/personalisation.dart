/// Personalisation, as the screens read it.
///
/// The launch already holds the profile — [LumeStartupController] reads it,
/// migrates it once, and republishes it whenever onboarding or a setting moves
/// it. So there is no second store: this is the one place that turns that
/// record into the [LumeUserContext] every destination, the catalogue and the
/// eligibility selector take.
///
/// It is a widget rather than a provider because the controller is a
/// [ChangeNotifier] and a plain `Provider` does not rebuild when one notifies.
/// [LumeProfileScope] listens, so changing country or switching the Islamic
/// experience off re-renders Home and the Tools hub in the same frame the
/// setting changed — which is §36's "changing these settings should
/// dynamically update the application", and §37's promise that nothing is
/// deleted while it happens.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalogue/data/feature_catalogue.dart';
import '../../features/catalogue/domain/eligibility.dart';
import '../../features/home/data/home_fixtures.dart';
import '../../features/explore/data/explore_fixtures.dart';
import '../../features/explore/domain/explore_repository.dart';
import '../../features/home/domain/home_repository.dart';
import '../../features/today/data/today_fixtures.dart';
import '../../features/today/domain/today_repository.dart';
import '../../features/onboarding/domain/onboarding_state.dart';
import '../../features/startup/application/startup_controller.dart';
import 'shell_provider.dart';

/// The registry, as one selector.
///
/// A provider so a test can hand a screen a catalogue of three features and
/// assert the composition rather than the contents of the real one.
final Provider<LumeEligibility> eligibilityProvider = Provider<LumeEligibility>(
  (Ref ref) => const LumeEligibility(
    features: kLumeFeatures,
    categories: kLumeCategories,
  ),
);

/// A country forced from outside the profile.
///
/// `null` — the product's value — means "read it from the profile, which is
/// the only place it is stored". A test or a preview overrides this to put a
/// screen in another market without writing to the user's record.
final Provider<String?> countryOverrideProvider = Provider<String?>(
  (Ref ref) => null,
);

/// Where Home's values come from.
///
/// A deterministic fixture carrying the prototype's own figures. It connects
/// to nothing; overriding this one provider is the whole of the swap when each
/// tool's real repository arrives.
final Provider<LumeHomeRepository> homeDataRepositoryProvider =
    Provider<LumeHomeRepository>((Ref ref) => LumeFakeHomeRepository());

/// Writes a tool to the recents list.
///
/// Opening a tool anywhere in the app writes it here, and the hub re-reads it
/// on every arrival — so there is nothing to subscribe to. The list is
/// filtered again on the way *out* (`LumeEligibility.recentFeatures`), because
/// a feature that has since been hidden must not resurface through history.
/// Today's day, from a deterministic fixture.
///
/// A real one aggregates the reader's own tasks, calendar, prayers, habits
/// and bills — see [LumeTodayRepository]. Nothing here persists.
final Provider<LumeTodayRepository> todayRepositoryProvider =
    Provider<LumeTodayRepository>(
      (Ref ref) =>
          LumeFakeTodayRepository(eligibility: ref.watch(eligibilityProvider)),
    );

/// Explore's context, from a deterministic fixture.
final Provider<LumeExploreRepository> exploreRepositoryProvider =
    Provider<LumeExploreRepository>(
      (Ref ref) => LumeFakeExploreRepository(
        eligibility: ref.watch(eligibilityProvider),
      ),
    );

final Provider<LumeRecentTools> recentToolsProvider = Provider<LumeRecentTools>(
  (Ref ref) => LumeRecentTools(ref.watch(startupControllerProvider)),
);

/// The recents writer.
class LumeRecentTools {
  const LumeRecentTools(this._gate);

  final LumeStartupController _gate;

  void note(String featureId) {
    final LumeProfileRecord record = _gate.state.profile;
    if (record.recents.firstOrNull == featureId) return;
    _gate.profileChanged(record.noteRecent(featureId));
  }
}

/// Hands its builder the live personalisation.
class LumeProfileScope extends ConsumerWidget {
  const LumeProfileScope({super.key, required this.builder});

  final Widget Function(BuildContext context, LumeUserContext user) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeStartupController gate = ref.watch(startupControllerProvider);
    final String? forced = ref.watch(countryOverrideProvider);

    return ListenableBuilder(
      listenable: gate,
      builder: (BuildContext context, Widget? _) {
        LumeUserContext user = LumeUserContext.from(gate.state.profile);
        if (forced != null) user = user.copyWith(country: forced);
        return builder(context, user);
      },
    );
  }
}
