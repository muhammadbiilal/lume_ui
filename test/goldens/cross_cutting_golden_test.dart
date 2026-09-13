/// Visual evidence for the four cross-cutting surfaces.
///
/// Global search, the notification centre, the banner and the two
/// notification sheets — each captured the way the reference is measured:
/// through the real router, over the destination it belongs to, with the
/// shell, its navigation and the scrim. A surface shot on its own is a
/// different picture from the one `measure_destinations.mjs` takes, and a
/// comparison between the two says nothing.
///
/// Every capture writes a `.flutter.png` and its measured sidecar into
/// `docs/conversion_archive/shots/cross-cutting/`, and compares against a
/// committed golden in `images/`. The two are different artifacts and the
/// inventory checker counts them separately.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/navigation/lume_shell.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/account/domain/notification_prefs.dart';
import 'package:lume/features/notifications/data/notification_fixtures.dart';
import 'package:lume/features/notifications/domain/notification_model.dart';
import 'package:lume/features/notifications/presentation/notification_host.dart';
import 'package:lume/features/notifications/presentation/notification_presenter.dart';
import 'package:lume/features/notifications/presentation/notification_sheets.dart';
import 'package:lume/features/search/presentation/search_sheet.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../features/destinations/destination_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';
import 'destination_golden_test.dart' show Cell, kCells;

/// Where the evidence for these surfaces lands.
const String kOut = '$kShotsDir/cross-cutting';

void main() {
  setUpAll(loadLumeFonts);

  /// One cell, through the router, captured and compared.
  Future<void> shoot(
    WidgetTester tester, {
    required String location,
    required String name,
    required Cell cell,
    List<Override> overrides = const <Override>[],
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    await captureLumeRoute(
      tester,
      location: location,
      name: name,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      overrides: overrides,
      after: after,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${name}_${cell.$1}.png'),
    );
  }

  Cell cellNamed(String name) => kCells.firstWhere((Cell c) => c.$1 == name);

  /// A feed with fixed content, so a capture is the same next week.
  LumeFixtureNotificationRepository feed(
    AppLocalizations l, {
    LumeNotificationPrefs prefs = const LumeNotificationPrefs(),
    List<LumeNotificationSample>? samples,
    bool quietHours = false,
    LumeNotificationFailure? failWith,
  }) => LumeFixtureNotificationRepository(
    eligibility: kEligibility,
    user: LumeUsers.defaultPk,
    l: l,
    readPrefs: () => prefs,
    samples: samples ?? kNotificationSamples,
    quietHours: quietHours,
    failWith: failWith,
  );

  Override feedWith({
    List<LumeNotificationSample>? samples,
    bool quietHours = false,
    LumeNotificationFailure? failWith,
  }) => notificationFeedProvider.overrideWith(
    (Ref ref) => feed(
      ref.watch(notificationStringsProvider),
      samples: samples,
      quietHours: quietHours,
      failWith: failWith,
    ),
  );

  // ---------------------------------------------------------------- search

  group('global search', () {
    Future<void> Function(WidgetTester) typing(String query) =>
        (WidgetTester t) => t.enterText(
          find.descendant(
            of: find.byKey(LumeSearchSheet.fieldKey),
            matching: find.byType(EditableText),
          ),
          query,
        );

    for (final Cell cell in kCells) {
      testWidgets('idle · ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          location: '/home/search',
          name: 'search_idle',
          cell: cell,
          // Past the sheet's 320 ms focus delay. At medium and expanded the
          // sheet's transition is shorter than the delay, and settling would
          // otherwise capture the field before it has taken focus — which the
          // reference, measured 900 ms after opening, never shows.
          after: (WidgetTester t) => t.pump(const Duration(milliseconds: 400)),
        );
      });
    }

    testWidgets('results · the reference cell', (WidgetTester tester) async {
      await shoot(
        tester,
        location: '/home/search',
        name: 'search_results',
        cell: kCells.first,
        after: typing('ca'),
      );
    });

    testWidgets('nothing found · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        location: '/home/search',
        name: 'search_empty',
        cell: kCells.first,
        after: typing('zzzz nothing'),
      );
    });

    testWidgets('results · right to left', (WidgetTester tester) async {
      await shoot(
        tester,
        location: '/home/search',
        name: 'search_results',
        cell: cellNamed('390x844_light_ur'),
        after: typing('ca'),
      );
    });

    testWidgets('results · twice the type size', (WidgetTester tester) async {
      await shoot(
        tester,
        location: '/home/search',
        name: 'search_results',
        cell: cellNamed('390x844_light_en_x2'),
        after: typing('ca'),
      );
    });
  });

  // ---------------------------------------------------- notification centre

  group('the notification centre', () {
    /// Past the first visit's skeleton, then [then].
    Future<void> Function(WidgetTester) settled([
      Future<void> Function(WidgetTester)? then,
    ]) => (WidgetTester t) async {
      await t.pump(LumeNotificationHost.settle);
      await t.pumpAndSettle();
      if (then != null) await then(t);
    };

    Future<void> Function(WidgetTester) tab(String label) =>
        (WidgetTester t) => t.tap(find.text(label).first);

    for (final Cell cell in kCells) {
      testWidgets('all · ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          location: '/home/notifications',
          name: 'notif_centre',
          cell: cell,
          overrides: <Override>[feedWith()],
          after: settled(),
        );
      });
    }

    testWidgets('unread only · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        location: '/home/notifications',
        name: 'notif_unread',
        cell: kCells.first,
        overrides: <Override>[feedWith()],
        after: settled(tab('Unread')),
      );
    });

    testWidgets('important only · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        location: '/home/notifications',
        name: 'notif_important',
        cell: kCells.first,
        overrides: <Override>[feedWith()],
        after: settled(tab('Important')),
      );
    });

    testWidgets('nothing to tell you · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        location: '/home/notifications',
        name: 'notif_empty',
        cell: kCells.first,
        overrides: <Override>[
          feedWith(samples: const <LumeNotificationSample>[]),
        ],
        after: settled(),
      );
    });

    testWidgets('previews off · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        location: '/home/notifications',
        name: 'notif_hidden',
        cell: kCells.first,
        overrides: <Override>[
          notificationPrefsProvider.overrideWithValue(
            LumeMemoryNotificationPrefs(
              const LumeNotificationPrefs(preview: false),
            ),
          ),
        ],
        after: settled(),
      );
    });

    testWidgets('quiet hours · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        location: '/home/notifications',
        name: 'notif_quiet',
        cell: kCells.first,
        overrides: <Override>[feedWith(quietHours: true)],
        after: settled(),
      );
    });

    testWidgets('could not be loaded · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        location: '/home/notifications',
        name: 'notif_error',
        cell: kCells.first,
        overrides: <Override>[
          feedWith(failWith: LumeNotificationFailure.unreachable),
        ],
        after: settled(),
      );
    });
  });

  // ---------------------------------------------------------------- banner

  group('the banner', () {
    /// Home, past the shell's first tick — the reference's own demo banner.
    Future<void> firstTick(WidgetTester t) async {
      await t.pump(LumeNotificationPresenter.firstTick);
      await t.pump();
      await t.pump();
    }

    for (final String name in <String>[
      '390x844_light_en',
      '390x844_dark_en',
      '390x844_light_ur',
      '390x844_light_en_x2',
      '852x393_light_en',
    ]) {
      testWidgets('over Home · $name', (WidgetTester tester) async {
        await shoot(
          tester,
          location: '/home',
          name: 'notif_banner',
          cell: cellNamed(name),
          after: firstTick,
        );
      });
    }

    testWidgets('with previews off', (WidgetTester tester) async {
      await shoot(
        tester,
        location: '/home',
        name: 'notif_banner_hidden',
        cell: kCells.first,
        overrides: <Override>[
          notificationPrefsProvider.overrideWithValue(
            LumeMemoryNotificationPrefs(
              const LumeNotificationPrefs(preview: false),
            ),
          ),
        ],
        after: firstTick,
      );
    });
  });

  // ---------------------------------------------------------------- sheets

  group('the notification sheets', () {
    /// Raised over Home the way their callers raise them.
    Future<void> Function(WidgetTester) raise(
      Future<Object?> Function(BuildContext context) show,
    ) => (WidgetTester t) async {
      unawaited(show(t.element(find.byType(LumeShell))));
      await t.pumpAndSettle();
    };

    for (final String name in <String>[
      '390x844_light_en',
      '390x844_dark_en',
      '390x844_light_ur',
      '390x844_light_en_x2',
    ]) {
      testWidgets('push ask · $name', (WidgetTester tester) async {
        await shoot(
          tester,
          location: '/home',
          name: 'notif_push',
          cell: cellNamed(name),
          after: raise(showLumeNotificationPushSheet),
        );
      });

      testWidgets('preferences · $name', (WidgetTester tester) async {
        await shoot(
          tester,
          location: '/home',
          name: 'notif_prefs_sheet',
          cell: cellNamed(name),
          overrides: <Override>[
            notificationPrefsProvider.overrideWithValue(
              LumeMemoryNotificationPrefs(),
            ),
          ],
          after: raise(showLumeNotificationPrefsSheet),
        );
      });
    }
  });
}
