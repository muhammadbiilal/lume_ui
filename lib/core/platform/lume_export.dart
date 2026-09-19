/// A tool's data, written out as a file (D7).
///
/// `tool.screen.js` `exportTool`: a tool with `exportRows()` writes a CSV —
/// UTF-8 with a byte-order mark, CRLF lines, a cell quoted when it holds a
/// quote, a comma or a line break — named `lume-<tool>-<yyyy-mm-dd>.csv`; a tool
/// without rows writes a small JSON record. It then toasts "Saved `name`",
/// or "Couldn’t write the file" when the browser threw.
///
/// [LumeExportFile] is that file as a value, validated before it can exist:
/// the name, extension and MIME type agree, the name is safe on every file
/// system, and the bytes are exactly what the reference would have written.
/// [LumeExporter] hands it to the platform; [LumeRecordingExporter] records it
/// and never touches the platform.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

enum LumeExportFormat {
  csv('csv', 'text/csv;charset=utf-8'),
  json('json', 'application/json');

  const LumeExportFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}

@immutable
class LumeExportFile {
  const LumeExportFile._(this.fileName, this.format, this.bytes);

  /// `lume-tool-yyyy-mm-dd` — lower-case letters, digits and hyphens only.
  static final RegExp _tool = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  static String _stem(String tool, DateTime day) {
    if (!_tool.hasMatch(tool)) {
      throw ArgumentError.value(tool, 'tool', 'not a catalogue id');
    }
    String two(int v) => v.toString().padLeft(2, '0');
    return 'lume-$tool-${day.year.toString().padLeft(4, '0')}'
        '-${two(day.month)}-${two(day.day)}';
  }

  /// A CSV of [rows]. Every row must be as wide as the first — a ragged export
  /// is a bug in the tool, not a file.
  factory LumeExportFile.csv({
    required String tool,
    required DateTime day,
    required List<List<Object?>> rows,
  }) {
    if (rows.isEmpty) throw ArgumentError.value(rows, 'rows', 'is empty');
    final int width = rows.first.length;
    if (width == 0 || rows.any((List<Object?> r) => r.length != width)) {
      throw ArgumentError.value(rows, 'rows', 'is ragged or has no columns');
    }
    final String csv = rows
        .map((List<Object?> r) => r.map(csvCell).join(','))
        .join('\r\n');
    return LumeExportFile._(
      '${_stem(tool, day)}.${LumeExportFormat.csv.extension}',
      LumeExportFormat.csv,
      Uint8List.fromList(utf8.encode('\ufeff$csv')),
    );
  }

  /// The reference's record for a tool with nothing tabular to give.
  factory LumeExportFile.record({
    required String tool,
    required DateTime day,
    required DateTime exported,
    required String locale,
    required String currency,
  }) {
    final String body = const JsonEncoder.withIndent('  ')
        .convert(<String, String>{
          'tool': tool,
          'exported': exported.toUtc().toIso8601String(),
          'locale': locale,
          'currency': currency,
        });
    return LumeExportFile._(
      '${_stem(tool, day)}.${LumeExportFormat.json.extension}',
      LumeExportFormat.json,
      Uint8List.fromList(utf8.encode(body)),
    );
  }

  /// `/[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v` — and a
  /// carriage return, which would split a line in every spreadsheet.
  static String csvCell(Object? cell) {
    final String v = cell?.toString() ?? '';
    return RegExp(r'[",\r\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
  }

  /// A document the tool has already written in full — Ledger's
  /// `lume.ledger/1` backup, or its CSV (which carries its own byte-order
  /// mark; one is added only if it is missing).
  factory LumeExportFile.document({
    required String tool,
    required DateTime day,
    required LumeExportFormat format,
    required String text,
  }) {
    final String body =
        format == LumeExportFormat.csv && !text.startsWith('\ufeff')
        ? '\ufeff$text'
        : text;
    return LumeExportFile._(
      '${_stem(tool, day)}.${format.extension}',
      format,
      Uint8List.fromList(utf8.encode(body)),
    );
  }

  final String fileName;
  final LumeExportFormat format;
  final Uint8List bytes;

  String get mimeType => format.mimeType;

  /// The text as written, without the byte-order mark.
  String get text {
    final String s = utf8.decode(bytes);
    return s.startsWith('\ufeff') ? s.substring(1) : s;
  }
}

enum LumeExportOutcome {
  /// The reader chose where the file went.
  saved,

  /// The reader closed the sheet without choosing.
  cancelled,

  /// This platform cannot write the file, or cannot say whether it did.
  unavailable,
  failed,
}

abstract interface class LumeExporter {
  Future<LumeExportOutcome> export(LumeExportFile file);
}

class LumeRecordingExporter implements LumeExporter {
  LumeRecordingExporter({this.outcome = LumeExportOutcome.saved});

  LumeExportOutcome outcome;
  final List<LumeExportFile> exported = <LumeExportFile>[];

  @override
  Future<LumeExportOutcome> export(LumeExportFile file) async {
    exported.add(file);
    return outcome;
  }
}
