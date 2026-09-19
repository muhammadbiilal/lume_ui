/// The privacy note follows what a sensitive tool can send out of Lume.
///
/// A tool that never shares says its information is never part of shared
/// content. A tool that shares only what the reader has reviewed — Ledger's
/// reminder — says exactly that, and never that nothing is shared. The copy
/// is chosen from typed catalogue metadata ([LumeOutbound]), not a tool id.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/presentation/privacy_note.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_en.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

import '../../helpers/load_fonts.dart';
import '../wave1/wave1_tools_test.dart' show pumpTool;

LumeFeature byId(String id) =>
    kLumeFeatures.firstWhere((LumeFeature f) => f.id == id);

void main() {
  final Map<String, AppLocalizations> langs = <String, AppLocalizations>{
    'en': AppLocalizationsEn(),
    'ur': AppLocalizationsUr(),
    'ar': AppLocalizationsAr(),
  };

  group('the catalogue', () {
    test('only Ledger shares reviewed content; it is sensitive', () {
      expect(
        <String>[
          for (final LumeFeature f in kLumeFeatures)
            if (f.outbound == LumeOutbound.reviewedShare) f.id,
        ],
        <String>['ledger'],
      );
      expect(byId('ledger').sensitive, isTrue);
    });

    test('a sensitive tool that shares nothing has no share card', () {
      // Expenses and Goals keep the reference's Share action in their
      // declared supports; with no card behind it the frame draws it
      // disabled (below), so nothing of theirs can leave.
      for (final LumeFeature f in kLumeFeatures) {
        if (!f.sensitive || f.outbound != LumeOutbound.none) continue;
        expect(f.shareable, isFalse, reason: f.id);
      }
    });
  });

  group('the note', () {
    final AppLocalizations l = langs['en']!;
    const LumeBuildProfile parity = LumeBuildProfile.parity;
    const List<LumeBuildProfile> shipped = <LumeBuildProfile>[
      LumeBuildProfile.development,
      LumeBuildProfile.release,
    ];

    test('a tool that is not sensitive has none', () {
      for (final LumeBuildProfile p in LumeBuildProfile.values) {
        expect(LumePrivacyNote.of(l, byId('calculator'), profile: p), isNull);
      }
    });

    test('parity: a tool that shares nothing keeps the reference sentence', () {
      final LumePrivateState n = LumePrivacyNote.of(
        l,
        byId('expenses'),
        profile: parity,
      )!;
      expect(n.title, 'Private to you');
      expect(
        n.text,
        'This information stays on your device, is never shown on Home and '
        'is never included in shared content.',
      );
      // Urdu and Arabic keep the reference's shorter sentence here.
      expect(
        LumePrivacyNote.of(
          langs['ur']!,
          byId('expenses'),
          profile: parity,
        )!.text,
        langs['ur']!.toolPrivateText,
      );
    });

    test('development and release: the whole contract', () {
      for (final LumeBuildProfile p in shipped) {
        final LumePrivateState n = LumePrivacyNote.of(
          l,
          byId('expenses'),
          profile: p,
        )!;
        expect(n.title, 'Private to you');
        expect(
          n.text,
          'This information stays on your device. It is never shown on Home '
          'or in its suggestions, and never included in shared content.',
        );
      }
    });

    test('a tool that shares reviewed content: only that leaves, in every '
        'flavor', () {
      for (final LumeBuildProfile p in LumeBuildProfile.values) {
        final LumePrivateState n = LumePrivacyNote.of(
          l,
          byId('ledger'),
          profile: p,
        )!;
        expect(n.title, 'Private by default');
        expect(
          n.text,
          'This information stays on your device and is never shown on Home. '
          'Only what you review and choose to share leaves Lume. Notes, '
          'record IDs and anything you did not review are never included.',
        );
        expect(n.text, isNot(contains('never included in shared content')));
      }
    });

    test('shipped: English, Urdu and Arabic say the same thing', () {
      // (home, suggestions, device, shared content) for a tool that shares
      // nothing; (home, review, choose, notes, ids) for reviewed sharing.
      const Map<String, (String, String, String, String)> none =
          <String, (String, String, String, String)>{
            'en': ('Home', 'suggestions', 'device', 'shared content'),
            'ur': ('ہوم', 'تجاویز', 'آلے', 'شیئر کیے گئے مواد'),
            'ar': ('الرئيسية', 'اقتراحاتها', 'جهازك', 'المحتوى الذي تشاركه'),
          };
      const Map<String, List<String>> reviewed = <String, List<String>>{
        'en': <String>['Home', 'review', 'choose', 'Notes', 'record IDs'],
        'ur': <String>['ہوم', 'دیکھ', 'چنیں', 'نوٹس', 'ریکارڈ کی شناخت'],
        'ar': <String>['الرئيسية', 'تراجعه', 'تختار', 'الملاحظات', 'معرّفات'],
      };
      for (final MapEntry<String, AppLocalizations> e in langs.entries) {
        final (String home, String sugg, String device, String shared) =
            none[e.key]!;
        final String full = e.value.toolPrivateFullText;
        for (final String w in <String>[home, sugg, device, shared]) {
          expect(full, contains(w), reason: '${e.key}: $w');
        }
        final String rev = e.value.toolPrivateReviewedText;
        for (final String w in reviewed[e.key]!) {
          expect(rev, contains(w), reason: '${e.key}: $w');
        }
        expect(
          e.value.toolPrivateReviewedTitle,
          isNot(e.value.toolPrivateTitle),
        );
        if (e.key != 'en') {
          // No English in Urdu or Arabic, beyond the product's name.
          for (final String t in <String>[
            full,
            rev,
            e.value.toolPrivateTitle,
            e.value.toolPrivateReviewedTitle,
          ]) {
            expect(
              t.replaceAll('Lume', ''),
              isNot(matches(RegExp('[A-Za-z]'))),
              reason: '${e.key}: $t',
            );
          }
        }
      }
    });
  });

  group('in the tool itself', () {
    setUpAll(loadLumeFonts);

    for (final LumeBuildProfile profile in LumeBuildProfile.values) {
      testWidgets('${profile.name}: Expenses says never shared; Ledger says '
          'only what you review', (WidgetTester t) async {
        final SemanticsHandle h = t.ensureSemantics();
        await pumpTool(
          t,
          'expenses',
          overrides: <Override>[
            buildProfileProvider.overrideWithValue(profile),
          ],
        );
        expect(find.text('Private to you'), findsOneWidget);
        expect(find.text('Private by default'), findsNothing);
        // Its Share, where drawn, does nothing: there is no card to share.
        for (final LumeIconButton b in t.widgetList<LumeIconButton>(
          find.byType(LumeIconButton),
        )) {
          if (b.label == 'Share') expect(b.onPressed, isNull);
        }

        await pumpTool(
          t,
          'ledger',
          overrides: <Override>[
            buildProfileProvider.overrideWithValue(profile),
          ],
        );
        expect(find.text('Private by default'), findsOneWidget);
        expect(find.textContaining('never included in shared'), findsNothing);
        // A screen reader hears the same meaning.
        expect(
          find.bySemanticsLabel(RegExp('Only what you review and choose')),
          findsOneWidget,
        );
        h.dispose();
      });
    }

    for (final (String code, AppLocalizations l)
        in <(String, AppLocalizations)>[
          ('ur', AppLocalizationsUr()),
          ('ar', AppLocalizationsAr()),
        ]) {
      for (final LumeBuildProfile profile in LumeBuildProfile.values) {
        testWidgets('$code · ${profile.name}: heard in full outside parity', (
          WidgetTester t,
        ) async {
          final SemanticsHandle h = t.ensureSemantics();
          await pumpTool(
            t,
            'expenses',
            locale: Locale(code),
            overrides: <Override>[
              buildProfileProvider.overrideWithValue(profile),
            ],
          );
          final String said = profile.reproducesReference
              ? l.toolPrivateText
              : l.toolPrivateFullText;
          expect(find.text(said), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(said))),
            findsOneWidget,
          );
          h.dispose();
        });
      }
    }
  });
}
