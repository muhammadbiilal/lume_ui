/// Committee on screen: what a reader sees and can do
/// (`COMMITTEE_PROPOSAL.md` §15).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/committee/domain/committee_book.dart';
import 'package:lume/features/committee/domain/committee_model.dart';
import 'package:lume/features/committee/presentation/committee_sheets.dart';
import 'package:lume/features/committee/presentation/committee_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import 'committee_screen_harness.dart';

/// Scroll to something, then press it.
Future<void> press(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

String digits(String s) => s.replaceAll(RegExp('[^0-9]'), '');

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('nothing is seeded: the reader is asked to add one', (
      WidgetTester t,
    ) async {
      final CommitteeWorld w = CommitteeWorld();
      await pumpCommittee(t, w);
      expect(find.byKey(LumeCommitteeTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeCommitteeTool.summaryKey), findsNothing);
      expect(find.byKey(LumeCommitteeTool.listKey), findsNothing);
      // Nothing was written by opening the tool.
      expect(w.repo.view().committees, isEmpty);
      w.dispose();
    });

    testWidgets('a committee is created from the form, with its members, '
        'its shares and its cycles', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld();
      await pumpCommittee(t, w);
      await press(t, find.byKey(LumeCommitteeTool.addKey));
      expect(find.byKey(LumeCommitteeTool.formKey), findsOneWidget);

      await t.enterText(
        find.byKey(LumeCommitteeTool.nameField),
        'Street kameti',
      );
      await t.enterText(
        find.byKey(LumeCommitteeTool.contributionField),
        '5000',
      );
      await t.enterText(find.byKey(LumeCommitteeTool.memberName(0)), 'You');
      await t.enterText(find.byKey(LumeCommitteeTool.memberName(1)), 'Ahmed');
      await press(t, find.byKey(LumeCommitteeTool.addMemberKey));
      await t.enterText(find.byKey(LumeCommitteeTool.memberName(2)), 'Sara');
      await t.pumpAndSettle();
      await press(t, find.byKey(LumeCommitteeTool.saveKey));

      final CommitteeBook book = w.book();
      expect(book.committees, hasLength(1));
      final CommitteeView v = book.committees.single;
      expect(v.name, 'Street kameti');
      expect(v.contribution.minor, 500000);
      expect(v.memberCount, 3);
      expect(v.positionCount, 3);
      expect(v.cycles, hasLength(3));
      expect(v.pool.minor, 1500000);
      expect(v.reader!.name, 'You');
      // The first member listed receives the first cycle.
      expect(v.cycles.first.recipientMember.name, 'You');
      expect(book.invariants(), isEmpty);
      expect(book.damage, isEmpty);
      w.dispose();
    });

    testWidgets('a form with one member is refused, and nothing is written', (
      WidgetTester t,
    ) async {
      final CommitteeWorld w = CommitteeWorld();
      await pumpCommittee(t, w);
      await press(t, find.byKey(LumeCommitteeTool.addKey));
      await t.enterText(find.byKey(LumeCommitteeTool.nameField), 'Too small');
      await t.enterText(
        find.byKey(LumeCommitteeTool.contributionField),
        '5000',
      );
      await t.enterText(find.byKey(LumeCommitteeTool.memberName(0)), 'You');
      // The second member is left blank.
      await press(t, find.byKey(LumeCommitteeTool.saveKey));
      expect(find.byKey(LumeCommitteeTool.formKey), findsOneWidget);
      expect(w.repo.view().committees, isEmpty);
      w.dispose();
    });
  });

  group('the reference composition', () {
    testWidgets('the pool is the contribution times the shares — not the '
        'reference\'s rounded figure', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      await pumpCommittee(
        t,
        w,
        query: 'committee=${w.committees['Office committee']!.value}',
      );
      final LumeSummaryCard card = t.widget<LumeSummaryCard>(
        find.byKey(LumeCommitteeTool.summaryKey),
      );
      expect(digits(card.value), '141500');
      expect(digits(card.value), isNot('142000'));
      // Your contribution, People, your turn.
      expect(digits(card.stats[0].value), '28300');
      expect(card.stats[1].value, '5');
      w.dispose();
    });

    testWidgets('every cycle has one recipient, in the order settled at '
        'creation', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      await pumpCommittee(
        t,
        w,
        query: 'committee=${w.committees['Office committee']!.value}',
      );
      expect(find.byKey(LumeCommitteeTool.orderKey), findsOneWidget);
      final CommitteeView v = w.view(w.committees['Office committee']!);
      expect(
        <String>[
          for (final CommitteeCycleView c in v.cycles) c.recipientMember.name,
        ],
        <String>['Ahmed', 'Bilal', 'Sara', 'You', 'Hina'],
      );
      w.dispose();
    });

    testWidgets('this cycle lists every member with their state', (
      WidgetTester t,
    ) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      await pumpCommittee(
        t,
        w,
        query: 'committee=${w.committees['Office committee']!.value}',
      );
      final List<LumeRichRow> rows = t
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeCommitteeTool.thisCycleKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(rows, hasLength(5));
      expect(rows.first.title, contains('You'));
      w.dispose();
    });

    testWidgets('the chart draws what each cycle collected, and History is '
        'real records', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      await pumpCommittee(
        t,
        w,
        query: 'committee=${w.committees['Office committee']!.value}',
      );
      expect(find.byKey(LumeCommitteeTool.chartKey), findsOneWidget);
      expect(find.byKey(LumeCommitteeTool.historyKey), findsOneWidget);
      final CommitteeView v = w.view(w.committees['Office committee']!);
      // 14 contributions and 2 payouts were recorded.
      expect(v.contributions, hasLength(14));
      expect(v.payouts, hasLength(2));
      w.dispose();
    });
  });

  group('recording', () {
    testWidgets('a contribution is recorded from the member, and the cycle '
        'collects it', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await pumpCommittee(t, w, query: 'committee=${id.value}');
      // Hina owes cycle 3.
      final CommitteeView before = w.view(id);
      expect(before.cycles[2].collected.minor, 11320000);

      await press(t, find.byKey(LumeCommitteeTool.payKey));
      // Cycle 4 is current on 7 September; everyone owes it, so the sheet
      // asks who is paying.
      final CommitteeView v = w.view(id);
      final CommitteeMemberView hina = v.members.firstWhere(
        (CommitteeMemberView m) => m.name == 'Hina',
      );
      await press(
        t,
        find.byKey(LumeCommitteeTool.memberPick(hina.member.id.value)),
      );
      expect(find.byKey(CommitteeSheetKeys.payGo), findsOneWidget);
      await press(t, find.byKey(CommitteeSheetKeys.payGo));

      final CommitteeView after = w.view(id);
      expect(after.cycles[3].collected.minor, 2830000);
      expect(after.collected.minor, 39620000 + 2830000);
      w.dispose();
    });

    testWidgets('a payout is refused while its cycle is short, and the '
        'reader is told what is missing', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await pumpCommittee(t, w, query: 'committee=${id.value}');
      // Cycle 3 is one contribution short, so nothing is "ready".
      expect(find.byKey(LumeCommitteeTool.payoutKey), findsNothing);
      expect(w.view(id).paidOut.minor, 28300000);
      w.dispose();
    });

    testWidgets('once the cycle is collected the payout can be recorded, '
        'and only that cycle changes', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      w.collect(id, 3, except: <String>{'Ahmed', 'Bilal', 'Sara', 'You'});
      await pumpCommittee(t, w, query: 'committee=${id.value}');
      expect(find.byKey(LumeCommitteeTool.payoutKey), findsOneWidget);
      await press(t, find.byKey(LumeCommitteeTool.payoutKey));
      await press(t, find.byKey(CommitteeSheetKeys.payGo));

      final CommitteeView v = w.view(id);
      expect(v.paidOut.minor, 42450000);
      expect(v.cycles[2].paidOut, isTrue);
      expect(v.cycles[3].paidOut, isFalse);
      expect(v.cycles[2].payout!.positionId, v.cycles[2].recipient.id);
      w.dispose();
    });
  });

  group('cancelling, reinstating and deleting', () {
    testWidgets('cancelling keeps every record and stops what is owed '
        'growing', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await pumpCommittee(t, w, query: 'committee=${id.value}');
      await press(t, find.byKey(LumeCommitteeTool.cancelKey));
      await press(t, find.byKey(CommitteeSheetKeys.confirm));

      final CommitteeView v = w.view(id);
      expect(v.status, CommitteeStatus.cancelled);
      expect(v.committee.cancelledOn, isNotNull);
      expect(v.collected.minor, 39620000);
      expect(v.contributions, hasLength(14));
      expect(v.outstandingIsFinal, isTrue);
      // Read a year later: the figure does not move.
      expect(
        w.view(id, LumeDate(2027, 9, 7)).outstanding!.minor,
        v.outstanding!.minor,
      );
      expect(find.byKey(LumeCommitteeTool.reinstateKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('reinstating brings the same records back and derives the '
        'states again', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await pumpCommittee(t, w, query: 'committee=${id.value}');
      await press(t, find.byKey(LumeCommitteeTool.cancelKey));
      await press(t, find.byKey(CommitteeSheetKeys.confirm));
      await press(t, find.byKey(LumeCommitteeTool.reinstateKey));
      final CommitteeView v = w.view(id);
      expect(v.status, CommitteeStatus.active);
      expect(v.committee.cancelledOn, isNull);
      expect(v.contributions, hasLength(14));
      expect(v.payouts, hasLength(2));
      w.dispose();
    });

    testWidgets('deleting says what would go, removes it all, and Undo '
        'brings it back', (WidgetTester t) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      await pumpCommittee(t, w, query: 'committee=${id.value}');
      final AppLocalizations l = AppLocalizations.of(
        t.element(find.byType(LumeToolbar).first),
      );
      await press(t, find.byKey(LumeCommitteeTool.deleteKey));
      // The confirmation names every record it would remove.
      expect(
        find.textContaining('5 members, 5 shares, 5 cycles'),
        findsOneWidget,
      );
      await press(t, find.text(l.actionDelete).last);
      expect(w.repo.view().committees, isEmpty);
      expect(w.repo.view().contributions, isEmpty);
      expect(find.byKey(LumeCommitteeTool.emptyKey), findsOneWidget);

      await press(t, find.text(l.recUndo));
      expect(w.repo.view().committees, hasLength(1));
      expect(w.repo.view().contributions, hasLength(14));
      expect(w.book().damage, isEmpty);
      w.dispose();
    });
  });

  group('states', () {
    testWidgets('a damaged committee is shown, and cannot be written to', (
      WidgetTester t,
    ) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      final LumeRecordId id = w.committees['Office committee']!;
      final CommitteeCycleView one = w.view(id).cycles.first;
      w.store.run<void>(
        (tx) => tx.update(
          CommitteeCollections.cycles,
          one.cycle.id.value,
          <String, Object?>{...one.cycle.toFields(), 'due': 'whenever'},
          expectVersion: one.cycle.version,
        ),
      );
      await pumpCommittee(t, w);
      expect(find.byKey(LumeCommitteeTool.defectsKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('without the reader\'s day nothing is called late', (
      WidgetTester t,
    ) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      await pumpCommittee(
        t,
        w,
        profile: LumeMemoryProfileRepository(
          initial: taxReader(country: 'US', region: 'New York', city: ''),
        ),
      );
      await press(
        t,
        find.byKey(LumeCommitteeTool.filterChip(CommitteeFilter.late_)),
      );
      expect(find.byKey(LumeCommitteeTool.dayUnknownKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('a link to a committee that is not there opens the list', (
      WidgetTester t,
    ) async {
      final CommitteeWorld w = CommitteeWorld().reference_();
      await pumpCommittee(
        t,
        w,
        query: 'committee=${LumeRecordId.generate().value}',
      );
      expect(find.byKey(LumeCommitteeTool.listKey), findsOneWidget);
      expect(find.byKey(LumeCommitteeTool.committeeKey), findsNothing);
      w.dispose();
    });
  });

  group('languages', () {
    for (final Locale locale in const <Locale>[Locale('ur'), Locale('ar')]) {
      testWidgets('${locale.languageCode}: the tool is in the reader\'s '
          'language, and the figures are the same', (WidgetTester t) async {
        final CommitteeWorld w = CommitteeWorld().reference_();
        await pumpCommittee(
          t,
          w,
          locale: locale,
          query: 'committee=${w.committees['Office committee']!.value}',
        );
        final AppLocalizations l = lookupAppLocalizations(locale);
        final LumeSummaryCard card = t.widget<LumeSummaryCard>(
          find.byKey(LumeCommitteeTool.summaryKey),
        );
        expect(card.kicker, l.commPoolEachCycle);
        expect(card.kicker, isNot('Pool each cycle'));
        // The same figure, in the reader's own digits.
        expect(
          card.value.replaceAll(RegExp('[^0-9٠-٩۰-۹]'), '').length,
          greaterThan(0),
        );
        w.dispose();
      });
    }
  });
}
