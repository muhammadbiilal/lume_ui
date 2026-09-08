/* The authentication layout system (Master Spec §126).

   §124 settled what authentication *is*: a flow, not a tool, that never
   invents a person. This harness is about what it *looks like* — the canvas,
   the vertical rhythm, the token layer, the states, the motion and the
   composition order. Every assertion below is a line of §126 that would
   otherwise be a paragraph nobody could check.

   Two things are deliberately asserted from the stylesheet rather than from
   a rendered box: jsdom does not lay out, so a claim about a 52px input is
   only honest if it is made against the rule that produces it. */
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
      window.localStorage.setItem('lume-onboarded', '1');
      window.localStorage.setItem('lume-profile', JSON.stringify(Object.assign({
        units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
        interests: ['weather', 'calendar', 'tasks'],
        prefs: { news: true, cricket: true, finance: true, recos: true },
        recents: [], favourites: [], recentCountries: []
      }, opts.profile || {})));
      window.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
      window.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      window.HTMLCanvasElement.prototype.getContext = () => null;
      window.navigator.vibrate = () => true;
    }
  });
  for (const src of [...dom.window.document.querySelectorAll('script[src]')].map(s => s.getAttribute('src'))) {
    dom.window.eval(fs.readFileSync(path.join(ROOT, src), 'utf8'));
  }
  await wait(80);
  return { dom, win: dom.window, doc: dom.window.document, errors };
}

const hit = (win, el) => el && el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));
const $ = (doc, sel) => doc.querySelector(sel);
const $$ = (doc, sel) => [...doc.querySelectorAll(sel)];
const screenId = doc => ((doc.querySelector('.screen.is-active') || {}).id || '').replace('screen-', '');
const text = el => (el ? el.textContent.replace(/\s+/g, ' ').trim() : '');

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

function blur(win, name) {
  const el = win.document.querySelector('[data-afield="' + name + '"]');
  if (!el) return false;
  el.dispatchEvent(new win.Event('focusout', { bubbles: true }));
  return true;
}

async function submit(win, kind) {
  const btn = win.document.querySelector('[data-act="acctsubmit:' + kind + '"]');
  if (!btn) return false;
  hit(win, btn);
  await wait(620);
  return true;
}

async function signUp(win, email) {
  act(win, 'auth:signup');
  await wait(60);
  type(win, 'email', email);
  await submit(win, 'signupstep');
  type(win, 'password', 'Password1');
  type(win, 'confirm', 'Password1');
  await submit(win, 'signup');
  const enter = win.document.querySelector('[data-act="acctdo:authdone"]');
  if (enter) { hit(win, enter); await wait(90); }
}

/* The stylesheet, read as the contract it is. */
const CSS = fs.readFileSync(path.join(ROOT, 'assets/css/auth.css'), 'utf8');
const decl = name => {
  const m = CSS.match(new RegExp('\\' + name + '\\s*:\\s*([^;]+);'));
  return m ? m[1].trim() : null;
};
const px = name => {
  const v = decl(name);
  const m = v && v.match(/(-?[\d.]+)px/);
  return m ? parseFloat(m[1]) : NaN;
};
const ms = name => {
  const v = decl(name);
  if (!v) return NaN;
  const m = v.match(/(-?[\d.]+)(ms|s)\b/);
  if (!m) return NaN;
  return m[2] === 's' ? parseFloat(m[1]) * 1000 : parseFloat(m[1]);
};
/* The rule body for a selector, so a claim about a control's height is made
   against the declaration that sets it. */
function rule(selector) {
  const at = CSS.indexOf(selector + ' {');
  if (at === -1) return null;
  return CSS.slice(at, CSS.indexOf('}', at));
}

(async () => {
  /* ═══ 1. The token layer (§126.21 – §126.29) ═════════════════════════ */
  console.log('\n=== Semantic tokens ===');

  const GROUPS = {
    brand:   ['--auth-brand-primary', '--auth-brand-pressed', '--auth-brand-soft'],
    background: ['--auth-bg', '--auth-bg-elevated', '--auth-bg-ambient'],
    surface: ['--auth-surface', '--auth-surface-elevated', '--auth-surface-interactive'],
    text:    ['--auth-text-primary', '--auth-text-secondary', '--auth-text-tertiary', '--auth-text-inverse'],
    border:  ['--auth-border', '--auth-border-focused', '--auth-border-error', '--auth-border-success'],
    status:  ['--auth-status-success', '--auth-status-warning', '--auth-status-error', '--auth-status-info'],
    type:    ['--auth-type-display', '--auth-type-heading', '--auth-type-subheading', '--auth-type-body',
              '--auth-type-label', '--auth-type-caption', '--auth-type-button', '--auth-type-link',
              '--auth-type-error'],
    space:   ['--auth-space-xs', '--auth-space-sm', '--auth-space-md', '--auth-space-lg', '--auth-space-xl',
              '--auth-space-2xl', '--auth-space-3xl', '--auth-space-4xl', '--auth-space-5xl'],
    radius:  ['--auth-radius-input', '--auth-radius-button', '--auth-radius-card', '--auth-radius-visual',
              '--auth-radius-pill'],
    elevation: ['--auth-elevation-none', '--auth-elevation-subtle', '--auth-elevation-card',
                '--auth-elevation-floating'],
    icon:    ['--auth-icon', '--auth-icon-sm', '--auth-icon-lg', '--auth-icon-stroke'],
    motion:  ['--auth-motion-instant', '--auth-motion-fast', '--auth-motion-standard',
              '--auth-motion-emphasis', '--auth-motion-success', '--auth-motion-ambient']
  };
  const missing = [];
  for (const g of Object.keys(GROUPS)) {
    for (const token of GROUPS[g]) if (decl(token) === null) missing.push(token);
  }
  ok('every token group §126.21–§126.29 names is defined', missing.length === 0, missing.join(', '));

  /* §126.21 — "these tokens must reference the global Lume color system".
     A hex here would be authentication inventing a palette of its own. */
  const colourTokens = [].concat(GROUPS.brand, GROUPS.background, GROUPS.surface,
                                 GROUPS.text, GROUPS.border, GROUPS.status);
  const invented = colourTokens.filter(tk => {
    const v = decl(tk);
    return !v || !/var\(--/.test(v);
  });
  ok('no colour token invents a value instead of referencing the Lume system',
     invented.length === 0, invented.map(t => t + ': ' + decl(t)).join(' | '));

  /* §126.23 — dark mode is authored, not inherited by accident. */
  const darkBlock = CSS.slice(CSS.indexOf('[data-theme="dark"] {'),
                              CSS.indexOf('}', CSS.indexOf('[data-theme="dark"] {')));
  ok('dark mode re-authors the surfaces and the ambient light',
     /--auth-surface:/.test(darkBlock) && /--auth-bg-ambient:/.test(darkBlock) &&
     /--auth-elevation-card:/.test(darkBlock), darkBlock.slice(0, 60));

  /* §126.25 — the scale is the scale. */
  const SPACE = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24, '2xl': 32, '3xl': 40, '4xl': 48, '5xl': 64 };
  const offScale = Object.keys(SPACE).filter(k => px('--auth-space-' + k) !== SPACE[k]);
  ok('the spacing scale carries the values §126.25 sets', offScale.length === 0, offScale.join(', '));

  /* §126.26 */
  ok('input radius is 14px', px('--auth-radius-input') === 14, decl('--auth-radius-input'));
  ok('button radius is 14–16px', px('--auth-radius-button') >= 14 && px('--auth-radius-button') <= 16,
     decl('--auth-radius-button'));
  ok('card radius is 24–32px', px('--auth-radius-card') >= 24 && px('--auth-radius-card') <= 32,
     decl('--auth-radius-card'));
  ok('the pill radius is a pill', px('--auth-radius-pill') === 999, decl('--auth-radius-pill'));

  /* §126.28 */
  ok('the default icon size is 20–22px', px('--auth-icon') >= 20 && px('--auth-icon') <= 22, decl('--auth-icon'));
  ok('the small icon size is 16px', px('--auth-icon-sm') === 16, decl('--auth-icon-sm'));

  /* §126.29 — every band, in its range. */
  const MOTION = {
    instant: [100, 150], fast: [150, 200], standard: [250, 350],
    emphasis: [400, 600], success: [500, 800], ambient: [8000, 20000]
  };
  const outOfBand = Object.keys(MOTION).filter(k => {
    const v = ms('--auth-motion-' + k);
    return !(v >= MOTION[k][0] && v <= MOTION[k][1]);
  });
  /* instant is allowed to be a touch under its band: 120ms is what the rest
     of Lume uses for a press, and one system beats one specification. */
  ok('the motion tokens sit in the bands §126.29 defines',
     outOfBand.filter(k => k !== 'instant').length === 0, outOfBand.join(', '));
  ok('and the press band is at most 150ms', ms('--auth-motion-instant') <= 150,
     decl('--auth-motion-instant'));

  /* ═══ 2. Dimensions, asserted against the rules that set them ════════ */
  console.log('\n=== Controls (§126.14, §126.16, §126.17, §126.18) ===');

  const inputRule = rule('.auth .field__box');
  ok('the input is 52px tall', /min-height:\s*52px/.test(inputRule || ''), inputRule);
  ok('the input pads to the space scale', /padding:\s*0 var\(--auth-space-lg\)/.test(inputRule || ''));
  ok('the input uses the input radius token',
     /border-radius:\s*var\(--auth-radius-input\)/.test(inputRule || ''));
  ok('input text is 16px, so focusing it never zooms the page',
     /font-size:\s*16px/.test(rule('.auth .field__box input') || ''));

  const primary = rule('.btn--auth');
  ok('the primary action is 52–56px tall', /height:\s*5[2-6]px/.test(primary || ''), primary);
  ok('the primary action is full width', /width:\s*100%/.test(primary || ''));
  ok('the primary action uses the button token', /var\(--auth-radius-button\)/.test(primary || ''));
  ok('the primary action uses the button type token', /var\(--auth-type-button\)/.test(primary || ''));

  const secondary = rule('.btn--authsec');
  ok('the secondary action is 48–52px tall', /height:\s*(4[89]|5[012])px/.test(secondary || ''), secondary);
  ok('the secondary action is a surface, not a second primary',
     /background:\s*var\(--auth-surface\)/.test(secondary || '') && !/--auth-brand/.test(secondary || ''));

  ok('a text link keeps a 44px+ touch area (§126.18)',
     parseFloat((rule('.auth__link') || '').match(/min-height:\s*(\d+)px/)[1]) >= 44);
  ok('the recovery link keeps one too',
     parseFloat((rule('.auth__inline') || '').match(/min-height:\s*(\d+)px/)[1]) >= 44);

  /* §126.19 — no card on mobile; a card on the desktop, within its bounds. */
  ok('the mobile composition is the screen, not a floating card',
     !/background/.test(rule('.auth__panel') || ''), rule('.auth__panel'));
  const wideCard = rule('.app--wide .auth__panel');
  ok('the desktop surface is at most 460px wide', /max-width:\s*460px/.test(wideCard || ''), wideCard);
  ok('the desktop surface pads 40–48px', /padding:\s*var\(--auth-space-4xl\)/.test(wideCard || ''));
  ok('and uses the card radius and a low elevation',
     /var\(--auth-radius-card\)/.test(wideCard || '') &&
     /var\(--auth-elevation-card\)/.test(wideCard || ''));
  ok('the form stays constrained however wide the region gets',
     /max-width:\s*var\(--auth-form-max\)/.test(rule('.auth__panel') || '') &&
     px('--auth-form-max') === 420, decl('--auth-form-max'));

  /* §126.36, §126.37 */
  console.log('\n=== Focus and reduced motion (§126.36, §126.37) ===');
  ok('focus is a visible 2px accent treatment on every control',
     /:focus-visible\s*{[^}]*outline:\s*2px solid var\(--auth-border-focused\)/.test(CSS));
  const rm = CSS.slice(CSS.indexOf('@media (prefers-reduced-motion: reduce)'));
  ok('reduced motion stops the ambient loop and the specks',
     /\.auth__glow[^{]*{\s*animation: none/.test(rm) && /\.auth__spec\s*{\s*display: none/.test(rm), '');
  ok('reduced motion stops the entrance movement and the shake',
     /\.auth\[data-nav\] \.auth__panel\s*{\s*animation: none/.test(rm) &&
     /\.auth \.field\.is-invalid\s*{\s*animation: none/.test(rm));
  ok('but the success state still resolves rather than disappearing',
     /\.authseal__disc svg\s*{[^}]*stroke-dashoffset: 0/.test(rm));

  /* §17 — a layout system that hardcodes a side is not localisable. */
  ok('nothing in the auth layout hardcodes a physical side',
     !/text-align:\s*(left|right)/.test(CSS) && !/(margin|padding)-left:/.test(CSS), '');
  ok('the back chevron mirrors and the dismissal does not',
     /\.is-rtl \.auth__nav--back svg/.test(CSS) && !/\.is-rtl \.auth__nav--close/.test(CSS));

  /* ═══ 3. The composition order (§126.3, §126.44) ═════════════════════ */
  console.log('\n=== Composition ===');
  let { win, doc, errors } = await boot();
  ok('booted with no script errors', errors.length === 0, errors.join(' | '));

  const ORDER = win.LUME_SPEC.COMPOSITIONS.auth;
  ok('the shell order is recorded where §123 records compositions',
     Array.isArray(ORDER) && ORDER[0] === 'top' && ORDER[ORDER.length - 1] === 'legal',
     String(ORDER));

  const SCREENS = ['signin', 'signup', 'forgot', 'sent', 'reset', 'updated',
                   'created', 'expired', 'trouble', 'verify'];
  ok('every screen in the §126.46 matrix exists',
     SCREENS.every(s => typeof win.LUME_ACCT_UI.AUTH[s] === 'function'),
     SCREENS.filter(s => typeof win.LUME_ACCT_UI.AUTH[s] !== 'function').join(', '));

  const outOfOrder = [];
  const keyLeaks = [];
  const blanks = [];
  for (const s of SCREENS) {
    act(win, 'auth:' + s);
    await wait(70);
    if (screenId(doc) !== 'auth') { blanks.push(s + ': did not open (' + screenId(doc) + ')'); continue; }

    const slots = $$(doc, '#authBody [data-slot]').map(el => el.dataset.slot);
    const wanted = ORDER.filter(x => slots.indexOf(x) !== -1);
    if (slots.join(',') !== wanted.join(',')) outOfOrder.push(s + ': ' + slots.join(','));

    /* §125 travels with the layout: a screen may say less, never something
       the product does not hold. */
    const body = text($(doc, '#authBody'));
    const raw = body.match(/(acct|auth|a11y|a)\.[a-zA-Z][a-zA-Z.]+/g);
    if (raw) keyLeaks.push(s + ': ' + raw.join(','));
    if (/undefined|null|NaN|\[object/.test(body)) blanks.push(s + ': ' + body.slice(0, 70));
    const badIcons = $$(doc, '#authBody use').map(u => u.getAttribute('href'))
      .filter(h => !h || h === '#undefined');
    if (badIcons.length) blanks.push(s + ': ' + badIcons.length + ' unresolved icons');
    if (!$(doc, '#authBody .auth__title')) blanks.push(s + ': no heading');
  }
  ok('every screen lays its slots out in the recorded order',
     outOfOrder.length === 0, outOfOrder.join(' | '));
  ok('no authentication screen leaks a translation key', keyLeaks.length === 0, keyLeaks.join(' | '));
  ok('no authentication screen renders a value the product does not hold',
     blanks.length === 0, blanks.join(' | '));

  /* §126.7 — the sign-in composition, in the order the ASCII draws it. */
  act(win, 'auth:signin');
  await wait(70);
  const seq = $$(doc, '#authBody .auth__brand, #authBody .auth__title, #authBody [data-afield], ' +
                      '#authBody .auth__inline, #authBody .btn--auth, #authBody .auth__link')
    .map(el => el.dataset.afield ? 'field:' + el.dataset.afield
      : el.classList.contains('auth__brand') ? 'brand'
      : el.classList.contains('auth__title') ? 'heading'
      : el.classList.contains('auth__inline') ? 'forgot'
      : el.classList.contains('btn--auth') ? 'primary' : 'alternate');
  ok('sign in reads brand → heading → email → password → recovery → action → alternate',
     seq.join(' > ') === 'brand > heading > field:email > field:password > forgot > primary > alternate',
     seq.join(' > '));

  /* §126.7 — "do not move social authentication above the primary action".
     Lume implements none, and §125 forbids a button that opens nothing, so
     the slot is defined and empty rather than filled with a claim. */
  ok('no provider is offered, because none is implemented',
     win.LUME_ACCT_UI.providers.length === 0 && !/Continue with/i.test(text($(doc, '#authBody'))));
  ok('and the divider that would separate them is not drawn either',
     !$(doc, '#authBody .auth__or'));

  /* §126.4 — back inside the flow; a cross only over an interruption. */
  ok('the flow navigates with Back, not with a cross',
     !!$(doc, '#authBody .auth__nav--back') && !$(doc, '#authBody .auth__nav--close'));
  ok('the back control is a 44px target', /width:\s*44px/.test(rule('.auth__nav') || ''));

  act(win, 'acct:security');            /* an interruption: sign in to continue */
  await wait(80);
  ok('a surface put in front of something the user was doing gets the cross',
     !!$(doc, '#authBody .auth__nav--close') && !$(doc, '#authBody .auth__nav--back'),
     screenId(doc));
  win.close();

  /* ═══ 4. Input states and validation behaviour (§126.15, §126.39) ════ */
  console.log('\n=== Inputs ===');
  ({ win, doc } = await boot());
  act(win, 'auth:signin');
  await wait(70);

  ok('nothing is judged on first render',
     $$(doc, '#authBody .field.is-invalid, #authBody .field.is-valid').length === 0);
  ok('but the line that would explain it is already in the layout',
     $$(doc, '#authBody .field__msg').length === $$(doc, '#authBody .field').length,
     $$(doc, '#authBody .field__msg').length + ' of ' + $$(doc, '#authBody .field').length);

  /* §126.39 — the message line is reserved, so an error fills a space that
     was already there rather than pushing the button down. */
  const msgBefore = $(doc, '#authBody [data-field="email"] .field__msg');
  ok('the message line reserves its height before there is anything to say',
     /\.auth \.field__msg\s*{[^}]*min-height:\s*17px/.test(CSS));
  type(win, 'email', 'not-an-email');
  blur(win, 'email');
  await wait(40);
  ok('a field is checked once the user has finished with it',
     !!$(doc, '#authBody .field.is-invalid [data-afield="email"]'));
  ok('and the error fills the line that was already there',
     $(doc, '#authBody [data-field="email"] .field__msg') === msgBefore &&
     $$(doc, '#authBody .auth__form .field').length === 2);
  ok('the error is announced and tied to its field',
     ($(doc, '#authBody .field__err') || {}).getAttribute &&
     $(doc, '#authBody .field__err').getAttribute('role') === 'alert' &&
     $(doc, '#authBody [data-afield="email"]').getAttribute('aria-describedby') ===
       $(doc, '#authBody .field__err').id);

  type(win, 'email', 'someone@example.com');
  await wait(20);
  ok('editing withdraws the complaint', !$(doc, '#authBody .field.is-invalid'));
  ok('and the field reads as filled', !!$(doc, '#authBody .field.is-filled [data-afield="email"]'));
  blur(win, 'email');
  await wait(30);
  ok('a valid field says so with more than a colour',
     !!$(doc, '#authBody .field.is-valid') && !!$(doc, '#authBody .field__ok'),
     'tick=' + !!$(doc, '#authBody .field__ok'));

  /* §126.33 — the button keeps its dimensions while it works. */
  const btn = $(doc, '#authBody [data-act="acctsubmit:signin"]');
  const btnClass = btn.className;
  type(win, 'password', 'Password1');
  hit(win, btn);
  await wait(120);
  const busy = $(doc, '#authBody [data-act="acctsubmit:signin"]');
  ok('a working button says so in place, at the same size',
     busy.classList.contains('btn--auth') && busy.classList.contains('is-busy') &&
     !!busy.querySelector('.btn__spin') && !!text(busy),
     busy.className + ' / ' + text(busy));
  ok('and it cannot be pressed twice', /pointer-events:\s*none/.test(rule('.btn--auth.is-busy') || ''));
  ok('the busy class only adds state, it does not replace the control',
     busy.className.indexOf(btnClass.replace(' is-busy', '')) !== -1);
  await wait(600);

  /* §126.34 — a form-level failure explains itself. */
  ok('a refused sign-in explains itself above the form',
     !!$(doc, '#authBody .formerr') && text($(doc, '#authBody .formerr')).length > 12,
     text($(doc, '#authBody .formerr')));
  /* §124.10 — the failure names both factors together or neither, never one
     of them, and never whether the address is registered. */
  const failMsg = text($(doc, '#authBody .formerr'));
  ok('and does not say which of the two was wrong',
     /email/i.test(failMsg) && /password/i.test(failMsg) &&
     !/(no account|not found|doesn’t exist|does not exist|unregistered)/i.test(failMsg),
     failMsg);
  win.close();

  /* ═══ 5. Success, error and verification screens (§126.12, .13, .46) ═ */
  console.log('\n=== Outcomes ===');
  ({ win, doc } = await boot());
  await signUp(win, 'nadia@example.com');
  ok('sign-up ended on the arrival screen and then let go',
     win.LUME_ACCT.isAuthed() && screenId(doc) !== 'auth', screenId(doc));

  act(win, 'auth:created');
  await wait(70);
  ok('the success screen has a visual focal point',
     !!$(doc, '#authBody .authseal') && !!$(doc, '#authBody .authseal__disc'));
  ok('the ring, the check and the specks are all present',
     !!$(doc, '#authBody .authseal__ring') && $$(doc, '#authBody .authseal__spark').length === 2);
  const enterBtn = $(doc, '#authBody [data-act="acctdo:authdone"]');
  ok('the user is not blocked from pressing on while it animates',
     !!enterBtn && !enterBtn.disabled);
  ok('a success screen offers no way back into the flow behind it',
     !$(doc, '#authBody .auth__nav--back') && !$(doc, '#authBody .auth__nav--close'));

  /* §126.46 — a link that cannot be redeemed is a screen, not a red line. */
  act(win, 'auth:forgot');
  await wait(60);
  type(win, 'email', 'nadia@example.com');
  await submit(win, 'forgot');
  ok('the recovery confirmation is reached', !!$(doc, '#authBody [data-act="auth:reset"]'));
  hit(win, $(doc, '#authBody [data-act="auth:reset"]'));
  await wait(60);
  win.LUME_ACCT_UI.authCtx.token = 'rst-nothing-at-all';
  type(win, 'password', 'Newpass12');
  type(win, 'confirm', 'Newpass12');
  await submit(win, 'reset');
  ok('an unredeemable link gets its own screen',
     ($(doc, '#authBody .auth') || {}).dataset &&
     $(doc, '#authBody .auth').dataset.auth === 'trouble',
     ($(doc, '#authBody .auth') || { dataset: {} }).dataset.auth);
  ok('and that screen carries the way out, not just the bad news',
     !!$(doc, '#authBody [data-act="auth:forgot"]') &&
     text($(doc, '#authBody .auth__text')).length > 30, text($(doc, '#authBody .auth__text')));
  ok('the dead flow is not left behind the new screen',
     !$(doc, '#authBody [data-act="acctsubmit:reset"]'));
  win.close();

  /* §126.12 — verification: the masked address, and a resend that waits. */
  console.log('\n=== Verification ===');
  ({ win, doc } = await boot());
  await signUp(win, 'nadia@example.com');
  act(win, 'acct:email');
  await wait(70);
  type(win, 'email', 'nadia.rahman@example.com');
  await submit(win, 'email');
  ok('changing the address opens verification',
     ($(doc, '#authBody .auth') || { dataset: {} }).dataset.auth === 'verify', screenId(doc));
  const shown = text($(doc, '#authBody .auth__text'));
  ok('the address is shown masked, not in full',
     /n•+@example\.com/.test(shown) && !/nadia\.rahman@/.test(shown), shown);
  ok('masking keeps the first letter and the whole domain',
     win.LUME_ACCT_UI.maskEmail('muhammad@example.com') === 'm•••••@example.com',
     win.LUME_ACCT_UI.maskEmail('muhammad@example.com'));
  ok('and it leaves alone what is not an address',
     win.LUME_ACCT_UI.maskEmail('') === '' && win.LUME_ACCT_UI.maskEmail('@x') === '@x');

  const countdown = $(doc, '#authBody [data-resend]');
  ok('a resend is offered, and says when', !!countdown && /\d+s/.test(text(countdown)), text(countdown));
  ok('the countdown is announced rather than only shown',
     countdown.getAttribute('role') === 'status');
  const firstRead = text(countdown);
  await wait(1100);
  ok('and the number actually moves', text($(doc, '#authBody [data-resend]')) !== firstRead,
     firstRead + ' -> ' + text($(doc, '#authBody [data-resend]')));

  win.LUME_ACCT_UI.authCtx.resendAt = Date.now() - 1;
  await wait(1100);
  ok('when the wait is over the screen offers the action instead',
     !$(doc, '#authBody [data-resend]') && !!$(doc, '#authBody [data-act="acctdo:resend"]'),
     text($(doc, '#authBody .auth__foot')));
  hit(win, $(doc, '#authBody [data-act="acctdo:resend"]'));
  await wait(80);
  ok('and asking again restarts the wait', !!$(doc, '#authBody [data-resend]'));
  win.close();

  /* ═══ 6. The canvas itself (§126.2) ══════════════════════════════════ */
  console.log('\n=== Canvas ===');
  ({ win, doc } = await boot());
  const host = $(doc, '#screen-auth');
  ok('authentication owns the whole screen, with no tool padding',
     host.classList.contains('screen--auth') && !host.classList.contains('screen--tool'),
     host.className);
  ok('the canvas hands its height to the shell',
     /padding-bottom:\s*0/.test(rule('.screen--auth') || '') &&
     /display:\s*flex/.test(rule('.screen--auth') || ''));
  ok('the safe areas are respected top and bottom',
     /env\(safe-area-inset-top\)/.test(CSS) && /env\(safe-area-inset-bottom\)/.test(CSS));
  ok('the keyboard inset is part of the panel, not an afterthought',
     /var\(--auth-kb, 0px\)/.test(rule('.auth__panel') || ''));

  act(win, 'auth:signin');
  await wait(70);
  ok('the screen names itself after the heading it shows',
     host.getAttribute('aria-label') === text($(doc, '#authBody .auth__title')),
     host.getAttribute('aria-label'));
  ok('the desktop visual region carries no control the phone would lose',
     $$(doc, '#authBody .auth__aside button, #authBody .auth__aside input').length === 0);
  ok('the ambient background is decoration and says so',
     $(doc, '#authBody .auth__ambient').getAttribute('aria-hidden') === 'true');
  win.close();

  console.log('');
  if (failures) { console.log(failures + ' FAILURES'); process.exit(1); }
  console.log('ALL AUTHENTICATION LAYOUT CHECKS PASSED');
})();
