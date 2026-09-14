/// The record form's lifecycle, held to `crud-engine.js`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/records/application/record_form.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/domain/record_schema.dart';

const LumeRecordSchema kSchema = LumeRecordSchema(
  collection: 'expenses',
  fields: <LumeRecordField>[
    LumeRecordField(
      name: 'title',
      kind: LumeRecordFieldKind.text,
      required: true,
    ),
    LumeRecordField(
      name: 'amount',
      kind: LumeRecordFieldKind.money,
      required: true,
      rule: LumeFieldRule.positive,
    ),
    LumeRecordField(
      name: 'notes',
      kind: LumeRecordFieldKind.textarea,
      optional: true,
    ),
  ],
);

LumeMemoryRecordRepository repo() => LumeMemoryRecordRepository(
  now: () => DateTime(2026, 9, 7, 16, 41),
  hydrateDelay: null,
);

void main() {
  test('an untouched field is not judged; leaving it is', () {
    final LumeRecordForm f = LumeRecordForm.create(
      schema: kSchema,
      repository: repo(),
      defaults: const <String, Object?>{},
      saveDelay: null,
    );
    expect(f.shownError('title'), isNull);
    f.setValue('title', '');
    expect(f.shownError('title'), isNull, reason: 'still typing');
    f.touch('title');
    expect(f.shownError('title'), LumeFieldError.required);
    f.setValue('title', 'Tea');
    expect(f.shownError('title'), isNull, reason: 're-judged once shown');
  });

  test(
    'a submit judges everything, keeps every value, names the first error',
    () {
      final LumeRecordForm f = LumeRecordForm.create(
        schema: kSchema,
        repository: repo(),
        defaults: const <String, Object?>{},
        saveDelay: null,
      );
      f.setValue('notes', 'kept');
      f.setValue('amount', '0');
      expect(f.save(), LumeSubmitStatus.invalid);
      expect(f.firstError, 'title');
      expect(f.shownError('amount'), LumeFieldError.positive);
      expect(f.value('notes'), 'kept');
    },
  );

  // A widget test's clock is a fake one, so the 320 ms write is timed exactly.
  testWidgets(
    'a save is busy while in flight, and a second submit does nothing',
    (WidgetTester tester) async {
      final LumeMemoryRecordRepository r = repo();
      r.open('expenses');
      final LumeRecordForm f = LumeRecordForm.create(
        schema: kSchema,
        repository: r,
        defaults: const <String, Object?>{},
      );
      addTearDown(f.dispose);
      final List<LumeSaveOutcome> outcomes = <LumeSaveOutcome>[];
      f.onSettled = (LumeSaveOutcome o, LumeRecord? rec) => outcomes.add(o);
      f.setValue('title', 'Tea');
      f.setValue('amount', '4.5');
      expect(f.save(), LumeSubmitStatus.saving);
      expect(f.busy, isTrue);
      expect(f.dirty, isFalse, reason: 'mid-save is not dirty');
      expect(f.save(), LumeSubmitStatus.busy);
      await tester.pump(LumeRecordForm.defaultSaveDelay);
      expect(outcomes, <LumeSaveOutcome>[LumeSaveOutcome.saved]);
      expect(r.view('expenses').items.single['amount'], 4.5);
    },
  );

  test('a refused save keeps the draft and says so', () {
    final LumeMemoryRecordRepository r = repo()..refuseWrites = true;
    final LumeRecordForm f = LumeRecordForm.create(
      schema: kSchema,
      repository: r,
      defaults: const <String, Object?>{},
      saveDelay: null,
    );
    LumeSaveOutcome? outcome;
    f.onSettled = (LumeSaveOutcome o, LumeRecord? rec) => outcome = o;
    f.setValue('title', 'Tea');
    f.setValue('amount', '4');
    f.save();
    expect(outcome, LumeSaveOutcome.failed);
    expect(f.failure, LumeWriteFailure.storage);
    expect(f.value('title'), 'Tea');
    expect(f.dirty, isTrue);
  });

  test(
    'a conflict stops the save; Review re-bases, Reload takes the newer one',
    () {
      final LumeMemoryRecordRepository r = repo();
      final LumeRecord rec = r.create('expenses', <String, Object?>{
        'title': 'Tea',
        'amount': 4,
      }).record!;
      final LumeRecordForm f = LumeRecordForm.edit(
        schema: kSchema,
        repository: r,
        record: rec,
        saveDelay: null,
      );
      // Someone else saves first.
      r.update('expenses', rec.id, <String, Object?>{'title': 'Chai'});
      LumeSaveOutcome? outcome;
      f.onSettled = (LumeSaveOutcome o, LumeRecord? x) => outcome = o;
      f.setValue('amount', '5');
      f.save();
      expect(outcome, LumeSaveOutcome.conflict);
      expect(f.conflict!['title'], 'Chai');

      f.reviewConflict();
      f.save();
      expect(outcome, LumeSaveOutcome.saved);
      expect(r.get('expenses', rec.id)!['amount'], 5);
      expect(
        r.get('expenses', rec.id)!['title'],
        'Tea',
        reason: 'the draft won',
      );

      final LumeRecordForm g = LumeRecordForm.edit(
        schema: kSchema,
        repository: r,
        record: r.get('expenses', rec.id)!,
        saveDelay: null,
      );
      r.update('expenses', rec.id, <String, Object?>{'title': 'Green tea'});
      g.setValue('title', 'Mine');
      g.save();
      g.reloadConflict();
      expect(g.value('title'), 'Green tea');
      expect(g.dirty, isFalse);
    },
  );
}
