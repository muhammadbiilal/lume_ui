/// Bills — `tools/money/bills.tool.js`, as a read-only dashboard.
///
/// The reference's composition, in its order: the summary card (this
/// month's total, a paid ring, overdue/upcoming/paid stats), an overdue
/// notice when there is one, the state filter, every bill, a six-month
/// trend, then a short history. Every tap the reference wires is a toast —
/// there is no add, edit or mark-as-paid, so nothing here is a record (see
/// `bills_fixtures.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/bills_fixtures.dart';

class LumeBillsTool extends ConsumerStatefulWidget {
  const LumeBillsTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeBillsTool(request: request);

  static const String id = 'bills';

  static const Key summaryKey = ValueKey<String>('bills.summary');
  static const Key noticeKey = ValueKey<String>('bills.notice');
  static const Key filterKey = ValueKey<String>('bills.filter');
  static const Key listKey = ValueKey<String>('bills.list');
  static const Key emptyKey = ValueKey<String>('bills.empty');
  static const Key trendKey = ValueKey<String>('bills.trend');
  static const Key historyKey = ValueKey<String>('bills.history');
  static Key filterChip(LumeBillsFilter f) =>
      ValueKey<String>('bills.filter.${f.name}');
  static Key row(String ref) => ValueKey<String>('bills.row.$ref');

  @override
  ConsumerState<LumeBillsTool> createState() => _LumeBillsToolState();
}

class _LumeBillsToolState extends ConsumerState<LumeBillsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);

  LumeBillsFilter get _filter => LumeBillsFilter.values.firstWhere(
    (LumeBillsFilter f) => f.name == _session.read(LumeBillsTool.id, 'state'),
    orElse: () => LumeBillsFilter.all,
  );

  void _setFilter(LumeBillsFilter f) =>
      setState(() => _session.write(LumeBillsTool.id, 'state', f.name));

  String _dueLabel(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeBill b,
  ) => switch (b.state) {
    LumeBillState.overdue => l.billsOverdueBy(-b.days),
    LumeBillState.paid => l.billsPaidOn(
      f.dateMedium(now.add(Duration(days: b.days))),
    ),
    LumeBillState.due || LumeBillState.upcoming => l.billsDueIn(b.days),
  };

  LumeBadge _badge(AppLocalizations l, LumeBillState state) => switch (state) {
    LumeBillState.overdue => LumeBadge(
      label: l.commonOverdue,
      tone: LumeBadgeTone.late_,
    ),
    LumeBillState.paid => LumeBadge(
      label: l.commonPaid,
      tone: LumeBadgeTone.ok,
    ),
    LumeBillState.due || LumeBillState.upcoming => LumeBadge(
      label: l.commonDue,
      tone: LumeBadgeTone.warn,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    final LumeColors lume = context.lume;

    final String ccy =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    final LumeBillsBoard board = LumeBillsBoard(currency: ccy);
    String money(double usd) => f.money(board.money(usd), code: ccy);

    final LumeBillsFilter filter = _filter;
    final List<LumeBill> shown = board.shown(filter);

    final List<String> trendLabels = <String>[
      for (int i = 5; i >= 0; i--)
        f.monthShort(DateTime(now.year, now.month - i)),
    ];

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
            child: LumeSummaryCard(
              key: LumeBillsTool.summaryKey,
              kicker: l.billsDueThisMonth,
              value: money(board.totalDueUsd),
              caption: board.overdueCount > 0
                  ? l.billsOverdueCount(board.overdueCount)
                  : l.billsAllOnTrack,
              aside: LumeProgressRing(
                value: board.paidRatio,
                centreValue: '${board.paidCount}/${board.list.length}',
                label: l.commonPaid,
              ),
              stats: <LumeStat>[
                LumeStat(
                  value: money(board.overdueUsd),
                  label: l.commonOverdue,
                ),
                LumeStat(
                  value: money(board.upcomingUsd),
                  label: l.billsUpcoming,
                ),
                LumeStat(value: money(board.paidUsd), label: l.billsPaidAmount),
              ],
            ),
          ),
          if (board.overdueCount > 0)
            LumeToolSection(
              child: LumeNoteCard(
                key: LumeBillsTool.noticeKey,
                tone: LumeNoteTone.warn,
                icon: LumeIcons.alert,
                title: l.billsNeedAttention(board.overdueCount),
                text: l.billsNeedAttentionText,
              ),
            ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            flush: true,
            child: LumeFilterBar(
              key: LumeBillsTool.filterKey,
              children: <Widget>[
                for (final LumeBillsFilter chip in LumeBillsFilter.values)
                  LumeFilterChip(
                    key: LumeBillsTool.filterChip(chip),
                    label: switch (chip) {
                      LumeBillsFilter.all => l.commonAll,
                      LumeBillsFilter.overdue => l.commonOverdue,
                      LumeBillsFilter.due => l.commonDue,
                      LumeBillsFilter.paid => l.commonPaid,
                    },
                    count: switch (chip) {
                      LumeBillsFilter.all => board.list.length,
                      LumeBillsFilter.overdue => board.overdueCount,
                      LumeBillsFilter.due => board.dueCount,
                      LumeBillsFilter.paid => board.paidCount,
                    },
                    selected: filter == chip,
                    onTap: () => _setFilter(chip),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            title: l.billsAll,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeBillsTool.emptyKey,
                    icon: LumeIcons.receipt,
                    title: l.billsNoMatch,
                    text: l.billsNoMatchText,
                    action: LumeButton(
                      label: l.commonAll,
                      icon: LumeIcons.refresh,
                      onPressed: () => _setFilter(LumeBillsFilter.all),
                    ),
                  )
                : LumeRows(
                    key: LumeBillsTool.listKey,
                    children: <Widget>[
                      for (final LumeBill b in shown)
                        LumeRichRow(
                          key: LumeBillsTool.row(b.ref),
                          icon: b.icon,
                          iconTone: b.state == LumeBillState.overdue
                              ? lume.amber.withValues(alpha: 0.18)
                              : null,
                          iconInk: b.state == LumeBillState.overdue
                              ? lume.amber
                              : null,
                          title: b.name,
                          subtitle: b.provider,
                          meta: <String>[
                            '${l.billsRef} ${b.ref}',
                            _dueLabel(l, f, now, b),
                          ],
                          badge: _badge(l, b.state),
                          value: money(b.amountUsd),
                          onTap: () => _host.currentState?.say(
                            b.state == LumeBillState.paid
                                ? l.billsRowPaid(b.name)
                                : l.billsOpening(b.provider),
                            tone: LumeToastTone.info,
                          ),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.billsTrend,
            child: LumeCard(
              child: LumeBarChart(
                key: LumeBillsTool.trendKey,
                values: LumeBillsFixtures.trend,
                labels: trendLabels,
                highlight: LumeBillsFixtures.trend.length - 1,
                label: l.billsTrend,
                caption: Text(
                  l.billsTrendCap(money(board.trendAverageUsd)),
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: lume.text3),
                ),
              ),
            ),
          ),
          LumeToolSection(
            title: l.commonHistory,
            child: LumeRows(
              key: LumeBillsTool.historyKey,
              children: <Widget>[
                for (final LumeBill h in board.history)
                  LumeCompactRow(
                    icon: LumeIcons.checkCircle,
                    label: h.name,
                    subtitle: _dueLabel(l, f, now, h),
                    value: money(h.amountUsd),
                    chevron: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
