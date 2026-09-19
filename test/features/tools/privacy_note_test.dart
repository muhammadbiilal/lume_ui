/// The privacy note follows what a sensitive tool can send out of Lume.
///
/// A tool that never shares says its information is never part of shared
/// content. A tool that shares only what the reader has reviewed — Ledger's
/// reminder — says exactly that, and never that nothing is shared. The copy
/// is chosen from typed catalogue metadata ([LumeOutbound]), not a tool id.
library;

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

    test('a tool that is not sensitive has none', () {
      expect(LumePrivacyNote.of(l, byId('calculator')), isNull);
    });

    test('a sensitive tool that shares nothing: never in shared content', () {
      final LumePrivateState n = LumePrivacyNote.of(l, byId('expenses'))!;
      expect(n.title, 'Private to you');
      expect(
        n.text,
        'This information stays on your device, is never shown on Home and '
        'is never included in shared content.',
      );
    });

    test('a sensitive tool that shares reviewed content: only that leaves', () {
      final LumePrivateState n = LumePrivacyNote.of(l, byId('ledger'))!;
      expect(n.title, 'Private by default');
      expect(
        n.text,
        'This information stays on your device and is never shown on Home. '
        'Only what you review and choose to share leaves Lume — nothing else '
        'is included.',
      );
      expect(n.text, isNot(contains('never included in shared content')));
    });

    test('English, Urdu and Arabic say the same thing', () {
      // Each language names Home, names the reader's review and choice, and
      // never says nothing is shared.
      const Map<String, (String, List<String>, String)> meaning =
          <String, (String, List<String>, String)>{
            'en': ('Home', <String>['review', 'choose'], 'never included'),
            'ur': ('ہوم', <String>['دیکھ', 'چنیں'], 'کبھی شیئر نہیں'),
            'ar': ('الرئيسية', <String>['تراجعه', 'تختار'], 'لا تُشارك'),
          };
      for (final MapEntry<String, AppLocalizations> e in langs.entries) {
        final (String home, List<String> review, String never) =
            meaning[e.key]!;
        final String text = e.value.toolPrivateReviewedText;
        expect(text, contains(home), reason: e.key);
        for (final String word in review) {
          expect(text, contains(word), reason: '${e.key}: $word');
        }
        expect(text, isNot(contains(never)), reason: e.key);
        expect(e.value.toolPrivateReviewedTitle, isNotEmpty);
        expect(
          e.value.toolPrivateReviewedTitle,
          isNot(e.value.toolPrivateTitle),
        );
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
  });
}
