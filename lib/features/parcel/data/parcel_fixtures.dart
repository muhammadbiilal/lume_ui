/// Two parcels in transit — `tool-data.js` `PARCELS`, typed.
///
/// The reference's tracking field and its "Track" button take no tracking
/// number at all: `pc_ref` is read by nothing, and the button's own action is
/// `toast:` a fixed line ("Looking up the shipment") that never changes with
/// what was typed and never resolves into a result. "Notify on updates" is
/// the same shape — "You'll be notified on every update", and nothing is.
/// Here the field and the buttons exist because the reference draws them,
/// and each button says Lume can't reach couriers or follow a shipment yet,
/// rather than claiming it is doing either.
///
/// Selecting a row is the one real interaction (`toolstate:parcel:parcel:
/// {ref}`) — it swaps which of these two fixture parcels the detail below the
/// list describes. There is no way, in the reference, for the reader to add a
/// parcel of their own; this is fixture display, not a record family.
///
/// **Dayroz obligation:** every parcel, every event and every ETA here is
/// fixture data. A real tracker needs each carrier's own tracking API (TCS's
/// and Leopards' here), reachable by the number the reader actually typed,
/// with its own delivery events and their own timestamps — not a script.
library;

import 'package:flutter/foundation.dart';

import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_progress.dart' show LumeTimelineState;

/// `tone` — the row's logo tile.
enum LumeParcelTone { amber, rose }

/// The words a stage carries, in both the list's badge and the timeline's
/// titles. `parcel.js` writes these as plain strings; naming them here is
/// what lets one label serve both places without repeating itself.
enum LumeParcelStage {
  booked,
  inTransit,
  arrived,
  outForDelivery,
  delivered,
  arriving,
}

@immutable
class LumeParcelEvent {
  const LumeParcelEvent({
    required this.stage,
    required this.place,
    required this.time,
    required this.state,
  });

  final LumeParcelStage stage;

  /// A place name — a proper noun, kept as the fixture writes it.
  final String place;

  /// The fixture's own clock string ("4 Sep, 14:10", "Today, 09:12",
  /// "Expected today") — written, not computed, exactly as Flights keeps its
  /// timetable strings.
  final String time;

  final LumeTimelineState state;
}

@immutable
class LumeParcel {
  const LumeParcel({
    required this.ref,
    required this.carrier,
    required this.logo,
    required this.tone,
    required this.item,
    required this.stage,
    required this.badge,
    required this.place,
    required this.eta,
    required this.progress,
    required this.events,
  });

  /// The tracking number — a proper identifier, kept as written.
  final String ref;
  final String carrier;

  /// The row's logo tile initials.
  final String logo;
  final LumeParcelTone tone;

  final String item;

  /// The parcel's current stage — the same word as its "now" event.
  final LumeParcelStage stage;

  /// `x.state` — the list badge's tone ('live' for the one out for delivery,
  /// 'info' for the one still moving between hubs).
  final LumeBadgeTone badge;

  /// Last seen.
  final String place;
  final String eta;

  /// 0–1.
  final double progress;

  final List<LumeParcelEvent> events;
}

abstract final class LumeParcelBoard {
  static const List<LumeParcel> parcels = <LumeParcel>[
    LumeParcel(
      ref: 'TCS-8842910',
      carrier: 'TCS',
      logo: 'TC',
      tone: LumeParcelTone.amber,
      item: 'Keyboard',
      stage: LumeParcelStage.outForDelivery,
      badge: LumeBadgeTone.live,
      place: 'Islamabad hub',
      eta: 'Today, by 18:00',
      progress: 0.85,
      events: <LumeParcelEvent>[
        LumeParcelEvent(
          stage: LumeParcelStage.booked,
          place: 'Karachi',
          time: '4 Sep, 14:10',
          state: LumeTimelineState.done,
        ),
        LumeParcelEvent(
          stage: LumeParcelStage.inTransit,
          place: 'Lahore hub',
          time: '5 Sep, 03:20',
          state: LumeTimelineState.done,
        ),
        LumeParcelEvent(
          stage: LumeParcelStage.arrived,
          place: 'Islamabad hub',
          time: '6 Sep, 07:45',
          state: LumeTimelineState.done,
        ),
        LumeParcelEvent(
          stage: LumeParcelStage.outForDelivery,
          place: 'Islamabad',
          time: 'Today, 09:12',
          state: LumeTimelineState.now,
        ),
        LumeParcelEvent(
          stage: LumeParcelStage.delivered,
          place: 'Islamabad',
          time: 'Expected today',
          state: LumeTimelineState.upcoming,
        ),
      ],
    ),
    LumeParcel(
      ref: 'LP-5521773',
      carrier: 'Leopards',
      logo: 'LP',
      tone: LumeParcelTone.rose,
      item: 'Books',
      stage: LumeParcelStage.inTransit,
      badge: LumeBadgeTone.info,
      place: 'Multan hub',
      eta: 'Wed, 10 Sep',
      progress: 0.45,
      events: <LumeParcelEvent>[
        LumeParcelEvent(
          stage: LumeParcelStage.booked,
          place: 'Karachi',
          time: '6 Sep, 11:00',
          state: LumeTimelineState.done,
        ),
        LumeParcelEvent(
          stage: LumeParcelStage.inTransit,
          place: 'Multan hub',
          time: 'Today, 04:30',
          state: LumeTimelineState.now,
        ),
        LumeParcelEvent(
          stage: LumeParcelStage.arriving,
          place: 'Islamabad',
          time: 'Expected 10 Sep',
          state: LumeTimelineState.upcoming,
        ),
      ],
    ),
  ];
}
