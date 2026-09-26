/// Taraweeh — `tools/islamic/taraweeh.tool.js`, the reference's mosque
/// finder for the Ramadan nights, in its order: the city and the season, a
/// search, the rakaat filter, the map, the mosques, the closest one's
/// figures, and the reminder note.
///
/// The mosques are Nearby Mosques' own sample list (`mosques_fixtures.dart`,
/// the reference's shared `nearbyMosques()`), each with its reciter, its
/// rakaat and its Taraweeh time; the source line says "Sample data". A row
/// says the mosque's name, as the reference's `toast:<name>` does. The city
/// chip opens Personalisation (`sheet:personalise`).
///
/// **Dayroz:** a row opens that mosque's Ramadan schedule; the reminder note
/// becomes the switch that schedules a notification twenty minutes before
/// Taraweeh at the reader's chosen mosque.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_map.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../mosques/data/mosques_fixtures.dart';
import '../../mosques/presentation/mosques_text.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';

class LumeTaraweehTool extends ConsumerStatefulWidget {
  const LumeTaraweehTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeTaraweehTool(request: request);

  static const String id = 'taraweeh';

  static const Key contextKey = ValueKey<String>('taraweeh.context');
  static const Key searchKey = ValueKey<String>('taraweeh.search');
  static const Key rakaatKey = ValueKey<String>('taraweeh.rakaat');
  static const Key mapKey = ValueKey<String>('taraweeh.map');
  static const Key listKey = ValueKey<String>('taraweeh.list');
  static const Key emptyKey = ValueKey<String>('taraweeh.empty');
  static const Key closestKey = ValueKey<String>('taraweeh.closest');
  static const Key remindKey = ValueKey<String>('taraweeh.remind');

  /// `all`, `8` or `20`.
  static Key rakaatChip(String value) =>
      ValueKey<String>('taraweeh.rakaat.$value');
  static Key row(LumeMosqueName name) =>
      ValueKey<String>('taraweeh.row.${name.name}');

  @override
  ConsumerState<LumeTaraweehTool> createState() => _LumeTaraweehToolState();
}

class _LumeTaraweehToolState extends ConsumerState<LumeTaraweehTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeTaraweehTool.id, 'q') ?? '',
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String get _rakaat => _session.read(LumeTaraweehTool.id, 'rakaat') ?? 'all';

  void _setRakaat(String v) =>
      setState(() => _session.write(LumeTaraweehTool.id, 'rakaat', v));

  /// A time of day as a `DateTime`, for the formatter.
  static DateTime _at(int minute) =>
      DateTime(2026, 1, 1, minute ~/ 60, minute % 60);

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
    final String rakaat = _rakaat;
    final String q = _query.text.trim().toLowerCase();

    String nameOf(LumeNearbyMosque m) => LumeMosquesText.name(l, m, city);
    final List<LumeNearbyMosque> shown = <LumeNearbyMosque>[
      for (final LumeNearbyMosque m in LumeMosquesFixtures.all)
        if ((rakaat == 'all' || '${m.rakaat}' == rakaat) &&
            (q.isEmpty || nameOf(m).toLowerCase().contains(q)))
          m,
    ];
    final LumeNearbyMosque? closest = shown.isEmpty ? null : shown.first;

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
              key: LumeTaraweehTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(
                  label: city,
                  icon: LumeIcons.pin,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: l.taraweehSeason),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSearchField(
              key: LumeTaraweehTool.searchKey,
              controller: _query,
              placeholder: l.taraweehSearch,
              onChanged: (String v) =>
                  setState(() => _session.write(LumeTaraweehTool.id, 'q', v)),
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            flush: true,
            child: Semantics(
              container: true,
              label: l.taraweehRakaat,
              child: LumeFilterBar(
                key: LumeTaraweehTool.rakaatKey,
                children: <Widget>[
                  for (final String v in <String>['all', '8', '20'])
                    LumeFilterChip(
                      key: LumeTaraweehTool.rakaatChip(v),
                      label: v == 'all'
                          ? l.commonAll
                          : l.taraweehRakaatCount(int.parse(v)),
                      selected: rakaat == v,
                      onTap: () => _setRakaat(v),
                    ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            child: LumeMap(
              key: LumeTaraweehTool.mapKey,
              label: l.taraweehMap,
              caption: city,
              pins: <LumeMapPin>[
                for (int i = 0; i < shown.length; i++)
                  LumeMapPin(
                    x: shown[i].x,
                    y: shown[i].y,
                    icon: LumeIcons.mosque,
                    label: nameOf(shown[i]),
                    active: i == 0,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.taraweehNearby,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeTaraweehTool.emptyKey,
                    icon: LumeIcons.mosque,
                    title: l.taraweehNoMatch,
                    text: l.taraweehNoMatchText,
                    action: LumeButton(
                      label: l.commonAll,
                      icon: LumeIcons.refresh,
                      onPressed: () => _setRakaat('all'),
                    ),
                  )
                : LumeRows(
                    key: LumeTaraweehTool.listKey,
                    children: <Widget>[
                      for (final LumeNearbyMosque m in shown)
                        LumeRichRow(
                          key: LumeTaraweehTool.row(m.name),
                          icon: LumeIcons.mosque,
                          iconTone: lume.tintAccent,
                          iconInk: lume.accent,
                          title: nameOf(m),
                          subtitle: l.mosquesAddr(city),
                          meta: <String>[
                            LumeMosquesText.distance(l, f, m.km),
                            l.taraweehRakaatCount(m.rakaat),
                            m.reciter,
                          ],
                          value: f.time(_at(m.taraweehMinute)),
                          valueSub: l.taraweehStarts,
                          chevron: true,
                          // The reference's own toast. **Dayroz:** open
                          // this mosque's Ramadan schedule.
                          onTap: () => _host.currentState?.say(
                            nameOf(m),
                            tone: LumeToastTone.info,
                          ),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.taraweehSelected,
            child: LumeCard(
              key: LumeTaraweehTool.closestKey,
              child: LumeMetrics(
                columns: 3,
                children: <Widget>[
                  LumeMetric(
                    icon: LumeIcons.clock,
                    value: f.time(_at(closest?.taraweehMinute ?? 20 * 60 + 45)),
                    label: l.taraweehStarts,
                  ),
                  LumeMetric(
                    icon: LumeIcons.route,
                    value: LumeMosquesText.distance(l, f, closest?.km ?? 0),
                    label: l.qiblaToKaaba,
                  ),
                  LumeMetric(
                    icon: LumeIcons.beads,
                    value: f.integer(closest?.rakaat ?? 20),
                    label: l.taraweehRakaat,
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeNoteCard(
              key: LumeTaraweehTool.remindKey,
              tone: LumeNoteTone.info,
              icon: LumeIcons.bell,
              title: l.taraweehRemindTitle,
              text: l.taraweehRemindText,
            ),
          ),
        ],
      ),
    );
  }
}
