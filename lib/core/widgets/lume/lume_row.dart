/// Rows: the rich row, the compact row, the record row, and the expandable row.
///
/// Measured:
///
/// | | height | padding | gap | surface |
/// |---|---|---|---|---|
/// | `.rrow` | 72 | 12 16 | 12 | none — it sits in a `.rows` card |
/// | `.crow` | 40 | 12 16 | 12 | none |
/// | `.rrec` | 44 min | 13 14 | 12 | `card`, 16 r, 1 px border, `shadow-xs` |
///
/// The rich row and the compact row have no surface of their own: they are
/// children of a grouping card. The record row *is* its own card, which is why
/// a record list is a stack of cards and a tool list is one card of rows.
///
/// §84: the same row adapts to its dataset. A rich row in Markets carries a
/// sparkline and a volume; the same row in Parcels carries a carrier and an
/// ETA. Everything is optional, so each caller fills only what it has.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_badge.dart';
import 'lume_pressable.dart';

/// `.rows` — the card that groups rich and compact rows, with hairlines
/// between them.
class LumeRows extends StatelessWidget {
  const LumeRows({super.key, required this.children, this.flat = false});

  final List<Widget> children;

  /// `.rows--flat` — no surface, for a list already inside a card.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0)
            // `.rrow { border-bottom: 1px solid var(--border) }` — the row's own
            // edge, so the hairline runs the full width of the card. Measured
            // on Learning's insights: 348 wide in a 350 card.
            Divider(
              height: LumeSpace.border,
              thickness: LumeSpace.border,
              color: lume.border,
            ),
          children[i],
        ],
      ],
    );

    if (flat) return body;

    return ClipRRect(
      borderRadius: LumeRadius.brLg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        // The hairline is the card's own, outside its rows — a `DecoratedBox`
        // paints it over them, which made two insight rows 121 where the
        // reference measures 123.
        child: Padding(
          padding: const EdgeInsets.all(LumeSpace.border),
          child: body,
        ),
      ),
    );
  }
}

/// `.rrow` — the rich list row.
class LumeRichRow extends StatelessWidget {
  const LumeRichRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.value,
    this.valueSub,
    this.icon,
    this.iconTone,
    this.iconInk,
    this.logo,
    this.thumb,
    this.badge,
    this.delta,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.selected = false,
    this.metaLineHeight,
    this.valueColor,
  });

  final String title;
  final String? subtitle;

  /// `.rrow.is-selected` — the row a detail below it is showing, on
  /// `tint-accent`, and announced as selected.
  final bool selected;

  /// The meta line's height, where a glyph drawn from a fallback face sets it
  /// taller than the font's own 12 — an arrow's 14; null is the font's own.
  final double? metaLineHeight;

  /// `.rrow.is-income .rrow__value { color: var(--up) }` — `null` is `text`.
  final Color? valueColor;

  /// Dot-separated metadata under the subtitle.
  final List<String>? meta;

  /// The trailing value. Tabular and direction-isolated — a price and a time
  /// in the same row must not swap places in an RTL page.
  final String? value;
  final String? valueSub;

  final String? icon;

  /// The lead tile's fill, and [iconInk] its glyph — `.rrow__icon--accent` is
  /// `tint-accent` behind `accent`. Neither set is the neutral tile.
  final Color? iconTone;
  final Color? iconInk;

  /// A short code where an icon would say less — a currency, a ticker.
  final String? logo;

  /// `.rrow__thumb` — a 52 × 40 illustration, radius 12, in place of an
  /// icon tile.
  final Widget? thumb;

  final LumeBadge? badge;
  final LumeDelta? delta;

  /// A sparkline or other inline visualisation.
  final Widget? trailing;

  final VoidCallback? onTap;
  final bool chevron;

  /// The specimen's height, which has a meta line. The row has no minimum of
  /// its own — `.rrow` sets none — so a title and a subtitle make it 60, as
  /// Learning's insights measure.
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget row = Container(
      color: selected ? lume.tintAccent : null,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: <Widget>[
          if (thumb != null) ...<Widget>[
            ClipRRect(
              borderRadius: LumeRadius.brIcon,
              child: SizedBox(width: 52, height: 40, child: thumb),
            ),
            const SizedBox(width: 12),
          ] else if (icon != null || logo != null) ...<Widget>[
            _RowLead(icon: icon, logo: logo, tone: iconTone, ink: iconInk),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _TitleLine(
                  title: Text(
                    title,
                    // Measured: 14 / 700 / −0.024em on the font's own 18.
                    style: LumeType.tracked(
                      LumeType.natural(
                        context,
                        context.lumeType.body,
                      ).copyWith(fontWeight: FontWeight.w700),
                      -0.024,
                    ).copyWith(color: lume.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  badge: badge,
                ),
                if (subtitle != null) ...<Widget>[
                  // `.rrow__body { gap: 1px }`.
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    // Measured: 11 / 500, `text-2`, on 13.
                    style: LumeType.natural(
                      context,
                      context.lumeType.metaSmall,
                    ).copyWith(color: lume.text2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (meta != null && meta!.isNotEmpty) ...<Widget>[
                  // `gap: 1px` then `.rrow__meta { margin-top: 3px }`.
                  const SizedBox(height: 4),
                  _MetaLine(parts: meta!, lineHeight: metaLineHeight),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            trailing!,
          ],
          if (value != null || valueSub != null || delta != null) ...<Widget>[
            const SizedBox(width: 12),
            // Deliberately not `Flexible`: this sits beside the title's own
            // `Expanded` above, and a second flex child here would split the
            // row's remaining space between the two rather than leaving the
            // title with all of it, moving this column (and the chevron
            // after it) — a real regression a parity test caught (wave 9).
            // `LumeDelta`'s own text already guards its narrower overflow.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final (int, Widget) w in <Widget>[
                  if (value != null)
                    // `.rrow__value` — 14 / 700 / −.03em on the font's own
                    // 18.
                    LumeNumerals(
                      value!,
                      style: LumeType.numeric(
                        LumeType.tracked(
                          LumeType.natural(
                            context,
                            context.lumeType.body,
                          ).copyWith(fontWeight: FontWeight.w700),
                          -0.03,
                        ),
                      ).copyWith(color: valueColor ?? lume.text),
                    ),
                  // `.rrow__valuesub` — 10 / 600 on the font's own 12.
                  if (valueSub != null)
                    Text(
                      valueSub!,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 10,
                          ).copyWith(
                            color: lume.text3,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ?delta,
                ].indexed) ...<Widget>[
                  // `.rrow__end { gap: 2px }`.
                  if (w.$1 > 0) const SizedBox(height: 2),
                  w.$2,
                ],
              ],
            ),
          ],
          if (chevron) ...<Widget>[
            // `.rrow { gap: 12px }` — the chevron is a flex item like the rest.
            const SizedBox(width: 12),
            LumeIcon(LumeIcons.chevR, size: 15, color: lume.text3),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return LumePressable(
      onTap: onTap,
      button: false,
      selected: selected,
      semanticLabel: _spoken,
      minSize: LumeSpace.tap,
      borderRadius: BorderRadius.zero,
      child: row,
    );
  }

  String get _spoken => <String?>[
    title,
    badge?.label,
    subtitle,
    value,
    valueSub,
  ].whereType<String>().join(', ');
}

/// `.rrow__titleline { display: flex; gap: 6px; min-width: 0 }` — the title
/// ellipsizes and the badge keeps its width, on one line. That line holds
/// while the badge and a readable scrap of title fit; when they cannot — a
/// long value beside it at 200 % — the badge goes under the title rather than
/// past the row's edge.
class _TitleLine extends StatelessWidget {
  const _TitleLine({required this.title, this.badge});

  final Widget title;
  final LumeBadge? badge;

  /// The least title worth keeping beside a badge, at 1×.
  static const double minTitle = 40;

  @override
  Widget build(BuildContext context) {
    final LumeBadge? b = badge;
    if (b == null) return title;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double need =
            LumeBadge.widthOf(context, b.label, b.tone) +
            6 +
            MediaQuery.textScalerOf(context).scale(minTitle);
        if (!box.hasBoundedWidth || box.maxWidth >= need) {
          return Row(
            children: <Widget>[
              Flexible(child: title),
              const SizedBox(width: 6),
              b,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: <Widget>[title, b],
        );
      },
    );
  }
}

class _RowLead extends StatelessWidget {
  const _RowLead({this.icon, this.logo, this.tone, this.ink});

  final String? icon;
  final String? logo;
  final Color? tone;
  final Color? ink;

  /// Measured: `.rrow__icon` 36 × 36; `.rrow__logo` 38 × 38. Both 12 px
  /// radius on `tintNeutral`.
  static const double size = 36;
  static const double logoSize = 38;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double side = logo != null ? logoSize : size;
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone ?? lume.tintNeutral,
        borderRadius: LumeRadius.brIcon,
      ),
      child: logo != null
          // `.rrow__logo` — 11 / 800 / −.02em, capitals, in the text ink.
          ? Text(
              LumeType.overline(context, logo!),
              maxLines: 1,
              style: LumeType.tracked(
                LumeType.natural(context, context.lumeType.metaSmall, size: 11),
                -0.02,
              ).copyWith(color: lume.text, fontWeight: FontWeight.w800),
            )
          // `.rrow__icon svg { width: 17px }`.
          : LumeIcon(icon!, size: 17, color: ink ?? lume.text2),
    );
  }
}

/// The dot-separated metadata line shared by the rich row and the record row.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.parts, this.lineHeight});

  final List<String> parts;
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    // `.rrow__meta` — 10 / 500 on the font's own 12, so two wrapped lines and
    // their 5-point gap measure 29.
    final TextStyle style =
        LumeType.natural(
          context,
          context.lumeType.metaSmall,
          size: 10,
        ).copyWith(
          color: lume.text3,
          fontWeight: FontWeight.w500,
          height: lineHeight,
        );

    // `.rrow__meta { display: flex; flex-wrap: wrap; align-items: center;
    // gap: 5px }` — every part and every dot is a flex item, so a long line
    // wraps between them, 5 apart both ways.
    final Widget dot = Container(
      width: 2.5,
      height: 2.5,
      decoration: BoxDecoration(
        color: lume.text3.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (int i = 0; i < parts.length; i++) ...<Widget>[
          if (i > 0) dot,
          Text(parts[i], style: style),
        ],
      ],
    );
  }
}

/// `.crow` — the dense secondary row.
///
/// Measured: 40 tall, `--pad-row`, 13 / 600 label, tabular 12 / 700 value.
class LumeCompactRow extends StatelessWidget {
  const LumeCompactRow({
    super.key,
    required this.label,
    this.subtitle,
    this.value,
    this.icon,
    this.onTap,
    this.chevron = true,
  });

  final String label;
  final String? subtitle;
  final String? value;
  final String? icon;
  final VoidCallback? onTap;

  /// Shown only when the row does something.
  final bool chevron;

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget row = Container(
      constraints: const BoxConstraints(minHeight: height),
      padding: LumeSpace.padRow,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            // `.crow__icon svg { width: 16px }`.
            LumeIcon(icon!, size: LumeSpace.iconSm, color: lume.text3),
            const SizedBox(width: 12),
          ],
          Expanded(
            // `.crow__label i { display: block; margin-top: 1px }` — the
            // subtitle sits *under* the label, not beside it. F2 read it as an
            // inline run, which held only because the component fixture never
            // gave the row one.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: LumeType.tracked(
                    LumeType.natural(context, context.lumeType.meta, size: 13),
                    -0.022,
                  ).copyWith(color: lume.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      style: LumeType.natural(
                        context,
                        context.lumeType.metaSmall,
                      ).copyWith(color: lume.text3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: 12),
            // Deliberately not `Flexible`: this sits beside the label's own
            // `Expanded` above, and a second flex child here would split the
            // row's remaining space between the two rather than leaving the
            // label with all of it — a real parity regression elsewhere in
            // this file's own history (wave 9).
            LumeNumerals(
              value!,
              style: LumeType.numeric(
                LumeType.tracked(
                  LumeType.natural(context, context.lumeType.label),
                  -0.02,
                ),
              ).copyWith(color: lume.text2),
            ),
          ],
          if (onTap != null && chevron) ...<Widget>[
            // `.crow { gap: 12px }` — the chevron is a flex item like the rest.
            const SizedBox(width: 12),
            LumeIcon(LumeIcons.chevR, size: 14, color: lume.text3),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return LumePressable(
      onTap: onTap,
      button: false,
      semanticLabel: value == null ? label : '$label, $value',
      // `button.crow` is 41 tall with its hairline. A pressable row keeps §9's
      // 44 instead — an accessibility adaptation, not parity (C62): a stack of
      // rows has no gap for a target to reach into, so the row itself grows.
      minSize: LumeSpace.tap,
      borderRadius: BorderRadius.zero,
      child: row,
    );
  }
}

/// `.rrec` — the record row.
///
/// Its own card. Carries an initial disc (records are the user's own words and
/// there is no icon for those) or a checkbox for a family that logs from the
/// row itself.
class LumeRecordRow extends StatelessWidget {
  const LumeRecordRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.value,
    this.initial,
    this.badge,
    this.selected = false,
    this.done = false,
    this.queuedLabel,
    this.onTap,
    this.onToggle,
    this.checkLabel,
  });

  final String title;
  final String? subtitle;
  final List<String>? meta;
  final String? value;

  /// The letter in the disc. Ignored when [onToggle] is set, which replaces the
  /// disc with a checkbox.
  final String? initial;

  final LumeBadge? badge;

  /// Selected in a detail pane. A persistent state, drawn with a tint and a
  /// border rather than a flash — it is not a press.
  final bool selected;

  /// Completed. Quieter, but never invisible: still a record to open and read.
  final bool done;

  /// An offline write not yet synced. §10: shown as queued, never as current.
  final String? queuedLabel;

  final VoidCallback? onTap;

  /// Fast optimistic logging — ticking writes immediately, with no form.
  final ValueChanged<bool>? onToggle;

  /// What the checkbox says it is — the family's own word ("Completed",
  /// "In basket"), with the row's title, so a screen reader hears which
  /// row's box it is on. Its state is carried as checked, not as words.
  final String? checkLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget card = AnimatedContainer(
      duration: LumeMotion.duration(context, LumeMotion.fast),
      curve: LumeMotion.ease,
      constraints: const BoxConstraints(minHeight: LumeSpace.tap),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      decoration: BoxDecoration(
        color: selected ? lume.tintAccent : lume.card,
        borderRadius: LumeRadius.brMd,
        border: Border.all(
          color: selected ? lume.accent.withValues(alpha: 0.45) : lume.border,
          width: LumeSpace.border,
        ),
        boxShadow: context.lumeShadows.xs,
      ),
      child: Row(
        children: <Widget>[
          if (onToggle != null)
            _RecordCheck(
              checked: done,
              label: checkLabel == null ? title : '$checkLabel, $title',
              onChanged: onToggle!,
            )
          else
            _RecordDisc(initial: initial ?? '·', dim: done),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              // `.rrec__body { gap: 2px }`.
              spacing: 2,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        title,
                        // Measured: 15 / 700 / −0.026em.
                        style:
                            LumeType.tracked(
                              LumeType.fit(context, context.lumeType.cardTitle),
                              -0.026,
                            ).copyWith(
                              color: done ? lume.text3 : lume.text,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: lume.text3,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...<Widget>[
                      const SizedBox(width: 7),
                      badge!,
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: LumeType.fit(
                      context,
                      context.lumeType.metaSmall,
                    ).copyWith(color: lume.text3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (meta != null && meta!.isNotEmpty) _RecordMeta(parts: meta!),
              ],
            ),
          ),
          if (value != null || queuedLabel != null) ...<Widget>[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (value != null)
                  LumeNumerals(
                    value!,
                    style: LumeType.numeric(
                      LumeType.tracked(
                        LumeType.fit(context, context.lumeType.cardTitle),
                        -0.03,
                      ),
                    ).copyWith(color: lume.text2),
                  ),
                if (queuedLabel != null)
                  Text(
                    queuedLabel!,
                    style: LumeType.fit(
                      context,
                      context.lumeType.metaSmall,
                    ).copyWith(color: lume.amberInk),
                  ),
              ],
            ),
          ],
          if (onTap != null) ...<Widget>[
            const SizedBox(width: LumeSpace.x2),
            LumeIcon(LumeIcons.chevR, size: 15, color: lume.text3),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return LumePressable(
      onTap: onTap,
      button: false,
      selected: selected,
      semanticLabel: _spoken,
      borderRadius: LumeRadius.brMd,
      minSize: LumeSpace.tap,
      child: card,
    );
  }

  String get _spoken =>
      <String?>[title, subtitle, value].whereType<String>().join(', ');
}

/// `.rrec__meta` — the record row's meta: the sub-line's 11 / 500 on its
/// 16-point line, one line, parts 5 apart with a dot between. Not `.rrow`'s
/// 10-point meta, which wraps.
class _RecordMeta extends StatelessWidget {
  const _RecordMeta({required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle style = LumeType.fit(
      context,
      context.lumeType.metaSmall,
    ).copyWith(color: lume.text3);
    final Widget dot = Container(
      width: 2.5,
      height: 2.5,
      decoration: BoxDecoration(
        color: lume.text3.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < parts.length; i++) ...<Widget>[
          if (i > 0) ...<Widget>[
            const SizedBox(width: 5),
            dot,
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              parts[i],
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// The initial disc. Measured: 38 × 38, circle, `tintAccent`, `accent-700`
/// ink at 15 / 700.
class _RecordDisc extends StatelessWidget {
  const _RecordDisc({required this.initial, this.dim = false});

  final String initial;
  final bool dim;

  static const double size = 38;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: lume.tintAccent,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: LumeType.fit(
              context,
              context.lumeType.cardTitle,
            ).copyWith(color: lume.accent700),
          ),
        ),
      ),
    );
  }
}

/// The checkbox a checkable family logs from. 38 px, so the row's own target
/// and the checkbox's do not fight each other.
class _RecordCheck extends StatelessWidget {
  const _RecordCheck({
    required this.checked,
    required this.label,
    required this.onChanged,
  });

  final bool checked;
  final String label;
  final ValueChanged<bool> onChanged;

  static const double size = 38;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      checked: checked,
      label: label,
      child: LumePressable(
        onTap: () => onChanged(!checked),
        borderRadius: LumeRadius.full,
        minSize: size,
        button: false,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: LumeMotion.duration(context, LumeMotion.fast),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: checked ? lume.accent : lume.tintNeutral,
            shape: BoxShape.circle,
            border: Border.all(
              color: checked ? lume.accent : lume.border2,
              width: LumeSpace.border,
            ),
          ),
          child: LumeIcon(
            LumeIcons.check,
            size: 17,
            color: checked ? lume.onAccent : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

/// `.rrecs` — record rows, stacked with a 10 px gap. Each is its own card, so
/// they are separated by space rather than by hairlines.
class LumeRecordList extends StatelessWidget {
  const LumeRecordList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (int i = 0; i < children.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(height: 10),
        children[i],
      ],
    ],
  );
}

/// `.xrow` — progressive disclosure instead of clutter.
class LumeExpandRow extends StatefulWidget {
  const LumeExpandRow({
    super.key,
    required this.header,
    required this.child,
    this.initiallyExpanded = false,
  });

  final Widget header;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<LumeExpandRow> createState() => _LumeExpandRowState();
}

class _LumeExpandRowState extends State<LumeExpandRow> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _open,
          child: LumePressable(
            onTap: () => setState(() => _open = !_open),
            borderRadius: LumeRadius.brSm,
            excludeSemantics: true,
            child: Padding(
              padding: LumeSpace.padRow,
              child: Row(
                children: <Widget>[
                  Expanded(child: widget.header),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: LumeMotion.duration(context, LumeMotion.fast),
                    curve: LumeMotion.ease,
                    child: LumeIcon(
                      LumeIcons.chevD,
                      size: LumeSpace.iconSm,
                      color: lume.text3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The body is absent when collapsed, not merely zero-height. A
        // cross-fade would keep it in the tree, which means a screen reader
        // would read content the sighted user cannot see — the reference's
        // `<details>` does not render a closed body either.
        _Disclosure(open: _open, child: widget.child),
      ],
    );
  }
}

/// The expanding half of [LumeExpandRow].
///
/// `AnimatedSize` is skipped entirely when motion is reduced rather than given
/// a zero duration: at zero it re-dirties itself inside its own `performLayout`
/// and asserts. With no motion there is nothing to animate anyway.
class _Disclosure extends StatelessWidget {
  const _Disclosure({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget body = open
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
              start: LumeSpace.padCard,
              end: LumeSpace.padCard,
              bottom: LumeSpace.padCard,
            ),
            child: child,
          )
        : const SizedBox(width: double.infinity);

    if (!LumeMotion.mayRepeat(context)) return body;

    return AnimatedSize(
      duration: LumeMotion.fast,
      curve: LumeMotion.ease,
      alignment: AlignmentDirectional.topStart,
      child: body,
    );
  }
}
