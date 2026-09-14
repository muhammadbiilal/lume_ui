/// The data table, the image card, the horizontal strip and the related-tools
/// rail.
///
/// §86: a table scrolls horizontally rather than shrinking its columns to
/// illegibility, and the scroll region is focusable and labelled so a keyboard
/// can reach it. That last part is easy to lose in a port — a `Scrollable`
/// with no semantics is a region a screen-reader user cannot move.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_art.dart';
import 'lume_pressable.dart';

/// A table column.
@immutable
class LumeColumn {
  const LumeColumn({
    required this.label,
    this.numeric = false,
    this.strong = false,
    this.width,
  });

  final String label;

  /// Right-aligned in LTR, and set in tabular figures so a column of numbers
  /// lines up. Direction-isolated, so it does not reorder in an RTL page.
  final bool numeric;

  final bool strong;
  final double? width;
}

/// `.dtable` — a horizontally scrollable table with priority columns.
class LumeTable extends StatelessWidget {
  const LumeTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.label,
    this.onRowTap,
    this.cell,
    this.cellWidth,
  });

  final List<LumeColumn> columns;

  /// Cell text, already formatted. One list per row, matching [columns].
  final List<List<String>> rows;

  /// A cell drawn as something other than its text — `UI.delta` in a
  /// change column. The text still sizes the column and names the row;
  /// `null` from the builder draws the text.
  final Widget? Function(int row, int column)? cell;

  /// The drawn width of a [cell] the builder draws, without its padding —
  /// so the column wants what is on screen, not the text behind it. `null`
  /// measures the text.
  final double? Function(BuildContext context, int row, int column)? cellWidth;

  /// The accessible name of the scroll region. Required: an unlabelled
  /// scrollable is one a screen reader cannot announce.
  final String label;

  final void Function(int index)? onRowTap;

  /// `.dtable th` — `padding: 10px 14px`; `td` — `11px 14px`.
  static const EdgeInsets headPadding = EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 14,
  );
  static const EdgeInsets cellPadding = EdgeInsets.symmetric(
    vertical: 11,
    horizontal: 14,
  );

  /// `th` — 10 / 700 / .03em, uppercase, muted, on `card-2`.
  static TextStyle headStyle(BuildContext context) => LumeType.tracked(
    LumeType.natural(context, context.lumeType.metaSmall, size: 10),
    0.03,
  ).copyWith(color: context.lume.text3, fontWeight: FontWeight.w700);

  /// `td` — 12 / 600, `text-2`; the first column is `text`.
  static TextStyle cellStyle(BuildContext context, int column) =>
      LumeType.numeric(
        LumeType.natural(context, context.lumeType.meta),
      ).copyWith(
        color: column == 0 ? context.lume.text : context.lume.text2,
        fontWeight: FontWeight.w600,
      );

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final List<String> heads = <String>[
      for (final LumeColumn c in columns) LumeType.overline(context, c.label),
    ];

    // `width: 100%` under automatic table layout: every cell is `nowrap`, so a
    // column wants exactly its widest cell, and whatever the table has left
    // over is shared out in proportion to those widths. Narrower than the
    // columns want, it keeps them and scrolls instead (§86).
    double measure(String text, TextStyle style) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final double w = p.width;
      p.dispose();
      return w;
    }

    final List<double> wants = <double>[
      for (int c = 0; c < columns.length; c++)
        columns[c].width ??
            <double>[
              measure(heads[c], headStyle(context)) + headPadding.horizontal,
              for (int i = 0; i < rows.length; i++)
                if (c < rows[i].length)
                  (cellWidth?.call(context, i, c) ??
                          measure(rows[i][c], cellStyle(context, c))) +
                      cellPadding.horizontal,
            ].reduce((double a, double b) => a > b ? a : b),
    ];
    final double wanted = wants.fold(0, (double a, double b) => a + b);

    return Semantics(
      label: label,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        // The hairline is the box's own, outside the rows: a `DecoratedBox`
        // paints it over its child, which put the table two points short.
        child: Padding(
          padding: const EdgeInsets.all(LumeSpace.border),
          child: ClipRRect(
            borderRadius: LumeRadius.brLg,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double room = c.maxWidth.isFinite ? c.maxWidth : wanted;
                final double scale = wanted < room && wanted > 0
                    ? room / wanted
                    : 1;
                final List<double> widths = <double>[
                  for (final double w in wants) w * scale,
                ];
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TableRow(
                        columns: columns,
                        widths: widths,
                        cells: heads,
                        header: true,
                      ),
                      for (int i = 0; i < rows.length; i++)
                        _TableRow(
                          columns: columns,
                          widths: widths,
                          cells: rows[i],
                          drawn: cell == null ? null : (int c) => cell!(i, c),
                          last: i == rows.length - 1,
                          onTap: onRowTap == null ? null : () => onRowTap!(i),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.columns,
    required this.widths,
    required this.cells,
    this.drawn,
    this.header = false,
    this.last = false,
    this.onTap,
  });

  final List<LumeColumn> columns;
  final List<double> widths;
  final List<String> cells;
  final Widget? Function(int column)? drawn;
  final bool header;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget row = Container(
      decoration: BoxDecoration(
        color: header ? lume.card2 : null,
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: lume.border, width: LumeSpace.border),
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < cells.length && i < widths.length; i++)
            Container(
              width: widths[i],
              padding: header ? LumeTable.headPadding : LumeTable.cellPadding,
              alignment: columns[i].numeric
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              // `.is-rtl .dtable td, th { direction: ltr; unicode-bidi:
              // isolate }` — a band's two amounts must not trade places.
              child:
                  drawn?.call(i) ??
                  LumeNumerals(
                    cells[i],
                    style: header
                        ? LumeTable.headStyle(context)
                        : LumeTable.cellStyle(context, i),
                    maxLines: 1,
                  ),
            ),
        ],
      ),
    );

    if (onTap == null) return row;
    return LumePressable(
      onTap: onTap,
      button: false,
      borderRadius: BorderRadius.zero,
      semanticLabel: cells.join(', '),
      child: row,
    );
  }
}

/// `.imgcard` — a card whose lead is a generated illustration.
///
/// Stylesheet: 168 wide, radius 16 with the art clipped to it, the card fill
/// inside a one-point border, `shadow-sm`; a 96-point [LumeArt]; then
/// `10 12 12` of body — the kicker 10 / 700 / .04em in capitals and the accent,
/// the title 13 / 700 / −.026em on a 1.28 line 4 below it, the meta 10 / 500
/// muted 5 below that.
class LumeImageCard extends StatelessWidget {
  const LumeImageCard({
    super.key,
    required this.title,
    this.seed = 1,
    this.tone = LumeArtTone.accent,
    this.glyph,
    this.kicker,
    this.meta,
    this.onTap,
    this.width = defaultWidth,
    this.semanticLabel,
  });

  final String title;
  final int seed;
  final LumeArtTone tone;
  final String? glyph;
  final String? kicker;
  final String? meta;
  final VoidCallback? onTap;

  /// `.imgcard { width: 168px }`; `null` for `.imgcard--wide`.
  final double? width;
  final String? semanticLabel;

  static const double defaultWidth = 168;
  static const double artHeight = 96;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (kicker != null)
            Text(
              LumeType.overline(context, kicker!),
              style: LumeType.tracked(
                LumeType.natural(context, context.lumeType.label, size: 10),
                0.04,
              ).copyWith(fontWeight: FontWeight.w700, color: lume.accent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Padding(
            padding: EdgeInsets.only(top: kicker == null ? 0 : 4),
            child: Text(
              title,
              style: LumeType.fit(
                context,
                LumeType.tracked(
                  context.lumeType.body.copyWith(
                    fontSize: 13,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
                  ),
                  -0.026,
                ),
              ).copyWith(color: lume.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (meta != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                meta!,
                style: LumeType.natural(
                  context,
                  context.lumeType.metaSmall,
                  size: 10,
                ).copyWith(fontWeight: FontWeight.w500, color: lume.text3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );

    final Widget card = Container(
      width: width,
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brMd,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LumeRadius.md - LumeSpace.border),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: artHeight,
              child: LumeArt(tone: tone, seed: seed, glyph: glyph),
            ),
            body,
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return LumePressable(
      onTap: onTap,
      button: false,
      semanticLabel:
          semanticLabel ??
          <String?>[kicker, title, meta].whereType<String>().join(', '),
      borderRadius: LumeRadius.brMd,
      minSize: 0,
      child: card,
    );
  }
}

/// One tool in the related rail.
@immutable
class LumeRelatedTool {
  const LumeRelatedTool({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final String icon;
}

/// `.related` — what makes Lume one product rather than a folder of apps.
///
/// The list is eligibility-filtered before it arrives: a related tool the user
/// cannot see must not appear here, or the rail becomes a way around the
/// visibility rules.
class LumeRelatedTools extends StatelessWidget {
  const LumeRelatedTools({super.key, required this.tools, this.onOpen});

  final List<LumeRelatedTool> tools;
  final void Function(String id)? onOpen;

  /// `.related__item` — measured 78 wide, `12px 6px` padding, 7 between the
  /// 34-point icon tile and the label.
  static const double itemWidth = 78;
  static const double iconSize = 34;

  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) return const SizedBox.shrink();
    final LumeColors lume = context.lume;

    // `.related` is a single scrolling row, and its items stretch to the
    // tallest, so a name that takes two lines makes every tile two lines tall.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < tools.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: LumeSpace.x2),
              LumePressable(
                onTap: onOpen == null ? null : () => onOpen!(tools[i].id),
                semanticLabel: tools[i].name,
                borderRadius: LumeRadius.brSm,
                minSize: LumeSpace.tap,
                child: Container(
                  width: itemWidth,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lume.card,
                    borderRadius: LumeRadius.brSm,
                    border: Border.all(
                      color: lume.border,
                      width: LumeSpace.border,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: iconSize,
                        height: iconSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: lume.tintNeutral,
                          borderRadius: LumeRadius.brIcon,
                        ),
                        child: LumeIcon(
                          tools[i].icon,
                          size: LumeSpace.iconSm,
                          color: lume.text2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        tools[i].name,
                        textAlign: TextAlign.center,
                        style:
                            LumeType.tracked(
                              LumeType.fit(
                                context,
                                context.lumeType.metaSmall,
                              ).copyWith(fontSize: 10, height: 1.25),
                              -0.015,
                            ).copyWith(
                              color: lume.text,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
