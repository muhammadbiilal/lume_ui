/// The tools no earlier golden pinned, captured as each one opens, in the
/// eight cells the rollout waves use.
///
/// Waves 1 to 4 and the per-tool golden files cover 37 tools; these are the
/// other 48. Each opens for the reader it exists for — a faith-gated tool for
/// a Muslim reader in Islamabad, every other tool for the default Islamabad
/// reader — so the frame is the tool, never the "not available" refusal.
///
/// The last group is the inventory: every tool the registry can build has at
/// least one committed golden, so a tool added later without one fails here
/// rather than going unpictured.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/application/tool_registry.dart';

import '../features/reminders/reminders_screen_harness.dart';
import '../features/tax/tax_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

const String kOut = '$kShotsDir/tools';

typedef Cell = (
  String name,
  Size size,
  ThemeMode theme,
  Locale locale,
  double scale,
);

const List<Cell> kCells = <Cell>[
  ('390x844_light_en', Size(390, 844), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_dark_en', Size(390, 844), ThemeMode.dark, Locale('en'), 1.0),
  ('700x900_light_en', Size(700, 900), ThemeMode.light, Locale('en'), 1.0),
  ('1100x900_light_en', Size(1100, 900), ThemeMode.light, Locale('en'), 1.0),
  ('852x393_light_en', Size(852, 393), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_light_ur', Size(390, 844), ThemeMode.light, Locale('ur'), 1.0),
  ('390x844_light_ar', Size(390, 844), ThemeMode.light, Locale('ar'), 1.0),
  ('390x844_light_en_x2', Size(390, 844), ThemeMode.light, Locale('en'), 2.0),
];

/// The 48, in catalogue order within each area.
const List<String> kTools = <String>[
  // Prayer & Islam.
  'prayer', 'qibla', 'mosques', 'praytrack', 'ramadan', 'fasting',
  'taraweeh', 'ayah', 'quran', 'quransearch', 'duas', 'names99', 'hijri',
  'zakat', 'faraid',
  // Money & rates.
  'currency', 'markets', 'fuel', 'fuelcost', 'natsavings', 'prizebonds',
  'bills', 'packages', 'subs',
  // Daily life.
  'loadshed', 'trains', 'cricket', 'aqi', 'holidays', 'bmi', 'docscan',
  'passport', 'vehicle', 'mediasaver', 'wastatus', 'speedtest',
  // Personal.
  'parcel', 'streak', 'mealplan', 'alarms', 'reminders', 'goals', 'habits',
  'meds', 'vaccines', 'health', 'cycle', 'pregnancy',
];

LumeFeature featureOf(String id) =>
    kLumeFeatures.firstWhere((LumeFeature f) => f.id == id);

void main() {
  setUpAll(loadLumeFonts);

  group('the remaining tools, as each opens', () {
    for (final String tool in kTools) {
      final String state = featureOf(tool).faith ? 'muslim_pk' : 'default_pk';
      for (final Cell cell in kCells) {
        testWidgets('$tool ${cell.$1}', (WidgetTester tester) async {
          final String golden = 'tool_${tool}_$state';
          // Reminders' real store is SQLite, which this suite's config does
          // not set up; its screen tests use the same memory store.
          final ReminderWorld? reminders = tool == 'reminders'
              ? ReminderWorld()
              : null;
          if (reminders != null) addTearDown(reminders.dispose);
          await captureLumeRoute(
            tester,
            location: LumeRoutes.tool(LumeRoutes.tools, tool),
            name: golden,
            outDir: kOut,
            surface: cell.$2,
            theme: cell.$3,
            locale: cell.$4,
            textScale: cell.$5,
            suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
            profile: taxProfile(state),
            overrides: <Override>[
              buildProfileProvider.overrideWithValue(LumeBuildProfile.parity),
              ...?reminders?.overrides,
            ],
          );
          expect(find.byType(LumeToolFrame), findsOneWidget);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('images/${golden}_${cell.$1}.png'),
          );
        });
      }
    }
  });

  group('the inventory', () {
    test('every tool the registry builds has a committed golden', () {
      final Set<String> pictured = <String>{
        for (final FileSystemEntity f in Directory(
          'test/goldens/images',
        ).listSync())
          if (RegExp(r'tool_([a-z0-9]+)_').firstMatch(f.uri.pathSegments.last)
              case final RegExpMatch m)
            m.group(1)!,
      };
      final List<String> missing = <String>[
        for (final String id in kLumeToolRegistry.keys)
          if (!pictured.contains(id)) id,
      ];
      expect(missing, isEmpty, reason: 'tools with no golden');
    });

    test('the list here is exactly the tools nothing else pictured', () {
      expect(kTools.toSet(), hasLength(48));
      for (final String id in kTools) {
        expect(kLumeToolRegistry.containsKey(id), isTrue, reason: id);
      }
    });
  });
}
