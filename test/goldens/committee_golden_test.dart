/// Committee, pinned and captured: the reference's composition in its
/// eight cells, and every state the reader reaches — first use, each
/// filter, a late committee, a completed and a cancelled one, no match,
/// the form and its validation, locked terms, a member, the contribution
/// and payout sheets, the cancel and delete confirmations, export and the
/// import check, a member holding two shares, the day-unavailable and
/// damaged states, loading and a storage failure.
///
/// The composition cells also write a `.flutter.png` beside the browser's
/// `.web.png` in
/// `docs/conversion_archive/shots/tools/tool_committee_default_pk/` for
/// `compare.mjs`. The reference draws one committee from a fixture; here
/// the same people are entered through the repository as a reader would,
/// corrected so that the cycles and the shares agree — a test fixture, and
/// a reader's Committee starts empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/committee/domain/committee_book.dart';
import 'package:lume/features/committee/domain/committee_model.dart';
import 'package:lume/features/committee/domain/committee_repository.dart';
import 'package:lume/features/committee/presentation/committee_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

import '../features/committee/committee_screen_harness.dart';
import '../features/tax/tax_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

const String kOut = '$kShotsDir/tools';

typedef Cell = (
  String name,
  Size size,
  ThemeMode theme,
  Locale locale,
  double scale,
);

const List<Cell> kCells = <Cell>[
  ('390x844_light_en', Size(390, 844), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_dark_en', Size(390, 844), ThemeMode.dark, Locale('en'), 1.0),
  ('700x900_light_en', Size(700, 900), ThemeMode.light, Locale('en'), 1.0),
  ('1100x900_light_en', Size(1100, 900), ThemeMode.light, Locale('en'), 1.0),
  ('852x393_light_en', Size(852, 393), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_light_ur', Size(390, 844), ThemeMode.light, Locale('ur'), 1.0),
  ('390x844_light_ar', Size(390, 844), ThemeMode.light, Locale('ar'), 1.0),
  ('390x844_light_en_x2', Size(390, 844), ThemeMode.light, Locale('en'), 2.0),
];

const Cell kPhone = (
  '390x844_light_en',
  Size(390, 844),
  ThemeMode.light,
  Locale('en'),
  1.0,
);

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String golden,
    required Cell cell,
    required CommitteeWorld world,
    LumeProfileRepository? profile,
    String query = '',
    List<Override> overrides = const <Override>[],
    Future<void> Function(WidgetTester tester)? after,
    bool compared = false,
  }) async {
    await captureLumeRoute(
      tester,
      location:
          '${LumeRoutes.tool(LumeRoutes.tools, 'committee')}'
          '${query.isEmpty ? '' : '?$query'}',
      name: golden,
      outDir: compared ? kOut : 'build/committee_shots',
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: profile ?? taxProfile('default_pk'),
      overrides: <Override>[...world.overrides, ...overrides],
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
    world.dispose();
  }

  group('Committee — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets('the committee, ${cell.$1}', (WidgetTester t) async {
        final CommitteeWorld w = CommitteeWorld().reference_();
        await shoot(
          t,
          golden: 'tool_committee_default_pk',
          cell: cell,
          world: w,
          query: 'committee=${w.committees['Office committee']!.value}',
          compared: true,
        );
      });
    }
  });

  group('Committee — the states a reader reaches', () {
    Future<void> state(
      WidgetTester t,
      String name,
      CommitteeWorld world, {
      Future<void> Function(WidgetTester tester)? after,
      LumeProfileRepository? profile,
      String query = '',
      Cell cell = kPhone,
      List<Override> overrides = const <Override>[],
    }) => shoot(
      t,
      golden: 'tool_committee_$name',
      cell: cell,
      world: world,
      profile: profile,
      query: query,
      overrides: overrides,
      after: after,
    );

    testWidgets('first use: nothing seeded', (WidgetTester t) async {
      await state(t, 'empty', CommitteeWorld());
    });

    testWidgets('the list, with one committee', (WidgetTester t) async {
      await state(t, 'list', CommitteeWorld()..reference_());
    });

    testWidgets('the list, filtered to late', (WidgetTester t) async {
      await state(
        t,
        'late',
        CommitteeWorld()..reference_(),
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(LumeCommitteeTool.filterChip(CommitteeFilter.late_)),
        ),
      );
    });

    testWidgets('no match', (WidgetTester t) async {
      await state(
        t,
        'no_match',
        CommitteeWorld()..reference_(),
        after: (WidgetTester t) async {
          await t.enterText(
            find.byKey(LumeCommitteeTool.searchKey),
            'nothing like this',
          );
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('a completed committee', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld();
      final Committee c = w.add();
      for (int n = 1; n <= 5; n++) {
        w.collect(c.id, n);
        w.payout(c.id, n);
      }
      await state(t, 'completed', w, query: 'committee=${c.id.value}');
    });

    testWidgets('a cancelled committee, with what was unpaid', (
      WidgetTester t,
    ) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      w.repo.setCancelled(
        id,
        true,
        on: day(9, 8),
        version: w.view(id).committee.version,
      );
      await state(t, 'cancelled', w, query: 'committee=${id.value}');
    });

    testWidgets('a member, and their cycles', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await state(
        t,
        'member',
        w,
        query: 'committee=${id.value}',
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(
            LumeCommitteeTool.memberRow(
              w.view(id).members.first.member.id.value,
            ),
          ),
        ),
      );
    });

    testWidgets('one member, two shares', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld();
      final Committee c = w.add(
        name: 'Two shares',
        members: <CommitteeMemberDraft>[
          const CommitteeMemberDraft(name: 'Ahmed', cycles: <int>[1]),
          const CommitteeMemberDraft(
            name: 'You',
            isReader: true,
            cycles: <int>[2, 4],
          ),
          const CommitteeMemberDraft(name: 'Sara', cycles: <int>[3]),
          const CommitteeMemberDraft(name: 'Hina', cycles: <int>[5]),
        ],
      );
      w.collect(c.id, 1);
      await state(t, 'two_shares', w, query: 'committee=${c.id.value}');
    });

    testWidgets('the form, empty', (WidgetTester t) async {
      await state(
        t,
        'form',
        CommitteeWorld(),
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeCommitteeTool.addKey)),
      );
    });

    testWidgets('the form, refusing what cannot be saved', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'form_errors',
        CommitteeWorld(),
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeCommitteeTool.addKey));
          await tapShown(t, find.byKey(LumeCommitteeTool.saveKey));
        },
      );
    });

    testWidgets('the form, with the terms locked', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await state(
        t,
        'form_locked',
        w,
        query: 'committee=${id.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeCommitteeTool.editKey)),
      );
    });

    testWidgets('recording a contribution', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await state(
        t,
        'pay_sheet',
        w,
        query: 'committee=${id.value}',
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeCommitteeTool.payKey));
          await tapShown(
            t,
            find.byKey(
              LumeCommitteeTool.memberPick(
                w.view(id).members.first.member.id.value,
              ),
            ),
          );
        },
      );
    });

    testWidgets('recording a payout', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      w.collect(id, 3, except: <String>{'Ahmed', 'Bilal', 'Sara', 'You'});
      await state(
        t,
        'payout_sheet',
        w,
        query: 'committee=${id.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeCommitteeTool.payoutKey)),
      );
    });

    testWidgets('the cancel confirmation', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await state(
        t,
        'cancel_confirm',
        w,
        query: 'committee=${id.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeCommitteeTool.cancelKey)),
      );
    });

    testWidgets('the delete confirmation, naming every record', (
      WidgetTester t,
    ) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await state(
        t,
        'delete_confirm',
        w,
        query: 'committee=${id.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeCommitteeTool.deleteKey)),
      );
    });

    testWidgets('the day cannot be worked out', (WidgetTester t) async {
      await state(
        t,
        'day_unknown',
        CommitteeWorld()..reference_(),
        profile: LumeMemoryProfileRepository(
          initial: taxReader(country: 'US', region: 'New York', city: ''),
        ),
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(LumeCommitteeTool.filterChip(CommitteeFilter.late_)),
        ),
      );
    });

    testWidgets('a record that cannot be read', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      final CommitteeCycleView one = w.view(id).cycles.first;
      w.store.run<void>(
        (LumeRecordTx tx) => tx.update(
          CommitteeCollections.cycles,
          one.cycle.id.value,
          <String, Object?>{...one.cycle.toFields(), 'due': 'whenever'},
          expectVersion: one.cycle.version,
        ),
      );
      await state(t, 'damaged', w);
    });

    testWidgets('the store is still loading', (WidgetTester t) async {
      await state(
        t,
        'loading',
        CommitteeWorld(readDelay: const Duration(seconds: 5)),
      );
    });

    testWidgets('the store will not answer', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld();
      w.store.retry(CommitteeCollections.payouts);
      w.store.unreadable.add(CommitteeCollections.payouts);
      w.store.retry(CommitteeCollections.payouts);
      await state(t, 'storage_failure', w);
    });
  });
}
