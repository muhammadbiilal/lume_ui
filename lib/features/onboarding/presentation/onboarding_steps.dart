/// The five steps that collect something: country, city, interests, the two
/// permissions, and the name.
///
/// Each owns three things and no more — its controller, its localisations, and
/// what Continue does. The composition is [LumeOnboardingScaffold]'s, the rules
/// are the model's, and the rendering is the view's. Swapping a fixture adapter
/// for a Dayroz provider changes a `build` body here and nothing else.
///
/// The four that only tell you something are in `onboarding_slides.dart`.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../domain/city_picker_model.dart';
import '../domain/onboarding_state.dart';
import 'city_screen.dart';
import 'onboarding_art.dart';
import 'onboarding_parts.dart';

import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../data/country_fixture.dart';
import '../data/interests_fixture.dart';
import '../domain/country_picker_model.dart';
import '../domain/interests_model.dart';
import 'country_screen.dart';
import 'interests_screen.dart';
import 'onboarding_chrome.dart';

/// The step indices live in the domain, next to the state machine that uses
/// them, and are re-exported here so a step widget has one import.
export '../domain/onboarding_steps_ids.dart';

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

    // A surface too short to pin a lead and a search field above a list hands
    // both to the list instead, and everything above the footer scrolls as one
    // piece. `LumeCountryPickerView.pinHead` carries the measurement.
    final bool foldLead = context.isCompactHeight;
    final Widget lead = LumeOnboardingLead(
      kicker: l.onbLocalKicker,
      title: l.onbWhereTitle,
      text: l.onbWhereText,
    );

    return LumeOnboardingScaffold(
      step: LumeOnboardingStep.country,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      backLabel: l.actionBack,
      skipLabel: l.actionSkip,
      stickyFoot: true,
      lead: foldLead ? null : lead,
      action: LumeOnboardingContinue(
        label: l.actionContinue,
        onPressed: model.canContinue
            ? () => widget.onContinue?.call(_controller.selected)
            : null,
      ),
      child: LumeCountryPickerView(
        model: model,
        pinHead: !foldLead,
        header: foldLead ? lead : null,
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

/// Step 4 — Which city are you in?
class CityStep extends StatefulWidget {
  const CityStep({
    super.key,
    required this.countries,
    required this.country,
    required this.initialCity,
    this.initialRegion,
    this.onContinue,
    this.onBack,
    this.onSkip,
    this.onUseLocation,
    this.locating = false,
    this.locationNote,
    this.controller,
  });

  final LumeCountryFixture countries;

  /// The country chosen on the previous step. The kicker is its localised
  /// name, and its cities are the list.
  final String country;

  final String initialCity;
  final String? initialRegion;

  /// Given the city and its region.
  final void Function(String city, String? region)? onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  /// Asks for one position; the permission request is the platform's, at
  /// the moment it is needed. `null` leaves the offer visible and inert.
  final VoidCallback? onUseLocation;

  /// While one position is being read: the row says so and cannot be pressed
  /// again.
  final bool locating;

  /// Why the last attempt found nothing, if it did not.
  final String? locationNote;

  final LumeCityPickerController? controller;

  @override
  State<CityStep> createState() => _CityStepState();
}

class _CityStepState extends State<CityStep> {
  late final LumeCityPickerController _controller =
      widget.controller ??
      LumeCityPickerController(
        selected: widget.initialCity,
        region: widget.initialRegion,
      );
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    if (widget.controller == null) _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String language = Localizations.localeOf(context).languageCode;
    final LumePlaces places = widget.countries.placesOf(widget.country);

    final LumeCityPickerModel model = LumeCityPicker.build(
      regions: places.regions,
      cities: places.cities,
      selected: _controller.selected,
      query: _controller.query,
      countryName: widget.countries
          .forLanguage(language)
          .firstWhere(
            (LumeCountry c) => c.code == widget.country,
            orElse: () => LumeCountry(
              code: widget.country,
              name: widget.country,
              currency: '',
            ),
          )
          .name,
    );

    // A surface too short to pin a lead and a search field above a list hands
    // both to the list instead. See `LumeCountryPickerView.pinHead`.
    final bool foldLead = context.isCompactHeight;
    final Widget lead = LumeOnboardingLead(
      // The kicker is the country's name, not a fixed word — which is how the
      // step says "still you, still here" without a sentence.
      kicker: model.countryName,
      title: l.onbCityTitle,
      text: l.onbCityText,
    );

    return LumeOnboardingScaffold(
      step: LumeOnboardingStep.city,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      backLabel: l.actionBack,
      skipLabel: l.actionSkip,
      stickyFoot: true,
      lead: foldLead ? null : lead,
      action: LumeOnboardingContinue(
        label: l.actionContinue,
        onPressed: () =>
            widget.onContinue?.call(_controller.selected, _controller.region),
      ),
      child: LumeCityPickerView(
        model: model,
        pinHead: !foldLead,
        header: foldLead ? lead : null,
        searchController: _search,
        searchPlaceholder: l.persSearchCities,
        noResultsText: l.searchNothing,
        useLocationLabel: widget.locating ? l.persLocating : l.persUseLocation,
        onUseLocation: widget.locating ? null : widget.onUseLocation,
        useLocationNote: widget.locationNote,
        onSelect: _controller.choose,
        onQueryChanged: (String q) => _controller.query = q,
      ),
    );
  }
}

/// Step 6 — Set it up once.
class SetUpStep extends StatelessWidget {
  const SetUpStep({
    super.key,
    required this.draft,
    required this.onChanged,
    this.onContinue,
    this.onBack,
    this.onSkip,
  });

  /// Holds the two permission intents and the prayer method.
  final LumeOnboardingDraft draft;
  final ValueChanged<LumeOnboardingDraft> onChanged;

  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeOnboardingScaffold(
      step: LumeOnboardingStep.setUp,
      onBack: onBack,
      onSkip: onSkip,
      backLabel: l.actionBack,
      skipLabel: l.actionSkip,
      action: LumeOnboardingContinue(
        label: l.actionLooksGood,
        onPressed: onContinue,
      ),
      secondaryAction: <Widget>[LumeOnboardingNote(text: l.onbOnDevice)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // `flex: 0 0 auto; min-height: 0` — this stage does not grow, so it
          // stays inside the step's own column rather than taking the slot.
          const LumeOnboardingArt.compact(
            artwork: LumeOnboardingArtwork.setUp,
            maxWidth: 242,
            padding: EdgeInsets.only(top: 2, bottom: 10),
          ),
          LumeOnboardingLead(
            title: l.onbSetupTitle,
            text: l.onbSetupText,
            topPadding: 0,
          ),
          const SizedBox(height: LumeOnboardingPartMetrics.rowsTop),
          Column(
            key: LumeOnboardingKeys.rows,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeOnboardingToggleRow(
                icon: LumeIcons.pin,
                title: l.onbPermLocation,
                // Both subtitles change with the faith preference chosen two
                // steps earlier.
                subtitle: draft.islamic
                    ? l.onbPermLocationSubFaith
                    : l.onbPermLocationSub,
                value: draft.wantsLocation,
                onChanged: (bool v) =>
                    onChanged(draft.copyWith(wantsLocation: v)),
              ),
              const SizedBox(height: LumeOnboardingPartMetrics.rowsGap),
              LumeOnboardingToggleRow(
                icon: LumeIcons.bellRing,
                title: l.onbPermNotify,
                subtitle: draft.islamic
                    ? l.onbPermNotifySubFaith
                    : l.onbPermNotifySub,
                value: draft.wantsReminders,
                onChanged: (bool v) =>
                    onChanged(draft.copyWith(wantsReminders: v)),
              ),
            ],
          ),
          // §64 again, on a slide: the method block does not exist for someone
          // who did not ask for the Islamic experience. Not hidden — absent.
          if (draft.islamic)
            LumeOnboardingChoice(
              label: l.onbMethodLabel,
              options: <LumeChoiceOption>[
                for (final LumeChoiceOptionData o
                    in LumePrayerMethod.optionsFor(l))
                  LumeChoiceOption(id: o.id, label: o.label),
              ],
              value: draft.method,
              onChanged: (String id) => onChanged(draft.copyWith(method: id)),
            ),
        ],
      ),
    );
  }
}

/// Step 7 — What should we call you?
class NameStep extends StatefulWidget {
  const NameStep({
    super.key,
    this.initialName = '',
    this.onContinue,
    this.onSkipStep,
    this.onBack,
    this.onSkip,
  });

  /// Prefilled from whatever Lume already holds — the account's name for a
  /// signed-in user, the device's for a guest.
  final String initialName;

  /// Given the trimmed name. Called only when it differs from [initialName]:
  /// an untouched field is not an instruction to erase anything.
  final ValueChanged<String>? onContinue;

  /// The step's own "Skip for now": advance **without writing**. §124.4 —
  /// skipping is a first-class outcome, not a deletion.
  final VoidCallback? onSkipStep;

  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late final TextEditingController _field = TextEditingController(
    text: widget.initialName,
  );

  /// `maxlength="40"`, the same cap `commitName` applies — enforced where the
  /// user can see it rather than only where it is saved.
  void _capLength() {
    if (_field.text.length <= LumeOnboardingState.nameMaxLength) return;
    final String capped = _field.text.substring(
      0,
      LumeOnboardingState.nameMaxLength,
    );
    _field.value = TextEditingValue(
      text: capped,
      selection: TextSelection.collapsed(offset: capped.length),
    );
  }

  @override
  void initState() {
    super.initState();
    _field.addListener(_capLength);
  }

  @override
  void dispose() {
    _field.removeListener(_capLength);
    _field.dispose();
    super.dispose();
  }

  void _continue() {
    final String typed = _field.text.trim();
    if (typed != widget.initialName.trim()) {
      widget.onContinue?.call(typed);
    } else {
      widget.onSkipStep?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeOnboardingScaffold(
      step: LumeOnboardingStep.name,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      backLabel: l.actionBack,
      skipLabel: l.actionSkip,
      action: LumeOnboardingContinue(
        label: l.actionContinue,
        onPressed: _continue,
      ),
      // `.onb__foot` is a grid with one gap, so the link and the note are two
      // of its rows rather than a column nested in one.
      secondaryAction: <Widget>[
        LumeOnboardingLink(label: l.onbNameSkip, onPressed: widget.onSkipStep),
        LumeOnboardingNote(text: l.onbNameNote),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const LumeOnboardingArt.compact(
            artwork: LumeOnboardingArtwork.name,
            maxWidth: 250,
            padding: EdgeInsets.only(top: 6, bottom: 4),
          ),
          LumeOnboardingLead(
            kicker: l.onbNameKicker,
            title: l.onbNameTitle,
            text: l.onbNameText,
            topPadding: 0,
          ),
          const SizedBox(height: LumeOnboardingPartMetrics.nameFieldTop),
          // `<label class="field field--wide">` — a `.field`, not a `.cfield`,
          // with `.onb__namefield`'s own box: `padding: 14px 16px;
          // border-radius: var(--r-md)`.
          LumeToolField(
            label: l.onbNameLabel,
            placeholder: l.onbNamePlaceholder,
            controller: _field,
            wide: true,
            boxPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            boxRadius: LumeRadius.brMd,
            // `.onb__namefield .field__box input { font-size: 16px }`, on a
            // 23-point line box — which is what makes the box 53 rather than
            // the 42 a tool field draws.
            inputStyle: const TextStyle(fontSize: 16, height: 23 / 16),
          ),
        ],
      ),
    );
  }
}
