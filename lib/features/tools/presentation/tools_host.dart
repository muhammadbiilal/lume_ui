/// The Tools hub, wired to the launch.
///
/// The hub keeps no data of its own: the catalogue is a constant, the
/// eligibility selector is a provider, and the personalisation comes from the
/// same [LumeProfileScope] every destination reads. So there is nothing to
/// load, and nothing to get out of step.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/routing/lume_routes.dart';
import '../../catalogue/domain/eligibility.dart';
import 'tools_screen.dart';

/// The hub on a branch.
class LumeToolsHost extends ConsumerWidget {
  const LumeToolsHost({super.key, required this.branch});

  /// The branch the hub sits on, so a tool opened from here returns here —
  /// and a tool opened from Home returns to Home.
  final String branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LumeProfileScope(
    builder: (BuildContext context, LumeUserContext user) => LumeToolsScreen(
      eligibility: ref.watch(eligibilityProvider),
      user: user,
      // The same resolver Home reads, so the Prayer Times tile names the same
      // prayer on both screens. Synchronous: the hub has nothing to load.
      live: ref
          .watch(homeDataRepositoryProvider)
          .statusesFor(user, now: LumeClockScope.of(context).now()),
      // Only the tools that can honestly report a count. The reference asks
      // two tools and catches whatever they throw; here the question is only
      // put to the ones that have an answer.
      attention: const <String, int>{'bills': 1, 'documents': 2},
      actions: LumeToolsActions(
        openTool: (String id) {
          ref.read(recentToolsProvider).note(id);
          context.go(LumeRoutes.tool(branch, id));
        },
        openPersonalise: () => context.go(LumeRoutes.account(branch)),
      ),
    ),
  );
}
