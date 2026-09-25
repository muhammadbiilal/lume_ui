/// What the catalogue and the capability layer already say about `wastatus`
/// — asserted here, independently of the widget, so this suite still runs
/// green while `wastatus_tool.dart` itself is blocked on ARB keys that are
/// added in a later, centralised pass (see the tool's own doc comment).
///
/// This file deliberately does not import `wastatus_tool.dart`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';

LumeFeature get _wastatus =>
    kLumeFeatures.firstWhere((LumeFeature f) => f.id == 'wastatus');

void main() {
  group('the catalogue entry (unchanged by this wave)', () {
    test('is Android-only, a library, kept on device', () {
      final LumeFeature f = _wastatus;
      expect(f.id, 'wastatus');
      expect(f.androidOnly, isTrue);
      expect(f.archetype, LumeToolArchetype.library);
      expect(f.freshness, LumeFreshnessKind.local);
      expect(f.fallbackSource, 'On device');
    });

    test('declares no sharing, export, favourites or search support', () {
      // Nothing this screen shows is the reader's own, or a feed, or a
      // record they added, so none of these controls would have anything
      // to act on.
      expect(_wastatus.supports, <LumeToolSupport>{
        LumeToolSupport.history,
        LumeToolSupport.offline,
      });
    });

    test('points at Media Saver and the document scanner, not at itself', () {
      expect(_wastatus.related, <String>{'mediasaver', 'docscan'});
    });
  });

  group('LumeDataCapability — why the tool screen has to be bare', () {
    test('the default fixture classification calls this sample data, which is '
        'wrong for a screen with no figures at all', () {
      // `wastatus` is not in `inputOnly`, `computed` or `readerRecords`, so
      // `LumeDataCapability.fixture` falls through to `isSample: true` —
      // correct for a tool that shows invented records it does not have a
      // real adapter for, wrong for a tool that shows no records, feed or
      // figure of any kind. `wastatus_tool.dart` reads `LumeToolScreen`
      // with `bare: true` for exactly this reason: nothing here derives a
      // source-bar claim from this capability, so the wrong claim can
      // never reach the screen.
      final LumeDataCapability cap = LumeDataCapability.fixture('wastatus');
      expect(cap.isSample, isTrue);
      expect(cap.isDurable, isFalse);
      expect(cap.isLive, isFalse);
      expect(cap.computedHere, isFalse);
    });
  });
}
