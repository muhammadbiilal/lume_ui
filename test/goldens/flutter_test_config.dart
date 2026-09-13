/// Records which golden every run actually compared.
///
/// A missing golden already fails loudly: `matchesGoldenFile` cannot read a
/// file that is not there. An **orphan** fails silently — a committed PNG that
/// no test compares any more is a case that was deleted or renamed without
/// anybody noticing, and the image sits in the repository looking like
/// coverage.
///
/// So the comparator is wrapped rather than replaced: it delegates every
/// comparison and every update to the real one, and writes down the key it was
/// asked about. `scripts/check_goldens.py` unions the files this leaves behind
/// and diffs them against `test/goldens/images/`.
///
/// Flutter runs each test file in its own isolate, so each writes its own
/// record and the checker unions them. One shared file would interleave.
///
/// This applies to `test/goldens/` only — the directory it sits in.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Where the records land. Cleared by the checker, never by a test: two
/// isolates clearing it would each erase the other's.
const String kRecordDir = 'build/golden_keys';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final Directory dir = Directory(kRecordDir);
  if (dir.existsSync()) {
    goldenFileComparator = _RecordingComparator(
      goldenFileComparator,
      File('$kRecordDir/${pid}_${DateTime.now().microsecondsSinceEpoch}.txt'),
    );
  }
  await testMain();
}

/// The real comparator, plus a note of what it was asked about.
class _RecordingComparator implements GoldenFileComparator {
  _RecordingComparator(this._inner, this._record);

  final GoldenFileComparator _inner;
  final File _record;

  void _note(Uri golden) {
    // The key as the test wrote it, resolved against the suite so two files
    // asking for the same image agree on its name.
    _record.writeAsStringSync(
      '${_inner.getTestUri(golden, null).toFilePath()}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) {
    _note(golden);
    return _inner.compare(imageBytes, golden);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) {
    _note(golden);
    return _inner.update(golden, imageBytes);
  }

  @override
  Uri getTestUri(Uri key, int? version) => _inner.getTestUri(key, version);
}
