/// The account route manifest.
///
/// Twenty-one routes, one host, one gate. These tests exist because a settings
/// section fails quietly: a route that renders nothing, a row that leads to a
/// blank host, a protected screen a link walks straight into — none of them
/// throws, and none of them shows up in a composition test of some other
/// screen. So the manifest is checked as a *whole* rather than route by route.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/domain/account_repository.dart';
import 'package:lume/features/startup/domain/startup_state.dart';

void main() {
  group('the manifest', () {
    test('is exactly twenty-one routes, with unique ids', () {
      // `ui/account-ui.js`'s `ROUTES`. Not a number to be adjusted when one is
      // added: a route that is not in the reference needs a decision, and a
      // reference route that is missing is the thing this catches.
      expect(LumeAccountRoute.values, hasLength(21));
      expect(
        LumeAccountRoute.values.map((LumeAccountRoute r) => r.segment).toSet(),
        hasLength(21),
      );
    });

    test('is in the order the source declares them', () {
      expect(
        LumeAccountRoute.values.map((LumeAccountRoute r) => r.segment).toList(),
        <String>[
          'prefs',
          'language',
          'region',
          'currency',
          'units',
          'time',
          'appearance',
          'notifications',
          'library',
          'account',
          'edit',
          'email',
          'phone',
          'security',
          'password',
          'sessions',
          'privacy',
          'sync',
          'help',
          'about',
          'delete',
        ],
      );
    });

    test('every segment parses back to its own route, and nothing else', () {
      for (final LumeAccountRoute r in LumeAccountRoute.values) {
        expect(LumeAccountRoute.parse(r.segment), r);
      }
      // A segment nobody defined is not a route. The router turns this into
      // the same refusal an unknown tool gets.
      for (final String nonsense in <String>[
        '',
        'Prefs',
        'preferences',
        'accounts',
        '../admin',
        'delete/all',
      ]) {
        expect(LumeAccountRoute.parse(nonsense), isNull, reason: nonsense);
      }
      expect(LumeAccountRoute.parse(null), isNull);
    });

    test('every route builds a path on every branch', () {
      for (final String branch in <String>[
        LumeRoutes.home,
        LumeRoutes.tools,
        LumeRoutes.trains,
        LumeRoutes.today,
        LumeRoutes.explore,
        LumeRoutes.profile,
      ]) {
        for (final LumeAccountRoute r in LumeAccountRoute.values) {
          final String path = LumeRoutes.accountRoute(branch, r.segment);
          expect(path, '$branch/account/${r.segment}');
          // And it rides the branch it was built on, so Back returns there.
          expect(LumeRoutes.branchOf(path), branch);
        }
      }
    });
  });

  group('the gate', () {
    final LumeAccountRepository repo = LumeFakeAccountRepository.guest();

    /// `PROTECTED` in `services/account.js`, written out rather than derived,
    /// so a route silently joining or leaving the list is a failure here.
    const Set<String> protected = <String>{
      'account',
      'email',
      'phone',
      'security',
      'password',
      'sessions',
      'delete',
    };

    test('seven routes need an account, and fourteen do not', () {
      for (final LumeAccountRoute r in LumeAccountRoute.values) {
        expect(
          repo.requiresAccount(r),
          protected.contains(r.segment),
          reason: r.segment,
        );
      }
      expect(protected, hasLength(7));
    });

    test('the router and the repository agree on which seven', () {
      // Two lists in two layers — routing is core, the account is a feature —
      // and this is what stops them drifting.
      expect(LumeRouteGate.protectedAccountRoutes, protected);
    });

    test('data & sync and privacy are open, and say why', () {
      // A row a guest can see must lead somewhere. Both describe what is on
      // *this device*, which is exactly as true without an account.
      expect(repo.requiresAccount(LumeAccountRoute.sync), isFalse);
      expect(repo.requiresAccount(LumeAccountRoute.privacy), isFalse);
      // And the edit form, which is the only screen that changes the name a
      // guest gave this device.
      expect(repo.requiresAccount(LumeAccountRoute.edit), isFalse);
    });

    test('a protected location is protected on every branch', () {
      for (final LumeAccountRoute r in LumeAccountRoute.values) {
        for (final String branch in <String>[
          LumeRoutes.home,
          LumeRoutes.profile,
        ]) {
          expect(
            LumeRouteGate.isProtected(
              LumeRoutes.accountRoute(branch, r.segment),
            ),
            protected.contains(r.segment),
            reason: '$branch/${r.segment}',
          );
        }
      }
    });

    test(
      'the bare path is an alias for an open route, not a protected one',
      () {
        // `/…/account` resolves to `prefs`. Treating the whole section as
        // protected would send a guest to sign in to read the help.
        expect(
          LumeRouteGate.isProtected(LumeRoutes.account(LumeRoutes.profile)),
          isFalse,
        );
        expect(
          LumeRouteGate.isProtected(
            LumeRoutes.accountRoute(LumeRoutes.profile, 'prefs'),
          ),
          isFalse,
        );
      },
    );

    test('a query string does not smuggle a route past the gate', () {
      expect(
        LumeRouteGate.isProtected('/profile/account/password?x=1'),
        isTrue,
      );
      expect(
        LumeRouteGate.isProtected('/profile/account/help?next=password'),
        isFalse,
      );
    });
  });

  group('the aliases, written down', () {
    test('there are exactly two, and both resolve to a real route', () {
      // `/account` → `/profile/account` → `/profile/account/prefs`.
      //
      // Neither is a screen. The reference has no account landing page: every
      // entry point names a route and the host always has one open.
      expect(LumeRoutes.account(LumeRoutes.profile), '/profile/account');
      expect(
        LumeRoutes.accountRoute(
          LumeRoutes.profile,
          LumeAccountRoute.prefs.segment,
        ),
        '/profile/account/prefs',
      );
    });
  });
}
