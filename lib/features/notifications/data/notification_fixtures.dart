/// The notification feed, as a deterministic fixture.
///
/// **Nothing here was delivered.** The reference's engine builds each row from
/// a live tool context, and those tools are not converted yet. So this carries
/// the rows the reference *renders* at the fixture instant, read off the
/// running prototype with `probe_notifications.mjs` rather than written by
/// hand, with every value labelled fixture-only.
///
/// What it reproduces exactly is the part that is about the reader:
///
/// * **eligibility** — a source whose tool this reader cannot see is not
///   built, so a country-gated alert is absent rather than filtered (§64).
///   Pakistan renders thirteen rows; London renders ten;
/// * **preferences** — a category or a type switched off removes its rows;
/// * **privacy** — previews off turns every body into "Content hidden";
///   sensitive previews off turns a *sensitive source's* body into its own
///   discreet line. The detail never reaches the widget layer;
/// * **order** — expired last, then rank, then age — with the reference's
///   own rank, in which low counts as normal (C54);
/// * **folding** — three rows of one source fold. The reference cannot reach
///   it (each source builds one row), so no fixture does either; the rule is
///   kept as a contract and tested as a function.
///
/// Two sources the reference declares do not build at the fixture instant:
/// the next prayer is more than 45 minutes away, and there is no weather
/// alert. They are absent here for the same reason.
library;

import 'package:flutter/widgets.dart' show Locale;

import '../../../core/fixtures/lume_reference_weather.dart';
import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/domain/notification_prefs.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../domain/notification_model.dart';

/// Resolves a row's text for a reader, in their language.
typedef LumeNotificationText =
    String Function(AppLocalizations l, LumeUserContext user);

/// One rendered row, for a source in `kNotificationSources`.
///
/// **Every value is fixture-only.** The Dayroz obligation for each is the
/// tool's own live context: the flight's real delay, the bill's real amount,
/// the event's real timestamp. The sentences are the reference's keys.
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
    this.builds,
  });

  /// The `kNotificationSources` id this stands for.
  final String sourceId;

  final LumeNotificationText title;

  /// What the row says when every preview is on.
  final LumeNotificationText body;

  /// What a sensitive source says while sensitive previews are off — the
  /// reference's `bodyPrivate`. `null` for a source that has none.
  final LumeNotificationText? privateBody;

  /// Minutes before the fixture instant. The reference anchors ages to when
  /// Lume started; with its clock frozen these are the source's own `ago`.
  final int agoMinutes;

  final LumeNotificationPriority priority;

  /// Which `n.act.*` verb the row's own button reads, if it has one.
  final String? actionKey;

  /// How long after its event the row stops asking to be acted on.
  final int? expiresMinutes;

  /// Whether the source builds a row for this reader at all — the reference's
  /// `build` returning `null`. `null` means it always does.
  ///
  /// This is not eligibility: a tool the reader can see may still have
  /// nothing to say. Markets is global, and speaks only when the reader's own
  /// exchange moved enough.
  final bool Function(LumeUserContext user)? builds;
}

/// The lead index of each exchange the reference knows, fixture-only:
/// `EXCHANGES[code].indices[0]` in `tool-data.js`.
///
/// A country with no entry has no exchange (`GLOBAL`), so no market row.
typedef LumeLeadIndex = ({
  String name,
  double pct,
  String value,
  String exchange,
});

const Map<String, LumeLeadIndex> kLeadIndices = <String, LumeLeadIndex>{
  'PK': (
    name: 'KSE-100',
    pct: 0.82,
    value: '154,230.42',
    exchange: 'Pakistan Stock Exchange',
  ),
  'US': (
    name: 'S&P 500',
    pct: 0.42,
    value: '5,812.44',
    exchange: 'Nasdaq · NYSE',
  ),
  'GB': (
    name: 'FTSE 100',
    pct: 0.38,
    value: '8,288.60',
    exchange: 'London Stock Exchange',
  ),
  'AE': (
    name: 'DFM General',
    pct: 0.40,
    value: '4,622.18',
    exchange: 'Dubai Financial Market',
  ),
  'SA': (
    name: 'TASI',
    pct: 0.53,
    value: '11,844.20',
    exchange: 'Saudi Exchange',
  ),
  'IN': (
    name: 'NIFTY 50',
    pct: 0.49,
    value: '24,188.65',
    exchange: 'National Stock Exchange',
  ),
};

/// `if (!ix || Math.abs(ix.pct) < 0.5) return null;`
const double kMarketMoveThreshold = 0.5;

LumeLeadIndex? _moved(LumeUserContext u) {
  final LumeLeadIndex? ix = kLeadIndices[u.country];
  if (ix == null || ix.pct.abs() < kMarketMoveThreshold) return null;
  return ix;
}

/// Tomorrow's forecast body, from the one port of the reference's weather.
///
/// `daily(base, seed)[1]` in the reference's own generator, formatted in the
/// market's units — so Islamabad reads 36° / 27°, London 25° / 17° and New
/// York 84° / 68°, which is what `probe_notifications.mjs` read off the
/// running prototype. A market the reference's weather does not define builds
/// no forecast row at all, rather than another market's (C61).
String _forecastBody(AppLocalizations l, LumeUserContext u) {
  final LumeReferenceDay d = lumeReferenceClimate(u.country)!.tomorrow;
  final LumeFormatting f = LumeFormatting(
    locale: const Locale('en'),
    countryCode: u.country,
    units: LumeFormatting.unitsFor(u.country),
  );
  return l.nForecastBody(
    f.temperature(d.highC),
    f.temperature(d.lowC),
    '${d.rainPercent}',
  );
}

String _signedPct(double pct) =>
    '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';

/// The thirteen rows the reference renders for a reader in Pakistan, in the
/// order its engine declares their sources.
final List<LumeNotificationSample> kNotificationSamples =
    <LumeNotificationSample>[
      LumeNotificationSample(
        sourceId: 'bills.overdue',
        title: (AppLocalizations l, LumeUserContext u) => l.nBillTitle(1),
        body: (AppLocalizations l, LumeUserContext u) =>
            l.nBillBody('Rs 7,920'),
        privateBody: (AppLocalizations l, LumeUserContext u) => l.nBillPrivate,
        agoMinutes: 180,
        priority: LumeNotificationPriority.high,
        actionKey: 'pay',
      ),
      LumeNotificationSample(
        sourceId: 'bills.due',
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nBillDueTitle('Electricity'),
        body: (AppLocalizations l, LumeUserContext u) =>
            '${l.nDueInDays(4)} · Rs 20,900',
        privateBody: (AppLocalizations l, LumeUserContext u) => l.nDueInDays(4),
        agoMinutes: 640,
        actionKey: 'pay',
      ),
      LumeNotificationSample(
        sourceId: 'markets.move',
        // Only the reader's own exchange, and only past half a percent:
        // Pakistan (+0.82%) and Saudi Arabia (+0.53%) build; London, New York,
        // Dubai and Mumbai do not.
        builds: (LumeUserContext u) => _moved(u) != null,
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nMarketTitle(_moved(u)!.name, _signedPct(_moved(u)!.pct)),
        body: (AppLocalizations l, LumeUserContext u) =>
            l.nMarketBody(_moved(u)!.value, _moved(u)!.exchange),
        agoMinutes: 2,
        actionKey: 'viewMarket',
      ),
      LumeNotificationSample(
        sourceId: 'parcel.transit',
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nParcelTitle('Keyboard'),
        body: (AppLocalizations l, LumeUserContext u) =>
            l.nParcelBody('TCS', 'Today, by 18:00'),
        agoMinutes: 18,
        actionKey: 'track',
      ),
      LumeNotificationSample(
        sourceId: 'flights.delay',
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nFlightTitle('EK 624'),
        body: (AppLocalizations l, LumeUserContext u) =>
            l.nFlightBody(17, '08:22', 'Islamabad Intl'),
        agoMinutes: 34,
        priority: LumeNotificationPriority.high,
        actionKey: 'viewFlight',
      ),
      LumeNotificationSample(
        sourceId: 'trains.delay',
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nTrainTitle('Tezgam Express'),
        body: (AppLocalizations l, LumeUserContext u) =>
            l.nTrainBody(35, 'Khanewal Junction'),
        agoMinutes: 52,
        actionKey: 'viewTrain',
      ),
      LumeNotificationSample(
        sourceId: 'weather.tomorrow',
        // The reader's own city, as the reference's `P().city` — so London
        // reads "Tomorrow in London".
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nWeatherTitle(u.city),
        // Tomorrow's forecast is seeded by country in the reference
        // (`D.daily(base.temp, country)`) and formatted in the reader's units,
        // so each market reads its own — New York in Fahrenheit.
        builds: (LumeUserContext u) => lumeReferenceClimate(u.country) != null,
        body: _forecastBody,
        agoMinutes: 300,
        priority: LumeNotificationPriority.low,
        expiresMinutes: 900,
      ),
      LumeNotificationSample(
        sourceId: 'loadshed.next',
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nOutageTitle('19:00'),
        // `ls.area + ' · ' + ls.slot.duration` — data, not a sentence, in the
        // reference too.
        body: (AppLocalizations l, LumeUserContext u) => 'Islamabad · 1h',
        agoMinutes: 12,
      ),
      LumeNotificationSample(
        sourceId: 'documents.expiring',
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nDocTitle('Driving Licence'),
        body: (AppLocalizations l, LumeUserContext u) =>
            l.nDocBody(25, '3 Oct 2025'),
        privateBody: (AppLocalizations l, LumeUserContext u) => l.nDocPrivate,
        agoMinutes: 1440,
        priority: LumeNotificationPriority.high,
        actionKey: 'viewDoc',
      ),
      LumeNotificationSample(
        sourceId: 'subs.renewal',
        title: (AppLocalizations l, LumeUserContext u) =>
            l.nSubTitle('Netflix'),
        body: (AppLocalizations l, LumeUserContext u) =>
            l.nSubBody(6, 'Rs 2,550'),
        privateBody: (AppLocalizations l, LumeUserContext u) =>
            l.nSubPrivate(6),
        agoMinutes: 720,
      ),
      LumeNotificationSample(
        sourceId: 'todos.today',
        title: (AppLocalizations l, LumeUserContext u) => l.nTasksLeft(4),
        body: (AppLocalizations l, LumeUserContext u) =>
            l.nTaskNext('Send the quarterly summary'),
        agoMinutes: 200,
        actionKey: 'complete',
        expiresMinutes: 720,
      ),
      LumeNotificationSample(
        sourceId: 'meds.dose',
        title: (AppLocalizations l, LumeUserContext u) => l.nMedTitle,
        body: (AppLocalizations l, LumeUserContext u) => l.nMedBody('8:00 pm'),
        privateBody: (AppLocalizations l, LumeUserContext u) => l.nMedPrivate,
        agoMinutes: 8,
        priority: LumeNotificationPriority.high,
        expiresMinutes: 240,
      ),
      LumeNotificationSample(
        sourceId: 'habits.streak',
        title: (AppLocalizations l, LumeUserContext u) => l.nHabitTitle(1),
        body: (AppLocalizations l, LumeUserContext u) => l.nHabitBody(12),
        agoMinutes: 420,
        priority: LumeNotificationPriority.low,
        expiresMinutes: 600,
      ),
    ];

/// The reference's rank: `PRIORITY[src.priority] || 1`.
///
/// `PRIORITY.low` is `0`, and `0 || 1` is `1` — so a low row sorts as though
/// it were normal. That is why "Tomorrow" and the habit reminder render above
/// the due bill and the subscription. Reproduced, not repaired (C54): the
/// Important filter still asks for rank two and above, which low never
/// reaches either way.
int lumeReferenceRank(LumeNotificationPriority p) => p.rank == 0 ? 1 : p.rank;

/// The feed, for as long as the process lives.
class LumeFixtureNotificationRepository
    implements LumeNotificationRepository, LumeNotificationDurability {
  LumeFixtureNotificationRepository({
    required this.eligibility,
    required this.user,
    required this.l,
    required this.readPrefs,
    List<LumeNotificationSample>? samples,
    this.quietHours = false,
    this.pushEnabled = false,
    this.failWith,
    this.delay = Duration.zero,
  }) : samples = samples ?? kNotificationSamples;

  final LumeEligibility eligibility;
  final LumeUserContext user;
  final AppLocalizations l;

  /// The preferences, *asked for* rather than held, from the same store the
  /// account's Notifications route and the preferences sheet write.
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

  /// What has been presented, through any surface. Nondurable, like the
  /// rest: a restart presents the first banner again, where the reference
  /// remembers it in the profile.
  final Set<String> _presented = <String>{};

  @override
  bool get isDurable => false;

  /// Three or more rows of one source fold at [foldAt].
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
    LumeNotificationSource src,
    LumeNotificationPrefs prefs,
  ) {
    if (!prefs.preview) return l.nHidden;
    if (src.sensitive && !prefs.sensitivePreview && s.privateBody != null) {
      return s.privateBody!(l, user);
    }
    return s.body(l, user);
  }

  /// Every row this reader may see, ordered. No clock is read: ages are the
  /// fixture's own, relative to the fixture instant.
  List<LumeNotification> _build() {
    final LumeNotificationPrefs prefs = readPrefs();
    final List<LumeNotification> out = <LumeNotification>[];
    for (int i = 0; i < samples.length; i++) {
      final LumeNotificationSample s = samples[i];
      final LumeNotificationSource? src = _sourceOf(s.sourceId);
      if (src == null || !_allowed(src, prefs)) continue;
      if (s.builds != null && !s.builds!(user)) continue;

      final String id = '${s.sourceId}#$i';
      if (_dismissed.contains(id)) continue;

      final LumeNotificationCategory? cat = _categoryOf(src.category);
      out.add(
        LumeNotification(
          id: id,
          title: s.title(l, user),
          body: _body(s, src, prefs),
          category: src.category,
          icon: cat?.icon ?? 'bell',
          tool: src.tool,
          agoMinutes: s.agoMinutes,
          priority: s.priority,
          read: _read.contains(id),
          expired: s.expiresMinutes != null && s.agoMinutes > s.expiresMinutes!,
          // `groupId: src.id` — a group is repetition of one source.
          groupId: s.sourceId,
          action: s.actionKey == null
              ? null
              : LumeNotificationAction(labelKey: s.actionKey!, tool: src.tool),
        ),
      );
    }

    out.sort((LumeNotification a, LumeNotification b) {
      if (a.expired != b.expired) return a.expired ? 1 : -1;
      final int byRank = lumeReferenceRank(
        b.priority,
      ).compareTo(lumeReferenceRank(a.priority));
      if (byRank != 0) return byRank;
      return a.agoMinutes.compareTo(b.agoMinutes);
    });
    return List<LumeNotification>.unmodifiable(out);
  }

  @override
  Future<LumeNotificationFeed> feed({required DateTime now}) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failWith != null) throw LumeNotificationException(failWith!);
    return LumeNotificationFeed(
      all: _build(),
      quietHours: quietHours,
      pushEnabled: pushEnabled,
    );
  }

  @override
  Future<void> markRead(String id) async => _read.add(id);

  @override
  Future<void> markAllRead() async {
    for (final LumeNotification n in _build()) {
      _read.add(n.id);
    }
  }

  @override
  Future<void> dismiss(String id) async => _dismissed.add(id);

  @override
  Future<LumeNotification?> nextToPresent({required DateTime now}) async {
    if (failWith != null) throw LumeNotificationException(failWith!);
    for (final LumeNotification n in _build()) {
      if (!n.read && !n.expired && !_presented.contains(n.id)) return n;
    }
    return null;
  }

  @override
  Future<void> markPresented(String id) async => _presented.add(id);

  @override
  Future<void> restoreAll() async => _dismissed.clear();
}

/// Fold three or more rows of one source into the first plus a summary.
///
/// `grouped(rows)` in the reference. **Unreachable from every fixture**, as it
/// is in the reference, where each source builds at most one row; kept because
/// a live engine can produce repeats, and tested as a function.
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
