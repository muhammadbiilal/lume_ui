/// The launch, as one object.
///
/// Reads the profile (running any one-shot migration first), restores the
/// session, and publishes a [LumeStartupState] the router listens to. Nothing
/// else in the application calls [LumeAuthRepository.restore] or
/// [LumeProfileMigrator.run] — a second caller would be a second restoration,
/// and [LumeFakeAuthRepository.restores] exists so a test can prove there is
/// only one.
///
/// It is a [ChangeNotifier] because that is what `GoRouter.refreshListenable`
/// takes: the gate re-evaluates when, and only when, something it reads has
/// actually changed.
library;

import 'dart:async';
import '../../onboarding/data/country_fixture.dart';

import 'package:flutter/foundation.dart';

import '../../auth/domain/auth_model.dart';
import '../../auth/domain/auth_repository.dart';
import '../../onboarding/domain/islamic_migration.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../onboarding/domain/profile_repository.dart';
import '../domain/startup_state.dart';

class LumeStartupController extends ChangeNotifier {
  LumeStartupController({
    required this.authRepository,
    required this.profileRepository,
  });

  final LumeAuthRepository authRepository;
  final LumeProfileRepository profileRepository;

  LumeStartupState _state = const LumeStartupState();
  LumeStartupState get state => _state;

  Future<void>? _boot;
  bool _disposed = false;

  /// Run the launch. Safe to call more than once; it only happens once.
  Future<void> boot() => _boot ??= _run();

  Future<void> _run() async {
    // The migration goes first: everything downstream reads a preference, and
    // reading one before it has been decided is how a grandfathered user ends
    // up looking like a fresh install for one frame.
    LumeProfileRecord profile = await profileRepository.readProfile();
    try {
      final LumeMigrationResult migrated = await LumeProfileMigrator(
        profileRepository,
      ).run();
      profile = migrated.record;
    } on Object {
      // A migration that cannot be written is not a launch that cannot
      // happen. It left no marker, so the next launch tries again.
    }

    LumeAuthStatus auth;
    try {
      auth = await authRepository.restore();
    } on Object {
      // A restore that failed is a guest. Nothing about a failed read says
      // somebody is signed in, and guessing the other way would show private
      // surfaces to whoever is holding the phone.
      auth = const LumeAuthStatus.guest();
    }

    // The country table, for every surface that has to name a country. It is
    // a bundled asset and it caches, so this is the one read; a failure is
    // not a launch that cannot happen, and the screens fall back to the code.
    LumeCountryFixture? countries;
    try {
      countries = await LumeCountryFixture.load();
    } on Object {
      countries = null;
    }

    if (_disposed) return;
    _publish(
      _state.copyWith(
        phase: LumeStartupPhase.ready,
        profile: profile,
        profileIsDurable: profileRepository.isDurable,
        auth: auth,
        countries: countries,
      ),
    );
  }

  /// Hold a location the user asked for but cannot have yet.
  ///
  /// Called by the gate's host when a redirect takes somebody away from where
  /// they were going. Only real destinations are held: sending someone back
  /// to the splash or into a flow they have just left is not resuming
  /// anything.
  void hold(String location) {
    if (LumeRouteGate.isFlow(location)) return;
    if (_state.held == location) return;
    _publish(_state.copyWith(held: location));
  }

  /// Take the held location, if there is one, and forget it.
  String? takeHeld() {
    final String? held = _state.held;
    if (held == null) return null;
    _publish(_state.copyWith(clearHeld: true));
    return held;
  }

  /// A flow finished with a new session.
  ///
  /// **Never touches the profile.** Signing in is not finishing onboarding,
  /// and an authentication that wrote `onboarded` would skip the flow for a
  /// user who has never seen it.
  void signedIn(LumeAuthStatus status) {
    _publish(_state.copyWith(auth: status));
  }

  /// The profile changed under us — onboarding finished, a setting moved.
  void profileChanged(LumeProfileRecord record) {
    _publish(_state.copyWith(profile: record));
  }

  /// End the session. The device keeps what the device made.
  Future<void> signOut() async {
    await authRepository.signOut();
    if (_disposed) return;
    _publish(
      _state.copyWith(auth: const LumeAuthStatus.guest(), clearHeld: true),
    );
  }

  /// Leave an expired session behind and carry on as a guest.
  Future<void> continueAsGuest() async {
    if (!_state.auth.isExpired) return;
    await signOut();
  }

  void _publish(LumeStartupState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
