/// The first-run flow: nine steps, one draft, one place that writes.
///
/// The prototype's `onbShow` is a function over an index and this is the same
/// machine — forward, back, skip, clamp, and the two steps that own their own
/// Continue. What it adds is the thing a browser prototype does not need: the
/// draft is a value, the record is behind an interface, and the points at
/// which the two meet are named.
///
/// **Where it writes, and why there.**
///
/// | Point | Writes |
/// |---|---|
/// | City's Continue | country, region, city — *before* interests, so the picker can drop what leads nowhere here |
/// | Interests' Continue | interests, and the faith outcome |
/// | Name's Continue | the display name, and **only when it changed** |
/// | Finish | the whole draft, and the completion marker |
/// | Header Skip | defaults when nothing was chosen, otherwise just the marker |
///
/// The name step's own "Skip for now" writes nothing at all: §124.4, skipping
/// is a first-class outcome rather than a deletion.
///
/// **Back does not unwind writes.** Going back from interests to the city step
/// leaves the location written — which is what the prototype does, and what a
/// user means by "let me look at that again". The draft is the single copy, so
/// returning to a step finds what was left there.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/lume_back_intercept.dart';
import '../../../l10n/app_localizations.dart';
import '../data/country_fixture.dart';
import '../data/interests_fixture.dart';
import '../domain/city_picker_model.dart';
import '../domain/interests_model.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_art.dart';
import 'onboarding_slides.dart';
import 'onboarding_steps.dart';

/// How the flow ended.
enum LumeOnboardingOutcome {
  /// The last step's Enter Lume.
  finished,

  /// The header's Skip, from anywhere.
  skipped,

  /// The welcome step's "Sign in". Authentication is its own phase; the flow
  /// hands over rather than pretending.
  signIn,
}

/// Hosts all nine steps.
class LumeOnboardingFlow extends StatefulWidget {
  const LumeOnboardingFlow({
    super.key,
    required this.countries,
    required this.catalogue,
    required this.store,
    this.onDone,
    this.initialStep = LumeOnboardingStep.welcome,
    this.nextPrayerName,
    this.onUseLocation,
  });

  final LumeCountryFixture countries;
  final LumeInterestsFixture catalogue;

  /// Read on entry, written at the points above. In memory here; Dayroz's at
  /// integration.
  final LumeOnboardingStore store;

  /// Called with how it ended and what was collected. The record is already
  /// written by the time this runs.
  final void Function(LumeOnboardingOutcome outcome, LumeProfileRecord record)?
  onDone;

  final int initialStep;

  /// The prayer the completion copy names, when the experience is on. `null`
  /// falls back to the neutral sentence rather than leaving a hole in one.
  final String? nextPrayerName;

  /// The city step's "use my current location". `null` leaves it inert — a
  /// real permission belongs to the platform, at the moment it is needed.
  final VoidCallback? onUseLocation;

  @override
  State<LumeOnboardingFlow> createState() => LumeOnboardingFlowState();
}

class LumeOnboardingFlowState extends State<LumeOnboardingFlow> {
  late int _step = widget.initialStep;
  late LumeOnboardingDraft _draft;

  /// The name the step opened with, so Continue can tell a change from a
  /// no-op without asking the store again.
  late String _nameOnEntry;

  /// The interests step's selection, owned here rather than by the step.
  ///
  /// `onbPicker` is built once in the prototype and keeps its own `sel` set
  /// across step changes, so walking back to the city and forward again finds
  /// the same five chosen. A `State` that is disposed on the way out cannot do
  /// that, and a draft that is only written on Continue never sees the picks
  /// at all — so the controller lives for the flow's lifetime.
  late final LumeInterestsController _interests = LumeInterestsController(
    selected: _draft.interests,
    faithOpen: _draft.islamic,
    faithInterests: widget.catalogue.faithInterests,
  );

  @visibleForTesting
  int get step => _step;

  @visibleForTesting
  LumeOnboardingDraft get draft => _draft;

  @override
  void initState() {
    super.initState();
    // Whatever the store hands over has already been through
    // `LumeProfileMigrator` at startup. Deciding a migration needs installation
    // metadata, which is a repository's to know and a widget's to stay out of;
    // this one reads a record and nothing else.
    final LumeProfileRecord record = widget.store.read();
    _draft = LumeOnboardingState.draftFrom(record);
    _nameOnEntry = record.displayName;
  }

  @override
  void dispose() {
    _interests.dispose();
    super.dispose();
  }

  void _go(int next) {
    setState(() => _step = next.clamp(0, LumeOnboardingStep.done));
  }

  void _back() {
    if (!LumeOnboardingStep.canGoBack(_step)) return;
    _go(_step - 1);
  }

  /// The header's Skip. Available on every step but the last.
  void _skip() {
    final LumeProfileRecord record = LumeOnboardingState.skip(
      widget.store.read(),
      _draft,
    );
    widget.store.write(record);
    widget.onDone?.call(LumeOnboardingOutcome.skipped, record);
  }

  void _signIn() {
    // Somebody who already has an account still gets a usable app if they
    // never come back: the same defaults Skip writes.
    final LumeProfileRecord record = LumeOnboardingState.skip(
      widget.store.read(),
      _draft,
    );
    widget.store.write(record);
    widget.onDone?.call(LumeOnboardingOutcome.signIn, record);
  }

  void _finish() {
    final LumeProfileRecord record = LumeOnboardingState.commit(
      widget.store.read(),
      _draft,
    );
    widget.store.write(record);
    widget.onDone?.call(LumeOnboardingOutcome.finished, record);
  }

  /// Choosing a country resets the city to that country's first, so a city
  /// from the previous country is never left standing.
  void _chooseCountry(String code) {
    final LumePlaces places = widget.countries.placesOf(code);
    final ({String city, String? region}) fallback =
        LumeCityPicker.defaultCityFor(
          regions: places.regions,
          cities: places.cities,
        );
    setState(() {
      _draft = _draft.copyWith(
        country: code,
        city: fallback.city,
        region: fallback.region,
        clearRegion: fallback.region == null,
      );
    });
    _go(LumeOnboardingStep.city);
  }

  void _chooseCity(String city, String? region) {
    setState(() {
      _draft = _draft.copyWith(
        city: city,
        region: region,
        clearRegion: region == null,
      );
    });
    // The location lands in the record here, before the interests step, so
    // the picker can filter on it.
    widget.store.write(
      widget.store.read().copyWith(
        country: _draft.country,
        region: _draft.region,
        city: _draft.city,
      ),
    );
    _go(LumeOnboardingStep.interests);
  }

  void _chooseInterests(Set<String> interests, bool islamic) {
    setState(() {
      _draft = _draft.copyWith(interests: interests, islamic: islamic);
    });
    widget.store.write(
      widget.store.read().copyWith(
        interests: interests.toList(),
        islamic: LumeOnboardingState.faithFrom(interests, current: islamic),
      ),
    );
    _go(LumeOnboardingStep.setUp);
  }

  void _commitName(String name) {
    setState(() => _draft = _draft.copyWith(displayName: name));
    widget.store.write(widget.store.read().copyWith(displayName: name));
    _go(LumeOnboardingStep.done);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    // Back inside the flow moves one step; from the first it leaves, which is
    // the route's business rather than the flow's.
    return LumeBackIntercept(
      onBack: () async {
        if (!LumeOnboardingStep.canGoBack(_step)) return false;
        _back();
        return true;
      },
      child: switch (_step) {
        LumeOnboardingStep.plan => ValueSlideStep(
          step: LumeOnboardingStep.plan,
          artwork: LumeOnboardingArtwork.plan,
          kicker: l.onbPlanKicker,
          title: l.onbPlanTitle,
          text: l.onbPlanText,
          onContinue: () => _go(LumeOnboardingStep.tools),
          onBack: _back,
          onSkip: _skip,
        ),
        LumeOnboardingStep.tools => ValueSlideStep(
          step: LumeOnboardingStep.tools,
          artwork: LumeOnboardingArtwork.tools,
          kicker: l.onbToolsKicker,
          // The whole catalogue, not the eligible subset — the copy quotes
          // what Lume has, not what this user can see.
          title: l.onbToolsTitle('${widget.catalogue.featureCount}'),
          text: l.onbToolsText,
          onContinue: () => _go(LumeOnboardingStep.country),
          onBack: _back,
          onSkip: _skip,
        ),
        LumeOnboardingStep.country => CountryStep(
          countries: widget.countries,
          initialCountry: _draft.country,
          onContinue: _chooseCountry,
          onBack: _back,
          onSkip: _skip,
        ),
        LumeOnboardingStep.city => CityStep(
          countries: widget.countries,
          country: _draft.country,
          initialCity: _draft.city,
          initialRegion: _draft.region,
          onContinue: _chooseCity,
          onBack: _back,
          onSkip: _skip,
          onUseLocation: widget.onUseLocation,
        ),
        LumeOnboardingStep.interests => InterestsStep(
          catalogue: widget.catalogue,
          controller: _interests,
          onContinue: _chooseInterests,
          onBack: _back,
          onSkip: _skip,
        ),
        LumeOnboardingStep.setUp => SetUpStep(
          draft: _draft,
          onChanged: (LumeOnboardingDraft d) => setState(() => _draft = d),
          onContinue: () => _go(LumeOnboardingStep.name),
          onBack: _back,
          onSkip: _skip,
        ),
        LumeOnboardingStep.name => NameStep(
          initialName: _nameOnEntry,
          onContinue: _commitName,
          // "Skip for now" advances and writes nothing.
          onSkipStep: () => _go(LumeOnboardingStep.done),
          onBack: _back,
          onSkip: _skip,
        ),
        LumeOnboardingStep.done => DoneStep(
          name: _draft.displayName,
          islamic: _draft.islamic,
          nextPrayer: widget.nextPrayerName,
          onFinish: _finish,
          onBack: _back,
        ),
        _ => WelcomeStep(
          onContinue: () => _go(LumeOnboardingStep.plan),
          onSignIn: _signIn,
          onSkip: _skip,
        ),
      },
    );
  }
}

/// The two bundled tables, once loaded.
typedef LumeOnboardingTables = ({
  LumeCountryFixture countries,
  LumeInterestsFixture catalogue,
});

/// Loads them, then hosts the flow.
///
/// The adapters read an asset, so there is one frame before they answer. A
/// spinner would be the wrong thing for a first run — the flow's own ground is
/// already the right colour — so the wait renders nothing over it.
class LumeOnboardingFlowLoader extends StatefulWidget {
  const LumeOnboardingFlowLoader({
    super.key,
    required this.store,
    this.onDone,
    this.initialStep = LumeOnboardingStep.welcome,
    this.nextPrayerName,
    this.onUseLocation,
  });

  final LumeOnboardingStore store;
  final void Function(LumeOnboardingOutcome outcome, LumeProfileRecord record)?
  onDone;
  final int initialStep;
  final String? nextPrayerName;
  final VoidCallback? onUseLocation;

  @override
  State<LumeOnboardingFlowLoader> createState() =>
      _LumeOnboardingFlowLoaderState();
}

class _LumeOnboardingFlowLoaderState extends State<LumeOnboardingFlowLoader> {
  late final Future<LumeOnboardingTables> _tables = _load();

  static Future<LumeOnboardingTables> _load() async => (
    countries: await LumeCountryFixture.load(),
    catalogue: await LumeInterestsFixture.load(),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LumeOnboardingTables>(
      future: _tables,
      builder:
          (BuildContext context, AsyncSnapshot<LumeOnboardingTables> snapshot) {
            // A first run with no country table is not a state to render
            // quietly — an invisible box that never resolves is the hardest
            // failure there is to find.
            final Object? error = snapshot.error;
            if (error != null) {
              Error.throwWithStackTrace(
                error,
                snapshot.stackTrace ?? StackTrace.current,
              );
            }
            final LumeOnboardingTables? data = snapshot.data;
            if (data == null) return const SizedBox.expand();
            return LumeOnboardingFlow(
              countries: data.countries,
              catalogue: data.catalogue,
              store: widget.store,
              initialStep: widget.initialStep,
              nextPrayerName: widget.nextPrayerName,
              onUseLocation: widget.onUseLocation,
              onDone: widget.onDone,
            );
          },
    );
  }
}
