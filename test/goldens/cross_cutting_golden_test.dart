/// Visual evidence for the four cross-cutting surfaces.
///
/// Global search, the notification centre, the banner and the two
/// notification sheets — each at the cells the brief requires, and each in
/// the states the reference actually has. A state the reference has no
/// composition for is not shot, because there would be nothing to compare it
/// against.
///
/// Every capture writes a `.flutter.png` and its measured sidecar into
/// `docs/conversion_archive/shots/cross-cutting/`, and compares against a
/// committed golden in `images/`. The two are different artifacts and the
/// inventory checker counts them separately.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/account/domain/notification_prefs.dart';
import 'package:lume/features/notifications/data/notification_fixtures.dart';
import 'package:lume/features/notifications/domain/notification_model.dart';
import 'package:lume/features/notifications/presentation/notification_banner.dart';
import 'package:lume/features/notifications/presentation/notification_centre.dart';
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

  /// One surface, captured and compared.
  Future<void> shoot(
    WidgetTester tester,
    Widget child,
    String name,
    Cell cell, {
    List<Override> overrides = const <Override>[],
  }) async {
    await captureLume(
      tester,
      child,
      name: name,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      overrides: overrides,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${name}_${cell.$1}.png'),
    );
  }

  /// A feed with fixed content, so a capture is the same next week.
  LumeFixtureNotificationRepository feed(
    AppLocalizations l, {
    LumeNotificationPrefs prefs = const LumeNotificationPrefs(),
    List<LumeNotificationSample>? samples,
    bool quietHours = false,
    LumeNotificationFailure? failWith,
  }) => LumeFixtureNotificationRepository(
    eligibility: kEligibility,
    user: LumeUsers.muslimPk,
    l: l,
    readPrefs: () => prefs,
    samples: samples ?? kNotificationSamples,
    quietHours: quietHours,
    failWith: failWith,
  );

  // ---------------------------------------------------------------- search

  group('global search', () {
    // The sheet itself, at every cell. Its geometry is the thing being
    // compared, and a sheet over a destination shows less of it.
    for (final Cell cell in kCells) {
      testWidgets('idle · ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          const LumeSearchSheet(branch: '/home'),
          'search_idle',
          cell,
        );
      });
    }

    testWidgets('results · the reference cell', (WidgetTester tester) async {
      await shoot(
        tester,
        const _TypedSearch(query: 'ca'),
        'search_results',
        kCells.first,
      );
    });

    testWidgets('nothing found · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        const _TypedSearch(query: 'zzzz nothing'),
        'search_empty',
        kCells.first,
      );
    });

    testWidgets('results · right to left', (WidgetTester tester) async {
      await shoot(
        tester,
        const _TypedSearch(query: 'ca'),
        'search_results',
        kCells.firstWhere((Cell c) => c.$1 == '390x844_light_ur'),
      );
    });

    testWidgets('results · twice the type size', (WidgetTester tester) async {
      await shoot(
        tester,
        const _TypedSearch(query: 'ca'),
        'search_results',
        kCells.firstWhere((Cell c) => c.$1 == '390x844_light_en_x2'),
      );
    });
  });

  // ---------------------------------------------------- notification centre

  group('the notification centre', () {
    for (final Cell cell in kCells) {
      testWidgets('all · ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          const _Centre(),
          'notif_centre',
          cell,
          overrides: <Override>[
            notificationFeedProvider.overrideWith(
              (Ref ref) => feed(ref.watch(notificationStringsProvider)),
            ),
          ],
        );
      });
    }

    testWidgets('unread only · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        const _Centre(filter: LumeNotificationFilter.unread()),
        'notif_unread',
        kCells.first,
        overrides: <Override>[
          notificationFeedProvider.overrideWith(
            (Ref ref) => feed(ref.watch(notificationStringsProvider)),
          ),
        ],
      );
    });

    testWidgets('important only · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        const _Centre(filter: LumeNotificationFilter.important()),
        'notif_important',
        kCells.first,
        overrides: <Override>[
          notificationFeedProvider.overrideWith(
            (Ref ref) => feed(ref.watch(notificationStringsProvider)),
          ),
        ],
      );
    });

    testWidgets('nothing to tell you · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        const _Centre(),
        'notif_empty',
        kCells.first,
        overrides: <Override>[
          notificationFeedProvider.overrideWith(
            (Ref ref) => feed(
              ref.watch(notificationStringsProvider),
              samples: const <LumeNotificationSample>[],
            ),
          ),
        ],
      );
    });

    testWidgets('previews off · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        const _Centre(),
        'notif_hidden',
        kCells.first,
        overrides: <Override>[
          notificationFeedProvider.overrideWith(
            (Ref ref) => feed(
              ref.watch(notificationStringsProvider),
              prefs: const LumeNotificationPrefs(preview: false),
            ),
          ),
        ],
      );
    });

    testWidgets('quiet hours · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        const _Centre(),
        'notif_quiet',
        kCells.first,
        overrides: <Override>[
          notificationFeedProvider.overrideWith(
            (Ref ref) =>
                feed(ref.watch(notificationStringsProvider), quietHours: true),
          ),
        ],
      );
    });

    testWidgets('could not be loaded · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        const _Centre(),
        'notif_error',
        kCells.first,
        overrides: <Override>[
          notificationFeedProvider.overrideWith(
            (Ref ref) => feed(
              ref.watch(notificationStringsProvider),
              failWith: LumeNotificationFailure.unreachable,
            ),
          ),
        ],
      );
    });
  });

  // ---------------------------------------------------------------- banner

  group('the banner', () {
    for (final String name in <String>[
      '390x844_light_en',
      '390x844_dark_en',
      '390x844_light_ur',
      '390x844_light_en_x2',
      '852x393_light_en',
    ]) {
      testWidgets('over a screen · $name', (WidgetTester tester) async {
        await shoot(
          tester,
          const _Banner(),
          'notif_banner',
          kCells.firstWhere((Cell c) => c.$1 == name),
        );
      });
    }

    testWidgets('withholding a sensitive body', (WidgetTester tester) async {
      await shoot(
        tester,
        const _Banner(withheld: true),
        'notif_banner_hidden',
        kCells.first,
      );
    });
  });

  // ---------------------------------------------------------------- sheets

  group('the notification sheets', () {
    for (final String name in <String>[
      '390x844_light_en',
      '390x844_dark_en',
      '390x844_light_ur',
      '390x844_light_en_x2',
    ]) {
      testWidgets('push ask · $name', (WidgetTester tester) async {
        await shoot(
          tester,
          const _PushAsk(),
          'notif_push',
          kCells.firstWhere((Cell c) => c.$1 == name),
        );
      });

      testWidgets('preferences · $name', (WidgetTester tester) async {
        await shoot(
          tester,
          const _PrefsSheet(),
          'notif_prefs_sheet',
          kCells.firstWhere((Cell c) => c.$1 == name),
          overrides: <Override>[
            notificationPrefsProvider.overrideWithValue(
              LumeMemoryNotificationPrefs(),
            ),
          ],
        );
      });
    }
  });
}

/// Search with something already typed, so the result list is what is shot.
class _TypedSearch extends StatefulWidget {
  const _TypedSearch({required this.query});

  final String query;

  @override
  State<_TypedSearch> createState() => _TypedSearchState();
}

class _TypedSearchState extends State<_TypedSearch> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final EditableTextState? field = tester(context);
      field?.updateEditingValue(
        TextEditingValue(
          text: widget.query,
          selection: TextSelection.collapsed(offset: widget.query.length),
        ),
      );
    });
  }

  /// The sheet's own field, found through the tree rather than through a key
  /// the production widget does not need.
  EditableTextState? tester(BuildContext context) {
    EditableTextState? found;
    void visit(Element e) {
      if (e is StatefulElement && e.state is EditableTextState) {
        found ??= e.state as EditableTextState;
      }
      e.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  @override
  Widget build(BuildContext context) => const LumeSearchSheet(branch: '/home');
}

/// The centre's body, with its own scroll, so a capture holds the whole list.
class _Centre extends ConsumerStatefulWidget {
  const _Centre({this.filter = const LumeNotificationFilter.all()});

  final LumeNotificationFilter filter;

  @override
  ConsumerState<_Centre> createState() => _CentreState();
}

class _CentreState extends ConsumerState<_Centre> {
  LumeNotificationFeed? _feed;
  LumeNotificationFailure? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final LumeNotificationFeed f = await ref
            .read(notificationFeedProvider)
            .feed(now: DateTime(2026, 9, 13, 16, 41));
        if (mounted) setState(() => _feed = f);
      } on LumeNotificationException catch (e) {
        if (mounted) setState(() => _failure = e.failure);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final LumeNotificationFeed f =
        _feed ??
        const LumeNotificationFeed(
          all: <LumeNotification>[],
          quietHours: false,
          pushEnabled: false,
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LumeNotificationCentre(
        feed: f,
        filter: widget.filter,
        failure: _failure,
        actions: LumeNotificationActions(
          setFilter: (_) {},
          open: (_) {},
          act: (_) {},
          dismiss: (_) {},
          markAllRead: () {},
          openSettings: () {},
          retry: () {},
        ),
      ),
    );
  }
}

/// A banner over a plain ground, so the banner is what is compared.
class _Banner extends StatelessWidget {
  const _Banner({this.withheld = false});

  final bool withheld;

  @override
  Widget build(BuildContext context) => LumeNotificationBannerHost(
    notification: withheld
        ? const LumeNotification(
            id: 'meds.dose#1',
            title: 'Time for a dose',
            body: 'A medication reminder is due',
            category: 'health',
            icon: 'pulse',
            tool: 'meds',
            agoMinutes: 8,
            priority: LumeNotificationPriority.high,
          )
        : const LumeNotification(
            id: 'weather.alert#0',
            title: 'Heavy rain warning',
            body: 'Karachi · this evening',
            category: 'weather',
            icon: 'cloud-sun',
            tool: 'weather',
            agoMinutes: 2,
            priority: LumeNotificationPriority.critical,
          ),
    child: const SizedBox.expand(),
  );
}

class _PushAsk extends StatelessWidget {
  const _PushAsk();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: LumeSheet(child: LumeNotificationPushAsk(sheetContext: context)),
  );
}

class _PrefsSheet extends StatelessWidget {
  const _PrefsSheet();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: LumeSheet(
      tall: true,
      title: AppLocalizations.of(context).nSettings,
      closeLabel: AppLocalizations.of(context).actionClose,
      onClose: () {},
      child: const LumeNotificationPrefsSheet(),
    ),
  );
}
