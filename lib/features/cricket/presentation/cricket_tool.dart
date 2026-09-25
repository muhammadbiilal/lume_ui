/// Cricket — `tools/daily/cricket.tool.js` over `tool-data.js` `CRICKET`.
///
/// One frozen match's scorecard, its fixtures and its table, exactly as the
/// reference composes them: a score card with the batting side's status and
/// three metrics, three tabs, and — under Live — the batting and bowling
/// cards the reference draws by default. The chosen tab lives in the tool
/// session.
///
/// The reference draws `UI.freshness({ quality: 'live' })` over the score;
/// this port does not repeat that claim itself (§45 of `CLAUDE.md`: no widget
/// works out its own freshness). What the source bar under this screen says
/// comes from [LumeDataCapability] alone, and cricket is not registered there
/// as live — so whatever the catalogue's own `freshness:` kind says, the bar
/// reads "Sample data", which is what a fixture match is.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/cricket_fixtures.dart';
import 'cricket_text.dart';

class LumeCricketTool extends ConsumerStatefulWidget {
  const LumeCricketTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeCricketTool(request: request);

  static const String id = 'cricket';

  static const Key scoreKey = ValueKey<String>('cricket.score');
  static const Key tabsKey = ValueKey<String>('cricket.tabs');
  static const Key battingKey = ValueKey<String>('cricket.batting');
  static const Key bowlingKey = ValueKey<String>('cricket.bowling');
  static const Key fixturesKey = ValueKey<String>('cricket.fixtures');
  static const Key standingsKey = ValueKey<String>('cricket.standings');

  /// `c.state('tab') || 'live'`.
  static const String defaultTab = 'live';

  @override
  ConsumerState<LumeCricketTool> createState() => _LumeCricketToolState();
}

class _LumeCricketToolState extends ConsumerState<LumeCricketTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);

  String get _tab =>
      _session.read(LumeCricketTool.id, 'tab') ?? LumeCricketTool.defaultTab;

  void _setTab(String v) =>
      setState(() => _session.write(LumeCricketTool.id, 'tab', v));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    const LumeCricketMatch m = LumeCricket.match;
    final String tab = _tab;

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The reference shares an unrelated quote (C68); this is the match this
      // screen leads with, and where and under what format it was played.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.quote,
        text:
            '${m.team1} ${m.score1} (${m.overs1}) '
            'v ${m.team2}${m.hasSecondInnings ? ' ${m.score2} (${m.overs2})' : ''}',
        source: '${m.format} · ${f.dateLong(now)}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeCard(
              key: LumeCricketTool.scoreKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: _TeamSide(code: m.team1, name: m.team1Full)),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            LumeNumerals(
                              m.score1,
                              style: LumeType.fit(
                                context,
                                context.lumeType.display,
                              ).copyWith(
                                color: context.lume.text,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${m.overs1} ${l.cricketOvers}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LumeType.fit(
                                context,
                                context.lumeType.metaSmall,
                              ).copyWith(color: context.lume.text3),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _TeamSide(
                          code: m.team2,
                          name: m.team2Full,
                          alignEnd: true,
                          second: m.hasSecondInnings
                              ? '${m.score2} (${m.overs2})'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    LumeCricketStrings.status(l, m),
                    textAlign: TextAlign.center,
                    style: LumeType.fit(
                      context,
                      context.lumeType.meta,
                    ).copyWith(color: context.lume.text2),
                  ),
                  const SizedBox(height: 16),
                  LumeMetrics(
                    columns: 3,
                    children: <Widget>[
                      LumeMetric(
                        value: f.fixed(m.runRate, 2),
                        label: l.cricketRunRate,
                      ),
                      LumeMetric(value: m.format, label: l.cricketFormat),
                      LumeMetric(value: m.venueCity, label: l.cricketVenue),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            flush: true,
            child: LumeTabs(
              key: LumeCricketTool.tabsKey,
              value: tab,
              onChanged: _setTab,
              items: <LumeChoice>[
                LumeChoice(value: 'live', label: l.cricketLive),
                LumeChoice(value: 'fixtures', label: l.cricketFixtures),
                // The reference's own naming: the tab that opens the table is
                // labelled with `cricket.standings` ("Table"), and the section
                // it opens is titled with `cricket.table` ("Standings").
                LumeChoice(value: 'standings', label: l.cricketStandings),
              ],
            ),
          ),
          if (tab == 'fixtures')
            LumeToolSection(
              title: l.cricketUpcoming,
              child: LumeRows(
                key: LumeCricketTool.fixturesKey,
                children: <Widget>[
                  for (final LumeCricketFixture fx in LumeCricket.fixtures)
                    LumeRichRow(
                      icon: LumeIcons.cricket,
                      title: '${fx.team1} v ${fx.team2}',
                      subtitle: fx.venue,
                      meta: <String>[fx.format],
                      value: fx.date,
                      valueSub: fx.time,
                    ),
                ],
              ),
            )
          else if (tab == 'standings')
            LumeToolSection(
              title: l.cricketTable,
              child: LumeTable(
                key: LumeCricketTool.standingsKey,
                label: l.cricketTable,
                columns: <LumeColumn>[
                  LumeColumn(label: l.cricketTeam),
                  LumeColumn(label: l.cricketPlayed, numeric: true),
                  LumeColumn(label: l.cricketWon, numeric: true),
                  LumeColumn(label: l.cricketLost, numeric: true),
                  LumeColumn(label: l.cricketPoints, numeric: true),
                  LumeColumn(label: l.cricketNrr, numeric: true),
                ],
                cell: (int row, int column) => column == 4
                    ? Text(
                        f.integer(LumeCricket.standings[row].points),
                        style: LumeTable.cellStyle(
                          context,
                          column,
                        ).copyWith(fontWeight: FontWeight.w800),
                      )
                    : null,
                rows: <List<String>>[
                  for (final LumeCricketStanding s in LumeCricket.standings)
                    <String>[
                      s.team,
                      f.integer(s.played),
                      f.integer(s.won),
                      f.integer(s.lost),
                      f.integer(s.points),
                      s.netRunRate,
                    ],
                ],
              ),
            )
          else ...<Widget>[
            LumeToolSection(
              title: l.cricketBatting,
              child: LumeTable(
                key: LumeCricketTool.battingKey,
                label: l.cricketBatting,
                columns: <LumeColumn>[
                  LumeColumn(label: l.cricketBatter),
                  LumeColumn(label: l.cricketRuns, numeric: true),
                  LumeColumn(label: l.cricketBalls, numeric: true),
                  LumeColumn(label: l.cricketFours, numeric: true),
                  LumeColumn(label: l.cricketSixes, numeric: true),
                  LumeColumn(label: l.cricketStrikeRate, numeric: true),
                ],
                cell: (int row, int column) => column == 0
                    ? _BatterName(batter: m.batters[row], notOut: l.cricketNotOut)
                    : null,
                rows: <List<String>>[
                  for (final LumeCricketBatter b in m.batters)
                    <String>[
                      b.name,
                      f.integer(b.runs),
                      f.integer(b.balls),
                      f.integer(b.fours),
                      f.integer(b.sixes),
                      f.number(b.strikeRate, decimals: 1),
                    ],
                ],
              ),
            ),
            LumeToolSection(
              title: l.cricketBowling,
              child: LumeTable(
                key: LumeCricketTool.bowlingKey,
                label: l.cricketBowling,
                columns: <LumeColumn>[
                  LumeColumn(label: l.cricketBowler),
                  LumeColumn(label: l.cricketOvers2, numeric: true),
                  LumeColumn(label: l.cricketMaidens, numeric: true),
                  LumeColumn(label: l.cricketRuns, numeric: true),
                  LumeColumn(label: l.cricketWickets, numeric: true),
                  LumeColumn(label: l.cricketEconomy, numeric: true),
                ],
                cell: (int row, int column) => column == 4
                    ? Text(
                        f.integer(m.bowlers[row].wickets),
                        style: LumeTable.cellStyle(
                          context,
                          column,
                        ).copyWith(fontWeight: FontWeight.w800),
                      )
                    : null,
                rows: <List<String>>[
                  for (final LumeCricketBowler b in m.bowlers)
                    <String>[
                      b.name,
                      f.number(b.overs),
                      f.integer(b.maidens),
                      f.integer(b.runs),
                      f.integer(b.wickets),
                      f.number(b.economy, decimals: 2),
                    ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One side of the score row — a code, its full name, and, for the side
/// batting second, its own line under them.
class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.code,
    required this.name,
    this.alignEnd = false,
    this.second,
  });

  final String code;
  final String name;
  final bool alignEnd;
  final String? second;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final CrossAxisAlignment cross = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          code,
          style: LumeType.fit(
            context,
            context.lumeType.cardTitle,
          ).copyWith(color: lume.text, fontWeight: FontWeight.w800),
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LumeType.fit(
            context,
            context.lumeType.metaSmall,
          ).copyWith(color: lume.text3),
        ),
        if (second != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            second!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LumeType.fit(context, context.lumeType.metaSmall).copyWith(
              color: lume.text2,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// A batting card's first column — the name bold, "not out" beside it in
/// words rather than a colour, matching the reference's own `<i>` suffix.
class _BatterName extends StatelessWidget {
  const _BatterName({required this.batter, required this.notOut});

  final LumeCricketBatter batter;
  final String notOut;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: <InlineSpan>[
        TextSpan(
          text: batter.name,
          style: LumeTable.cellStyle(
            context,
            0,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        if (!batter.out)
          TextSpan(
            text: ' $notOut',
            style: LumeTable.cellStyle(context, 0).copyWith(
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: context.lume.text3,
            ),
          ),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
