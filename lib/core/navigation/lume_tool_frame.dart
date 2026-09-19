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

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../layout/lume_measure.dart';
import '../theme/lume/lume_colors.dart';
import '../theme/lume/lume_space.dart';
import '../theme/lume/lume_theme.dart';
import '../widgets/lume/lume_badge.dart';
import '../widgets/lume/lume_header.dart';
import '../widgets/lume/lume_state.dart';
import '../widgets/lume/lume_table.dart';
import '../widgets/lume/lume_target.dart';
import '../widgets/lume/lume_tool.dart';

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
    this.sourceSample,
    this.sourceSampleSemantics,
    this.freshness,
    this.freshnessLabel,
    this.freshnessSemantics,
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

  /// The sample-data mark at the head of the source line, and what a screen
  /// reader says for it (F6B closure, `RELEASE_HONESTY.md`).
  final String? sourceSample;
  final String? sourceSampleSemantics;

  /// The live/delayed/cached marker that sits beside the subtitle.
  final LumeFreshnessQuality? freshness;
  final String? freshnessLabel;

  /// What a screen reader hears for [freshnessLabel], where it differs.
  final String? freshnessSemantics;

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
  final ScrollController _scroll = ScrollController();

  /// `.toolbar.is-stuck` — the hairline appears once content has scrolled
  /// under the bar (`root.scrollTop > 4`).
  bool _stuck = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final bool stuck = _scroll.hasClients && _scroll.offset > 4;
    if (stuck != _stuck) setState(() => _stuck = stuck);
  }

  @override
  void dispose() {
    widget.onLeave?.call();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return CustomScrollView(
      controller: _scroll,
      slivers: <Widget>[
        // `.toolbar { position: sticky; top: 0; background: bg 88 %;
        // backdrop-filter: saturate(1.6) blur(18px) }`.
        PinnedHeaderSliver(
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: lume.bg.withValues(alpha: 0.88),
                  border: Border(
                    bottom: BorderSide(
                      color: _stuck ? lume.border : Colors.transparent,
                      width: LumeSpace.border,
                    ),
                  ),
                ),
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
            ),
          ),
        ),
        SliverToBoxAdapter(
          // Sections bring their own gutters, and a flush one brings none, so
          // the measure only caps and centres here.
          child: LumeMeasure(
            wide: widget.wide,
            gutters: false,
            // Sections are 24 apart, so a small control near an edge has room
            // to be touched past its drawn box without taking anybody's tap.
            child: LumeTargetRegion(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _content(context),
              ),
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

  /// `engine.js` `build()`: the body, then `sourceSection`, `privacyNote` and
  /// `relatedSection`, each its own `.sect`.
  List<Widget> _content(BuildContext context) {
    if (!widget.eligible) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            title: widget.strings.unavailableTitle,
            text: widget.strings.unavailableText,
          ),
        ),
      ];
    }

    return switch (widget.status) {
      LumeToolStatus.unavailable => <Widget>[
        LumeToolSection(
          child: LumeToolState(
            title: widget.strings.unavailableTitle,
            text: widget.strings.unavailableText,
          ),
        ),
      ],
      LumeToolStatus.error => <Widget>[
        LumeToolSection(
          child: LumeToolState.error(
            title: widget.strings.errorTitle,
            text: widget.strings.errorText,
            action: widget.onRetry == null
                ? null
                : LumeNoticeAction(
                    label: widget.strings.retry,
                    onPressed: widget.onRetry,
                  ),
          ),
        ),
      ],
      LumeToolStatus.loading => <Widget>[
        LumeToolSection(
          child: Semantics(
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
        ),
      ],
      LumeToolStatus.ready => <Widget>[
        widget.body,
        if (widget.freshness != null ||
            widget.source != null ||
            widget.updated != null ||
            widget.sourceNote != null ||
            widget.sourceSample != null)
          LumeToolSection(
            child: LumeSourceBar(
              quality: widget.freshness,
              qualityLabel: widget.freshnessLabel,
              qualitySemantics: widget.freshnessSemantics,
              source: widget.source,
              updated: widget.updated,
              note: widget.sourceNote,
              sample: widget.sourceSample,
              sampleSemantics: widget.sourceSampleSemantics,
            ),
          ),
        if (widget.privacy != null) LumeToolSection(child: widget.privacy!),
        if (widget.related.isNotEmpty)
          LumeToolSection(
            title: widget.strings.relatedTitle,
            child: LumeRelatedTools(
              tools: widget.related,
              onOpen: widget.onOpenRelated,
            ),
          ),
      ],
    };
  }
}
