/* Master Spec §65 / §112 verification harness.
   Boots the real index.html in jsdom under four personalisation states and
   opens every tool in the catalogue, asserting each screen composes. */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');

const ROOT = require('path').resolve(__dirname, '..');

const STATES = [
  { name: 'Muslim + Pakistan + Islamabad',  profile: { country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad', islamic: true,  lang: 'en' } },
  { name: 'Non-Muslim + Pakistan',          profile: { country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad', islamic: false, lang: 'en' } },
  { name: 'Muslim + UK + London (Urdu/RTL)',profile: { country: 'GB', region: 'England', city: 'London', islamic: true,  lang: 'ur' } },
  { name: 'Non-Muslim + USA + New York',    profile: { country: 'US', region: 'New York', city: 'New York', islamic: false, lang: 'en' } },
  { name: 'Muslim + Saudi Arabia (Arabic)', profile: { country: 'SA', region: null, city: 'Riyadh', islamic: true, lang: 'ar', units: 'imperial' } }
];

async function boot(profile) {
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const vc = new VirtualConsole();
  const errors = [];
  vc.on('jsdomError', e => errors.push('jsdomError: ' + (e.message || e)));
  vc.on('error', (...a) => errors.push('console.error: ' + a.map(String).join(' ')));

  const dom = new JSDOM(html, {
    url: 'http://localhost/index.html',
    runScripts: 'dangerously',
    resources: undefined,
    virtualConsole: vc,
    pretendToBeVisual: true,
    beforeParse(window) {
      window.localStorage.setItem('lume-onboarded', '1');
      window.localStorage.setItem('lume-profile', JSON.stringify(Object.assign({
        name: 'Zeeshan', initials: 'ZK', units: 'auto', currency: 'auto', clock: 'auto',
        method: 'MWL', interests: ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news', 'markets', 'trains'],
        prefs: { news: true, cricket: true, finance: true, recos: true }, recents: [], recentCountries: []
      }, profile)));
      window.matchMedia = window.matchMedia || (q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} }));
      window.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      window.cancelAnimationFrame = id => clearTimeout(id);
      window.HTMLCanvasElement.prototype.getContext = () => null;
      window.scrollTo = () => {};
    }
  });

  // Load every local script manually (jsdom won't fetch file:// subresources here).
  const scripts = [...dom.window.document.querySelectorAll('script[src]')].map(s => s.getAttribute('src'));
  for (const src of scripts) {
    const code = fs.readFileSync(path.join(ROOT, src), 'utf8');
    try {
      dom.window.eval(code);
    } catch (e) {
      errors.push('script ' + src + ': ' + e.message + '\n' + (e.stack || '').split('\n').slice(0, 4).join('\n'));
    }
  }
  await new Promise(r => setTimeout(r, 60));
  return { dom, errors };
}

function textOf(el) { return (el.textContent || '').replace(/\s+/g, ' ').trim(); }

process.on('unhandledRejection', e => { console.error('UNHANDLED', e && (e.stack || e.message || e)); process.exit(2); });

(async () => {
  let failures = 0;
  const keyRe = /\b(?:[a-z][a-zA-Z0-9]{1,18}\.){1,3}[a-zA-Z0-9]{2,24}\b/g;

  for (const state of STATES) {
    const { dom, errors } = await boot(state.profile);
    const win = dom.window, doc = win.document;
    const C = win.LUME, SPEC = win.LUME_SPEC, TOOLS = win.LUME_TOOLS;

    console.log('\n=== ' + state.name + ' ===');
    if (errors.length) {
      failures += errors.length;
      errors.slice(0, 6).forEach(e => console.log('  BOOT ERROR ' + e));
    }
    if (!C || !TOOLS) { console.log('  FATAL: app did not initialise'); failures++; continue; }

    console.log('  dir=' + doc.documentElement.dir + ' lang=' + doc.documentElement.lang);

    // Visibility of features for this state
    const visible = [];
    const hidden = [];
    C.FEATURES.forEach(f => {
      const faithOk = !f.faith || state.profile.islamic;
      const ctryOk = !f.countries || f.countries.indexOf(state.profile.country) !== -1;
      (faithOk && ctryOk ? visible : hidden).push(f.id);
    });
    console.log('  features visible: ' + visible.length + ' / ' + C.FEATURES.length);

    // §64 — hidden features must not leak into any surface
    const shellText = textOf(doc.querySelector('#screen-home')) + ' ' + textOf(doc.querySelector('#screen-tools'));
    if (!state.profile.islamic) {
      const leaks = ['Qur', 'Prayer Times', 'Qibla', 'Tasbih', 'Zakat', 'Hadith', 'Ramadan']
        .filter(w => shellText.indexOf(w) !== -1);
      if (leaks.length) { console.log('  FAIL islamic leak on shell: ' + leaks.join(', ')); failures++; }
      else console.log('  ok: no Islamic content on Home/Tools');
    }

    // Open every visible tool
    let opened = 0, empty = 0, rawKeys = new Set(), buildErrors = [];
    for (const id of visible) {
      let built;
      try { built = TOOLS.build(id); } catch (e) { buildErrors.push(id + ': ' + e.message); continue; }
      if (!built) { buildErrors.push(id + ': build returned null'); continue; }
      opened++;
      const body = built.body || '';
      if (body.length < 400) { empty++; console.log('  thin screen: ' + id + ' (' + body.length + ' chars)'); }
      if (/state--error/.test(body)) { buildErrors.push(id + ': rendered error state'); }
      // untranslated keys leaking into visible text
      const stripped = body.replace(/<[^>]+>/g, ' ').replace(/&[a-z#0-9]+;/g, ' ');
      (stripped.match(keyRe) || []).forEach(k => {
        if (/^(?:e\.g|i\.e|etc)\b/.test(k)) return;
        if (/\.(?:com|app|org|net)$/.test(k)) return;
        rawKeys.add(k);
      });
    }
    console.log('  tools built: ' + opened + ' (thin: ' + empty + ')');

    // §6 — a screen must earn the density its contract declares.
    const MIN_SECTIONS = { low: 1, medium: 3, high: 5, veryhigh: 7 };
    const underweight = [];
    for (const id of visible) {
      const built = TOOLS.build(id);
      if (!built) continue;
      const sections = (built.body.match(/<section class="sect/g) || []).length;
      const need = MIN_SECTIONS[built.density] || 3;
      if (sections < need) underweight.push(id + ' (' + built.density + ': ' + sections + '/' + need + ')');
    }
    if (underweight.length) {
      failures += underweight.length;
      console.log('  FAIL density not earned: ' + underweight.join(', '));
    } else {
      console.log('  ok: every screen earns its declared density');
    }
    if (buildErrors.length) {
      failures += buildErrors.length;
      buildErrors.slice(0, 10).forEach(e => console.log('  FAIL ' + e));
    }
    if (rawKeys.size) {
      failures += rawKeys.size;
      console.log('  FAIL untranslated keys: ' + [...rawKeys].slice(0, 12).join(', '));
    }

    // §64 — a hidden tool must refuse to build/open
    for (const id of hidden.slice(0, 5)) {
      const el = doc.querySelector('[data-act="tool:' + id + '"]');
      if (el) { console.log('  FAIL hidden tool reachable in DOM: ' + id); failures++; }
    }

    dom.window.close();
  }

  console.log('\n' + (failures ? 'FAILURES: ' + failures : 'ALL CHECKS PASSED'));
  process.exit(failures ? 1 : 0);
})();
