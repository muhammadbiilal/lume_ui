/// What the catalogue and the capability layer say about `wastatus`,
/// asserted independently of the widget.
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

  group('LumeDataCapability', () {
    test('a note and an empty list: nothing sampled, nothing to claim', () {
      // The screen draws no figure of any kind, so it sits with the other
      // input-only tools and the source line does not call it sample data.
      final LumeDataCapability cap = LumeDataCapability.fixture('wastatus');
      expect(LumeDataCapability.inputOnly, contains('wastatus'));
      expect(cap.isSample, isFalse);
      expect(cap.isDurable, isFalse);
      expect(cap.isLive, isFalse);
    });
  });
}
