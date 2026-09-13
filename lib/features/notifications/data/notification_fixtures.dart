/// The notification feed, as a deterministic fixture.
///
/// **Nothing here was delivered.** The reference's engine builds each row from
/// a live tool context — prayer times, bill balances, an exchange's indices —
/// and those tools are not converted yet. So this carries the reference's own
/// fifteen sources with fixed, sample content, and the centre says out loud
/// that it is sample content (`nFixtureNote`). A list of alerts that were
/// never sent must not imply that they were (§125).
///
/// What it does reproduce exactly is the part that is about the reader rather
/// than about the data:
///
/// * **eligibility** — a source whose tool this reader cannot see is not
///   built, so a faith-gated or country-gated alert is absent rather than
///   filtered (§64);
/// * **preferences** — a category switched off, or a type switched off,
///   removes its rows;
/// * **privacy** — with previews off every body becomes "Content hidden";
///   with sensitive previews off, a sensitive source's body becomes its own
///   discreet line. The detail never reaches the widget layer;
/// * **order** — expired last, then priority descending, then age ascending;
/// * **folding** — three or more rows of one event become the first plus a
///   summary.
///
/// Ages are minutes *before the injected clock*, exactly as the reference
/// anchors them to when Lume started — so "18 min ago" is a fact about the
/// clock rather than a literal.
library;

import '../../../l10n/app_localizations.dart';
import '../../account/domain/notification_prefs.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../domain/notification_model.dart';

/// One row of sample content for a source in `kNotificationSources`.
///
/// **Every field is fixture-only.** The Dayroz obligation is one row per
/// source in `docs/conversion_archive/CROSS_CUTTING_INVENTORY.md`: the title
/// and body come from the tool's own live context, and the age from the
/// event's real timestamp.
class LumeNotificationSample {
  const LumeNotificationSample({
    required this.sourceId,
    required this.title,
    required this.body,
    required this.agoMinutes,
    this.priority = LumeNotificationPriority.normal,
    this.privateBody,
    this.actionKey,
    this.expiresMinutes,
    this.groupId,
  });

  /// The `kNotificationSources` id this stands for.
  final String sourceId;

  final String title;

  /// What the row says when previews are on.
  final String body;

  /// What a *sensitive* source says when sensitive previews are off. The
  /// reference calls it `bodyPrivate`: it reports that something changed
  /// without reporting what.
  final String? privateBody;

  /// Minutes before the injected clock.
  final int agoMinutes;

  final LumeNotificationPriority priority;

  /// Which localised verb the row's own button reads, if it has one.
  final String? actionKey;

  /// How long after its event the row stops asking to be acted on.
  final int? expiresMinutes;

  /// Rows sharing one id are updates of one event and fold when there are
  /// three or more.
  final String? groupId;
}

/// The reference's fifteen, with sample content.
///
/// Ages and priorities are the reference's own (`notify-engine.js`,
/// `SOURCES`); the sentences are this fixture's, because the live ones do not
/// exist until the tools do.
const List<LumeNotificationSample> kNotificationSamples =
    <LumeNotificationSample>[
      LumeNotificationSample(
        sourceId: 'prayer.next',
        title: 'Asr is coming up',
        body: 'Asr at 4:52 PM · in 22 minutes',
        agoMinutes: 0,
        actionKey: 'viewPrayer',
        expiresMinutes: 60,
      ),
      LumeNotificationSample(
        sourceId: 'meds.dose',
        title: 'Time for a dose',
        body: 'Metformin · 500 mg with food',
        privateBody: 'A medication reminder is due',
        agoMinutes: 8,
        priority: LumeNotificationPriority.high,
        expiresMinutes: 240,
      ),
      LumeNotificationSample(
        sourceId: 'loadshed.next',
        title: 'Load-shedding at 6:00 PM',
        body: 'Gulshan-e-Iqbal · about 2 hours',
        agoMinutes: 12,
      ),
      LumeNotificationSample(
        sourceId: 'parcel.transit',
        title: 'Your parcel is out for delivery',
        body: 'TCS · arriving today',
        agoMinutes: 18,
        actionKey: 'track',
      ),
      LumeNotificationSample(
        sourceId: 'flights.delay',
        title: 'PK-301 is delayed',
        body: 'Now departing 7:40 PM · gate 14',
        agoMinutes: 34,
        priority: LumeNotificationPriority.high,
        actionKey: 'viewFlight',
      ),
      LumeNotificationSample(
        sourceId: 'trains.delay',
        title: 'Green Line is running late',
        body: 'About 35 minutes behind',
        agoMinutes: 52,
        actionKey: 'viewTrain',
      ),
      LumeNotificationSample(
        sourceId: 'weather.alert',
        title: 'Heavy rain warning',
        body: 'Karachi · this evening',
        agoMinutes: 96,
        priority: LumeNotificationPriority.critical,
        actionKey: 'viewWeather',
        expiresMinutes: 720,
      ),
      LumeNotificationSample(
        sourceId: 'bills.overdue',
        title: '2 bills are overdue',
        body: 'Rs 8,400 outstanding',
        privateBody: 'Some bills need attention',
        agoMinutes: 180,
        priority: LumeNotificationPriority.high,
        actionKey: 'pay',
      ),
      LumeNotificationSample(
        sourceId: 'todos.today',
        title: '3 tasks left today',
        body: 'Next: pick up groceries',
        agoMinutes: 200,
        actionKey: 'complete',
        expiresMinutes: 720,
      ),
      LumeNotificationSample(
        sourceId: 'weather.tomorrow',
        title: 'Tomorrow in Karachi',
        body: '34° / 27° · clear',
        agoMinutes: 300,
        priority: LumeNotificationPriority.low,
        expiresMinutes: 900,
      ),
      LumeNotificationSample(
        sourceId: 'habits.streak',
        title: 'Water · 4 days running',
        body: 'One more glass keeps it going',
        agoMinutes: 420,
        priority: LumeNotificationPriority.low,
        expiresMinutes: 600,
      ),
      LumeNotificationSample(
        sourceId: 'bills.due',
        title: 'K-Electric is due soon',
        body: 'Due Friday · Rs 5,100',
        privateBody: 'Due Friday',
        agoMinutes: 640,
        actionKey: 'pay',
      ),
      LumeNotificationSample(
        sourceId: 'subs.renewal',
        title: 'A subscription renews tomorrow',
        body: 'Spotify · Rs 499 monthly',
        privateBody: 'A subscription renews tomorrow',
        agoMinutes: 720,
      ),
      LumeNotificationSample(
        sourceId: 'documents.expiring',
        title: 'Your passport expires in 30 days',
        body: 'Renew before 13 October',
        privateBody: 'A document needs attention',
        agoMinutes: 1440,
        priority: LumeNotificationPriority.high,
        actionKey: 'viewDoc',
      ),
      // Three updates of one event, so the folding rule has something to
      // fold. The reference folds at three.
      LumeNotificationSample(
        sourceId: 'markets.move',
        title: 'KSE-100 is up 0.8%',
        body: '78,412 · Pakistan Stock Exchange',
        agoMinutes: 2,
        actionKey: 'viewMarket',
        groupId: 'markets.kse',
      ),
      LumeNotificationSample(
        sourceId: 'markets.move',
        title: 'KSE-100 is up 1.1%',
        body: '78,655 · Pakistan Stock Exchange',
        agoMinutes: 14,
        actionKey: 'viewMarket',
        groupId: 'markets.kse',
      ),
      LumeNotificationSample(
        sourceId: 'markets.move',
        title: 'KSE-100 is up 0.4%',
        body: '78,120 · Pakistan Stock Exchange',
        agoMinutes: 26,
        actionKey: 'viewMarket',
        groupId: 'markets.kse',
      ),
    ];

/// The feed, for as long as the process lives.
class LumeFixtureNotificationRepository
    implements LumeNotificationRepository, LumeNotificationDurability {
  LumeFixtureNotificationRepository({
    required this.eligibility,
    required this.user,
    required this.l,
    required this.readPrefs,
    this.samples = kNotificationSamples,
    this.quietHours = false,
    this.pushEnabled = false,
    this.failWith,
    this.delay = Duration.zero,
  });

  final LumeEligibility eligibility;
  final LumeUserContext user;
  final AppLocalizations l;

  /// The preferences, *asked for* rather than held.
  ///
  /// A snapshot taken when the repository was built would be stale the moment
  /// the reader switched a category off — and they can do that from the
  /// preferences sheet without this being rebuilt. The record is read at the
  /// moment it is needed, from the same store the account route writes.
  final LumeNotificationPrefs Function() readPrefs;

  final List<LumeNotificationSample> samples;
  final bool quietHours;
  final bool pushEnabled;

  /// Makes the read refuse, for the failure state the reference draws.
  final LumeNotificationFailure? failWith;

  /// How long the read takes, for the skeleton.
  final Duration delay;

  final Set<String> _read = <String>{};
  final Set<String> _dismissed = <String>{};

  @override
  bool get isDurable => false;

  /// Three or more rows of one event fold at [foldAt].
  static const int foldAt = 3;

  LumeNotificationSource? _sourceOf(String id) {
    for (final LumeNotificationSource s in kNotificationSources) {
      if (s.id == id) return s;
    }
    return null;
  }

  LumeNotificationCategory? _categoryOf(String id) {
    for (final LumeNotificationCategory c in kNotificationCategories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// `allowed(src)` — the same three gates, in the same order.
  bool _allowed(LumeNotificationSource src, LumeNotificationPrefs prefs) {
    final LumeFeature? f = eligibility.visibleById(src.tool, user);
    if (f == null) return false;
    if (!prefs.isOn(src.category)) return false;
    if (!prefs.isTypeOn(src.id)) return false;
    return true;
  }

  /// `bodyFor(src, made)` — what the row is allowed to say.
  String _body(
    LumeNotificationSample s,
    LumeNotificationCategory? cat,
    LumeNotificationPrefs prefs,
  ) {
    if (!prefs.preview) return l.nHidden;
    final bool sensitive = cat?.sensitive ?? false;
    if (sensitive && !prefs.sensitivePreview && s.privateBody != null) {
      return s.privateBody!;
    }
    return s.body;
  }

  @override
  Future<LumeNotificationFeed> feed({required DateTime now}) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failWith != null) throw LumeNotificationException(failWith!);

    final LumeNotificationPrefs prefs = readPrefs();
    final List<LumeNotification> out = <LumeNotification>[];
    for (int i = 0; i < samples.length; i++) {
      final LumeNotificationSample s = samples[i];
      final LumeNotificationSource? src = _sourceOf(s.sourceId);
      if (src == null || !_allowed(src, prefs)) continue;

      final String id = '${s.sourceId}#$i';
      if (_dismissed.contains(id)) continue;

      final LumeNotificationCategory? cat = _categoryOf(src.category);
      final bool expired =
          s.expiresMinutes != null && s.agoMinutes > s.expiresMinutes!;

      out.add(
        LumeNotification(
          id: id,
          title: s.title,
          body: _body(s, cat, prefs),
          category: src.category,
          icon: cat?.icon ?? 'bell',
          tool: src.tool,
          agoMinutes: s.agoMinutes,
          priority: s.priority,
          read: _read.contains(id),
          expired: expired,
          groupId: s.groupId ?? id,
          action: s.actionKey == null
              ? null
              : LumeNotificationAction(labelKey: s.actionKey!, tool: src.tool),
        ),
      );
    }

    // Expired last, then priority descending, then age ascending. Priority
    // outranking recency is the whole point: an important row must not fall
    // off the bottom because three ordinary ones arrived.
    out.sort((LumeNotification a, LumeNotification b) {
      if (a.expired != b.expired) return a.expired ? 1 : -1;
      final int byPriority = b.priority.rank.compareTo(a.priority.rank);
      if (byPriority != 0) return byPriority;
      return a.agoMinutes.compareTo(b.agoMinutes);
    });

    return LumeNotificationFeed(
      all: List<LumeNotification>.unmodifiable(out),
      quietHours: quietHours,
      pushEnabled: pushEnabled,
    );
  }

  @override
  Future<void> markRead(String id) async => _read.add(id);

  @override
  Future<void> markAllRead() async {
    final LumeNotificationFeed f = await feed(now: DateTime.now());
    for (final LumeNotification n in f.all) {
      _read.add(n.id);
    }
  }

  @override
  Future<void> dismiss(String id) async => _dismissed.add(id);
}

/// Fold three or more updates of one event into the first plus a summary.
///
/// `grouped(rows)` in the reference. Unrelated events are never folded
/// together, and the summary is marked read only when every row it stands
/// for has been.
List<LumeNotification> foldNotifications(
  List<LumeNotification> rows,
  AppLocalizations l,
) {
  final Map<String, List<LumeNotification>> byGroup =
      <String, List<LumeNotification>>{};
  final List<String> order = <String>[];
  for (final LumeNotification n in rows) {
    (byGroup[n.groupId] ??= <LumeNotification>[]).add(n);
    if (byGroup[n.groupId]!.length == 1) order.add(n.groupId);
  }

  final List<LumeNotification> out = <LumeNotification>[];
  for (final String g in order) {
    final List<LumeNotification> items = byGroup[g]!;
    if (items.length < LumeFixtureNotificationRepository.foldAt) {
      out.addAll(items);
      continue;
    }
    final LumeNotification head = items.first;
    final List<LumeNotification> rest = items.sublist(1);
    out
      ..add(head)
      ..add(
        LumeNotification(
          id: 'group:$g',
          title: l.nGroupTitle(head.title),
          body: l.nGroupBody(rest.length),
          category: head.category,
          icon: head.icon,
          tool: head.tool,
          agoMinutes: rest.first.agoMinutes,
          priority: LumeNotificationPriority.low,
          read: rest.every((LumeNotification x) => x.read),
          grouped: true,
          groupId: g,
          members: rest.length,
        ),
      );
  }
  return out;
}
