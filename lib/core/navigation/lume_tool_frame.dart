/// One frame, shared by all 85 tool screens.
///
/// `tool.screen.js` is explicit about what the host owns and what a tool
/// supplies: *"Each tool supplies its own composition; everything around it
/// comes from here."* Around it means the back control, the title, the
/// subtitle, the actions, the provenance line, the privacy notice, the related
/// rail, and the three states a tool can be in before it has anything to show.
///
/// **The gate is not the entry point.** §64: *"opening a tool asks the same
/// eligibility selector every other surface asks, so a hidden feature cannot be
/// reached through a deep link, a related-tool card, a search result or a
/// notification either."* [eligible] is that check, asked here, at the frame,
/// where every one of those paths has to pass. A frame handed `eligible: false`
/// renders the unavailable state and never builds [body] — so a gated tool's
/// widgets are not merely invisible, they do not exist, and nothing in them can
/// run, request or announce itself.
///
/// **Teardown is Flutter's.** The reference releases countdowns, sub-views and
/// the tool stack by hand in `onLeave`, because a browser screen that is hidden
/// is still mounted. Here a tool that leaves is disposed: its timers and
/// controllers go with it, whether it was left through Back, through the tab
/// bar, or by a rotation that replaced the whole layout. [onLeave] exists for
/// what genuinely outlives the widget — a recent-tools note, an analytics
/// mark — and not for cleanup.
library;

import 'package:flutter/material.dart';

import '../layout/lume_measure.dart';
import '../theme/lume/lume_space.dart';
import '../widgets/lume/lume_badge.dart';
import '../widgets/lume/lume_header.dart';
import '../widgets/lume/lume_state.dart';
import '../widgets/lume/lume_table.dart';

/// What a tool has to show, before it has anything to show.
enum LumeToolStatus {
  /// [LumeToolFrame.body] is built.
  ready,

  /// Skeletons, not a spinner. §11: a loading surface should have the shape of
  /// the thing that is coming.
  loading,

  /// Something failed and can be retried.
  error,

  /// The tool exists but not here — a country that has no localisation for it,
  /// a capability the device lacks.
  unavailable,
}

/// The strings the frame's own states need.
///
/// Passed in rather than looked up, for the same reason [LumeDestination]'s
/// labels are: this file holds no user-facing text, so it cannot be the reason
/// a language is incomplete.
@immutable
class LumeToolFrameStrings {
  const LumeToolFrameStrings({
    required this.loading,
    required this.errorTitle,
    required this.errorText,
    required this.retry,
    required this.unavailableTitle,
    required this.unavailableText,
    required this.back,
    this.relatedTitle,
  });

  final String loading;
  final String errorTitle;
  final String errorText;
  final String retry;
  final String unavailableTitle;
  final String unavailableText;
  final String back;
  final String? relatedTitle;
}

/// The host every tool is drawn inside.
class LumeToolFrame extends StatefulWidget {
  const LumeToolFrame({
    super.key,
    required this.title,
    required this.body,
    required this.strings,
    this.subtitle,
    this.onBack,
    this.actions = const <Widget>[],
    this.status = LumeToolStatus.ready,
    this.eligible = true,
    this.onRetry,
    this.source,
    this.updated,
    this.sourceNote,
    this.freshness,
    this.freshnessLabel,
    this.privacy,
    this.related = const <LumeRelatedTool>[],
    this.onOpenRelated,
    this.wide = false,
    this.onLeave,
  });

  /// The tool's name, already localised.
  final String title;

  /// What the tool is for, or the context it is showing — the city, the
  /// currency pair, the month.
  final String? subtitle;

  /// The tool's own composition. Built only when the frame is [eligible] and
  /// [LumeToolStatus.ready].
  final Widget body;

  final LumeToolFrameStrings strings;

  /// `null` hides the back control. A tool always has one; a tool *pane* inside
  /// a master-detail layout may not.
  final VoidCallback? onBack;

  /// Share, refresh, settings — the tool's own verbs.
  final List<Widget> actions;

  final LumeToolStatus status;

  /// §64's gate, asked at the frame. `false` renders the unavailable state and
  /// never builds [body].
  final bool eligible;

  final VoidCallback? onRetry;

  /// §19: where a number came from, and when. Shown under the body, because
  /// provenance follows the value it qualifies.
  final String? source;
  final String? updated;
  final String? sourceNote;

  /// The live/delayed/cached marker that sits beside the subtitle.
  final LumeFreshnessQuality? freshness;
  final String? freshnessLabel;

  /// §61: what this tool holds and what leaves the device. Shown for the
  /// sensitive families, above the related rail.
  final Widget? privacy;

  /// Eligibility-filtered before it arrives — a related tool the user cannot
  /// see must not be in this list.
  final List<LumeRelatedTool> related;
  final ValueChanged<String>? onOpenRelated;

  /// A tool that genuinely needs the width: a two-pane composition, a wide
  /// table. `.is-wide`.
  final bool wide;

  /// Runs once when the frame leaves the tree. For what outlives the widget —
  /// a recents note — not for cleanup, which Flutter already does.
  final VoidCallback? onLeave;

  @override
  State<LumeToolFrame> createState() => _LumeToolFrameState();
}

class _LumeToolFrameState extends State<LumeToolFrame> {
  @override
  void dispose() {
    widget.onLeave?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: false,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: LumeMeasure(
            wide: widget.wide,
            gutters: false,
            child: LumeToolbar(
              title: widget.title,
              subtitle: widget.subtitle,
              onBack: widget.onBack,
              backLabel: widget.strings.back,
              actions: widget.actions,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: LumeMeasure(
            wide: widget.wide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _content(context),
            ),
          ),
        ),
        // The bar's clearance, republished by the shell. A tool never counts
        // the navigation's height for itself.
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context) {
    if (!widget.eligible) {
      return <Widget>[
        LumeToolState(
          title: widget.strings.unavailableTitle,
          text: widget.strings.unavailableText,
        ),
      ];
    }

    return switch (widget.status) {
      LumeToolStatus.unavailable => <Widget>[
        LumeToolState(
          title: widget.strings.unavailableTitle,
          text: widget.strings.unavailableText,
        ),
      ],
      LumeToolStatus.error => <Widget>[
        LumeToolState.error(
          title: widget.strings.errorTitle,
          text: widget.strings.errorText,
          action: widget.onRetry == null
              ? null
              : LumeNoticeAction(
                  label: widget.strings.retry,
                  onPressed: widget.onRetry,
                ),
        ),
      ],
      LumeToolStatus.loading => <Widget>[
        Semantics(
          label: widget.strings.loading,
          liveRegion: true,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LumeSkeleton(kind: LumeSkeletonKind.metric),
              SizedBox(height: LumeSpace.gapCard),
              LumeSkeleton(kind: LumeSkeletonKind.card),
              SizedBox(height: LumeSpace.gapCard),
              LumeSkeleton(kind: LumeSkeletonKind.row, count: 2),
            ],
          ),
        ),
      ],
      LumeToolStatus.ready => <Widget>[
        if (widget.freshness != null &&
            widget.freshnessLabel != null) ...<Widget>[
          LumeFreshness(
            label: widget.freshnessLabel!,
            quality: widget.freshness!,
          ),
          const SizedBox(height: LumeSpace.x3),
        ],
        widget.body,
        if (widget.source != null ||
            widget.updated != null ||
            widget.sourceNote != null) ...<Widget>[
          const SizedBox(height: LumeSpace.x4),
          LumeSourceLine(
            source: widget.source,
            updated: widget.updated,
            note: widget.sourceNote,
          ),
        ],
        if (widget.privacy != null) ...<Widget>[
          const SizedBox(height: LumeSpace.gapSection),
          widget.privacy!,
        ],
        if (widget.related.isNotEmpty) ...<Widget>[
          const SizedBox(height: LumeSpace.gapSection),
          LumeRelatedTools(tools: widget.related, onOpen: widget.onOpenRelated),
        ],
      ],
    };
  }
}
