/// The flight board — `tool-data.js` `FLIGHTS`, typed.
///
/// Five flights with their airline, aircraft and registration, the two ends,
/// the timetable and what actually happened, a status, and where each one is.
/// Names of airlines, airports and aircraft are proper names and stay as the
/// data writes them; times are the operators' 24-hour strings.
///
/// **Dayroz obligation:** every figure here is fixture data under a "Live"
/// label the reference gives it (C73). A board needs a licensed flight-status
/// feed with its observation time, and positions from a real ADS-B source.
library;

import 'package:flutter/foundation.dart';

import '../../../core/widgets/lume/lume_badge.dart';

/// `tone` — the airline tile's wash.
enum LumeAirlineTone { rose, green, violet, amber, indigo }

/// `statusKey`, and the badge each status wears (`tone2`).
enum LumeFlightStatus {
  enroute(LumeBadgeTone.live),
  landed(LumeBadgeTone.ok),
  delayed(LumeBadgeTone.late_),
  scheduled(LumeBadgeTone.info);

  const LumeFlightStatus(this.badge);

  final LumeBadgeTone badge;
}

@immutable
class LumeFlight {
  const LumeFlight({
    required this.no,
    required this.airline,
    required this.logo,
    required this.tone,
    required this.craft,
    required this.reg,
    required this.fromCode,
    required this.from,
    required this.toCode,
    required this.to,
    required this.dep,
    required this.arr,
    required this.actual,
    required this.status,
    required this.delay,
    required this.alt,
    required this.speed,
    required this.progress,
    required this.gate,
    required this.term,
    required this.dist,
    required this.eta,
  });

  final String no;
  final String airline;
  final String logo;
  final LumeAirlineTone tone;
  final String craft;
  final String reg;
  final String fromCode;
  final String from;
  final String toCode;
  final String to;
  final String dep;
  final String arr;
  final String actual;
  final LumeFlightStatus status;

  /// Minutes late.
  final int delay;

  /// Feet.
  final int alt;

  /// Kilometres an hour.
  final int speed;

  final double progress;
  final String gate;
  final String term;

  /// Kilometres.
  final int dist;

  final String eta;

  /// `tone2 === 'live'`.
  bool get live => status.badge == LumeBadgeTone.live;
}

abstract final class LumeFlightBoard {
  static const List<LumeFlight> flights = <LumeFlight>[
    LumeFlight(
      no: 'EK 624',
      airline: 'Emirates',
      logo: 'EK',
      tone: LumeAirlineTone.rose,
      craft: 'Boeing 777-300ER',
      reg: 'A6-EQK',
      fromCode: 'DXB',
      from: 'Dubai Intl',
      toCode: 'ISB',
      to: 'Islamabad Intl',
      dep: '03:35',
      arr: '08:05',
      actual: '03:52',
      status: LumeFlightStatus.enroute,
      delay: 17,
      alt: 38000,
      speed: 902,
      progress: 0.62,
      gate: 'C12',
      term: '3',
      dist: 2038,
      eta: '08:22',
    ),
    LumeFlight(
      no: 'PK 309',
      airline: 'Pakistan Intl',
      logo: 'PK',
      tone: LumeAirlineTone.green,
      craft: 'Airbus A320',
      reg: 'AP-BOL',
      fromCode: 'KHI',
      from: 'Jinnah Intl',
      toCode: 'LHE',
      to: 'Allama Iqbal Intl',
      dep: '07:00',
      arr: '08:45',
      actual: '07:00',
      status: LumeFlightStatus.landed,
      delay: 0,
      alt: 0,
      speed: 0,
      progress: 1,
      gate: 'A4',
      term: 'M',
      dist: 1024,
      eta: '08:41',
    ),
    LumeFlight(
      no: 'QR 614',
      airline: 'Qatar Airways',
      logo: 'QR',
      tone: LumeAirlineTone.violet,
      craft: 'Boeing 787-8',
      reg: 'A7-BCF',
      fromCode: 'DOH',
      from: 'Hamad Intl',
      toCode: 'LHE',
      to: 'Allama Iqbal Intl',
      dep: '02:10',
      arr: '08:30',
      actual: '02:44',
      status: LumeFlightStatus.delayed,
      delay: 34,
      alt: 36000,
      speed: 874,
      progress: 0.41,
      gate: 'B8',
      term: '1',
      dist: 2384,
      eta: '09:04',
    ),
    LumeFlight(
      no: 'TK 710',
      airline: 'Turkish Airlines',
      logo: 'TK',
      tone: LumeAirlineTone.amber,
      craft: 'Airbus A321neo',
      reg: 'TC-LSK',
      fromCode: 'IST',
      from: 'Istanbul',
      toCode: 'KHI',
      to: 'Jinnah Intl',
      dep: '20:15',
      arr: '05:40',
      actual: '20:15',
      status: LumeFlightStatus.scheduled,
      delay: 0,
      alt: 0,
      speed: 0,
      progress: 0,
      gate: 'F22',
      term: 'I',
      dist: 4102,
      eta: '05:40',
    ),
    LumeFlight(
      no: 'BA 262',
      airline: 'British Airways',
      logo: 'BA',
      tone: LumeAirlineTone.indigo,
      craft: 'Boeing 787-9',
      reg: 'G-ZBKA',
      fromCode: 'LHR',
      from: 'Heathrow',
      toCode: 'ISB',
      to: 'Islamabad Intl',
      dep: '21:40',
      arr: '10:15',
      actual: '21:58',
      status: LumeFlightStatus.enroute,
      delay: 18,
      alt: 40000,
      speed: 918,
      progress: 0.78,
      gate: '14',
      term: '5',
      dist: 5794,
      eta: '10:33',
    ),
  ];
}
