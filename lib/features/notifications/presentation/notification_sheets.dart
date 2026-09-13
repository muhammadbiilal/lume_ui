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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/personalisation.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
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
import '../../catalogue/domain/eligibility.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: lume.tintAccent,
              borderRadius: LumeRadius.full,
            ),
            child: Center(
              child: LumeIcon(LumeIcons.bell, size: 24, color: lume.accent),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.nPushTitle,
          textAlign: TextAlign.center,
          style: LumeType.tracked(
            LumeType.natural(context, context.lumeType.title, size: 17),
            -0.03,
          ).copyWith(color: lume.text, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          l.nPushText,
          textAlign: TextAlign.center,
          style: LumeType.natural(
            context,
            context.lumeType.metaSmall,
            size: 12.5,
          ).copyWith(color: lume.text2, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),
        for (final LumeNotificationCategory c in cats)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                LumeIcon(c.icon, size: LumeSpace.iconSm, color: lume.text3),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lumeNotificationCategoryLabel(l, c.id),
                    style: LumeType.natural(
                      context,
                      context.lumeType.meta,
                      size: 13,
                    ).copyWith(color: lume.text2, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        LumeButton.accent(
          key: allowKey,
          label: l.nPushAllow,
          icon: LumeIcons.bell,
          block: true,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
        // `.pushask__later { margin: 14px auto 0; padding: 8px 16px;
        // font-size: 13px; font-weight: 650; color: var(--text-3) }` — a bare
        // text control, not a `.btn`. Declining should not look like a second
        // offer.
        const SizedBox(height: 6),
        Center(
          child: LumePressable(
            key: laterKey,
            onTap: () => Navigator.of(sheetContext).pop(false),
            semanticLabel: l.nPushNotNow,
            borderRadius: LumeRadius.brSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          closeLabel: AppLocalizations.of(sheetContext).actionClose,
          onClose: () => Navigator.of(sheetContext).maybePop(),
          child: const LumeNotificationPrefsSheet(),
        ),
      ),
    );

/// `#sheet-notifprefs` — the switches, over whatever raised them.
class LumeNotificationPrefsSheet extends ConsumerWidget {
  const LumeNotificationPrefsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeStoreGroup(
            icon: LumeIcons.bell,
            label: l.notifPrefGeneral,
            child: LumeAccountList(
              rows: <Widget>[
                LumeSettingsRow(
                  title: l.notifPrefInApp,
                  subtitle: l.notifPrefInAppSub,
                  toggle: prefs.inApp,
                  onTap: () => store.write(prefs.copyWith(inApp: !prefs.inApp)),
                ),
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
          ),
          const SizedBox(height: 14),
          LumeStoreGroup(
            icon: LumeIcons.sliders,
            label: l.notifPrefCategories,
            child: LumeAccountList(
              rows: <Widget>[
                for (int i = 0; i < cats.length; i++)
                  LumeSettingsRow(
                    icon: cats[i].icon,
                    title: lumeNotificationCategoryLabel(l, cats[i].id),
                    toggle: prefs.isOn(cats[i].id),
                    onTap: () => store.write(
                      prefs.toggled(cats[i].id, on: !prefs.isOn(cats[i].id)),
                    ),
                    isLast: i == cats.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
