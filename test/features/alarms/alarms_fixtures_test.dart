/// `LumeAlarmBoard.next` — the reference's `list.filter(a => a.on)[0]`, over
/// its own fixture, and the one thing worth a pure unit test here.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/alarms/data/alarms_fixtures.dart';

void main() {
  group('LumeAlarmBoard', () {
    test('the fixture is the reference’s own three alarms, in its own '
        'order', () {
      expect(LumeAlarmBoard.alarms.map((LumeAlarm a) => a.id), <String>[
        'a1',
        'a2',
        'a3',
      ]);
      expect(LumeAlarmBoard.alarms.map((LumeAlarm a) => a.on), <bool>[
        true,
        false,
        true,
      ]);
    });

    test('next is the first armed alarm — Work, not Wind down', () {
      final LumeAlarm? next = LumeAlarmBoard.next(LumeAlarmBoard.alarms);
      expect(next?.id, 'a1');
      expect(next?.label, LumeAlarmLabel.work);
    });

    test('next is null when nothing is armed', () {
      final List<LumeAlarm> allOff = LumeAlarmBoard.alarms
          .map(
            (LumeAlarm a) => LumeAlarm(
              id: a.id,
              hour: a.hour,
              minute: a.minute,
              label: a.label,
              repeat: a.repeat,
              on: false,
            ),
          )
          .toList();
      expect(LumeAlarmBoard.next(allOff), isNull);
    });
  });
}
