/// What a record family is — the part of `record-schemas.js` that decides.
///
/// A schema names a collection, its fields, which of them are required, the
/// one rule a field may carry, and whether deleting a record can be undone.
/// How a row, a hero or a fact reads is presentation, and lives with the
/// tool that draws it; how validation runs is the form's, and no schema gets
/// a different idea of what "required" means.
library;

import 'package:flutter/foundation.dart';

/// `text · textarea · number · money · date · time · select · check · attach`.
enum LumeRecordFieldKind {
  text,
  textarea,
  number,
  money,
  date,
  time,
  select,
  check,

  /// A photo or document. Adding one is not built in the reference either:
  /// it says "Attachments are coming soon".
  attach,
}

/// A field's one rule beyond being required.
enum LumeFieldRule {
  /// `positive` — a number greater than zero.
  positive,
}

/// Why a field is in error.
enum LumeFieldError { required, positive }

@immutable
class LumeRecordField {
  const LumeRecordField({
    required this.name,
    required this.kind,
    this.required = false,
    this.optional = false,
    this.wide = false,
    this.rule,
    this.rows = 3,
    this.yearsBack = 50,
    this.yearsAhead = 50,
  });

  final String name;
  final LumeRecordFieldKind kind;
  final bool required;

  /// Marked "Optional" beside its label (§8 marks the optional ones).
  final bool optional;

  /// Spans both columns of a paired form.
  final bool wide;

  final LumeFieldRule? rule;

  /// A textarea's `rows` — Notes' body opens at six.
  final int rows;

  /// How far a date picker may reach either side of the day it opens on.
  ///
  /// Fifty years each way suits a due date, an event or an expense, and was
  /// the host's fixed figure. It is wrong for a date the reader is
  /// *remembering* rather than planning: Birthdays' field opens on today, so
  /// a fifty-year floor could not reach a birth year before 1976 — the tool
  /// could not record most of the people it exists to record. The floor
  /// belongs to the field, so the family says how far back its own date
  /// goes (C100).
  final int yearsBack;

  /// The same, forward. A birth date has no business being in 2076 either,
  /// but a wrong future date is a visible mistake where a missing past one
  /// is a wall, so this stays at fifty unless a family says otherwise.
  final int yearsAhead;

  /// `defaultFor()` for kinds with no context: an unticked box, an empty
  /// string. Dates, times and selects take theirs from the tool.
  Object? get blank => kind == LumeRecordFieldKind.check ? false : '';
}

@immutable
class LumeRecordSchema {
  const LumeRecordSchema({
    required this.collection,
    required this.fields,
    this.recoverable = true,
  });

  /// `coll` — and the tool id.
  final String collection;

  final List<LumeRecordField> fields;

  /// Whether a delete offers Undo. Documents and health records say no, and
  /// their confirmation says so instead of promising one.
  final bool recoverable;
}
