/// Public Holidays — the reference tool for `tools/daily/holidays.tool.js`.
///
/// Where the reader is, the next holiday on that country's table, a search
/// and a kind filter over the full list, and the list itself. The month grid
/// `holidays.tool.js` also draws (`c.monthGrid()`) is left out here: it is a
/// bare, un-marked calendar page with no holiday of its own on it (nothing in
/// the reference paints a holiday onto a day square), and `calendar_fixtures
/// .dart`'s own tool already gives this exact table a month grid to sit
/// beside — drawing a second, identical, unmarked one here would be
/// decoration standing in for content rather than adding to it.
///
/// **Corrected:** the reference's "next" is simply `list[0]` — the first row
/// of an unsorted table, not a computed one; Pakistan's table happens to
/// start in November, so a reader opening it in January is told their next
/// holiday is nine months away. [LumeHolidaysTool.next] finds the holiday
/// nearest the reader's own today, the same correction
/// `calendar_fixtures.dart`'s agenda already made for its own ordering.
///
/// **Honesty:** every date on this table is illustrative reference data with
/// no year attached — see `holidays_fixtures.dart` for why one can't
/// honestly be printed — so the tool says this plainly on screen rather than
/// silently presenting a date as though it were confirmed for the current
/// year.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/holidays_fixtures.dart';
import 'holidays_text.dart';

class LumeHolidaysTool extends ConsumerStatefulWidget {
  const LumeHolidaysTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeHolidaysTool(request: request);

  static const String id = 'holidays';

  static const Key summaryKey = ValueKey<String>('holidays.summary');
  static const Key noteKey = ValueKey<String>('holidays.note');
  static const Key searchKey = ValueKey<String>('holidays.search');
  static const Key filterKey = ValueKey<String>('holidays.filter');
  static const Key listKey = ValueKey<String>('holidays.list');
  static const Key emptyKey = ValueKey<String>('holidays.empty');

  /// The session's own spelling of "every kind" — `c.filter('kind', 'all')`.
  static const String allKinds = 'all';

  /// The holiday in [list] nearest [today], with the date it next falls on —
  /// today's date carried forward a year past whichever holidays have
  /// already passed it, since every date here is a bare month and day. See
  /// the library doc for why the reference's own `list[0]` is not repeated.
  static (LumeHoliday, DateTime) next(List<LumeHoliday> list, DateTime today) {
    final DateTime day = DateTime(today.year, today.month, today.day);
    DateTime at(LumeHoliday h) {
      final DateTime d = DateTime(day.year, h.month, h.day);
      return d.isBefore(day) ? DateTime(day.year + 1, h.month, h.day) : d;
    }

    LumeHoliday best = list.first;
    DateTime bestAt = at(best);
    for (final LumeHoliday h in list.skip(1)) {
      final DateTime d = at(h);
      if (d.isBefore(bestAt)) {
        best = h;
        bestAt = d;
      }
    }
    return (best, bestAt);
  }

  /// `shown` — kept to [kind] where it isn't [allKinds], and to [query]
  /// matched against the name in every language passed (§47: the reader's
  /// own, and English).
  static List<LumeHoliday> filter(
    List<LumeHoliday> list, {
    required String kind,
    required String query,
    required List<AppLocalizations> languages,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeHoliday>[
      for (final LumeHoliday h in list)
        if ((kind == allKinds || h.kind.name == kind) &&
            (q.isEmpty ||
                languages.any(
                  (AppLocalizations l) => LumeHolidaysText.name(
                    l,
                    h.name,
                  ).toLowerCase().contains(q),
                )))
          h,
    ];
  }

  @override
  ConsumerState<LumeHolidaysTool> createState() => _LumeHolidaysToolState();
}

class _LumeHolidaysToolState extends ConsumerState<LumeHolidaysTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeHolidaysTool.id, 'q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _search(String q) =>
      setState(() => _session.write(LumeHolidaysTool.id, 'q', q));

  void _setKind(String kind) =>
      setState(() => _session.write(LumeHolidaysTool.id, 'kind', kind));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final LumeColors lume = context.lume;
    final DateTime now = LumeClockScope.of(context).now();

    final List<LumeHoliday> all = LumeHolidaysFixtures.holidaysFor(
      r.user.country,
    );
    final List<LumeHolidayKind> kinds = LumeHolidaysFixtures.kindsOf(all);
    final String kind =
        _session.read(LumeHolidaysTool.id, 'kind') ?? LumeHolidaysTool.allKinds;
    final List<LumeHoliday> shown = LumeHolidaysTool.filter(
      all,
      kind: kind,
      query: _query.text,
      languages: <AppLocalizations>{
        l,
        lookupAppLocalizations(const Locale('en')),
      }.toList(),
    );

    final (LumeHoliday upcoming, DateTime upcomingAt) = LumeHolidaysTool.next(
      all,
      now,
    );

    String dateOf(LumeHoliday h) =>
        f.dateMedium(DateTime(now.year, h.month, h.day));

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      exportFile: shown.isEmpty
          ? null
          : () => LumeExportFile.csv(
              tool: LumeHolidaysTool.id,
              day: now,
              rows: <List<Object?>>[
                <Object?>[l.commonDate, l.commonName, l.holidaysKind],
                for (final LumeHoliday h in shown)
                  <Object?>[
                    dateOf(h),
                    LumeHolidaysText.name(l, h.name),
                    LumeHolidaysText.kind(l, h.kind),
                  ],
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              items: <LumeContextItem>[
                LumeContextItem(
                  label: LumeToolScreen.countryName(
                    context,
                    ref,
                    r.user.country,
                  ),
                  icon: LumeIcons.globe,
                  onTap: () => showLumePersonalise(context),
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeHolidaysTool.summaryKey,
              kicker: l.holidaysNext,
              value: LumeHolidaysText.name(l, upcoming.name),
              caption:
                  '${f.dateMedium(upcomingAt)} · '
                  '${LumeHolidaysText.kind(l, upcoming.kind)}',
              stats: <LumeStat>[
                LumeStat(value: '${all.length}', label: l.holidaysListed),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeNoteCard(
              key: LumeHolidaysTool.noteKey,
              tone: LumeNoteTone.warn,
              icon: LumeIcons.alert,
              title: l.holidaysNoteTitle,
              text: l.holidaysNoteText,
            ),
          ),
          LumeToolSection(
            child: LumeSearchField(
              key: LumeHolidaysTool.searchKey,
              controller: _query,
              focusNode: _searchFocus,
              placeholder: l.holidaysSearch,
              onChanged: _search,
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            child: Semantics(
              label: l.holidaysKind,
              container: true,
              child: LumeFilterBar(
                key: LumeHolidaysTool.filterKey,
                children: <Widget>[
                  LumeFilterChip(
                    label: l.commonAll,
                    selected: kind == LumeHolidaysTool.allKinds,
                    onTap: () => _setKind(LumeHolidaysTool.allKinds),
                  ),
                  for (final LumeHolidayKind k in kinds)
                    LumeFilterChip(
                      label: LumeHolidaysText.kind(l, k),
                      selected: kind == k.name,
                      onTap: () => _setKind(k.name),
                    ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.holidaysListTitle,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeHolidaysTool.emptyKey,
                    icon: LumeIcons.calendar,
                    title: l.holidaysNoMatch,
                    text: l.holidaysNoMatchText,
                  )
                : LumeRows(
                    key: LumeHolidaysTool.listKey,
                    children: <Widget>[
                      for (final LumeHoliday h in shown)
                        LumeRichRow(
                          icon: LumeIcons.calendar,
                          iconTone: lume.tintAccent,
                          title: LumeHolidaysText.name(l, h.name),
                          subtitle: LumeHolidaysText.kind(l, h.kind),
                          value: dateOf(h),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
