/// Installments in the catalogue and on the surfaces around it: sensitive,
/// shares nothing, sends no notification, says what it is for — and never
/// reaches Home, even for a reader who favourites and uses it
/// (`INSTALLMENTS_PROPOSAL.md` §40.1, §40.11).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/home/application/home_controller.dart';
import 'package:lume/features/home/domain/home_model.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';
import 'package:lume/features/tools/presentation/privacy_note.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_en.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

import '../destinations/destination_harness.dart';

void main() {
  final LumeFeature inst = kLumeFeatures.firstWhere(
    (LumeFeature f) => f.id == 'installments',
  );

  test('sensitive, sharing nothing, sending nothing', () {
    expect(inst.sensitive, isTrue);
    expect(inst.outbound, LumeOutbound.none);
    expect(inst.shareable, isFalse);
    expect(inst.supports, isNot(contains(LumeToolSupport.notifications)));
    expect(inst.supports, isNot(contains(LumeToolSupport.sharing)));
    expect(inst.supports, contains(LumeToolSupport.search));
  });

  test('its own records only: never sample data', () {
    expect(LumeDataCapability.readerRecords, contains('installments'));
    expect(LumeDataCapability.fixture('installments').isSample, isFalse);
  });

  test('the tile says what it is for, in every language — never a count', () {
    expect(
      AppLocalizationsEn().toolStatusInstallments,
      'Track fixed payment plans',
    );
    for (final String s in <String>[
      AppLocalizationsEn().toolStatusInstallments,
      AppLocalizationsUr().toolStatusInstallments,
      AppLocalizationsAr().toolStatusInstallments,
    ]) {
      expect(s, isNot(matches(RegExp(r'[0-9٠-٩۰-۹]'))));
    }
  });

  test('the privacy note: never in shared content, in every flavor', () {
    for (final LumeBuildProfile p in LumeBuildProfile.values) {
      expect(
        LumePrivacyNote.of(AppLocalizationsEn(), inst, profile: p)!.title,
        'Private to you',
      );
    }
  });

  testWidgets('never on Home, however much the reader uses it', (
    WidgetTester tester,
  ) async {
    const LumeUserContext user = LumeUserContext(
      interests: <String>{'expenses', 'savings'},
      favourites: <String>['installments'],
      recents: <String>['installments'],
    );
    final LumeHomeController c = await composeHome(user);
    addTearDown(c.dispose);
    final LumeHomeData d = c.state.data!;
    expect(
      d.quickTools.map((LumeFeature f) => f.id),
      isNot(contains('installments')),
    );
    expect(
      d.quickActions.map((LumeQuickAction a) => a.featureId),
      isNot(contains('installments')),
    );
    for (final LumeHeroCard h in d.hero) {
      expect('${h.target}', isNot(contains('installments')));
    }
    for (final LumeDiscoverCard x in d.discover) {
      expect('${x.target}', isNot(contains('installments')));
    }
    for (final LumeGlanceCard g in d.glance) {
      expect('${g.target}', isNot(contains('installments')));
    }
  });
}
