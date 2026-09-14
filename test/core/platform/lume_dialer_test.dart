/// The dialer contract (D6): the number dialled is the number shown, nothing
/// but a phone number reaches the dialer, and every outcome is reported.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_dialer.dart';
import 'package:lume/core/platform/lume_dialer_platform.dart';
import 'package:lume/features/emergency/data/emergency_directory.dart';

void main() {
  group('a number is what is shown, and nothing else', () {
    for (final (String shown, String dialable) in <(String, String)>[
      ('1122', '1122'),
      ('15', '15'),
      ('0800 111 999', '0800111999'),
      ('1-800-222-1222', '18002221222'),
      ('+44 20 7946 0958', '+442079460958'),
      ('  911 ', '911'),
    ]) {
      test('"$shown" dials $dialable', () {
        final LumeDialNumber n = LumeDialNumber.parse(shown)!;
        expect(n.dialable, dialable);
        expect(n.display, shown.trim());
        expect(n.uri.toString(), 'tel:$dialable');
      });
    }

    for (final String refused in <String>[
      '',
      '1',
      'tel:15',
      '*123#',
      '15;112',
      '++15',
      '12a',
      '15,1',
      '+',
      '- 15',
      '1234567890123456',
      '١١٢٢', // Eastern Arabic digits are shown only through LumeNumerals.
    ]) {
      test('"$refused" is refused', () {
        expect(LumeDialNumber.parse(refused), isNull);
      });
    }
  });

  test('every number in the directory can be dialled as shown', () {
    for (final String country in <String>[
      ...LumeEmergencyDirectory.countries,
      'JP',
    ]) {
      for (final LumeEmergencyService s in LumeEmergencyDirectory.forCountry(
        country,
      )) {
        expect(
          LumeDialNumber.parse(s.number),
          isNotNull,
          reason: '$country ${s.name} ${s.number}',
        );
      }
    }
  });

  test('a country without a list falls back to the international numbers', () {
    expect(
      LumeEmergencyDirectory.forCountry('JP'),
      same(LumeEmergencyDirectory.fallback),
    );
    expect(
      LumeEmergencyDirectory.forCountry('pk').first.number,
      '1122',
      reason: 'the code is not case-sensitive',
    );
  });

  group('the recording dialer never reaches the platform', () {
    test('records what it was given, and answers as told', () async {
      final LumeRecordingDialer d = LumeRecordingDialer();
      expect(await d.dial('0800 111 999'), LumeDialOutcome.opened);
      d.outcome = LumeDialOutcome.failed;
      expect(await d.dial('15'), LumeDialOutcome.failed);
      expect(d.dialled.map((LumeDialNumber n) => n.dialable), <String>[
        '0800111999',
        '15',
      ]);
    });

    test('a malformed number is refused before anything is recorded', () async {
      final LumeRecordingDialer d = LumeRecordingDialer();
      expect(await d.dial('*#06#'), LumeDialOutcome.malformed);
      expect(d.dialled, isEmpty);
      expect(d.requested, <String>['*#06#']);
    });
  });

  group('the platform adapter reports what the platform said', () {
    late List<Uri> asked;
    late List<Uri> opened;

    LumePlatformDialer adapter({
      bool can = true,
      bool open = true,
      Object? throws,
    }) {
      asked = <Uri>[];
      opened = <Uri>[];
      return LumePlatformDialer(
        canOpen: (Uri u) async {
          asked.add(u);
          if (throws != null) throw throws;
          return can;
        },
        open: (Uri u) async {
          opened.add(u);
          return open;
        },
      );
    }

    test('opened — with the tel: form of the number shown', () async {
      expect(await adapter().dial('0800 111 999'), LumeDialOutcome.opened);
      expect(opened, <Uri>[Uri.parse('tel:0800111999')]);
    });

    test('unavailable — nothing on the device can dial', () async {
      expect(
        await adapter(can: false).dial('911'),
        LumeDialOutcome.unavailable,
      );
      expect(opened, isEmpty);
    });

    test('failed — the platform declined', () async {
      expect(await adapter(open: false).dial('911'), LumeDialOutcome.failed);
    });

    test('failed — the platform threw', () async {
      expect(
        await adapter(throws: PlatformException(code: 'x')).dial('911'),
        LumeDialOutcome.failed,
      );
    });

    test('unavailable — no plugin on this platform', () async {
      expect(
        await adapter(throws: MissingPluginException()).dial('911'),
        LumeDialOutcome.unavailable,
      );
    });

    test('malformed — the platform is never asked', () async {
      expect(await adapter().dial('tel:911'), LumeDialOutcome.malformed);
      expect(asked, isEmpty);
    });
  });
}
