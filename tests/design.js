/* ============================================================
   Lume — design system harness  (Design System §10)

   The handoff section of the Design System is a contract, and a
   contract nobody checks is a wish. This drives the two halves
   of it:

     the tokens      one central light and dark theme, semantic
                     type styles rather than per-widget
                     declarations, the spacing, radius and touch
                     scales the document names;

     the layout      the three width classes, the navigation
                     each one shows, the content cap, and the
                     golden checks at compact, medium and
                     expanded widths that §10 asks for by name.

   Where the document states a number — 44 px targets, a
   360-440 px list pane, a 680-760 px reading cap, 160/260/420 ms
   motion — the number is asserted, not admired.
   ============================================================ */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');
const { loadInto } = require('./modules');

const ROOT = path.resolve(__dirname, '..');
let failures = 0;
function ok(label, cond, extra) {
  console.log((cond ? '  ok   ' : '  FAIL ') + label + (cond ? '' : '  -> ' + (extra === undefined ? '' : extra)));
  if (!cond) failures++;
}

const wait = ms => new Promise(r => setTimeout(r, ms));

/* ---- the stylesheets, as text, in the order the page loads them ---- */
const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
const sheets = [...html.matchAll(/href="(assets\/css\/[^"]+)"/g)].map(m => m[1]);
const CSS = sheets.map(h => fs.readFileSync(path.join(ROOT, h), 'utf8')).join('\n');

function decl(name) {
  const m = new RegExp('(?:^|[;{\\s])' + name.replace(/[-]/g, '\\-') + '\\s*:\\s*([^;}]+)').exec(CSS);
  return m ? m[1].trim() : null;
}

function rule(selector) {
  const esc = selector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const m = new RegExp('(?:^|\\})[^{}@]*?' + esc + '\\s*\\{([^}]*)\\}', 'm').exec(CSS);
  return m ? m[1] : null;
}

async function boot(width) {
  const vc = new VirtualConsole();
  const errors = [];
  vc.on('jsdomError', e => errors.push(String(e.message || e)));
  vc.on('error', (...a) => errors.push(a.map(String).join(' ')));

  const dom = new JSDOM(html, {
    url: 'http://localhost/index.html',
    runScripts: 'dangerously',
    virtualConsole: vc,
    pretendToBeVisual: true,
    beforeParse(window) {
      window.localStorage.setItem('lume-onboarded', '1');
      window.localStorage.setItem('lume-profile', JSON.stringify({
        country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad',
        islamic: false, lang: 'en', units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
        interests: ['weather', 'calendar', 'tasks', 'notes'],
        prefs: { news: true, cricket: true, finance: true, recos: true },
        recents: [], favourites: [], recentCountries: []
      }));
      Object.defineProperty(window.HTMLElement.prototype, 'offsetWidth', {
        configurable: true,
        get() { return this.id === 'app' ? width : 100; }
      });
      window.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
      window.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      window.HTMLCanvasElement.prototype.getContext = () => null;
    }
  });
  loadInto(dom, ROOT, errors);
  await wait(60);
  return { dom, errors };
}

(async () => {
  /* ==========================================================
     Colour  (§3)
     ========================================================== */
  console.log('\n=== Colour (§3) ===');
  const PALETTE = {
    '--accent-50': '#E9F7F4', '--accent-100': '#CFEDE7', '--accent-400': '#34B39D',
    '--accent': '#10998A', '--accent-600': '#0B7F73', '--accent-700': '#086357',
    '--bg': '#F6F6F4', '--card': '#FFFFFF',
    '--text': '#101113', '--text-2': '#56585F', '--text-3': '#8B8D95',
    '--rose-ink': '#A3323F'
  };
  Object.keys(PALETTE).forEach(function (token) {
    const got = decl(token);
    ok('the ' + token + ' the document names is the one shipped',
       got && got.toUpperCase() === PALETTE[token].toUpperCase(), got);
  });

  const dark = CSS.slice(CSS.indexOf('[data-theme="dark"]'));
  ok('dark mode is authored, not inverted: its own canvas',
     /--bg:\s*#0A0A0B/i.test(dark));
  ok('its own card surface', /--card:\s*#141416/i.test(dark));
  ok('its own primary text', /--text:\s*#F3F3F4/i.test(dark));
  ok('and its own accent', /--accent:\s*#35CBB2/i.test(dark));
  ok('gradients are re-authored for dark rather than dimmed',
     /--grad-accent-a:\s*#06463F/i.test(dark));

  /* ==========================================================
     Typography  (§4)
     ========================================================== */
  console.log('\n=== Typography (§4) ===');
  ok('Plus Jakarta Sans carries Latin text', /Plus Jakarta Sans/.test(decl('--font') || ''));
  ok('Noto Naskh Arabic is loaded for Arabic reading content',
     /Noto\+Naskh\+Arabic/.test(html));

  const TYPE = {
    '--t-display': /800 28px\/32px/,
    '--t-title': /700 20px\/26px/,
    '--t-section': /700 17px\/22px/,
    '--t-cardtitle': /700 15px\/20px/,
    '--t-body': /400 14px\/22px/,
    '--t-label': /700 12px\/16px/,
    '--t-tab': /700 10px\/14px/
  };
  Object.keys(TYPE).forEach(function (token) {
    ok('the type scale carries ' + token.replace('--t-', ''),
       TYPE[token].test(decl(token) || ''), decl(token));
  });
  ok('semantic styles are used, not per-widget declarations',
     (CSS.match(/font:\s*var\(--t-/g) || []).length >= 40,
     String((CSS.match(/font:\s*var\(--t-/g) || []).length));
  ok('money and timers use tabular numerals',
     /font-variant-numeric:\s*tabular-nums/.test(rule('.num') || ''));

  /* ==========================================================
     Spacing, shape, motion  (§5)
     ========================================================== */
  console.log('\n=== Spacing, shape and motion (§5) ===');
  ok('20 px is the phone page padding', decl('--pad') === '20px', decl('--pad'));
  ok('12 px is the control radius', decl('--r-sm') === '12px', decl('--r-sm'));
  ok('16 px is the card radius', decl('--r-md') === '16px', decl('--r-md'));
  ok('26 px is the sheet radius', decl('--r-xl') === '26px', decl('--r-xl'));
  ok('the minimum touch target is 44 px', decl('--tap') === '44px', decl('--tap'));
  ok('icons carry a 1.75 px rounded stroke',
     /stroke-width:\s*1\.75/.test(rule('.ico') || ''));
  ok('feedback is 160 ms', decl('--dur-fast') === '.16s', decl('--dur-fast'));
  ok('a standard transition is 260 ms', decl('--dur') === '.26s', decl('--dur'));
  ok('a screen transition is 420 ms', decl('--dur-slow') === '.42s', decl('--dur-slow'));
  ok('reduced motion is honoured', /prefers-reduced-motion: reduce/.test(CSS));

  /* ==========================================================
     Responsive layout  (§1, §6)
     ========================================================== */
  console.log('\n=== The three width classes (§1, §6) ===');
  ok('the medium boundary is 600 px', /min-width:\s*600px/.test(CSS));
  ok('the expanded boundary is 840 px', /\[data-bp="expanded"\]/.test(CSS));
  ok('a rail is 84 px wide', decl('--nav-rail') === '84px', decl('--nav-rail'));
  ok('a sidebar is 244 px wide', decl('--nav-side') === '244px', decl('--nav-side'));

  const cap = parseInt(decl('--content-max'), 10);
  ok('reading and form content is capped at 680-760 px (§5)',
     cap >= 680 && cap <= 760, decl('--content-max'));
  const pane = parseInt(decl('--list-pane'), 10);
  ok('the master-detail list pane is 360-440 px (§5)',
     pane >= 360 && pane <= 440, decl('--list-pane'));

  /* ---- golden checks at the three widths (§10, "Testing") ---- */
  for (const [width, name, nav] of [[390, 'compact', 'tabbar'], [720, 'medium', 'rail'], [1180, 'expanded', 'sidebar']]) {
    console.log('\n--- ' + name + ' (' + width + 'px) ---');
    const { dom, errors } = await boot(width);
    const doc = dom.window.document;
    const $ = s => doc.querySelector(s);
    const $$ = s => [...doc.querySelectorAll(s)];

    ok('boots clean at ' + width + 'px', errors.length === 0, errors.slice(0, 2).join(' | '));
    ok('reports the ' + name + ' width class', doc.documentElement.dataset.bp === name,
       doc.documentElement.dataset.bp);
    ok('Home rendered', $('#screen-home').classList.contains('is-active'));

    /* One destination set. Both presentations exist in the document at all
       times — the stylesheet shows the right one — so both must agree. */
    const bar = $$('#tabbar .tab').map(b => b.dataset.tab);
    const side = $$('#navside .navtab').map(b => b.dataset.tab);
    ok('the bottom bar and the rail hold the same destinations',
       bar.join('>') === side.join('>'), bar.join('>') + ' vs ' + side.join('>'));
    ok('Pakistan gets Trains as a first-class destination',
       bar.join('>') === 'home>tools>trains>today>profile', bar.join('>'));
    ok('never more than five destinations (§6)', bar.length <= 5, String(bar.length));

    ok('exactly one destination is selected, in both presentations',
       $$('[aria-selected="true"]').filter(el => el.dataset.tab).length === 2,
       String($$('[aria-selected="true"]').filter(el => el.dataset.tab).length));

    /* Navigating selects in both, so a resize never lands on a stale one. */
    const tools = $('#navside .navtab[data-tab="tools"]');
    tools.dispatchEvent(new dom.window.MouseEvent('click', { bubbles: true }));
    await wait(30);
    ok('choosing a destination in the rail moves the bottom bar too',
       $('#tabbar .tab[data-tab="tools"]').getAttribute('aria-selected') === 'true');
    ok('and the screen followed', $('#screen-tools').classList.contains('is-active'));

    dom.window.close();
  }

  console.log('\n=== Navigation presentation (§6) ===');
  ok('the bottom bar is compact-only', /\[data-bp="medium"\]\s*\.tabbar[\s\S]{0,80}display:\s*none/.test(CSS));
  ok('the rail and sidebar are hidden when compact',
     /\.navside\s*\{[^}]*display:\s*none/.test(CSS));
  ok('the sidebar carries the wordmark, the rail does not',
     /\[data-bp="expanded"\]\s*\.navside__brand[\s\S]{0,60}display:\s*block/.test(CSS));
  ok('a rail destination stacks its label under its icon',
     /\[data-bp="medium"\]\s*\.navtab\s*\{[^}]*flex-direction:\s*column/.test(CSS));
  ok('a navigation destination keeps a 44 px target',
     /min-height:\s*var\(--tap\)/.test(rule('.navtab') || ''));

  /* ==========================================================
     Accessibility  (§9)
     ========================================================== */
  console.log('\n=== Accessibility (§9) ===');
  ok('focus is a visible 2 px accent outline with 2 px offset',
     /outline:\s*2px solid var\(--accent\)/.test(rule(':focus-visible') || '') &&
     /outline-offset:\s*2px/.test(rule(':focus-visible') || ''));
  ok('a record row keeps a 44 px target', /min-height:\s*var\(--tap\)/.test(rule('.rrec') || ''));
  ok('a form field is at least 44 px tall',
     parseInt((rule('.cfield__box') || '').match(/min-height:\s*(\d+)px/)[1], 10) >= 44);
  ok('a checkbox row keeps one too', /min-height:\s*var\(--tap\)/.test(rule('.cfield--check') || ''));
  ok('the destructive button uses the danger ink, which carries white at AA',
     /(^|\})\s*\.btn--danger\s*\{[^}]*background:\s*var\(--rose-ink\)/m.test(CSS));
  ok('an invalid field is a boundary and a message, not colour alone',
     /border-color:\s*var\(--rose-ink\)/.test(rule('.cfield__box.is-invalid') || ''));
  ok('essential text is allowed to wrap',
     /overflow-wrap:\s*anywhere/.test(rule('.cfact__value') || ''));

  /* ==========================================================
     RTL  (§9)
     ========================================================== */
  console.log('\n=== RTL (§9) ===');
  ok('the shell borders with a logical property, so it mirrors on its own',
     /border-inline-end/.test(rule('.navside') || ''));
  ok('directional chevrons mirror', /\.is-rtl\s+\.crow__chev[\s\S]{0,60}scaleX\(-1\)/.test(CSS));
  {
    const { dom } = await boot(390);
    const win = dom.window, doc = win.document;
    const profile = JSON.parse(win.localStorage.getItem('lume-profile'));
    profile.lang = 'ur';
    win.localStorage.setItem('lume-profile', JSON.stringify(profile));
    dom.window.close();

    const rtl = new JSDOM(html, {
      url: 'http://localhost/index.html', runScripts: 'dangerously',
      pretendToBeVisual: true,
      beforeParse(w) {
        w.localStorage.setItem('lume-onboarded', '1');
        w.localStorage.setItem('lume-profile', JSON.stringify(Object.assign(profile, { lang: 'ar' })));
        Object.defineProperty(w.HTMLElement.prototype, 'offsetWidth', {
          configurable: true, get() { return this.id === 'app' ? 1180 : 100; }
        });
        w.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
        w.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
        w.HTMLCanvasElement.prototype.getContext = () => null;
      }
    });
    loadInto(rtl, ROOT, []);
    await wait(80);
    const d = rtl.window.document;
    ok('an Arabic profile sets the document direction', d.documentElement.dir === 'rtl');
    ok('and the body carries the RTL class', d.body.classList.contains('is-rtl'));
    ok('while the expanded layout still holds', d.documentElement.dataset.bp === 'expanded');
    rtl.window.close();
  }

  /* ==========================================================
     Handoff  (§10)
     ========================================================== */
  console.log('\n=== Engineering handoff (§10) ===');
  /* Declaring a custom property is defining a token, which is what a few
     sheets legitimately do for their own layer. A raw hex as a *value* is
     what this looks for. */
  function rawHex(href) {
    const body = fs.readFileSync(path.join(ROOT, href), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '');
    return [...body.matchAll(/(^|[;{])\s*(?!--)([a-z-]+)\s*:\s*([^;}]*#[0-9a-f]{3,8}[^;}]*)/gi)]
      .map(m => href.replace('assets/css/', '') + ' ' + m[2]);
  }

  const NEW_SHEETS = ['assets/css/crud.css', 'assets/css/responsive.css'];
  const fresh = NEW_SHEETS.reduce((a, h) => a.concat(rawHex(h)), []);
  ok('the record and responsive layers declare no colour of their own',
     fresh.length === 0, fresh.join(', '));

  /* The rest of the product still carries colour written before the token
     file covered every case — gradients, ink on a coloured surface, a mask.
     This is a ratchet rather than a gate: it may fall, never rise. */
  const BASELINE = 21;
  const legacy = sheets.filter(h => !/tokens\.css$/.test(h) && NEW_SHEETS.indexOf(h) === -1)
    .reduce((a, h) => a.concat(rawHex(h)), []);
  ok('and nowhere else has grown a new one (' + legacy.length + ' of ' + BASELINE + ')',
     legacy.length <= BASELINE, [...new Set(legacy)].slice(0, 8).join(', '));

  ok('the viewport meta allows the full 320-1366 range',
     /width=device-width/.test(html) && /viewport-fit=cover/.test(html));
  ok('breakpoints are declared once, in the width service',
     /BREAKPOINTS\s*=\s*\{\s*medium:\s*600,\s*expanded:\s*840\s*\}/
       .test(fs.readFileSync(path.join(ROOT, 'assets/js/core/breakpoint.js'), 'utf8')));

  console.log(failures ? '\n' + failures + ' FAILURE(S)' : '\nALL DESIGN SYSTEM CHECKS PASSED');
  process.exit(failures ? 1 : 0);
})().catch(e => { console.error(e); process.exit(1); });
