/// The four steps that only tell you something.
///
/// Welcome, the two value slides and the completion: an illustration, a
/// heading, a sentence, one action. They collect nothing, so none of them owns
/// a controller or reports a value — the flow moves them along.
///
/// The five that *do* collect are in `onboarding_steps.dart`. The split is by
/// what a step is, not by which phase built it.
library;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_art.dart';
import 'onboarding_chrome.dart';
import 'onboarding_parts.dart';

/// Step 0 — Welcome.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, this.onContinue, this.onSignIn, this.onSkip});

  final VoidCallback? onContinue;

  /// §124.6 — this leads to authentication, not to a toast that pretends
  /// somebody signed in. F4B leaves the destination to its caller, because
  /// authentication is its own phase.
  final VoidCallback? onSignIn;

  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeOnboardingScaffold(
      step: LumeOnboardingStep.welcome,
      // No Back on the first step: the control is invisible and unreachable,
      // and keeps its 34 points so the progress bar does not shift.
      onSkip: onSkip,
      skipLabel: l.actionSkip,
      action: LumeOnboardingContinue(
        label: l.actionGetStarted,
        onPressed: onContinue,
      ),
      secondaryAction: <Widget>[
        LumeOnboardingLink(
          label: l.onbSignInPrompt,
          emphasis: l.onbSignInAction,
          onPressed: onSignIn,
        ),
      ],
      art: const LumeOnboardingArt(artwork: LumeOnboardingArtwork.welcome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeOnboardingBrand(wordmark: 'Lume', tagline: l.appTagline),
          LumeOnboardingLead(
            title: l.onbWelcomeTitle,
            text: l.onbWelcomeText,
            topPadding: 0,
          ),
        ],
      ),
    );
  }
}

/// Steps 1 and 2 — the two value slides.
///
/// One widget, because they are one composition with different words: art,
/// kicker, title, text, Continue. Splitting them would be two copies of the
/// same file waiting to drift.
class ValueSlideStep extends StatelessWidget {
  const ValueSlideStep({
    super.key,
    required this.step,
    required this.artwork,
    required this.kicker,
    required this.title,
    required this.text,
    this.onContinue,
    this.onBack,
    this.onSkip,
  });

  final int step;
  final LumeOnboardingArtwork artwork;
  final String kicker;
  final String title;
  final String text;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeOnboardingScaffold(
      step: step,
      onBack: onBack,
      onSkip: onSkip,
      backLabel: l.actionBack,
      skipLabel: l.actionSkip,
      action: LumeOnboardingContinue(
        label: l.actionContinue,
        onPressed: onContinue,
      ),
      art: LumeOnboardingArt(artwork: artwork),
      child: LumeOnboardingLead(
        kicker: kicker,
        title: title,
        text: text,
        topPadding: 0,
      ),
    );
  }
}

/// Step 8 — You're all set.
class DoneStep extends StatelessWidget {
  const DoneStep({
    super.key,
    required this.name,
    required this.islamic,
    this.nextPrayer,
    this.onFinish,
    this.onBack,
  });

  /// Empty when nobody gave one, which is a designed branch rather than the
  /// lesser of two.
  final String name;

  final bool islamic;

  /// The prayer the faith copy names. `null` falls back to the general copy,
  /// because a sentence with a hole in it is worse than the neutral one.
  final String? nextPrayer;

  final VoidCallback? onFinish;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool faithCopy = islamic && nextPrayer != null;

    return LumeOnboardingScaffold(
      step: LumeOnboardingStep.done,
      onBack: onBack,
      backLabel: l.actionBack,
      // `.onb__skip[disabled]` — the last step has nothing left to skip past,
      // so Skip is invisible and inert, and still holds the top row's shape.
      // The label is still given: without one there would be no control to
      // reserve the space with.
      skipLabel: l.actionSkip,
      action: LumeOnboardingContinue(
        label: l.onbEnterLume,
        onPressed: onFinish,
      ),
      secondaryAction: <Widget>[LumeOnboardingNote(text: l.onbRevisit)],
      art: const LumeOnboardingSeal(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeOnboardingLead(
            kicker: l.onbAllSet,
            title: name.isEmpty ? l.onbReadyTitle : l.onbReadyNamed(name),
            text: faithCopy ? l.onbReadyFaith(nextPrayer!) : l.onbReadyGeneral,
            // `t('onb.readyFaith', { prayer: '<b>' + name + '</b>' })`.
            emphasis: faithCopy ? nextPrayer : null,
            topPadding: 0,
          ),
        ],
      ),
    );
  }
}
