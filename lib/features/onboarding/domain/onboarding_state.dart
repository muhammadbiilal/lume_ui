/// The onboarding draft, the step machine, and what onboarding is allowed to
/// persist.
///
/// The prototype keeps two things: `lume-onboarded`, a completion marker, and
/// `lume-profile`, the personalisation record. This models both, plus the two
/// things the prototype's set-up step collects and then throws away — see
/// ONBOARDING_INVENTORY F1.
///
/// **Nothing here writes.** The draft is a value; [LumeOnboardingStore] is the
/// interface a persistence layer implements, and the only implementation in
/// this repository keeps it in memory. Dayroz supplies the real one at
/// integration, and the contract it has to satisfy is the tests in
/// `onboarding_state_test.dart`.
///
/// **Three rules run through all of it**, and each has a test:
///
/// * Religion is never inferred from country or language. The only thing that
///   turns the Islamic experience on is choosing an Islamic interest or the
///   switch above them.
/// * A partially-made choice is not a preference. The draft is committed at
///   the points the prototype commits it, and not before.
/// * A migration runs once, and says so in a marker, so a user who has turned
///   something off does not find it back on next launch.
library;

import 'package:flutter/foundation.dart';

import '../../../l10n/app_localizations.dart';

export 'onboarding_steps_ids.dart';

/// The prayer calculation methods the set-up step offers.
///
/// Five literal `<button>`s in the prototype with no ids and no `data-i18n`,
/// and the first is marked active whatever `profile.method` holds — see
/// ONBOARDING_INVENTORY F3. They get ids here so the stored value and the
/// rendered selection can agree.
enum LumePrayerMethod {
  karachi('Karachi'),
  mwl('MWL'),
  isna('ISNA'),
  ummAlQura('UmmAlQura'),
  egyptian('Egyptian');

  const LumePrayerMethod(this.id);

  /// The value stored in the profile. `MWL` is `app-store.js`'s default.
  final String id;

  static const String defaultId = 'MWL';

  static LumePrayerMethod fromId(String id) =>
      values.firstWhere((LumePrayerMethod m) => m.id == id, orElse: () => mwl);

  String label(AppLocalizations l) => switch (this) {
    karachi => l.methodKarachi,
    mwl => l.methodMwl,
    isna => l.methodIsna,
    ummAlQura => l.methodUmmAlQura,
    egyptian => l.methodEgyptian,
  };

  /// In the order the prototype lists them.
  static List<LumeChoiceOptionData> optionsFor(AppLocalizations l) =>
      <LumeChoiceOptionData>[
        for (final LumePrayerMethod m in values) (id: m.id, label: m.label(l)),
      ];
}

/// What a choice pill needs. A record rather than a class so the presentation
/// layer's own option type stays in the presentation layer.
typedef LumeChoiceOptionData = ({String id, String label});

/// Everything the flow has collected.
@immutable
class LumeOnboardingDraft {
  const LumeOnboardingDraft({
    this.country = 'PK',
    this.region,
    this.city = '',
    this.interests = const <String>{},
    this.islamic = false,
    this.displayName = '',
    this.method = LumePrayerMethod.defaultId,
    this.wantsLocation = true,
    this.wantsReminders = true,
  });

  final String country;
  final String? region;
  final String city;

  final Set<String> interests;

  /// Never inferred. Set by the interests step's switch, or by choosing any
  /// interest in the faith group.
  final bool islamic;

  final String displayName;
  final String method;

  /// The two set-up toggles, which are **intent** rather than permission. A
  /// real permission is requested by the platform at the moment it is needed;
  /// recording "yes, ask me" on a slide is all a slide can honestly do.
  final bool wantsLocation;
  final bool wantsReminders;

  LumeOnboardingDraft copyWith({
    String? country,
    String? region,
    bool clearRegion = false,
    String? city,
    Set<String>? interests,
    bool? islamic,
    String? displayName,
    String? method,
    bool? wantsLocation,
    bool? wantsReminders,
  }) => LumeOnboardingDraft(
    country: country ?? this.country,
    region: clearRegion ? null : (region ?? this.region),
    city: city ?? this.city,
    interests: interests ?? this.interests,
    islamic: islamic ?? this.islamic,
    displayName: displayName ?? this.displayName,
    method: method ?? this.method,
    wantsLocation: wantsLocation ?? this.wantsLocation,
    wantsReminders: wantsReminders ?? this.wantsReminders,
  );

  @override
  bool operator ==(Object other) =>
      other is LumeOnboardingDraft &&
      other.country == country &&
      other.region == region &&
      other.city == city &&
      setEquals(other.interests, interests) &&
      other.islamic == islamic &&
      other.displayName == displayName &&
      other.method == method &&
      other.wantsLocation == wantsLocation &&
      other.wantsReminders == wantsReminders;

  @override
  int get hashCode => Object.hash(
    country,
    region,
    city,
    Object.hashAllUnordered(interests),
    islamic,
    displayName,
    method,
    wantsLocation,
    wantsReminders,
  );
}

/// The personalisation record onboarding reads and writes.
@immutable
class LumeProfileRecord {
  const LumeProfileRecord({
    this.country = 'PK',
    this.region = 'Islamabad Capital Territory',
    this.city = 'Islamabad',
    this.interests = const <String>[],
    this.islamic,
    this.displayName = '',
    this.method = LumePrayerMethod.defaultId,
    this.wantsLocation = true,
    this.wantsReminders = true,
    this.onboarded = false,
    this.migrations = const <String>{},
  });

  final String country;
  final String region;
  final String city;
  final List<String> interests;

  /// **Nullable on purpose.** `null` means "never expressed" and is what an
  /// existing user without a saved value looks like; `false` means "asked for
  /// off". The grandfathering rule turns only the first into a decision.
  final bool? islamic;

  final String displayName;
  final String method;
  final bool wantsLocation;
  final bool wantsReminders;

  /// `lume-onboarded`.
  final bool onboarded;

  /// Which one-shot migrations have already run. A marker per migration, so
  /// adding a second one later cannot re-run the first.
  final Set<String> migrations;

  LumeProfileRecord copyWith({
    String? country,
    String? region,
    String? city,
    List<String>? interests,
    bool? islamic,
    bool clearIslamic = false,
    String? displayName,
    String? method,
    bool? wantsLocation,
    bool? wantsReminders,
    bool? onboarded,
    Set<String>? migrations,
  }) => LumeProfileRecord(
    country: country ?? this.country,
    region: region ?? this.region,
    city: city ?? this.city,
    interests: interests ?? this.interests,
    islamic: clearIslamic ? null : (islamic ?? this.islamic),
    displayName: displayName ?? this.displayName,
    method: method ?? this.method,
    wantsLocation: wantsLocation ?? this.wantsLocation,
    wantsReminders: wantsReminders ?? this.wantsReminders,
    onboarded: onboarded ?? this.onboarded,
    migrations: migrations ?? this.migrations,
  );
}

/// Where the record lives. Implemented in memory here; by Dayroz later.
abstract interface class LumeOnboardingStore {
  LumeProfileRecord read();
  void write(LumeProfileRecord record);
}

/// The in-memory implementation the fixture app runs on.
class LumeMemoryOnboardingStore implements LumeOnboardingStore {
  LumeMemoryOnboardingStore([LumeProfileRecord? initial])
    : _record = initial ?? const LumeProfileRecord();

  LumeProfileRecord _record;

  @override
  LumeProfileRecord read() => _record;

  @override
  void write(LumeProfileRecord record) => _record = record;
}

/// The rules the flow obeys, as functions rather than as a widget.
abstract final class LumeOnboardingState {
  /// `maxlength="40"` on the name field, and the same cap `commitName` applies.
  static const int nameMaxLength = 40;

  /// `DEFAULT_INTERESTS` — what a skipped picker falls back to.
  static const List<String> defaultInterests = <String>[
    'weather',
    'calendar',
    'tasks',
    'notes',
    'maths',
    'expenses',
    'news',
  ];

  /// `FAITH_INTERESTS`.
  static const Set<String> faithInterests = <String>{
    'prayer',
    'quran',
    'hadith',
    'duas',
    'zakat',
    'ramadan',
  };

  /// The marker the one-shot Islamic migration writes.
  static const String islamicMigration = 'islamic-default-2026-09';

  /// A draft seeded from the stored record, which is what reopening the flow
  /// does — `onbStart` re-reads the profile rather than keeping the last run's.
  static LumeOnboardingDraft draftFrom(LumeProfileRecord r) =>
      LumeOnboardingDraft(
        country: r.country,
        region: r.region,
        city: r.city,
        interests: r.interests.toSet(),
        // A record that never expressed a preference is off in the draft, and
        // stays "never expressed" in the record until something sets it.
        islamic: r.islamic ?? false,
        displayName: r.displayName,
        method: r.method,
        wantsLocation: r.wantsLocation,
        wantsReminders: r.wantsReminders,
      );

  /// Choosing any interest in the faith group turns the experience on.
  ///
  /// `syncFaithFromInterests`: it turns it **on** and never off, so an explicit
  /// `true` survives a selection that happens to hold none.
  static bool faithFrom(Set<String> interests, {required bool current}) =>
      current || interests.any(faithInterests.contains);

  /// What a completed flow writes.
  ///
  /// The whole draft lands at once, which is the point at which a set of
  /// half-made choices becomes a preference.
  static LumeProfileRecord commit(
    LumeProfileRecord record,
    LumeOnboardingDraft draft,
  ) => record.copyWith(
    country: draft.country,
    region: draft.region ?? record.region,
    city: draft.city.isEmpty ? record.city : draft.city,
    interests: draft.interests.toList(),
    islamic: faithFrom(draft.interests, current: draft.islamic),
    displayName: draft.displayName,
    method: draft.method,
    wantsLocation: draft.wantsLocation,
    wantsReminders: draft.wantsReminders,
    onboarded: true,
  );

  /// What the header's Skip writes.
  ///
  /// `onbSkip`: a user who has chosen nothing gets the general defaults and
  /// **`islamic: false`** — the one place the flow writes a faith value
  /// without being asked, and it writes the neutral one. A user who has
  /// already chosen keeps what they chose.
  static LumeProfileRecord skip(
    LumeProfileRecord record,
    LumeOnboardingDraft draft,
  ) {
    if (draft.interests.isEmpty && record.interests.isEmpty) {
      return record.copyWith(
        interests: defaultInterests,
        islamic: false,
        onboarded: true,
      );
    }
    return record.copyWith(onboarded: true);
  }

  /// The one-shot Islamic-content migration.
  ///
  /// Three populations, three answers:
  ///
  /// * **A fresh install** has no record to migrate. `islamic` stays `null`
  ///   until the flow sets it, and everything downstream reads `null` as off.
  /// * **An existing user with a saved value** keeps it, whichever way it
  ///   points. This is the case the marker exists to protect: without it, a
  ///   user who turned the experience off would find it back on.
  /// * **An existing user with no saved value** is grandfathered from what
  ///   they already chose — if any stored interest is in the faith group they
  ///   plainly asked for it, so it becomes `true`; otherwise `false`. Country
  ///   and language are not consulted.
  ///
  /// Runs once. The marker is written whether or not anything changed, so the
  /// decision is made exactly one time.
  static LumeProfileRecord migrateIslamicDefault(LumeProfileRecord record) {
    if (record.migrations.contains(islamicMigration)) return record;

    final Set<String> migrations = <String>{
      ...record.migrations,
      islamicMigration,
    };

    // Never onboarded and nothing stored: a fresh install. Mark it and leave
    // the value unexpressed.
    if (!record.onboarded && record.interests.isEmpty) {
      return record.copyWith(migrations: migrations);
    }

    if (record.islamic != null) {
      return record.copyWith(migrations: migrations);
    }

    return record.copyWith(
      islamic: record.interests.any(faithInterests.contains),
      migrations: migrations,
    );
  }

  /// Turning the Islamic experience off removes the faith interests and
  /// **nothing else**.
  static Set<String> withoutFaith(Set<String> interests) =>
      interests.where((String id) => !faithInterests.contains(id)).toSet();

  /// Whether the flow should be shown at all.
  ///
  /// `forced` is the prototype's `?tour=1` and the Profile screen's replay: a
  /// completed flow does not reappear unless something explicitly restarts it.
  static bool shouldShow(LumeProfileRecord record, {bool forced = false}) =>
      forced || !record.onboarded;
}
