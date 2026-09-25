/// Medication on screen: first use, adding, editing, deleting with undo,
/// and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/meds/domain/meds_model.dart';
import 'package:lume/features/meds/presentation/meds_sheets.dart';
import 'package:lume/features/meds/presentation/meds_tool.dart';

import '../../helpers/load_fonts.dart';
import 'meds_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('starts empty, nothing rotated in from a fixture', (
      WidgetTester t,
    ) async {
      final MedsWorld w = MedsWorld();
      await pumpMeds(t, w);
      expect(find.byKey(LumeMedsTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeMedsTool.addKey), findsOneWidget);
      expect(w.repo.view().medications, isEmpty);
      w.dispose();
    });
  });

  group('adding a medication', () {
    testWidgets('fills the form, saves, and shows up in the list', (
      WidgetTester t,
    ) async {
      final MedsWorld w = MedsWorld();
      await pumpMeds(t, w);
      await tapShown(t, find.byKey(LumeMedsTool.addKey));

      await t.enterText(find.byKey(LumeMedsTool.nameField), 'Metformin');
      await t.enterText(find.byKey(LumeMedsTool.doseField), '500 mg');
      await t.enterText(find.byKey(LumeMedsTool.dosesLeftField), '22');
      await t.pumpAndSettle();

      await tapShown(t, find.byKey(LumeMedsTool.scheduleField));
      await tapShown(
        t,
        find.byKey(MedsSheetKeys.scheduleOption(MedsSchedule.twice)),
      );

      await tapShown(t, find.byKey(LumeMedsTool.saveKey));

      expect(w.repo.view().medications, hasLength(1));
      final MedsEntry saved = w.repo.view().medications.single;
      expect(saved.name, 'Metformin');
      expect(saved.dose, '500 mg');
      expect(saved.schedule, MedsSchedule.twice);
      expect(saved.dosesLeft, 22);
      // Back on the detail screen for the medication just saved.
      expect(find.text('Metformin'), findsWidgets);
      w.dispose();
    });

    testWidgets('an empty name is refused, nothing is written', (
      WidgetTester t,
    ) async {
      final MedsWorld w = MedsWorld();
      await pumpMeds(t, w);
      await tapShown(t, find.byKey(LumeMedsTool.addKey));
      await t.enterText(find.byKey(LumeMedsTool.doseField), '500 mg');
      await tapShown(t, find.byKey(LumeMedsTool.saveKey));
      expect(w.repo.view().medications, isEmpty);
      expect(find.byKey(LumeMedsTool.formKey), findsOneWidget);
      w.dispose();
    });
  });

  group('editing a medication', () {
    testWidgets('changes are written back, not duplicated', (
      WidgetTester t,
    ) async {
      final MedsWorld w = MedsWorld();
      w.add('Vitamin D', dose: '50,000 IU', dosesLeft: 8);
      await pumpMeds(t, w);

      await tapShown(
        t,
        find.byKey(LumeMedsTool.row(w.repo.view().medications.single.id.value)),
      );
      expect(find.byKey(LumeMedsTool.medicationKey), findsOneWidget);
      // The Edit action opens the same form pre-filled.
      await tapShown(t, find.text('Edit'));

      await t.enterText(find.byKey(LumeMedsTool.dosesLeftField), '3');
      await tapShown(t, find.byKey(LumeMedsTool.saveKey));

      expect(w.repo.view().medications, hasLength(1));
      final MedsEntry edited = w.repo.view().medications.single;
      expect(edited.dosesLeft, 3);
      expect(edited.runningLow, isTrue);
      w.dispose();
    });
  });

  group('deleting a medication', () {
    testWidgets('removes it, and Undo brings it back', (WidgetTester t) async {
      final MedsWorld w = MedsWorld();
      final MedsEntry m = w.add('Cetirizine', dose: '10 mg');
      await pumpMeds(t, w);

      await tapShown(t, find.byKey(LumeMedsTool.row(m.id.value)));
      await tapShown(t, find.text('Delete'));
      expect(find.byKey(MedsSheetKeys.confirm), findsOneWidget);
      await tapShown(t, find.text('Delete').last);

      expect(w.repo.view().medications, isEmpty);

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().medications, hasLength(1));
      expect(w.repo.view().medications.single.name, 'Cetirizine');
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the empty state is translated', (WidgetTester t) async {
      final MedsWorld w = MedsWorld();
      await pumpMeds(t, w, locale: const Locale('ur'));
      expect(find.text('کوئی دوا درج نہیں'), findsOneWidget);
      w.dispose();
    });
  });
}
