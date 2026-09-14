/// The share and export contracts (D7): what can leave, in what form, and
/// that every outcome is reported rather than assumed.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/platform/lume_share_platform.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('a share card is honest content or nothing', () {
    test('words and their source, trimmed', () {
      final LumeShareCard card = LumeShareCard.tryCreate(
        kind: LumeShareKind.reminder,
        text: '  Tax due (annual): Rs 120,000 ',
        source: ' FBR · 2025-26 ',
      )!;
      expect(card.text, 'Tax due (annual): Rs 120,000');
      expect(card.source, 'FBR · 2025-26');
      expect(card.caption, 'Tax due (annual): Rs 120,000 — FBR · 2025-26');
      expect(card.fileName, 'lume-reminder.png');
    });

    for (final (String why, String text, String source, String? arabic)
        in <(String, String, String, String?)>[
          ('no words', '   ', 'Lume', null),
          ('no source', 'A figure', '  ', null),
          ('too long to draw', 'x' * 281, 'Lume', null),
          ('an empty Arabic line', 'Words', 'Lume', ' '),
        ]) {
      test('refused: $why', () {
        expect(
          LumeShareCard.tryCreate(
            kind: LumeShareKind.quote,
            text: text,
            source: source,
            arabic: arabic,
          ),
          isNull,
        );
      });
    }

    test('a sensitive tool never makes a card', () {
      expect(
        LumeShareCard.forFeature(
          sensitive: true,
          kind: LumeShareKind.quote,
          text: 'Blood pressure 120/80',
          source: 'Health Records',
        ),
        isNull,
      );
      expect(
        LumeShareCard.forFeature(
          sensitive: false,
          kind: LumeShareKind.quote,
          text: 'Chicken Karahi',
          source: 'Recipe library',
        ),
        isNotNull,
      );
    });
  });

  group('an export is the file the reference writes', () {
    final DateTime day = DateTime(2026, 9, 7);

    test('CSV: byte-order mark, CRLF, quoted where it must be', () {
      final LumeExportFile f = LumeExportFile.csv(
        tool: 'tax',
        day: day,
        rows: <List<Object?>>[
          <Object?>['Band', 'Rate', 'Taxed here'],
          <Object?>['Up to 600,000', '0%', 0],
          <Object?>['He said "no"', null, 'two\nlines'],
        ],
      );
      expect(f.fileName, 'lume-tax-2026-09-07.csv');
      expect(f.mimeType, 'text/csv;charset=utf-8');
      expect(f.bytes.take(3), <int>[0xEF, 0xBB, 0xBF]);
      expect(
        f.text,
        'Band,Rate,Taxed here\r\n'
        '"Up to 600,000",0%,0\r\n'
        '"He said ""no""",,"two\nlines"',
      );
    });

    test('the reference quoting rule, cell by cell', () {
      expect(LumeExportFile.csvCell('plain'), 'plain');
      expect(LumeExportFile.csvCell('a,b'), '"a,b"');
      expect(LumeExportFile.csvCell('a"b'), '"a""b"');
      expect(LumeExportFile.csvCell('a\rb'), '"a\rb"');
      expect(LumeExportFile.csvCell(12.5), '12.5');
      expect(LumeExportFile.csvCell(null), '');
    });

    test('JSON: the record a tool without rows writes', () {
      final LumeExportFile f = LumeExportFile.record(
        tool: 'timer',
        day: day,
        exported: DateTime.utc(2026, 9, 7, 11, 41, 32),
        locale: 'en-PK',
        currency: 'PKR',
      );
      expect(f.fileName, 'lume-timer-2026-09-07.json');
      expect(f.mimeType, 'application/json');
      expect(jsonDecode(f.text), <String, String>{
        'tool': 'timer',
        'exported': '2026-09-07T11:41:32.000Z',
        'locale': 'en-PK',
        'currency': 'PKR',
      });
    });

    test('extension and MIME type always agree', () {
      for (final LumeExportFormat format in LumeExportFormat.values) {
        expect(
          format.mimeType,
          contains(format.extension == 'csv' ? 'csv' : 'json'),
        );
      }
    });

    for (final String bad in <String>[
      '../tax',
      'Tax',
      'tax tool',
      '',
      'tax/',
    ]) {
      test('refused: a tool id "$bad" cannot name a file', () {
        expect(
          () => LumeExportFile.csv(
            tool: bad,
            day: day,
            rows: <List<Object?>>[
              <Object?>['a'],
            ],
          ),
          throwsArgumentError,
        );
      });
    }

    test('refused: no rows, or ragged rows', () {
      expect(
        () =>
            LumeExportFile.csv(tool: 'tax', day: day, rows: <List<Object?>>[]),
        throwsArgumentError,
      );
      expect(
        () => LumeExportFile.csv(
          tool: 'tax',
          day: day,
          rows: <List<Object?>>[
            <Object?>['a', 'b'],
            <Object?>['c'],
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('the recording adapters never reach the platform', () {
    test('sharer, saver and exporter record and answer as told', () async {
      final Uint8List png = Uint8List.fromList(<int>[1, 2, 3]);
      final LumeRecordingSharer sharer = LumeRecordingSharer(
        outcome: LumeShareOutcome.dismissed,
      );
      expect(
        await sharer.shareImage(png, fileName: 'lume-quote.png', caption: 'c'),
        LumeShareOutcome.dismissed,
      );
      expect(sharer.shared.single.fileName, 'lume-quote.png');

      final LumeRecordingImageSaver saver = LumeRecordingImageSaver();
      expect(
        await saver.saveImage(png, fileName: 'lume-quote.png'),
        LumeSaveOutcome.saved,
      );
      expect(saver.saved, hasLength(1));

      final LumeRecordingExporter exporter = LumeRecordingExporter(
        outcome: LumeExportOutcome.failed,
      );
      final LumeExportFile file = LumeExportFile.csv(
        tool: 'tax',
        day: DateTime(2026, 9, 7),
        rows: <List<Object?>>[
          <Object?>['a'],
        ],
      );
      expect(await exporter.export(file), LumeExportOutcome.failed);
      expect(exporter.exported.single.fileName, 'lume-tax-2026-09-07.csv');
    });

    test(
      'the production saver says it cannot save, and never pretends',
      () async {
        expect(
          await const LumeUnavailableImageSaver().saveImage(
            Uint8List(0),
            fileName: 'lume-quote.png',
          ),
          LumeSaveOutcome.unavailable,
        );
      },
    );
  });

  group('the platform adapters report what the sheet said', () {
    late List<ShareParams> opened;

    LumeShareSheet sheet(ShareResultStatus status, {Object? throws}) =>
        (ShareParams p) async {
          opened.add(p);
          if (throws != null) throw throws;
          return status;
        };

    setUp(() => opened = <ShareParams>[]);

    final Uint8List png = Uint8List.fromList(<int>[137, 80, 78, 71]);

    for (final (ShareResultStatus status, LumeShareOutcome outcome)
        in <(ShareResultStatus, LumeShareOutcome)>[
          (ShareResultStatus.success, LumeShareOutcome.shared),
          (ShareResultStatus.dismissed, LumeShareOutcome.dismissed),
          (ShareResultStatus.unavailable, LumeShareOutcome.unavailable),
        ]) {
      test('share: $status is $outcome', () async {
        expect(
          await LumePlatformSharer(sheet: sheet(status)).shareImage(
            png,
            fileName: 'lume-reminder.png',
            caption: 'Words — Source',
          ),
          outcome,
        );
        final ShareParams p = opened.single;
        expect(p.files!.single.mimeType, 'image/png');
        expect(p.fileNameOverrides, <String>['lume-reminder.png']);
        expect(p.text, 'Words — Source');
      });
    }

    test(
      'share: a platform error is a failure, no plugin is unavailable',
      () async {
        expect(
          await LumePlatformSharer(
            sheet: sheet(
              ShareResultStatus.success,
              throws: PlatformException(code: 'x'),
            ),
          ).shareImage(png, fileName: 'f.png', caption: 'c'),
          LumeShareOutcome.failed,
        );
        expect(
          await LumePlatformSharer(
            sheet: sheet(
              ShareResultStatus.success,
              throws: MissingPluginException(),
            ),
          ).shareImage(png, fileName: 'f.png', caption: 'c'),
          LumeShareOutcome.unavailable,
        );
      },
    );

    for (final (ShareResultStatus status, LumeExportOutcome outcome)
        in <(ShareResultStatus, LumeExportOutcome)>[
          (ShareResultStatus.success, LumeExportOutcome.saved),
          (ShareResultStatus.dismissed, LumeExportOutcome.cancelled),
          (ShareResultStatus.unavailable, LumeExportOutcome.unavailable),
        ]) {
      test('export: $status is $outcome', () async {
        final LumeExportFile file = LumeExportFile.csv(
          tool: 'tax',
          day: DateTime(2026, 9, 7),
          rows: <List<Object?>>[
            <Object?>['a'],
          ],
        );
        expect(
          await LumePlatformExporter(sheet: sheet(status)).export(file),
          outcome,
        );
        final ShareParams p = opened.single;
        expect(p.files!.single.mimeType, 'text/csv;charset=utf-8');
        expect(p.fileNameOverrides, <String>['lume-tax-2026-09-07.csv']);
        expect(p.text, isNull, reason: 'a file travels without a caption');
      });
    }
  });
}
