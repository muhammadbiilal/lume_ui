/// Ledger on screen: first use, the populated composition, filters, search,
/// sort, the forms and their failures, void and delete with Undo, archive,
/// the reminder, export and import, deep links and restoration, the
/// day-unknown and damaged states, release honesty, RTL, text scale,
/// keyboard and accessibility.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/ledger/domain/ledger_book.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/domain/ledger_transfer.dart';
import 'package:lume/features/ledger/presentation/ledger_sheets.dart';
import 'package:lume/features/ledger/presentation/ledger_text.dart';
import 'package:lume/features/ledger/presentation/ledger_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_en.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import 'ledger_screen_harness.dart';

final LumeCurrency pkr = LumeCurrency.of('PKR');
LumeMoney rs(int rupees) => LumeMoney.entry(rupees * 100, pkr);

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

List<String> peopleShown(WidgetTester t) => <String>[
  for (final LumeRichRow r in t.widgetList<LumeRichRow>(
    find.descendant(
      of: find.byKey(LumeLedgerTool.peopleKey),
      matching: find.byType(LumeRichRow),
    ),
  ))
    r.title,
];

Finder get deleteButton => find.descendant(
  of: find.byKey(LedgerSheetKeys.confirm),
  matching: find.text('Delete'),
);

void main() {
  setUpAll(loadLumeFonts);

  LedgerBook book(LedgerWorld w) => w.repo.view().book(LumeDate(2026, 9, 7));

  group('first use and the composition', () {
    testWidgets('first use: empty, no sample people, one way in', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld();
      await pumpLedger(t, w);
      expect(find.byKey(LumeLedgerTool.emptyKey), findsOneWidget);
      expect(find.text('Ahmed'), findsNothing);
      expect(find.byKey(LumeLedgerTool.summaryKey), findsNothing);
      await tapShown(t, find.byKey(LumeLedgerTool.addPersonKey));
      await t.enterText(find.byKey(LumeLedgerTool.nameField), '  Zainab ');
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      expect(book(w).parties.single.name, 'Zainab');
      expect(find.text('Zainab'), findsWidgets);
      w.dispose();
    });

    testWidgets('populated: the reference composition, figures that agree', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      final LumeSummaryCard card = t.widget(
        find.byKey(LumeLedgerTool.summaryKey),
      );
      expect(card.kicker, 'Net position');
      expect(card.value, 'Rs\u00a038,300');
      expect(card.caption, 'owed to you overall');
      expect(card.stats.map((LumeStat s) => '${s.label}=${s.value}'), <String>[
        'Owed to you=Rs\u00a051,000',
        'You owe=Rs\u00a012,700',
        'People=3',
      ]);
      // The reference rounds each figure on its own and reads 38,200 and
      // 50,900 (§17.1); rows and summary agree here.
      expect(peopleShown(t), <String>['Bilal', 'Ahmed', 'Sara']);
      final List<LumeRichRow> rows = t
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeLedgerTool.peopleKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(rows.first.badge?.label, 'Overdue');
      expect(rows.map((LumeRichRow r) => r.valueSub), <String>[
        'owes you',
        'owes you',
        'you owe',
      ]);
      expect(find.byKey(LumeLedgerTool.recentKey), findsOneWidget);
      expect(find.byKey(LumeLedgerTool.actionsKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('the tile says what the tool is for, never a figure', (
      WidgetTester t,
    ) async {
      expect(AppLocalizationsEn().toolStatusLedger, 'Lend and borrow');
      final LumeFeature ledger = kLumeFeatures.firstWhere(
        (LumeFeature f) => f.id == 'ledger',
      );
      expect(ledger.sensitive, isTrue);
    });
  });

  group('filters, search and sort', () {
    for (final (LedgerFilter f, List<String> want)
        in <(LedgerFilter, List<String>)>[
          (LedgerFilter.owesYou, <String>['Bilal', 'Ahmed']),
          (LedgerFilter.youOwe, <String>['Sara']),
          (LedgerFilter.overdue, <String>['Bilal']),
        ]) {
      testWidgets('${f.name}: by the balance now; the summary never moves', (
        WidgetTester t,
      ) async {
        final LedgerWorld w = LedgerWorld().reference();
        await pumpLedger(t, w);
        await tapShown(t, find.byKey(LumeLedgerTool.filterChip(f)));
        expect(peopleShown(t), want);
        final LumeSummaryCard card = t.widget(
          find.byKey(LumeLedgerTool.summaryKey),
        );
        expect(card.value, 'Rs\u00a038,300');
        w.dispose();
      });
    }

    testWidgets('the filter bar says what it filters by', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      expect(
        find.bySemanticsLabel('Show people by their current balance'),
        findsOneWidget,
      );
      w.dispose();
    });

    testWidgets('search: names and notes, ignoring case; no match offers '
        'Show all', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      await t.enterText(find.byKey(LumeLedgerTool.searchKey), 'RENT');
      await t.pumpAndSettle();
      expect(peopleShown(t), <String>['Bilal']);
      await t.enterText(find.byKey(LumeLedgerTool.searchKey), 'sar');
      await t.pumpAndSettle();
      expect(peopleShown(t), <String>['Sara']);
      await t.enterText(find.byKey(LumeLedgerTool.searchKey), 'nobody');
      await t.pumpAndSettle();
      expect(find.byKey(LumeLedgerTool.noMatchKey), findsOneWidget);
      await tapShown(t, find.text('Show all'));
      expect(peopleShown(t), hasLength(3));
      w.dispose();
    });

    test('search folds Arabic and Urdu letter forms and diacritics', () {
      expect(LedgerText.fold('أحمد'), LedgerText.fold('احمد'));
      expect(LedgerText.fold('کریم'), LedgerText.fold('كريم'));
      expect(LedgerText.fold('مُحَمَّد'), LedgerText.fold('محمد'));
      expect(LedgerText.fold('Zoë'), 'zoe');
      expect(LedgerText.initials('ahmed khan'), 'AK');
      expect(LedgerText.initials('احمد خان'), 'اخ');
      expect(LedgerText.initials('123'), isNull);
    });

    testWidgets('sort: name, amount, recent; the order is stable', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      Future<void> sortBy(String label) async {
        await tapShown(
          t,
          find.descendant(
            of: find.byKey(LumeLedgerTool.sortKey),
            matching: find.text(label),
          ),
        );
      }

      // The bar says which way it now sorts; the list follows it.
      List<String> ordered(List<String> ascending) {
        final LumeSortBar bar = t.widget(find.byKey(LumeLedgerTool.sortKey));
        return bar.direction == LumeSortDirection.ascending
            ? ascending
            : ascending.reversed.toList();
      }

      await sortBy('Name');
      expect(peopleShown(t), ordered(<String>['Ahmed', 'Bilal', 'Sara']));
      await sortBy('Name');
      expect(peopleShown(t), ordered(<String>['Ahmed', 'Bilal', 'Sara']));
      await sortBy('Amount');
      // Largest balance first, within a currency.
      expect(peopleShown(t), ordered(<String>['Ahmed', 'Bilal', 'Sara']));
      await sortBy('Recent activity');
      expect(peopleShown(t), ordered(<String>['Sara', 'Ahmed', 'Bilal']));
      w.dispose();
    });
  });

  group('entries through the form', () {
    Future<void> openAdd(WidgetTester t) =>
        tapShown(t, find.byKey(LumeLedgerTool.addKey));

    Future<void> pickPerson(WidgetTester t, String name) async {
      await tapShown(t, find.byKey(LumeLedgerTool.personField));
      await tapShown(t, find.widgetWithText(LumeRadioRow, name));
    }

    testWidgets('a loan, saved: the person opens, figures follow', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      await openAdd(t);
      await pickPerson(t, 'Sara');
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '1,000.50');
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      final LedgerEntry e = book(
        w,
      ).entries.firstWhere((LedgerEntry x) => x.amount.minor == 100050);
      expect(e.kind, LedgerKind.lent);
      expect(e.on, LumeDate(2026, 9, 7));
      expect(find.byKey(LumeLedgerTool.personKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('precision is refused, never rounded; nothing is written', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      await openAdd(t);
      await pickPerson(t, 'Sara');
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '12.345');
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      expect(find.text('PKR takes 2 decimal places'), findsOneWidget);
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '0');
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      expect(find.text('Enter an amount above zero'), findsOneWidget);
      expect(book(w).entries, hasLength(3));
      w.dispose();
    });

    testWidgets('Arabic digits and separators are read exactly', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w, locale: const Locale('ar'));
      await openAdd(t);
      await tapShown(t, find.byKey(LumeLedgerTool.personField));
      await tapShown(t, find.widgetWithText(LumeRadioRow, 'Sara'));
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '١٬٢٥٠٫٥٠');
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      expect(
        book(w).entries.map((LedgerEntry e) => e.amount.minor),
        contains(125050),
      );
      w.dispose();
    });

    testWidgets('an overpayment asks; kept as credit it shows on the row', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w, query: 'person=${w.people['Bilal']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.personAddKey));
      await tapShown(t, find.text('Got back'));
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '17500');
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      expect(find.text('More than is open'), findsOneWidget);
      expect(find.textContaining('Rs\u00a0500.00'), findsOneWidget);
      // Cancel: nothing written.
      await tapShown(t, find.byKey(LedgerSheetKeys.cancel));
      expect(book(w).entries, hasLength(3));
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      await tapShown(t, find.byKey(LedgerSheetKeys.confirm));
      final LedgerBalance b = book(w).balancesOf(w.people['Bilal']!).single;
      expect(b.creditToThem.minor, 50000);
      expect(b.direction, LedgerDirection.youOwe);
      expect(find.textContaining('credit'), findsWidgets);
      w.dispose();
    });

    testWidgets('a manual allocation, chosen in the picker', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      final LedgerEntry later = w.add(
        'Ahmed',
        LedgerKind.lent,
        rs(6000),
        LumeDate(2026, 8, 25),
        due: LumeDate(2026, 10, 1),
      );
      await pumpLedger(t, w, query: 'person=${w.people['Ahmed']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.personAddKey));
      await tapShown(t, find.text('Got back'));
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '1000');
      await tapShown(t, find.text('Choose'));
      await t.enterText(
        find.byKey(LumeLedgerTool.applied(later.id.value)),
        '1000',
      );
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      final LedgerAllocation a = book(w).allocations.single;
      expect(a.manual, isTrue);
      expect(a.principalId, later.id);
      w.dispose();
    });
  });

  group('corrections', () {
    testWidgets('void, then restore: the figures return exactly', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      final LedgerEntry r = w.add(
        'Ahmed',
        LedgerKind.repaidToMe,
        rs(4000),
        LumeDate(2026, 8, 20),
      );
      await pumpLedger(t, w, query: 'person=${w.people['Ahmed']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.historyRow(r.id.value)));
      await tapShown(t, find.byKey(LumeLedgerTool.voidKey));
      expect(book(w).entry(r.id)!.voided, isTrue);
      expect(
        book(w).balancesOf(w.people['Ahmed']!).single.balance.minor,
        3400000,
      );
      await tapShown(t, find.byKey(LumeLedgerTool.voidKey));
      expect(book(w).entry(r.id)!.active, isTrue);
      expect(
        book(w).balancesOf(w.people['Ahmed']!).single.balance.minor,
        3000000,
      );
      w.dispose();
    });

    testWidgets('delete asks, then Undo brings back the same entry', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      final LedgerEntry r = w.add(
        'Ahmed',
        LedgerKind.repaidToMe,
        rs(4000),
        LumeDate(2026, 8, 20),
      );
      final LedgerAllocation a = book(w).allocations.single;
      await pumpLedger(t, w, query: 'person=${w.people['Ahmed']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.historyRow(r.id.value)));
      await tapShown(t, find.byKey(LumeLedgerTool.deleteKey));
      await tapShown(t, deleteButton);
      expect(book(w).entry(r.id), isNull);
      await tapShown(t, find.text('Undo'));
      expect(book(w).entry(r.id)!.id, r.id);
      expect(book(w).allocations.single.id, a.id);
      w.dispose();
    });

    testWidgets('deleting a paid loan offers credit or deleting the '
        'repayments; Cancel writes nothing', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.add('Ahmed', LedgerKind.repaidToMe, rs(4000), LumeDate(2026, 8, 20));
      final LedgerEntry loan = book(w).entries.firstWhere(
        (LedgerEntry e) =>
            e.partyId == w.people['Ahmed'] && e.kind == LedgerKind.lent,
      );
      await pumpLedger(t, w, query: 'person=${w.people['Ahmed']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.historyRow(loan.id.value)));
      await tapShown(t, find.byKey(LumeLedgerTool.deleteKey));
      await tapShown(t, deleteButton);
      expect(find.text('Repayments paid this entry'), findsOneWidget);
      await tapShown(t, find.byKey(LedgerSheetKeys.cancel));
      expect(book(w).entry(loan.id), isNotNull);
      w.dispose();
    });

    testWidgets('archive only when settled; a person with entries is never '
        'deleted with them', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w, query: 'person=${w.people['Ahmed']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.archiveKey));
      expect(
        find.text('Only a settled person can be archived.'),
        findsOneWidget,
      );
      await t.pump(const Duration(seconds: 3));
      await tapShown(t, find.byKey(LumeLedgerTool.deletePersonKey));
      expect(book(w).party(w.people['Ahmed']!), isNotNull);
      expect(
        find.textContaining('1 entry still names this person'),
        findsOneWidget,
      );
      w.dispose();
    });
  });

  group('the reminder', () {
    testWidgets('previewed, edited, handed over — never "sent"', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w, query: 'person=${w.people['Bilal']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.personRemindKey));
      final TextField field = t.widget(
        find.descendant(
          of: find.byKey(LedgerSheetKeys.reminderText),
          matching: find.byType(TextField),
        ),
      );
      final String text = field.controller!.text;
      expect(
        text,
        'Hi \u2068Bilal\u2069, a reminder about '
        '\u2068Rs\u00a017,000.00\u2069 from 17 July 2026, due 31 August 2026.',
      );
      expect(text.contains('Rent share'), isFalse);
      expect(
        find.text(
          'Not included: notes, other people, other currencies, record ids.',
        ),
        findsOneWidget,
      );
      expect(w.sharer.shared, isEmpty);
      await t.enterText(find.byKey(LedgerSheetKeys.reminderText), 'Hi Bilal');
      await tapShown(t, find.byKey(LedgerSheetKeys.reminderShare));
      expect(w.sharer.shared, <String>['Hi Bilal']);
      expect(find.text('Handed to your share sheet'), findsOneWidget);
      for (final String claim in <String>['sent', 'delivered', 'received']) {
        expect(find.textContaining(RegExp('\\b$claim\\b')), findsNothing);
      }
      w.dispose();
    });

    testWidgets('dismissed: nothing is said to have happened', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.sharer.outcome = LumeShareOutcome.dismissed;
      await pumpLedger(t, w, query: 'person=${w.people['Bilal']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.personRemindKey));
      await tapShown(t, find.byKey(LedgerSheetKeys.reminderShare));
      expect(find.text('Handed to your share sheet'), findsNothing);
      expect(find.byKey(LedgerSheetKeys.reminderShare), findsOneWidget);
      w.dispose();
    });

    testWidgets('no share sheet on this device: said, never faked', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.sharer.outcome = LumeShareOutcome.unavailable;
      await pumpLedger(t, w, query: 'person=${w.people['Bilal']!.value}');
      await tapShown(t, find.byKey(LumeLedgerTool.personRemindKey));
      await tapShown(t, find.byKey(LedgerSheetKeys.reminderShare));
      expect(find.byKey(LedgerSheetKeys.reminderUnavailable), findsOneWidget);
      expect(
        find.text('Sharing isn\'t available on this device'),
        findsOneWidget,
      );
      expect(find.text('Handed to your share sheet'), findsNothing);
      w.dispose();
    });

    testWidgets('the privacy note and the preview agree: only the reviewed '
        'text leaves, and closing the preview hands over nothing', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      // Ledger shares reviewed content, so its note never says it shares
      // nothing (LumeOutbound.reviewedShare).
      expect(find.text('Private by default'), findsOneWidget);
      expect(find.textContaining('never included in shared'), findsNothing);
      await pumpLedger(t, w, query: 'person=${w.people['Bilal']!.value}');

      await tapShown(t, find.byKey(LumeLedgerTool.personRemindKey));
      // Closed without Share: nothing handed over, nothing claimed.
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(find.byKey(LedgerSheetKeys.reminderText), findsNothing);
      expect(w.sharer.shared, isEmpty);
      expect(find.text('Handed to your share sheet'), findsNothing);

      await tapShown(t, find.byKey(LumeLedgerTool.personRemindKey));
      final String preview = t
          .widget<TextField>(
            find.descendant(
              of: find.byKey(LedgerSheetKeys.reminderText),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;
      await tapShown(t, find.byKey(LedgerSheetKeys.reminderShare));
      // Exactly the previewed text — no note, no other person, no id.
      expect(w.sharer.shared, <String>[preview]);
      final String out = w.sharer.shared.single;
      for (final String hidden in <String>[
        'Rent share',
        'Car repair',
        'Ahmed',
        'Sara',
        for (final LumeRecordId id in w.people.values) id.value,
      ]) {
        expect(out.contains(hidden), isFalse, reason: hidden);
      }
      w.dispose();
    });

    testWidgets('only people who owe the reader can be reminded', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      await tapShown(t, find.byKey(LumeLedgerTool.remindKey));
      expect(find.widgetWithText(LumeRadioRow, 'Ahmed'), findsOneWidget);
      expect(find.widgetWithText(LumeRadioRow, 'Bilal'), findsOneWidget);
      expect(find.widgetWithText(LumeRadioRow, 'Sara'), findsNothing);
      w.dispose();
    });
  });

  group('export and import', () {
    testWidgets('JSON export: names private by default', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      await tapShown(t, find.bySemanticsLabel('Export'));
      await tapShown(t, find.byKey(LedgerSheetKeys.exportGo));
      final LumeExportFile file = w.exporter.exported.single;
      expect(file.fileName, 'lume-ledger-2026-09-07.json');
      expect(file.text.contains('Ahmed'), isFalse);
      expect(file.text.contains('Person 1'), isTrue);
      final Map<String, Object?> doc =
          jsonDecode(file.text) as Map<String, Object?>;
      expect(doc['schema'], 'lume.ledger/1');
      expect(doc['source'], containsPair('store', 'memory'));
      w.dispose();
    });

    testWidgets('CSV export, names chosen', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      await tapShown(t, find.bySemanticsLabel('Export'));
      await tapShown(t, find.byKey(LedgerSheetKeys.exportCsv));
      await tapShown(t, find.byKey(LedgerSheetKeys.exportNames));
      expect(
        find.text(
          'This file will contain the names and notes you typed. Anyone you '
          'give it to can read them.',
        ),
        findsOneWidget,
      );
      await tapShown(t, find.byKey(LedgerSheetKeys.exportGo));
      final LumeExportFile file = w.exporter.exported.single;
      expect(file.fileName, 'lume-ledger-2026-09-07.csv');
      // UTF-8 with a byte-order mark (which `utf8.decode` itself drops).
      expect(file.bytes.take(3).toList(), <int>[0xef, 0xbb, 0xbf]);
      expect(file.text.startsWith('entry_id,'), isTrue);
      expect(file.text.contains('Ahmed'), isTrue);
      w.dispose();
    });

    testWidgets('import: checked first, then all of it', (
      WidgetTester t,
    ) async {
      final LedgerWorld from = LedgerWorld().reference();
      final LedgerBook b = book(from);
      final String doc = ledgerExportJson(
        parties: b.parties,
        entries: b.entries,
        allocations: b.allocations,
        exportedAt: DateTime.utc(2026, 9, 7),
        build: 'test',
        durable: false,
        includePrivate: true,
      );
      final LedgerWorld to = LedgerWorld(seed: 3);
      to.person('Existing');
      await pumpLedger(t, to);
      await tapShown(t, find.bySemanticsLabel('Export'));
      await tapShown(t, find.byKey(LedgerSheetKeys.importOpen));
      await t.enterText(find.byKey(LedgerSheetKeys.importText), '{broken');
      await tapShown(t, find.byKey(LedgerSheetKeys.importCheck));
      expect(find.text('1 problem. Nothing will be imported.'), findsOneWidget);
      expect(book(to).parties, hasLength(1));
      await t.enterText(find.byKey(LedgerSheetKeys.importText), doc);
      await tapShown(t, find.byKey(LedgerSheetKeys.importCheck));
      expect(find.textContaining('Ready: 6 to add'), findsOneWidget);
      await tapShown(t, find.byKey(LedgerSheetKeys.importGo));
      expect(book(to).parties, hasLength(4));
      expect(find.text('Imported 6 records'), findsOneWidget);
      from.dispose();
      to.dispose();
    });
  });

  group('links, restoration and states', () {
    testWidgets('a deep link opens the person; an unknown one says so', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w, query: 'person=${w.people['Sara']!.value}');
      expect(find.byKey(LumeLedgerTool.personKey), findsOneWidget);
      expect(find.text('Sara'), findsWidgets);
      w.dispose();

      final LedgerWorld v = LedgerWorld().reference();
      await pumpLedger(
        t,
        v,
        query: 'person=00000000-0000-4000-8000-000000000999',
      );
      await t.pump();
      expect(find.byKey(LumeLedgerTool.personKey), findsNothing);
      expect(find.text('That person isn\'t in your Ledger.'), findsOneWidget);
      v.dispose();

      final LedgerWorld x = LedgerWorld().reference();
      await pumpLedger(t, x, query: 'person=not-a-uuid');
      await t.pump();
      expect(find.byKey(LumeLedgerTool.personKey), findsNothing);
      x.dispose();
    });

    testWidgets('restoration: the filter and the person survive leaving and '
        'coming back', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      final GoRouter router = await pumpLedger(t, w);
      await tapShown(
        t,
        find.byKey(LumeLedgerTool.filterChip(LedgerFilter.owesYou)),
      );
      router.go('/tools');
      await t.pumpAndSettle();
      router.go('/tools/tool/ledger');
      await t.pumpAndSettle();
      final LumeFilterChip chip = t.widget(
        find.byKey(LumeLedgerTool.filterChip(LedgerFilter.owesYou)),
      );
      expect(chip.selected, isTrue);
      w.dispose();
    });

    testWidgets('day unknown: nothing is overdue or not; the Overdue filter '
        'says why', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(
        t,
        w,
        profile: LumeMemoryProfileRepository(
          initial: taxReader(country: 'US', region: 'New York', city: ''),
        ),
      );
      expect(find.text('Overdue'), findsWidgets);
      final List<LumeRichRow> rows = t
          .widgetList<LumeRichRow>(find.byType(LumeRichRow))
          .toList();
      expect(
        rows.where((LumeRichRow r) => r.badge?.label == 'Overdue'),
        isEmpty,
      );
      await tapShown(
        t,
        find.byKey(LumeLedgerTool.filterChip(LedgerFilter.overdue)),
      );
      expect(find.byKey(LumeLedgerTool.dayUnknownKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('release build: the source line claims no storage it lacks', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(
        t,
        w,
        overrides: <Override>[
          buildProfileProvider.overrideWithValue(LumeBuildProfile.release),
        ],
      );
      final LumeSourceBar bar = t.widget(find.byType(LumeSourceBar));
      expect(<String?>[
        bar.qualityLabel,
        bar.source,
        bar.note,
      ], isNot(contains('Stored on this device')));
      expect(find.text('Kept until you close Lume'), findsOneWidget);
      expect(find.text('Sample data'), findsNothing);
      w.dispose();
    });

    testWidgets('a storage failure on save: said, and nothing changed', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      w.store.refuseWrites = true;
      await tapShown(t, find.byKey(LumeLedgerTool.addKey));
      await tapShown(t, find.byKey(LumeLedgerTool.personField));
      await tapShown(t, find.widgetWithText(LumeRadioRow, 'Sara'));
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '10');
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      expect(find.text('Couldn\'t save. Nothing was changed.'), findsOneWidget);
      expect(book(w).entries, hasLength(3));
      w.dispose();
    });
  });

  group('languages, direction, size and access', () {
    for (final (Locale locale, String net, TextDirection dir)
        in <(Locale, String, TextDirection)>[
          (
            const Locale('ur'),
            AppLocalizationsUr().ledgerNet,
            TextDirection.rtl,
          ),
          (
            const Locale('ar'),
            AppLocalizationsAr().ledgerNet,
            TextDirection.rtl,
          ),
        ]) {
      testWidgets('${locale.languageCode}: its own words, right to left', (
        WidgetTester t,
      ) async {
        final LedgerWorld w = LedgerWorld().reference();
        await pumpLedger(t, w, locale: locale);
        final LumeSummaryCard card = t.widget(
          find.byKey(LumeLedgerTool.summaryKey),
        );
        expect(card.kicker, net);
        expect(
          Directionality.of(t.element(find.byKey(LumeLedgerTool.peopleKey))),
          dir,
        );
        w.dispose();
      });
    }

    testWidgets('200% text: nothing overflows', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w, textScale: 2);
      expect(t.takeException(), isNull);
      w.dispose();
    });

    testWidgets('landscape phone and desktop widths lay out cleanly', (
      WidgetTester t,
    ) async {
      for (final Size s in <Size>[
        const Size(852, 393),
        const Size(1100, 900),
      ]) {
        final LedgerWorld w = LedgerWorld().reference();
        await pumpLedger(t, w, surface: s);
        expect(t.takeException(), isNull);
        expect(find.byKey(LumeLedgerTool.summaryKey), findsOneWidget);
        w.dispose();
      }
    });

    testWidgets('keyboard: Tab reaches the filters, search and rows', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      final Set<Object?> reached = <Object?>{};
      for (int i = 0; i < 30; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();
        reached.add(FocusManager.instance.primaryFocus);
      }
      expect(reached.length, greaterThan(3));
      w.dispose();
    });

    testWidgets('screen readers hear each row\'s direction in words, and '
        'every action is a labelled button (switch access)', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      final LedgerWorld w = LedgerWorld().reference();
      await pumpLedger(t, w);
      expect(find.bySemanticsLabel(RegExp('owes you')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('you owe')), findsWidgets);
      for (final Key k in <Key>[
        LumeLedgerTool.addKey,
        LumeLedgerTool.remindKey,
      ]) {
        expect(
          t.getSemantics(find.byKey(k)),
          isSemantics(
            isButton: true,
            hasTapAction: true,
            isEnabled: true,
            label: k == LumeLedgerTool.addKey
                ? 'Add an entry'
                : 'Send a reminder',
          ),
        );
      }
      h.dispose();
      w.dispose();
    });
  });
}
