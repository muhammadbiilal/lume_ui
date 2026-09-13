/// `.nrow` — one notification in the centre.
///
/// The row draws what it was given and asks nothing. Whether the body is the
/// real one, a discreet one, or "Content hidden" was decided before it got
/// here, which is the only way to be sure a preview cannot leak: there is
/// nothing on this widget to leak *from*.
///
/// Its geometry, from `screens/notifications.css` and measured against the
/// running reference (`measure_destinations.mjs --screen notifications`):
///
/// * `.nrow__main` pads `--pad-row` (12 × 16), with a 36-point icon, a 12-point
///   gap, the body, and the unread dot — 80.58 tall for one line of text;
/// * the title is 14 / 700 / −.026em on a 1.3 line, the body 12 / 400 on
///   1.45 three below it, the meta line 11 / 600 five below that;
/// * `.nrow__acts` is 44 tall — a 32-point line plus 12 underneath — inset 64
///   at the start so a button sits under the title;
/// * an unread row is tinted across its *whole* height, action strip and
///   all, and carries a three-point accent bar at its inline start;
/// * an expired row is drawn at 58 % and loses its dot.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/notification_model.dart';

/// The tint a category's icon carries. `.nrow__icon--<category>`.
Color lumeNotificationTint(LumeColors lume, String category) =>
    switch (category) {
      'faith' => lume.tintAccent,
      'markets' => lume.toneGreen,
      'finance' => lume.toneAmber,
      'travel' => lume.tone(lume.violet),
      'weather' => lume.tone(lume.sky),
      'documents' => lume.tone(lume.indigo),
      'health' => lume.tone(lume.rose),
      _ => lume.tintNeutral,
    };

/// The ink that sits on that tint.
Color lumeNotificationInk(LumeColors lume, String category) =>
    switch (category) {
      'faith' => lume.accent,
      'markets' => lume.up,
      'finance' => lume.amber,
      'travel' => lume.violet,
      'weather' => lume.sky,
      'documents' => lume.indigo,
      'health' => lume.rose,
      _ => lume.text2,
    };

/// How long ago, in the reader's own words.
///
/// `just now` under a minute, minutes under an hour, hours under a day, then
/// days. Computed from the row's own age against the injected clock, never
/// from a wall clock.
String lumeNotificationAge(AppLocalizations l, int agoMinutes) {
  if (agoMinutes < 1) return l.nNow;
  if (agoMinutes < 60) return l.nMinsAgo(agoMinutes);
  if (agoMinutes < 1440) return l.nHoursAgo((agoMinutes / 60).round());
  return l.nDaysAgo((agoMinutes / 1440).round());
}

class LumeNotificationRow extends StatelessWidget {
  const LumeNotificationRow({
    super.key,
    required this.notification,
    required this.categoryLabel,
    this.actionLabel,
    this.onOpen,
    this.onAct,
    this.onDismiss,
    this.isLast = false,
  });

  final LumeNotification notification;

  /// The category's own name, already localised. Omitted from the meta line
  /// of a folded row, which stands for several categories' worth of nothing.
  final String categoryLabel;

  /// The verb on the row's own button, already localised.
  final String? actionLabel;

  final VoidCallback? onOpen;
  final VoidCallback? onAct;
  final VoidCallback? onDismiss;
  final bool isLast;

  /// `--pad-row: 12px 16px`.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  /// `.nrow__icon` — 36 × 36 on `--r-icon`, with a 17-point glyph.
  static const double iconSize = 36;
  static const double glyph = 17;

  /// `.nrow__main { gap: 12px }`.
  static const double gap = 12;

  /// `.nrow__dot` — 8 × 8, six below the top of the title.
  static const double dot = 8;

  /// `.nrow.is-unread::before { width: 3px }`.
  static const double unreadBar = 3;

  /// `.nrow__acts { padding: 0 16px 12px 64px }` — the icon's inset, its
  /// width and its gap, so a button starts under the title.
  static const double actsStart = 64;

  /// `.nrow__dismiss` — a 32-point circle holding a 14-point cross. Also the
  /// height of the strip's one line, which the action pill is centred in.
  static const double dismissSize = 32;
  static const double dismissGlyph = 14;

  /// `.nrow.is-expired { opacity: .58 }`.
  static const double expiredOpacity = 0.58;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeNotification n = notification;

    final LumeBadgeTone? tone = switch (n.priority) {
      LumeNotificationPriority.critical => LumeBadgeTone.late_,
      LumeNotificationPriority.high => LumeBadgeTone.warn,
      _ => null,
    };
    final String? badgeLabel = switch (n.priority) {
      LumeNotificationPriority.critical => l.nPriCritical,
      LumeNotificationPriority.high => l.nPriHigh,
      _ => null,
    };

    final String meta = <String>[
      lumeNotificationAge(l, n.agoMinutes),
      if (!n.grouped) categoryLabel,
      if (n.actioned) l.nActioned,
      if (n.expired) l.nExpired,
    ].join(' · ');

    // Everything a screen reader needs, in one sentence, so the row is not
    // read as five unrelated fragments. The unread dot is a word here.
    final String spoken = <String>[
      if (!n.read) l.nUnread,
      n.title,
      ?badgeLabel,
      n.body,
      meta,
    ].join(', ');

    final Widget main = LumePressable(
      onTap: onOpen,
      semanticLabel: spoken,
      minSize: 0,
      child: Padding(
        padding: padding,
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: lumeNotificationTint(lume, n.category),
                  borderRadius: LumeRadius.brIcon,
                ),
                child: Center(
                  child: LumeIcon(
                    n.icon,
                    size: glyph,
                    color: lumeNotificationInk(lume, n.category),
                  ),
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // `.nrow__titleline { align-items: center; gap: 6px }`.
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            n.title,
                            style:
                                LumeType.tracked(
                                  LumeType.natural(
                                    context,
                                    context.lumeType.meta,
                                    size: 14,
                                  ),
                                  -0.026,
                                ).copyWith(
                                  // `.is-actioned .nrow__title` — done with,
                                  // so it stops asking to be read first.
                                  color: n.actioned ? lume.text2 : lume.text,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  leadingDistribution:
                                      TextLeadingDistribution.even,
                                ),
                          ),
                        ),
                        if (badgeLabel != null) ...<Widget>[
                          const SizedBox(width: 6),
                          LumeBadge(label: badgeLabel, tone: tone!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 12,
                          ).copyWith(
                            color: lume.text2,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meta,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 11,
                          ).copyWith(
                            color: lume.text3,
                            fontWeight: FontWeight.w600,
                            // Measured 13: 11 px on a normal line box, which
                            // is shorter than the font's own natural one.
                            height: 13 / 11,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                    ),
                  ],
                ),
              ),
              if (!n.read && !n.expired) ...<Widget>[
                const SizedBox(width: gap),
                Container(
                  width: dot,
                  height: dot,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: lume.accent,
                    borderRadius: LumeRadius.full,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final bool canAct = actionLabel != null && onAct != null;
    final bool canDismiss = !n.grouped && onDismiss != null;

    // `.nrow__acts` is a 32-point line with twelve under it: 44, which is
    // also the smallest target §9 allows. So each control's target is the
    // strip's full height and its drawing sits in the top 32 — the targets
    // are accessible and the row is exactly as tall as the reference's.
    // At the end, the cross's 44-point target spends six of the reference's
    // sixteen-point inset, so the circle still ends sixteen from the edge.
    final Widget strip = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: actsStart,
        end: 16 - (LumeSpace.tap - dismissSize) / 2,
      ),
      child: SizedBox(
        height: LumeSpace.tap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (canAct)
              LumePressable(
                onTap: onAct,
                semanticLabel: '$actionLabel, ${n.title}',
                borderRadius: LumeRadius.full,
                minSize: 0,
                child: SizedBox(
                  height: LumeSpace.tap,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(
                      height: dismissSize,
                      child: Center(
                        // `.nrow__act` — a tinted pill, 7 × 14.
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: lume.tintAccent,
                            borderRadius: LumeRadius.full,
                          ),
                          child: Text(
                            actionLabel!,
                            style:
                                LumeType.natural(
                                  context,
                                  context.lumeType.metaSmall,
                                  size: 12,
                                ).copyWith(
                                  color: lume.accent,
                                  fontWeight: FontWeight.w700,
                                  // Measured 29 with 7 above and below: a
                                  // 15-point line for 12 px.
                                  height: 15 / 12,
                                  leadingDistribution:
                                      TextLeadingDistribution.even,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if (canDismiss)
              LumePressable(
                onTap: onDismiss,
                semanticLabel: '${l.nDismiss}, ${n.title}',
                borderRadius: LumeRadius.full,
                minSize: 0,
                child: SizedBox(
                  width: LumeSpace.tap,
                  height: LumeSpace.tap,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: dismissSize,
                      height: dismissSize,
                      child: Center(
                        child: LumeIcon(
                          LumeIcons.x,
                          size: dismissGlyph,
                          color: lume.text3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    Widget row = Container(
      decoration: BoxDecoration(
        // `.nrow.is-unread` — four per cent of accent into the card, across
        // the whole row.
        color: n.read ? null : Color.lerp(lume.card, lume.accent, 0.04),
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: lume.border, width: LumeSpace.border),
              ),
      ),
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[main, if (canAct || canDismiss) strip],
          ),
          if (!n.read)
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: unreadBar,
              child: ColoredBox(color: lume.accent),
            ),
        ],
      ),
    );

    if (n.expired) row = Opacity(opacity: expiredOpacity, child: row);
    return row;
  }
}
