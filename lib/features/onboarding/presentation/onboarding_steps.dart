/// The two reference steps, wired: chrome, view model, controller, strings.
///
/// Each step owns three things and no more — the controller, the localisations,
/// and what Continue does. The composition is [LumeOnboardingScaffold]'s, the
/// rules are the model's, and the rendering is the view's. Swapping the fixture
/// adapter for a Dayroz provider changes the two `build` bodies here and
/// nothing else.
library;

import 'package:flutter/material.dart';

import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../data/country_fixture.dart';
import '../data/interests_fixture.dart';
import '../domain/country_picker_model.dart';
import '../domain/interests_model.dart';
import 'country_screen.dart';
import 'interests_screen.dart';
import 'onboarding_chrome.dart';

/// Which of the nine steps each of these is, so the progress bar is right.
///
/// The flow is Welcome · Plan · Tools · **Country** · City · **Interests** ·
/// Set up · Name · All set. F4A builds the two marked; the rest are F4B.
abstract final class LumeOnboardingStep {
  static const int welcome = 0;
  static const int plan = 1;
  static const int tools = 2;
  static const int country = 3;
  static const int city = 4;
  static const int interests = 5;
  static const int setUp = 6;
  static const int name = 7;
  static const int allSet = 8;
}

/// Step 4 — "Where are you based?"
class CountryStep extends StatefulWidget {
  const CountryStep({
    super.key,
    required this.countries,
    this.initialCountry = LumeCountryFixtureState.defaultCountry,
    this.recent = LumeCountryFixtureState.noRecent,
    this.onContinue,
    this.onBack,
    this.onSkip,
    this.controller,
  });

  final LumeCountryFixture countries;

  /// The draft opens on Pakistan, matching `app-store.js`.
  final String initialCountry;

  /// `profile.recentCountries`. Empty on a first run, which is why the Recent
  /// section is absent rather than empty.
  final List<String> recent;

  /// Given the chosen country code.
  final ValueChanged<String>? onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  /// Supplied by a test or a host that wants to drive the step.
  final LumeCountryPickerController? controller;

  @override
  State<CountryStep> createState() => _CountryStepState();
}

class _CountryStepState extends State<CountryStep> {
  late final LumeCountryPickerController _controller =
      widget.controller ??
      LumeCountryPickerController(selected: widget.initialCountry);
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String language = Localizations.localeOf(context).languageCode;

    final LumeCountryPickerModel model = LumeCountryPicker.build(
      all: widget.countries.forLanguage(language),
      popularOrder: widget.countries.popularOrder,
      selected: _controller.selected,
      query: _controller.query,
      recent: widget.recent,
      recentTitle: l.persRecent,
      popularTitle: l.persPopular,
      allTitle: l.persAllCountries,
      // `localeCompare(a, b, L.lang())`, precomputed — an Urdu list sorts by
      // Urdu collation, not by code point.
      allOrder: widget.countries.orderFor(language),
    );

    return LumeOnboardingScaffold(
      step: LumeOnboardingStep.country,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      backLabel: l.actionBack,
      skipLabel: l.actionSkip,
      stickyFoot: true,
      lead: LumeOnboardingLead(
        kicker: l.onbLocalKicker,
        title: l.onbWhereTitle,
        text: l.onbWhereText,
      ),
      action: LumeOnboardingContinue(
        label: l.actionContinue,
        onPressed: model.canContinue
            ? () => widget.onContinue?.call(_controller.selected)
            : null,
      ),
      child: LumeCountryPickerView(
        model: model,
        searchController: _search,
        searchPlaceholder: l.persSearchCountries,
        noResultsText: l.searchNothing,
        onSelect: (String code) => _controller.selected = code,
        onQueryChanged: (String q) => _controller.query = q,
      ),
    );
  }
}

/// Step 6 — "What are you here for?"
class InterestsStep extends StatefulWidget {
  const InterestsStep({
    super.key,
    required this.catalogue,
    this.initialSelection = const <String>{},
    this.initialFaithOpen,
    this.visibleFeatureInterests,
    this.onContinue,
    this.onBack,
    this.onSkip,
    this.controller,
  });

  final LumeInterestsFixture catalogue;

  /// A first run selects nothing. Coming back to the step restores what was
  /// chosen, which is what this is for.
  final Set<String> initialSelection;

  /// `null` infers it from the selection, exactly as `set(list, faith)` does.
  final bool? initialFaithOpen;

  /// The eligibility engine's answer, once there is one. Until then the
  /// fixture's own "referenced by some feature" set stands in.
  final Set<String>? visibleFeatureInterests;

  /// Given the chosen interests and whether the Islamic experience is on.
  final void Function(Set<String> interests, bool islamic)? onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  final LumeInterestsController? controller;

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  late final LumeInterestsController _controller =
      widget.controller ??
      LumeInterestsController(
        selected: widget.initialSelection,
        faithOpen: widget.initialFaithOpen,
        faithInterests: widget.catalogue.faithInterests,
      );

  /// The refusal message, shown where the reference shows a toast.
  LumeToastData? _toast;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _toggle(String id, AppLocalizations l) {
    final bool accepted = _controller.toggle(id);
    if (accepted) {
      if (_toast != null) setState(() => _toast = null);
      return;
    }
    setState(() {
      _toast = LumeToastData(
        message: l.onbAtCap(LumeInterests.maximum.toString()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    final List<LumeInterestGroup> groups = widget.catalogue.build(
      label: (String id) => interestLabel(l, id),
      groupLabel: (String id) => interestGroupLabel(l, id),
      visibleFeatureInterests: widget.visibleFeatureInterests,
    );
    final LumeInterestsModel model = _controller.model(groups);

    return Stack(
      children: <Widget>[
        LumeOnboardingScaffold(
          step: LumeOnboardingStep.interests,
          onBack: widget.onBack,
          onSkip: widget.onSkip,
          backLabel: l.actionBack,
          skipLabel: l.actionSkip,
          stickyFoot: true,
          // No `lead` here: the interests step scrolls as one piece, so its
          // copy is the first thing in the list rather than pinned above it.
          // See LumeInterestsView.header.
          action: LumeOnboardingContinue(
            label: l.actionContinue,
            onPressed: model.canContinue
                ? () => widget.onContinue?.call(model.selected, model.faithOpen)
                : null,
          ),
          child: LumeInterestsView(
            model: model,
            header: LumeOnboardingLead(
              kicker: l.onbYoursKicker,
              title: l.onbHereForTitle,
              text: l.onbHereForText,
              topPadding: LumeOnboardingMetrics.leadTopPicker,
            ),
            countLabel: model.meetsMinimum
                ? l.onbSelected(
                    model.count.toString(),
                    LumeInterests.maximum.toString(),
                  )
                : l.onbMinimum(
                    model.count.toString(),
                    LumeInterests.minimum.toString(),
                  ),
            clearLabel: l.actionClear,
            faithTitle: l.persIslamic,
            faithSubtitle: l.persIslamicSub,
            onToggle: (String id) => _toggle(id, l),
            onClear: _controller.clear,
            onFaithChanged: _controller.setFaithOpen,
          ),
        ),
        if (_toast != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 92 + MediaQuery.paddingOf(context).bottom,
            child: Align(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LumeToast(data: _toast!),
              ),
            ),
          ),
      ],
    );
  }
}

/// One interest's label. The only mapping from id to string.
String interestLabel(AppLocalizations l, String id) => switch (id) {
  'weather' => l.intWeather,
  'calendar' => l.intCalendar,
  'tasks' => l.intTasks,
  'notes' => l.intNotes,
  'convert' => l.intConvert,
  'maths' => l.intMaths,
  'alarms' => l.intAlarms,
  'expenses' => l.intExpenses,
  'rates' => l.intRates,
  'bills' => l.intBills,
  'savings' => l.intSavings,
  'markets' => l.intMarkets,
  'habits' => l.intHabits,
  'water' => l.intWater,
  'fitness' => l.intFitness,
  'meds' => l.intMeds,
  'sleep' => l.intSleep,
  'trains' => l.intTrains,
  'flights' => l.intFlights,
  'nearby' => l.intNearby,
  'fuel' => l.intFuel,
  'news' => l.intNews,
  'cricket' => l.intCricket,
  'reading' => l.intReading,
  'quotes' => l.intQuotes,
  'prayer' => l.intPrayer,
  'quran' => l.intQuran,
  'hadith' => l.intHadith,
  'duas' => l.intDuas,
  'zakat' => l.intZakat,
  'ramadan' => l.intRamadan,
  // A catalogue that grows without its ARB entry shows the id rather than a
  // blank chip, and `interests_catalogue_test.dart` fails before a user sees
  // one.
  _ => id,
};

/// One group's label.
String interestGroupLabel(AppLocalizations l, String id) => switch (id) {
  'everyday' => l.igEveryday,
  'money' => l.igMoney,
  'health' => l.igHealth,
  'travel' => l.igTravel,
  'news' => l.igNews,
  'faith' => l.igFaith,
  _ => id,
};
