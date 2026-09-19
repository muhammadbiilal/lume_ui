/// CRUD presentation: the collection header, the detail actions, the form
/// card, the submit bar, the delete confirmation and the master-detail
/// scaffold.
///
/// Measured:
///
/// | | height | radius | ink |
/// |---|---|---|---|
/// | `.cact--edit` | 52 | 12 | `tintAccent` / `accent-700` |
/// | `.cact--danger` | 52 | 12 | rose surface / `roseInk` |
/// | `.crud__count` | 13 | — | 11 / 500, muted |
/// | `.crud__id` | 16 | — | 11 / 500, muted |
///
/// Neither detail action is a filled button, and that is the point: the
/// primary action of a detail screen is *reading it*. Edit and Delete are
/// available without competing with the content for attention.
library;

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../layout/lume_breakpoint.dart';
import '../../layout/lume_measure.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_button.dart';
import 'lume_pressable.dart';

/// `.crud__count` — the collection's condition, under its title.
///
/// The reference puts the state *here* rather than in a banner: "12 expenses",
/// "No expenses yet", "Could not refresh". An empty collection says so instead
/// of counting to zero.
class LumeListCount extends StatelessWidget {
  const LumeListCount({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      label,
      style: LumeType.fit(
        context,
        context.lumeType.metaSmall,
      ).copyWith(color: context.lume.text3),
    ),
  );
}

/// `.crud__id` — a record's provenance line. (The identity itself is
/// `LumeRecordId`, `core/values`.)
class LumeRecordIdLabel extends StatelessWidget {
  const LumeRecordIdLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: TextAlign.center,
    style: LumeType.fit(
      context,
      context.lumeType.metaSmall,
    ).copyWith(color: context.lume.text3),
  );
}

/// `.cacts` — the actions on a record detail.
class LumeDetailActions extends StatelessWidget {
  const LumeDetailActions({
    super.key,
    required this.editLabel,
    this.onEdit,
    this.deleteLabel,
    this.onDelete,
    this.extra = const <Widget>[],
  });

  final String editLabel;
  final VoidCallback? onEdit;

  /// `null` hides the destructive action entirely, which is what a read-only
  /// record needs.
  final String? deleteLabel;
  final VoidCallback? onDelete;

  final List<Widget> extra;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      LumeDetailAction(
        label: editLabel,
        icon: LumeIcons.note,
        onPressed: onEdit,
      ),
      if (deleteLabel != null) ...<Widget>[
        const SizedBox(height: 10),
        LumeDetailAction(
          label: deleteLabel!,
          onPressed: onDelete,
          destructive: true,
        ),
      ],
      for (final Widget w in extra) ...<Widget>[const SizedBox(height: 10), w],
    ],
  );
}

/// `.cact` — one full-width detail action.
///
/// Measured: 52 tall, 12 px radius, 9 px gap, 15 / 700.
class LumeDetailAction extends StatelessWidget {
  const LumeDetailAction({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.destructive = false,
  });

  final String label;
  final String? icon;
  final VoidCallback? onPressed;
  final bool destructive;

  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color bg = destructive
        ? Color.lerp(lume.card, lume.rose, 0.10)!
        : lume.tintAccent;
    final Color fg = destructive ? lume.roseInk : lume.accent700;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: LumePressable(
        onTap: onPressed,
        enabled: onPressed != null,
        borderRadius: LumeRadius.brSm,
        minSize: height,
        excludeSemantics: true,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(vertical: LumeSpace.x3),
          decoration: BoxDecoration(color: bg, borderRadius: LumeRadius.brSm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                LumeIcon(icon!, size: 17, color: fg),
                const SizedBox(width: 9),
              ],
              Text(
                label,
                style: LumeType.fit(
                  context,
                  context.lumeType.cardTitle,
                ).copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.cformcard` — the card a record form lives in.
///
/// Capped at the reading measure even inside a wide composition, because a
/// form field 1100 px wide is not a better form field.
class LumeFormCard extends StatelessWidget {
  const LumeFormCard({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: LumeSpace.contentMax),
      child: Container(
        padding: const EdgeInsets.all(LumeSpace.x5),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (title != null) ...<Widget>[
              Text(
                title!,
                style: LumeType.fit(
                  context,
                  context.lumeType.section,
                ).copyWith(color: lume.text),
              ),
              const SizedBox(height: LumeSpace.x4),
            ],
            LumeFormSection(children: children),
          ],
        ),
      ),
    );
  }
}

/// `.cform` — form fields with an 18 px gap.
///
/// At expanded width a `pair` section becomes two columns; anything marked
/// wide spans both, and the whole thing collapses to one column when the pane
/// is narrow or the text is large (§9 of the CRUD guide).
class LumeFormSection extends StatelessWidget {
  const LumeFormSection({super.key, required this.children, this.pair = false});

  final List<Widget> children;

  /// Two columns for related short fields, where there is room.
  final bool pair;

  static const double gap = 18;

  @override
  Widget build(BuildContext context) {
    final bool twoColumn =
        pair &&
        context.isExpanded &&
        MediaQuery.textScalerOf(context).scale(14) < 20;

    if (!twoColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double columnGap = 20;
        final double width = (constraints.maxWidth - columnGap) / 2;
        return Wrap(
          spacing: columnGap,
          runSpacing: 16,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// `.csubmit` — the save area.
///
/// The busy action keeps its label and its size (§7, §8), so the button does
/// not change shape under the user's thumb, and a second tap while a save is
/// in flight does nothing rather than saving twice.
class LumeSubmitBar extends StatelessWidget {
  const LumeSubmitBar({
    super.key,
    required this.saveLabel,
    this.onSave,
    this.cancelLabel,
    this.onCancel,
    this.busy = false,
    this.busyLabel,
    this.note,
  });

  final String saveLabel;
  final VoidCallback? onSave;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final bool busy;
  final String? busyLabel;

  /// A line under the actions — "Saved on this device only".
  final String? note;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumeButton.accent(
          label: saveLabel,
          onPressed: onSave,
          block: true,
          busy: busy,
          busyLabel: busyLabel,
        ),
        if (cancelLabel != null) ...<Widget>[
          const SizedBox(height: 10),
          LumeButton(
            label: cancelLabel!,
            // A cancel stays live while a save is in flight only if cancelling
            // is actually possible; the caller decides by passing null.
            onPressed: busy ? null : onCancel,
            block: true,
          ),
        ],
        if (note != null) ...<Widget>[
          const SizedBox(height: LumeSpace.x3),
          Text(
            note!,
            textAlign: TextAlign.center,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3),
          ),
        ],
      ],
    );
  }
}

/// `.panes` — the master-detail scaffold.
///
/// One pane below expanded, two at expanded. Selecting a record at expanded
/// width updates the detail pane and **does not push a route**; the list keeps
/// its scroll, its filters and its position because it is never rebuilt from
/// scratch.
class LumeMasterDetail extends StatelessWidget {
  const LumeMasterDetail({
    super.key,
    required this.list,
    required this.detail,
    this.detailKey,
  });

  final Widget list;

  /// What the detail pane shows. Pass the "select a record" state when nothing
  /// is selected — the pane is never blank.
  final Widget detail;

  final Key? detailKey;

  @override
  Widget build(BuildContext context) {
    if (!context.hasDetailPane) return list;

    final double paneWidth = LumeLayout.listPaneWidth(context.shellWidth);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: paneWidth, child: list),
        const SizedBox(width: LumeSpace.x5),
        Expanded(
          child: KeyedSubtree(key: detailKey, child: detail),
        ),
      ],
    );
  }
}

/// What deleting a record means, which changes what the confirmation says.
enum LumeDeleteKind {
  /// Most families. The record leaves the list at once and Undo brings it back.
  recoverable,

  /// Documents and health records — the two whose consideration is secure
  /// deletion and consent. The confirmation says it cannot be undone, and then
  /// no Undo is armed, because arming one would be a lie.
  irreversible,
}

/// The confirmation's content — `.dconfirm` in `#sheet-recdelete`.
///
/// It names the record and states the consequence before it asks, and the
/// action is labelled with the verb rather than "OK". Measured
/// (`tool_expenses_default_pk_delete_*`): a centred column 10 apart inside
/// `22 20 6`; a 70-point "!" mark in rose at 12 % — amber at 14 % when it
/// warns — 6 above the title; the title 20 / 700 on 26; the text body on 22 in
/// `text-2`, no wider than 36 characters, 14 above the buttons; the action
/// solid rose ink, or amber, and the quiet Cancel under it, both 46 tall.
class LumeDeleteConfirmation extends StatelessWidget {
  const LumeDeleteConfirmation({
    super.key,
    required this.title,
    required this.consequence,
    required this.confirmLabel,
    required this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.kind = LumeDeleteKind.recoverable,
    this.warn = false,
  });

  /// Names the record — "Delete this expense?".
  final String title;

  /// What happens next. For [LumeDeleteKind.irreversible] this says so.
  final String consequence;

  /// The verb. Never "OK".
  final String confirmLabel;

  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final LumeDeleteKind kind;

  /// `.sheet--confirm.is-warn` — leaving unsaved changes rather than removing
  /// a saved record.
  final bool warn;

  static const double markSize = 70;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle textStyle = LumeType.fit(
      context,
      context.lumeType.body,
    ).copyWith(color: lume.text2);
    final TextPainter zero = TextPainter(
      text: TextSpan(text: '0' * 36, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double measure = zero.width;
    zero.dispose();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(
            child: Container(
              width: markSize,
              height: markSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: warn
                    ? lume.amber.withValues(alpha: 0.14)
                    : lume.rose.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                '!',
                style:
                    LumeType.natural(
                      context,
                      context.lumeType.display,
                      size: 30,
                    ).copyWith(
                      fontWeight: FontWeight.w800,
                      color: warn ? lume.amber : lume.roseInk,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 6 + 10),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: LumeType.fit(
                context,
                context.lumeType.title,
              ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: measure),
            child: Text(
              consequence,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
          const SizedBox(height: 14 + 10),
          LumeButton(
            label: confirmLabel,
            onPressed: onConfirm,
            block: true,
            tone: warn ? LumeButtonTone.warn : LumeButtonTone.critical,
          ),
          const SizedBox(height: 10),
          // The safe choice is the one that is not destructive, and it is the
          // one the thumb reaches first from the bottom of the screen.
          LumeButton(label: cancelLabel, onPressed: onCancel, block: true),
        ],
      ),
    );
  }
}

/// `.cfield` holding a `select` or a date — the label above, the chosen value
/// in a 48-point box, a 15-point glyph at its end. Pressing it chooses.
///
/// Measured: the label 12 / 700 in `text-2` on 16, with an optional marker
/// in `metasm` 8 after it; 7 to the box; the box `0 14` of padding in `card`
/// inside `--border-2`, radius 12; the value 14 / 500, 8 from the glyph.
class LumeFormPicker extends StatelessWidget {
  const LumeFormPicker({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.optionalLabel,
    this.icon = LumeIcons.chevD,
  });

  final String label;

  /// The chosen value, already worded.
  final String value;

  final VoidCallback? onTap;
  final String? optionalLabel;
  final String icon;

  static const double boxHeight = 48;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      button: true,
      label: label,
      value: value,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeFieldLabel(label: label, optionalLabel: optionalLabel),
            const SizedBox(height: 7),
            LumePressable(
              onTap: onTap,
              borderRadius: LumeRadius.brSm,
              minSize: boxHeight,
              child: Container(
                constraints: const BoxConstraints(minHeight: boxHeight),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: lume.card,
                  borderRadius: LumeRadius.brSm,
                  border: Border.all(
                    color: lume.border2,
                    width: LumeSpace.border,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumeType.fit(context, context.lumeType.body)
                            .copyWith(
                              color: lume.text,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LumeIcon(icon, size: 15, color: lume.text3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.cfield__label` — sentence case at label weight, and "Optional" beside it.
class LumeFieldLabel extends StatelessWidget {
  const LumeFieldLabel({super.key, required this.label, this.optionalLabel});

  final String label;
  final String? optionalLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Flexible(
          child: Text(
            label,
            style: LumeType.fit(
              context,
              context.lumeType.label,
            ).copyWith(color: lume.text2),
          ),
        ),
        if (optionalLabel != null) ...<Widget>[
          const SizedBox(width: 8),
          Text(
            optionalLabel!,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3),
          ),
        ],
      ],
    );
  }
}

/// `.cattach` — adding a photo or a document to a record.
///
/// Measured: at least 64 tall, radius 12, `card` inside a dashed
/// `--border-2`; a 17-point glyph 9 from the 15 / 700 label, in `accent-700`.
class LumeAttachTile extends StatelessWidget {
  const LumeAttachTile({
    super.key,
    required this.fieldLabel,
    required this.label,
    this.optionalLabel,
    this.attached = false,
    this.onTap,
  });

  final String fieldLabel;
  final String label;
  final String? optionalLabel;
  final bool attached;
  final VoidCallback? onTap;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumeFieldLabel(label: fieldLabel, optionalLabel: optionalLabel),
        const SizedBox(height: 7),
        Semantics(
          button: true,
          label: label,
          child: LumePressable(
            onTap: onTap,
            borderRadius: LumeRadius.brSm,
            minSize: height,
            excludeSemantics: true,
            child: CustomPaint(
              foregroundPainter: _DashedBox(lume.border2),
              child: Container(
                constraints: const BoxConstraints(minHeight: height),
                decoration: BoxDecoration(
                  color: lume.card,
                  borderRadius: LumeRadius.brSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    LumeIcon(
                      attached ? LumeIcons.checkCircle : LumeIcons.camera,
                      size: 17,
                      color: lume.accent700,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumeType.fit(
                          context,
                          context.lumeType.cardTitle,
                        ).copyWith(color: lume.accent700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBox extends CustomPainter {
  const _DashedBox(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final RRect outline = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(LumeRadius.sm),
    );
    for (final PathMetric metric
        in (Path()..addRRect(outline)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color;
}
