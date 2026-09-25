/// Bills — the reference tool for a read-only money dashboard.
///
/// `tools/money/bills.tool.js` over `context.js` `bills()` and `D.BILLS`: a
/// fixed household of five bills — their state (overdue, due, upcoming or
/// paid), the day offset from "now" that state was measured at, and a masked
/// account reference. There is no add, edit or mark-as-paid here: every tap
/// the reference wires is a toast (`'toast:' + …`), never a write, so this
/// stays a display, like Currency & Gold, rather than a record family like
/// Meal Plan.
///
/// Amounts are authored in dollars, like every other dollar-authored fixture
/// ([lumeFromUsd]); a bill's category and provider are shown as the reference
/// writes them (`x.name`, `x.provider` — never run through `c.t()`).
///
/// Kept as the reference has it (`context.js` `bills()`): `dueCount` counts
/// only the bills the reference calls strictly `due`, yet selecting the
/// "Due" filter also shows the ones it calls `upcoming`
/// (`state === 'due' && x.state === 'upcoming'`). The chip's count and the
/// chip's list disagree on purpose — this is the reference's own arithmetic,
/// not a Flutter bug.
library;

import '../../../core/fixtures/lume_reference_money.dart';
import '../../../core/icons/lume_icons.dart';

/// `b.state`.
enum LumeBillState { overdue, due, upcoming, paid }

/// A filter chip's value — `c.filter('state', 'all')`'s domain.
enum LumeBillsFilter { all, overdue, due, paid }

/// One row of `D.BILLS`.
class LumeBill {
  const LumeBill({
    required this.name,
    required this.provider,
    required this.amountUsd,
    required this.days,
    required this.state,
    required this.ref,
  });

  /// `b.name` — the bill's category, kept untranslated as the reference
  /// writes it.
  final String name;

  /// `b.provider` — kept untranslated, like [name].
  final String provider;

  /// `b.amount` — dollars, converted per reader at display time.
  final double amountUsd;

  /// `b.days` — signed days from "now"; negative is in the past. Drives the
  /// due label, and for [LumeBillState.paid], the date it was paid.
  final int days;

  final LumeBillState state;

  /// `b.ref` — a masked account number, shown as-is.
  final String ref;

  /// `{ Electricity: 'i-bolt', Gas: 'i-flame', Internet: 'i-wifi',
  /// Water: 'i-droplet', Mobile: 'i-signal' }[b.name] || 'i-receipt'`.
  String get icon => switch (name) {
    'Electricity' => LumeIcons.bolt,
    'Gas' => LumeIcons.flame,
    'Internet' => LumeIcons.wifi,
    'Water' => LumeIcons.droplet,
    'Mobile' => LumeIcons.signal,
    _ => LumeIcons.receipt,
  };
}

abstract final class LumeBillsFixtures {
  /// `D.BILLS`, verbatim.
  static const List<LumeBill> list = <LumeBill>[
    LumeBill(
      name: 'Electricity',
      provider: 'K-Electric',
      amountUsd: 74,
      days: 4,
      state: LumeBillState.due,
      ref: '••••4821',
    ),
    LumeBill(
      name: 'Gas',
      provider: 'SSGC',
      amountUsd: 21,
      days: 10,
      state: LumeBillState.upcoming,
      ref: '••••7734',
    ),
    LumeBill(
      name: 'Internet',
      provider: 'Nayatel',
      amountUsd: 28,
      days: -5,
      state: LumeBillState.overdue,
      ref: '••••1180',
    ),
    LumeBill(
      name: 'Water',
      provider: 'CDA',
      amountUsd: 9,
      days: 17,
      state: LumeBillState.upcoming,
      ref: '••••0042',
    ),
    LumeBill(
      name: 'Mobile',
      provider: 'Jazz',
      amountUsd: 12,
      days: -7,
      state: LumeBillState.paid,
      ref: '••••3390',
    ),
  ];

  /// `trend: [128, 142, 118, 156, 134, 144]` — six months of bar heights, in
  /// dollars like the rows above (the last month, 144, is exactly the sum of
  /// every bill's [LumeBill.amountUsd]). The reference never runs these
  /// through `c.money()` for the bars themselves — only the caption beneath
  /// them cites a converted figure.
  static const List<double> trend = <double>[128, 142, 118, 156, 134, 144];
}

/// `bills()` — the fixed list, aggregated for one reader's currency.
class LumeBillsBoard {
  const LumeBillsBoard({required this.currency});

  /// The reader's currency — every dollar figure is converted through this.
  final String currency;

  List<LumeBill> get list => LumeBillsFixtures.list;

  List<LumeBill> get overdueBills => <LumeBill>[
    for (final LumeBill b in list)
      if (b.state == LumeBillState.overdue) b,
  ];

  /// Strictly `due` — not `upcoming`. See the class doc's quirk note.
  List<LumeBill> get dueBills => <LumeBill>[
    for (final LumeBill b in list)
      if (b.state == LumeBillState.due) b,
  ];

  List<LumeBill> get upcomingBills => <LumeBill>[
    for (final LumeBill b in list)
      if (b.state == LumeBillState.upcoming) b,
  ];

  List<LumeBill> get paidBills => <LumeBill>[
    for (final LumeBill b in list)
      if (b.state == LumeBillState.paid) b,
  ];

  double _sumUsd(List<LumeBill> bills) =>
      bills.fold(0.0, (double s, LumeBill b) => s + b.amountUsd);

  /// `b.totalDue` — every bill that is not yet paid.
  double get totalDueUsd =>
      _sumUsd(overdueBills) + _sumUsd(dueBills) + _sumUsd(upcomingBills);

  double get overdueUsd => _sumUsd(overdueBills);
  double get upcomingUsd => _sumUsd(upcomingBills);
  double get paidUsd => _sumUsd(paidBills);

  int get overdueCount => overdueBills.length;

  /// `dueCount` — strictly `due` (see the filter quirk).
  int get dueCount => dueBills.length;
  int get paidCount => paidBills.length;

  /// `b.paidRatio`.
  double get paidRatio => list.isEmpty ? 0 : paidCount / list.length;

  /// `money(usd)` — the reference's dollar-to-local conversion, tidied.
  double money(double usd) => lumeFromUsd(usd, currency);

  /// The trend's average month, converted — what the trend caption cites.
  double get trendAverageUsd =>
      LumeBillsFixtures.trend.reduce((double a, double b) => a + b) /
      LumeBillsFixtures.trend.length;

  /// `shownBills` — bills matching a filter, in the reference's order and
  /// with its quirk: `due` also shows `upcoming`.
  List<LumeBill> shown(LumeBillsFilter filter) => <LumeBill>[
    for (final LumeBill b in list)
      if (filter == LumeBillsFilter.all ||
          b.state.name == filter.name ||
          (filter == LumeBillsFilter.due && b.state == LumeBillState.upcoming))
        b,
  ];

  /// `history` — every paid bill, then up to two more still open, in the
  /// list's own order.
  List<LumeBill> get history => <LumeBill>[
    ...paidBills,
    ...<LumeBill>[
      for (final LumeBill b in list)
        if (b.state != LumeBillState.paid) b,
    ].take(2),
  ];
}
