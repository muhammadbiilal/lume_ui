/// The record form's lifecycle — `crud-engine.js`, the part that decides.
///
/// Values live here and are never read back off the screen, so a rebuild
/// cannot lose what was typed and a failed save cannot clear it (§10). What
/// "valid" means is one function, called on leaving a field for that field
/// and on submitting for all of them, so the two can never disagree:
///
/// * an untouched field is not judged;
/// * leaving a field judges it;
/// * submitting judges every field, keeps every value, and names the first
///   field in error so the screen can move focus to it;
/// * while a save is in flight a second submit does nothing;
/// * a save that finds a newer version stops with a conflict, which Review
///   re-bases on (the next save is a deliberate overwrite) and Reload throws
///   the draft away for.
///
/// What a record *is* — its fields — comes from [LumeRecordSchema].
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/record_model.dart';
import '../domain/record_repository.dart';
import '../domain/record_schema.dart';

/// Which form this is.
enum LumeFormMode { create, edit }

/// What a submit did at once.
enum LumeSubmitStatus {
  /// A save is already in flight; nothing happened.
  busy,

  /// At least one field is in error; [LumeRecordForm.firstError] names it.
  invalid,

  /// The write is under way; [LumeRecordForm.onSettled] will hear how it ended.
  saving,
}

/// How a save ended.
enum LumeSaveOutcome { saved, failed, conflict }

class LumeRecordForm extends ChangeNotifier {
  LumeRecordForm.create({
    required this.schema,
    required this.repository,
    required Map<String, Object?> defaults,
    this.saveDelay = defaultSaveDelay,
  }) : mode = LumeFormMode.create,
       recordId = null,
       _base = null,
       _values = <String, Object?>{
         for (final LumeRecordField f in schema.fields)
           f.name: defaults[f.name] ?? f.blank,
       };

  LumeRecordForm.edit({
    required this.schema,
    required this.repository,
    required LumeRecord record,
    Map<String, Object?> defaults = const <String, Object?>{},
    this.saveDelay = defaultSaveDelay,
  }) : mode = LumeFormMode.edit,
       recordId = record.id,
       _base = record.version,
       _values = <String, Object?>{
         for (final LumeRecordField f in schema.fields)
           f.name: record[f.name] ?? defaults[f.name] ?? f.blank,
       };

  /// `SAVE_MS` — the write, not a decoration on it: a save that lands in the
  /// same tick can never show progress, be double-submitted or fail.
  static const Duration defaultSaveDelay = Duration(milliseconds: 320);

  final LumeRecordSchema schema;
  final LumeRecordRepository repository;
  final LumeFormMode mode;

  /// The record an edit form was opened on.
  final String? recordId;

  /// `null` saves in the same turn — for a test that is not about saving.
  final Duration? saveDelay;

  final Map<String, Object?> _values;
  final Set<String> _touched = <String>{};
  final Map<String, LumeFieldError> _errors = <String, LumeFieldError>{};
  bool _submitted = false;
  bool _busy = false;
  bool _dirty = false;
  LumeWriteFailure? _failure;
  LumeRecord? _conflict;
  int? _base;
  Timer? _pending;

  /// Heard once a save that was under way has ended.
  void Function(LumeSaveOutcome outcome, LumeRecord? record)? onSettled;

  Object? value(String name) => _values[name];
  bool get busy => _busy;
  bool get submitted => _submitted;

  /// Changed since it opened, and not mid-save — `isDirty()`.
  bool get dirty => _dirty && !_busy;

  /// A save the store refused, shown above the form until the next attempt.
  LumeWriteFailure? get failure => _failure;

  /// The newer version a save ran into.
  LumeRecord? get conflict => _conflict;

  /// The first field in error, in schema order.
  String? get firstError {
    for (final LumeRecordField f in schema.fields) {
      if (_errors.containsKey(f.name)) return f.name;
    }
    return null;
  }

  /// The error a field shows: only once it has been left, or the form
  /// submitted. Never before either.
  LumeFieldError? shownError(String name) =>
      _submitted || _touched.contains(name) ? _errors[name] : null;

  /// The verdict on one field, whether or not it is shown yet.
  LumeFieldError? errorFor(LumeRecordField f, Object? v) {
    final bool empty = v == null || (v is String && v.trim().isEmpty);
    if (f.required && empty) return LumeFieldError.required;
    if (f.rule == LumeFieldRule.positive && !empty) {
      final num? n = v is num ? v : num.tryParse('$v'.trim());
      if (n == null || n <= 0) return LumeFieldError.positive;
    }
    return null;
  }

  void _judge(LumeRecordField f) {
    final LumeFieldError? e = errorFor(f, _values[f.name]);
    if (e == null) {
      _errors.remove(f.name);
    } else {
      _errors[f.name] = e;
    }
  }

  LumeRecordField _field(String name) =>
      schema.fields.firstWhere((LumeRecordField f) => f.name == name);

  /// A keystroke. A field the reader is still typing in is re-judged only if
  /// it is already showing a verdict — otherwise the error would move under
  /// them.
  void setValue(String name, Object? v) {
    _values[name] = v;
    _dirty = true;
    if (_submitted || _touched.contains(name)) _judge(_field(name));
    notifyListeners();
  }

  /// Leaving a field.
  void touch(String name) {
    _touched.add(name);
    _judge(_field(name));
    notifyListeners();
  }

  /// Submit.
  LumeSubmitStatus save() {
    if (_busy) return LumeSubmitStatus.busy;
    _submitted = true;
    _failure = null;
    _conflict = null;
    _errors.clear();
    for (final LumeRecordField f in schema.fields) {
      _judge(f);
    }
    if (_errors.isNotEmpty) {
      notifyListeners();
      return LumeSubmitStatus.invalid;
    }
    _busy = true;
    notifyListeners();
    if (saveDelay == null) {
      _write();
    } else {
      _pending = Timer(saveDelay!, _write);
    }
    return LumeSubmitStatus.saving;
  }

  /// What is stored: money and numbers as numbers, the rest as entered.
  Map<String, Object?> get payload => <String, Object?>{
    for (final LumeRecordField f in schema.fields)
      f.name:
          f.kind == LumeRecordFieldKind.money ||
              f.kind == LumeRecordFieldKind.number
          ? _asNumber(_values[f.name])
          : _values[f.name],
  };

  static Object? _asNumber(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    final String s = '$v'.trim();
    return s.isEmpty ? null : num.tryParse(s);
  }

  void _write() {
    _pending = null;
    _busy = false;
    final LumeWriteResult result = mode == LumeFormMode.create
        ? repository.create(schema.collection, payload)
        : repository.update(
            schema.collection,
            recordId!,
            payload,
            expectVersion: _base,
          );
    if (!result.ok) {
      if (result.failure == LumeWriteFailure.conflict) {
        _conflict = result.current;
        notifyListeners();
        onSettled?.call(LumeSaveOutcome.conflict, null);
        return;
      }
      _failure = result.failure;
      notifyListeners();
      onSettled?.call(LumeSaveOutcome.failed, null);
      return;
    }
    _dirty = false;
    notifyListeners();
    onSettled?.call(LumeSaveOutcome.saved, result.record);
  }

  /// Review: keep what the reader wrote and re-base it on the newer version,
  /// so the next save is a deliberate overwrite.
  void reviewConflict() {
    final LumeRecord? newer = _conflict;
    if (newer == null) return;
    _base = newer.version;
    _conflict = null;
    notifyListeners();
  }

  /// Reload: throw the draft away for the newer version.
  void reloadConflict() {
    final LumeRecord? newer = _conflict;
    if (newer == null) return;
    for (final LumeRecordField f in schema.fields) {
      _values[f.name] = newer[f.name] ?? f.blank;
    }
    _base = newer.version;
    _conflict = null;
    _errors.clear();
    _touched.clear();
    _submitted = false;
    _dirty = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }
}
