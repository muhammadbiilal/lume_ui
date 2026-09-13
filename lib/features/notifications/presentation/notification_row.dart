/// `.nrow` — one notification in the centre.
///
/// The row draws what it was given and asks nothing. Whether the body is the
/// real one, a discreet one, or "Content hidden" was decided before it got
/// here, which is the only way to be sure a preview cannot leak: there is
/// nothing on this widget to leak *from*.
///
/// Its own structure, from `screens/notifications.css`: a tinted icon whose
/// colour is the category's, a title line that may carry a priority badge,
/// the body, and a meta line of age · category · state. An unread row is
/// tinted and carries a dot; a row with an action or that is not folded also
/// carries an action strip.
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

  /// `.nrow__icon` is 34 × 34 with a 17 px glyph.
  static const double iconSize = 34;

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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        color: n.read
            ? null
            // `.nrow.is-unread` — four per cent of accent *into the card*.
            : Color.lerp(lume.card, lume.accent, 0.04),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: lumeNotificationTint(lume, n.category),
                  borderRadius: LumeRadius.brSm,
                ),
                child: Center(
                  child: LumeIcon(
                    n.icon,
                    size: LumeSpace.iconMd,
                    color: lumeNotificationInk(lume, n.category),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
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
                                  -0.022,
                                ).copyWith(
                                  color: lume.text,
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeLabel != null) ...<Widget>[
                          const SizedBox(width: 7),
                          LumeBadge(label: badgeLabel, tone: tone!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.body,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 12.5,
                          ).copyWith(
                            color: lume.text2,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 11,
                          ).copyWith(
                            color: lume.text3,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!n.read) ...<Widget>[
                const SizedBox(width: 10),
                Container(
                  width: 7,
                  height: 7,
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

    final bool hasStrip =
        (actionLabel != null && onAct != null) ||
        (!n.grouped && onDismiss != null);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: lume.border, width: LumeSpace.border),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          main,
          if (hasStrip)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 62,
                end: 10,
                bottom: 10,
              ),
              child: Row(
                children: <Widget>[
                  if (actionLabel != null && onAct != null)
                    LumePressable(
                      onTap: onAct,
                      semanticLabel: '$actionLabel, ${n.title}',
                      borderRadius: LumeRadius.brSm,
                      minSize: LumeSpace.tap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        child: Text(
                          actionLabel!,
                          style:
                              LumeType.tracked(
                                LumeType.natural(
                                  context,
                                  context.lumeType.metaSmall,
                                  size: 12,
                                ),
                                -0.01,
                              ).copyWith(
                                color: lume.accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!n.grouped && onDismiss != null)
                    LumePressable(
                      onTap: onDismiss,
                      semanticLabel: '${l.nDismiss}, ${n.title}',
                      borderRadius: LumeRadius.full,
                      minSize: LumeSpace.tap,
                      child: LumeIcon(
                        LumeIcons.x,
                        size: LumeSpace.iconSm,
                        color: lume.text3,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
