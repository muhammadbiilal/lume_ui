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

/// `.crud__id` — a record's provenance line.
class LumeRecordId extends StatelessWidget {
  const LumeRecordId({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
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
          icon: LumeIcons.trash,
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
        ? Color.lerp(lume.card, lume.rose, 0.07)!
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

/// The delete confirmation's content.
///
/// A sheet or dialog hosts it; this is what goes inside. It names the record
/// and states the consequence, and the destructive action is labelled with the
/// verb rather than "OK".
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
  });

  /// Names the record — "Delete Groceries?", not "Delete item?".
  final String title;

  /// What happens next. For [LumeDeleteKind.irreversible] this says so.
  final String consequence;

  /// The verb. Never "OK".
  final String confirmLabel;

  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final LumeDeleteKind kind;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: LumeType.fit(
              context,
              context.lumeType.section,
            ).copyWith(color: lume.text),
          ),
        ),
        const SizedBox(height: LumeSpace.x2),
        Text(
          consequence,
          style: LumeType.fit(
            context,
            context.lumeType.body,
          ).copyWith(color: lume.text2),
        ),
        const SizedBox(height: LumeSpace.x5),
        LumeButton.danger(
          label: confirmLabel,
          onPressed: onConfirm,
          block: true,
          icon: kind == LumeDeleteKind.irreversible ? LumeIcons.alert : null,
        ),
        const SizedBox(height: 10),
        // The safe choice is the one that is not destructive, and it is the
        // one the thumb reaches first from the bottom of the screen.
        LumeButton(label: cancelLabel, onPressed: onCancel, block: true),
      ],
    );
  }
}
