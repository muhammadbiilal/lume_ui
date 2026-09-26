/// The two personalisation editors the account section opens.
///
/// `sheet:personalise` in the reference is one tall sheet holding location,
/// language, units, currency, time, interests and the content switches. Six of
/// those seven now have a route of their own in the account section, and a
/// second copy of the language picker would be a second answer to the same
/// question — so the sheet is split into the two editors its two entry points
/// are actually about:
///
/// | entry point | opens |
/// |---|---|
/// | Profile's Interests row | [showLumePersonalise] — the interests picker |
/// | the Region route's Change button | [showLumeLocationPicker] — country, then city |
///
/// Recorded as D41. Neither is a route: the reference opens a sheet from both
/// places, and a sheet has no address.
///
/// Both write through [LumeStartupController.profileChanged], which is the one
/// place the profile is stored — so changing a country here re-renders Home
/// and the tab set in the same frame, and **nothing is deleted while it
/// happens**.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _PersonaliseSheetState extends ConsumerState<_PersonaliseSheet> {
  late final LumeStartupController _gate = ref.read(startupControllerProvider);
  // Growable: the load below adds the catalogue's faith interests to it. A
  // `const` set here made that throw, the future fail, and the sheet spin
  // forever without ever drawing an interest.
  late final LumeInterestsController _picks = LumeInterestsController(
    faithInterests: <String>{},
  );
  Future<LumeInterestsFixture>? _catalogue;

  @override
  void initState() {
    super.initState();
    _catalogue = LumeInterestsFixture.load().then((
      LumeInterestsFixture fixture,
    ) {
      final LumeProfileRecord p = _gate.state.profile;
      _picks
        ..faithInterests.addAll(fixture.faithInterests)
        ..restore(p.interests.toSet(), faithOpen: p.islamic ?? false);
      return fixture;
    });
  }

  @override
  void dispose() {
    _picks.dispose();
    super.dispose();
  }

  /// Written on every change rather than on a Save button.
  ///
  /// The reference's sheet has no Save: a switch is the commit. Holding the
  /// edit until a button would mean a reader who closed the sheet lost a
  /// choice they had already watched take effect.
  void _commit() {
    final LumeProfileRecord p = _gate.state.profile;
    _gate.profileChanged(
      p.copyWith(
        interests: _picks.selected.toList(growable: false),
        islamic: _picks.faithOpen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeSheet(
      title: l.persTitle,
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
                    ),
                  );
                  return LumeInterestsView(
                    model: model,
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
                    onToggle: (String id) {
                      _picks.toggle(id);
                      _commit();
                    },
                    onClear: () {
                      _picks.clear();
                      _commit();
                    },
                    onFaithChanged: (bool on) {
                      _picks.setFaithOpen(on);
                      _commit();
                    },
                  );
                },
              );
            },
      ),
    );
  }
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
