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
import '../../theme/lume/lume_gradients.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
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
  });

  final List<LumeColumn> columns;

  /// Cell text, already formatted. One list per row, matching [columns].
  final List<List<String>> rows;

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
              for (final List<String> r in rows)
                if (c < r.length)
                  measure(r[c], cellStyle(context, c)) + cellPadding.horizontal,
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
    this.header = false,
    this.last = false,
    this.onTap,
  });

  final List<LumeColumn> columns;
  final List<double> widths;
  final List<String> cells;
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
              child: LumeNumerals(
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
/// The art is deterministic from its seed, so the same story gets the same
/// picture on every render and a golden does not flicker.
class LumeImageCard extends StatelessWidget {
  const LumeImageCard({
    super.key,
    required this.title,
    required this.seed,
    this.kicker,
    this.meta,
    this.gradient,
    this.glyph,
    this.onTap,
    this.width,
  });

  final String title;

  /// Chooses the colourway and the shapes. Same seed, same art.
  final int seed;

  final String? kicker;
  final String? meta;
  final LumeGradient? gradient;
  final String? glyph;
  final VoidCallback? onTap;
  final double? width;

  static const double artHeight = 108;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Map<String, LumeGradient> ways = context.lumeGradients.all;
    final LumeGradient g =
        gradient ?? ways.values.elementAt(seed.abs() % ways.length);

    final Widget card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: LumeRadius.brMd,
          child: Container(
            height: artHeight,
            width: double.infinity,
            decoration: BoxDecoration(gradient: g.linear),
            child: CustomPaint(
              painter: _ArtPainter(seed: seed, ink: g.on),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (kicker != null)
          Text(
            LumeType.overline(context, kicker!),
            style: LumeType.overlineStyle(
              context,
              context.lumeType,
            ).copyWith(color: lume.accent700),
          ),
        Text(
          title,
          style: LumeType.fit(
            context,
            context.lumeType.cardTitle,
          ).copyWith(color: lume.text),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (meta != null)
          Text(
            meta!,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );

    final Widget sized = width == null
        ? card
        : SizedBox(width: width, child: card);

    if (onTap == null) return sized;
    return LumePressable(
      onTap: onTap,
      button: false,
      semanticLabel: title,
      borderRadius: LumeRadius.brMd,
      minSize: 0,
      child: sized,
    );
  }
}

/// Deterministic decorative shapes. Soft geometry and floating circles, from
/// §53's visual language — never a stock illustration.
class _ArtPainter extends CustomPainter {
  const _ArtPainter({required this.seed, required this.ink});

  final int seed;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    // A tiny deterministic sequence: same seed, same picture, every time.
    int s = seed.abs() * 2654435761 % 2147483647;
    double next() {
      s = (s * 1103515245 + 12345) % 2147483647;
      return s / 2147483647;
    }

    final Paint p = Paint()..color = ink.withValues(alpha: 0.14);
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(next() * size.width, next() * size.height),
        12 + next() * 34,
        p,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.55,
          size.height * 0.35,
          size.width * 0.5,
          size.height * 0.7,
        ),
        const Radius.circular(26),
      ),
      Paint()..color = ink.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.seed != seed || old.ink != ink;
}

/// `.hstrip` — a horizontally scrolling rail of cards.
class LumeHorizontalStrip extends StatelessWidget {
  const LumeHorizontalStrip({
    super.key,
    required this.children,
    this.gutters = true,
    this.itemWidth = 220,
  });

  final List<Widget> children;
  final bool gutters;
  final double itemWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: gutters
        ? const EdgeInsetsDirectional.symmetric(
            horizontal: LumeSpace.pageCompact,
          )
        : EdgeInsets.zero,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: LumeSpace.x3),
          SizedBox(width: itemWidth, child: children[i]),
        ],
      ],
    ),
  );
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
