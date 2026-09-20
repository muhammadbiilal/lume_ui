/// Committee in the catalogue and on the surfaces around it: sensitive,
/// shares nothing, sends no notification, says what it is for — and never
/// reaches Home, even for a reader who favourites and uses it
/// (`COMMITTEE_PROPOSAL.md` §11, D-C9, D-C10).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/home/application/home_controller.dart';
import 'package:lume/features/home/domain/home_model.dart';
import 'package:lume/features/tools/application/tool_registry.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';
import 'package:lume/features/tools/presentation/privacy_note.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_en.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

import '../destinations/destination_harness.dart';

void main() {
  final LumeFeature committee = kLumeFeatures.firstWhere(
    (LumeFeature f) => f.id == 'committee',
  );

  test('sensitive, sharing nothing, sending nothing', () {
    expect(committee.sensitive, isTrue);
    expect(committee.outbound, LumeOutbound.none);
    expect(committee.shareable, isFalse);
    // The reference declares notifications and implements none (D-C10).
    expect(committee.supports, isNot(contains(LumeToolSupport.notifications)));
    expect(committee.supports, isNot(contains(LumeToolSupport.sharing)));
    // What it declares, it really has.
    expect(committee.supports, contains(LumeToolSupport.search));
    expect(committee.supports, contains(LumeToolSupport.filters));
    expect(committee.supports, contains(LumeToolSupport.sorting));
    expect(committee.supports, contains(LumeToolSupport.export));
  });

  test('its own records only: never sample data', () {
    expect(LumeDataCapability.readerRecords, contains('committee'));
    expect(LumeDataCapability.fixture('committee').isSample, isFalse);
    // Nothing in this build is durable or encrypted, and it does not say so.
    expect(LumeDataCapability.fixture('committee').isDurable, isFalse);
    expect(LumeDataCapability.fixture('committee').isEncrypted, isFalse);
  });

  test('it opens on its own host, not the archetype fallback', () {
    expect(kLumeToolRegistry.keys, contains('committee'));
  });

  test('the tile says what it is for, in every language — never a count', () {
    expect(
      AppLocalizationsEn().toolStatusCommittee,
      'Track a savings committee',
    );
    for (final String s in <String>[
      AppLocalizationsEn().toolStatusCommittee,
      AppLocalizationsUr().toolStatusCommittee,
      AppLocalizationsAr().toolStatusCommittee,
    ]) {
      expect(s, isNot(matches(RegExp(r'[0-9٠-٩۰-۹]'))));
    }
  });

  test('the privacy note: never in shared content, in every flavor', () {
    for (final LumeBuildProfile p in LumeBuildProfile.values) {
      expect(
        LumePrivacyNote.of(AppLocalizationsEn(), committee, profile: p)!.title,
        'Private to you',
      );
    }
  });

  testWidgets('never on Home, however much the reader uses it', (
    WidgetTester tester,
  ) async {
    const LumeUserContext user = LumeUserContext(
      interests: <String>{'savings', 'expenses'},
      favourites: <String>['committee'],
      recents: <String>['committee'],
    );
    final LumeHomeController c = await composeHome(user);
    addTearDown(c.dispose);
    final LumeHomeData d = c.state.data!;
    expect(
      d.quickTools.map((LumeFeature f) => f.id),
      isNot(contains('committee')),
    );
    expect(
      d.quickActions.map((LumeQuickAction a) => a.featureId),
      isNot(contains('committee')),
    );
    for (final LumeHeroCard h in d.hero) {
      expect('${h.target}', isNot(contains('committee')));
    }
    for (final LumeDiscoverCard x in d.discover) {
      expect('${x.target}', isNot(contains('committee')));
    }
    for (final LumeGlanceCard g in d.glance) {
      expect('${g.target}', isNot(contains('committee')));
    }
  });
}
