/// Ledger and a currency change: Bulgaria's euro (1 January 2026) is the
/// default for what is new, and the lev stays exactly what it was for what
/// is old — decoded, imported, summed apart, exported, never converted.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/ledger/domain/ledger_book.dart';
import 'package:lume/features/ledger/domain/ledger_failure.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/domain/ledger_repository.dart';
import 'package:lume/features/ledger/domain/ledger_transfer.dart';
import 'package:lume/features/ledger/presentation/ledger_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import 'ledger_harness.dart';
import 'ledger_screen_harness.dart';

final LumeCurrency eur = LumeCurrency.of('EUR');
final LumeCurrency bgn = LumeCurrency.of('BGN');

LumeMoney euros(int minor) => LumeMoney.entry(minor, eur);

/// A lev ledger as it would have been kept before the changeover, arriving
/// the only way a withdrawn currency can arrive now: a backup. Written in
/// euros and exported, then relabelled — the export format is the same.
String levBackup() {
  final LedgerHarness h = LedgerHarness(seed: 3);
  final LumeRecordId ivan = h.person('Ivan');
  h.add(ivan, LedgerKind.lent, euros(50000), LumeDate(2025, 11, 3));
  h.add(ivan, LedgerKind.repaidToMe, euros(12050), LumeDate(2025, 12, 1));
  final LedgerBook b = h.book();
  final String doc = ledgerExportJson(
    parties: b.parties,
    entries: b.entries,
    allocations: b.allocations,
    exportedAt: DateTime.utc(2025, 12, 20),
    build: 'test',
    durable: false,
    includePrivate: true,
  );
  h.dispose();
  return doc.replaceAll('"currency": "EUR"', '"currency": "BGN"');
}

/// [into] with the lev backup imported.
void importLev(LedgerHarness into) {
  final LedgerImportReport r = ledgerImportCheck(levBackup(), into.store);
  expect(r.issues, isEmpty);
  expect(ledgerImportApply(r, into.store).ok, isTrue);
}

LumeProfileRepository bulgarian() => LumeMemoryProfileRepository(
  initial: taxReader(country: 'BG', region: '', city: 'Sofia'),
);

void main() {
  group('the domain', () {
    test('a stored lev entry still decodes, with its minor units', () {
      final LedgerHarness h = LedgerHarness();
      importLev(h);
      final List<LedgerEntry> entries = h.book().entries;
      expect(entries, hasLength(2));
      expect(entries.map((LedgerEntry e) => e.currency).toSet(), {bgn});
      expect(entries.map((LedgerEntry e) => e.amount.minor).toSet(), <int>{
        50000,
        12050,
      });
      expect(h.book().defects, isEmpty);
      h.expectSound();
      h.dispose();
    });

    test('a lev backup imports when otherwise valid', () {
      final LedgerHarness h = LedgerHarness();
      final LedgerImportReport r = ledgerImportCheck(levBackup(), h.store);
      expect(r.ok, isTrue, reason: '${r.issues}');
      h.dispose();
    });

    test('lev and euro are summed apart; nothing converts', () {
      final LedgerHarness h = LedgerHarness();
      importLev(h);
      final LumeRecordId ivan = h.book().parties.single.id;
      h.add(ivan, LedgerKind.lent, euros(10000), LumeDate(2026, 3, 1));
      final List<LedgerCurrencySummary> sums = h.book().summaries;
      expect(sums.map((LedgerCurrencySummary s) => s.currency).toSet(), {
        bgn,
        eur,
      });
      LedgerCurrencySummary of(LumeCurrency c) =>
          sums.firstWhere((LedgerCurrencySummary s) => s.currency == c);
      // 500.00 lent less 120.50 repaid, in lev — not a euro figure at 1.95583.
      expect(of(bgn).owedToYou, LumeMoney.entry(37950, bgn));
      expect(of(eur).owedToYou, euros(10000));
      // Ivan has one row per currency, and the lev loan is still open.
      expect(
        h.book().balancesOf(ivan).map((LedgerBalance b) => b.currency).toSet(),
        {bgn, eur},
      );
      h.expectSound();
      h.dispose();
    });

    test('a euro repayment never pays a lev loan', () {
      final LedgerHarness h = LedgerHarness();
      importLev(h);
      final LumeRecordId ivan = h.book().parties.single.id;
      final LedgerEntry levLoan = h.book().entries.firstWhere(
        (LedgerEntry e) => e.kind == LedgerKind.lent,
      );
      final LedgerResult<LedgerWrite> r = h.tryAdd(
        ivan,
        LedgerKind.repaidToMe,
        euros(1000),
        LumeDate(2026, 3, 1),
      );
      // Nothing in euros is owed, so the euro is an overpayment to confirm —
      // never applied to the lev.
      expect(r.failure?.kind, LedgerFailureKind.overpayment);
      expect(h.remaining(levLoan.id), 37950);
      h.dispose();
    });

    test('a new entry is never in the lev', () {
      final LedgerHarness h = LedgerHarness();
      final LumeRecordId ivan = h.person('Ivan');
      final LedgerResult<LedgerWrite> r = h.tryAdd(
        ivan,
        LedgerKind.lent,
        LumeMoney.entry(100, bgn),
        LumeDate(2026, 3, 1),
      );
      expect(r.failure?.kind, LedgerFailureKind.validation);
      expect(r.failure?.field, 'currency');
      expect(h.book().entries, isEmpty);
      expect(ledgerDefaultCurrency('BGN'), isNull);
      expect(ledgerDefaultCurrency('EUR'), eur);
      h.dispose();
    });

    test('a lev entry exports as BGN, in JSON and CSV', () {
      final LedgerHarness h = LedgerHarness();
      importLev(h);
      final LedgerBook b = h.book();
      final Map<String, Object?> doc =
          jsonDecode(
                ledgerExportJson(
                  parties: b.parties,
                  entries: b.entries,
                  allocations: b.allocations,
                  exportedAt: DateTime.utc(2026, 9, 7),
                  build: 'test',
                  durable: false,
                  includePrivate: false,
                ),
              )
              as Map<String, Object?>;
      for (final Object? e in doc['entries']! as List<Object?>) {
        expect((e! as Map<String, Object?>)['currency'], 'BGN');
      }
      for (final Object? a in doc['allocations']! as List<Object?>) {
        expect((a! as Map<String, Object?>)['currency'], 'BGN');
      }
      final String csv = ledgerExportCsv(b);
      expect(csv, contains('BGN'));
      expect(csv, isNot(contains('EUR')));
      h.dispose();
    });
  });

  group('on screen', () {
    setUpAll(loadLumeFonts);

    Future<void> tapShown(WidgetTester t, Finder f) async {
      await t.ensureVisible(f.first);
      await t.pumpAndSettle();
      await t.tap(f.first);
      await t.pumpAndSettle();
    }

    String currencyShown(WidgetTester t) => t
        .widget<LumeFormPicker>(find.byKey(LumeLedgerTool.currencyField))
        .value;

    testWidgets('a Bulgarian reader\'s new entry starts in euros', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld();
      w.person('Ivan');
      await pumpLedger(t, w, profile: bulgarian());
      await tapShown(t, find.byKey(LumeLedgerTool.addKey));
      expect(currencyShown(t), 'EUR');
      // The currency list never offers the lev.
      await tapShown(t, find.byKey(LumeLedgerTool.currencyField));
      expect(find.widgetWithText(LumeRadioRow, 'BGN'), findsNothing);
      await tapShown(t, find.widgetWithText(LumeRadioRow, 'EUR'));
      await tapShown(t, find.byKey(LumeLedgerTool.personField));
      await tapShown(t, find.widgetWithText(LumeRadioRow, 'Ivan'));
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '25.50');
      // The header's Save: the banner that used to lie over it by now has a
      // slot of its own (C92).
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      final LedgerEntry e = w.repo
          .view()
          .book(LumeDate(2026, 9, 7))
          .entries
          .single;
      expect(e.currency, eur);
      expect(e.amount.minor, 2550);
      w.dispose();
    });

    testWidgets('every offered currency can be reached in the list', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld();
      w.person('Ivan');
      await pumpLedger(
        t,
        w,
        profile: bulgarian(),
        surface: const Size(390, 844),
      );
      await tapShown(t, find.byKey(LumeLedgerTool.addKey));
      await tapShown(t, find.byKey(LumeLedgerTool.currencyField));
      final String last = LumeCurrency.offered
          .where((LumeCurrency c) => c != eur)
          .last
          .code;
      final Finder row = find.widgetWithText(LumeRadioRow, last);
      await t.scrollUntilVisible(
        row,
        400,
        scrollable: find.descendant(
          of: find.byType(LumeSheet),
          matching: find.byType(Scrollable),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(row);
      await t.pumpAndSettle();
      expect(currencyShown(t), last);
      expect(t.takeException(), isNull);
      w.dispose();
    });

    testWidgets('lev and euro show side by side, each with its code', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld();
      final LedgerImportReport r = ledgerImportCheck(levBackup(), w.store);
      expect(ledgerImportApply(r, w.store).ok, isTrue);
      w.repo.open();
      final LumeRecordId ivan = w.repo
          .view()
          .book(LumeDate(2026, 9, 7))
          .parties
          .single
          .id;
      w.people['Ivan'] = ivan;
      w.add('Ivan', LedgerKind.lent, euros(10000), LumeDate(2026, 3, 1));
      await pumpLedger(t, w, profile: bulgarian());
      expect(find.textContaining('BGN'), findsWidgets);
      expect(find.textContaining('EUR'), findsWidgets);
      expect(find.textContaining('379.50'), findsWidgets);
      w.dispose();
    });

    testWidgets('changing country or currency changes no stored entry', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld();
      final LedgerImportReport r = ledgerImportCheck(levBackup(), w.store);
      expect(ledgerImportApply(r, w.store).ok, isTrue);
      w.repo.open();
      await pumpLedger(t, w, profile: bulgarian());
      final String before = w.store.debugDump();

      final LumeStartupController gate = ProviderScope.containerOf(
        t.element(find.byKey(LumeLedgerTool.addKey)),
      ).read(startupControllerProvider);
      gate.profileChanged(
        gate.state.profile.copyWith(country: 'PK', city: 'Islamabad'),
      );
      await t.pumpAndSettle();
      gate.profileChanged(gate.state.profile.copyWith(currency: 'USD'));
      await t.pumpAndSettle();

      expect(w.store.debugDump(), before);
      // Only what is new follows the reader's choice.
      await tapShown(t, find.byKey(LumeLedgerTool.addKey));
      expect(currencyShown(t), 'USD');
      w.dispose();
    });
  });
}
