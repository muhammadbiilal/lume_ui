/* ============================================================
   Lume — Authentication screen

   A flow, not a utility. It never enters the tool router, the
   catalogue or search, and it has its own back stack because
   sign-in and sign-up are siblings rather than one nested
   inside the other.

   What this screen is responsible for is presentation and the
   feedback around it: which flow is showing, when validation
   starts, the resend countdown, and where a completed flow
   returns the user to. Credentials, digests and sessions belong
   to the account engine — the prototype one, which is not
   production security and does not pretend to be.

   A success screen deliberately offers no route back into the
   flow behind it.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $ } from '../core/dom.js';

export function createAuthScreen(ctx) {
  let bound = false;
  let t, L, UI, AUI, ACCT, NOTIFY, router, applyStrings, showScreen, homeTab,
      openAccount, cancelSubmit, toast, store, applyVisibility, saveProfile,
      renderAll, refreshNotifBadge, runAct, accountDo, enterAccountRoute, profile,
      forgetPrayerTimes;

  function bindShell() {
    if (bound) return;
    bound = true;
    t = ctx.t; L = ctx.L; UI = ctx.ui; AUI = ctx.accountUI; ACCT = ctx.account;
    NOTIFY = ctx.notify; router = ctx.router; applyStrings = ctx.applyStrings;
    showScreen = function (name) { router.go(name, { quiet: true }); };
    homeTab = function () { return router.currentTab('profile'); };
    openAccount = ctx.openAccount;
    cancelSubmit = ctx.forms.cancelSubmit;
    toast = ctx.toast; store = ctx.store;
    applyVisibility = ctx.applyVisibility; saveProfile = ctx.saveProfile;
    renderAll = ctx.renderAll; refreshNotifBadge = ctx.refreshNotifBadge;
    runAct = ctx.runAct; profile = ctx.profile();
    /* Signing in can change the city, and prayer times are cached against
       it. Dropping the cache is the shell's to do, because the shell is
       what holds it. */
    forgetPrayerTimes = ctx.forgetPrayerTimes;
    /* Returning to a held account destination after signing in, and the
       one account verb authentication itself performs. Both belong to the
       account surfaces, so they are borrowed rather than duplicated. */
    accountDo = function (verb, arg) { return ctx.forms.perform(verb, arg); };
    enterAccountRoute = function (route) { ctx.accountScreen().enter(route); };
  }

  var authRoute = null, authStack = [], authReturn = 'profile';
  /* Where the flow was entered from, so it can be returned to. */
  var authFromAccount = null, authFromStack = null;

  /* The empty shape each flow starts from. A flow always begins from a
     copy of this, so a half-typed sign-up cannot leak into a sign-in. */
  var AUTH_VALUES = {
    signin: { email: '', password: '' },
    signup: { name: '', email: '', password: '', confirm: '' },
    forgot: { email: '' },
    reset:  { password: '', confirm: '' },
    verify: { code: '' }
  };

  /* ---- authentication ------------------------------------------------ */
  function openAuth(route, opts) {
    opts = opts || {};
    if (!AUI.AUTH[route]) return;
    if (opts.then !== undefined) AUI.authCtx.pending = opts.then;
    if (opts.modal !== undefined) AUI.authCtx.modal = !!opts.modal;

    if (!authRoute) {
      authReturn = homeTab();
      /* An authentication flow entered from inside the account section comes
         back to the screen that sent it there, not to the top (§124.25). */
      var held = ctx.accountScreen().hold();
      authFromAccount = held.route;
      authFromStack = held.stack;
    } else if (route !== authRoute) {
      /* Sign in and sign up are siblings, not levels: hopping between them
         used to stack, so escaping took one press per hop. */
      var at = authStack.indexOf(route);
      if (at !== -1) authStack.length = at;
      else authStack.push(authRoute);
    }

    /* An outcome is not a step. Nothing behind "your account is ready" is
       worth returning to, so the flow's history ends there (§126.30). */
    if (opts.fresh) authStack.length = 0;

    authRoute = route;
    /* §126.30 — forward navigation and backward navigation are different
       transitions, so the shell is told which one it is. */
    AUI.authCtx.nav = opts.back ? 'back' : 'fwd';
    /* §126.9 — a sign-up always starts at its first step. */
    if (route === 'signup') AUI.authCtx.step = 1;
    /* §126.12 — the resend window opens when the screen does. */
    if (route === 'verify') AUI.authCtx.resendAt = Date.now() + RESEND_WAIT;
    AUI.resetForm(AUTH_VALUES[route] ? JSON.parse(JSON.stringify(AUTH_VALUES[route])) : {});
    showScreen('auth');
    renderAuth();
  }

  /* ---- the resend countdown (§126.12) ---------------------------------
     A number that counts down is only honest if it moves. */
  var RESEND_WAIT = 45000;
  var resendTimer = null;

  /* The countdown stops when the screen goes away, not only when the wait
     ends: a verification left behind used to keep ticking against a node
     that was no longer on screen. */
  function stopResend() {
    if (resendTimer) { clearInterval(resendTimer); resendTimer = null; }
  }

  function tickResend() {
    if (resendTimer) { clearInterval(resendTimer); resendTimer = null; }
    if (authRoute !== 'verify') return;
    if (!$('[data-resend]')) return;
    resendTimer = setInterval(function () {
      var el = $('[data-resend]');
      if (authRoute !== 'verify' || !el) { clearInterval(resendTimer); resendTimer = null; return; }
      var left = Math.max(0, Math.ceil((AUI.authCtx.resendAt - Date.now()) / 1000));
      if (left > 0) { el.textContent = t('auth.resendIn', { s: left }); return; }
      clearInterval(resendTimer);
      resendTimer = null;
      renderAuth();                     /* the wait is over: offer the action */
    }, 1000);
  }

  function renderAuth() {
    var body = $('#authBody');
    if (!body || !authRoute) return;
    var authHost = $('#screen-auth');
    /* §126.44 — the shell is the screen's own; every route returns the whole
       composition rather than a fragment someone else wraps. */
    body.innerHTML = AUI.AUTH[authRoute]();
    var authTitle = $('.auth__title', body);
    if (authHost && authTitle) authHost.setAttribute('aria-label', authTitle.textContent);
    applyStrings(body);
    applyVisibility();
    tickResend();
  }

  function closeAuth(dismiss) {
    /* A cross dismisses the whole flow; a back chevron steps through it. The
       two were the same control, so the X on a modal sign-in behaved as Back
       and took two presses to escape (§124.25). */
    /* Escape and the shell's own Back step through a progressive form the
       same way its Back control does — leaving the flow from step two would
       throw away step one (§126.9). */
    if (authRoute === 'signup' && AUI.authCtx.step === 2 && !dismiss) {
      accountDo('signupback');
      return;
    }
    if (authStack.length && !dismiss) {
      authRoute = authStack.pop();
      AUI.authCtx.nav = 'back';
      if (authRoute === 'signup') AUI.authCtx.step = 1;
      AUI.resetForm(AUTH_VALUES[authRoute] ? JSON.parse(JSON.stringify(AUTH_VALUES[authRoute])) : {});
      renderAuth();
      return;
    }
    if (resendTimer) { clearInterval(resendTimer); resendTimer = null; }
    /* Choosing to stay a guest ends the expired session rather than
       leaving it to interrupt again on the next launch (§124.27). */
    if (authRoute === 'expired') ACCT.signOut();
    var to = authReturn || 'profile';
    var backTo = authFromAccount;
    var backStack = authFromStack;
    authRoute = null;
    authStack.length = 0;
    authFromAccount = null;
    authFromStack = null;
    AUI.authCtx.pending = null;
    AUI.authCtx.modal = false;
    if (backTo && AUI.ROUTES[backTo]) {
      /* A destination held across authentication is resumed exactly where
         it was, with the stack that led to it. */
      ctx.accountScreen().restore(backTo, backStack || []);
      renderAll();
      return;
    }
    router.go(to);
    renderAll();
  }

  /* §124.29 — notification state belongs to whoever was signed in. */
  function resetNotificationsForAccount() {
    profile.notifyRead = {};
    profile.notifyActed = {};
    profile.notifyGone = {};
    profile.notifySeen = {};
    if (profile.notify) profile.notify.push = false;
    NOTIFY.prefsChanged();
    saveProfile();
    refreshNotifBadge();
  }

  function authSucceeded(message) {
    var pending = AUI.authCtx.pending;
    AUI.authCtx.pending = null;
    AUI.authCtx.modal = false;
    AUI.authCtx.token = null;      /* a recovery link does not outlive its flow */
    AUI.authCtx.step = 1;
    if (resendTimer) { clearInterval(resendTimer); resendTimer = null; }
    authRoute = null;
    authStack.length = 0;
    resetNotificationsForAccount();
    forgetPrayerTimes();
    saveProfile();
    renderAll();
    router.go(pending ? 'profile' : (authReturn || 'profile'));
    if (pending) runAct(pending);
    if (message) toast(message);
  }


  return defineScreen({
    id: 'auth',
    template: function () {
      return `
  <section class="screen screen--auth" id="screen-auth" role="region" aria-label="Sign in">
    <div id="authBody"></div>
  </section>
`;
    },

    render: function () {
      bindShell();
      renderAuth();
    },

    onLeave: function () {
      authRoute = null;
      authStack.length = 0;
      stopResend();
    },

    open: function (route, opts) { bindShell(); openAuth(route, opts); },
    close: function (dismiss) { bindShell(); closeAuth(dismiss); },
    succeeded: function (message) { bindShell(); authSucceeded(message); },
    resetNotifications: function () { bindShell(); resetNotificationsForAccount(); },
    route: function () { return authRoute; },
    /* End the flow without navigating: the caller is about to send the
       user somewhere itself, and a flow left standing behind it would be
       returned to by the next Back. */
    release: function () { authRoute = null; authStack.length = 0; stopResend(); },
    /* Open a fresh resend window and redraw, so the countdown starts over. */
    restartResend: function () {
      bindShell();
      AUI.authCtx.resendAt = Date.now() + RESEND_WAIT;
      renderAuth();
    },
    values: function () { return AUTH_VALUES; }
  });
}
