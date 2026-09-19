/// The friendly zone label is presentation only, everywhere a zone is shown.
///
/// Rules held here, beyond `lume_follow_region_test.dart`'s:
///
/// - CLDR's label is never invented where CLDR has none: a language that
///   lacks a zone's label shows its canonical identifier, not English text.
/// - One label never collapses two canonical zones: distinct identifiers
///   stay distinct rows, and screen readers hear each identifier.
/// - Changing language changes the words, never the stored zone.
/// - A screen reader hears the label and the identifier on Calendar and
///   Events.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_country_zones.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/time/lume_zone_aliases.dart';
import 'package:lume/core/time/lume_zone_labels.dart';
import 'package:lume/core/time/lume_zone_labels_data.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../features/account/account_harness.dart';
import '../../features/tax/tax_harness.dart';
import '../../features/wave2/wave2_harness.dart';
import '../../helpers/load_fonts.dart';

String canonical(String id) =>
    kLumeCanonicalZones.contains(id) ? id : (kLumeZoneAliases[id] ?? id);

void main() {
  group('labels are CLDR\'s or none', () {
    test('a language CLDR gives no label shows the identifier, never '
        'another language’s', () {
      int checked = 0;
      for (final String language in <String>['en', 'ur', 'ar']) {
        final Set<String> own = kLumeZoneLabelText[language]!.keys.toSet();
        for (final String other in <String>['en', 'ur', 'ar']) {
          for (final String id in kLumeZoneLabelText[other]!.keys) {
            if (own.contains(id) || !kLumeCanonicalZones.contains(id)) {
              continue;
            }
            final LumeZoneLabel l = LumeZoneLabels.of(id, language: language);
            expect(l.text, isNull, reason: '$language $id');
            expect(l.display, l.id);
            expect(l.semantics, l.id);
            checked++;
          }
        }
      }
      // CLDR names a few zones in Urdu and Arabic that it leaves unnamed in
      // English; each shows its identifier to an English reader.
      expect(checked, greaterThan(0));
    });

    test('every label shown is CLDR\'s text in CLDR\'s pattern', () {
      for (final String language in <String>['en', 'ur', 'ar']) {
        for (final String id in kLumeCanonicalZones) {
          final LumeZoneLabel l = LumeZoneLabels.of(id, language: language);
          expect(l.id, id);
          if (l.text == null) {
            expect(l.display, id);
          } else {
            expect(
              l.display,
              kLumeZoneLabelFormat[language]!.replaceAll('{0}', l.text!),
            );
            expect(l.semantics, '${l.display}, $id');
          }
        }
      }
    });
  });

  group('one label never merges two zones', () {
    test('each country\'s zones keep one identity each, in every language', () {
      for (final MapEntry<String, List<String>> c
          in kLumeCountryZoneIds.entries) {
        final Set<String> ids = <String>{
          for (final String z in c.value) canonical(z),
        };
        for (final String language in <String>['en', 'ur', 'ar']) {
          final List<LumeZoneLabel> labels = <LumeZoneLabel>[
            for (final String id in ids)
              LumeZoneLabels.of(id, language: language, country: c.key),
          ];
          expect(
            labels.map((LumeZoneLabel l) => l.id).toSet(),
            hasLength(ids.length),
            reason: c.key,
          );
          // Where two zones read alike, what a screen reader hears still
          // tells them apart.
          expect(
            labels.map((LumeZoneLabel l) => l.semantics).toSet(),
            hasLength(ids.length),
            reason: '${c.key} $language',
          );
        }
      }
    });

    test('a shared label never makes a country resolve on its own', () {
      // The United States has many zones; none is picked because its label
      // is familiar.
      final LumeZoneResolution r = LumeTimeZoneService.shared.reader(
        country: 'US',
        city: '',
      );
      expect(r.outcome, LumeZoneOutcome.selectionRequired);
      expect(r.label('en'), isNull);
    });
  });

  group('on screen', () {
    setUpAll(loadLumeFonts);

    testWidgets('Account › Time: one row per identity, the identifier under '
        'each label', (WidgetTester t) async {
      await pumpAccountHost(
        t,
        route: LumeAccountRoute.time,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            country: 'US',
            city: 'New York',
            region: 'New York',
          ),
        ),
        surface: const Size(390, 6000),
      );
      final List<LumeOptionRow> rows = t
          .widgetList<LumeOptionRow>(find.byType(LumeOptionRow))
          .where((LumeOptionRow r) => r.subtitle?.contains('/') ?? false)
          .toList();
      final Set<String> ids = <String>{
        for (final LumeOptionRow r in rows) r.subtitle!,
      };
      expect(ids, contains('America/New_York'));
      expect(ids, contains('America/Los_Angeles'));
      expect(ids, hasLength(rows.length), reason: 'no identity twice');
      for (final String id in ids) {
        expect(id, canonical(id), reason: 'stored and shown canonical');
      }
    });

    testWidgets('changing language changes the words, never the zone', (
      WidgetTester t,
    ) async {
      final Map<String, String> seen = <String, String>{};
      for (final String language in <String>['en', 'ur', 'ar']) {
        final LumeStartupController gate = await bootedGate(
          profile: const LumeProfileRecord(
            country: 'KW',
            city: 'Kuwait City',
            region: '',
            timeZone: 'Asia/Riyadh',
          ),
        );
        await pumpAccountHost(
          t,
          route: LumeAccountRoute.time,
          gate: gate,
          locale: Locale(language),
          surface: const Size(390, 4000),
        );
        final LumeOptionRow chosen = t
            .widgetList<LumeOptionRow>(find.byType(LumeOptionRow))
            .firstWhere(
              (LumeOptionRow r) => r.selected && r.subtitle == 'Asia/Riyadh',
            );
        seen[language] = chosen.title;
        expect(gate.state.profile.timeZone, 'Asia/Riyadh');
      }
      expect(seen['en'], 'Kuwait Time');
      expect(seen.values.toSet(), hasLength(3), reason: '$seen');
    });

    testWidgets('Calendar: the reader hears the label and the identifier', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await pumpWave2(t, 'calendar');
      expect(find.text('\u2068Pakistan Time\u2069'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pakistan Time, Asia/Karachi'),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('Events: the Timezone fact says the label, then the '
        'identifier', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final LumeProfileRepository reader = LumeMemoryProfileRepository(
        initial: taxReader().copyWith(timeZone: 'America/New_York'),
      );
      await pumpWave2(t, 'events', profile: reader);
      await tapVisible(t, find.byType(LumeRecordRow).first);
      expect(
        find.bySemanticsLabel('Timezone, New York Time, America/New_York'),
        findsOneWidget,
      );
      h.dispose();
    });
  });
}
