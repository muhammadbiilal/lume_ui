/// The personalisation editors.
///
/// [showLumePersonalise] is `sheet:personalise` — the reference's one tall
/// sheet: where you are, language and formatting, content, and your
/// interests, with Save preferences. Every entry point the reference has
/// opens it: Profile's Interests row, Tools' header, search, and each tool's
/// place chip.
///
/// [showLumeLocationPicker] is the country-then-city picker, opened by the
/// sheet's Country and City rows and by Account → Region.
///
/// Both write through [LumeStartupController.profileChanged], which is the one
/// place the profile is stored — so changing a country re-renders Home and
/// the tab set in the same frame, and **nothing is deleted while it
/// happens** (§37).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/locale_provider.dart';
import '../../../app/providers/personalisation.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_locales.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_settings.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../catalogue/data/feature_catalogue.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import 'account_parts.dart';
import '../../../app/providers/platform_services.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/application/use_location.dart';
import '../../onboarding/data/country_fixture.dart';
import '../../onboarding/data/interests_fixture.dart';
import '../../onboarding/domain/city_picker_model.dart';
import '../../onboarding/domain/country_picker_model.dart';
import '../../onboarding/domain/interests_model.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../onboarding/presentation/city_screen.dart';
import '../../onboarding/presentation/country_screen.dart';
import '../../onboarding/presentation/interests_screen.dart';
import '../../onboarding/presentation/onboarding_steps.dart';
import '../../startup/application/startup_controller.dart';

/// The interests picker, over whatever screen asked for it.
Future<void> showLumePersonalise(BuildContext context) => showLumeSheet<void>(
  context: context,
  barrierLabel: AppLocalizations.of(context).persTitle,
  child: const _PersonaliseSheet(),
);

/// Country, and then the cities in it.
Future<void> showLumeLocationPicker(BuildContext context) =>
    showLumeSheet<void>(
      context: context,
      barrierLabel: AppLocalizations.of(context).persWhereYouAre,
      child: const _LocationSheet(),
    );

// ---------------------------------------------------------------- interests

class _PersonaliseSheet extends ConsumerStatefulWidget {
  const _PersonaliseSheet();

  @override
  ConsumerState<_PersonaliseSheet> createState() => _PersonaliseSheetState();
}

/// `#sheet-personalise` — the reference's one tall sheet, in its order:
/// where you are, language and formatting, content, your interests, and
/// Save preferences.
///
/// What is held and what is written, as the reference's `pickers.js` has it:
///
/// * **Drafted until Save** — the interests, the Islamic experience, units,
///   currency and the time format. Save is disabled until the minimum of
///   interests is picked, writes them all at once, closes the sheet and says
///   "Your app has been updated". Closing without Save keeps nothing.
/// * **Written at once** — the content switches (`data-pref`, handled by the
///   shell the moment one is pressed) and the language, which the reference
///   also applies immediately because it is the one setting nobody can judge
///   without seeing it.
/// * **Where you are** — the Country and City rows open the location picker,
///   which saves the place it is given (the reference edits it inline, in the
///   same draft; here it is its own sheet, the one Account → Region opens).
class _PersonaliseSheetState extends ConsumerState<_PersonaliseSheet> {
  late final LumeStartupController _gate = ref.read(startupControllerProvider);
  late final LumeProfileRecord _start = _gate.state.profile;
  late final LumeInterestsController _picks = LumeInterestsController(
    // Growable: the load below adds the catalogue's faith interests to it. A
    // `const` set here made that throw, the future fail, and the sheet spin
    // forever without ever drawing an interest.
    faithInterests: <String>{},
  );
  Future<LumeInterestsFixture>? _catalogue;

  late LumeUnitsPreference _units = _start.units;
  late String _currency = _start.currency;
  late String _clock = _start.clock;

  /// The refusal at the cap, shown where the reference shows a toast.
  LumeToastData? _toast;

  @override
  void initState() {
    super.initState();
    _catalogue = LumeInterestsFixture.load().then((
      LumeInterestsFixture fixture,
    ) {
      _picks
        ..faithInterests.addAll(fixture.faithInterests)
        ..restore(_start.interests.toSet(), faithOpen: _start.islamic ?? false);
      return fixture;
    });
  }

  @override
  void dispose() {
    _picks.dispose();
    super.dispose();
  }

  /// `cycle(list, current)` — small option sets do not deserve a sheet.
  static T _next<T>(List<T> list, T current) {
    final int at = list.indexOf(current);
    return list[(at + 1) % list.length];
  }

  void _toggle(String id, AppLocalizations l) {
    if (_picks.toggle(id)) {
      if (_toast != null) setState(() => _toast = null);
      return;
    }
    setState(
      () => _toast = LumeToastData(
        message: l.onbAtCap(LumeInterests.maximum.toString()),
      ),
    );
  }

  void _setContent(LumeContentPrefs prefs) {
    final LumeProfileRecord p = _gate.state.profile;
    _gate.profileChanged(p.copyWith(prefs: prefs));
  }

  void _save(AppLocalizations l) {
    final LumeProfileRecord p = _gate.state.profile;
    _gate.profileChanged(
      p.copyWith(
        interests: _picks.selected.toList(growable: false),
        islamic: _picks.faithOpen,
        units: _units,
        currency: _currency,
        clock: _clock,
      ),
    );
    // Raised from the sheet's own context, so it lands in the root overlay
    // the sheet sits in, and stays up once the sheet has closed.
    showLumeToast(context, LumeToastData(message: l.persSaved));
    Navigator.of(context).maybePop();
  }

  String _unitsLabel(AppLocalizations l) => switch (_units) {
    LumeUnitsPreference.auto => l.persUnitsAuto,
    LumeUnitsPreference.metric => l.persUnitsMetric,
    LumeUnitsPreference.imperial => l.persUnitsImperial,
  };

  String _clockLabel(AppLocalizations l) => switch (_clock) {
    '12' => l.persTime12,
    '24' => l.persTime24,
    _ => l.persUnitsAuto,
  };

  /// The interests some feature visible in the reader's country offers —
  /// `pickers.js` drops the rest. Asked with the Islamic experience on so
  /// the faith interests stay; the faith card is what governs those.
  Set<String> _visibleInterests(LumeProfileRecord p) {
    final LumeEligibility eligibility = ref.read(eligibilityProvider);
    final LumeUserContext asked = LumeUserContext(
      country: p.country,
      city: p.city,
      islamic: true,
    );
    return <String>{
      for (final LumeFeature f in kLumeFeatures)
        if (eligibility.isVisible(f, asked)) ...f.interests,
    };
  }

  Widget _header(AppLocalizations l, LumeProfileRecord p, String language) {
    final LumeCountryFixture? countries = _gate.state.countries;
    final String countryCurrency = countries?.currencyOf(p.country) ?? '';
    // `['auto', 'USD', 'EUR', 'GBP', <the country's>]`, each once.
    final List<String> currencies = <String>{
      LumePreference.auto,
      for (final String c in <String>['USD', 'EUR', 'GBP', countryCurrency])
        if (c.isNotEmpty) c,
    }.toList();
    final LumeContentPrefs prefs = p.prefs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LumeSettingsGroupLabel(l.persWhereYouAre),
        const SizedBox(height: 9),
        // §124.17 — say what changing this changes, where it changes.
        LumeNoteCard(
          tone: LumeNoteTone.warn,
          icon: LumeIcons.alert,
          title: l.acctRegionTitle,
          text: l.acctRegionWarn,
        ),
        const SizedBox(height: 12),
        LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              key: LumePersonaliseKeys.country,
              icon: LumeIcons.globe,
              title: l.persCountry,
              subtitle: l.persCountrySub,
              value: countries?.nameOf(p.country, language) ?? p.country,
              onTap: () => showLumeLocationPicker(context),
            ),
            if (p.region.isNotEmpty)
              LumeSettingsRow(
                icon: LumeIcons.pin,
                title: l.persRegion,
                value: p.region,
                chevron: false,
              ),
            LumeSettingsRow(
              key: LumePersonaliseKeys.city,
              icon: LumeIcons.pin,
              title: l.persCity,
              subtitle: l.persCitySub,
              value: p.city,
              onTap: () => showLumeLocationPicker(context),
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 22),
        LumeSettingsGroupLabel(l.persFormatting),
        const SizedBox(height: 9),
        LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              key: LumePersonaliseKeys.language,
              icon: LumeIcons.globe,
              title: l.persAppLanguage,
              value: LumeLocales.forCode(language).native,
              onTap: () {
                final List<String> codes = <String>[
                  for (final LumeLanguage x in LumeLocales.all) x.code,
                ];
                ref.read(localeProvider.notifier).state = Locale(
                  _next(codes, language),
                );
              },
            ),
            LumeSettingsRow(
              key: LumePersonaliseKeys.units,
              icon: LumeIcons.ruler,
              title: l.persUnits,
              value: _unitsLabel(l),
              onTap: () => setState(
                () => _units = _next(LumeUnitsPreference.values, _units),
              ),
            ),
            LumeSettingsRow(
              key: LumePersonaliseKeys.currency,
              icon: LumeIcons.currency,
              title: l.persCurrency,
              value: _currency == LumePreference.auto
                  ? l.persCurrencyAuto(countryCurrency)
                  : _currency,
              onTap: () =>
                  setState(() => _currency = _next(currencies, _currency)),
            ),
            LumeSettingsRow(
              key: LumePersonaliseKeys.clock,
              icon: LumeIcons.clock,
              title: l.persTimeFormat,
              value: _clockLabel(l),
              onTap: () => setState(
                () => _clock = _next(<String>[
                  LumePreference.auto,
                  '12',
                  '24',
                ], _clock),
              ),
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 22),
        LumeSettingsGroupLabel(l.persContent),
        const SizedBox(height: 9),
        LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              key: LumePersonaliseKeys.islamic,
              icon: LumeIcons.moonStar,
              accent: _picks.faithOpen,
              title: l.persIslamic,
              subtitle: l.persIslamicSub,
              toggle: _picks.faithOpen,
              onTap: () => _picks.setFaithOpen(!_picks.faithOpen),
            ),
            LumeSettingsRow(
              key: LumePersonaliseKeys.news,
              icon: LumeIcons.news,
              title: l.persNews,
              subtitle: l.persNewsSub,
              toggle: prefs.news,
              onTap: () => _setContent(prefs.copyWith(news: !prefs.news)),
            ),
            LumeSettingsRow(
              key: LumePersonaliseKeys.sport,
              icon: LumeIcons.cricket,
              title: l.persSport,
              subtitle: l.persSportSub,
              toggle: prefs.cricket,
              onTap: () => _setContent(prefs.copyWith(cricket: !prefs.cricket)),
            ),
            LumeSettingsRow(
              key: LumePersonaliseKeys.finance,
              icon: LumeIcons.trending,
              title: l.persFinance,
              subtitle: l.persFinanceSub,
              toggle: prefs.finance,
              onTap: () => _setContent(prefs.copyWith(finance: !prefs.finance)),
            ),
            LumeSettingsRow(
              key: LumePersonaliseKeys.recos,
              icon: LumeIcons.sparkles,
              title: l.persRecos,
              subtitle: l.persRecosSub,
              toggle: prefs.recommendations,
              onTap: () => _setContent(
                prefs.copyWith(recommendations: !prefs.recommendations),
              ),
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 22),
        LumeSettingsGroupLabel(l.persInterests),
        const SizedBox(height: 4),
        Text(
          l.persInterestsHint(LumeInterests.minimum),
          style: LumeType.natural(
            context,
            context.lumeType.meta,
          ).copyWith(color: context.lume.text2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String language = Localizations.localeOf(context).languageCode;
    // Watched, so a place chosen in the location picker, or a content switch,
    // is drawn here as soon as it is saved.
    final LumeProfileRecord p = ref
        .watch(startupControllerProvider)
        .state
        .profile;
    return Stack(
      children: <Widget>[
        LumeSheet(
          title: l.persTitle,
          subtitle: l.persSub,
          tall: true,
          closeLabel: l.actionClose,
          onClose: () => Navigator.of(context).maybePop(),
          child: FutureBuilder<LumeInterestsFixture>(
            future: _catalogue,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<LumeInterestsFixture> snapshot,
                ) {
                  final LumeInterestsFixture? fixture = snapshot.data;
                  if (fixture == null) {
                    return const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return ListenableBuilder(
                    listenable: _picks,
                    builder: (BuildContext context, Widget? _) {
                      final LumeInterestsModel model = _picks.model(
                        fixture.build(
                          label: (String id) => interestLabel(l, id),
                          groupLabel: (String id) => interestGroupLabel(l, id),
                          visibleFeatureInterests: _visibleInterests(p),
                        ),
                      );
                      return LumeInterestsView(
                        model: model,
                        header: _header(l, p, language),
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
                        onClear: _picks.clear,
                        onFaithChanged: _picks.setFaithOpen,
                        footer: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                l.persDataSafe,
                                style: LumeType.natural(
                                  context,
                                  context.lumeType.meta,
                                ).copyWith(color: context.lume.text2),
                              ),
                              const SizedBox(height: 16),
                              LumeButtonRow(
                                children: <Widget>[
                                  LumeButton.accent(
                                    key: LumePersonaliseKeys.save,
                                    label: l.persSavePrefs,
                                    block: true,
                                    onPressed: model.meetsMinimum
                                        ? () => _save(l)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
          ),
        ),
        if (_toast != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
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

/// The Personalisation sheet's rows and Save, for a test to find.
abstract final class LumePersonaliseKeys {
  static const Key country = ValueKey<String>('pers.country');
  static const Key city = ValueKey<String>('pers.city');
  static const Key language = ValueKey<String>('pers.language');
  static const Key units = ValueKey<String>('pers.units');
  static const Key currency = ValueKey<String>('pers.currency');
  static const Key clock = ValueKey<String>('pers.clock');
  static const Key islamic = ValueKey<String>('pers.islamic');
  static const Key news = ValueKey<String>('pers.news');
  static const Key sport = ValueKey<String>('pers.sport');
  static const Key finance = ValueKey<String>('pers.finance');
  static const Key recos = ValueKey<String>('pers.recos');
  static const Key save = ValueKey<String>('pers.save');
}

// ----------------------------------------------------------------- location

class _LocationSheet extends ConsumerStatefulWidget {
  const _LocationSheet();

  @override
  ConsumerState<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<_LocationSheet> {
  late final LumeStartupController _gate = ref.read(startupControllerProvider);
  final TextEditingController _search = TextEditingController();

  /// Country first, then the cities in it. Two steps in one sheet, because
  /// choosing a country without choosing a city leaves the weather, the
  /// prayer times and the local services pointing at nothing.
  bool _pickingCity = false;
  late String _country = _gate.state.profile.country;
  String _query = '';

  /// "Use my current location" — reading, and why it last found nothing.
  bool _locating = false;
  String? _locationNote;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _chooseCountry(String code) {
    setState(() {
      _country = code;
      _pickingCity = true;
      _query = '';
      _search.clear();
    });
  }

  void _chooseCity(String city, String? region) {
    final LumeProfileRecord p = _gate.state.profile;
    // §37 — a change of country changes which local services apply. It does
    // not delete a note, a task, an expense or a favourite, and nothing here
    // touches any of them.
    _gate.profileChanged(
      p.copyWith(country: _country, city: city, region: region ?? ''),
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  /// One position, turned into the nearest city the picker lists. Here, as
  /// with a tapped city, the place found is saved and the sheet closes; the
  /// Region screen then shows it, and choosing by hand stays one tap away.
  Future<void> _useLocation(LumeCountryFixture table) async {
    if (_locating) return;
    final AppLocalizations l = AppLocalizations.of(context);
    setState(() {
      _locating = true;
      _locationNote = null;
    });
    final LumeUseLocationResult found = await LumeUseLocation.resolve(
      locator: ref.read(locatorProvider),
      countries: table,
    );
    if (!mounted) return;
    final String? country = found.country;
    final String? city = found.city;
    if (country != null && city != null) {
      _country = country;
      _chooseCity(city, found.region);
      return;
    }
    setState(() {
      _locating = false;
      _locationNote = found.message(l);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String language = Localizations.localeOf(context).languageCode;
    final LumeCountryFixture? table = _gate.state.countries;

    if (table == null) {
      return LumeSheet(
        title: l.persWhereYouAre,
        closeLabel: l.actionClose,
        onClose: () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.toolErrorText),
        ),
      );
    }

    if (!_pickingCity) {
      return LumeSheet(
        title: l.persCountry,
        closeLabel: l.actionClose,
        onClose: () => Navigator.of(context).maybePop(),
        child: LumeCountryPickerView(
          model: LumeCountryPicker.build(
            all: table.forLanguage(language),
            popularOrder: table.popularOrder,
            allOrder: table.orderFor(language),
            recent: const <String>[],
            selected: _country,
            query: _query,
            recentTitle: l.persRecent,
            popularTitle: l.persPopular,
            allTitle: l.persAllCountries,
          ),
          onSelect: _chooseCountry,
          onQueryChanged: (String q) => setState(() => _query = q),
          searchPlaceholder: l.persSearchCountries,
          noResultsText: l.searchNothing,
          searchController: _search,
        ),
      );
    }

    final LumePlaces places = table.placesOf(_country);
    return LumeSheet(
      title: l.persCity,
      closeLabel: l.actionClose,
      onClose: () => Navigator.of(context).maybePop(),
      child: LumeCityPickerView(
        model: LumeCityPicker.build(
          countryName: table.nameOf(_country, language) ?? _country,
          cities: places.cities,
          regions: places.regions,
          selected: _gate.state.profile.city,
          query: _query,
        ),
        onSelect: _chooseCity,
        onQueryChanged: (String q) => setState(() => _query = q),
        searchPlaceholder: l.persSearchCities,
        noResultsText: l.searchNothing,
        useLocationLabel: _locating ? l.persLocating : l.persUseLocation,
        onUseLocation: _locating ? null : () => _useLocation(table),
        useLocationNote: _locationNote,
        searchController: _search,
      ),
    );
  }
}
