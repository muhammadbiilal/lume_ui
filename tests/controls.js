/* Controls harness — proves filters, sorting and search actually change what
   the screen shows (§87–§89, §112), and that empty states appear (§91). */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');

const ROOT = require('path').resolve(__dirname, '..');
let failures = 0;
function ok(label, cond, extra) {
  console.log((cond ? '  ok   ' : '  FAIL ') + label + (cond ? '' : '  → ' + (extra || '')));
  if (!cond) failures++;
}

async function boot(profile) {
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const vc = new VirtualConsole();
  const errors = [];
  vc.on('jsdomError', e => errors.push(String(e.message || e)));
  vc.on('error', (...a) => errors.push(a.map(String).join(' ')));
  const dom = new JSDOM(html, {
    url: 'http://localhost/index.html', runScripts: 'dangerously',
    virtualConsole: vc, pretendToBeVisual: true,
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
  for (const src of [...dom.window.document.querySelectorAll('script[src]')].map(s => s.getAttribute('src'))) {
    dom.window.eval(fs.readFileSync(path.join(ROOT, src), 'utf8'));
  }
  await new Promise(r => setTimeout(r, 60));
  return { dom, errors };
}

const wait = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const { dom, errors } = await boot({ country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad', islamic: true, lang: 'en' });
  const win = dom.window, doc = win.document;
  const $ = s => doc.querySelector(s);
  const $$ = s => [...doc.querySelectorAll(s)];
  const click = el => el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));
  const rows = () => $$('#toolBody .rrow').map(r => (r.querySelector('.rrow__title') || {}).textContent);
  // only the Top-assets section sorts; the hero above it does not
  const securities = () => [...doc.querySelectorAll('#toolBody [data-sect="assets"] .rrow__title')]
    .map(e => e.textContent);
  const open = async id => { click($(`[data-act="tool:${id}"]`) || $('[data-tab="tools"]')); await wait(30); };

  ok('booted clean', errors.length === 0, errors.slice(0, 2).join(' | '));
  click($('[data-tab="tools"]'));
  await wait(20);

  /* ---------------- sorting actually sorts (§89) ---------------- */
  console.log('\n=== Sorting ===');
  await open('markets');
  click($$('#toolBody .ttab').find(b => /Stocks/.test(b.textContent)));
  await wait(30);
  // Top assets caps at five; expand it so sorting is compared over the whole list
  const seeAll = $('#toolBody [data-sect="assets"] .sect__link');
  if (seeAll) { click(seeAll); await wait(30); }
  const byChange = securities();
  const priceBtn = $$('#toolBody .sortopt').find(b => /Price/.test(b.textContent));
  ok('sort options carry an action', !!priceBtn && priceBtn.hasAttribute('data-act'),
     priceBtn ? priceBtn.outerHTML.slice(0, 90) : 'no button');
  click(priceBtn);
  await wait(30);
  const byPrice = securities();
  ok('sorting by price reorders the list', byChange.join() !== byPrice.join(),
     byChange.join(',') + '  vs  ' + byPrice.join(','));
  ok('the active dimension is marked pressed',
     ($$('#toolBody .sortopt').find(b => /Price/.test(b.textContent)) || {}).getAttribute?.('aria-pressed') === 'true');
  click($$('#toolBody .sortopt').find(b => /Price/.test(b.textContent)));
  await wait(30);
  ok('tapping again reverses the direction', securities().join() === byPrice.slice().reverse().join(),
     securities().join(',') + '  vs  ' + byPrice.slice().reverse().join(','));

  /* ---------------- search actually searches (§87) ---------------- */
  console.log('\n=== Search ===');
  const search = $('#toolBody [data-tool-search]');
  ok('markets renders a search field', !!search);
  search.value = 'bank';
  search.dispatchEvent(new win.Event('input', { bubbles: true }));
  await wait(400);
  const found = securities();
  ok('searching narrows the list', found.length > 0 && found.length < byPrice.length,
     found.join(','));
  const again = $('#toolBody [data-tool-search]');
  again.value = 'zzzzz';
  again.dispatchEvent(new win.Event('input', { bubbles: true }));
  await wait(400);
  ok('a search with no hits shows an empty state, not a blank list',
     /state--empty/.test($('#toolBody').innerHTML) && $$('#toolBody .rrow').length < byPrice.length,
     $$('#toolBody .rrow').length + ' rows');

  /* ---------------- filters actually filter (§88) ---------------- */
  console.log('\n=== Filters ===');
  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  await open('expenses');
  const allTx = $$('#toolBody .rrow').length;
  const chip = $$('#toolBody .fchip').find(b => /Groceries/.test(b.textContent));
  ok('filter chips carry an action', !!chip && chip.hasAttribute('data-act'),
     chip ? chip.outerHTML.slice(0, 90) : 'no chip');
  click(chip);
  await wait(30);
  const filtered = $$('#toolBody .rrow').length;
  ok('filtering by category narrows the transactions', filtered > 0 && filtered < allTx,
     allTx + ' → ' + filtered);
  ok('the active chip is marked pressed',
     ($$('#toolBody .fchip').find(b => /Groceries/.test(b.textContent)) || {}).getAttribute?.('aria-pressed') === 'true');

  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  await open('documents');
  const allDocs = $$('#toolBody .rrow').length;
  const vehChip = $$('#toolBody .fchip').find(b => /Vehicle/.test(b.textContent));
  click(vehChip);
  await wait(30);
  ok('documents filter by category', $$('#toolBody .rrow').length < allDocs,
     allDocs + ' → ' + $$('#toolBody .rrow').length);

  /* ---------------- segmented controls re-compose ---------------- */
  console.log('\n=== Segmented controls ===');
  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  await open('quran');
  const surahList = $('#toolBody').textContent;
  click($$('#toolBody .seg').find(b => /Juz/.test(b.textContent)));
  await wait(30);
  ok('the Qur’an browse control switches to Juz', /Juz 1|Juz 2/.test($('#toolBody').textContent));
  click($$('#toolBody .seg').find(b => /Bookmark/.test(b.textContent)));
  await wait(30);
  ok('and to Bookmarks', /Al-Kahf/.test($('#toolBody').textContent) && !/Juz 30/.test($('#toolBody').textContent));

  /* ---------------- library browsing (§22 library) ---------------- */
  console.log('\n=== Duas library ===');
  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  await open('duas');
  const allDuas = $$('#toolBody .rrow').length;
  ok('the dua library lists duas, not just categories', allDuas >= 3, allDuas + ' rows');
  const tile = $$('#toolBody .tile').find(b => /Travel/.test(b.textContent));
  ok('category tiles are real controls', !!tile && /toolstate/.test(tile.getAttribute('data-act') || ''));
  click(tile);
  await wait(30);
  ok('choosing a category filters the library', $$('#toolBody .rrow').length < allDuas,
     allDuas + ' → ' + $$('#toolBody .rrow').length);

  /* ---------------- accessibility of the new controls ---------------- */
  console.log('\n=== Accessibility ===');
  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  await open('todos');
  const task = $('#toolBody [data-task]');
  ok('a task exposes a checkbox role', task && task.getAttribute('role') === 'checkbox');
  ok('and its checked state', task && ['true', 'false'].includes(task.getAttribute('aria-checked')));
  click(task);
  await wait(20);

  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  await open('prayer');
  const ring = $('#toolBody .pring');
  ok('a progress ring announces its value', ring && ring.getAttribute('role') === 'progressbar' &&
     ring.hasAttribute('aria-valuenow'), ring ? ring.getAttribute('role') : 'none');
  const table = $('#toolBody .tablewrap');
  ok('a wide table is keyboard-scrollable', table && table.getAttribute('tabindex') === '0');

  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  await open('mosques');
  const map = $('#toolBody .lmap');
  ok('a map with pins is a group, not an image', map && map.getAttribute('role') === 'group',
     map ? map.getAttribute('role') : 'none');
  ok('its pins are reachable buttons', $$('#toolBody .lmap__pin').length >= 3);

  /* ---------------- no raw keys leaked anywhere ---------------- */
  console.log('\n=== Localisation ===');
  const C = win.LUME, TOOLS = win.LUME_TOOLS;
  const keyRe = /\b(?:[a-z][a-zA-Z0-9]{1,18}\.){1,3}[a-zA-Z0-9]{2,24}\b/g;
  const leaked = new Set();
  C.FEATURES.forEach(f => {
    const built = TOOLS.build(f.id);
    if (!built) return;
    const text = (built.header + built.body).replace(/<[^>]+>/g, ' ').replace(/&[a-z#0-9]+;/g, ' ');
    (text.match(keyRe) || []).forEach(k => { if (!/\.(com|app|org|net)$/.test(k)) leaked.add(k); });
  });
  ok('no untranslated keys reach the screen', leaked.size === 0, [...leaked].slice(0, 8).join(', '));

  const hardMoney = new Set();
  C.FEATURES.forEach(f => {
    const built = TOOLS.build(f.id);
    if (!built) return;
    if (/₨/.test(built.body)) hardMoney.add(f.id);
  });
  ok('no rupee symbol survives outside a PKR locale', hardMoney.size === 0, [...hardMoney].join(', '));

  win.close();
  console.log('\n' + (failures ? failures + ' FAILURES' : 'ALL CONTROL CHECKS PASSED'));
  process.exit(failures ? 1 : 0);
})().catch(e => { console.error('HARNESS ERROR', e); process.exit(2); });
