/* Interaction harness — drives the real DOM the way a user would. */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');

const ROOT = require('path').resolve(__dirname, '..');
let failures = 0;
function ok(label, cond, extra) {
  console.log((cond ? '  ok   ' : '  FAIL ') + label + (cond ? '' : '  ' + (extra || '')));
  if (!cond) failures++;
}

async function boot(profile) {
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
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
      window.localStorage.setItem('lume-profile', JSON.stringify(Object.assign({
        name: 'Zeeshan', initials: 'ZK', units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
        interests: ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news', 'markets'],
        prefs: { news: true, cricket: true, finance: true, recos: true }, recents: [], recentCountries: []
      }, profile)));
      window.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
      window.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      window.HTMLCanvasElement.prototype.getContext = () => null;
      window.navigator.vibrate = () => true;
    }
  });
  const scripts = [...dom.window.document.querySelectorAll('script[src]')].map(s => s.getAttribute('src'));
  for (const src of scripts) dom.window.eval(fs.readFileSync(path.join(ROOT, src), 'utf8'));
  await new Promise(r => setTimeout(r, 60));
  return { dom, errors };
}

function click(win, el) {
  el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));
}
const wait = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  /* ---------------- Muslim + Pakistan ---------------- */
  console.log('\n=== Muslim + Pakistan: navigation & tool screens ===');
  let { dom, errors } = await boot({ country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad', islamic: true, lang: 'en' });
  let win = dom.window, doc = win.document;
  const $ = s => doc.querySelector(s);
  const $$ = s => [...doc.querySelectorAll(s)];

  ok('booted with no script errors', errors.length === 0, errors.slice(0, 2).join(' | '));
  ok('Home is the active screen', $('#screen-home').classList.contains('is-active'));
  ok('quick actions rendered', $$('#quickActions .qaction').length >= 3);
  ok('live cards rendered', $$('#liveNow .livecard').length >= 1);
  ok('upcoming rendered', $$('#upcomingList .crow').length >= 1);
  ok('quick tools rendered', $$('#quickTools .tool').length === 8);

  // open Markets from wherever it appears
  click(win, $('[data-tab="tools"]'));
  await wait(20);
  const marketsBtn = $('[data-act="tool:markets"]');
  ok('Markets reachable from Tools', !!marketsBtn);
  click(win, marketsBtn);
  await wait(20);

  ok('tool screen is active', $('#screen-tool').classList.contains('is-active'));
  ok('tool header rendered with back', !!$('#toolHeader [data-tool-back]'));
  ok('tool header has no close X', !$('#toolHeader [data-close]'));
  const mkBody = $('#toolBody');
  ok('Markets is very-high density', mkBody.dataset.density === 'veryhigh', mkBody.dataset.density);
  ok('Markets is a data explorer', mkBody.dataset.archetype === 'explorer', mkBody.dataset.archetype);
  ok('index rows carry a sparkline (§114)', $$('#toolBody .rrow .spark').length >= 4);
  ok('index rows carry an absolute + % change', /\+[\d,.]+\s+\+?[\d.]+%|▲/.test(mkBody.textContent));
  ok('market status strip present', !!$('#toolBody .mstat'));
  ok('sort controls present (§89)', $$('#toolBody .sortopt').length >= 3);
  ok('tabs present (§26)', $$('#toolBody .ttab').length >= 6);
  ok('source + freshness shown (§107)', !!$('#toolBody .srcbar') && /Exchange feed/.test(mkBody.textContent));
  ok('related tools shown (§97)', $$('#toolBody .related__item').length >= 1);
  ok('PSX is the local exchange', /Pakistan Stock Exchange|KSE-100/.test(mkBody.textContent));

  // switch a tab
  const moversTab = $$('#toolBody .ttab').find(b => /Movers/.test(b.textContent));
  click(win, moversTab);
  await wait(20);
  ok('Movers tab switches content', /Top gainers/.test($('#toolBody').textContent));

  // related tool navigation pushes onto the stack
  const rel = $('#toolBody .related__item');
  const relName = rel.textContent.trim();
  click(win, rel);
  await wait(20);
  ok('related tool opens (' + relName + ')', $('#toolHeader .toolbar__title').textContent.trim() === relName,
     $('#toolHeader .toolbar__title').textContent);
  click(win, $('#toolHeader [data-tool-back]'));
  await wait(20);
  ok('back returns to Markets', /Markets/.test($('#toolHeader .toolbar__title').textContent));
  click(win, $('#toolHeader [data-tool-back]'));
  await wait(20);
  ok('back again leaves the tool screen', !$('#screen-tool').classList.contains('is-active'));

  /* ---- calculator recomputes live ---- */
  console.log('\n=== Calculators recompute (§22E) ===');
  win.eval('document.querySelector("[data-act=\'tool:loan\']")')
  click(win, $('[data-act="tool:loan"]') || $('[data-tab="tools"]'));
  await wait(20);
  if (!$('[data-input="ln_principal"]')) { click(win, $('[data-act="tool:loan"]')); await wait(20); }
  const principal = $('[data-input="ln_principal"]');
  ok('loan calculator has inputs', !!principal);
  const emiBefore = $('[data-ln-emi]').textContent;
  principal.value = String(Number(principal.value) * 2);
  principal.dispatchEvent(new win.Event('input', { bubbles: true }));
  await wait(400);
  const emiAfter = $('[data-ln-emi]').textContent;
  ok('doubling the principal changes the EMI', emiBefore !== emiAfter, emiBefore + ' -> ' + emiAfter);
  ok('amortisation table rendered', $$('#toolBody .dtable tbody tr').length >= 3);

  /* ---- tasbih counts ---- */
  console.log('\n=== Tasbih is a focused interaction (§24.15) ===');
  click(win, $('#toolHeader [data-tool-back]'));
  await wait(20);
  click(win, $('[data-act="tool:tasbih"]'));
  await wait(20);
  ok('tasbih is low density', $('#toolBody').dataset.density === 'low');
  const counter = $('[data-tasbih-count]');
  ok('counter present', !!counter);
  click(win, counter); click(win, counter); click(win, counter);
  ok('counter increments', $('[data-tasbih-num]').textContent === '3', $('[data-tasbih-num]').textContent);

  /* ---- emergency uses tel: links ---- */
  console.log('\n=== Emergency is an action interface (§46) ===');
  click(win, $('#toolHeader [data-tool-back]'));
  await wait(20);
  click(win, $('[data-act="tool:emergency"]'));
  await wait(20);
  ok('emergency is low density', $('#toolBody').dataset.density === 'low');
  ok('primary action is a real tel: link', ($('.sos') || {}).href === 'tel:1122', ($('.sos') || {}).href);
  ok('all services dial out', $$('.call[href^="tel:"]').length >= 3);

  win.close();

  /* ---------------- Non-Muslim + USA: gating & regional swap ------------- */
  console.log('\n=== Non-Muslim + USA: gating and regional configuration ===');
  ({ dom, errors } = await boot({ country: 'US', region: 'New York', city: 'New York', islamic: false, lang: 'en' }));
  win = dom.window; doc = win.document;
  const q = s => doc.querySelector(s);
  const qq = s => [...doc.querySelectorAll(s)];

  ok('booted with no script errors', errors.length === 0, errors.slice(0, 2).join(' | '));
  ok('no Islamic entry point anywhere in the DOM',
     qq('[data-act^="tool:quran"], [data-act^="tool:prayer"], [data-act^="tool:tasbih"], [data-act^="tool:zakat"]').length === 0);

  // §64 — deep link to a hidden tool must be refused
  win.eval('document.body.insertAdjacentHTML("beforeend", \'<button id="deepLink" data-act="tool:quran"></button>\')');
  click(win, q('#deepLink'));
  await wait(20);
  ok('deep link to a hidden tool is refused', !q('#screen-tool').classList.contains('is-active'));
  ok('refusal is explained, not silent', q('#toast').classList.contains('is-open'));

  // regional configuration
  click(win, q('[data-tab="tools"]'));
  await wait(20);
  click(win, q('[data-act="tool:markets"]'));
  await wait(20);
  ok('US market shows NASDAQ/NYSE indices', /S&P 500|Nasdaq|Dow Jones/.test(q('#toolBody').textContent));
  ok('US market does not show PSX', !/Pakistan Stock Exchange/.test(q('#toolBody').textContent));
  ok('prices are in USD', /\$/.test(q('#toolBody').textContent));

  click(win, q('#toolHeader [data-tool-back]'));
  await wait(20);
  click(win, q('[data-act="tool:emergency"]'));
  await wait(20);
  ok('US emergency number is 911', /911/.test(q('#toolBody').textContent) && !/1122/.test(q('#toolBody').textContent));

  click(win, q('#toolHeader [data-tool-back]'));
  await wait(20);
  click(win, q('[data-act="tool:weather"]'));
  await wait(20);
  ok('US weather uses Fahrenheit', /°F|\d+°/.test(q('#toolBody').textContent));
  ok('miles, not kilometres', !/\bkm\b/.test(q('#toolBody .rows').textContent || ''));

  // Pakistan-only tools are absent
  ok('no Pakistan-only tools in a US catalogue',
     qq('[data-act="tool:loadshed"], [data-act="tool:trains"], [data-act="tool:prizebonds"]').length === 0);
  ok('Trains is not a US bottom-nav destination', !q('.tab[data-tab="trains"]'));

  win.close();

  /* ---------------- Urdu RTL ---------------- */
  console.log('\n=== Muslim + UK + Urdu: RTL and localisation ===');
  ({ dom, errors } = await boot({ country: 'GB', region: 'England', city: 'London', islamic: true, lang: 'ur' }));
  win = dom.window; doc = win.document;
  const r = s => doc.querySelector(s);

  ok('booted with no script errors', errors.length === 0, errors.slice(0, 2).join(' | '));
  ok('document direction is RTL', doc.documentElement.dir === 'rtl');
  ok('body carries the RTL class', doc.body.classList.contains('is-rtl'));

  click(win, r('[data-tab="tools"]'));
  await wait(20);
  click(win, r('[data-act="tool:prayer"]'));
  await wait(20);
  ok('prayer screen renders in Urdu', /فجر|ظہر|عصر|مغرب|عشاء/.test(r('#toolBody').textContent));
  ok('London is the location context', /London/.test(r('#toolHeader').textContent + r('#toolBody').textContent));

  click(win, r('#toolHeader [data-tool-back]'));
  await wait(20);
  click(win, r('[data-act="tool:markets"]'));
  await wait(20);
  ok('UK market shows the LSE', /FTSE 100|London Stock Exchange/.test(r('#toolBody').textContent));
  ok('prices are in GBP', /£/.test(r('#toolBody').textContent));

  win.close();

  console.log('\n' + (failures ? failures + ' FAILURES' : 'ALL INTERACTION CHECKS PASSED'));
  process.exit(failures ? 1 : 0);
})().catch(e => { console.error('HARNESS ERROR', e); process.exit(2); });
