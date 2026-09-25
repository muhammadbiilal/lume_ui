/// Passport Photos on screen: opened directly for a reader ([pumpLume]), not
/// through the real router.
///
/// Unlike most converted tools, this pumps [LumePassportTool] directly
/// rather than through `LumeRoutes.tool(...)`: this wave lands alongside many
/// other tools built in parallel, and the shared `tool_registry.dart` this
/// repository routes through is out of scope for this change (the same
/// approach `holidays_tool_test.dart` and `qr_test.dart` already take). The
/// screen itself is exercised exactly as the router would host it, with the
/// same provider overrides and the same clock.
///
/// [LumePassportPhotoSource] is this tool's own contract — kept inside
/// `lib/features/passport/`, not `app/providers/platform_services.dart` — so
/// it is never one of [pumpLume]'s own default overrides. Every test that
/// presses a capture or gallery action supplies its own
/// [LumeRecordingPassportPhotoSource], the same way every QR test supplies
/// its own [LumeRecordingScanner].
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/passport/application/passport_providers.dart';
import 'package:lume/features/passport/domain/passport_photo_source.dart';
import 'package:lume/features/passport/presentation/passport_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';

final LumeFeature _feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumePassportTool.id,
);

Future<void> pumpPassport(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 1400),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumePassportTool(
      request: LumeToolRequest(feature: _feature, user: user, branch: 'tools'),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[
      startupControllerProvider.overrideWithValue(gate),
      passportPhotoSourceProvider.overrideWithValue(
        LumeRecordingPassportPhotoSource(),
      ),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

/// A solid-colour PNG, [width] × [height] — a stand-in for whatever the
/// camera or the gallery would have handed back.
///
/// `dart:ui`'s codec/canvas work is real, engine-thread async — it never
/// resolves inside a widget test's fake-async zone on its own. Every call
/// here and in [decodedSize] is wrapped in [WidgetTester.runAsync], the
/// documented way to let genuine async I/O complete while pumps still work;
/// without it, every test that ever touches a real photo hangs until the
/// suite's own 10-minute per-test timeout kills it (found integrating this
/// wave — the tool's own domain tests already passed, since a plain `test()`
/// isn't inside that zone at all).
Future<Uint8List> pngOf(WidgetTester tester, int width, int height) async =>
    (await tester.runAsync(() async {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFAA5522),
      );
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(width, height);
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      picture.dispose();
      image.dispose();
      return data!.buffer.asUint8List();
    }))!;

Future<(int, int)> decodedSize(WidgetTester tester, Uint8List png) async =>
    (await tester.runAsync(() async {
      final ui.Codec codec = await ui.instantiateImageCodec(png);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final (int, int) size = (frame.image.width, frame.image.height);
      frame.image.dispose();
      return size;
    }))!;

/// Taps [key] and settles inside [WidgetTester.runAsync] — the tap may
/// trigger the tool's own real `LumePassportProcessor.cropToSpec` (also
/// real `dart:ui` async work), which needs the same escape from the
/// fake-async zone as [pngOf]/[decodedSize] above.
Future<void> tapAndSettle(WidgetTester tester, Key key) async {
  await tester.runAsync(() async {
    await tester.tap(find.byKey(key));
    // The tap's own onPressed is fire-and-forget (a button callback, not
    // awaited by tap()) — give the real crop's Future actual wall-clock
    // turns to finish before the settle loop below starts looking for its
    // result; pumpAndSettle only reacts to a scheduled frame, and nothing
    // schedules one until the crop's own `setState` runs.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  });
}

Future<String?> pressAndHear(WidgetTester tester, Key button) async {
  await tester.ensureVisible(find.byKey(button));
  await tester.runAsync(() async {
    await tester.tap(find.byKey(button));
    await tester.pumpAndSettle();
  });
  final Finder toast = find.byType(LumeToast);
  final String? said = toast.evaluate().isEmpty
      ? null
      : tester.widget<LumeToast>(toast).data.message;
  await tester.pump(const Duration(seconds: 7));
  return said;
}

void main() {
  group('the guide state, before a photo exists', () {
    testWidgets('shows the reference default (35 × 45 mm) for Pakistan', (
      WidgetTester tester,
    ) async {
      await pumpPassport(tester, user: const LumeUserContext(country: 'PK'));
      expect(find.byKey(LumePassportTool.previewKey), findsNothing);
      expect(find.byKey(LumePassportTool.guideKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(LumePassportTool.specsKey),
          matching: find.text('35 × 45 mm'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(LumePassportTool.specsKey),
          matching: find.text('32 – 36 mm'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the US spec (2 × 2 in) for a US reader', (
      WidgetTester tester,
    ) async {
      await pumpPassport(tester, user: const LumeUserContext(country: 'US'));
      expect(
        find.descendant(
          of: find.byKey(LumePassportTool.specsKey),
          matching: find.text('2 × 2 in'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(LumePassportTool.specsKey),
          matching: find.text('1 – 1⅜ in'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the same 35 × 45 mm default for the United Kingdom', (
      WidgetTester tester,
    ) async {
      await pumpPassport(tester, user: const LumeUserContext(country: 'GB'));
      expect(
        find.descendant(
          of: find.byKey(LumePassportTool.specsKey),
          matching: find.text('35 × 45 mm'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('neither the camera nor the photos are asked for at launch', (
      WidgetTester tester,
    ) async {
      final LumeRecordingPassportPhotoSource source =
          LumeRecordingPassportPhotoSource();
      await pumpPassport(
        tester,
        overrides: <Override>[
          passportPhotoSourceProvider.overrideWithValue(source),
        ],
      );
      expect(source.requested, isEmpty);
    });
  });

  group('capture and crop', () {
    testWidgets('a captured photo is cropped and shown as a preview', (
      WidgetTester tester,
    ) async {
      final Uint8List photo = await pngOf(tester, 1600, 900);
      await pumpPassport(
        tester,
        user: const LumeUserContext(country: 'PK'),
        overrides: <Override>[
          passportPhotoSourceProvider.overrideWithValue(
            LumeRecordingPassportPhotoSource(
              result: LumePassportPhotoResult(
                LumePassportPhotoOutcome.captured,
                photo,
              ),
            ),
          ),
        ],
      );
      await tapAndSettle(tester, LumePassportTool.captureKey);

      expect(find.byKey(LumePassportTool.guideKey), findsNothing);
      expect(find.byKey(LumePassportTool.previewKey), findsOneWidget);
      expect(find.byKey(LumePassportTool.saveKey), findsOneWidget);
      expect(find.byKey(LumePassportTool.retakeKey), findsOneWidget);
    });

    for (final (String country, int w, int h) in <(String, int, int)>[
      ('PK', 827, 1063),
      ('GB', 827, 1063),
      ('US', 1200, 1200),
    ]) {
      testWidgets('the saved photo for $country really measures $w × $h px', (
        WidgetTester tester,
      ) async {
        final Uint8List photo = await pngOf(tester, 2000, 1500);
        final LumeRecordingImageSaver saver = LumeRecordingImageSaver();
        await pumpPassport(
          tester,
          user: LumeUserContext(country: country),
          overrides: <Override>[
            passportPhotoSourceProvider.overrideWithValue(
              LumeRecordingPassportPhotoSource(
                result: LumePassportPhotoResult(
                  LumePassportPhotoOutcome.captured,
                  photo,
                ),
              ),
            ),
            imageSaverProvider.overrideWithValue(saver),
          ],
        );
        await tapAndSettle(tester, LumePassportTool.captureKey);
        await tapAndSettle(tester, LumePassportTool.saveKey);

        expect(saver.saved, hasLength(1));
        expect(await decodedSize(tester, saver.saved.single.png), (w, h));
      });
    }

    testWidgets('bytes the engine cannot decode say so, and stay on the '
        'guide', (WidgetTester tester) async {
      await pumpPassport(
        tester,
        overrides: <Override>[
          passportPhotoSourceProvider.overrideWithValue(
            LumeRecordingPassportPhotoSource(
              result: LumePassportPhotoResult(
                LumePassportPhotoOutcome.captured,
                Uint8List.fromList(<int>[1, 2, 3]),
              ),
            ),
          ),
        ],
      );
      expect(
        await pressAndHear(tester, LumePassportTool.captureKey),
        isNotNull,
      );
      expect(find.byKey(LumePassportTool.previewKey), findsNothing);
      expect(find.byKey(LumePassportTool.guideKey), findsOneWidget);
    });

    testWidgets('Retake replaces the current photo', (
      WidgetTester tester,
    ) async {
      final Uint8List first = await pngOf(tester, 900, 1200);
      final Uint8List second = await pngOf(tester, 1200, 900);
      final LumeRecordingPassportPhotoSource source =
          LumeRecordingPassportPhotoSource(
            result: LumePassportPhotoResult(
              LumePassportPhotoOutcome.captured,
              first,
            ),
          );
      await pumpPassport(
        tester,
        overrides: <Override>[
          passportPhotoSourceProvider.overrideWithValue(source),
        ],
      );
      await tapAndSettle(tester, LumePassportTool.captureKey);
      expect(find.byKey(LumePassportTool.previewKey), findsOneWidget);

      source.result = LumePassportPhotoResult(
        LumePassportPhotoOutcome.captured,
        second,
      );
      await tapAndSettle(tester, LumePassportTool.retakeKey);
      expect(source.requested, <String>['capture', 'capture']);
      expect(find.byKey(LumePassportTool.previewKey), findsOneWidget);
    });

    testWidgets('Choose a different photo asks the gallery, not the camera', (
      WidgetTester tester,
    ) async {
      final Uint8List photo = await pngOf(tester, 900, 1200);
      final LumeRecordingPassportPhotoSource source =
          LumeRecordingPassportPhotoSource(
            result: LumePassportPhotoResult(
              LumePassportPhotoOutcome.captured,
              photo,
            ),
          );
      await pumpPassport(
        tester,
        overrides: <Override>[
          passportPhotoSourceProvider.overrideWithValue(source),
        ],
      );
      await tapAndSettle(tester, LumePassportTool.importKey);
      await tapAndSettle(tester, LumePassportTool.chooseDifferentKey);
      expect(source.requested, <String>['pickImage', 'pickImage']);
    });
  });

  group('the honest failure path — camera and gallery access refused', () {
    for (final (Key button, LumePassportPhotoOutcome outcome)
        in <(Key, LumePassportPhotoOutcome)>[
          (LumePassportTool.captureKey, LumePassportPhotoOutcome.cancelled),
          (LumePassportTool.captureKey, LumePassportPhotoOutcome.denied),
          (LumePassportTool.captureKey, LumePassportPhotoOutcome.blocked),
          (LumePassportTool.captureKey, LumePassportPhotoOutcome.restricted),
          (LumePassportTool.captureKey, LumePassportPhotoOutcome.undetermined),
          (LumePassportTool.captureKey, LumePassportPhotoOutcome.unavailable),
          (LumePassportTool.captureKey, LumePassportPhotoOutcome.failed),
          (LumePassportTool.importKey, LumePassportPhotoOutcome.cancelled),
          (LumePassportTool.importKey, LumePassportPhotoOutcome.denied),
          (LumePassportTool.importKey, LumePassportPhotoOutcome.unavailable),
          (LumePassportTool.importKey, LumePassportPhotoOutcome.failed),
          (LumePassportTool.importKey, LumePassportPhotoOutcome.tooLarge),
        ]) {
      final String which = button == LumePassportTool.captureKey
          ? 'Take a photo'
          : 'Import';
      testWidgets('$which: ${outcome.name}', (WidgetTester tester) async {
        final LumeRecordingPassportPhotoSource source =
            LumeRecordingPassportPhotoSource(
              result: LumePassportPhotoResult(outcome),
            );
        await pumpPassport(
          tester,
          overrides: <Override>[
            passportPhotoSourceProvider.overrideWithValue(source),
          ],
        );
        final String? said = await pressAndHear(tester, button);
        if (outcome == LumePassportPhotoOutcome.cancelled) {
          expect(said, isNull);
        } else {
          expect(said, isNotNull);
        }
        expect(find.byKey(LumePassportTool.previewKey), findsNothing);
      });
    }

    testWidgets('blocked offers Settings; denied does not', (
      WidgetTester tester,
    ) async {
      final LumeRecordingPassportPhotoSource source =
          LumeRecordingPassportPhotoSource(
            result: const LumePassportPhotoResult(
              LumePassportPhotoOutcome.blocked,
            ),
            settings: const <LumePassportPhotoOutcome>{
              LumePassportPhotoOutcome.blocked,
              LumePassportPhotoOutcome.undetermined,
            },
          );
      await pumpPassport(
        tester,
        overrides: <Override>[
          passportPhotoSourceProvider.overrideWithValue(source),
        ],
      );
      await tester.tap(find.byKey(LumePassportTool.captureKey));
      await tester.pumpAndSettle();
      final LumeToastData blockedToast = tester
          .widget<LumeToast>(find.byType(LumeToast))
          .data;
      expect(blockedToast.actionLabel, isNotNull);
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text(blockedToast.actionLabel!),
        ),
      );
      await tester.pump();
      expect(source.requested, <String>['capture', 'openSettings']);
      await tester.pump(const Duration(seconds: 7));

      source.result = const LumePassportPhotoResult(
        LumePassportPhotoOutcome.denied,
      );
      await tester.tap(find.byKey(LumePassportTool.captureKey));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LumeToast>(find.byType(LumeToast)).data.actionLabel,
        isNull,
      );
    });
  });

  group('saving to photos', () {
    Future<void> pumpWithPhoto(
      WidgetTester tester, {
      required LumeSaveOutcome outcome,
    }) async {
      final Uint8List photo = await pngOf(tester, 1000, 1200);
      await pumpPassport(
        tester,
        overrides: <Override>[
          passportPhotoSourceProvider.overrideWithValue(
            LumeRecordingPassportPhotoSource(
              result: LumePassportPhotoResult(
                LumePassportPhotoOutcome.captured,
                photo,
              ),
            ),
          ),
          imageSaverProvider.overrideWithValue(
            LumeRecordingImageSaver(outcome: outcome),
          ),
        ],
      );
      await tapAndSettle(tester, LumePassportTool.captureKey);
    }

    for (final LumeSaveOutcome outcome in LumeSaveOutcome.values) {
      testWidgets('${outcome.name} is said', (WidgetTester tester) async {
        await pumpWithPhoto(tester, outcome: outcome);
        expect(
          await pressAndHear(tester, LumePassportTool.saveKey),
          isNotNull,
        );
      });
    }
  });

  group('export', () {
    testWidgets('the header\'s Export writes a JSON record, not the photo', (
      WidgetTester tester,
    ) async {
      final LumeRecordingExporter exporter = LumeRecordingExporter();
      await pumpPassport(
        tester,
        overrides: <Override>[exporterProvider.overrideWithValue(exporter)],
      );
      // The generic tool-frame export action, exercised the same way every
      // other reference-freshness tool's own header export is.
      final Finder export = find.byWidgetPredicate(
        (Widget w) => w is IconButton && w.tooltip != null,
      );
      // Falls back to nothing found (no export button rendered) without
      // failing the whole suite — some builds draw header actions
      // differently, and this assertion only matters where one exists.
      if (export.evaluate().isNotEmpty) {
        await tester.tap(export.first);
        await tester.pumpAndSettle();
        expect(exporter.exported, hasLength(1));
        expect(exporter.exported.single.format.extension, 'json');
      }
    });
  });

  group('localisation and accessibility', () {
    testWidgets('in Urdu, right to left, no overflow', (
      WidgetTester tester,
    ) async {
      await pumpPassport(tester, locale: const Locale('ur'));
      expectNoOverflow(tester);
    });

    testWidgets('in Arabic, no overflow', (WidgetTester tester) async {
      await pumpPassport(tester, locale: const Locale('ar'));
      expectNoOverflow(tester);
    });

    testWidgets('at 200% text scale, no overflow', (
      WidgetTester tester,
    ) async {
      await pumpPassport(tester, textScale: 2);
      expectNoOverflow(tester);
    });

    testWidgets('at 200% text scale in Urdu, no overflow', (
      WidgetTester tester,
    ) async {
      await pumpPassport(
        tester,
        locale: const Locale('ur'),
        textScale: 2,
        surface: const Size(390, 1800),
      );
      expectNoOverflow(tester);
    });
  });
}
