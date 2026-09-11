/// The authentication flow, hosted.
///
/// Owns a [LumeAuthFlowController] for the life of the flow, draws whichever
/// screen it is on, keeps the location in step with it, and reports the
/// outcome upward. It navigates **nothing** itself: the host is handed an
/// outcome and the gate decides where that goes.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/lume_back_intercept.dart';
import '../../../core/theme/lume/lume_motion.dart';
import '../application/auth_flow_controller.dart';
import '../domain/auth_model.dart';
import '../domain/auth_repository.dart';
import 'auth_screens.dart';

class LumeAuthFlow extends StatefulWidget {
  const LumeAuthFlow({
    super.key,
    required this.repository,
    this.initialRoute = LumeAuthRoute.signIn,
    this.modal = false,
    this.pendingDestination,
    this.status = const LumeAuthStatus.guest(),
    this.onOutcome,
    this.onRouteChanged,
    this.onOpenLegal,
    this.controller,
  });

  final LumeAuthRepository repository;
  final LumeAuthRoute initialRoute;

  /// Whether the flow interrupted something. Decides whether the header
  /// carries a cross and whether the sign-in screen offers "Continue as a
  /// guest".
  final bool modal;

  /// A location held across the flow and resumed after it.
  final String? pendingDestination;

  /// What is known about the account already — the expired session's address,
  /// the pending one, the name the arrival screen greets.
  final LumeAuthStatus status;

  /// Called once, when the flow is finished with. Carries the status the flow
  /// produced, so nothing above it has to ask the repository again.
  final void Function(
    LumeAuthOutcome outcome,
    LumeAuthStatus? status,
    String? pending,
  )?
  onOutcome;

  /// Called whenever the flow moves, so the location can follow it and a link
  /// to a screen is a real link.
  final ValueChanged<LumeAuthRoute>? onRouteChanged;

  final VoidCallback? onOpenLegal;

  /// Supplied by a test that wants to drive the flow directly. The flow owns
  /// the controller it creates and does not own one it is given.
  final LumeAuthFlowController? controller;

  @override
  State<LumeAuthFlow> createState() => LumeAuthFlowState();
}

class LumeAuthFlowState extends State<LumeAuthFlow> {
  late final LumeAuthFlowController _controller =
      widget.controller ??
      LumeAuthFlowController(
        repository: widget.repository,
        initialRoute: widget.initialRoute,
        modal: widget.modal,
        pendingDestination: widget.pendingDestination,
      );
  late final bool _owns = widget.controller == null;

  LumeAuthRoute? _reported;
  bool _finished = false;

  @visibleForTesting
  LumeAuthFlowController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _reported = _controller.route;
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});

    final LumeAuthOutcome? outcome = _controller.outcome;
    if (outcome != null && !_finished) {
      _finished = true;
      // After the frame: the outcome usually causes a navigation, and
      // navigating out of a listener that fired during a build is how a
      // "setState during build" lands in a crash report.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onOutcome?.call(
          outcome,
          _controller.finalStatus,
          _controller.pendingDestination,
        );
      });
      return;
    }

    if (_controller.route != _reported) {
      _reported = _controller.route;
      final LumeAuthRoute now = _controller.route;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onRouteChanged?.call(now);
      });
    }
  }

  /// The location moved under us.
  ///
  /// Two ways that happens, and only one of them is news. When the flow itself
  /// moved, [_onChange] already pushed the new location and the controller is
  /// where the URL says — nothing to do. When something *else* moved (a deep
  /// link, a Back that popped a page), the controller has to follow.
  @override
  void didUpdateWidget(LumeAuthFlow old) {
    super.didUpdateWidget(old);
    if (widget.initialRoute != old.initialRoute &&
        widget.initialRoute != _controller.route) {
      _controller.go(widget.initialRoute);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    // Disposing wipes what was typed. A password must not outlive the screen
    // that collected it — and a controller the flow does not own still has its
    // form emptied here, because leaving the screen is leaving the screen.
    if (_owns) {
      _controller.dispose();
    } else {
      _controller.leaveFlow();
    }
    super.dispose();
  }

  Future<bool> _back() async {
    if (_controller.form.busy) return true;
    if (_controller.back()) return true;
    // Nothing left inside the flow. A screen that cannot be dismissed stays
    // put; anything else leaves.
    if (!_controller.route.dismissible) return true;
    _controller.dismiss();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final LumeAccount? account = widget.status.account;
    return LumeBackIntercept(
      onBack: _back,
      child: AnimatedSwitcher(
        duration: LumeMotion.standard,
        switchInCurve: LumeMotion.easeOut,
        // Forward and backward are different transitions, so the panel is told
        // which one it is: forward rises, back settles.
        transitionBuilder: (Widget child, Animation<double> t) =>
            FadeTransition(
              opacity: t,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(
                    0,
                    _controller.nav == LumeAuthNav.forward ? 0.03 : -0.02,
                  ),
                  end: Offset.zero,
                ).animate(t),
                child: child,
              ),
            ),
        child: KeyedSubtree(
          key: ValueKey<String>(
            '${_controller.route.name}/${_controller.step}',
          ),
          child: LumeAuthScreen(
            controller: _controller,
            accountEmail: account?.email,
            pendingEmail: account?.pendingEmail,
            displayName: account?.displayName,
            onOpenLegal: widget.onOpenLegal,
          ),
        ),
      ),
    );
  }
}
