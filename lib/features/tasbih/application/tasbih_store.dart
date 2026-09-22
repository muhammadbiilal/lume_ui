/// Where the count lives, and how long.
///
/// [LumeToolSession] — `context.js`'s module-level `STATE`, in memory for the
/// life of the app and written nowhere. Leaving the tool and coming back
/// finds the count where it was; closing Lume does not. The screen says so
/// (`l.tasbihNotKept`) rather than letting a reader assume a tally is being
/// kept for them.
library;

import '../../tools/application/tool_session.dart';
import '../domain/tasbih_count.dart';
import '../domain/tasbih_phrase.dart';

class LumeTasbihStore {
  const LumeTasbihStore(this._session);

  final LumeToolSession _session;

  /// The catalogue id, which is also the session's key for this tool.
  static const String tool = 'tasbih';

  static const String phraseKey = 'phrase';
  static const String countKey = 'count';
  static const String roundsKey = 'rounds';

  int _read(String key) => int.tryParse(_session.read(tool, key) ?? '') ?? 0;

  /// What the session holds, made safe to draw.
  LumeTasbihCount read() => LumeTasbihCount.restored(
    phrase:
        int.tryParse(_session.read(tool, phraseKey) ?? '') ??
        LumeTasbihPhrases.first,
    count: _read(countKey),
    rounds: _read(roundsKey),
  );

  void write(LumeTasbihCount value) {
    _session
      ..write(tool, phraseKey, '${value.phrase}')
      ..write(tool, countKey, '${value.count}')
      ..write(tool, roundsKey, '${value.rounds}');
  }
}
