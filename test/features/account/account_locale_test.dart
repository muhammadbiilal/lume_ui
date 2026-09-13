/// Every account route, in every language, at twice the type size.
///
/// A settings section is where localisation fails quietly. The strings are
/// short, so nothing wraps in English; they are rows, so nothing obviously
/// breaks; and a row that overflows by four points in Urdu at 200% looks, in
/// a screenshot, almost exactly like one that does not.
///
/// So this asserts the three things a screenshot cannot: that the page does
/// not overflow, that it is laid out in the direction the language reads, and
/// that no English string survived into a translated screen. All twenty-one
/// routes, every time — an archetype would miss exactly the one route nobody
/// thought about.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/presentation/account_host.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../helpers/load_fonts.dart';
import 'account_harness.dart';

/// The reference cell's width. Height is generous so a route lays out in one
/// pass: a row below the fold is still built, and an overflow below the fold
/// is still an overflow.
const Size kPhone = Size(390, 2400);

/// And the narrowest phone Lume draws for, where an over-long translation has
/// the least room to be wrong in.
const Size kNarrow = Size(359, 2400);

void main() {
  setUpAll(loadLumeFonts);

  const Map<String, TextDirection> languages = <String, TextDirection>{
    'en': TextDirection.ltr,
    'ur': TextDirection.rtl,
    'ar': TextDirection.rtl,
  };

  /// Pumps one route and hands back whatever it threw, if anything.
  Future<Object?> render(
    WidgetTester tester,
    LumeAccountRoute route, {
    required Locale locale,
    required double textScale,
    Size surface = kPhone,
    LumeFakeAccountRepository? account,
  }) async {
    final LumeStartupController gate = await bootedGate();
    await pumpAccountHost(
      tester,
      route: route,
      account: account,
      gate: gate,
      locale: locale,
      textScale: textScale,
      surface: surface,
    );
    return tester.takeException();
  }

  for (final MapEntry<String, TextDirection> lang in languages.entries) {
    group('in ${lang.key}', () {
      testWidgets('every route lays out', (WidgetTester tester) async {
        for (final LumeAccountRoute route in LumeAccountRoute.values) {
          expect(
            await render(
              tester,
              route,
              locale: Locale(lang.key),
              textScale: 1.0,
            ),
            isNull,
            reason: '${lang.key}/${route.segment}',
          );
        }
      });

      testWidgets('and at twice the type size', (WidgetTester tester) async {
        // §60: dynamic type is not optional, and a translated string at 200%
        // is the worst case a settings row ever sees.
        for (final LumeAccountRoute route in LumeAccountRoute.values) {
          expect(
            await render(
              tester,
              route,
              locale: Locale(lang.key),
              textScale: 2.0,
            ),
            isNull,
            reason: '${lang.key}/${route.segment} at 200%',
          );
        }
      });

      testWidgets('and on the narrowest phone Lume draws for', (
        WidgetTester tester,
      ) async {
        for (final LumeAccountRoute route in LumeAccountRoute.values) {
          expect(
            await render(
              tester,
              route,
              locale: Locale(lang.key),
              textScale: 1.0,
              surface: kNarrow,
            ),
            isNull,
            reason: '${lang.key}/${route.segment} at 359',
          );
        }
      });

      testWidgets('and the refusal a guest meets lays out too', (
        WidgetTester tester,
      ) async {
        // The seven protected routes have a second screen nobody captures by
        // default, and it carries the longest sentence in the section.
        for (final LumeAccountRoute route in LumeAccountRoute.values) {
          expect(
            await render(
              tester,
              route,
              locale: Locale(lang.key),
              textScale: 2.0,
              account: LumeFakeAccountRepository.guest(),
            ),
            isNull,
            reason: '${lang.key}/${route.segment} as a guest at 200%',
          );
        }
      });

      testWidgets('in the direction the language reads', (
        WidgetTester tester,
      ) async {
        for (final LumeAccountRoute route in LumeAccountRoute.values) {
          await render(tester, route, locale: Locale(lang.key), textScale: 1.0);
          expect(
            Directionality.of(tester.element(find.byType(LumeAccountHost))),
            lang.value,
            reason: '${lang.key}/${route.segment}',
          );
        }
      });
    });
  }

  group('nothing English survives a translated screen', () {
    /// Strings that are the same in every language on purpose.
    ///
    /// A currency code, a language's own name, the product's name and a
    /// version number are not translations — translating them would be the
    /// defect.
    const Set<String> kNotTranslated = <String>{
      'Lume',
      'English',
      'USD',
      'EUR',
      'GBP',
      'AED',
      'SAR',
      'INR',
      'JPY',
      'PKR',
    };

    for (final String code in <String>['ur', 'ar']) {
      testWidgets('in $code', (WidgetTester tester) async {
        // An English sentence in the middle of an Urdu screen is what a
        // missing key looks like after `gen_l10n`'s silent fallback. Latin
        // letters in a row of Arabic script are the visible symptom, so that
        // is what is looked for.
        final RegExp latinWords = RegExp(r'[A-Za-z]{3,}');

        for (final LumeAccountRoute route in LumeAccountRoute.values) {
          await render(tester, route, locale: Locale(code), textScale: 1.0);

          for (final LumeSettingsRow row in tester.widgetList<LumeSettingsRow>(
            find.byType(LumeSettingsRow),
          )) {
            for (final String? text in <String?>[row.title, row.subtitle]) {
              if (text == null) continue;
              final Iterable<String> words = latinWords
                  .allMatches(text)
                  .map((RegExpMatch m) => m.group(0)!)
                  .where((String w) => !kNotTranslated.contains(w));
              expect(words, isEmpty, reason: '$code/${route.segment}: "$text"');
            }
          }
        }
      });
    }
  });
}
