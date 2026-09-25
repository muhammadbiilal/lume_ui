/// [LumePassportSpec] — the reference's own binary country rule
/// (`passportSpecs()`, `tools/context.js`), and the pixel math this build
/// adds on top of it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/passport/domain/passport_spec.dart';

void main() {
  group('forCountry — only the United States is asked apart', () {
    test('US gets the 2 × 2 in spec', () {
      final LumePassportSpec spec = LumePassportSpec.forCountry('US');
      expect(spec, LumePassportSpec.us);
      expect(spec.sizeLabel, '2 × 2 in');
      expect(spec.headHeightLabel, '1 – 1⅜ in');
    });

    test('is not case sensitive', () {
      expect(LumePassportSpec.forCountry('us'), LumePassportSpec.us);
    });

    for (final String country in <String>['PK', 'GB', 'SA', 'IN', 'CA', 'AU']) {
      test('$country gets the reference\'s 35 × 45 mm default', () {
        final LumePassportSpec spec = LumePassportSpec.forCountry(country);
        expect(spec, LumePassportSpec.intl);
        expect(spec.sizeLabel, '35 × 45 mm');
        expect(spec.headHeightLabel, '32 – 36 mm');
      });
    }
  });

  group('pixel canvas — real conversions at the reference\'s own 600 dpi', () {
    test('2 × 2 in is exactly 1200 × 1200 px', () {
      expect(LumePassportSpec.us.widthPx, 1200);
      expect(LumePassportSpec.us.heightPx, 1200);
    });

    test('35 × 45 mm rounds to 827 × 1063 px, the figure quoted for this '
        'document size at 600 dpi', () {
      expect(LumePassportSpec.intl.widthPx, 827);
      expect(LumePassportSpec.intl.heightPx, 1063);
    });
  });

  test('two specs with the same id are equal', () {
    expect(LumePassportSpec.forCountry('PK'), LumePassportSpec.forCountry('DE'));
    expect(
      LumePassportSpec.forCountry('PK').hashCode,
      LumePassportSpec.forCountry('DE').hashCode,
    );
  });
}
