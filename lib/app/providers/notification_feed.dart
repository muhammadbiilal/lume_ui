/// The notification feed, for the centre and the banner.
///
/// One repository, two surfaces — the centre and the banner read the same
/// feed, so a row cannot appear in one and not the other. It is built from
/// the launch's own profile, the shared eligibility selector and the *same*
/// preference record the account's Notifications route writes, so switching a
/// category off there empties it here without either surface knowing about
/// the other.
///
/// **Nothing behind it is durable or live.** `LumeFixtureNotificationRepository`
/// reports `isDurable == false`, and the centre says on screen that its rows
/// are samples.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalogue/domain/eligibility.dart';
import '../../features/notifications/data/notification_fixtures.dart';
import '../../features/notifications/domain/notification_model.dart';
import '../../features/startup/application/startup_controller.dart';
import '../../l10n/app_localizations.dart';
import 'locale_provider.dart';
import 'personalisation.dart';
import 'shell_provider.dart';

/// The strings the feed resolves against.
///
/// Only a few of them: the sample titles and bodies are fixture content and
/// are not translated, but "Content hidden" and a folded row's summary are
/// product copy and follow the reader's language. Resolved from the chosen
/// locale rather than from a `BuildContext`, because the repository is built
/// outside the tree — and a test may override it directly.
final Provider<AppLocalizations> notificationStringsProvider =
    Provider<AppLocalizations>(
      (Ref ref) => lookupAppLocalizations(
        ref.watch(localeProvider) ?? const Locale('en'),
      ),
    );

/// What the centre and the banner both read.
final Provider<LumeNotificationRepository> notificationFeedProvider =
    Provider<LumeNotificationRepository>((Ref ref) {
      final LumeStartupController gate = ref.watch(startupControllerProvider);
      return LumeFixtureNotificationRepository(
        eligibility: ref.watch(eligibilityProvider),
        user: LumeUserContext.from(gate.state.profile),
        l: ref.watch(notificationStringsProvider),
        // Asked for at read time, from the same store the Notifications
        // *preferences* route writes — so a switch flipped in the sheet is
        // true the next time the centre reads, without this provider having
        // to be rebuilt.
        readPrefs: () => ref.read(notificationPrefsProvider).prefs,
      );
    });
