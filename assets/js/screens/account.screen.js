/* ============================================================
   Lume — Account screen

   A host for the nested settings screens rather than a screen
   of its own: profile editing, security, sessions, language,
   appearance, region, units, time, currency, notifications,
   data and deletion all render into it.

   Two things it owns and the settings screens do not.

   Its own back stack, so Back inside a section returns to the
   section above it and only leaves the account once there is
   nothing left to return to.

   The unsaved-changes guard. Every route change and every
   departure asks it first, which is why guardDirty is here and
   not in whichever form happens to be dirty.

   What it does not own is the account engine. Persistence,
   passwords and sessions belong to the service; this decides
   what is on screen.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $, esc } from '../core/dom.js';

export function createAccountScreen(ctx) {
  let bound = false;
  let t, L, UI, AUI, ACCT, router, applyStrings, showScreen, homeTab, openAuth,
      cancelSubmit, askConfirm, applyVisibility, animateBars;

  function bindShell() {
    if (bound) return;
    bound = true;
    t = ctx.t; L = ctx.L; UI = ctx.ui; AUI = ctx.accountUI; ACCT = ctx.account;
    router = ctx.router; applyStrings = ctx.applyStrings;
    showScreen = function (name) { router.go(name, { quiet: true }); };
    homeTab = function () { return router.currentTab('profile'); };
    openAuth = ctx.openAuth;
    applyVisibility = ctx.applyVisibility; animateBars = ctx.animateBars;
    cancelSubmit = ctx.forms.cancelSubmit;
    askConfirm = ctx.forms.askConfirm;
  }

  var accountRoute = null, accountStack = [], accountReturn = 'profile';

  function enterAccountRoute(route) {
    accountRoute = route;
    var def = AUI.ROUTES[route]();
    AUI.resetForm(def.values || {});
    showScreen('account');
    renderAccount();
  }

  var pendingNav = null;

  /* §124.14's dirty state is only honest if leaving respects it. */
  function guardDirty(go) {
    if (!AUI.form.dirty) { go(); return; }
    pendingNav = go;
    askConfirm({ title: t('acct.discardTitle'), text: t('acct.discardText'),
                 cta: t('acct.discardCta'), tone: 'danger', act: 'acctdo:discard' });
  }

  function openAccount(route, opts) {
    opts = opts || {};
    if (!AUI.ROUTES[route]) return;
    if (accountRoute && accountRoute !== route && AUI.form.dirty) {
      guardDirty(function () { openAccount(route, opts); });
      return;
    }

    /* §124.28 — a destination that belongs to the account is held across
       authentication and resumed afterwards, never swapped for Home. */
    if (ACCT.requiresAccount(route) && !ACCT.isAuthed()) {
      openAuth('signin', { modal: true, then: 'acct:' + route });
      return;
    }

    if (accountRoute && !opts.replace) accountStack.push(accountRoute);
    else if (!accountRoute) accountReturn = homeTab();
    enterAccountRoute(route);
  }

  function renderAccount() {
    var head = $('#accountHeader'), body = $('#accountBody');
    if (!head || !body || !accountRoute) return;
    var built = AUI.ROUTES[accountRoute]();
    head.innerHTML = UI.toolHeader({
      title: built.title, sub: built.sub ? esc(built.sub) : null, backLabel: t('a11y.back')
    });
    /* One host, a dozen screens: a fixed label announced "Account" whichever
       one was showing (§101). */
    var host = $('#screen-account');
    if (host) host.setAttribute('aria-label', built.title);
    body.innerHTML = built.body;
    applyStrings(body);
    applyVisibility();
    if (built.after) built.after();
    animateBars($('#screen-account'));
  }

  function closeAccount() {
    if (AUI.form.dirty) { guardDirty(closeAccount); return; }
    cancelSubmit();
    if (accountStack.length) { enterAccountRoute(accountStack.pop()); return; }
    accountRoute = null;
    router.go(accountReturn || 'profile');
  }


  return defineScreen({
    id: 'account',
    template: function () {
      return `
  <section class="screen screen--tool" id="screen-account" role="region" aria-label="Account">
    <div id="accountHeader"></div>
    <div id="accountBody"></div>
  </section>
`;
    },

    render: function () {
      bindShell();
      renderAccount();
    },

    /* A route does not survive leaving the account. The shell used to clear
       it from inside its navigation function, which meant only navigation
       that went through that function cleared it. */
    onLeave: function () {
      accountRoute = null;
      accountStack.length = 0;
    },

    open: function (route, opts) { bindShell(); openAccount(route, opts); },
    close: function () { bindShell(); closeAccount(); },
    guardDirty: function (go) { bindShell(); return guardDirty(go); },
    /* Let go of the navigation guardDirty held back, once the user has
       agreed to lose the edit. */
    resumeGuarded: function () {
      const go = pendingNav;
      pendingNav = null;
      if (go) go();
    },
    route: function () { return accountRoute; },
    /* Where the account section currently is, for an authentication flow
       entered from inside it that has to come back to the same place. */
    hold: function () { return { route: accountRoute, stack: accountStack.slice() }; },
    enter: function (route) { bindShell(); enterAccountRoute(route); },
    /* Resume a destination that was held across authentication, stack and
       all, so Back from it goes where it would have gone before. */
    restore: function (route, stack) {
      bindShell();
      accountStack = stack || [];
      enterAccountRoute(route);
    },
    clearStack: function () { accountStack.length = 0; accountRoute = null; }
  });
}
