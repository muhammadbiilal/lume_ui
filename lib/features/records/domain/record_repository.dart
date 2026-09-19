/// Where a record tool's records live — the shape of `records.js`.
///
/// One store for every family. It holds records, reports what happened, and
/// tells whoever is listening; it formats, translates and draws nothing.
///
/// **Durability is declared, not implied.** The reference writes its records
/// to the browser's storage. This build takes no storage package
/// (`DAYROZ_ARCHITECTURE_MAPPING.md`: reference state is fixtures, not
/// persistence), so the implementation here keeps records for as long as the
/// app runs and says so through [LumeRecordRepository.durable]. A screen that
/// would claim "kept on this device" reads that flag first (C74). Dayroz
/// supplies the durable, encrypted store behind this same interface.
library;

import 'package:flutter/foundation.dart';

import 'record_model.dart';
import 'record_transaction.dart';

/// Every store also commits several records at once
/// ([LumeRecordTransactions]) — a family whose records depend on each other
/// needs it, and a store that cannot must not pretend to.
abstract interface class LumeRecordRepository
    implements Listenable, LumeRecordTransactions {
  /// Whether a write survives the app being closed.
  bool get durable;

  /// Whether writes are being queued rather than made current.
  bool get isOffline;

  /// Start reading [collection] if it has not been read, and say what to draw
  /// now. The first open of a collection is a loading state; listeners hear
  /// when the records arrive.
  LumeCollectionView open(String collection);

  /// What to draw for [collection] now, without starting a read.
  LumeCollectionView view(String collection);

  /// One record, or `null` when it is not (or no longer) there.
  LumeRecord? get(String collection, String id);

  /// Newest first — a record just created is visible without scrolling.
  LumeWriteResult create(String collection, Map<String, Object?> fields);

  /// [expectVersion] is the version the form was opened against. Passing it is
  /// what makes a conflict detectable; omitting it is a deliberate overwrite.
  ///
  /// [claim] says the reader has written the record's words — a form's save —
  /// so a sample record becomes theirs and is never re-translated. A tick on
  /// a row writes no words and passes `false`, keeping a sample record's
  /// text in the reader's language (`records.js` `update` keeps `_seed`
  /// unless the form clears it).
  LumeWriteResult update(
    String collection,
    String id,
    Map<String, Object?> fields, {
    int? expectVersion,
    bool claim = true,
  });

  LumeWriteResult remove(String collection, String id);

  /// Reverse the last write, and nothing else — one step, not a stack. `null`
  /// when there is nothing to reverse, which is the honest answer after a
  /// bulk clear or an irreversible delete.
  LumeUndone? undo();

  bool get canUndo;

  /// Drop the one step of history, so an Undo that could not be honoured is
  /// never offered.
  void forgetUndo();

  /// After a load error, try again rather than re-reporting it.
  LumeCollectionView retry(String collection);
}
