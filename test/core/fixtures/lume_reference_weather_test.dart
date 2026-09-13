/// The weather port, against the reference run in Node.
///
/// `weather_truth.mjs` imports `assets/js/data/catalogue.js` and
/// `assets/js/data/tool-data.js` as the modules they are and asks the
/// functions the screens ask — `LUME.weatherFor(country, '')` and
/// `LUME_DATA.daily(base.temp, country.charCodeAt(0) * 17)`. Every row below
/// is what that printed. A difference here is the port being wrong, not the
/// reference.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_weather.dart';
import 'package:lume/core/icons/lume_icons.dart';

typedef _Day = (int hi, int lo, int rain, String condition, String icon);
typedef _Truth = ({
  int temp,
  int feels,
  int rain,
  int wind,
  String icon,
  _Day today,
  _Day tomorrow,
});

const String _s = LumeIcons.sun;
const String _c = LumeIcons.cloudSun;
const String _mc = 'mostlyClear';
const String _cb = 'cloudBuilding';

const Map<String, _Truth> _truth = <String, _Truth>{
  'PK': (
    temp: 34,
    feels: 38,
    rain: 8,
    wind: 14,
    icon: _s,
    today: (34, 23, 64, _mc, _c),
    tomorrow: (36, 27, 1, _cb, _s),
  ),
  'IN': (
    temp: 33,
    feels: 37,
    rain: 25,
    wind: 12,
    icon: _s,
    today: (33, 24, 70, _cb, _s),
    tomorrow: (34, 23, 16, _mc, _c),
  ),
  'GB': (
    temp: 21,
    feels: 19,
    rain: 12,
    wind: 8,
    icon: _c,
    today: (21, 10, 21, _cb, _c),
    tomorrow: (25, 17, 10, _cb, _c),
  ),
  'US': (
    temp: 24,
    feels: 24,
    rain: 20,
    wind: 10,
    icon: _c,
    today: (24, 12, 10, _mc, _c),
    tomorrow: (29, 20, 50, _mc, _s),
  ),
  'CA': (
    temp: 17,
    feels: 15,
    rain: 35,
    wind: 13,
    icon: _c,
    today: (17, 6, 65, _mc, _c),
    tomorrow: (22, 10, 69, _mc, _s),
  ),
  'AE': (
    temp: 39,
    feels: 44,
    rain: 0,
    wind: 11,
    icon: _s,
    today: (39, 30, 16, _mc, _s),
    tomorrow: (41, 32, 63, _mc, _s),
  ),
  'SA': (
    temp: 40,
    feels: 42,
    rain: 0,
    wind: 9,
    icon: _s,
    today: (40, 30, 31, _mc, _s),
    tomorrow: (42, 31, 44, _mc, _s),
  ),
  'AU': (
    temp: 26,
    feels: 26,
    rain: 10,
    wind: 18,
    icon: _s,
    today: (26, 17, 16, _mc, _s),
    tomorrow: (28, 19, 63, _mc, _s),
  ),
  'DE': (
    temp: 18,
    feels: 17,
    rain: 40,
    wind: 11,
    icon: _c,
    today: (18, 6, 54, _cb, _s),
    tomorrow: (21, 10, 36, _mc, _s),
  ),
  'FR': (
    temp: 21,
    feels: 20,
    rain: 15,
    wind: 9,
    icon: _c,
    today: (21, 11, 32, _cb, _s),
    tomorrow: (21, 12, 42, _cb, _s),
  ),
  'TR': (
    temp: 27,
    feels: 27,
    rain: 5,
    wind: 12,
    icon: _s,
    today: (27, 16, 21, _mc, _s),
    tomorrow: (28, 18, 12, _mc, _c),
  ),
  'ID': (
    temp: 31,
    feels: 35,
    rain: 60,
    wind: 7,
    icon: _c,
    today: (31, 22, 70, _cb, _s),
    tomorrow: (32, 21, 16, _mc, _c),
  ),
  'MY': (
    temp: 32,
    feels: 36,
    rain: 65,
    wind: 6,
    icon: _c,
    today: (32, 24, 26, _mc, _s),
    tomorrow: (33, 21, 27, _mc, _c),
  ),
  'BD': (
    temp: 32,
    feels: 37,
    rain: 45,
    wind: 10,
    icon: _c,
    today: (32, 22, 5, _mc, _c),
    tomorrow: (33, 25, 31, _mc, _c),
  ),
  'EG': (
    temp: 35,
    feels: 36,
    rain: 0,
    wind: 14,
    icon: _s,
    today: (35, 26, 43, _cb, _s),
    tomorrow: (37, 27, 4, _cb, _s),
  ),
  'NG': (
    temp: 30,
    feels: 34,
    rain: 55,
    wind: 9,
    icon: _c,
    today: (30, 21, 16, _mc, _s),
    tomorrow: (34, 23, 65, _cb, _s),
  ),
  'ZA': (
    temp: 22,
    feels: 21,
    rain: 10,
    wind: 16,
    icon: _s,
    today: (22, 13, 26, _cb, _c),
    tomorrow: (25, 16, 29, _cb, _s),
  ),
  'SG': (
    temp: 31,
    feels: 36,
    rain: 60,
    wind: 8,
    icon: _c,
    today: (31, 21, 31, _mc, _s),
    tomorrow: (33, 22, 44, _mc, _s),
  ),
  'JP': (
    temp: 26,
    feels: 27,
    rain: 20,
    wind: 10,
    icon: _c,
    today: (26, 16, 59, _cb, _s),
    tomorrow: (31, 21, 53, _mc, _s),
  ),
  'CN': (
    temp: 25,
    feels: 26,
    rain: 25,
    wind: 11,
    icon: _c,
    today: (25, 14, 65, _mc, _c),
    tomorrow: (30, 18, 69, _mc, _s),
  ),
};

void main() {
  void expectDay(LumeReferenceDay got, _Day want, String reason) {
    expect(got.highC, want.$1, reason: '$reason high');
    expect(got.lowC, want.$2, reason: '$reason low');
    expect(got.rainPercent, want.$3, reason: '$reason rain');
    expect(got.conditionKey, want.$4, reason: '$reason condition');
    expect(got.icon, want.$5, reason: '$reason icon');
  }

  test('covers exactly the twenty markets WEATHER_BY_COUNTRY writes down', () {
    expect(kReferenceWeatherMarkets, _truth.keys.toList());
  });

  for (final MapEntry<String, _Truth> e in _truth.entries) {
    test('${e.key} reads what the reference computes', () {
      final LumeReferenceClimate? c = lumeReferenceClimate(e.key);
      expect(c, isNotNull);
      expect(c!.provenance, LumeWeatherProvenance.reference);
      expect(c.temperatureC, e.value.temp);
      expect(c.feelsLikeC, e.value.feels);
      expect(c.rainPercent, e.value.rain);
      expect(c.windKph, e.value.wind);
      expect(c.icon, e.value.icon);
      expect(c.days, hasLength(5));
      expectDay(c.today, e.value.today, '${e.key} today');
      expectDay(c.tomorrow, e.value.tomorrow, '${e.key} tomorrow');
    });
  }

  test('the live row takes the phrase’s first clause, Explore the whole', () {
    final LumeReferenceClimate pk = lumeReferenceClimate('PK')!;
    expect(pk.conditionKey, 'hazySunHumid');
    expect(pk.shortConditionKey, 'hazySun');
    final LumeReferenceClimate ae = lumeReferenceClimate('AE')!;
    expect(ae.conditionKey, 'clearVeryWarm');
    expect(ae.shortConditionKey, 'clear');
  });

  test('a market outside the twenty, with no zone, is unavailable', () {
    expect(lumeReferenceClimate('KE'), isNull);
    expect(lumeReferenceClimate('BR'), isNull);
    expect(lumeReferenceClimate(''), isNull);
  });

  test('with a zone, it is derived from WEATHER_BY_ZONE', () {
    final LumeReferenceClimate? ke = lumeReferenceClimate(
      'KE',
      timeZone: 'Africa/Nairobi',
    );
    expect(ke!.provenance, LumeWeatherProvenance.derived);
    expect(ke.temperatureC, 31);
    expect(ke.conditionKey, 'warmAndDry');
    // An unknown prefix falls back to Europe, as `weatherFor` does.
    final LumeReferenceClimate? odd = lumeReferenceClimate(
      'XX',
      timeZone: 'Antarctica/Troll',
    );
    expect(odd!.temperatureC, 18);
    expect(odd.conditionKey, 'changeable');
  });

  test('a country’s own entry wins over its zone', () {
    expect(
      lumeReferenceClimate('PK', timeZone: 'Europe/London')!.provenance,
      LumeWeatherProvenance.reference,
    );
  });
}
