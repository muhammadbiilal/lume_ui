/// Small string/icon mappings for Goals — no state, no logic beyond a
/// lookup, so each is trivial to check against its enum.
library;

import '../../../core/icons/lume_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/goals_model.dart';

abstract final class GoalsText {
  static String state(AppLocalizations l, GoalState s) => switch (s) {
    GoalState.active => l.goalsStateActive,
    GoalState.completed => l.goalsStateCompleted,
    GoalState.abandoned => l.goalsStateAbandoned,
  };

  static String icon(GoalIcon i) => switch (i) {
    GoalIcon.target => LumeIcons.target,
    GoalIcon.plane => LumeIcons.plane,
    GoalIcon.grid => LumeIcons.grid,
    GoalIcon.home => LumeIcons.home,
    GoalIcon.star => LumeIcons.star,
    GoalIcon.shield => LumeIcons.shield,
  };
}
