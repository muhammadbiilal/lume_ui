/// Takes the system Back press, where there is a router to take it from.
///
/// [BackButtonListener] reaches for `Router.of(context).backButtonDispatcher`
/// and throws when there is none. The product always has a router; a widget
/// test that pumps one screen on its own does not, and a screen that cannot be
/// pumped in isolation is a screen that is hard to test.
///
/// So this is the same widget with a lookup in front of it. The guard costs one
/// `dependOnInheritedWidgetOfExactType` and buys back every isolated pump.
///
/// Two screens need it for the same reason: something is showing *over*
/// something else inside one route, so the first Back should reveal what is
/// underneath rather than leave the route. A record over its list, a step
/// inside a flow.
library;

import 'package:flutter/widgets.dart';

/// Intercepts Back when a router is present, and is otherwise transparent.
class LumeBackIntercept extends StatelessWidget {
  const LumeBackIntercept({
    super.key,
    required this.onBack,
    required this.child,
  });

  /// Returns `true` when it handled the press and the route should stay.
  final Future<bool> Function() onBack;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Router.maybeOf(context) == null) return child;
    return BackButtonListener(onBackButtonPressed: onBack, child: child);
  }
}
