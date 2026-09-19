/// A withdrawn currency in Ledger (LumeCurrencyPolicy): the lev is never
/// used for something new, and stays usable for what services a lev record
/// already kept — its repayment, its correction, its void and restore, its
/// import and export. Nothing converts it.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency_policy.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/features/ledger/domain/ledger_book.dart';
import 'package:lume/features/ledger/domain/ledger_failure.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/domain/ledger_repository.dart';
import 'package:lume/features/ledger/domain/ledger_transfer.dart';
import 'package:lume/features/ledger/presentation/ledger_tool.dart';

import '../../helpers/load_fonts.dart';
import 'ledger_currency_test.dart' show bulgarian, eur, bgn, euros, levBackup;
import 'ledger_harness.dart';
import 'ledger_screen_harness.dart';

LumeMoney lev(int minor) => LumeMoney.entry(minor, bgn);

/// Ivan with the lev backup: 500.00 lent on 3 Nov 2025, 120.50 repaid.
(LedgerHarness, LumeRecordId, LedgerEntry) levWorld() {
  final LedgerHarness h = LedgerHarness();
  final LedgerImportReport r = ledgerImportCheck(levBackup(), h.store);
  expect(ledgerImportApply(r, h.store).ok, isTrue);
  final LedgerBook b = h.book();
  return (
    h,
    b.parties.single.id,
    b.entries.firstWhere((LedgerEntry e) => e.kind == LedgerKind.lent),
  );
}

void main() {
  group('the domain', () {
    test('a lev repayment pays the lev loan it services', () {
      final (LedgerHarness h, LumeRecordId ivan, LedgerEntry loan) = levWorld();
      final LedgerEntry r = h.add(
        ivan,
        LedgerKind.repaidToMe,
        lev(10000),
        LumeDate(2026, 9, 1),
      );
      expect(r.currency, bgn);
      expect(h.remaining(loan.id), 50000 - 12050 - 10000);
      expect(h.paid(r.id), <(LumeRecordId, int)>[(loan.id, 10000)]);
      expect(
        ledgerCurrencyAvailability(
          h.book().entries,
          partyId: ivan,
          kind: LedgerKind.repaidToMe,
          currency: bgn,
        ),
        LumeCurrencyAvailability.historicalForExistingRecord,
      );
      h.expectSound();
      h.dispose();
    });

    test('a new lev principal is refused, even beside a lev loan', () {
      final (LedgerHarness h, LumeRecordId ivan, _) = levWorld();
      for (final LedgerKind k in <LedgerKind>[
        LedgerKind.lent,
        LedgerKind.borrowed,
      ]) {
        final LedgerResult<LedgerWrite> r = h.tryAdd(
          ivan,
          k,
          lev(100),
          LumeDate(2026, 9, 1),
        );
        expect(r.failure?.field, 'currency', reason: '$k');
        expect(r.failure?.reason, 'withdrawn');
      }
      expect(h.book().entries, hasLength(2));
      h.dispose();
    });

    test('the lev never repays a euro loan, nor the wrong direction', () {
      final (LedgerHarness h, LumeRecordId ivan, _) = levWorld();
      final LumeRecordId mira = h.person('Mira');
      h.add(mira, LedgerKind.lent, euros(5000), LumeDate(2026, 9, 1));
      // Mira owes euros: a lev repayment has nothing in lev to service.
      final LedgerResult<LedgerWrite> r = h.tryAdd(
        mira,
        LedgerKind.repaidToMe,
        lev(5000),
        LumeDate(2026, 9, 2),
      );
      expect(r.failure?.reason, 'withdrawn');
      // Ivan's lev loan is one the reader lent: the reader paying Ivan back
      // in lev services nothing.
      final LedgerResult<LedgerWrite> back = h.tryAdd(
        ivan,
        LedgerKind.repaidByMe,
        lev(100),
        LumeDate(2026, 9, 2),
      );
      expect(back.failure?.reason, 'withdrawn');
      h.dispose();
    });

    test('a lev entry is corrected in lev', () {
      final (LedgerHarness h, LumeRecordId ivan, LedgerEntry loan) = levWorld();
      final LedgerResult<LedgerWrite> r = h.repo.editEntry(
        loan.id,
        LedgerEntryDraft(
          partyId: ivan,
          kind: LedgerKind.lent,
          amount: lev(60000),
          on: loan.on,
          note: 'Corrected',
        ),
        version: loan.version,
      );
      expect(r.failure, isNull);
      expect(h.entry(loan.id).currency, bgn);
      expect(h.remaining(loan.id), 60000 - 12050);
      h.expectSound();
      h.dispose();
    });

    test('void and restore a lev loan: the same figures come back', () {
      final (LedgerHarness h, _, LedgerEntry loan) = levWorld();
      final List<LedgerCurrencySummary> before = h.book().summaries;
      // Voiding a paid loan turns what repaid it into credit: confirmed.
      expect(
        h.repo
            .setVoided(
              loan.id,
              true,
              version: loan.version,
              confirmExcess: true,
            )
            .ok,
        isTrue,
      );
      // The repayment it had is lev credit now, and stays lev.
      final LedgerEntry rep = h.book().entries.firstWhere(
        (LedgerEntry e) => e.kind == LedgerKind.repaidToMe,
      );
      expect(h.credit(rep.id), 12050);
      expect(
        h.repo.setVoided(loan.id, false, version: h.entry(loan.id).version).ok,
        isTrue,
      );
      expect(h.remaining(loan.id), 50000 - 12050);
      expect(h.credit(rep.id), 0);
      expect(
        h.book().summaries.map((LedgerCurrencySummary s) => s.net),
        before.map((LedgerCurrencySummary s) => s.net),
      );
      h.expectSound();
      h.dispose();
    });

    test('lev credit serves only a lev loan, and opens nothing new', () {
      final (LedgerHarness h, LumeRecordId ivan, LedgerEntry loan) = levWorld();
      // Overpaid in lev, confirmed: the excess is credit, in lev.
      final LedgerEntry over = h.add(
        ivan,
        LedgerKind.repaidToMe,
        lev(40000),
        LumeDate(2026, 9, 2),
        confirm: true,
      );
      expect(h.remaining(loan.id), 0);
      expect(h.credit(over.id), 40000 - (50000 - 12050));
      expect(h.credit(over.id) > 0, isTrue);
      // A euro loan to Ivan is not paid by lev credit.
      final LedgerEntry euroLoan = h.add(
        ivan,
        LedgerKind.lent,
        euros(1000),
        LumeDate(2026, 9, 3),
      );
      expect(h.remaining(euroLoan.id), 1000);
      // And the credit is no reason to let a new lev loan in.
      final LedgerResult<LedgerWrite> r = h.tryAdd(
        ivan,
        LedgerKind.lent,
        lev(100),
        LumeDate(2026, 9, 4),
      );
      expect(r.failure?.reason, 'withdrawn');
      h.expectSound();
      h.dispose();
    });

    test('export and import after a lev repayment: still BGN, lossless', () {
      final (LedgerHarness h, LumeRecordId ivan, _) = levWorld();
      h.add(ivan, LedgerKind.repaidToMe, lev(1000), LumeDate(2026, 9, 1));
      final LedgerBook b = h.book();
      final String doc = ledgerExportJson(
        parties: b.parties,
        entries: b.entries,
        allocations: b.allocations,
        exportedAt: DateTime.utc(2026, 9, 7),
        build: 'test',
        durable: false,
        includePrivate: true,
      );
      final Map<String, Object?> json = jsonDecode(doc) as Map<String, Object?>;
      for (final Object? e in json['entries']! as List<Object?>) {
        expect((e! as Map<String, Object?>)['currency'], 'BGN');
      }
      final LedgerHarness fresh = LedgerHarness(seed: 9);
      final LedgerImportReport r = ledgerImportCheck(doc, fresh.store);
      expect(r.issues, isEmpty);
      expect(ledgerImportApply(r, fresh.store).ok, isTrue);
      expect(
        fresh.book().entries.map((LedgerEntry e) => e.amount),
        unorderedEquals(b.entries.map((LedgerEntry e) => e.amount)),
      );
      h.dispose();
      fresh.dispose();
    });

    test('what is new still defaults to the euro', () {
      expect(ledgerDefaultCurrency('EUR'), eur);
      expect(ledgerDefaultCurrency('BGN'), isNull);
    });
  });

  group('the form', () {
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

    LedgerWorld levScreenWorld() {
      final LedgerWorld w = LedgerWorld();
      final LedgerImportReport r = ledgerImportCheck(levBackup(), w.store);
      expect(ledgerImportApply(r, w.store).ok, isTrue);
      w.repo.open();
      w.people['Ivan'] = w.repo
          .view()
          .book(LumeDate(2026, 9, 7))
          .parties
          .single
          .id;
      return w;
    }

    testWidgets('a repayment to the lev loan starts in lev, said as no longer '
        'issued, and saves in lev', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final LedgerWorld w = levScreenWorld();
      await pumpLedger(t, w, profile: bulgarian());
      await tapShown(t, find.byKey(LumeLedgerTool.addKey));
      // Something new: the euro, and no lev on the list.
      expect(currencyShown(t), 'EUR');
      await tapShown(t, find.byKey(LumeLedgerTool.personField));
      await tapShown(t, find.widgetWithText(LumeRadioRow, 'Ivan'));
      expect(currencyShown(t), 'EUR');
      await tapShown(t, find.byKey(LumeLedgerTool.currencyField));
      expect(find.textContaining('BGN'), findsNothing);
      Navigator.of(t.element(find.byType(LumeRadioRow).first)).pop();
      await t.pumpAndSettle();

      // A repayment from Ivan: what it repays is kept in lev.
      await tapShown(t, find.text('Got back'));
      expect(currencyShown(t), 'BGN · no longer issued');
      // A screen reader hears it: the field's value, not only its picture.
      expect(
        t.getSemantics(find.byKey(LumeLedgerTool.currencyField)).value,
        'BGN · no longer issued',
      );
      await tapShown(t, find.byKey(LumeLedgerTool.currencyField));
      expect(
        find.widgetWithText(LumeRadioRow, 'BGN · no longer issued'),
        findsOneWidget,
      );
      await tapShown(
        t,
        find.widgetWithText(LumeRadioRow, 'BGN · no longer issued'),
      );
      await t.enterText(find.byKey(LumeLedgerTool.amountField), '10');
      await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
      final LedgerEntry saved = w.repo
          .view()
          .book(LumeDate(2026, 9, 7))
          .entries
          .firstWhere((LedgerEntry e) => e.amount.minor == 1000);
      expect(saved.currency, bgn);
      expect(saved.kind, LedgerKind.repaidToMe);

      // Saved, the form opens Ivan. A new entry from there: back to a loan,
      // the lev goes and the euro returns.
      expect(find.byKey(LumeLedgerTool.personKey), findsOneWidget);
      await tapShown(t, find.byKey(LumeLedgerTool.personAddKey));
      await tapShown(t, find.text('Got back'));
      expect(currencyShown(t), 'BGN · no longer issued');
      await tapShown(t, find.text('Lent'));
      expect(currencyShown(t), 'EUR');
      h.dispose();
      w.dispose();
    });

    testWidgets('Urdu and Arabic say the lev is no longer issued', (
      WidgetTester t,
    ) async {
      for (final (Locale locale, String said) in <(Locale, String)>[
        (const Locale('ur'), 'BGN · اب جاری نہیں'),
        (const Locale('ar'), 'BGN · لم تعد تُصدر'),
      ]) {
        final LedgerWorld w = levScreenWorld();
        await pumpLedger(t, w, profile: bulgarian(), locale: locale);
        await tapShown(t, find.byKey(LumeLedgerTool.addKey));
        await tapShown(t, find.byKey(LumeLedgerTool.personField));
        await tapShown(t, find.widgetWithText(LumeRadioRow, 'Ivan'));
        await tapShown(t, find.byKey(LumeLedgerTool.kindField));
        final Finder chips = find.descendant(
          of: find.byKey(LumeLedgerTool.kindField),
          matching: find.byType(LumeFilterChip),
        );
        // The third kind is "they paid you back".
        await tapShown(t, chips.at(LedgerKind.repaidToMe.index));
        expect(currencyShown(t), said, reason: '$locale');
        w.dispose();
      }
    });
  });
}
