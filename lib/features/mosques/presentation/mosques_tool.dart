/// Nearby Mosques — `tools/islamic/mosques.tool.js`, composed in the
/// reference's own order: the reader's city, a map of the mosques near it, a
/// search, a radius filter, the mosques within that radius, and Directions /
/// Suggest a mosque.
///
/// The four mosques are the reference's own sample list
/// (`mosques_fixtures.dart`), and the source line says "Sample data" over
/// them. Each row's next prayer is the reader's city's real schedule
/// (`prayer_schedule.dart`, shared with Prayer Times), as the reference reads
/// its own `prayerState()`.
///
/// Every control does what the reference's does: a row, Directions and
/// Suggest a mosque each say their line; the radius chips and the search
/// filter the list; the empty state widens the radius to 5 km. The city chip
/// opens the location picker — the reference's `sheet:personalise`, whose
/// first section is where the reader is.
///
/// **Dayroz:** a row opens that mosque (its address, facilities and jamaat
/// times); Directions hands the chosen mosque to the platform's maps app;
/// Suggest a mosque submits the reader's suggestion for review.
///
/// Faith-gated at the catalogue (`faith: true`); [LumeToolScreen] blocks a
/// non-Muslim reader's body before this build draws a row (§64).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_map.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/mosques_fixtures.dart';
import 'mosques_text.dart';

class LumeMosquesTool extends ConsumerStatefulWidget {
  const LumeMosquesTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeMosquesTool(request: request);

  static const String id = 'mosques';

  static const Key contextKey = ValueKey<String>('mosques.context');
  static const Key mapKey = ValueKey<String>('mosques.map');
  static const Key searchKey = ValueKey<String>('mosques.search');
  static const Key radiusKey = ValueKey<String>('mosques.radius');
  static const Key listKey = ValueKey<String>('mosques.list');
  static const Key emptyKey = ValueKey<String>('mosques.empty');
  static const Key directionsKey = ValueKey<String>('mosques.directions');
  static const Key suggestKey = ValueKey<String>('mosques.suggest');

  static Key radiusChip(int km) => ValueKey<String>('mosques.radius.$km');
  static Key row(LumeMosqueName name) =>
      ValueKey<String>('mosques.row.${name.name}');

  @override
  ConsumerState<LumeMosquesTool> createState() => _LumeMosquesToolState();
}

class _LumeMosquesToolState extends ConsumerState<LumeMosquesTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeMosquesTool.id, 'q') ?? '',
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  int get _radius =>
      int.tryParse(_session.read(LumeMosquesTool.id, 'radius') ?? '') ??
      LumeMosquesFixtures.defaultRadius;

  void _setRadius(int km) =>
      setState(() => _session.write(LumeMosquesTool.id, 'radius', '$km'));

  void _say(String message) =>
      _host.currentState?.say(message, tone: LumeToastTone.info);

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final String city = r.user.city;
    final int radius = _radius;

    // `set[next.index]` — the reader's city's next prayer, the same for every
    // row, as the reference's is. Missing where the city or its clock is
    // unknown: the row then shows no time rather than a guessed one.
    final DateTime now = LumeClockScope.of(context).now();
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    final LumeZoneResolution zone = ref
        .watch(timeZoneServiceProvider)
        .readerZone(
          startup.profile,
          ref.watch(deviceZoneProvider),
          country: r.user.country,
          city: city,
        );
    final (LumePrayerDay? day, LumePrayerMissing? _) = LumePrayerDay.at(
      now: now,
      country: r.user.country,
      city: city,
      zone: zone,
    );
    final LumePrayerSlot? next = day?.state(now).$1;

    String nameOf(LumeNearbyMosque m) => LumeMosquesText.name(l, m, city);
    final List<LumeNearbyMosque> shown = LumeMosquesFixtures.shown(
      radiusKm: radius,
      query: _query.text,
      nameOf: nameOf,
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumeMosquesTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(
                  label: city,
                  icon: LumeIcons.pin,
                  onTap: () => showLumeLocationPicker(context),
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeMap(
              key: LumeMosquesTool.mapKey,
              label: l.mosquesMap,
              caption: city,
              pins: <LumeMapPin>[
                for (int i = 0; i < LumeMosquesFixtures.all.length; i++)
                  LumeMapPin(
                    x: LumeMosquesFixtures.all[i].x,
                    y: LumeMosquesFixtures.all[i].y,
                    icon: LumeIcons.mosque,
                    label: nameOf(LumeMosquesFixtures.all[i]),
                    active: i == 0,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSearchField(
              key: LumeMosquesTool.searchKey,
              controller: _query,
              placeholder: l.mosquesSearch,
              onChanged: (String q) =>
                  setState(() => _session.write(LumeMosquesTool.id, 'q', q)),
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            flush: true,
            // `filterBar([{ id: 'radius', label: 'Within', … }])` — the group
            // is named for a screen reader, as the reference's `aria-label`.
            child: Semantics(
              container: true,
              label: l.mosquesRadius,
              child: LumeFilterBar(
                key: LumeMosquesTool.radiusKey,
                children: <Widget>[
                  for (final int km in LumeMosquesFixtures.radii)
                    LumeFilterChip(
                      key: LumeMosquesTool.radiusChip(km),
                      label: LumeMosquesText.distance(l, f, km),
                      selected: radius == km,
                      onTap: () => _setRadius(km),
                    ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            title: l.mosquesNearby,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeMosquesTool.emptyKey,
                    icon: LumeIcons.mosque,
                    title: l.mosquesNoneNear,
                    text: l.mosquesNoneNearText,
                    action: LumeButton(
                      label: LumeMosquesText.distance(l, f, 5),
                      icon: LumeIcons.navigation,
                      onPressed: () => _setRadius(5),
                    ),
                  )
                : LumeRows(
                    key: LumeMosquesTool.listKey,
                    children: <Widget>[
                      for (final LumeNearbyMosque m in shown)
                        LumeRichRow(
                          key: LumeMosquesTool.row(m.name),
                          icon: LumeIcons.mosque,
                          iconTone: lume.tintAccent,
                          iconInk: lume.accent,
                          title: nameOf(m),
                          subtitle: l.mosquesAddr(city),
                          meta: <String>[
                            LumeMosquesText.distance(l, f, m.km),
                            l.mosquesWalk(m.walkMinutes),
                            LumeMosquesText.facilities(l, m),
                          ],
                          value: next == null ? null : f.time(next.at),
                          valueSub: next == null
                              ? null
                              : LumeFeatureStrings.prayerName(l, next.key),
                          chevron: true,
                          // The reference's own toast. **Dayroz:** open
                          // this mosque.
                          onTap: () => _say(
                            '${nameOf(m)} · '
                            '${LumeMosquesText.distance(l, f, m.km)}',
                          ),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            child: LumeButtonRow(
              children: <Widget>[
                LumeButton.accent(
                  key: LumeMosquesTool.directionsKey,
                  label: l.mosquesDirections,
                  icon: LumeIcons.navigation,
                  // **Dayroz:** hand the chosen mosque to the maps app.
                  onPressed: () => _say(l.mosquesOpening),
                ),
                LumeButton(
                  key: LumeMosquesTool.suggestKey,
                  label: l.mosquesAddYours,
                  icon: LumeIcons.plus,
                  // **Dayroz:** submit the suggestion for review.
                  onPressed: () => _say(l.mosquesSuggest),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
