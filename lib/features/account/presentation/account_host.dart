/// The account section's host.
///
/// A host for the nested settings screens rather than a screen of its own: all
/// twenty-one routes render into it. Three things it owns and the routes do
/// not.
///
/// **The gate.** Seven routes need an account. The host asks
/// [LumeAccountRepository.requiresAccount] before it builds, so a row, a deep
/// link and a session that expires while the screen is open all reach the same
/// refusal — and the routes themselves never check.
///
/// **The unsaved-changes guard.** Every departure asks it first, which is why
/// it is here and not inside whichever form happens to be dirty.
///
/// **The writes.** A route names what it wants; this decides what that means
/// and tells the reader what happened. Nothing destructive happens without a
/// second, deliberate confirmation, and **nothing here connects to a server**:
/// every repository behind it is a fixture that says so.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/locale_provider.dart';
import '../../../app/providers/theme_provider.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_locales.dart';
import '../../../core/lume_build.dart';
import '../../../core/routing/lume_routes.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_flow_controller.dart';
import '../../onboarding/data/country_fixture.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../startup/application/startup_controller.dart';
import '../application/account_form.dart';
import '../domain/account_model.dart';
import '../domain/account_repository.dart';
import '../domain/notification_prefs.dart';
import 'account_parts.dart';
import 'account_routes.dart';
import 'personalise_sheet.dart';

/// One account route, on a branch.
class LumeAccountHost extends ConsumerStatefulWidget {
  const LumeAccountHost({super.key, required this.branch, required this.route});

  /// The branch the account was opened from, so Back returns to it.
  final String branch;

  final LumeAccountRoute route;

  /// Keys the tests address the host by.
  static const Key headerKey = Key('account.header');
  static const Key bodyKey = Key('account.body');

  @override
  ConsumerState<LumeAccountHost> createState() => _LumeAccountHostState();
}

class _LumeAccountHostState extends ConsumerState<LumeAccountHost> {
  final LumeAccountForm _form = LumeAccountForm();

  LumeToastData? _toast;
  List<LumeDeviceSession> _sessions = const <LumeDeviceSession>[];
  LumeStoredData _stored = const LumeStoredData(
    onDevice: <String>[],
    synced: <String>[],
  );

  @override
  void initState() {
    super.initState();
    _form.addListener(_onForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRoute();
      unawaited(_readSideData());
    });
  }

  @override
  void didUpdateWidget(LumeAccountHost old) {
    super.didUpdateWidget(old);
    if (old.route != widget.route) _openRoute();
  }

  @override
  void dispose() {
    _form
      ..removeListener(_onForm)
      ..dispose();
    super.dispose();
  }

  void _onForm() {
    if (mounted) setState(() {});
  }

  /// A route opens on its own values, and nothing from the last one.
  void _openRoute() {
    final LumeAccountView view = _view();
    _form.reset(view.initialValues);
  }

  Future<void> _readSideData() async {
    final List<LumeDeviceSession> sessions = await ref
        .read(sessionRepositoryProvider)
        .sessions();
    final LumeStoredData stored = await ref
        .read(syncRepositoryProvider)
        .stored();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _stored = stored;
    });
  }

  void _say(String message) {
    if (!mounted) return;
    setState(() => _toast = LumeToastData(message: message));
  }

  // -- leaving -------------------------------------------------------------

  /// Back, with the guard in front of it.
  ///
  /// A dirty form is not a screen somebody can be moved off silently: the
  /// reader is asked, and only their own answer lets the navigation through.
  Future<void> _leave() async {
    if (_form.dirty && !await _confirmDiscard()) return;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.branch);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await _ask(
          title: l.acctDiscardTitle,
          text: l.acctDiscardText,
          confirm: l.acctDiscardCta,
        ) ??
        false;
  }

  Future<bool?> _ask({
    required String title,
    required String text,
    required String confirm,
    LumeDeleteKind kind = LumeDeleteKind.recoverable,
  }) {
    final AppLocalizations l = AppLocalizations.of(context);
    return showLumeSheet<bool>(
      context: context,
      barrierLabel: title,
      child: LumeSheet(
        child: LumeDeleteConfirmation(
          title: title,
          consequence: text,
          confirmLabel: confirm,
          cancelLabel: l.actionCancel,
          kind: kind,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
  }

  // -- the writes ----------------------------------------------------------

  LumeStartupController get _gate => ref.read(startupControllerProvider);

  void _writeProfile(LumeProfileRecord next) => _gate.profileChanged(next);

  Future<void> _writeNotify(LumeNotificationPrefs next) async {
    await ref.read(notificationPrefsProvider).write(next);
    if (mounted) setState(() {});
  }

  /// Which field a refusal belongs to, and what it says.
  LumeFormIssue _issueFor(LumeAccountFailure failure) =>
      LumeFormIssue(switch (failure) {
        LumeAccountFailure.wrongPassword => 'currentWrong',
        LumeAccountFailure.weakPassword => 'passwordWeak',
        LumeAccountFailure.mismatch => 'confirmMismatch',
        LumeAccountFailure.invalidEmail => 'emailInvalid',
        LumeAccountFailure.emailTaken => 'emailTaken',
        LumeAccountFailure.invalidPhone => 'phoneInvalid',
        LumeAccountFailure.nameRequired => 'nameRequired',
        LumeAccountFailure.locked => 'locked',
        LumeAccountFailure.signedOut => 'signedOut',
        LumeAccountFailure.storage => 'storage',
        LumeAccountFailure.unreachable => 'unreachable',
      });

  /// Send whichever form this route holds.
  Future<void> _submit() async {
    if (_form.busy) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAccountRepository repo = ref.read(accountRepositoryProvider);
    _form.beginSubmit();

    try {
      switch (widget.route) {
        case LumeAccountRoute.edit:
          final LumeAccountResult r = await repo.updateIdentity(
            displayName: _form.read('displayName'),
            firstName: _form.read('firstName'),
            lastName: _form.read('lastName'),
            phone: _form.read('phone'),
          );
          if (!_settle(r)) return;
          // A guest's name lives on the device, not on an account.
          if (repo.state != LumeAccountState.authed) {
            _writeProfile(
              _gate.state.profile.copyWith(
                displayName: _form.read('displayName'),
              ),
            );
          }
          _say(l.acctEditSaved);
          await _leave();
        case LumeAccountRoute.email:
          final LumeAccountResult r = await repo.requestEmailChange(
            _form.read('email'),
          );
          if (!_settle(r)) return;
          _say(l.acctEmailPending);
        case LumeAccountRoute.phone:
          final LumeAccountResult r = await repo.updateIdentity(
            phone: _form.read('phone'),
          );
          if (!_settle(r)) return;
          _say(l.acctPhoneSaved);
        case LumeAccountRoute.password:
          final LumeAccountResult r = await repo.changePassword(
            current: _form.read('current'),
            password: _form.read('password'),
            confirm: _form.read('confirm'),
          );
          if (!_settle(r)) return;
          _say(l.authUpdatedTitle);
          await _leave();
        case LumeAccountRoute.delete:
          await _deleteAccount();
        // Every other route is a chooser: it writes on the tap and has
        // nothing to submit.
        case LumeAccountRoute.prefs:
        case LumeAccountRoute.language:
        case LumeAccountRoute.region:
        case LumeAccountRoute.currency:
        case LumeAccountRoute.units:
        case LumeAccountRoute.time:
        case LumeAccountRoute.appearance:
        case LumeAccountRoute.notifications:
        case LumeAccountRoute.library:
        case LumeAccountRoute.account:
        case LumeAccountRoute.security:
        case LumeAccountRoute.sessions:
        case LumeAccountRoute.privacy:
        case LumeAccountRoute.sync:
        case LumeAccountRoute.help:
        case LumeAccountRoute.about:
          _form.endSubmit();
      }
    } on Object {
      _form.refuse(const LumeFormIssue('unreachable'));
    }
  }

  /// True when the write went through. A refusal lands on its own field.
  bool _settle(LumeAccountResult r) {
    if (r.isOk) {
      _form.settle();
      return true;
    }
    _form.refuse(_issueFor(r.failure!), field: r.field);
    return false;
  }

  /// Deletion asks twice: the password here, and then one more confirmation
  /// that is deliberately separate from it.
  Future<void> _deleteAccount() async {
    final AppLocalizations l = AppLocalizations.of(context);
    _form.endSubmit();
    final bool confirmed =
        await _ask(
          title: l.acctDeleteFinalTitle,
          text: l.acctDeleteFinalText,
          confirm: l.acctDeleteCta,
          kind: LumeDeleteKind.irreversible,
        ) ??
        false;
    if (!confirmed || !mounted) return;

    _form.beginSubmit();
    final LumeAccountResult r = await ref
        .read(accountDeletionProvider)
        .deleteAccount(password: _form.read('current'));
    if (!mounted) return;
    if (!_settle(r)) return;
    _say(l.acctDeleted);
    // §37 — the account is gone and the reader's own things are not.
    if (mounted) context.go(widget.branch);
  }

  Future<void> _signOutOthers() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool ok =
        await _ask(
          title: l.acctSignOutOthers,
          text: l.acctSignOutOthersText,
          confirm: l.acctSignOutOthers,
        ) ??
        false;
    if (!ok || !mounted) return;
    final LumeRevokeResult r = await ref
        .read(sessionRepositoryProvider)
        .signOutOthers();
    if (!mounted) return;
    await _readSideData();
    _say(l.acctSignedOutOthers(r.revoked));
  }

  Future<void> _revoke(String id) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeRevokeResult r = await ref
        .read(sessionRepositoryProvider)
        .revoke(id);
    if (!mounted) return;
    if (r.signedOutSelf) {
      // Ending this device's session *is* signing out, and the whole shell
      // has to be told rather than one settings screen.
      _say(l.acctLoggedOut);
      context.go(widget.branch);
      return;
    }
    await _readSideData();
  }

  // -- building ------------------------------------------------------------

  LumeAccountView _view() {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAccountRouteContext c = _context(l);
    // The gate, asked once, in one place.
    if (ref.read(accountRepositoryProvider).requiresAccount(widget.route) &&
        c.state != LumeAccountState.authed) {
      return signedOutView(c, _titleFor(l, widget.route));
    }
    return buildAccountRoute(widget.route, c);
  }

  /// A protected route's own title, so a refusal still says which door it is.
  String _titleFor(AppLocalizations l, LumeAccountRoute route) =>
      switch (route) {
        LumeAccountRoute.account => l.acctPersonalTitle,
        LumeAccountRoute.email => l.acctEmailTitle,
        LumeAccountRoute.phone => l.acctPhoneTitle,
        LumeAccountRoute.security => l.acctSecurityTitle,
        LumeAccountRoute.password => l.acctChangePassword,
        LumeAccountRoute.sessions => l.acctSessionsTitle,
        LumeAccountRoute.delete => l.acctDeleteTitle,
        _ => l.acctPrefsTitle,
      };

  LumeAccountRouteContext _context(AppLocalizations l) {
    final LumeProfileRecord p = _gate.state.profile;
    final String language = Localizations.localeOf(context).languageCode;
    final LumeCountryFixture? table = _gate.state.countries;
    final String countryName = table?.nameOf(p.country, language) ?? p.country;
    final LumeFormatting f = LumeFormatting.of(context, countryCode: p.country);
    final LumeAccountRepository repo = ref.read(accountRepositoryProvider);

    return LumeAccountRouteContext(
      l: l,
      f: f,
      form: _form,
      profile: p,
      state: repo.state,
      identity: repo.identity,
      notify: ref.watch(notificationPrefsProvider).prefs,
      themeMode: ref.watch(themeModeProvider),
      language: LumeLocales.forCode(language).native,
      countryName: countryName,
      regionValue: <String>[
        countryName,
        if (p.city.isNotEmpty) p.city,
        f.currency,
      ].join(' · '),
      // The reader's *market's* currency and zone, from the table the
      // launch read — not the formatter's resolved one, which is already
      // the reader's override where they have set one.
      homeCurrency: table?.currencyOf(p.country) ?? '',
      homeZone: table?.zoneOf(p.country) ?? 'UTC',
      zones: table?.zonesNear(p.country) ?? const <String>[],
      version: kLumeVersion,
      favourites: const <LumeLibraryEntry>[],
      recents: const <LumeLibraryEntry>[],
      sessions: _sessions,
      stored: _stored,
      actions: _actions(l),
    );
  }

  LumeAccountActions _actions(AppLocalizations l) => LumeAccountActions(
    open: (LumeAccountRoute route) =>
        context.push(LumeRoutes.accountRoute(widget.branch, route.segment)),
    openTool: (String id) {
      ref.read(recentToolsProvider).note(id);
      context.go(LumeRoutes.tool(widget.branch, id));
    },
    setLanguage: (String code) =>
        ref.read(localeProvider.notifier).state = Locale(code),
    setCurrency: (String code) =>
        _writeProfile(_gate.state.profile.copyWith(currency: code)),
    setUnits: (LumeUnitsPreference units) =>
        _writeProfile(_gate.state.profile.copyWith(units: units)),
    setClock: (String clock) =>
        _writeProfile(_gate.state.profile.copyWith(clock: clock)),
    setZone: (String? zone) => _writeProfile(
      _gate.state.profile.copyWith(timeZone: zone, clearTimeZone: zone == null),
    ),
    setTheme: (ThemeMode mode) =>
        ref.read(themeModeProvider.notifier).state = mode,
    toggleCategory: (String id, bool on) => unawaited(
      _writeNotify(
        ref.read(notificationPrefsProvider).prefs.toggled(id, on: on),
      ),
    ),
    togglePreview: (bool on) => unawaited(
      _writeNotify(
        ref.read(notificationPrefsProvider).prefs.copyWith(preview: on),
      ),
    ),
    toggleSensitivePreview: (bool on) => unawaited(
      _writeNotify(
        ref
            .read(notificationPrefsProvider)
            .prefs
            .copyWith(sensitivePreview: on),
      ),
    ),
    toggleRecommendations: (bool on) => _writeProfile(
      _gate.state.profile.copyWith(
        prefs: _gate.state.profile.prefs.copyWith(recommendations: on),
      ),
    ),
    editLocation: () => unawaited(showLumeLocationPicker(context)),
    submit: () => unawaited(_submit()),
    signIn: () =>
        context.go(LumeRoutes.authRoute(LumeAuthRoute.signIn.segment)),
    startTour: () => _say(l.acctHelpTour),
    sendFeedback: () => _say(l.acctHelpContact),
    pickPhoto: () => _say(l.acctPhotoNote),
    clearPhoto: () => unawaited(_clearPhoto()),
    clearPhone: () => unawaited(_clearPhone()),
    cancelEmailChange: () => unawaited(_cancelEmailChange()),
    revoke: (String id) => unawaited(_revoke(id)),
    signOutOthers: () => unawaited(_signOutOthers()),
    leaveField: (String name) => _form.leave(name),
  );

  Future<void> _clearPhoto() async {
    await ref.read(accountRepositoryProvider).updateIdentity(photo: '');
    _writeProfile(_gate.state.profile.copyWith(photo: ''));
    if (mounted) setState(() {});
  }

  Future<void> _clearPhone() async {
    final AppLocalizations l = AppLocalizations.of(context);
    await ref.read(accountRepositoryProvider).updateIdentity(phone: '');
    if (!mounted) return;
    _form.reset(<String, String>{'phone': ''});
    _say(l.acctPhoneSaved);
  }

  Future<void> _cancelEmailChange() async {
    await ref.read(accountRepositoryProvider).cancelEmailChange();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAccountView view = _view();

    final Widget screen = PopScope<Object?>(
      // A dirty form is not a screen somebody can be swiped off.
      canPop: !_form.dirty,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        unawaited(_leave());
      },
      child: LumeDestinationPage(
        storageId: 'account/${widget.route.segment}',
        // One host, twenty-one screens: a fixed label announced "Account"
        // whichever one was showing.
        semanticLabel: view.title,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: LumeAccountHost.headerKey,
              child: LumeToolbar(
                title: view.title,
                subtitle: view.subtitle,
                backLabel: l.actionBack,
                onBack: () => unawaited(_leave()),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: LumeAccountHost.bodyKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_form.message != null)
                    LumeMeasure(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: LumeNoteCard(
                          icon: LumeIcons.alert,
                          tone: LumeNoteTone.danger,
                          title: accountMessage(l, _form.message!),
                        ),
                      ),
                    ),
                  ...view.body(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (_toast == null) return screen;
    return Stack(
      children: <Widget>[
        screen,
        Positioned(
          left: 0,
          right: 0,
          bottom: 92 + MediaQuery.paddingOf(context).bottom,
          child: Align(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LumeToast(data: _toast!),
            ),
          ),
        ),
      ],
    );
  }
}
