/// Public holidays — `tools/daily/holidays.tool.js` over `tool-data.js`
/// `HOLIDAYS` / `HOLIDAYS_FALLBACK`, typed.
///
/// Six country tables (`PK`, `US`, `GB`, `AE`, `SA`, `IN`) of `[date, name,
/// kind]` tuples, plus a three-entry global fallback for every other market —
/// ported here as month/day pairs against the same [LumeHolidayName] and
/// [LumeHolidayKind] shape `calendar_fixtures.dart` already gives this exact
/// table for its own "next holidays" strip. The two copies are deliberate:
/// each tool owns its data so neither can be broken by a change made for the
/// other, and this one is the primary, full-list presentation of it.
///
/// **Which year is this for?** `HOLIDAYS` gives no year at all — every entry
/// is a bare "9 Nov" or "25 Dec", never "9 Nov 2025". And its movable
/// holidays don't even agree on a single year: the UK's Good Friday (18 Apr),
/// Early May (5 May) and Summer (25 Aug) bank holidays are 2025's; the US's
/// Thanksgiving (28 Nov) is 2024's; India's Holi (14 Mar) and Diwali (20 Oct)
/// are 2025's. A table stitched together from two different real years is
/// not "this year's calendar" for either of them, so nothing here claims one
/// — [LumeHolidaysFixtures] is presented as illustrative reference data, not
/// a dated calendar, and the tool says so on screen (`holidaysNoteText`).
///
/// **Dayroz obligation:** a real Public Holidays feature needs a licensed,
/// annually-updated public-holidays calendar per country (a government
/// gazette feed or a commercial holidays API), region-aware where a country
/// observes different holidays by state or province. Its lunar-calendar
/// entries — Eid al-Fitr, Eid al-Adha, Islamic New Year — move against the
/// Gregorian calendar every year and can never be safely projected forward
/// from a fixed month/day the way a fixed-date national holiday can; they
/// need the same real, observation-based Islamic date source the rest of
/// Lume's Islamic experience needs, not a rule computed here.
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';

enum LumeHolidayKind { national, federal, bank, public, gazetted }

/// Every holiday name across the six tables — resolved to the reader's
/// language through the existing `holiday*` reference strings
/// (`holidayIqbalDay`, `holidayThanksgiving`, …), the same generic keys
/// `calendar_fixtures.dart`'s own list already reuses (§47: one name, shared).
enum LumeHolidayName {
  iqbalDay,
  quaidDay,
  kashmirDay,
  pakistanDay,
  labourDay,
  independenceDay,
  thanksgiving,
  christmasDay,
  newYearsDay,
  mlkDay,
  laborDay,
  boxingDay,
  goodFriday,
  earlyMay,
  summer,
  nationalDay,
  eidAlFitr,
  eidAlAdha,
  islamicNewYear,
  commemorationDay,
  foundingDay,
  gandhiJayanti,
  christmas,
  republicDay,
  holi,
  diwali,
}

@immutable
class LumeHoliday {
  const LumeHoliday(this.month, this.day, this.name, this.kind);

  /// 1–12, no year — see the class doc for why.
  final int month;
  final int day;
  final LumeHolidayName name;
  final LumeHolidayKind kind;
}

abstract final class LumeHolidaysFixtures {
  static const Map<String, List<LumeHoliday>>
  _byCountry = <String, List<LumeHoliday>>{
    'PK': <LumeHoliday>[
      LumeHoliday(11, 9, LumeHolidayName.iqbalDay, LumeHolidayKind.national),
      LumeHoliday(12, 25, LumeHolidayName.quaidDay, LumeHolidayKind.national),
      LumeHoliday(2, 5, LumeHolidayName.kashmirDay, LumeHolidayKind.national),
      LumeHoliday(3, 23, LumeHolidayName.pakistanDay, LumeHolidayKind.national),
      LumeHoliday(5, 1, LumeHolidayName.labourDay, LumeHolidayKind.national),
      LumeHoliday(
        8,
        14,
        LumeHolidayName.independenceDay,
        LumeHolidayKind.national,
      ),
    ],
    'US': <LumeHoliday>[
      LumeHoliday(
        11,
        28,
        LumeHolidayName.thanksgiving,
        LumeHolidayKind.federal,
      ),
      LumeHoliday(
        12,
        25,
        LumeHolidayName.christmasDay,
        LumeHolidayKind.federal,
      ),
      LumeHoliday(1, 1, LumeHolidayName.newYearsDay, LumeHolidayKind.federal),
      LumeHoliday(1, 20, LumeHolidayName.mlkDay, LumeHolidayKind.federal),
      LumeHoliday(
        7,
        4,
        LumeHolidayName.independenceDay,
        LumeHolidayKind.federal,
      ),
      LumeHoliday(9, 2, LumeHolidayName.laborDay, LumeHolidayKind.federal),
    ],
    'GB': <LumeHoliday>[
      LumeHoliday(12, 25, LumeHolidayName.christmasDay, LumeHolidayKind.bank),
      LumeHoliday(12, 26, LumeHolidayName.boxingDay, LumeHolidayKind.bank),
      LumeHoliday(1, 1, LumeHolidayName.newYearsDay, LumeHolidayKind.bank),
      LumeHoliday(4, 18, LumeHolidayName.goodFriday, LumeHolidayKind.bank),
      LumeHoliday(5, 5, LumeHolidayName.earlyMay, LumeHolidayKind.bank),
      LumeHoliday(8, 25, LumeHolidayName.summer, LumeHolidayKind.bank),
    ],
    'AE': <LumeHoliday>[
      LumeHoliday(12, 2, LumeHolidayName.nationalDay, LumeHolidayKind.public),
      LumeHoliday(1, 1, LumeHolidayName.newYearsDay, LumeHolidayKind.public),
      LumeHoliday(3, 30, LumeHolidayName.eidAlFitr, LumeHolidayKind.public),
      LumeHoliday(6, 6, LumeHolidayName.eidAlAdha, LumeHolidayKind.public),
      LumeHoliday(
        6,
        26,
        LumeHolidayName.islamicNewYear,
        LumeHolidayKind.public,
      ),
      LumeHoliday(
        12,
        1,
        LumeHolidayName.commemorationDay,
        LumeHolidayKind.public,
      ),
    ],
    'SA': <LumeHoliday>[
      LumeHoliday(9, 23, LumeHolidayName.nationalDay, LumeHolidayKind.public),
      LumeHoliday(2, 22, LumeHolidayName.foundingDay, LumeHolidayKind.public),
      LumeHoliday(3, 30, LumeHolidayName.eidAlFitr, LumeHolidayKind.public),
      LumeHoliday(6, 6, LumeHolidayName.eidAlAdha, LumeHolidayKind.public),
    ],
    'IN': <LumeHoliday>[
      LumeHoliday(
        10,
        2,
        LumeHolidayName.gandhiJayanti,
        LumeHolidayKind.gazetted,
      ),
      LumeHoliday(12, 25, LumeHolidayName.christmas, LumeHolidayKind.gazetted),
      LumeHoliday(1, 26, LumeHolidayName.republicDay, LumeHolidayKind.gazetted),
      LumeHoliday(
        8,
        15,
        LumeHolidayName.independenceDay,
        LumeHolidayKind.gazetted,
      ),
      LumeHoliday(3, 14, LumeHolidayName.holi, LumeHolidayKind.gazetted),
      LumeHoliday(10, 20, LumeHolidayName.diwali, LumeHolidayKind.gazetted),
    ],
  };

  /// `HOLIDAYS_FALLBACK` — every market without its own table.
  static const List<LumeHoliday> fallback = <LumeHoliday>[
    LumeHoliday(1, 1, LumeHolidayName.newYearsDay, LumeHolidayKind.public),
    LumeHoliday(12, 25, LumeHolidayName.christmasDay, LumeHolidayKind.public),
    LumeHoliday(5, 1, LumeHolidayName.labourDay, LumeHolidayKind.public),
  ];

  /// `holidaysFor(code)` — the country's own table, in the table's own
  /// order, or [fallback].
  static List<LumeHoliday> holidaysFor(String countryCode) =>
      _byCountry[countryCode.toUpperCase()] ?? fallback;

  /// The distinct kinds in [list], first-seen order — `kinds` in the
  /// reference's `build()`.
  static List<LumeHolidayKind> kindsOf(List<LumeHoliday> list) =>
      LinkedHashSet<LumeHolidayKind>.of(
        list.map((LumeHoliday h) => h.kind),
      ).toList();
}
