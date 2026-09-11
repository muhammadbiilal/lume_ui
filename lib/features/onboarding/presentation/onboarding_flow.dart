/// The slice of the first-run flow that exists.
///
/// F4A converted two of the nine steps, and this is what makes them reachable
/// rather than only testable: country, then interests, then out. The seven
/// others are F4B, and this host is where they will be added — it already
/// carries the step index, the back stack and the draft, so adding one is a
/// case in [_step] rather than a new structure.
///
/// **It holds no state a real flow would keep.** The draft lives here for the
/// length of the flow and is handed to `onFinished` at the end; there is no
/// persistence, no profile store and no backend. Wiring it to Dayroz's
/// preference store is documented in ONBOARDING_CONTRACT §5 and is not done
/// here.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/lume_back_intercept.dart';
import '../data/country_fixture.dart';
import '../data/interests_fixture.dart';
import 'onboarding_steps.dart';

/// What the flow has collected so far.
@immutable
class LumeOnboardingDraft {
  const LumeOnboardingDraft({
    this.country = LumeCountryFixtureState.defaultCountry,
    this.interests = const <String>{},
    this.islamic = false,
  });

  final String country;
  final Set<String> interests;

  /// Whether the Islamic experience is on — decided by the interests step's
  /// switch, and never inferred from the country.
  final bool islamic;

  LumeOnboardingDraft copyWith({
    String? country,
    Set<String>? interests,
    bool? islamic,
  }) => LumeOnboardingDraft(
    country: country ?? this.country,
    interests: interests ?? this.interests,
    islamic: islamic ?? this.islamic,
  );
}

/// Hosts the steps that exist, in order.
class LumeOnboardingFlow extends StatefulWidget {
  const LumeOnboardingFlow({
    super.key,
    required this.countries,
    required this.catalogue,
    this.onFinished,
    this.onLeave,
    this.initialStep = LumeOnboardingStep.country,
  });

  final LumeCountryFixture countries;
  final LumeInterestsFixture catalogue;

  /// Called with everything collected, when the last converted step is done.
  final ValueChanged<LumeOnboardingDraft>? onFinished;

  /// Called when Back leaves the first step, or Skip leaves the flow.
  final VoidCallback? onLeave;

  final int initialStep;

  @override
  State<LumeOnboardingFlow> createState() => _LumeOnboardingFlowState();
}

class _LumeOnboardingFlowState extends State<LumeOnboardingFlow> {
  late int _step = widget.initialStep;
  LumeOnboardingDraft _draft = const LumeOnboardingDraft();

  /// The steps this slice knows how to show, in flow order.
  static const List<int> _converted = <int>[
    LumeOnboardingStep.country,
    LumeOnboardingStep.interests,
  ];

  void _back() {
    final int at = _converted.indexOf(_step);
    if (at <= 0) {
      widget.onLeave?.call();
      return;
    }
    setState(() => _step = _converted[at - 1]);
  }

  void _advance() {
    final int at = _converted.indexOf(_step);
    if (at < 0 || at == _converted.length - 1) {
      widget.onFinished?.call(_draft);
      return;
    }
    setState(() => _step = _converted[at + 1]);
  }

  @override
  Widget build(BuildContext context) {
    // Back leaves the flow only from its first step; inside it, it moves back
    // one. A route pop would skip the intermediate steps.
    return LumeBackIntercept(
      onBack: () async {
        if (_converted.indexOf(_step) <= 0) return false;
        _back();
        return true;
      },
      child: switch (_step) {
        LumeOnboardingStep.interests => InterestsStep(
          catalogue: widget.catalogue,
          initialSelection: _draft.interests,
          initialFaithOpen: _draft.islamic,
          onBack: _back,
          onSkip: widget.onLeave,
          onContinue: (Set<String> interests, bool islamic) {
            setState(() {
              _draft = _draft.copyWith(interests: interests, islamic: islamic);
            });
            _advance();
          },
        ),
        _ => CountryStep(
          countries: widget.countries,
          initialCountry: _draft.country,
          onBack: _back,
          onSkip: widget.onLeave,
          onContinue: (String code) {
            setState(() => _draft = _draft.copyWith(country: code));
            _advance();
          },
        ),
      },
    );
  }
}

/// Loads the two bundled tables, then hosts the flow.
///
/// The adapters read an asset, so there is one frame before they answer. A
/// spinner would be the wrong thing for a first run — the flow's own ground is
/// already the right colour — so the wait renders the ground and nothing else.
class LumeOnboardingFlowLoader extends StatefulWidget {
  const LumeOnboardingFlowLoader({
    super.key,
    this.onFinished,
    this.onLeave,
    this.initialStep = LumeOnboardingStep.country,
  });

  final ValueChanged<LumeOnboardingDraft>? onFinished;
  final VoidCallback? onLeave;
  final int initialStep;

  @override
  State<LumeOnboardingFlowLoader> createState() =>
      _LumeOnboardingFlowLoaderState();
}

class _LumeOnboardingFlowLoaderState extends State<LumeOnboardingFlowLoader> {
  late final Future<
    ({LumeCountryFixture countries, LumeInterestsFixture catalogue})
  >
  _tables = _load();

  static Future<
    ({LumeCountryFixture countries, LumeInterestsFixture catalogue})
  >
  _load() async => (
    countries: await LumeCountryFixture.load(),
    catalogue: await LumeInterestsFixture.load(),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
      ({LumeCountryFixture countries, LumeInterestsFixture catalogue})
    >(
      future: _tables,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        final ({LumeCountryFixture countries, LumeInterestsFixture catalogue})?
        data =
            snapshot.data
                as ({
                  LumeCountryFixture countries,
                  LumeInterestsFixture catalogue,
                })?;
        if (data == null) return const SizedBox.expand();
        return LumeOnboardingFlow(
          countries: data.countries,
          catalogue: data.catalogue,
          initialStep: widget.initialStep,
          onFinished: widget.onFinished,
          onLeave: widget.onLeave,
        );
      },
    );
  }
}
