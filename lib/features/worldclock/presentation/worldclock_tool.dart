/// World Clock — `tools/daily/worldclock.tool.js`, rebuilt on the IANA
/// database Lume already carries (`WORLD_CLOCK_PROPOSAL.md`, D-W1…D-W10).
///
/// The reference's four sections are kept — a summary, a search field, a list
/// of places, and "Convert a time" — and everything inside them is worked out
/// from one instant ([LumeClockScope]) read through [LumeTimeZoneService].
/// Nothing derived is stored: the session remembers only *which* zones are
/// listed, in what order, and what the converter is set to (D-W3).
///
/// What differs from the reference, deliberately:
///
/// * the headline is the **reader's** zone and the reader's date, not the
///   device's (defects 1 and 2);
/// * a zone is shown by CLDR's localized label, with its identifier beneath
///   (defect 3);
/// * the reader's own clock leads the list, and the eight anchors are a
///   starting point rather than the whole world: any of the 341 canonical
///   zones, and any city the country table carries, can be added — searched
///   through [LumeZoneLabels.matches] (defects 4, 5, 20);
/// * offsets are exact to the minute, so `+5:30` and `+5:45` are sayable, and
///   "Same time" means a difference of zero rather than a failed lookup
///   (defects 7, 8, 10);
/// * a place on another day says yesterday or tomorrow (defect 12);
/// * "Convert a time" converts (defects 13, 14);
/// * the clock ticks on the minute (defect 17);
/// * every string is localized (defect 18).
///
/// **Failure is typed, never substituted** (D-W10): an unknown zone, an
/// unavailable database, a device that has not said where it is, and a country
/// with several zones each get their own state, naming what was asked for.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/time/lume_city_zones.dart';
import '../../../core/time/lume_country_zones.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/time/lume_zone.dart';
import '../../../core/time/lume_zone_aliases.dart';
import '../../../core/time/lume_zone_labels.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_settings.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/data/country_fixture.dart';
import '../../onboarding/domain/country_picker_model.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';

/// Schedules one delayed callback. The real [Timer] by default; a test that
/// steps time itself supplies its own.
typedef LumeClockTicker = Timer Function(Duration delay, void Function() fire);

/// Why there is no clock to show — each names what was asked for, and none of
/// them is another zone quietly put in its place (D-W10).
enum LumeClockTrouble {
  /// An identifier the database does not hold, or that is not an identifier.
  zoneUnknown,

  /// The database itself is not loaded.
  database,

  /// "Follow this device", and no device zone.
  device,

  /// "Follow my region", and the country lists several canonical zones.
  choose,
}

/// One place on the list: the identifier as it is stored, and what it
/// resolved to. A stored alias is read, never rewritten.
@immutable
class LumeClockPlace {
  const LumeClockPlace(this.stored, this.resolution);

  /// The identifier exactly as the session holds it.
  final String stored;

  final LumeZoneResolution resolution;

  bool get ok => resolution.resolved;

  /// The canonical identifier — the identity a row is keyed by.
  String get id => resolution.canonicalId ?? stored;

  /// A stored identifier that is a backward link to [id].
  bool get isAlias => resolution.isAlias;

  LumeClockTrouble get trouble => LumeWorldClock.troubleOf(resolution.outcome);
}

/// One row, read at one instant: the place's wall clock, its day against the
/// reader's, and its offset from the reader.
@immutable
class LumeClockReading {
  const LumeClockReading({
    required this.place,
    required this.local,
    required this.offset,
    required this.dayShift,
    required this.summer,
  });

  final LumeClockPlace place;

  /// The place's wall clock — a naive value whose fields are the place's.
  final DateTime local;

  /// From the reader's zone to this one, exact to the minute. Negative is
  /// behind.
  final Duration offset;

  /// −1 yesterday, 0 today, +1 tomorrow — and, across the date line, ±2.
  final int dayShift;

  /// The zone is on its summer offset at this instant.
  final bool summer;
}

/// One thing the reader may add: a city, or a zone.
@immutable
class LumeClockChoice {
  const LumeClockChoice({
    required this.zone,
    required this.title,
    required this.subtitle,
  });

  /// The canonical identifier this choice adds.
  final String zone;

  final String title;
  final String subtitle;
}

/// The arithmetic, as pure functions. No clock of its own, no zone of its
/// own; nothing here reads or writes anything.
abstract final class LumeWorldClock {
  /// `WORLD_CITIES` — the reference's eight rows, so the list a reader first
  /// sees is the one the reference showed, with their own clock above it.
  static const List<String> anchors = <String>[
    'Asia/Karachi',
    'Asia/Dubai',
    'Europe/London',
    'America/New_York',
    'Asia/Tokyo',
    'Asia/Singapore',
    'Europe/Istanbul',
    'Australia/Sydney',
  ];

  static const String _isolateStart = '\u2068';
  static const String _isolateEnd = '\u2069';

  /// A name or a figure, first-strong isolated: a Latin identifier inside an
  /// Urdu line, and a localized time inside an Arabic one, each keep their
  /// own direction without reordering the sentence around them.
  static String isolate(String text) => '$_isolateStart$text$_isolateEnd';

  /// How long until the wall clock turns over to the next minute.
  ///
  /// Computed from the instant each time it is asked and never from the last
  /// tick, so a tick that fires late shortens the next wait instead of
  /// pushing it further out: the schedule cannot accumulate drift.
  static Duration untilNextMinute(DateTime now) => Duration(
    microseconds:
        const Duration(minutes: 1).inMicroseconds -
        (now.second * 1000000 + now.millisecond * 1000 + now.microsecond),
  );

  /// The stored list of identifiers.
  static List<String> parse(String? stored) => <String>[
    for (final String s in (stored ?? '').split(','))
      if (s.trim().isNotEmpty) s.trim(),
  ];

  static String encode(List<String> ids) => ids.join(',');

  /// The list a reader who has added nothing sees: the reference's anchors,
  /// without the one their own row already is.
  static List<String> seed(String? readerZone) => <String>[
    for (final String id in anchors)
      if (id != readerZone) id,
  ];

  /// Which typed state an outcome is said as.
  static LumeClockTrouble troubleOf(LumeZoneOutcome outcome) =>
      switch (outcome) {
        LumeZoneOutcome.unknown ||
        LumeZoneOutcome.malformed => LumeClockTrouble.zoneUnknown,
        LumeZoneOutcome.missingDevice => LumeClockTrouble.device,
        LumeZoneOutcome.selectionRequired => LumeClockTrouble.choose,
        // A zone that was found and could not be read through is the
        // database's failure, not the identifier's.
        LumeZoneOutcome.databaseUnavailable ||
        LumeZoneOutcome.conversionFailed ||
        LumeZoneOutcome.canonical ||
        LumeZoneOutcome.alias ||
        LumeZoneOutcome.device => LumeClockTrouble.database,
      };

  /// Whole days between the reader's date and the place's, at one instant.
  ///
  /// Both are naive wall clocks, so the difference is taken on dates read as
  /// UTC: a device on a daylight-saving day has 23- and 25-hour days, and
  /// subtracting those would lose a day at midnight.
  static int dayShift(DateTime reader, DateTime place) => DateTime.utc(
    place.year,
    place.month,
    place.day,
  ).difference(DateTime.utc(reader.year, reader.month, reader.day)).inDays;

  /// The zone is on an offset greater than its own standard one. Neither
  /// hemisphere is assumed, and a zone that never changes is never "summer".
  static bool summerTime(LumeZone zone, DateTime instant) {
    final int year = instant.toUtc().year;
    final Duration a = zone.offsetAt(DateTime.utc(year, 1, 15));
    final Duration b = zone.offsetAt(DateTime.utc(year, 7, 15));
    return zone.offsetAt(instant) > (a < b ? a : b);
  }

  /// One place read at [instant] against the reader's zone, or `null` where
  /// it cannot be read — which the caller says rather than fills in.
  static LumeClockReading? read({
    required LumeTimeZoneService service,
    required DateTime instant,
    required LumeZone reader,
    required LumeClockPlace place,
  }) {
    final LumeZone? zone = place.resolution.zone;
    if (zone == null) return null;
    final LumeZoneClock clock = service.clock(instant, place.resolution);
    if (!clock.ok) return null;
    return LumeClockReading(
      place: place,
      local: clock.local!,
      offset: clock.offset! - reader.offsetAt(instant),
      dayShift: dayShift(reader.wallClockAt(instant), clock.local!),
      summer: summerTime(zone, instant),
    );
  }

  /// The instant at which [zone]'s wall clock reads [wall].
  ///
  /// The database answers one way only — an instant to a wall clock — so the
  /// inverse tries the offset the wall time suggests, then the offset that
  /// answer sits in. Two hours of the year are not one instant:
  ///
  /// * the **repeated** hour (autumn) reads back at two instants; the first —
  ///   still on the summer offset — is taken;
  /// * the **skipped** hour (spring) reads back at neither; the instant after
  ///   the jump is taken, so the converted time lands on a clock the zone
  ///   actually shows rather than on an hour that never happened.
  static DateTime instantOf(DateTime wall, LumeZone zone) {
    final DateTime asUtc = DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
      wall.millisecond,
    );
    final Duration first = zone.offsetAt(asUtc);
    final DateTime a = asUtc.subtract(first);
    final Duration second = zone.offsetAt(a);
    if (second == first) return a;
    final DateTime b = asUtc.subtract(second);
    final bool aReads = _reads(zone, a, wall);
    final bool bReads = _reads(zone, b, wall);
    if (aReads && bReads) return a.isBefore(b) ? a : b;
    if (aReads) return a;
    if (bReads) return b;
    return a.isAfter(b) ? a : b;
  }

  static bool _reads(LumeZone zone, DateTime instant, DateTime wall) {
    final DateTime local = zone.wallClockAt(instant);
    return local.year == wall.year &&
        local.month == wall.month &&
        local.day == wall.day &&
        local.hour == wall.hour &&
        local.minute == wall.minute;
  }

  /// `5:30` — hours and minutes in the reader's own digits, isolated so the
  /// figure keeps its order inside a sentence in either direction.
  static String duration(LumeFormatting f, Duration d) {
    final int minutes = d.inMinutes.abs();
    return isolate('${f.integer(minutes ~/ 60)}:${twoDigits(f, minutes % 60)}');
  }

  /// Two digits in the locale's own numerals — its zero, not an ASCII one.
  static String twoDigits(LumeFormatting f, int value) =>
      value < 10 ? '${f.integer(0)}${f.integer(value)}' : f.integer(value);

  /// "5:30 ahead", "4:00 behind", "Same time".
  ///
  /// The direction and the duration are formatted **together**, once, and
  /// that one string is what every caller reuses: Arabic says the direction
  /// as a verb before the figure, so a bare offset handed to a screen reader
  /// would arrive with no direction at all.
  static String offsetLabel(
    AppLocalizations l,
    LumeFormatting f,
    Duration offset,
  ) {
    if (offset == Duration.zero) return l.clockSameTime;
    final String text = duration(f, offset);
    return offset.isNegative ? l.clockBehind(text) : l.clockAhead(text);
  }

  /// Yesterday, today, tomorrow — and, where the date line puts a place two
  /// days from the reader, the date itself rather than a word that is wrong.
  static String dayLabel(
    AppLocalizations l,
    LumeFormatting f,
    int shift,
    DateTime local,
  ) => switch (shift) {
    -1 => l.clockYesterday,
    0 => l.clockToday,
    1 => l.clockTomorrow,
    _ => f.dateShort(local),
  };

  /// What the reader may add, for [query].
  ///
  /// Cities first — a reader looks for Delhi, not for `Asia/Kolkata` — then
  /// every canonical zone whose CLDR label or identifier matches. A zone is
  /// offered once: the first choice that names it keeps it.
  static List<LumeClockChoice> choices({
    required String query,
    required String language,
    LumeCountryFixture? countries,
    int limit = 60,
  }) {
    final String q = query.trim().toLowerCase();
    final List<LumeClockChoice> out = <LumeClockChoice>[];
    final Set<String> seen = <String>{};

    if (q.isNotEmpty && countries != null) {
      for (final LumeCountry country in countries.forLanguage(language)) {
        for (final String city in countries.placesOf(country.code).cities) {
          if (!city.toLowerCase().contains(q)) continue;
          final String? zone =
              kLumeCityZones['${country.code}:$city'] ??
              kLumeCountryZone[country.code];
          if (zone == null || !seen.add(zone)) continue;
          out.add(
            LumeClockChoice(
              zone: zone,
              title: city,
              subtitle:
                  '${country.name} · '
                  '${LumeZoneLabels.of(zone, language: language).display}',
            ),
          );
          if (out.length >= limit) return out;
        }
      }
    }

    for (final String id in kLumeCanonicalZones) {
      final LumeZoneLabel label = LumeZoneLabels.of(id, language: language);
      if (!LumeZoneLabels.matches(query, label)) continue;
      if (!seen.add(id)) continue;
      out.add(
        LumeClockChoice(zone: id, title: label.display, subtitle: label.id),
      );
      if (out.length >= limit) return out;
    }
    return out;
  }

  /// [ids] with the one at [from] moved by [by] places, or [ids] unchanged
  /// where that would take it off the list.
  static List<String> move(List<String> ids, int from, int by) {
    final int to = from + by;
    if (from < 0 || from >= ids.length || to < 0 || to >= ids.length) {
      return ids;
    }
    final List<String> out = <String>[...ids];
    out.insert(to, out.removeAt(from));
    return out;
  }

  /// The canonical identifier for [id] — a link reads as the zone it names.
  static String canonical(String id) =>
      kLumeCanonicalZones.contains(id) ? id : (kLumeZoneAliases[id] ?? id);

  /// Whether [id] is already listed, compared canonically: a zone cannot be
  /// added twice under two of its names.
  static bool holds(List<String> ids, String id) {
    final String want = canonical(id);
    return ids.any((String s) => canonical(s) == want);
  }

  /// `profile.clock` as a formatter reads it. [LumePreference.auto] leaves
  /// the market's own clock in place (D-W9: threaded here, and nowhere else).
  static bool? hour12(String preference) => switch (preference) {
    '12' => true,
    '24' => false,
    _ => null,
  };
}

class LumeWorldClockTool extends ConsumerStatefulWidget {
  const LumeWorldClockTool({super.key, required this.request, this.ticker});

  final LumeToolRequest request;

  /// The minute tick, for a test that steps time itself.
  final LumeClockTicker? ticker;

  static Widget open(LumeToolRequest request) =>
      LumeWorldClockTool(request: request);

  static const String id = 'worldclock';

  /// The session keys. Only these are ever written: which zones are listed,
  /// in what order, and what the converter is set to. No time, offset, day
  /// or daylight-saving flag is stored anywhere.
  static const String placesKey = 'places';
  static const String fromKey = 'from';
  static const String toKey = 'to';
  static const String atKey = 'at';

  /// How many places a search offers before "Show all".
  static const int shortList = 8;

  static const Key summaryKey = ValueKey<String>('worldclock.summary');
  static const Key searchKey = ValueKey<String>('worldclock.search');
  static const Key clocksKey = ValueKey<String>('worldclock.clocks');
  static const Key emptyKey = ValueKey<String>('worldclock.empty');
  static const Key noMatchKey = ValueKey<String>('worldclock.nomatch');
  static const Key troubleKey = ValueKey<String>('worldclock.trouble');
  static const Key addKey = ValueKey<String>('worldclock.add');
  static const Key showAllKey = ValueKey<String>('worldclock.showall');
  static const Key convertKey = ValueKey<String>('worldclock.convert');
  static const Key convertFromKey = ValueKey<String>('worldclock.convert.from');
  static const Key convertToKey = ValueKey<String>('worldclock.convert.to');
  static const Key convertAtKey = ValueKey<String>('worldclock.convert.at');
  static const Key convertResultKey = ValueKey<String>(
    'worldclock.convert.result',
  );
  static const Key rowActionsKey = ValueKey<String>('worldclock.row.actions');
  static const Key moveUpKey = ValueKey<String>('worldclock.row.up');
  static const Key moveDownKey = ValueKey<String>('worldclock.row.down');
  static const Key removeKey = ValueKey<String>('worldclock.row.remove');

  /// The row for one zone — named, so a test finds a place without depending
  /// on how its label reads in the language under test.
  static Key rowKey(String zone) => ValueKey<String>('worldclock.row.$zone');

  /// A place the search offers to add.
  static Key choiceKey(String zone) =>
      ValueKey<String>('worldclock.choice.$zone');

  /// One option in the converter's pickers.
  static Key optionKey(String value) =>
      ValueKey<String>('worldclock.option.$value');

  @override
  ConsumerState<LumeWorldClockTool> createState() => _LumeWorldClockToolState();
}

class _LumeWorldClockToolState extends ConsumerState<LumeWorldClockTool>
    with WidgetsBindingObserver {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocus = FocusNode();

  Timer? _tick;
  LumeClock _clock = const LumeClock.system();
  bool _awake = true;
  bool _showAll = false;

  LumeToolSession get _session => ref.read(toolSessionProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clock = LumeClockScope.of(context);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Time passed while Lume was away. The screen is recomputed from the
        // clock, never from the ticks it did not receive.
        _awake = true;
        if (mounted) setState(() {});
        _schedule();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _awake = false;
        _tick?.cancel();
        _tick = null;
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// One tick, at the next minute boundary, scheduled from the clock as it
  /// reads now — so nothing accumulates across a day of them.
  void _schedule() {
    _tick?.cancel();
    _tick = null;
    if (!_awake) return;
    final LumeClockTicker fire = widget.ticker ?? Timer.new;
    _tick = fire(LumeWorldClock.untilNextMinute(_clock.now()), () {
      if (!mounted) return;
      setState(() {});
      _schedule();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  // ---- the session ------------------------------------------------------

  List<String> _stored() => LumeWorldClock.parse(
    _session.read(LumeWorldClockTool.id, LumeWorldClockTool.placesKey),
  );

  List<String> _places(String readerZone) => LumeWorldClock.parse(
    _session.field(
      LumeWorldClockTool.id,
      LumeWorldClockTool.placesKey,
      () => LumeWorldClock.encode(LumeWorldClock.seed(readerZone)),
    ),
  );

  void _writePlaces(List<String> ids) {
    _session.write(
      LumeWorldClockTool.id,
      LumeWorldClockTool.placesKey,
      LumeWorldClock.encode(ids),
    );
    if (mounted) setState(() {});
  }

  // ---- the screen -------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    final LumeProfileRecord profile = startup.profile;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
      hour12: LumeWorldClock.hour12(profile.clock),
    );
    final String language = Localizations.localeOf(context).languageCode;
    final DateTime now = _clock.now();

    final LumeTimeZoneService service = ref.watch(timeZoneServiceProvider);
    final LumeZoneResolution reader = service.readerZone(
      profile,
      ref.watch(deviceZoneProvider),
      country: r.user.country,
      city: r.user.city,
    );
    final LumeZoneClock readerClock = service.clock(now, reader);

    if (!readerClock.ok) {
      return _frame(
        l,
        r,
        _trouble(
          l,
          LumeWorldClock.troubleOf(readerClock.failure ?? reader.outcome),
          reader.requested,
        ),
      );
    }

    final LumeZone readerZone = reader.zone!;
    final DateTime readerLocal = readerClock.local!;
    final List<String> ids = _places(readerZone.id);
    final List<LumeClockPlace> places = <LumeClockPlace>[
      for (final String id in ids) LumeClockPlace(id, service.resolveId(id)),
    ];

    return _frame(
      l,
      r,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _summary(l, f, reader, readerZone, readerLocal, language),
          LumeToolSection(
            child: LumeSearchField(
              key: LumeWorldClockTool.searchKey,
              controller: _query,
              focusNode: _queryFocus,
              placeholder: l.clockSearch,
              semanticLabel: l.clockSearch,
              onChanged: (String _) => setState(() => _showAll = false),
              onClear: () => setState(() {
                _query.clear();
                _showAll = false;
              }),
            ),
          ),
          _clocks(l, f, service, now, reader, readerZone, places, language),
          _convert(l, f, service, now, readerZone, places, language),
        ],
      ),
    );
  }

  Widget _frame(AppLocalizations l, LumeToolRequest r, Widget body) =>
      LumeToolScreen(
        key: _host,
        feature: r.feature,
        user: r.user,
        onBack: r.onBack,
        onOpenRelated: r.onOpenRelated,
        // Which database the times come from, in place of the frame's
        // archetype line: the figures are a compiled-in release, and saying
        // which one is the honest sub-line for a tool made of zones.
        subtitle: l.clockDatabaseVersion(
          LumeWorldClock.isolate(LumeTimeZoneService.databaseVersion),
        ),
        actions: LumeToolActions(onSearch: _queryFocus.requestFocus),
        body: body,
      );

  /// The four ways there is no clock, each naming what was asked for.
  Widget _trouble(
    AppLocalizations l,
    LumeClockTrouble trouble,
    String? requested,
  ) => LumeToolSection(
    child: LumeToolState(
      key: LumeWorldClockTool.troubleKey,
      icon: LumeIcons.globe,
      title: switch (trouble) {
        LumeClockTrouble.zoneUnknown => l.clockZoneUnknownTitle,
        LumeClockTrouble.database => l.clockDatabaseTitle,
        LumeClockTrouble.device => l.clockDeviceTitle,
        LumeClockTrouble.choose => l.clockChooseTitle,
      },
      text: switch (trouble) {
        LumeClockTrouble.zoneUnknown => l.clockZoneUnknownText(
          LumeWorldClock.isolate(requested ?? ''),
        ),
        LumeClockTrouble.database => l.clockDatabaseText,
        LumeClockTrouble.device => l.clockDeviceText,
        LumeClockTrouble.choose => l.clockChooseText,
      },
    ),
  );

  Widget _summary(
    AppLocalizations l,
    LumeFormatting f,
    LumeZoneResolution reader,
    LumeZone zone,
    DateTime local,
    String language,
  ) {
    final LumeZoneLabel? label = reader.label(language);
    return LumeToolSection(
      child: LumeSummaryCard(
        key: LumeWorldClockTool.summaryKey,
        kicker: l.clockYourTime,
        value: f.time(local),
        caption:
            '${LumeWorldClock.isolate(label?.display ?? zone.id)} · '
            '${f.dateFull(local)}',
      ),
    );
  }

  // ---- the list ---------------------------------------------------------

  Widget _clocks(
    AppLocalizations l,
    LumeFormatting f,
    LumeTimeZoneService service,
    DateTime now,
    LumeZoneResolution reader,
    LumeZone readerZone,
    List<LumeClockPlace> places,
    String language,
  ) {
    final String query = _query.text.trim();
    final LumeZoneLabel readerLabel =
        reader.label(language) ??
        LumeZoneLabels.of(readerZone.id, language: language);
    final bool readerShown =
        query.isEmpty || LumeZoneLabels.matches(query, readerLabel);

    final List<Widget> rows = <Widget>[
      if (readerShown)
        _readerRow(l, f, reader, readerZone, readerLabel, now, language),
      for (final (int i, LumeClockPlace p) in places.indexed)
        if (query.isEmpty ||
            LumeZoneLabels.matches(
              query,
              LumeZoneLabels.of(p.id, language: language, requested: p.stored),
            ))
          _placeRow(
            l,
            f,
            service,
            now,
            readerZone,
            p,
            i,
            places.length,
            language,
          ),
    ];

    // While a query stands, the places that are *not* yet listed are offered
    // under the ones that are: one field both filters and adds.
    final List<LumeClockChoice> offers = query.isEmpty
        ? const <LumeClockChoice>[]
        : <LumeClockChoice>[
            for (final LumeClockChoice c in LumeWorldClock.choices(
              query: query,
              language: language,
              countries: ref.watch(startupControllerProvider).state.countries,
              limit: _showAll ? 60 : LumeWorldClockTool.shortList + 1,
            ))
              if (!LumeWorldClock.holds(<String>[
                readerZone.id,
                for (final LumeClockPlace p in places) p.stored,
              ], c.zone))
                c,
          ];
    final bool clipped =
        !_showAll && offers.length > LumeWorldClockTool.shortList;
    final List<LumeClockChoice> shown = clipped
        ? offers.sublist(0, LumeWorldClockTool.shortList)
        : offers;

    return LumeToolSection(
      title: l.clockCities,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (rows.isNotEmpty || shown.isNotEmpty)
            Semantics(
              // How many clocks there are, said once to a screen reader
              // rather than drawn over the head — the count is a fact about
              // the list, not a heading.
              label: l.clockCount(rows.length),
              explicitChildNodes: true,
              child: LumeRows(
                key: LumeWorldClockTool.clocksKey,
                children: <Widget>[
                  ...rows,
                  for (final LumeClockChoice c in shown)
                    LumeRichRow(
                      key: LumeWorldClockTool.choiceKey(c.zone),
                      title: LumeWorldClock.isolate(c.title),
                      subtitle: LumeWorldClock.isolate(c.subtitle),
                      icon: LumeIcons.plus,
                      onTap: () => _add(l, c),
                    ),
                ],
              ),
            ),
          if (clipped)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: LumeButton(
                key: LumeWorldClockTool.showAllKey,
                label: l.clockShowAll,
                block: true,
                onPressed: () => setState(() => _showAll = true),
              ),
            ),
          if (rows.isEmpty && shown.isEmpty)
            LumeToolState(
              key: query.isEmpty
                  ? LumeWorldClockTool.emptyKey
                  : LumeWorldClockTool.noMatchKey,
              icon: query.isEmpty ? LumeIcons.globe : LumeIcons.search,
              title: query.isEmpty ? l.clockEmptyTitle : l.clockNoMatch,
              text: query.isEmpty ? l.clockEmptyText : l.clockNoMatchText,
              action: query.isEmpty
                  ? LumeButton.accent(
                      key: LumeWorldClockTool.addKey,
                      label: l.clockAdd,
                      icon: LumeIcons.plus,
                      onPressed: _queryFocus.requestFocus,
                    )
                  : null,
            )
          else if (places.isEmpty && query.isEmpty)
            LumeToolState(
              key: LumeWorldClockTool.emptyKey,
              icon: LumeIcons.globe,
              title: l.clockEmptyTitle,
              text: l.clockEmptyText,
              action: LumeButton.accent(
                key: LumeWorldClockTool.addKey,
                label: l.clockAdd,
                icon: LumeIcons.plus,
                onPressed: _queryFocus.requestFocus,
              ),
            ),
        ],
      ),
    );
  }

  Widget _readerRow(
    AppLocalizations l,
    LumeFormatting f,
    LumeZoneResolution reader,
    LumeZone zone,
    LumeZoneLabel label,
    DateTime now,
    String language,
  ) => _row(
    key: LumeWorldClockTool.rowKey(zone.id),
    title: LumeWorldClock.isolate(label.display),
    // A stored alias is read, never rewritten: the row says both names.
    subtitle: reader.isAlias && reader.requested != null
        ? l.clockAliasNote(
            LumeWorldClock.isolate(reader.requested!),
            LumeWorldClock.isolate(zone.id),
          )
        : l.clockYourZone,
    time: f.time(zone.wallClockAt(now)),
    day: l.clockToday,
    offset: l.clockSameTime,
    spokenPlace: '${l.clockYourTime}, ${label.semantics}',
    onTap: null,
  );

  Widget _placeRow(
    AppLocalizations l,
    LumeFormatting f,
    LumeTimeZoneService service,
    DateTime now,
    LumeZone readerZone,
    LumeClockPlace place,
    int index,
    int count,
    String language,
  ) {
    final LumeClockReading? reading = LumeWorldClock.read(
      service: service,
      instant: now,
      reader: readerZone,
      place: place,
    );
    if (reading == null) {
      // Typed, and never another zone's time standing in for it.
      return LumeRichRow(
        key: LumeWorldClockTool.rowKey(place.stored),
        title: LumeWorldClock.isolate(place.stored),
        subtitle: switch (place.trouble) {
          LumeClockTrouble.database => l.clockDatabaseTitle,
          _ => l.clockZoneUnknownTitle,
        },
        value: '—',
        icon: LumeIcons.alert,
        onTap: () => _openRowActions(l, place, index, count),
      );
    }
    final LumeZoneLabel label = LumeZoneLabels.of(
      place.id,
      language: language,
      requested: place.stored,
    );
    return _row(
      key: LumeWorldClockTool.rowKey(place.id),
      title: LumeWorldClock.isolate(label.display),
      subtitle: place.isAlias
          ? l.clockAliasNote(
              LumeWorldClock.isolate(place.stored),
              LumeWorldClock.isolate(place.id),
            )
          : LumeWorldClock.isolate(place.id),
      time: f.time(reading.local),
      day: LumeWorldClock.dayLabel(l, f, reading.dayShift, reading.local),
      offset: LumeWorldClock.offsetLabel(l, f, reading.offset),
      summer: reading.summer ? l.clockSummerTime : null,
      spokenPlace: label.semantics,
      onTap: () => _openRowActions(l, place, index, count),
    );
  }

  /// One row, said once: the place, its time, its day and its offset — the
  /// offset already carrying its direction, because Arabic says the direction
  /// as a verb and a bare figure would reach a screen reader without one.
  Widget _row({
    required Key key,
    required String title,
    required String subtitle,
    required String time,
    required String day,
    required String offset,
    required String spokenPlace,
    required VoidCallback? onTap,
    String? summer,
  }) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String spoken = l.clockRowSemantics(
      LumeWorldClock.isolate(spokenPlace),
      LumeWorldClock.isolate(time),
      day,
      offset,
    );
    return Semantics(
      key: key,
      container: true,
      button: onTap != null,
      label: summer == null ? spoken : '$spoken, $summer',
      onTap: onTap,
      child: ExcludeSemantics(
        child: LumeRichRow(
          title: title,
          subtitle: subtitle,
          meta: <String>[offset, day, ?summer],
          value: time,
          icon: LumeIcons.clock,
          onTap: onTap,
        ),
      ),
    );
  }

  // ---- adding, removing, ordering ---------------------------------------

  void _add(AppLocalizations l, LumeClockChoice choice) {
    final List<String> ids = _stored();
    if (LumeWorldClock.holds(ids, choice.zone)) {
      _host.currentState?.say(
        l.clockAlready(LumeWorldClock.isolate(choice.title)),
        tone: LumeToastTone.info,
      );
      return;
    }
    _writePlaces(<String>[...ids, choice.zone]);
    _query.clear();
    _showAll = false;
    _host.currentState?.say(l.clockAdded(LumeWorldClock.isolate(choice.title)));
  }

  Future<void> _openRowActions(
    AppLocalizations l,
    LumeClockPlace place,
    int index,
    int count,
  ) async {
    final String language = Localizations.localeOf(context).languageCode;
    final String name = place.ok
        ? LumeZoneLabels.of(place.id, language: language).display
        : place.stored;
    final String? action = await showLumeSheet<String>(
      context: context,
      barrierLabel: name,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          title: LumeWorldClock.isolate(name),
          child: Column(
            key: LumeWorldClockTool.rowActionsKey,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LumeButton(
                key: LumeWorldClockTool.moveUpKey,
                label: l.clockMoveUp,
                icon: LumeIcons.arrowUp,
                block: true,
                onPressed: index == 0
                    ? null
                    : () => Navigator.of(sheet).pop('up'),
              ),
              const SizedBox(height: 8),
              LumeButton(
                key: LumeWorldClockTool.moveDownKey,
                label: l.clockMoveDown,
                icon: LumeIcons.arrowDown,
                block: true,
                onPressed: index >= count - 1
                    ? null
                    : () => Navigator.of(sheet).pop('down'),
              ),
              const SizedBox(height: 8),
              LumeButton.dangerGhost(
                key: LumeWorldClockTool.removeKey,
                label: l.clockRemove,
                icon: LumeIcons.trash,
                block: true,
                onPressed: () => Navigator.of(sheet).pop('remove'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    final List<String> ids = _stored();
    if (index >= ids.length) return;
    switch (action) {
      case 'up':
        _writePlaces(LumeWorldClock.move(ids, index, -1));
      case 'down':
        _writePlaces(LumeWorldClock.move(ids, index, 1));
      case 'remove':
        final List<String> before = <String>[...ids];
        _writePlaces(<String>[...ids]..removeAt(index));
        _host.currentState?.say(
          l.clockRemovedToast(LumeWorldClock.isolate(name)),
          actionLabel: l.recUndo,
          onAction: () => _writePlaces(before),
        );
    }
  }

  // ---- the converter ----------------------------------------------------

  Widget _convert(
    AppLocalizations l,
    LumeFormatting f,
    LumeTimeZoneService service,
    DateTime now,
    LumeZone readerZone,
    List<LumeClockPlace> places,
    String language,
  ) {
    final List<String> listed = <String>[
      readerZone.id,
      for (final LumeClockPlace p in places)
        if (p.ok) p.id,
    ];
    final String from = _pick(LumeWorldClockTool.fromKey, listed, listed.first);
    final String to = _pick(
      LumeWorldClockTool.toKey,
      listed,
      listed.length > 1 ? listed[1] : listed.first,
    );
    final DateTime readerLocal = readerZone.wallClockAt(now);
    final int at =
        int.tryParse(
          _session.read(LumeWorldClockTool.id, LumeWorldClockTool.atKey) ?? '',
        ) ??
        (readerLocal.hour * 60 + readerLocal.minute);

    final LumeZone? fromZone = service.resolveId(from).zone;
    final LumeZone? toZone = service.resolveId(to).zone;
    String name(String id) => LumeZoneLabels.of(id, language: language).display;
    String clockOf(int minutes) =>
        f.time(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

    final String result;
    if (from == to) {
      result = l.clockConvertSame;
    } else if (fromZone == null || toZone == null) {
      result = l.clockZoneUnknownTitle;
    } else {
      final DateTime wall = DateTime(
        readerLocal.year,
        readerLocal.month,
        readerLocal.day,
        at ~/ 60,
        at % 60,
      );
      final DateTime instant = LumeWorldClock.instantOf(wall, fromZone);
      final DateTime here = fromZone.wallClockAt(instant);
      final DateTime there = toZone.wallClockAt(instant);
      result = l.clockConvertResult(
        LumeWorldClock.isolate(f.time(there)),
        LumeWorldClock.dayLabel(
          l,
          f,
          LumeWorldClock.dayShift(here, there),
          there,
        ),
      );
    }

    return LumeToolSection(
      title: l.clockConvert,
      child: LumeCard(
        child: Column(
          key: LumeWorldClockTool.convertKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeFieldGrid(
              children: <Widget>[
                LumeToolField(
                  key: LumeWorldClockTool.convertFromKey,
                  label: l.clockConvertFrom,
                  value: LumeWorldClock.isolate(name(from)),
                  onTap: () => _pickZone(l, LumeWorldClockTool.fromKey, listed),
                ),
                LumeToolField(
                  key: LumeWorldClockTool.convertToKey,
                  label: l.clockConvertTo,
                  value: LumeWorldClock.isolate(name(to)),
                  onTap: () => _pickZone(l, LumeWorldClockTool.toKey, listed),
                ),
                LumeToolField(
                  key: LumeWorldClockTool.convertAtKey,
                  label: l.clockConvertAt,
                  value: LumeWorldClock.isolate(clockOf(at)),
                  onTap: () => _pickAt(l, clockOf),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              key: LumeWorldClockTool.convertResultKey,
              liveRegion: true,
              child: Text(
                result,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A stored choice that is still on the list, else [fallback]: a zone the
  /// reader has since removed cannot go on being the converter's "from".
  String _pick(String key, List<String> listed, String fallback) {
    final String? held = _session.read(LumeWorldClockTool.id, key);
    return held != null && listed.contains(held) ? held : fallback;
  }

  Future<void> _pickZone(
    AppLocalizations l,
    String key,
    List<String> listed,
  ) async {
    final String language = Localizations.localeOf(context).languageCode;
    final String title = key == LumeWorldClockTool.fromKey
        ? l.clockConvertFrom
        : l.clockConvertTo;
    final String current = _pick(key, listed, listed.first);
    final String? picked = await showLumeSheet<String>(
      context: context,
      barrierLabel: title,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          tall: true,
          title: title,
          child: SingleChildScrollView(
            child: LumeOptionList(
              label: title,
              children: <LumeOptionRow>[
                for (final (int i, String id) in listed.indexed)
                  LumeOptionRow(
                    key: LumeWorldClockTool.optionKey(id),
                    title: LumeWorldClock.isolate(
                      LumeZoneLabels.of(id, language: language).display,
                    ),
                    subtitle: LumeWorldClock.isolate(id),
                    selected: id == current,
                    isLast: i == listed.length - 1,
                    onTap: () => Navigator.of(sheet).pop(id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _session.write(LumeWorldClockTool.id, key, picked);
    setState(() {});
  }

  Future<void> _pickAt(
    AppLocalizations l,
    String Function(int minutes) clockOf,
  ) async {
    const int step = 30;
    final int? picked = await showLumeSheet<int>(
      context: context,
      barrierLabel: l.clockConvertAt,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          tall: true,
          title: l.clockConvertAt,
          child: SingleChildScrollView(
            child: LumeOptionList(
              label: l.clockConvertAt,
              children: <LumeOptionRow>[
                for (int m = 0; m < 24 * 60; m += step)
                  LumeOptionRow(
                    key: LumeWorldClockTool.optionKey('$m'),
                    title: LumeWorldClock.isolate(clockOf(m)),
                    selected: false,
                    isLast: m + step >= 24 * 60,
                    onTap: () => Navigator.of(sheet).pop(m),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _session.write(LumeWorldClockTool.id, LumeWorldClockTool.atKey, '$picked');
    setState(() {});
  }
}
