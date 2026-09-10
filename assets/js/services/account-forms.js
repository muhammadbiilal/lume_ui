/* ============================================================
   Lume — the account form service

   Account and authentication are separate destinations with
   separate back stacks, but the user types into the same forms
   on both. Validation, dirty tracking, submission, the
   confirmation dialog and the account action vocabulary are one
   body of behaviour, so they live here rather than being copied
   into two screens or owned by whichever one is showing.

   The rules this keeps, all of which are about not lying to the
   user:

     · validation starts after interaction, never on the first
       render of an untouched field;
     · error space is reserved, so a message appearing does not
       move the control the user is aiming at;
     · a submission in flight cannot be submitted again;
     · an unknown account and a wrong password are answered
       identically;
     · a dirty form is never abandoned without asking.

   It reaches the two screens through the shell rather than
   importing them, because they reach it the same way and an
   import in both directions would be a cycle.
   ============================================================ */
import { $, $$ } from '../core/dom.js';

export function createAccountForms(ctx) {
  let bound = false;
  let t, L, UI, AUI, ACCT, NOTIFY, GEO, I18N, router, applyStrings, toast, store,
      profile, saveProfile, renderAll, setThemeMode, sheetOpen, sheetClose,
      accountScreen, authScreen, esc, runAct, refreshNotifBadge, startTour,
      renderAccount, renderAuth, openAccount, closeAccount, openAuth, closeAuth,
      authSucceeded, resetNotificationsForAccount;

  function bindShell() {
    if (bound) return;
    bound = true;
    t = ctx.t; L = ctx.L; UI = ctx.ui; AUI = ctx.accountUI; ACCT = ctx.account;
    NOTIFY = ctx.notify; GEO = ctx.geo; I18N = ctx.i18n;
    router = ctx.router; applyStrings = ctx.applyStrings; toast = ctx.toast;
    store = ctx.store; profile = ctx.profile(); saveProfile = ctx.saveProfile;
    renderAll = ctx.renderAll; setThemeMode = ctx.setThemeMode;
    sheetOpen = ctx.sheetOpen; sheetClose = ctx.sheetClose;
    accountScreen = ctx.accountScreen(); authScreen = ctx.authScreen();
    esc = ctx.ui.esc;
    runAct = ctx.runAct; refreshNotifBadge = ctx.refreshNotifBadge;
    startTour = ctx.startTour;

    /* The two hosts, reached the way everything else here is reached: the
       shell holds them, so neither this nor they import the other. */
    renderAccount = function () { accountScreen.render(); };
    renderAuth = function () { authScreen.render(); };
    openAccount = ctx.openAccount;
    closeAccount = function () { accountScreen.close(); };
    openAuth = ctx.openAuth;
    closeAuth = function (dismiss) { authScreen.close(dismiss); };
    authSucceeded = function (message) { authScreen.succeeded(message); };
    resetNotificationsForAccount = function () { authScreen.resetNotifications(); };
  }

  /* ---- forms --------------------------------------------------------- */
  function formHost() {
    return router.current() === 'auth' ? $('#authBody') : $('#accountBody');
  }

  function collectForm() {
    var host = formHost();
    if (!host) return;
    $$('[data-afield]', host).forEach(function (el) {
      AUI.form.values[el.dataset.afield] = el.value;
    });
  }

  function repaintForm() {
    if (router.current() === 'auth') renderAuth(); else renderAccount();
  }

  function fail(result) {
    AUI.form.errors = result.errors || {};
    AUI.form.message = result.form ? { tone: 'error', key: result.form } : null;
    repaintForm();
    /* Announcing three errors at once and leaving focus on the body left the
       user to hunt for which field was wrong (§101). */
    var first = $('[aria-invalid="true"]', formHost());
    if (first && first.focus) { try { first.focus(); } catch (e) {} }
  }

  /* Every submission is a designed loading state before it is a result
     (§124.26). */
  var submitTimer = null;

  function cancelSubmit() {
    if (submitTimer) { clearTimeout(submitTimer); submitTimer = null; }
    AUI.form.busy = false;
  }

  function submitForm(kind) {
    if (AUI.form.busy) return;
    collectForm();
    AUI.form.errors = {};
    AUI.form.message = null;
    AUI.form.busy = true;
    repaintForm();
    submitTimer = setTimeout(function () {
      submitTimer = null;
      AUI.form.busy = false;
      applySubmit(kind, AUI.form.values);
    }, 420);
  }

  /* The two ways a recovery link dies. Both are the link's fault, not the
     password's, and both belong on the error screen (§126.46). */
  var LINK_FAILURES = { 'acct.err.linkInvalid': 1, 'acct.err.linkExpired': 1 };

  function applySubmit(kind, v) {
    var r;

    if (kind === 'signin') {
      r = ACCT.signIn(v);
      if (!r.ok) return fail(r);
      var who = ACCT.displayName();
      return authSucceeded(who ? t('auth.welcomeBack', { name: who }) : t('auth.welcome'));
    }

    /* §126.9 — the identity step is checked by the same engine that will
       check the whole form, so step one can never accept what step two's
       submission would reject. */
    if (kind === 'signupstep') {
      r = ACCT.signUpStep(v);
      if (!r.ok) return fail(r);
      AUI.authCtx.step = 2;
      AUI.authCtx.nav = 'fwd';
      AUI.form.errors = {};
      AUI.form.message = null;
      return renderAuth();
    }

    if (kind === 'signup') {
      r = ACCT.signUp(v);
      if (!r.ok) return fail(r);
      /* §124.29 — notification state belongs to whoever was signed in, and
         the account exists from here, not from the moment the arrival screen
         is dismissed. */
      resetNotificationsForAccount();
      /* §126.13 — the arrival is designed rather than a toast over whatever
         screen happened to be behind. */
      return openAuth('created', { fresh: true });
    }

    if (kind === 'forgot') {
      r = ACCT.requestReset(v.email);
      if (!r.ok) return fail(r);
      AUI.authCtx.token = r.token;
      AUI.authCtx.email = r.email;
      return openAuth('sent');
    }

    if (kind === 'reset') {
      r = ACCT.resetPassword({ token: AUI.authCtx.token, password: v.password, confirm: v.confirm });
      /* §126.34 — a link that cannot be redeemed is not something the user
         can fix by retyping, so it gets a screen with a way out rather than
         a red line above a form that will refuse them again. */
      if (!r.ok && LINK_FAILURES[r.form]) {
        AUI.authCtx.token = null;
        AUI.authCtx.troubleText = r.form === 'acct.err.linkExpired'
          ? 'auth.troubleExpired' : 'auth.troubleText';
        return openAuth('trouble', { fresh: true });
      }
      if (!r.ok) return fail(r);
      AUI.authCtx.token = null;
      return openAuth('updated', { fresh: true });
    }

    if (kind === 'verify') {
      r = ACCT.verifyEmail(v.code);
      if (!r.ok) return fail(r);
      authScreen.release();
      renderAll();
      openAccount('account', { replace: true });
      return toast(t('acct.emailChanged'));
    }

    if (kind === 'edit') {
      r = ACCT.updateUser({
        displayName: v.displayName, firstName: v.firstName,
        lastName: v.lastName, phone: v.phone
      });
      if (!r.ok) return fail(r);
      AUI.form.dirty = false;      /* saved is not unsaved */
      renderAll();
      closeAccount();
      return toast(t('acct.editSaved'));
    }

    if (kind === 'email') {
      r = ACCT.requestEmailChange(v.email);
      if (!r.ok) return fail(r);
      openAuth('verify', { modal: false });
      return;
    }

    if (kind === 'phone') {
      r = ACCT.updateUser({ phone: v.phone });
      if (!r.ok) return fail(r);
      renderAccount();
      return toast(t('acct.phoneSaved'));
    }

    if (kind === 'password') {
      r = ACCT.changePassword({ current: v.current, password: v.password, confirm: v.confirm });
      if (!r.ok) return fail(r);
      closeAccount();
      return toast(t('acct.passwordChanged'));
    }

    if (kind === 'delete') {
      /* §124.22 — identity is confirmed here; the deletion itself waits for
         one more, deliberately separate confirmation. */
      if (!ACCT.verifyPassword(v.current)) {
        return fail({ errors: { current: v.current ? 'acct.err.currentWrong' : 'acct.err.currentRequired' } });
      }
      /* The button was left in its busy state while the dialog was up, and
         `pointer-events: none` then made it permanently dead if the dialog
         was cancelled. */
      repaintForm();
      askConfirm({
        title: t('acct.deleteFinalTitle'), text: t('acct.deleteFinalText'),
        cta: t('acct.deleteCta'), tone: 'danger', act: 'acctdo:deletefinal'
      });
      return;
    }
  }

  /* ---- the confirmation dialog (§124.21, §124.22) --------------------- */
  var confirmAct = null;

  function askConfirm(o) {
    var title = $('#confirmTitle'), text = $('#confirmText');
    var go = $('#confirmGo'), cancel = $('#confirmCancel');
    if (!title || !go) return;
    title.textContent = o.title;
    text.textContent = o.text || '';
    go.textContent = o.cta;
    go.className = 'btn btn--block pressable ' + (o.tone === 'danger' ? 'btn--danger' : 'btn--accent');
    cancel.textContent = t('a.cancel');
    confirmAct = o.act;
    sheetOpen('confirm');
  }

  (function bindConfirm() {
    var go = $('#confirmGo');
    if (!go) return;
    go.addEventListener('click', function () {
      var act = confirmAct;
      confirmAct = null;
      sheetClose();
      if (act) runAct(act);
    });
  })();

  /* ---- the vocabulary ------------------------------------------------- */
  function accountAction(kind, arg) {
    var bits = String(arg).split(':');

    if (kind === 'acct') { openAccount(bits[0]); return true; }
    if (kind === 'auth') { openAuth(bits[0]); return true; }
    if (kind === 'acctsubmit') { submitForm(bits[0]); return true; }

    if (kind === 'acctset') {
      var key = bits.shift(), value = bits.join(':');
      if (key === 'lang') { profile.lang = value; }
      else if (key === 'currency') { profile.currency = value; }
      else if (key === 'units') { profile.units = value; }
      else if (key === 'clock') { profile.clock = value; }
      else if (key === 'tz') { profile.tz = value === 'auto' ? '' : value; }
      else if (key === 'theme') { setThemeMode(value); }
      if (key !== 'theme') saveProfile();
      renderAll();
      renderAccount();
      return true;
    }

    if (kind === 'accttoggle') {
      var p = NOTIFY.prefs();
      if (bits[0] === 'cat') { p.cats[bits[1]] = p.cats[bits[1]] === false; }
      else if (bits[0] === 'recos') { profile.prefs.recos = profile.prefs.recos === false; }
      else { p[bits[0]] = !p[bits[0]]; }
      NOTIFY.prefsChanged();
      saveProfile();
      renderAccount();
      refreshNotifBadge();
      return true;
    }

    if (kind === 'acctdo') { accountDo(bits.shift(), bits.join(':')); return true; }

    return false;
  }

  function accountDo(verb, arg) {
    if (verb === 'tour') { sheetClose(); startTour(); return; }
    if (verb === 'feedback') { toast(t('acct.helpContact')); return; }
    if (verb === 'authclose') { closeAuth(true); return; }

    /* §126.9 — stepping back inside sign-up keeps what was typed. A step is
       not a screen the user is leaving. */
    if (verb === 'signupback') {
      collectForm();
      AUI.authCtx.step = 1;
      AUI.authCtx.nav = 'back';
      AUI.form.errors = {};
      AUI.form.message = null;
      renderAuth();
      return;
    }

    /* The success screen's own way out (§126.13). */
    if (verb === 'authdone') {
      var who = ACCT.displayName();
      authSucceeded(who ? t('auth.welcomeBack', { name: who }) : t('auth.accountCreated'));
      return;
    }

    if (verb === 'resend') {
      var pending = ACCT.user() && ACCT.user().pendingEmail;
      if (pending) ACCT.requestEmailChange(pending);
      /* How long the window is belongs to the screen that draws it, so
         asking again restarts it there rather than here with a second copy
         of the number. */
      authScreen.restartResend();
      toast(t('auth.resent'));
      return;
    }

    if (verb === 'discard') {
      AUI.form.dirty = false;
      /* The navigation the guard held back. The account screen took it, so
         the account screen is what lets it go. */
      accountScreen.resumeGuarded();
      return;
    }

    if (verb === 'logout') {
      askConfirm({ title: t('acct.logoutTitle'), text: t('acct.logoutText'),
                   cta: t('acct.signOut'), tone: 'danger', act: 'acctdo:logoutgo' });
      return;
    }
    if (verb === 'logoutgo') {
      ACCT.signOut();          /* releases the account's notification state */
      renderAll();
      router.go('profile');
      toast(t('acct.loggedOut'));
      return;
    }

    if (verb === 'signoutothers') {
      askConfirm({ title: t('acct.signOutOthers'), text: t('acct.signOutOthersText'),
                   cta: t('acct.signOutOthers'), tone: 'danger', act: 'acctdo:signoutothersgo' });
      return;
    }
    if (verb === 'signoutothersgo') {
      var r = ACCT.signOutOthers();
      renderAccount();
      toast(t('acct.signedOutOthers', { n: L.num(r.revoked || 0) }));
      return;
    }

    if (verb === 'revoke') {
      var rv = ACCT.revokeSession(arg);
      if (rv && rv.self) { renderAll(); router.go('profile'); toast(t('acct.loggedOut')); return; }
      renderAccount();
      return;
    }

    if (verb === 'emailcancel') {
      ACCT.cancelEmailChange();
      if (router.current() === 'auth') { authScreen.release(); openAccount('email', { replace: true }); }
      else renderAccount();
      return;
    }

    if (verb === 'photo') { pickPhoto(); return; }
    if (verb === 'photoclear') {
      ACCT.updateUser({ photo: '' });
      renderAll();
      renderAccount();
      return;
    }

    if (verb === 'deletefinal') {
      var res = ACCT.deleteAccount(AUI.form.values.current);
      if (!res.ok) { fail(res); return; }
      accountScreen.clearStack();
      renderAll();
      router.go('profile');
      toast(t('acct.deleted'));
    }
  }

  /* §124.14 — a real picker, and the file never leaves the device. */
  function pickPhoto() {
    var input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.addEventListener('change', function () {
      var file = input.files && input.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function () {
        shrinkPhoto(String(reader.result), function (small) {
          if (!small) { toast(t('acct.err.photoTooBig')); return; }
          var res = ACCT.updateUser({ photo: small });
          if (!res.ok) { toast(t(res.form || 'acct.err.storage')); return; }
          renderAll();
          renderAccount();
        });
      };
      reader.readAsDataURL(file);
    });
    input.click();
  }

  /* Local storage holds a few megabytes for everything Lume keeps; a photo
     straight off a phone camera is larger than that on its own. This scales
     the longest edge to 256px, and refuses rather than filling the store
     when it cannot. */
  function shrinkPhoto(dataUrl, done) {
    var MAX_RAW = 120000;
    if (dataUrl.length <= MAX_RAW) { done(dataUrl); return; }

    var img = new Image();
    img.onload = function () {
      var canvas = document.createElement('canvas');
      var ctx = canvas.getContext ? canvas.getContext('2d') : null;
      if (!ctx) { done(null); return; }
      var side = 256;
      var scale = Math.min(1, side / Math.max(img.width || side, img.height || side));
      canvas.width = Math.max(1, Math.round((img.width || side) * scale));
      canvas.height = Math.max(1, Math.round((img.height || side) * scale));
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      var out;
      try { out = canvas.toDataURL('image/jpeg', 0.82); } catch (e) { out = null; }
      done(out && out.length < 400000 ? out : null);
    };
    img.onerror = function () { done(null); };
    img.src = dataUrl;
  }

  /* ---- live form behaviour -------------------------------------------- */
  document.addEventListener('input', function (e) {
    var el = e.target.closest ? e.target.closest('[data-afield]') : null;
    if (!el) return;
    var name = el.dataset.afield;
    AUI.form.values[name] = el.value;

    /* The checklist and the meter follow the keystrokes; repainting the
       whole form here would take the caret with it. */
    var rules = $('[data-pwrules="' + name + '"]');
    if (rules) {
      ACCT.passwordChecks(el.value).forEach(function (c) {
        var row = $('[data-rule="' + c.id + '"]', rules);
        if (row) row.classList.toggle('is-ok', c.ok);
      });
    }
    var meter = $('[data-pwmeter="' + name + '"]');
    if (meter) {
      var st = ACCT.passwordStrength(el.value);
      meter.dataset.tone = st.tone;
      $$('.pwmeter__seg', meter).forEach(function (seg, i) {
        seg.classList.toggle('is-on', i < st.score);
      });
      var label = $('.pwmeter__label', meter);
      if (label) label.textContent = t(st.key);
    }

    var field = el.closest('.field');
    if (field) {
      /* §126.39 — editing a field withdraws the complaint about it, and the
         message line empties without collapsing, so nothing below moves. */
      field.classList.remove('is-invalid');
      field.classList.remove('is-valid');
      field.classList.toggle('is-filled', el.value !== '');
      delete AUI.form.errors[name];
      delete AUI.form.valid[name];
      var msg = $('.field__msg', field);
      if (msg && msg.classList.contains('field__err')) {
        msg.className = 'field__msg field__hint';
        msg.removeAttribute('role');
        msg.textContent = '';
        el.removeAttribute('aria-invalid');
      }
    }
    updateDirty();
  });

  /* §126.39 — nothing is judged on first render. A field is checked once the
     user has finished with it, and the whole form is checked on submission.
     Only the two checks that can be made in isolation happen here: whether
     an address is an address, and whether a confirmation matches. */
  var LEAVE_CHECKS = {
    email: function (v) {
      if (!v) return null;
      return ACCT.emailValid(v) ? true : 'acct.err.emailInvalid';
    },
    confirm: function (v) {
      if (!v) return null;
      return v === (AUI.form.values.password || '') ? true : 'acct.err.confirmMismatch';
    }
  };

  document.addEventListener('focusout', function (e) {
    var el = e.target.closest ? e.target.closest('[data-afield]') : null;
    if (!el || router.current() !== 'auth') return;
    var name = el.dataset.afield;
    var check = LEAVE_CHECKS[name];
    if (!check) return;
    AUI.form.touched[name] = true;
    var verdict = check(el.value);
    if (verdict === null) return;
    var field = el.closest('.field');
    if (!field) return;
    if (verdict === true) {
      AUI.form.valid[name] = true;
      markValid(field, el);
      return;
    }
    AUI.form.errors[name] = verdict;
    markInvalid(field, el, verdict);
  });

  /* §126.15 — a field that passed says so with a mark as well as a border,
     because a border is a colour and a colour on its own is not a signal.
     A password field keeps its reveal control instead: two glyphs in one box
     is clutter, and the rules underneath already report on it. */
  function markValid(field, el) {
    field.classList.remove('is-invalid');
    field.classList.add('is-valid');
    el.removeAttribute('aria-invalid');
    var box = $('.field__box', field);
    if (!box || $('.pwtoggle', box) || $('.field__ok', box)) return;
    var tick = document.createElement('span');
    tick.className = 'field__ok';
    tick.setAttribute('aria-hidden', 'true');
    tick.innerHTML = '<svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg>';
    box.appendChild(tick);
  }

  /* The field is corrected where it stands. A repaint here would take the
     caret and the focus with it, at the moment the user is moving on. */
  function markInvalid(field, el, key) {
    field.classList.remove('is-valid');
    field.classList.add('is-invalid');
    el.setAttribute('aria-invalid', 'true');
    var msg = $('.field__msg', field);
    if (!msg) return;
    msg.className = 'field__msg field__err';
    msg.setAttribute('role', 'alert');
    msg.innerHTML = '<svg class="ico" viewBox="0 0 24 24" aria-hidden="true"><use href="#i-alert"/></svg>' +
      esc(t(key));
  }

  /* §126.38 — when the software keyboard opens, the panel keeps its own
     bottom above it, so the field being typed into and the button that
     submits it are never underneath it. */
  (function keyboardInset() {
    var vv = window.visualViewport;
    if (!vv) return;
    var apply = function () {
      var hidden = Math.max(0, window.innerHeight - vv.height - vv.offsetTop);
      var el = $('#authBody .auth__panel');
      if (el) el.style.setProperty('--auth-kb', hidden > 80 ? hidden + 'px' : '0px');
      var focused = document.activeElement;
      if (hidden > 80 && focused && focused.dataset && focused.dataset.afield && focused.scrollIntoView) {
        try { focused.scrollIntoView({ block: 'center', behavior: 'smooth' }); } catch (err) {}
      }
    };
    vv.addEventListener('resize', apply);
    vv.addEventListener('scroll', apply);
  })();

  /* §124.18 — Save stays inert until something actually changed. */
  function updateDirty() {
    var f = AUI.form, changed = false, k;
    for (k in f.base) {
      if (Object.prototype.hasOwnProperty.call(f.base, k) &&
          String(f.values[k] === undefined ? '' : f.values[k]) !== String(f.base[k] === undefined ? '' : f.base[k])) {
        changed = true;
      }
    }
    f.dirty = changed;
    var btn = $('#accountBody [data-act="acctsubmit:edit"]');
    if (btn) btn.disabled = !changed;
    var hint = $('#accountBody .dirtyhint');
    if (hint) hint.hidden = changed;
  }

  document.addEventListener('click', function (e) {
    var b = e.target.closest('[data-pwtoggle]');
    if (!b) return;
    e.preventDefault();                 /* the toggle sits inside a label */
    var name = b.dataset.pwtoggle;
    var input = $('[data-afield="' + name + '"]', formHost());
    if (!input) return;
    var show = input.type === 'password';
    input.type = show ? 'text' : 'password';
    /* Kept in form state so a failed submission — which repaints the form —
       does not re-mask what the user asked to see. */
    AUI.setRevealed(name, show);
    b.setAttribute('aria-pressed', show ? 'true' : 'false');
    b.setAttribute('aria-label', t(show ? 'acct.pw.hide' : 'acct.pw.show'));
    b.innerHTML = '<svg class="ico" viewBox="0 0 24 24"><use href="#' + (show ? 'i-eye-off' : 'i-eye') + '"/></svg>';
  });

  /* §101 — a radio group is one tab stop, and the arrows move within it. */
  document.addEventListener('keydown', function (e) {
    var opt = e.target.closest ? e.target.closest('.optlist [role="radio"]') : null;
    if (!opt) return;
    var keys = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 };
    var step = keys[e.key];
    if (!step) return;
    var group = opt.closest('.optlist');
    var all = $$('[role="radio"]', group);
    var at = all.indexOf(opt);
    /* Left and right follow the reading direction. */
    if (L.dir() === 'rtl' && (e.key === 'ArrowRight' || e.key === 'ArrowLeft')) step = -step;
    var next = all[(at + step + all.length) % all.length];
    if (!next) return;
    e.preventDefault();
    all.forEach(function (r) { r.setAttribute('tabindex', '-1'); });
    next.setAttribute('tabindex', '0');
    next.focus();
    next.click();
  });

  /* Enter submits the form it is typed in. */
  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Enter') return;
    var el = e.target.closest ? e.target.closest('[data-afield]') : null;
    if (!el) return;
    var host = formHost();
    var submit = host ? $('[data-act^="acctsubmit:"]', host) : null;
    if (submit && !submit.disabled) { e.preventDefault(); submit.click(); }
  });


  return {
    action: function (kind, arg) { bindShell(); return accountAction(kind, arg); },
    /* The one account verb authentication performs for itself. */
    perform: function (verb, arg) { bindShell(); return accountDo(verb, arg); },
    cancelSubmit: function () { bindShell(); cancelSubmit(); },
    askConfirm: function (o) { bindShell(); askConfirm(o); },
    updateDirty: function () { bindShell(); updateDirty(); },
    repaint: function () { bindShell(); repaintForm(); }
  };
}
