/// The one address this tool ever opens: a real Google Maps search, never a
/// fixture of invented mosques.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_link_opener.dart';
import 'package:lume/features/mosques/domain/mosques_search.dart';

void main() {
  group('LumeMosquesSearch.mapsUri', () {
    test('is a real, checkable Google Maps search address', () {
      final Uri uri = LumeMosquesSearch.mapsUri('Islamabad, Pakistan');
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['query'], 'mosques near Islamabad, Pakistan');
    });

    test('carries the place through untouched, whatever script it is in', () {
      final Uri uri = LumeMosquesSearch.mapsUri('İstanbul, Türkiye');
      expect(uri.queryParameters['query'], 'mosques near İstanbul, Türkiye');
    });

    test('encodes what a URL cannot carry raw (a space, a comma)', () {
      final Uri uri = LumeMosquesSearch.mapsUri('New York, United States');
      expect(uri.toString(), contains('mosques+near+New+York'));
      // Round-trips back to the exact text handed in — nothing lost or
      // mangled by the encoding.
      expect(uri.queryParameters['query'], 'mosques near New York, United States');
    });

    test('passes the same outbound allowlist every other checked address '
        'in Lume does — nothing here needs a special case', () {
      final Uri uri = LumeMosquesSearch.mapsUri('London, United Kingdom');
      expect(LumeLinkOpener.allows(uri), isTrue);
    });

    test('never carries the reader\'s own account details or a userinfo '
        'section, so the allowlist has nothing to reject', () {
      final Uri uri = LumeMosquesSearch.mapsUri('Dubai, United Arab Emirates');
      expect(uri.userInfo, isEmpty);
    });
  });
}
