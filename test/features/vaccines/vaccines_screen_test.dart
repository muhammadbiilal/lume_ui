/// Vaccinations on screen: first use, adding, validation, editing, deleting
/// (irreversible, no Undo — a health record), and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/features/vaccines/domain/vaccines_model.dart';
import 'package:lume/features/vaccines/domain/vaccines_repository.dart';
import 'package:lume/features/vaccines/presentation/vaccines_tool.dart';

import '../../helpers/load_fonts.dart';
import 'vaccines_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

final LumeDate kToday = LumeDate(2026, 9, 7);

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('empty: what it is for, one way in, nothing seeded', (
      WidgetTester t,
    ) async {
      final VaccinesWorld w = VaccinesWorld();
      await pumpVaccines(t, w);
      expect(find.byKey(LumeVaccinesTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeVaccinesTool.addKey), findsOneWidget);
      expect(w.repo.view().records, isEmpty);
      w.dispose();
    });
  });

  group('adding a vaccination', () {
    testWidgets('a new vaccination appears, dated today by default', (
      WidgetTester t,
    ) async {
      final VaccinesWorld w = VaccinesWorld();
      await pumpVaccines(t, w);
      await tapShown(t, find.byKey(LumeVaccinesTool.addKey));
      expect(find.byKey(LumeVaccinesTool.formKey), findsOneWidget);

      await t.enterText(find.byKey(LumeVaccinesTool.nameField), 'MMR');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeVaccinesTool.saveKey));

      expect(find.byKey(LumeVaccinesTool.recordKey), findsOneWidget);
      expect(w.repo.view().records, hasLength(1));
      final VaccineRecord r = w.repo.view().records.single;
      expect(r.name, 'MMR');
      expect(r.date, kToday);
      expect(r.status, VaccineStatus.given);
      w.dispose();
    });

    testWidgets('an empty name is refused, on screen', (WidgetTester t) async {
      final VaccinesWorld w = VaccinesWorld();
      await pumpVaccines(t, w);
      await tapShown(t, find.byKey(LumeVaccinesTool.addKey));
      await tapShown(t, find.byKey(LumeVaccinesTool.saveKey));

      expect(find.byKey(LumeVaccinesTool.formKey), findsOneWidget);
      final LumeFormField nameField = t.widget<LumeFormField>(
        find.byKey(LumeVaccinesTool.nameField),
      );
      expect(nameField.error, isNotNull);
      expect(w.repo.view().records, isEmpty);
      w.dispose();
    });
  });

  group('editing a vaccination', () {
    testWidgets('changes are saved in place, not duplicated', (
      WidgetTester t,
    ) async {
      final VaccinesWorld w = VaccinesWorld();
      final VaccineRecord seeded = w.repo
          .add(
            VaccineDraft(
              name: 'MMR',
              date: LumeDate(2026, 1, 1),
              status: VaccineStatus.due,
            ),
          )
          .value!
          .record!;
      await pumpVaccines(t, w);

      await tapShown(t, find.byKey(LumeVaccinesTool.row(seeded.id.value)));
      await tapShown(t, find.text('Edit'));
      expect(find.byKey(LumeVaccinesTool.formKey), findsOneWidget);

      await t.enterText(find.byKey(LumeVaccinesTool.nameField), 'MMR booster');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeVaccinesTool.saveKey));

      expect(w.repo.view().records, hasLength(1));
      final VaccineRecord updated = w.repo.view().records.single;
      expect(updated.name, 'MMR booster');
      expect(updated.id, seeded.id);
      w.dispose();
    });
  });

  group('deleting a vaccination — irreversible, no Undo', () {
    testWidgets('removes it for good, and offers no Undo', (
      WidgetTester t,
    ) async {
      final VaccinesWorld w = VaccinesWorld();
      final VaccineRecord seeded = w.repo
          .add(
            VaccineDraft(
              name: 'MMR',
              date: kToday,
              status: VaccineStatus.given,
            ),
          )
          .value!
          .record!;
      await pumpVaccines(t, w);

      await tapShown(t, find.byKey(LumeVaccinesTool.row(seeded.id.value)));
      await tapShown(t, find.text('Delete'));
      expect(find.byType(LumeDeleteConfirmation), findsOneWidget);
      await tapShown(t, find.text('Delete').last);

      expect(w.repo.view().records, isEmpty);
      expect(find.text('Undo'), findsNothing);
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the empty state is translated', (WidgetTester t) async {
      final VaccinesWorld w = VaccinesWorld();
      await pumpVaccines(t, w, locale: const Locale('ur'));
      expect(find.text('ابھی تک کوئی ویکسینیشن نہیں'), findsOneWidget);
      w.dispose();
    });
  });
}
