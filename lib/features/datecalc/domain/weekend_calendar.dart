/// Which days count as the weekend, for a country on a date (F6B closure).
///
/// The reference counts Saturday and Sunday everywhere. That is kept, as a
/// fixture that says it is one, behind a contract a real calendar replaces:
/// weekends differ by country — Friday–Saturday in much of the Gulf, Friday
/// alone in some places — and a country can change its weekend on a date, as
/// the UAE did in 2022. Lume invents none of those rules; Dayroz's country
/// calendar supplies them through [weekendCalendarProvider].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The weekend rule, asked one day at a time.
abstract interface class LumeWeekendCalendar {
  /// Whether [day] is a weekend day in [countryCode] (ISO 3166-1 alpha-2).
  bool isWeekend(String countryCode, DateTime day);

  /// This rule is the reference's own fixture, not a country's calendar.
  bool get isReferenceFixture;
}

/// The same weekdays for every country and every date.
@immutable
class LumeFixedWeekend implements LumeWeekendCalendar {
  const LumeFixedWeekend(this.weekdays, {this.isReferenceFixture = false});

  /// `context.js` `dateCalc()`: `d.getDay() === 0 || d.getDay() === 6`.
  static const LumeFixedWeekend reference = LumeFixedWeekend(<int>{
    DateTime.saturday,
    DateTime.sunday,
  }, isReferenceFixture: true);

  /// [DateTime.weekday] values.
  final Set<int> weekdays;

  @override
  final bool isReferenceFixture;

  @override
  bool isWeekend(String countryCode, DateTime day) =>
      weekdays.contains(day.weekday);
}

/// The weekend rule the Date Calculator counts with. This build has only the
/// reference's fixture; a country calendar overrides it.
final Provider<LumeWeekendCalendar> weekendCalendarProvider =
    Provider<LumeWeekendCalendar>((Ref ref) => LumeFixedWeekend.reference);
