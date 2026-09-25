/// Health Records on screen: first use, adding, search, filtering, and the
/// one delete confirmation — which never offers Undo, because it cannot
/// honour one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/features/health/domain/health_model.dart';
import 'package:lume/features/health/presentation/health_tool.dart';

import '../../helpers/load_fonts.dart';
import 'health_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('empty: what it is for, one way in, nothing seeded', (
      WidgetTester t,
    ) async {
      final HealthWorld w = HealthWorld();
      await pumpHealth(t, w);
      expect(find.byKey(LumeHealthTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeHealthTool.addKey), findsOneWidget);
      expect(find.text('Annual physical'), findsNothing);
      expect(w.repo.view().records, isEmpty);
      w.dispose();
    });
  });

  group('adding a record', () {
    testWidgets('a new record appears', (WidgetTester t) async {
      final HealthWorld w = HealthWorld();
      await pumpHealth(t, w);
      await tapShown(t, find.byKey(LumeHealthTool.addKey));
      expect(find.byKey(LumeHealthTool.formKey), findsOneWidget);

      await t.enterText(find.byKey(LumeHealthTool.titleField), 'Blood test');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeHealthTool.saveKey));

      expect(find.byKey(LumeHealthTool.recordKey), findsOneWidget);
      expect(w.repo.view().records, hasLength(1));
      expect(w.repo.view().records.single.title, 'Blood test');
      w.dispose();
    });

    testWidgets('an empty title is refused, on screen', (WidgetTester t) async {
      final HealthWorld w = HealthWorld();
      await pumpHealth(t, w);
      await tapShown(t, find.byKey(LumeHealthTool.addKey));
      await tapShown(t, find.byKey(LumeHealthTool.saveKey));

      expect(find.byKey(LumeHealthTool.formKey), findsOneWidget);
      final LumeFormField titleField = t.widget<LumeFormField>(
        find.byKey(LumeHealthTool.titleField),
      );
      expect(titleField.error, isNotNull);
      expect(w.repo.view().records, isEmpty);
      w.dispose();
    });
  });

  group('editing a record', () {
    testWidgets('changes are saved in place', (WidgetTester t) async {
      final HealthWorld w = HealthWorld().reference();
      await pumpHealth(t, w);
      await tapShown(
        t,
        find.byKey(LumeHealthTool.row(w.records['Annual physical']!.value)),
      );
      await tapShown(t, find.text('Edit'));
      expect(find.byKey(LumeHealthTool.formKey), findsOneWidget);

      await t.enterText(
        find.byKey(LumeHealthTool.titleField),
        'Follow-up visit',
      );
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeHealthTool.saveKey));

      expect(w.repo.view().records.single.title, 'Follow-up visit');
      w.dispose();
    });
  });

  group('search', () {
    testWidgets('filters the list by title', (WidgetTester t) async {
      final HealthWorld w = HealthWorld();
      w.add('Annual physical');
      w.add('Lipid panel', kind: HealthRecordKind.report, value: '4.9 mmol/L');
      await pumpHealth(t, w);
      expect(find.text('Annual physical'), findsWidgets);
      expect(find.text('Lipid panel'), findsWidgets);

      await t.enterText(find.byKey(LumeHealthTool.searchKey), 'lipid');
      await t.pumpAndSettle();
      final Finder rows = find.descendant(
        of: find.byKey(LumeHealthTool.listKey),
        matching: find.text('Annual physical'),
      );
      expect(rows, findsNothing);
      expect(
        find.descendant(
          of: find.byKey(LumeHealthTool.listKey),
          matching: find.text('Lipid panel'),
        ),
        findsWidgets,
      );
      w.dispose();
    });
  });

  group('filter', () {
    testWidgets('a kind chip narrows the list to that kind', (
      WidgetTester t,
    ) async {
      final HealthWorld w = HealthWorld();
      w.add('Annual physical');
      w.add('Lipid panel', kind: HealthRecordKind.report);
      await pumpHealth(t, w);

      await tapShown(
        t,
        find.byKey(LumeHealthTool.filterChip(HealthRecordKind.report)),
      );
      expect(
        find.descendant(
          of: find.byKey(LumeHealthTool.listKey),
          matching: find.text('Annual physical'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(LumeHealthTool.listKey),
          matching: find.text('Lipid panel'),
        ),
        findsWidgets,
      );
      w.dispose();
    });
  });

  group('delete', () {
    testWidgets('removes it for good, and offers no Undo', (
      WidgetTester t,
    ) async {
      final HealthWorld w = HealthWorld().reference();
      await pumpHealth(t, w);
      await tapShown(
        t,
        find.byKey(LumeHealthTool.row(w.records['Annual physical']!.value)),
      );
      await tapShown(t, find.text('Delete'));
      final Finder confirmation = find.byType(LumeDeleteConfirmation);
      expect(confirmation, findsOneWidget);
      expect(
        t.widget<LumeDeleteConfirmation>(confirmation).kind,
        LumeDeleteKind.irreversible,
      );
      await tapShown(t, find.text('Delete').last);

      expect(w.repo.view().records, isEmpty);
      expect(find.text('Undo'), findsNothing);
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the empty state is translated', (WidgetTester t) async {
      final HealthWorld w = HealthWorld();
      await pumpHealth(t, w, locale: const Locale('ur'));
      expect(find.byKey(LumeHealthTool.emptyKey), findsOneWidget);
      w.dispose();
    });
  });
}
