/// States: loading, empty, no results, error, offline, conflict, save failure,
/// private and unavailable.
///
/// The CRUD guide's §10 table is the contract, and it is mostly about what
/// *not* to do:
///
/// | state | show | do not |
/// |---|---|---|
/// | empty | reason, next step, one primary CTA | a blank card or an unexplained zero |
/// | loading | skeletons shaped like the final content | a spinner over the whole list |
/// | offline | cached records, an offline label, queued status | pretend the data is current |
/// | save failure | preserved input, an explanation, Retry | clear the values |
/// | delete success | remove immediately, restore if supported | leave a ghost row |
/// | conflict | explain the newer version, offer Review or Reload | silently overwrite |
///
/// Two shapes, measured apart. `.state` is a tool's state — 34/24 padding,
/// 20 px radius, its own bordered surface. `.cstate` is a record collection's
/// — no surface, a 19 px title, centred in the space the list would occupy.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_button.dart';
import 'lume_pressable.dart';

/// `.state` — a tool's empty, error or unavailable surface.
class LumeToolState extends StatelessWidget {
  const LumeToolState({
    super.key,
    required this.title,
    this.text,
    this.icon,
    this.action,
    this.footnote,
    this.isError = false,
  });

  const LumeToolState.error({
    super.key,
    required this.title,
    this.text,
    this.action,
    this.footnote,
  }) : icon = LumeIcons.alert,
       isError = true;

  final String title;
  final String? text;
  final String? icon;

  /// Exactly one primary call to action. §10: one, not a row of options.
  final Widget? action;

  /// "Your saved data is still safe" — shown under the action, not instead of
  /// it.
  final String? footnote;

  final bool isError;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      liveRegion: isError,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
        decoration: BoxDecoration(
          color: lume.card2,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border2, width: LumeSpace.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeIcon(
              icon ?? LumeIcons.sparkles,
              size: LumeSpace.iconLg,
              color: isError ? lume.roseInk : lume.text3,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: LumeType.tracked(
                LumeType.fit(
                  context,
                  context.lumeType.body,
                ).copyWith(fontWeight: FontWeight.w700),
                -0.026,
              ).copyWith(color: lume.text),
            ),
            if (text != null) ...<Widget>[
              const SizedBox(height: LumeSpace.x1),
              Text(
                text!,
                textAlign: TextAlign.center,
                style: LumeType.fit(
                  context,
                  context.lumeType.meta,
                ).copyWith(color: lume.text3, fontWeight: FontWeight.w400),
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: LumeSpace.x4),
              action!,
            ],
            if (footnote != null) ...<Widget>[
              const SizedBox(height: LumeSpace.x3),
              Text(
                footnote!,
                textAlign: TextAlign.center,
                style: LumeType.fit(
                  context,
                  context.lumeType.metaSmall,
                ).copyWith(color: lume.text3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Which collection state is showing.
///
/// They are kept apart because the guide keeps them apart: an empty collection
/// and a search that found nothing are different situations with different
/// next steps, and showing "Nothing here yet" to someone who just typed a
/// query is telling them something false.
enum LumeCollectionStateKind { empty, noResults, error, pane }

/// `.cstate` — a record collection's state.
class LumeCollectionState extends StatelessWidget {
  const LumeCollectionState({
    super.key,
    required this.kind,
    required this.title,
    required this.text,
    this.icon,
    this.primaryAction,
    this.secondaryAction,
    this.footnote,
  });

  final LumeCollectionStateKind kind;
  final String title;
  final String text;
  final String? icon;

  /// The one primary call to action. For an error this is **Retry, first** —
  /// the guide is explicit that the retry comes before the cached fallback.
  final Widget? primaryAction;

  /// The cached fallback, where one exists.
  final Widget? secondaryAction;

  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool isError = kind == LumeCollectionStateKind.error;
    final bool quiet =
        kind == LumeCollectionStateKind.noResults ||
        kind == LumeCollectionStateKind.pane;

    return Semantics(
      liveRegion: isError,
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: LumeSpace.x8,
          horizontal: LumeSpace.x5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!quiet || icon != null) ...<Widget>[
              LumeIcon(
                icon ?? (isError ? LumeIcons.alert : LumeIcons.sparkles),
                size: 28,
                color: isError ? lume.roseInk : lume.text3,
              ),
              const SizedBox(height: LumeSpace.x3),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              // Measured: 19 / 700.
              style: LumeType.fit(
                context,
                context.lumeType.section,
              ).copyWith(color: lume.text, fontSize: 19),
            ),
            const SizedBox(height: LumeSpace.x2),
            Text(
              text,
              textAlign: TextAlign.center,
              style: LumeType.fit(
                context,
                context.lumeType.body,
              ).copyWith(color: lume.text2),
            ),
            if (primaryAction != null) ...<Widget>[
              const SizedBox(height: LumeSpace.x5),
              primaryAction!,
            ],
            if (secondaryAction != null) ...<Widget>[
              const SizedBox(height: LumeSpace.x2),
              secondaryAction!,
            ],
            if (footnote != null) ...<Widget>[
              const SizedBox(height: LumeSpace.x3),
              Text(
                footnote!,
                textAlign: TextAlign.center,
                style: LumeType.fit(
                  context,
                  context.lumeType.metaSmall,
                ).copyWith(color: lume.text3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What a notice is about.
enum LumeNoticeKind { error, warning, offline, info }

/// `.cnotice` — a persistent notice above a form or a list.
///
/// A card, not a toast. §10: a save failure must not disappear while the user
/// is still reading it, and a conflict must be acted on rather than dismissed.
class LumeNotice extends StatelessWidget {
  const LumeNotice({
    super.key,
    required this.kind,
    required this.title,
    required this.text,
    this.actions = const <Widget>[],
  });

  final LumeNoticeKind kind;
  final String title;
  final String text;

  /// Retry; or Review and Reload for a conflict. Never a lone dismiss.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final (Color bg, Color border, Color glyph, String icon) = switch (kind) {
      LumeNoticeKind.error => (
        Color.lerp(lume.card, lume.rose, 0.06)!,
        lume.rose.withValues(alpha: 0.26),
        lume.roseInk,
        LumeIcons.alert,
      ),
      LumeNoticeKind.warning => (
        Color.lerp(lume.card, lume.amber, 0.08)!,
        lume.amber.withValues(alpha: 0.30),
        lume.amberInk,
        LumeIcons.refresh,
      ),
      LumeNoticeKind.offline => (
        lume.card2,
        lume.border2,
        lume.text3,
        LumeIcons.wifi,
      ),
      LumeNoticeKind.info => (
        lume.card2,
        lume.border,
        lume.text3,
        LumeIcons.info,
      ),
    };

    return Semantics(
      liveRegion:
          kind == LumeNoticeKind.error || kind == LumeNoticeKind.warning,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: LumeRadius.brIcon,
          border: Border.all(color: border, width: LumeSpace.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LumeIcon(icon, size: LumeSpace.iconMd, color: glyph),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: LumeType.fit(
                      context,
                      context.lumeType.cardTitle,
                    ).copyWith(color: lume.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: LumeType.fit(
                      context,
                      context.lumeType.metaSmall,
                    ).copyWith(color: lume.text2),
                  ),
                  if (actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: LumeSpace.x2,
                      runSpacing: LumeSpace.x2,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.cnotice__act` — a small bordered action inside a notice.
///
/// Measured: 36 min-height, 0/12 padding, 8 px radius, `card` fill, 12 / 700.
class LumeNoticeAction extends StatelessWidget {
  const LumeNoticeAction({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: LumePressable(
        onTap: onPressed,
        enabled: onPressed != null,
        borderRadius: LumeRadius.brXs,
        // The visual box is the measured 36; the *target* is the 44 §9 asks
        // for. The reference's own `.cnotice__act` is a 36 px target, which is
        // under its own accessibility floor — recorded in KNOWN_DIFFERENCES.
        minSize: LumeSpace.tap,
        excludeSemantics: true,
        child: Center(
          widthFactor: 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: height),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: lume.card,
              borderRadius: LumeRadius.brXs,
              border: Border.all(color: lume.border2, width: LumeSpace.border),
            ),
            child: Text(
              label,
              style: LumeType.fit(
                context,
                context.lumeType.label,
              ).copyWith(color: lume.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.obanner` — the offline strip above a tool's content.
class LumeOfflineBanner extends StatelessWidget {
  const LumeOfflineBanner({super.key, required this.title, this.text});

  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) =>
      LumeNotice(kind: LumeNoticeKind.offline, title: title, text: text ?? '');
}

/// What shape a skeleton should take.
enum LumeSkeletonKind { row, card, metric, chart, record }

/// `.sk` — a loading placeholder shaped like the content it stands in for.
///
/// §10: skeletons shaped like the final content, never a spinner over the
/// whole list. The shimmer **stops** under reduced motion — it is indefinite,
/// so it does not run at all rather than running instantly, and it is the
/// other thing that makes `pumpAndSettle` hang.
class LumeSkeleton extends StatefulWidget {
  const LumeSkeleton({
    super.key,
    this.kind = LumeSkeletonKind.row,
    this.count = 1,
  });

  final LumeSkeletonKind kind;
  final int count;

  /// Measured heights.
  static double heightFor(LumeSkeletonKind kind) => switch (kind) {
    LumeSkeletonKind.row => 58,
    LumeSkeletonKind.card => 118,
    LumeSkeletonKind.metric => 76,
    LumeSkeletonKind.chart => 132,
    LumeSkeletonKind.record => 66,
  };

  @override
  State<LumeSkeleton> createState() => _LumeSkeletonState();
}

class _LumeSkeletonState extends State<LumeSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _shimmer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LumeMotion.mayRepeat(context)) {
      _shimmer ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    } else {
      _shimmer?.dispose();
      _shimmer = null;
    }
  }

  @override
  void dispose() {
    _shimmer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double h = LumeSkeleton.heightFor(widget.kind);

    Widget bar() {
      final Widget base = Container(
        height: h,
        decoration: BoxDecoration(
          color: lume.tintNeutral,
          borderRadius: LumeRadius.brIcon,
        ),
      );
      if (_shimmer == null) return base;
      return AnimatedBuilder(
        animation: _shimmer!,
        builder: (BuildContext context, Widget? child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (Rect bounds) => LinearGradient(
              begin: Alignment(-1 + _shimmer!.value * 3, 0),
              end: Alignment(-0.4 + _shimmer!.value * 3, 0),
              colors: <Color>[
                lume.tintNeutral,
                lume.cardHover,
                lume.tintNeutral,
              ],
            ).createShader(bounds),
            child: child,
          );
        },
        child: base,
      );
    }

    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < widget.count; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 10),
              bar(),
            ],
          ],
        ),
      ),
    );
  }
}

/// A sensitive surface the user has to ask to see.
///
/// §61 and §62: health records, documents and money are discoverable without
/// being on display. The detail is not rendered until it is asked for, so a
/// shoulder-surfer and a screenshot both see the same nothing.
class LumePrivateState extends StatelessWidget {
  const LumePrivateState({
    super.key,
    required this.title,
    required this.text,
    this.revealLabel,
    this.onReveal,
  });

  final String title;
  final String text;
  final String? revealLabel;
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LumeSpace.x5),
      decoration: BoxDecoration(
        color: lume.card2,
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              LumeIcon(
                LumeIcons.lock,
                size: LumeSpace.iconMd,
                color: lume.text3,
              ),
              const SizedBox(width: LumeSpace.x2),
              Expanded(
                child: Text(
                  title,
                  style: LumeType.fit(
                    context,
                    context.lumeType.cardTitle,
                  ).copyWith(color: lume.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: LumeSpace.x2),
          Text(
            text,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text2),
          ),
          if (onReveal != null) ...<Widget>[
            const SizedBox(height: LumeSpace.x4),
            LumeButton(
              label: revealLabel ?? 'Show',
              icon: LumeIcons.eye,
              onPressed: onReveal,
              small: true,
            ),
          ],
        ],
      ),
    );
  }
}
