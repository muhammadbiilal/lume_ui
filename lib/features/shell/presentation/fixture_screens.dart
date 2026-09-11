/// Fixture screens: enough of a product for the shell to be verified against,
/// and deliberately no more.
///
/// Phase F3 builds the shell, the navigation and the routing. The screens those
/// carry are F4 and later. What sits in the outlet until then has to be real
/// enough to prove the shell works — long enough to scroll, stateful enough to
/// show that a branch keeps its position, and reachable enough to prove every
/// route resolves — without pretending to be Home, Tools or Today.
///
/// So each one names its destination, scrolls, and counts its own taps. The
/// count is the point: it is per-screen state, and if a branch's stack were
/// being rebuilt when you leave and come back, the number would reset.
library;

import 'package:flutter/material.dart';

import '../../../core/layout/lume_measure.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';

/// A destination, a nested screen, or anything else the shell has to host.
///
/// Scrolls, remembers its scroll offset through its [PageStorageKey], and keeps
/// a tap count so state preservation is visible rather than asserted.
class LumeFixtureScreen extends StatefulWidget {
  const LumeFixtureScreen({
    super.key,
    required this.title,
    required this.storageId,
    this.subtitle,
    this.onBack,
    this.backLabel,
    this.actions = const <Widget>[],
    this.rows = 24,
    this.links = const <LumeFixtureLink>[],
  });

  final String title;
  final String? subtitle;

  /// Distinguishes this screen's scroll position and counter from every other
  /// one's. A branch's root and the same screen pushed on another branch are
  /// different surfaces and must not share a slot.
  final String storageId;

  final VoidCallback? onBack;
  final String? backLabel;
  final List<Widget> actions;

  /// Enough rows to scroll at every width class.
  final int rows;

  /// Where this screen can go. The only navigation a fixture performs.
  final List<LumeFixtureLink> links;

  @override
  State<LumeFixtureScreen> createState() => _LumeFixtureScreenState();
}

/// One way out of a fixture screen.
@immutable
class LumeFixtureLink {
  const LumeFixtureLink({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final String? icon;
}

class _LumeFixtureScreenState extends State<LumeFixtureScreen> {
  /// Per-screen state, which is the whole reason this widget is stateful: it
  /// survives a tab switch only if the branch's stack survives with it.
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return CustomScrollView(
      key: PageStorageKey<String>('fixture:${widget.storageId}'),
      primary: false,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: LumeMeasure(
            gutters: false,
            child: LumeToolbar(
              title: widget.title,
              subtitle: widget.subtitle,
              onBack: widget.onBack,
              backLabel: widget.backLabel,
              actions: widget.actions,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: LumeMeasure(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (widget.links.isNotEmpty) ...<Widget>[
                  LumeCard(
                    child: Column(
                      children: <Widget>[
                        for (final LumeFixtureLink link in widget.links)
                          LumeRichRow(
                            title: link.label,
                            icon: link.icon,
                            onTap: link.onTap,
                            chevron: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LumeSpace.gapSection),
                ],
                LumeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        key: ValueKey<String>(
                          'fixture-count:${widget.storageId}',
                        ),
                        '$_taps',
                        style: LumeType.numeric(
                          LumeType.fit(context, context.lumeType.display),
                        ).copyWith(color: lume.text),
                      ),
                      const SizedBox(height: LumeSpace.x3),
                      LumeButton(
                        label: widget.title,
                        onPressed: () => setState(() => _taps++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LumeSpace.gapSection),
                for (int i = 0; i < widget.rows; i++)
                  LumeCompactRow(
                    label: widget.title,
                    value: '${i + 1}',
                    chevron: false,
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }
}

/// A location the router could not match, and the two flows that cover the
/// shell rather than sitting inside it, drawn the same way: one honest state,
/// one way out.
class LumeMessageScreen extends StatelessWidget {
  const LumeMessageScreen({
    super.key,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: LumeMeasure(
            child: LumeToolState(
              title: title,
              text: text,
              action: actionLabel == null
                  ? null
                  : LumeNoticeAction(label: actionLabel!, onPressed: onAction),
            ),
          ),
        ),
      ),
    );
  }
}
