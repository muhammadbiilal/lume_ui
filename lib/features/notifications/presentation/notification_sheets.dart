/// The two notification sheets.
///
/// `#sheet-notifpush` asks for permission, and `#sheet-notifprefs` is the
/// preferences as a sheet. There is no third: the inventory's third F5D sheet
/// is `#sheet-search`, which is not notification-related and is already
/// built. `sheet-confirm` is raised by `services/account-forms.js`, and
/// `sheet-recdelete` by the record engine — neither belongs to notifications.
///
/// **Permission is never requested at boot.** The reader sees what will be
/// sent first, and a refusal is a choice with a button rather than the
/// absence of one. Nothing here touches a platform permission API: this
/// conversion has no push, and the sheet reports rather than requests.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/notification_feed.dart';
import '../../../app/providers/personalisation.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/domain/notification_prefs.dart';
import '../../account/presentation/account_parts.dart';
import '../../account/presentation/account_routes.dart'
    show lumeNotificationTypeLabel;
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../presentation/notification_centre.dart';

/// Ask whether Lume may send notifications.
///
/// Returns `true` when the reader said yes. **It does not grant anything** —
/// there is no push in this build — so the caller records the answer and the
/// surfaces report it.
Future<bool?> showLumeNotificationPushSheet(BuildContext context) =>
    showLumeSheet<bool>(
      context: context,
      barrierLabel: AppLocalizations.of(context).nPushTitle,
      child: Builder(
        builder: (BuildContext sheetContext) => LumeSheet(
          child: LumeNotificationPushAsk(sheetContext: sheetContext),
        ),
      ),
    );

/// `.pushask` — the body of `#sheet-notifpush`.
class LumeNotificationPushAsk extends ConsumerWidget {
  const LumeNotificationPushAsk({super.key, required this.sheetContext});

  /// The sheet's own context, so the buttons pop the sheet rather than the
  /// screen beneath it — the same lesson the account's confirmation learned
  /// when sheets moved to the root navigator.
  final BuildContext sheetContext;

  /// The reference lists at most six categories.
  static const int listLimit = 6;

  static const Key allowKey = ValueKey<String>('notifpush.allow');
  static const Key laterKey = ValueKey<String>('notifpush.later');

  /// One line per category this reader would actually hear from — derived
  /// from the same sources and the same eligibility the centre uses, so the
  /// promise made here is the promise the centre keeps.
  static List<LumeNotificationCategory> categoriesFor(
    LumeEligibility eligibility,
    LumeUserContext user,
  ) {
    final List<LumeNotificationCategory> out = <LumeNotificationCategory>[];
    final Set<String> seen = <String>{};
    for (final LumeNotificationSource src in kNotificationSources) {
      if (seen.contains(src.category)) continue;
      if (eligibility.visibleById(src.tool, user) == null) continue;
      seen.add(src.category);
      for (final LumeNotificationCategory c in kNotificationCategories) {
        if (c.id == src.category) out.add(c);
      }
    }
    return out.take(listLimit).toList(growable: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final List<LumeNotificationCategory> cats = categoriesFor(
      ref.watch(eligibilityProvider),
      LumeUserContext.from(ref.watch(startupControllerProvider).state.profile),
    );

    final TextStyle textStyle =
        LumeType.natural(
          context,
          context.lumeType.metaSmall,
          size: 13,
        ).copyWith(
          color: lume.text2,
          fontWeight: FontWeight.w400,
          height: 1.5,
          leadingDistribution: TextLeadingDistribution.even,
        );

    // `.pushask__text { max-width: 32ch }` — thirty-two of the font's own
    // zeros, measured rather than guessed, so it follows the type scale.
    final TextPainter zero = TextPainter(
      text: TextSpan(text: '0', style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double measure = zero.width * 32;
    zero.dispose();

    // `.pushask__later` is a 32-point line; its 44-point target spends six of
    // the fourteen above it and six of the twenty below, so nothing moves.
    const double laterOverhang = (LumeSpace.tap - 32) / 2;

    // `.pushask { text-align: center; padding: 8px 4px 20px }`.
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 20 - laterOverhang),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // `.pushask__art` — 56 on `--r-lg`, a ringing bell at 26.
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: lume.tintAccent,
                borderRadius: LumeRadius.brLg,
              ),
              child: Center(
                child: LumeIcon(
                  LumeIcons.bellRing,
                  size: 26,
                  color: lume.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // `.pushask__title` — 20 / 800 / −.035em.
          Text(
            l.nPushTitle,
            textAlign: TextAlign.center,
            style: LumeType.tracked(
              LumeType.natural(context, context.lumeType.title, size: 20),
              -0.035,
            ).copyWith(color: lume.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: measure),
              child: Text(
                l.nPushText,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
          ),
          // `.pushask__list { justify-content: center; gap: 8px;
          // margin: 20px 0 }` — what would arrive, as pills.
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final LumeNotificationCategory c in cats)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: lume.card2,
                    borderRadius: LumeRadius.full,
                    border: Border.all(
                      color: lume.border,
                      width: LumeSpace.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      LumeIcon(c.icon, size: 14, color: lume.accent),
                      const SizedBox(width: 6),
                      Text(
                        lumeNotificationCategoryLabel(l, c.id),
                        style:
                            LumeType.natural(
                              context,
                              context.lumeType.metaSmall,
                              size: 12,
                            ).copyWith(
                              color: lume.text,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // `.btn.btn--accent.btn--block` — the words alone.
          LumeButton.accent(
            key: allowKey,
            label: l.nPushAllow,
            block: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          // `.pushask__later { margin: 14px auto 0; padding: 8px 16px;
          // font-size: 13px; font-weight: 650; color: var(--text-3) }` — a
          // bare text control, not a `.btn`. Declining should not look like a
          // second offer.
          const SizedBox(height: 14 - laterOverhang),
          Center(
            child: LumePressable(
              key: laterKey,
              onTap: () => Navigator.of(sheetContext).pop(false),
              semanticLabel: l.nPushNotNow,
              borderRadius: LumeRadius.brSm,
              minSize: LumeSpace.tap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Text(
                  l.nPushNotNow,
                  style: LumeType.natural(
                    context,
                    context.lumeType.meta,
                    size: 13,
                  ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The notification preferences, as a sheet.
///
/// The same content as the account's Notifications *route* and the same
/// store: `#sheet-notifprefs` is raised from the notification centre, where
/// walking out to the account section to switch one category off would lose
/// the reader's place. One preference record, two doors — and the categories
/// come from `kNotificationCategories` rather than from a second list.
Future<void> showLumeNotificationPrefsSheet(BuildContext context) =>
    showLumeSheet<void>(
      context: context,
      barrierLabel: AppLocalizations.of(context).nSettings,
      child: Builder(
        builder: (BuildContext sheetContext) => LumeSheet(
          tall: true,
          title: AppLocalizations.of(sheetContext).nSettings,
          subtitle: AppLocalizations.of(sheetContext).nSettingsSub,
          closeLabel: AppLocalizations.of(sheetContext).actionClose,
          onClose: () => Navigator.of(sheetContext).maybePop(),
          child: const LumeNotificationPrefsSheet(),
        ),
      ),
    );

/// `#sheet-notifprefs` — `renderNotifPrefs`, over whatever raised it.
///
/// The reference draws the same five sections here as on the account's
/// Notifications route, from the same function: General, Categories, By tool,
/// Quiet hours and Privacy, then a control that brings dismissed rows back
/// (C44). Its heads are `UI.sectionHead` — a head over a list, not a `.sect`
/// with a page's gap above it — because the sheet body already pads.
class LumeNotificationPrefsSheet extends ConsumerWidget {
  const LumeNotificationPrefsSheet({super.key});

  /// `.sect__head { margin-bottom: 12px }`.
  static const double headGap = 12;

  /// `.npref__tool { margin: 18px 0 8px }` — the top collapsing with the
  /// head's twelve when it is the first thing under one.
  static const double toolTop = 18;
  static const double toolBottom = 8;

  /// `.btnrow { margin-top: 20px }`.
  static const double restoreTop = 20;

  static const Key restoreKey = ValueKey<String>('notifprefs.restore');

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      // The store is a `ChangeNotifier` behind a plain provider, so watching
      // the provider does not hear a write. The sheet listens to the store
      // itself — otherwise a switch stays where it was after it is flipped,
      // and a second step starts again from the hour the sheet opened on.
      ListenableBuilder(
        listenable: ref.watch(notificationPrefsProvider),
        builder: (BuildContext context, Widget? _) => _sheet(context, ref),
      );

  Widget _sheet(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeNotificationPrefsStore store = ref.watch(
      notificationPrefsProvider,
    );
    final LumeNotificationPrefs prefs = store.prefs;
    final bool islamic =
        ref.watch(startupControllerProvider).state.profile.islamic ?? false;
    final LumeEligibility eligibility = ref.watch(eligibilityProvider);
    final LumeUserContext user = LumeUserContext.from(
      ref.watch(startupControllerProvider).state.profile,
    );
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );

    // Only what this reader can hear from (§64): a category with no visible
    // source, and a tool the reader cannot see, are absent rather than off.
    final List<LumeNotificationCategory> cats = kNotificationCategories
        .where((LumeNotificationCategory c) => c.faith ? islamic : true)
        .where(
          (LumeNotificationCategory c) => kNotificationSources.any(
            (LumeNotificationSource s) =>
                s.category == c.id &&
                eligibility.visibleById(s.tool, user) != null,
          ),
        )
        .toList(growable: false);

    final Map<String, List<LumeNotificationSource>> byTool =
        <String, List<LumeNotificationSource>>{};
    for (final LumeNotificationSource s in kNotificationSources) {
      if (eligibility.visibleById(s.tool, user) == null) continue;
      (byTool[s.tool] ??= <LumeNotificationSource>[]).add(s);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ---- General ----------------------------------------------------
          _Head(l.notifPrefGeneral),
          LumeAccountList(
            rows: <Widget>[
              LumeSettingsRow(
                title: l.notifPrefPush,
                // What the OS has granted, not what the app would like. This
                // build never asks, so it never claims to have been allowed.
                subtitle: l.acctPushAsk,
                toggle: prefs.push,
                onTap: () => store.write(prefs.copyWith(push: !prefs.push)),
              ),
              LumeSettingsRow(
                title: l.notifPrefInApp,
                subtitle: l.notifPrefInAppSub,
                toggle: prefs.inApp,
                onTap: () => store.write(prefs.copyWith(inApp: !prefs.inApp)),
              ),
              LumeSettingsRow(
                title: l.notifPrefSound,
                toggle: prefs.sound,
                onTap: () => store.write(prefs.copyWith(sound: !prefs.sound)),
              ),
              LumeSettingsRow(
                title: l.notifPrefHaptics,
                toggle: prefs.haptics,
                onTap: () =>
                    store.write(prefs.copyWith(haptics: !prefs.haptics)),
              ),
              LumeSettingsRow(
                title: l.notifPrefBadge,
                subtitle: l.notifPrefBadgeSub,
                toggle: prefs.badge,
                onTap: () => store.write(prefs.copyWith(badge: !prefs.badge)),
                isLast: true,
              ),
            ],
          ),

          // ---- Categories -------------------------------------------------
          _Head(l.notifPrefCategories, subtitle: l.notifPrefCategoriesSub),
          LumeAccountList(
            rows: <Widget>[
              for (int i = 0; i < cats.length; i++)
                LumeSettingsRow(
                  title: lumeNotificationCategoryLabel(l, cats[i].id),
                  toggle: prefs.isOn(cats[i].id),
                  onTap: () => store.write(
                    prefs.toggled(cats[i].id, on: !prefs.isOn(cats[i].id)),
                  ),
                  isLast: i == cats.length - 1,
                ),
            ],
          ),

          // ---- By tool ----------------------------------------------------
          _Head(l.notifPrefPerTool, subtitle: l.notifPrefPerToolSub),
          for (final (int i, MapEntry<String, List<LumeNotificationSource>> g)
              in byTool.entries.indexed) ...<Widget>[
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? toolTop - headGap : toolTop,
                bottom: toolBottom,
              ),
              child: _ToolLabel(LumeFeatureStrings.name(l, g.key)),
            ),
            LumeAccountList(
              rows: <Widget>[
                for (int j = 0; j < g.value.length; j++)
                  LumeSettingsRow(
                    title: lumeNotificationTypeLabel(l, g.value[j].type),
                    toggle: prefs.isTypeOn(g.value[j].id),
                    onTap: () => store.write(
                      prefs.typeToggled(
                        g.value[j].id,
                        on: !prefs.isTypeOn(g.value[j].id),
                      ),
                    ),
                    isLast: j == g.value.length - 1,
                  ),
              ],
            ),
          ],

          // ---- Quiet hours ------------------------------------------------
          _Head(l.notifPrefQuiet, subtitle: l.notifPrefQuietSub),
          // The same three rows the account's Notifications route draws,
          // from the same builder, over the same store.
          LumeAccountList(
            rows: lumeQuietHoursRows(
              l: l,
              f: f,
              prefs: prefs,
              onQuiet: (bool on) => store.write(prefs.copyWith(quiet: on)),
              onStep: ({required bool from, required int by}) =>
                  store.write(prefs.quietStepped(from: from, by: by)),
            ),
          ),

          // ---- Privacy ----------------------------------------------------
          _Head(l.acctPrivacyTitle, subtitle: l.notifPrefPrivacySub),
          LumeAccountList(
            rows: <Widget>[
              LumeSettingsRow(
                title: l.notifPrefPreview,
                subtitle: l.notifPrefPreviewSub,
                toggle: prefs.preview,
                onTap: () =>
                    store.write(prefs.copyWith(preview: !prefs.preview)),
              ),
              LumeSettingsRow(
                title: l.notifPrefSensitive,
                subtitle: l.notifPrefSensitiveSub,
                toggle: prefs.sensitivePreview,
                onTap: () => store.write(
                  prefs.copyWith(sensitivePreview: !prefs.sensitivePreview),
                ),
                isLast: true,
              ),
            ],
          ),

          // `notifrestore` — every dismissed row back, and a toast saying so.
          const SizedBox(height: restoreTop),
          LumeButton(
            key: restoreKey,
            label: l.notifPrefRestore,
            icon: LumeIcons.refresh,
            block: true,
            onPressed: () => unawaited(_restore(context, ref, l)),
          ),
        ],
      ),
    );
  }

  static Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    await ref.read(notificationFeedProvider).restoreAll();
    if (context.mounted) {
      showLumeToast(context, LumeToastData(message: l.nRestored));
    }
  }
}

/// `.sect__head` inside the sheet — 15 / 700 over an 11 / 500 line, twelve
/// above the list it names.
class _Head extends StatelessWidget {
  const _Head(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Padding(
      padding: const EdgeInsets.only(
        bottom: LumeNotificationPrefsSheet.headGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              style: LumeType.tracked(
                LumeType.natural(context, context.lumeType.meta, size: 15),
                -0.028,
              ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: LumeType.natural(
                context,
                context.lumeType.metaSmall,
                size: 11,
              ).copyWith(color: lume.text3, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.npref__tool` — a tool's name over its own switches, 11 / 700 / .04em,
/// uppercased for the eye and announced as written.
class _ToolLabel extends StatelessWidget {
  const _ToolLabel(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Text(
    LumeType.overline(context, name),
    semanticsLabel: name,
    style: LumeType.tracked(
      LumeType.natural(context, context.lumeType.metaSmall, size: 11),
      0.04,
    ).copyWith(color: context.lume.text3, fontWeight: FontWeight.w700),
  );
}
