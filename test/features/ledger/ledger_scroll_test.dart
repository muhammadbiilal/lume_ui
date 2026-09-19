/// Where a view opens (regression): Ledger kept the scroll of the view it
/// came from, so a person opened from far down the list opened part-way
/// down their own page, and the form under them. A new view now opens at
/// its top, as Installments' do; a filter or a sort keeps the reader's place.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/features/installments/presentation/installments_tool.dart';
import 'package:lume/features/ledger/presentation/ledger_tool.dart';

import '../../helpers/load_fonts.dart';
import '../installments/installments_screen_harness.dart';
import 'ledger_screen_harness.dart';

ScrollPosition page(WidgetTester t) => t
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(LumeToolFrame),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

Future<void> scrollBy(WidgetTester t, double dy) async {
  page(t).jumpTo(page(t).pixels + dy);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  testWidgets('Ledger: a person, an entry and the form open at their top; '
      'back to the list opens it at its top', (WidgetTester t) async {
    final LedgerWorld w = LedgerWorld().reference();
    await pumpLedger(t, w, surface: const Size(390, 844));
    await scrollBy(t, 400);
    expect(page(t).pixels, greaterThan(0));
    final Finder bilal = find.byKey(
      LumeLedgerTool.row(w.people['Bilal']!.value, 'PKR'),
    );
    await t.ensureVisible(bilal);
    await t.pumpAndSettle();
    await t.tap(bilal);
    await t.pumpAndSettle();
    expect(find.byKey(LumeLedgerTool.personKey), findsOneWidget);
    expect(page(t).pixels, 0);

    await scrollBy(t, 300);
    final Finder add = find.byKey(LumeLedgerTool.personAddKey);
    await t.ensureVisible(add);
    await t.pumpAndSettle();
    await t.tap(add);
    await t.pumpAndSettle();
    expect(find.byKey(LumeLedgerTool.formKey), findsOneWidget);
    expect(page(t).pixels, 0);
    // Leave the form by the toolbar's Back (nothing typed, nothing asked),
    // scroll the person, and leave them the same way.
    await t.tap(find.byType(LumeBackButton));
    await t.pumpAndSettle();
    expect(find.byKey(LumeLedgerTool.personKey), findsOneWidget);
    expect(page(t).pixels, 0);
    await scrollBy(t, 200);
    await t.tap(find.byType(LumeBackButton));
    await t.pumpAndSettle();
    expect(find.byKey(LumeLedgerTool.peopleKey), findsOneWidget);
    expect(page(t).pixels, 0);
    w.dispose();
  });

  testWidgets('Ledger: a filter keeps the reader\'s place', (
    WidgetTester t,
  ) async {
    final LedgerWorld w = LedgerWorld().reference();
    await pumpLedger(t, w, surface: const Size(390, 844));
    await scrollBy(t, 120);
    final double at = page(t).pixels;
    await t.tap(find.byKey(LumeLedgerTool.filterChip(LedgerFilter.owesYou)));
    await t.pumpAndSettle();
    expect(page(t).pixels, at);
    w.dispose();
  });

  testWidgets('Installments: the same rule', (WidgetTester t) async {
    final InstallmentsWorld w = InstallmentsWorld().reference();
    await pumpInstallments(t, w, surface: const Size(390, 844));
    await scrollBy(t, 400);
    final Finder phone = find.byKey(
      LumeInstallmentsTool.row(w.plans['Phone']!.value),
    );
    await t.ensureVisible(phone);
    await t.pumpAndSettle();
    await t.tap(phone);
    await t.pumpAndSettle();
    expect(find.byKey(LumeInstallmentsTool.planKey), findsOneWidget);
    expect(page(t).pixels, 0);
    w.dispose();
  });
}
