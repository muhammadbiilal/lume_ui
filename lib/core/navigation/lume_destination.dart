/// The destination set — one definition, three presentations.
///
/// The reference's whole navigation discipline is in one sentence of
/// `shell.js`: *both bars are drawn from the same `tabOrder()`, carry the same
/// `data-tab` and the same class, so the router selects a destination once
/// rather than keeping three navigations in step by hand.*
///
/// This is that, typed. A destination's route, label, icon, selected icon,
/// eligibility, badge, branch index and semantic label are declared **here and
/// nowhere else**; the bottom bar, the rail and the sidebar all render the same
/// list. There is no way for them to disagree, because there is nothing for
/// them to disagree about.
///
/// **Never more than five** (§6). The tab set is personalised, so it is a
/// question rather than a constant — which is why [LumeDestinations.forCountry]
/// takes a country and returns a list, instead of there being a `const` one.
library;

import 'package:flutter/widgets.dart';

import '../icons/lume_icons.dart';

/// Every destination that can be primary, as an identity rather than a string.
enum LumeDestinationId {
  home,
  tools,
  trains,
  today,
  explore,
  profile;

  /// The route path. `/home`, `/tools`, …
  String get path => '/$name';
}

/// One primary destination.
@immutable
class LumeDestination {
  const LumeDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.semanticLabel,
    this.badgeCount,
    this.showDot = false,
  });

  final LumeDestinationId id;

  /// The visible label, already localised by whoever built the list.
  final String label;

  /// The glyph. The reference uses one icon per destination in both states —
  /// selection is carried by colour and the pill, not by a filled variant.
  final String icon;

  /// What a screen reader says. Usually the label, but a destination carrying
  /// a badge says the count too.
  final String semanticLabel;

  /// A number on the destination. `null` for none.
  final int? badgeCount;

  /// An unread marker with no number.
  final bool showDot;

  String get path => id.path;

  bool get hasBadge => showDot || (badgeCount != null && badgeCount! > 0);

  LumeDestination copyWith({int? badgeCount, bool? showDot}) => LumeDestination(
    id: id,
    label: label,
    icon: icon,
    semanticLabel: semanticLabel,
    badgeCount: badgeCount ?? this.badgeCount,
    showDot: showDot ?? this.showDot,
  );
}

/// Builds the destination set for a user.
abstract final class LumeDestinations {
  /// §6: never more than five.
  static const int maximum = 5;

  /// The glyph for each destination, from the reference's `TAB_META`.
  static const Map<LumeDestinationId, String> icons =
      <LumeDestinationId, String>{
        LumeDestinationId.home: LumeIcons.home,
        LumeDestinationId.tools: LumeIcons.grid,
        LumeDestinationId.trains: LumeIcons.train,
        LumeDestinationId.today: LumeIcons.sun,
        LumeDestinationId.explore: LumeIcons.compass,
        LumeDestinationId.profile: LumeIcons.user,
      };

  /// The order for a country.
  ///
  /// Trains is a first-class destination in Pakistan; everywhere else Explore
  /// takes that slot and Trains lives inside Tools. This is the *only* place
  /// that decision is made — `eligibility` decides whether a feature exists,
  /// and this decides whether it is a tab, and the two are different questions.
  static List<LumeDestinationId> orderFor(String countryCode) =>
      countryCode == 'PK'
      ? const <LumeDestinationId>[
          LumeDestinationId.home,
          LumeDestinationId.tools,
          LumeDestinationId.trains,
          LumeDestinationId.today,
          LumeDestinationId.profile,
        ]
      : const <LumeDestinationId>[
          LumeDestinationId.home,
          LumeDestinationId.tools,
          LumeDestinationId.today,
          LumeDestinationId.explore,
          LumeDestinationId.profile,
        ];

  /// Every id any country can show, in a stable order.
  ///
  /// The router's branches are built from this, not from one country's order,
  /// so switching country re-orders the *presentation* without rebuilding the
  /// navigator or losing any branch's stack.
  static const List<LumeDestinationId> all = <LumeDestinationId>[
    LumeDestinationId.home,
    LumeDestinationId.tools,
    LumeDestinationId.trains,
    LumeDestinationId.today,
    LumeDestinationId.explore,
    LumeDestinationId.profile,
  ];

  /// The branch index a destination occupies in the shell route.
  ///
  /// Fixed for the life of the app. The *visible* order changes with country;
  /// the branch index does not, which is what lets a Pakistani user switch to
  /// the UK and still find Today's stack where they left it.
  static int branchIndexOf(LumeDestinationId id) => all.indexOf(id);

  /// Build the destinations for a country, with labels supplied by the caller
  /// so this file holds no strings.
  static List<LumeDestination> build({
    required String countryCode,
    required String Function(LumeDestinationId) label,
    Map<LumeDestinationId, int> badges = const <LumeDestinationId, int>{},
    Set<LumeDestinationId> dots = const <LumeDestinationId>{},
  }) {
    final List<LumeDestinationId> order = orderFor(countryCode);
    assert(
      order.length <= maximum,
      'never more than $maximum destinations (§6) — got ${order.length}',
    );
    return <LumeDestination>[
      for (final LumeDestinationId id in order)
        LumeDestination(
          id: id,
          label: label(id),
          icon: icons[id]!,
          semanticLabel: _spoken(label(id), badges[id], dots.contains(id)),
          badgeCount: badges[id],
          showDot: dots.contains(id),
        ),
    ];
  }

  static String _spoken(String label, int? count, bool dot) {
    if (count != null && count > 0) return '$label, $count new';
    if (dot) return '$label, new';
    return label;
  }
}
