/* Account, identity, authentication and settings (Master Spec §124, §125).

   Two things are under test here. The first is the lifecycle: onboarding,
   guest, sign up, sign in, recovery, security, deletion. The second is the
   rule that produced it — that no screen ever shows an identity the product
   does not hold. Every assertion below failed against the build that said
   "You're ready, Zeeshan". */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');

const ROOT = path.resolve(__dirname, '..');
let failures = 0;

function ok(label, cond, extra) {
  console.log((cond ? '  ok   ' : '  FAIL ') + label + (cond ? '' : '  -> ' + (extra || '')));
  if (!cond) failures++;
}

const wait = ms => new Promise(r => setTimeout(r, ms));

async function boot(opts) {
  opts = opts || {};
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const vc = new VirtualConsole();
  const errors = [];
  vc.on('jsdomError', e => errors.push(String(e.message || e)));
  const dom = new JSDOM(html, {
    url: 'http://localhost/index.html', runScripts: 'dangerously',
    virtualConsole: vc, pretendToBeVisual: true,
    beforeParse(window) {
      if (opts.onboarded !== false) window.localStorage.setItem('lume-onboarded', '1');
      window.localStorage.setItem('lume-profile', JSON.stringify(Object.assign({
        units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
        interests: ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news', 'markets'],
        prefs: { news: true, cricket: true, finance: true, recos: true },
        recents: [], favourites: [], recentCountries: []
      }, opts.profile || {})));
      if (opts.storage) {
        for (const k of Object.keys(opts.storage)) window.localStorage.setItem(k, opts.storage[k]);
      }
      window.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
      window.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      window.HTMLCanvasElement.prototype.getContext = () => null;
      window.navigator.vibrate = () => true;
      window.URL.createObjectURL = () => 'blob:stub';
      window.URL.revokeObjectURL = () => {};
    }
  });
  for (const src of [...dom.window.document.querySelectorAll('script[src]')].map(s => s.getAttribute('src'))) {
    dom.window.eval(fs.readFileSync(path.join(ROOT, src), 'utf8'));
  }
  await wait(80);
  return { dom, win: dom.window, doc: dom.window.document, errors };
}

/* ---- driving the real DOM ---------------------------------------------- */
const hit = (win, el) => el && el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));
const $ = (doc, sel) => doc.querySelector(sel);
const $$ = (doc, sel) => [...doc.querySelectorAll(sel)];
const screenId = doc => ((doc.querySelector('.screen.is-active') || {}).id || '').replace('screen-', '');
const text = el => (el ? el.textContent.replace(/\s+/g, ' ').trim() : '');

/* Actions the product speaks, dispatched the way the product dispatches them. */
function act(win, a) {
  const b = win.document.createElement('button');
  b.setAttribute('data-act', a);
  win.document.body.appendChild(b);
  b.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));
  b.remove();
}

function type(win, name, value) {
  const el = win.document.querySelector('[data-afield="' + name + '"]');
  if (!el) return false;
  el.value = value;
  el.dispatchEvent(new win.Event('input', { bubbles: true }));
  return true;
}

async function submit(win, kind) {
  const btn = win.document.querySelector('[data-act="acctsubmit:' + kind + '"]');
  if (!btn) return false;
  hit(win, btn);
  await wait(620);
  return true;
}

async function fillSignUp(win, { name, email, password, confirm }) {
  act(win, 'auth:signup');
  await wait(60);
  if (name !== undefined) type(win, 'name', name);
  if (email !== undefined) type(win, 'email', email);
  if (password !== undefined) type(win, 'password', password);
  if (confirm !== undefined) type(win, 'confirm', confirm);
  await submit(win, 'signup');
}

/* Text that reached the eye, not text that exists in the file. */
function visibleText(doc) {
  return $$(doc, '.screen.is-active, .sheet.is-open, .onb:not([hidden])')
    .map(el => el.textContent).join(' ').replace(/\s+/g, ' ');
}

(async () => {
  /* ═══ 1. Onboarding never invents a name (§124.4, §124.5, §125) ═══════ */
  console.log('\n=== Onboarding: the name is asked for, or it does not exist ===');
  let { win, doc } = await boot({ onboarded: false });

  ok('onboarding runs on a first launch', !$(doc, '#onb').hidden);
  ok('nothing on the completion screen names anyone',
     !/Zeeshan/.test(doc.body.innerHTML), 'a placeholder identity survived');

  /* Walk the tour to the name step. */
  const nextBtns = () => $$(doc, '.onb-step.is-active [data-onb-next], .onb-step.is-active #onbPickNext');
  for (let i = 0; i < 7; i++) {
    const b = nextBtns()[0];
    if (!b || b.disabled) break;
    hit(win, b);
    await wait(40);
  }
  const nameStep = $(doc, '.onb-step.is-active');
  ok('the tour reaches a step that asks for a name',
     !!nameStep && !!$(doc, '#onbName'), nameStep ? nameStep.dataset.step : 'no step');
  ok('the name field starts empty', ($(doc, '#onbName') || {}).value === '',
     ($(doc, '#onbName') || {}).value);

  /* Skipping is a first-class outcome. */
  hit(win, $(doc, '#onbNameSkip'));
  await wait(60);
  const doneTitle = text($(doc, '#onbDoneTitle'));
  ok('skipping the name gives the neutral completion',
     doneTitle === 'You’re all set' || doneTitle === "You're all set", doneTitle);
  ok('the neutral completion contains no name and no dangling comma',
     !/,\s*$/.test(doneTitle) && !/undefined|null/.test(doneTitle), doneTitle);

  /* Now go back and give one. */
  hit(win, $(doc, '#onbBack'));
  await wait(60);
  type(win, 'x', 'x');                       /* no-op: proves the helper is safe */
  const nameInput = $(doc, '#onbName');
  nameInput.value = 'Muhammad';
  nameInput.dispatchEvent(new win.Event('input', { bubbles: true }));
  hit(win, $(doc, '#onbNameNext'));
  await wait(60);
  ok('a name that was typed is used on the completion screen',
     /Muhammad/.test(text($(doc, '#onbDoneTitle'))), text($(doc, '#onbDoneTitle')));

  hit(win, $(doc, '#onbFinish'));
  await wait(80);
  ok('the greeting uses the name the user gave',
     /Muhammad/.test(text($(doc, '#greetText'))), text($(doc, '#greetText')));
  ok('the app-bar avatar shows initials derived from that name',
     text($(doc, '#appbarAvatar')) === 'M', text($(doc, '#appbarAvatar')));
  win.close();

  /* ═══ 2. No name is a designed state, not a broken one (§125) ═════════ */
  console.log('\n=== No name: the neutral branch ===');
  ({ win, doc } = await boot());
  ok('the greeting stands alone when Lume has no name',
     !/,/.test(text($(doc, '#greetText'))), text($(doc, '#greetText')));
  ok('the app-bar avatar falls back to a glyph, not invented initials',
     text($(doc, '#appbarAvatar')) === '' && !!$(doc, '#appbarAvatar svg'),
     text($(doc, '#appbarAvatar')));
  ok('no placeholder identity anywhere in the shell',
     !/Zeeshan|trillo\.io|zeeshan@/i.test(doc.body.innerHTML));

  /* ═══ 3. Profile as a guest (§124.7) ═════════════════════════════════ */
  console.log('\n=== Profile: the guest composition ===');
  hit(win, $(doc, '[data-tab="profile"]'));
  await wait(60);
  const wanted = win.LUME_SPEC.COMPOSITIONS.profile;
  const order = $$(doc, '#profileBody [data-sect]').map(x => x.dataset.sect)
    .filter(x => wanted.indexOf(x) !== -1);
  ok('the profile keeps its approved composition (§123, §124.7)',
     order.slice(0, wanted.length).join('>') === wanted.join('>'),
     order.join(' > ') + ' vs ' + wanted.join(' > '));
  ok('a guest is offered an account', !!$(doc, '#profileBody [data-act="auth:signup"]'));
  ok('a guest is offered sign in', !!$(doc, '#profileBody [data-act="auth:signin"]'));
  ok('a guest is not shown a log-out row', !$(doc, '#profileBody [data-act="acctdo:logout"]'));
  ok('a guest is not shown an email address',
     !/@/.test(text($(doc, '#profileBody .phead'))), text($(doc, '#profileBody .phead')).slice(0, 90));
  ok('no statistic is shown that nothing produced',
     !/64|Member since/.test(text($(doc, '#profileBody .phead'))),
     text($(doc, '#profileBody .phead')).slice(0, 120));

  /* Every settings row leads somewhere (§124.30). */
  const deadRows = $$(doc, '#profileBody .list-row').filter(r => !r.dataset.act && !r.dataset.sheet);
  ok('every settings row has a destination', deadRows.length === 0,
     deadRows.map(r => text(r)).join(' | '));

  /* ═══ 4. Sign up: validation before acceptance (§124.9) ══════════════ */
  console.log('\n=== Sign up ===');
  act(win, 'auth:signup');
  await wait(60);
  ok('the sign-up screen opens', screenId(doc) === 'auth', screenId(doc));
  ok('the password rules are shown before submission', !!$(doc, '[data-pwrules="password"]'));

  await submit(win, 'signup');
  ok('an empty sign-up reports the email inline',
     !!$(doc, '.field.is-invalid [data-afield="email"]'));
  ok('an empty sign-up reports the password inline',
     !!$(doc, '.field.is-invalid [data-afield="password"]'));
  ok('errors are inline, not only a toast', $$(doc, '.field__err').length >= 2,
     $$(doc, '.field__err').length + ' inline errors');

  type(win, 'email', 'not-an-email');
  type(win, 'password', 'Password1');
  type(win, 'confirm', 'Password1');
  await submit(win, 'signup');
  ok('an invalid email is caught', /email address/i.test(text($(doc, '.field__err'))),
     text($(doc, '.field__err')));

  type(win, 'email', 'muhammad@example.com');
  type(win, 'password', 'short');
  type(win, 'confirm', 'short');
  await submit(win, 'signup');
  ok('a password that misses the rules is refused',
     /requirements/i.test(visibleText(doc)), text($(doc, '.field__err')));

  type(win, 'password', 'Password1');
  type(win, 'confirm', 'Password2');
  await submit(win, 'signup');
  ok('a mismatched confirmation is refused', /don’t match|don't match/i.test(visibleText(doc)),
     text($(doc, '.field__err')));

  /* The live checklist tracks what is typed. */
  type(win, 'password', 'Password1');
  await wait(30);
  const rulesOn = $$(doc, '[data-pwrules="password"] .pwrule.is-ok').length;
  ok('the checklist ticks as the rules are met', rulesOn === 4, rulesOn + ' of 4');

  type(win, 'name', 'Muhammad Bilal');
  type(win, 'confirm', 'Password1');
  await submit(win, 'signup');
  ok('a valid sign-up creates the account', win.LUME_ACCT.isAuthed(), win.LUME_ACCT.state());
  ok('the account carries the name that was given',
     win.LUME_ACCT.fullName() === 'Muhammad Bilal', win.LUME_ACCT.fullName());
  ok('sign-up lands somewhere designed, not on a blank screen',
     ['home', 'profile'].indexOf(screenId(doc)) !== -1, screenId(doc));

  /* ═══ 5. Profile as an account holder (§124.7) ═══════════════════════ */
  hit(win, $(doc, '[data-tab="profile"]'));
  await wait(60);
  ok('the profile now shows the real name',
     /Muhammad Bilal/.test(text($(doc, '#profileBody .phead'))));
  ok('the profile shows the real email',
     /muhammad@example\.com/.test(text($(doc, '#profileBody .phead'))));
  ok('the avatar shows initials from the real name',
     text($(doc, '#profileBody .pavatar')) === 'MB', text($(doc, '#profileBody .pavatar')));
  ok('an account holder is offered Edit profile', !!$(doc, '[data-act="acct:edit"]'));
  ok('an account holder is offered log out', !!$(doc, '[data-act="acctdo:logout"]'));
  ok('the composition does not change with the account state',
     $$(doc, '#profileBody [data-sect]').map(x => x.dataset.sect)
       .filter(x => wanted.indexOf(x) !== -1).slice(0, wanted.length).join('>') === wanted.join('>'),
     $$(doc, '#profileBody [data-sect]').map(x => x.dataset.sect).join(' > '));

  /* ═══ 6. A duplicate address is refused (§124.9) ═════════════════════ */
  console.log('\n=== Duplicate account ===');
  act(win, 'acctdo:logoutgo');
  await wait(80);
  ok('logging out returns to the guest state', win.LUME_ACCT.isGuest(), win.LUME_ACCT.state());
  await fillSignUp(win, { email: 'muhammad@example.com', password: 'Password1', confirm: 'Password1' });
  ok('an address already registered is refused',
     /already exists/i.test(visibleText(doc)), text($(doc, '.field__err')));

  /* ═══ 7. Sign in, and what failure may say (§124.10) ═════════════════ */
  console.log('\n=== Sign in ===');
  act(win, 'auth:signin');
  await wait(60);
  type(win, 'email', 'muhammad@example.com');
  type(win, 'password', 'Wrong1234');
  await submit(win, 'signin');
  const wrongPw = text($(doc, '.formerr'));
  ok('a wrong password is refused', !win.LUME_ACCT.isAuthed() && !!wrongPw, wrongPw);

  type(win, 'email', 'nobody@example.com');
  type(win, 'password', 'Wrong1234');
  await submit(win, 'signin');
  const noAccount = text($(doc, '.formerr'));
  ok('an unknown account and a wrong password say exactly the same thing',
     wrongPw === noAccount && /incorrect/i.test(noAccount), wrongPw + '  vs  ' + noAccount);

  type(win, 'email', 'muhammad@example.com');
  type(win, 'password', 'Password1');
  await submit(win, 'signin');
  ok('the right credentials sign in', win.LUME_ACCT.isAuthed(), win.LUME_ACCT.state());

  /* ═══ 8. Security and change password (§124.12, §124.13) ════════════ */
  console.log('\n=== Security ===');
  act(win, 'acct:security');
  await wait(60);
  ok('security opens', screenId(doc) === 'account', screenId(doc));
  ok('security lists only what exists',
     /Not available/i.test(text($(doc, '#accountBody'))), 'two-factor is claimed but absent');

  act(win, 'acct:password');
  await wait(60);
  type(win, 'current', 'Nope1234');
  type(win, 'password', 'Newpass12');
  type(win, 'confirm', 'Newpass12');
  await submit(win, 'password');
  ok('a wrong current password blocks the change',
     /current password is incorrect/i.test(visibleText(doc)), text($(doc, '.field__err')));

  type(win, 'current', 'Password1');
  type(win, 'password', 'Newpass12');
  type(win, 'confirm', 'Newpass12');
  await submit(win, 'password');
  await wait(60);
  ok('the right current password changes it', win.LUME_ACCT.isAuthed());

  act(win, 'acctdo:logoutgo');
  await wait(60);
  act(win, 'auth:signin');
  await wait(60);
  type(win, 'email', 'muhammad@example.com');
  type(win, 'password', 'Password1');
  await submit(win, 'signin');
  ok('the old password no longer works', !win.LUME_ACCT.isAuthed(), win.LUME_ACCT.state());
  type(win, 'password', 'Newpass12');
  await submit(win, 'signin');
  ok('the new password does', win.LUME_ACCT.isAuthed(), win.LUME_ACCT.state());
  win.close();

  /* ═══ 9. Recovery says the same thing either way (§124.11) ═══════════ */
  console.log('\n=== Forgot password ===');
  ({ win, doc } = await boot());
  await fillSignUp(win, { name: 'Ada', email: 'ada@example.com', password: 'Password1', confirm: 'Password1' });
  act(win, 'acctdo:logoutgo');
  await wait(60);

  act(win, 'auth:forgot');
  await wait(60);
  type(win, 'email', 'nobody@example.com');
  await submit(win, 'forgot');
  const unknownSent = text($(doc, '#authBody'));
  const unknownHasLink = !!$(doc, '[data-act="auth:reset"]');
  ok('an unknown address still reaches the confirmation',
     /Check your email/i.test(unknownSent), unknownSent.slice(0, 80));

  /* The confirmation must be indistinguishable, and that includes what it
     offers — a link shown only for real accounts is an existence oracle
     wearing the right words (§124.11). */
  const unknownToken = win.LUME_ACCT.requestReset('nobody-else@example.com').token;
  ok('a recovery token is issued for an address with no account too',
     !!unknownToken, String(unknownToken));
  ok('redeeming a token that belongs to nothing fails honestly',
     !win.LUME_ACCT.resetPassword({ token: unknownToken, password: 'Newpass12', confirm: 'Newpass12' }).ok);

  act(win, 'auth:forgot');
  await wait(60);
  type(win, 'email', 'ada@example.com');
  await submit(win, 'forgot');
  const knownSent = text($(doc, '.auth__title')) + ' ' + text($(doc, '.auth__text'));
  ok('a known address gets the identical wording',
     /Check your email/.test(knownSent) &&
     /If an account exists/.test(text($(doc, '#authBody'))), knownSent);
  ok('a known address gets the identical affordances',
     !!$(doc, '[data-act="auth:reset"]') === unknownHasLink,
     'unknown had link=' + unknownHasLink);
  ok('the two confirmations are the same screen',
     text($(doc, '#authBody')) === unknownSent, 'wording diverged');

  hit(win, $(doc, '[data-act="auth:reset"]'));
  await wait(60);
  type(win, 'password', 'Resetme12');
  type(win, 'confirm', 'Resetme12');
  await submit(win, 'reset');
  ok('the reset lands on a success screen',
     /Password updated/i.test(text($(doc, '#authBody'))), text($(doc, '.auth__title')));

  hit(win, $(doc, '[data-act="auth:signin"]'));
  await wait(60);
  type(win, 'email', 'ada@example.com');
  type(win, 'password', 'Resetme12');
  await submit(win, 'signin');
  ok('the reset password signs in', win.LUME_ACCT.isAuthed(), win.LUME_ACCT.state());
  win.close();

  /* ═══ 10. A guest keeps everything they made (§124.24) ═══════════════ */
  console.log('\n=== Guest → account ===');
  ({ win, doc } = await boot({
    profile: { country: 'GB', region: '', city: 'London', lang: 'en', displayName: 'Sam',
               favourites: ['calculator', 'weather'], interests: ['weather', 'calendar', 'tasks', 'notes', 'maths'] }
  }));
  const beforeFavs = JSON.parse(win.localStorage.getItem('lume-profile')).favourites.join(',');
  await fillSignUp(win, { email: 'sam@example.com', password: 'Password1', confirm: 'Password1' });
  const after = JSON.parse(win.localStorage.getItem('lume-profile'));
  ok('creating an account keeps the favourites', after.favourites.join(',') === beforeFavs,
     after.favourites.join(','));
  ok('creating an account keeps the country and city',
     after.country === 'GB' && after.city === 'London', after.country + '/' + after.city);
  ok('creating an account keeps the interests', after.interests.length === 5, after.interests.length);
  ok('a guest name carries into the account', win.LUME_ACCT.displayName() === 'Sam',
     win.LUME_ACCT.displayName());

  /* ═══ 11. Editing the profile (§124.14) ═════════════════════════════ */
  console.log('\n=== Edit profile ===');
  act(win, 'acct:edit');
  await wait(60);
  const save = $(doc, '[data-act="acctsubmit:edit"]');
  ok('save is inert until something changes', !!save && save.disabled, save ? 'enabled' : 'missing');
  type(win, 'displayName', 'Samira');
  await wait(30);
  ok('save wakes up when a field changes',
     !$(doc, '[data-act="acctsubmit:edit"]').disabled);
  await submit(win, 'edit');
  await wait(60);
  ok('the new name is stored', win.LUME_ACCT.displayName() === 'Samira', win.LUME_ACCT.displayName());
  hit(win, $(doc, '[data-tab="home"]'));
  await wait(60);
  ok('the greeting follows the new name', /Samira/.test(text($(doc, '#greetText'))),
     text($(doc, '#greetText')));
  win.close();

  /* ═══ 12. A protected destination survives authentication (§124.28) ══ */
  console.log('\n=== Deep link into an account-only destination ===');
  ({ win, doc } = await boot());
  act(win, 'acct:security');
  await wait(60);
  ok('a guest asking for Security is sent to authentication', screenId(doc) === 'auth', screenId(doc));
  ok('the reason is explained rather than assumed',
     /belongs to your account/i.test(text($(doc, '#authBody'))), text($(doc, '#authBody')).slice(0, 90));
  ok('a modal authentication offers a way out that is not Back',
     !!$(doc, '[data-act="acctdo:authclose"]'));

  hit(win, $(doc, '[data-act="auth:signup"]'));
  await wait(60);
  type(win, 'email', 'deep@example.com');
  type(win, 'password', 'Password1');
  type(win, 'confirm', 'Password1');
  await submit(win, 'signup');
  await wait(120);
  ok('after signing in the user lands on what they asked for, not Home',
     screenId(doc) === 'account' && /Security/i.test(text($(doc, '#accountHeader'))),
     screenId(doc) + ' · ' + text($(doc, '#accountHeader')));

  /* ═══ 13. Back is back, everywhere (§124.25) ════════════════════════ */
  console.log('\n=== Navigation ===');
  hit(win, $(doc, '#accountHeader [data-tool-back]'));
  await wait(60);
  ok('back from a settings screen returns to Profile', screenId(doc) === 'profile', screenId(doc));

  act(win, 'acct:prefs');
  await wait(50);
  act(win, 'acct:language');
  await wait(50);
  hit(win, $(doc, '#accountHeader [data-tool-back]'));
  await wait(50);
  ok('back from a nested settings screen returns to its parent',
     /Preferences/i.test(text($(doc, '#accountHeader'))), text($(doc, '#accountHeader')));
  hit(win, $(doc, '[data-tab="home"]'));
  await wait(50);
  act(win, 'acct:prefs');
  await wait(50);
  hit(win, $(doc, '#accountHeader [data-tool-back]'));
  await wait(50);
  ok('the settings stack does not survive leaving through the tab bar',
     screenId(doc) === 'home', screenId(doc));

  /* ═══ 14. Preferences actually change the product (§124.17) ═════════ */
  console.log('\n=== Preferences ===');
  act(win, 'acct:language');
  await wait(60);
  const urdu = $$(doc, '#accountBody .optrow').find(o => /اردو/.test(o.textContent));
  ok('every shipped language is offered', !!urdu,
     $$(doc, '#accountBody .optrow').map(o => text(o)).join(' | '));
  hit(win, urdu);
  await wait(80);
  ok('choosing a language switches the app', doc.documentElement.lang === 'ur',
     doc.documentElement.lang);
  ok('choosing an RTL language switches direction', doc.documentElement.dir === 'rtl',
     doc.documentElement.dir);
  const marked = $$(doc, '#accountBody .optrow.is-on').length;
  ok('the chosen language is the one marked', marked === 1, marked + ' marked');
  act(win, 'acctset:lang:en');
  await wait(80);

  act(win, 'acct:appearance');
  await wait(60);
  act(win, 'acctset:theme:dark');
  await wait(60);
  ok('appearance switches the theme', doc.documentElement.dataset.theme === 'dark',
     doc.documentElement.dataset.theme);
  act(win, 'acctset:theme:system');
  await wait(60);
  ok('appearance can hand the choice back to the system',
     !win.localStorage.getItem('lume-theme'), win.localStorage.getItem('lume-theme'));

  act(win, 'acct:units');
  await wait(60);
  act(win, 'acctset:units:imperial');
  await wait(80);
  ok('units are stored', JSON.parse(win.localStorage.getItem('lume-profile')).units === 'imperial');

  /* ═══ 15. Notifications are one store, two doors (§124.18) ══════════ */
  console.log('\n=== Notifications from Profile ===');
  act(win, 'acct:notifications');
  await wait(120);
  ok('the notification settings render inside the account screen',
     !!$(doc, '#acctNotifPrefs .list-row'), text($(doc, '#accountBody')).slice(0, 60));
  const firstToggle = $(doc, '#acctNotifPrefs [data-npref="inApp"]');
  ok('the same preferences are editable here', !!firstToggle);
  if (firstToggle) {
    const before = win.LUME_NOTIFY_PREFS_INAPP = firstToggle.querySelector('.switch').classList.contains('is-on');
    hit(win, firstToggle);
    await wait(80);
    const now = $(doc, '#acctNotifPrefs [data-npref="inApp"]').querySelector('.switch').classList.contains('is-on');
    ok('a preference changed here actually changes', before !== now, before + ' -> ' + now);
  }

  /* ═══ 16. Sessions and devices (§124.13) ════════════════════════════ */
  console.log('\n=== Sessions ===');
  act(win, 'acct:sessions');
  await wait(60);
  ok('this device is listed and labelled as this device',
     /This device/i.test(text($(doc, '#accountBody'))), text($(doc, '#accountBody')).slice(0, 120));
  ok('this device cannot be revoked from the list of others',
     $$(doc, '#accountBody .sessrow__out').length === 0);

  /* ═══ 17. Logout is confirmed (§124.21) ═════════════════════════════ */
  console.log('\n=== Logout ===');
  hit(win, $(doc, '[data-tab="profile"]'));
  await wait(60);
  hit(win, $(doc, '[data-act="acctdo:logout"]'));
  await wait(80);
  ok('logging out asks first', $(doc, '#sheet-confirm').classList.contains('is-open'));
  ok('the confirmation says what happens',
     /sign in again/i.test(text($(doc, '#confirmText'))), text($(doc, '#confirmText')));
  hit(win, $(doc, '#confirmCancel'));
  await wait(60);
  ok('cancelling keeps the session', win.LUME_ACCT.isAuthed());
  hit(win, $(doc, '[data-act="acctdo:logout"]'));
  await wait(60);
  hit(win, $(doc, '#confirmGo'));
  await wait(120);
  ok('confirming signs out', win.LUME_ACCT.isGuest(), win.LUME_ACCT.state());
  ok('signing out returns to the guest profile',
     !!$(doc, '#profileBody [data-act="auth:signup"]'), screenId(doc));
  win.close();

  /* ═══ 18. Deletion is separated and confirmed twice (§124.22) ═══════ */
  console.log('\n=== Delete account ===');
  ({ win, doc } = await boot());
  await fillSignUp(win, { name: 'Temp', email: 'temp@example.com', password: 'Password1', confirm: 'Password1' });
  act(win, 'acct:account');
  await wait(60);
  const del = $(doc, '#accountBody [data-act="acct:delete"]');
  ok('deletion sits in its own block, not among the ordinary rows',
     !!del && !!del.closest('.danger'), del ? 'not separated' : 'missing');

  act(win, 'acct:delete');
  await wait(60);
  ok('deletion explains what it does before asking',
     /cannot be undone/i.test(text($(doc, '#accountBody'))), text($(doc, '#accountBody')).slice(0, 120));
  ok('deletion also says what stays',
     /remain on this device/i.test(text($(doc, '#accountBody'))));

  type(win, 'current', 'Wrong1234');
  await submit(win, 'delete');
  ok('a wrong password does not delete anything',
     win.LUME_ACCT.isAuthed() && /incorrect/i.test(visibleText(doc)), win.LUME_ACCT.state());

  type(win, 'current', 'Password1');
  await submit(win, 'delete');
  ok('the right password still asks once more',
     $(doc, '#sheet-confirm').classList.contains('is-open') && win.LUME_ACCT.isAuthed());
  hit(win, $(doc, '#confirmGo'));
  await wait(140);
  ok('the final confirmation deletes the account', win.LUME_ACCT.isGuest(), win.LUME_ACCT.state());
  ok('deletion leaves the device data alone',
     JSON.parse(win.localStorage.getItem('lume-profile')).interests.length > 0);
  ok('a deleted account cannot sign in again', (function () {
    return !win.LUME_ACCT.signIn({ email: 'temp@example.com', password: 'Password1' }).ok;
  })());
  win.close();

  /* ═══ 19. An expired session is explained (§124.27) ═════════════════ */
  console.log('\n=== Session expiry ===');
  ({ win, doc } = await boot());
  await fillSignUp(win, { email: 'exp@example.com', password: 'Password1', confirm: 'Password1' });
  const users = win.localStorage.getItem('lume-accounts');
  const session = JSON.parse(win.localStorage.getItem('lume-session'));
  session.expires = Date.now() - 1000;
  win.close();

  ({ win, doc } = await boot({ storage: {
    'lume-accounts': users, 'lume-session': JSON.stringify(session)
  } }));
  await wait(60);
  ok('a dead session is reported rather than silently dropped',
     screenId(doc) === 'auth' && /expired/i.test(text($(doc, '#authBody'))),
     screenId(doc) + ' · ' + text($(doc, '.auth__title')));
  ok('an expired session is not treated as signed in', !win.LUME_ACCT.isAuthed(),
     win.LUME_ACCT.state());
  hit(win, $(doc, '[data-act="acctdo:authclose"]'));
  await wait(80);
  ok('choosing to stay a guest ends the dead session', win.LUME_ACCT.isGuest(),
     win.LUME_ACCT.state());
  win.close();

  /* ═══ 20. Notifications belong to an account (§124.29) ══════════════ */
  console.log('\n=== Notifications and the account ===');
  ({ win, doc } = await boot());
  await fillSignUp(win, { email: 'one@example.com', password: 'Password1', confirm: 'Password1' });
  win.LUME_NOTIFY_TEST = null;
  act(win, 'tab:notifications');
  await wait(150);
  const firstRow = $(doc, '#notifBody [data-notif-open]');
  if (firstRow) { hit(win, firstRow); await wait(80); }
  act(win, 'acctdo:logoutgo');
  await wait(120);
  const stored = JSON.parse(win.localStorage.getItem('lume-profile'));
  ok('signing out clears what the account had read',
     !stored.notifyRead || Object.keys(stored.notifyRead).length === 0,
     JSON.stringify(stored.notifyRead || {}).slice(0, 60));
  ok('signing out releases the push subscription',
     !stored.notify || stored.notify.push === false, JSON.stringify((stored.notify || {}).push));
  win.close();

  /* ═══ 21. §125 sweep: nothing assumed, nothing untranslated ═════════ */
  console.log('\n=== The state and data contract (§125) ===');
  /* Favourites and recents are seeded so the library renders rows rather
     than its empty state: an empty screen proves nothing about the rows. */
  ({ win, doc } = await boot({ profile: {
    country: 'SA', city: 'Riyadh', lang: 'ar', islamic: true,
    favourites: ['calculator', 'weather', 'prayer'], recents: ['calculator', 'quran']
  } }));
  const routes = ['prefs', 'language', 'region', 'currency', 'units', 'time', 'appearance',
                  'notifications', 'library', 'privacy', 'sync', 'help', 'about'];
  const authRoutes = ['signin', 'signup', 'forgot'];
  let leaks = [], blanks = [];

  for (const r of routes) {
    act(win, 'acct:' + r);
    await wait(90);
    const body = text($(doc, '#accountBody')) + ' ' + text($(doc, '#accountHeader'));
    if (/undefined|null|NaN|\[object/.test(body)) blanks.push(r + ': ' + body.slice(0, 60));
    /* An icon reference that resolves to nothing is the same defect in
       another costume. */
    const badIcons = $$(doc, '#accountBody use').map(u => u.getAttribute('href'))
      .filter(h => !h || h === '#undefined' || h === '#null');
    if (badIcons.length) blanks.push(r + ': ' + badIcons.length + ' unresolved icons');
    const raw = body.match(/\b(acct|auth|onb|a11y|cat|tools|pers)\.[a-zA-Z.]+/g);
    if (raw) leaks.push(r + ': ' + raw.join(','));
    if (!body.trim()) blanks.push(r + ': empty screen');
  }
  for (const r of authRoutes) {
    act(win, 'auth:' + r);
    await wait(90);
    const body = text($(doc, '#authBody'));
    if (/undefined|null|NaN/.test(body)) blanks.push(r + ': ' + body.slice(0, 60));
    const raw = body.match(/\b(acct|auth|a11y)\.[a-zA-Z.]+/g);
    if (raw) leaks.push(r + ': ' + raw.join(','));
    if (!body.trim()) blanks.push(r + ': empty screen');
  }
  ok('no account screen renders undefined, null or NaN', blanks.length === 0, blanks.join(' | '));
  ok('no account screen leaks a translation key', leaks.length === 0, leaks.join(' | '));
  ok('the account screens follow the RTL direction', doc.documentElement.dir === 'rtl');
  win.close();


  /* ═══ 22. What the engine audit found ═══════════════════════════════ */
  console.log('\n=== Engine regressions ===');
  ({ win, doc } = await boot());
  const A = () => win.LUME_ACCT;

  /* An email change verified late must not overwrite whoever took the
     address in the meantime. */
  await fillSignUp(win, { name: 'Ada', email: 'ada@example.com', password: 'Password1', confirm: 'Password1' });
  const pending = A().requestEmailChange('shared@example.com');
  ok('an email change can be requested', pending.ok, JSON.stringify(pending));
  A().signOut();
  const carol = A().signUp({ email: 'shared@example.com', password: 'Carolpw9', confirm: 'Carolpw9' });
  ok('someone else may take the address while the change is pending', carol.ok);
  A().signOut();
  A().signIn({ email: 'ada@example.com', password: 'Password1' });
  const verdict = A().verifyEmail(pending.code);
  ok('verifying a stale email change does not destroy the account that took it',
     !verdict.ok, JSON.stringify(verdict));
  A().signOut();
  ok('the account that took the address still works',
     A().signIn({ email: 'shared@example.com', password: 'Carolpw9' }).ok);
  A().signOut();
  win.close();

  /* Identity belongs to whoever owns it: an account's name and photo never
     become the device's, and never reach the next account created here. */
  ({ win, doc } = await boot());
  await fillSignUp(win, { name: 'Bilal', email: 'bilal@example.com', password: 'Password1', confirm: 'Password1' });
  ok('an account holder is greeted by name', A().displayName() === 'Bilal', A().displayName());
  act(win, 'acctdo:logoutgo');
  await wait(80);
  ok('signing out does not leave the last holder’s name on the device',
     A().displayName() === null, String(A().displayName()));
  ok('signing out does not leave the last holder’s photo on the device',
     A().photo() === null, String(A().photo()));
  await fillSignUp(win, { email: 'stranger@example.com', password: 'Password1', confirm: 'Password1' });
  ok('a new account on the same device does not inherit a name',
     A().fullName() === null, String(A().fullName()));
  ok('the profile shows the address when there is no name',
     /stranger@example\.com/.test(text($(doc, '#profileBody .phead'))),
     text($(doc, '#profileBody .phead')).slice(0, 80));

  /* A save that does not touch the name must not rewrite it. */
  A().updateUser({ displayName: 'Zara' });
  A().updateUser({ phone: '+44 7700 900000' });
  ok('saving a phone number leaves the name alone', A().displayName() === 'Zara', A().displayName());

  /* A patch carrying an email applies the rest of itself too. */
  const mixed = A().updateUser({ firstName: 'Zara', lastName: 'K', email: 'moved@example.com' });
  ok('a patch with an email still saves the other fields',
     A().user().lastName === 'K', JSON.stringify(mixed));
  ok('and starts a verification rather than moving the address',
     A().user().email === 'stranger@example.com' && !!A().user().pendingEmail,
     A().user().email + ' / ' + A().user().pendingEmail);
  A().cancelEmailChange();

  /* One browser is one device, however many times it signs in. */
  const deviceRows = () => A().sessions().length;
  ok('one browser is one device', deviceRows() === 1, deviceRows() + ' rows');
  A().expireSession();
  A().signIn({ email: 'stranger@example.com', password: 'Password1' });
  A().expireSession();
  A().signIn({ email: 'stranger@example.com', password: 'Password1' });
  ok('expiring and signing back in does not invent devices', deviceRows() === 1,
     deviceRows() + ' rows after three sign-ins');

  /* A revoked session stops working. */
  const mySession = JSON.parse(win.localStorage.getItem('lume-session'));
  const accounts = JSON.parse(win.localStorage.getItem('lume-accounts'));
  accounts['stranger@example.com'].sessions = [];
  win.localStorage.setItem('lume-accounts', JSON.stringify(accounts));
  ok('a session whose device was signed out elsewhere stops being signed in',
     !A().isAuthed(), A().state());
  ok('and is reported as a session that ended, not as a guest',
     A().isExpired(), A().state());

  /* A corrupt expiry fails closed, not open. */
  win.localStorage.setItem('lume-session', JSON.stringify(
    Object.assign({}, mySession, { expires: 'soon' })));
  ok('a session with a corrupt expiry is not valid forever', !A().isAuthed(), A().state());
  win.close();

  /* The strength meter never contradicts the checklist beside it. */
  ({ win, doc } = await boot());
  const strengthOf = pw => A().passwordStrength(pw);
  ok('a password that fails a displayed rule cannot read better than Fair',
     strengthOf('aaaaaaaaaaaa!').score <= 2 && strengthOf('Ab1!').score <= 2,
     'aaaaaaaaaaaa! -> ' + strengthOf('aaaaaaaaaaaa!').score + ', Ab1! -> ' + strengthOf('Ab1!').score);
  ok('a compliant password reads at least Good', strengthOf('Password1').score >= 3,
     String(strengthOf('Password1').score));

  /* Initials are letters or they are nothing. */
  const emoji = String.fromCodePoint(0x1F642);
  A().signUp({ name: emoji, email: 'emoji@example.com', password: 'Password1', confirm: 'Password1' });
  ok('an emoji name yields no initials rather than half a surrogate',
     A().initials() === null, JSON.stringify(A().initials()));
  /* Clearing the display name falls through to the first name, which is the
     hierarchy 124.3 defines; clearing both leaves nothing, and nothing is a
     valid answer. */
  A().updateUser({ displayName: '   ' });
  ok('an emptied display name falls back to the first name',
     A().displayName() === emoji, JSON.stringify(A().displayName()));
  A().updateUser({ firstName: '  ', lastName: '' });
  ok('a name of spaces is not a name', A().displayName() === null, JSON.stringify(A().displayName()));

  /* Recovery is bounded by the account it was issued for. */
  const tok = A().requestReset('emoji@example.com').token;
  A().signOut();
  A().signUp({ email: 'bystander@example.com', password: 'Password1', confirm: 'Password1' });
  A().resetPassword({ token: tok, password: 'Another12', confirm: 'Another12' });
  ok('resetting one account’s password does not sign a bystander out',
     A().isAuthed(), A().state());
  win.close();

  /* Addresses no mail system would accept are refused. */
  ({ win, doc } = await boot());
  const bad = ['a@b', 'a@-.com', '.a@b.com', 'a..b@c.com', 'a@b..com', 'a b@c.com',
               'a'.repeat(70) + '@b.com'];
  const accepted = bad.filter(v => A().emailValid(v));
  ok('malformed addresses are refused', accepted.length === 0, accepted.join(' | '));
  const good = ['a@b.com', 'first.last@sub.domain.co.uk', 'x+tag@example.org'];
  const refused = good.filter(v => !A().emailValid(v));
  ok('ordinary addresses are accepted', refused.length === 0, refused.join(' | '));

  /* A device screen is not gated behind an account. */
  act(win, 'acct:sync');
  await wait(80);
  ok('a guest can open Data & sync, which is a row they are shown',
     screenId(doc) === 'account' && !/Sign in to continue/i.test(text($(doc, '#accountBody'))),
     screenId(doc) + ' · ' + text($(doc, '#accountBody')).slice(0, 60));
  win.close();

  /* The expired state is designed, not borrowed from the guest. */
  ({ win, doc } = await boot());
  await fillSignUp(win, { name: 'Rehan', email: 'rehan@example.com', password: 'Password1', confirm: 'Password1' });
  const expiredAccounts = win.localStorage.getItem('lume-accounts');
  const expiredSession = JSON.parse(win.localStorage.getItem('lume-session'));
  expiredSession.expires = Date.now() - 1000;
  const deviceKey = win.localStorage.getItem('lume-device');
  win.close();

  ({ win, doc } = await boot({ storage: {
    'lume-accounts': expiredAccounts,
    'lume-session': JSON.stringify(expiredSession),
    'lume-device': deviceKey
  } }));
  await wait(60);
  hit(win, $(doc, '[data-tab="profile"]'));
  await wait(80);
  const head = text($(doc, '#profileBody .phead'));
  ok('an expired session is not rendered as a guest',
     !/using Lume as a guest/i.test(head), head.slice(0, 110));
  ok('the expired profile does not show the last holder’s name as if signed in',
     !/^Rehan/.test(head), head.slice(0, 60));
  ok('the expired profile offers a way back in',
     !!$(doc, '#profileBody [data-act="auth:signin"]'));

  /* Leaving an expired session behind releases its notification state. */
  act(win, 'auth:expired');
  await wait(60);
  act(win, 'acctdo:authclose');
  await wait(100);
  const left = JSON.parse(win.localStorage.getItem('lume-profile'));
  ok('continuing as a guest releases the account’s notification state',
     (!left.notifyRead || !Object.keys(left.notifyRead).length) &&
     (!left.notify || left.notify.push === false),
     JSON.stringify({ read: left.notifyRead, push: (left.notify || {}).push }));
  win.close();

  console.log('\n' + (failures ? failures + ' FAILURES' : 'ALL ACCOUNT CHECKS PASSED'));
  process.exit(failures ? 1 : 0);
})();
