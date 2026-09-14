/// What the Calendar shows — `context.js` `calendar()` and `tool-data.js`
/// `HOLIDAYS`, typed.
///
/// The agenda is the reference's three fixed items; a Muslim reader's next
/// prayer joins it, computed from the sun ([LumeSolar]). The holidays are the
/// first four of the country's table in the table's own order, or the global
/// three.
///
/// **Dayroz obligations:** the agenda is fixture content with no store; the
/// holiday table is undated reference data — a real calendar needs the
/// reader's own events, a dated holiday source per country and region, and
/// the observed Islamic dates each year.
library;

import 'package:flutter/foundation.dart';

import '../../../core/icons/lume_icons.dart';

enum LumeHolidayKind { national, federal, bank, public, gazetted }

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

  final int month;
  final int day;
  final LumeHolidayName name;
  final LumeHolidayKind kind;
}

/// Where an agenda item sits relative to now — `state`.
enum LumeAgendaState { done, now, upcoming }

@immutable
class LumeCalendarItem {
  const LumeCalendarItem({
    required this.id,
    required this.hour,
    required this.minute,
    required this.state,
    required this.icon,
  });

  /// Stable, and the key its title and place are written under.
  final String id;
  final int hour;
  final int minute;
  final LumeAgendaState state;
  final String icon;

  int get minutes => hour * 60 + minute;
}

abstract final class LumeCalendarFixtures {
  /// `calendar().agenda` — before a prayer joins it.
  static const List<LumeCalendarItem> agenda = <LumeCalendarItem>[
    LumeCalendarItem(
      id: 'standup',
      hour: 9,
      minute: 0,
      state: LumeAgendaState.done,
      icon: LumeIcons.checkCircle,
    ),
    LumeCalendarItem(
      id: 'review',
      hour: 14,
      minute: 0,
      state: LumeAgendaState.now,
      icon: LumeIcons.users,
    ),
    LumeCalendarItem(
      id: 'groceries',
      hour: 18,
      minute: 30,
      state: LumeAgendaState.upcoming,
      icon: LumeIcons.cart,
    ),
  ];

  static const Map<String, List<LumeHoliday>>
  _holidays = <String, List<LumeHoliday>>{
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

  /// `HOLIDAYS_FALLBACK`.
  static const List<LumeHoliday> fallback = <LumeHoliday>[
    LumeHoliday(1, 1, LumeHolidayName.newYearsDay, LumeHolidayKind.public),
    LumeHoliday(12, 25, LumeHolidayName.christmasDay, LumeHolidayKind.public),
    LumeHoliday(5, 1, LumeHolidayName.labourDay, LumeHolidayKind.public),
  ];

  /// `holidaysFor(code).slice(0, 4)`.
  static List<LumeHoliday> holidaysFor(String code) =>
      (_holidays[code.toUpperCase()] ?? fallback).take(4).toList();

  /// `D.holidaysFor(country).length` — the whole list, which Date Calculator
  /// counts, not the four the calendar shows.
  static int holidayCountFor(String code) =>
      (_holidays[code.toUpperCase()] ?? fallback).length;
}
