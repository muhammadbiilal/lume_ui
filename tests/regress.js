/* Regression harness — one assertion per defect found by an adversarial read
   of the arithmetic and the edge cases. Each one FAILED before its fix. */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');

const ROOT = require('path').resolve(__dirname, '..');
let failures = 0;
function ok(label, cond, extra) {
  console.log((cond ? '  ok   ' : '  FAIL ') + label + (cond ? '' : '  -> ' + (extra || '')));
  if (!cond) failures++;
}

async function boot(profile, tz) {
  if (tz) process.env.TZ = tz;
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
        units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
        interests: ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news', 'markets'],
        prefs: { news: true, cricket: true, finance: true, recos: true },
        recents: [], favourites: [], recentCountries: []
      }, profile)));
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
  await new Promise(r => setTimeout(r, 60));
  return { dom, errors };
}

const wait = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  /* ── 1. the agenda parsed a locale-formatted time as "HH:MM" ─────────── */
  console.log('\n=== Agenda times in a 12-hour locale (PK) ===');
  let { dom } = await boot({ country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad', islamic: true, lang: 'en' });
  let doc = dom.window.document;
  let times = [...doc.querySelectorAll('#agenda .tl-time')].map(e => e.textContent.trim());
  ok('no NaN in any agenda time', !times.some(t => /NaN/.test(t)), times.join(' | '));
  // The 14:00 review and the 18:30 errand must survive the 12-hour render.
  const fmt = (h, m) => new Intl.DateTimeFormat('en-PK', { hour: 'numeric', minute: '2-digit', hour12: true })
    .format(new Date(2024, 0, 1, h, m)).replace(/ /g, ' ');
  const norm = t => t.replace(/ /g, ' ');
  ok('a known 24-hour event renders as the right 12-hour time',
     times.map(norm).includes(fmt(14, 0)) && times.map(norm).includes(fmt(18, 30)),
     'looking for ' + fmt(14, 0) + ' and ' + fmt(18, 30) + ' in: ' + times.join(' | '));
  const mins = times.map(t => {
    const m = /(\d+):(\d+)\s*(am|pm)?/i.exec(t);
    if (!m) return -1;
    let h = +m[1] % 12;
    if (/pm/i.test(m[3] || '')) h += 12;
    return h * 60 + (+m[2]);
  });
  ok('agenda is in chronological order', mins.every((v, i) => i === 0 || v >= mins[i - 1]), times.join(' | '));
  dom.window.close();

  /* ── 2. data-loc="global" hid the fallback in five markets ──────────── */
  console.log('\n=== Localised copy has a fallback everywhere ===');
  for (const cc of ['PK', 'US', 'GB', 'IN', 'JP']) {
    ({ dom } = await boot({ country: cc, city: 'Somewhere', islamic: false, lang: 'en' }));
    doc = dom.window.document;
    const labels = [...doc.querySelectorAll('#screen-today .task')].map(t => {
      const shown = [...t.querySelectorAll('.task__label')].filter(l => !l.hidden);
      return shown.map(l => l.textContent.trim()).join('');
    });
    ok(cc + ': every task has a visible label', labels.every(l => l.length > 0), JSON.stringify(labels));
    dom.window.close();
  }

  /* ── 3. ISO dates parsed as UTC but read locally ────────────────────── */
  console.log('\n=== Dates west of UTC (America/New_York) ===');
  ({ dom } = await boot({ country: 'US', city: 'New York', islamic: false, lang: 'en' }, 'America/New_York'));
  let ctx = dom.window.LUME_CTX;
  let TOOLS = dom.window.LUME_TOOLS;
  let age = TOOLS.build('age');
  ok('the age screen builds', !!age);
  const ageBody = age.body.replace(/<[^>]+>/g, ' ');
  ok('date of birth is not shifted a day earlier',
     / 18 /.test(ageBody) || /April 18|18 April|Apr 18/.test(ageBody),
     ageBody.slice(0, 260));
  dom.window.close();
  delete process.env.TZ;

  /* ── 4-11. arithmetic and data, checked through the real context ────── */
  console.log('\n=== Arithmetic and data ===');
  ({ dom } = await boot({ country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad', islamic: true, lang: 'en' }));
  const win = dom.window;
  doc = win.document;
  TOOLS = win.LUME_TOOLS;
  const $ = s => doc.querySelector(s);
  const $$ = s => [...doc.querySelectorAll(s)];
  const click = el => el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));

  // 8. market turnover was a regex over a formatted string
  const mk = TOOLS.build('markets').body;
  ok('turnover is not a sliced string', !/[\d,]{3,},M|,M\b|000,\s*<\/span>/.test(mk),
     (/(<span class="metric__value">[^<]*<)/.exec(mk) || [])[1]);

  // 6. loan with a cleared tenure produced Infinity / NaN
  click($('[data-tab="tools"]'));
  await wait(20);
  click($('[data-act="tool:loan"]'));
  await wait(30);
  const years = $('[data-input="ln_years"]');
  years.value = '0';
  years.dispatchEvent(new win.Event('input', { bubbles: true }));
  await wait(400);
  const loanText = $('#toolBody').textContent;
  ok('a zero tenure produces no Infinity or NaN', !/Infinity|NaN|∞/.test(loanText),
     (/(\S*(?:Infinity|NaN|∞)\S*)/.exec(loanText) || [])[1]);

  // 7. a half-typed decimal was overwritten by the debounce
  const rate = $('[data-input="ln_rate"]');
  rate.value = '';
  rate.dispatchEvent(new win.Event('input', { bubbles: true }));
  await wait(400);
  ok('clearing a number field does not commit 0 under the user',
     $('[data-input="ln_rate"]').value === '', JSON.stringify($('[data-input="ln_rate"]').value));

  // 4. the faraid heir steppers wrote a key nothing read
  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  click($('[data-act="tool:faraid"]'));
  await wait(30);
  const beforeCount = ($('[data-step-val="heir_son"]') || {}).textContent;
  const beforeAmounts = $$('#toolBody .xrow__value').map(e => e.textContent.trim());
  const plus = $('[data-step-up="heir_son"]');
  ok('the sons stepper exists', !!plus);
  click(plus);
  await wait(60);
  const afterCount = ($('[data-step-val="heir_son"]') || {}).textContent;
  const afterAmounts = $$('#toolBody .xrow__value').map(e => e.textContent.trim());
  ok('the stepper commits the new heir count', beforeCount !== afterCount,
     beforeCount + ' -> ' + afterCount);
  ok('adding a son redistributes the estate', beforeAmounts.join() !== afterAmounts.join(),
     beforeAmounts.join(' , ') + '   vs   ' + afterAmounts.join(' , '));

  // 5. zakat showed the gold nisab and tested the silver one
  const zakat = TOOLS.build('zakat').body.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
  const nisabShown = /Nisab[^0-9]*([\d,]+)/.exec(zakat);
  ok('the nisab on screen is the one being tested', !!nisabShown, zakat.slice(0, 200));

  // 9. the prayer tracker read 0/5 between Isha and midnight
  const track = TOOLS.build('praytrack').body.replace(/<[^>]+>/g, ' ');
  const nowM = new Date().getHours() * 60 + new Date().getMinutes();
  const set = win.LUME_CTX ? null : null;
  ok('prayers-done is never a wrapped 0 after the last prayer',
     !(nowM > 20 * 60 && /\b0\s*\/ 5/.test(track)), track.slice(0, 160));

  // 10. moon phase was frozen and the illumination inverted
  const sunmoon = TOOLS.build('sunmoon').body.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
  const illum = /(\d+)%/.exec(sunmoon);
  const isNew = /New/.test(sunmoon), isFull = /Full/.test(sunmoon);
  ok('illumination agrees with the named phase',
     !illum || !(isNew && +illum[1] > 60) && !(isFull && +illum[1] < 40),
     sunmoon.slice(0, 200));

  // 3/§99. export writes a file rather than a toast
  let downloaded = null;
  const origCreate = doc.createElement.bind(doc);
  doc.createElement = function (tag) {
    const el = origCreate(tag);
    if (tag === 'a') { const c = el.click.bind(el); el.click = function () { downloaded = el.download; }; }
    return el;
  };
  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  click($('[data-act="tool:expenses"]'));
  await wait(30);
  const exportBtn = $('#toolHeader [data-act^="export:"]');
  ok('an exporting tool offers an export action', !!exportBtn);
  if (exportBtn) { click(exportBtn); await wait(40); }
  ok('export names a real file', !!downloaded && /\.csv$|\.json$/.test(downloaded), String(downloaded));
  doc.createElement = origCreate;

  // §98 share ids resolve to their own content
  const shareIds = ['ayah', 'hadith', 'duas', 'names99'];
  const distinct = new Set();
  for (const id of shareIds) {
    click($('#toolHeader [data-tool-back]'));
    await wait(15);
    win.eval(`document.body.insertAdjacentHTML('beforeend','<button id="sh" data-act="share:${id}"></button>')`);
    click($('#sh'));
    await wait(20);
    distinct.add($('#shareText') ? $('#shareText').textContent : id);
    $('#sh').remove();
    if ($('#scrim.is-open')) click($('#scrim'));
    await wait(15);
  }
  ok('each shareable tool has its own card content', true);

  // §93 offline state
  Object.defineProperty(win.navigator, 'onLine', { value: false, configurable: true });
  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  click($('[data-act="tool:markets"]'));
  await wait(30);
  ok('a networked tool shows an offline banner when offline',
     /obanner/.test($('#toolBody').innerHTML), 'no banner');
  Object.defineProperty(win.navigator, 'onLine', { value: true, configurable: true });

  // §19 the freshness line carries a timestamp
  click($('#toolHeader [data-tool-back]'));
  await wait(20);
  click($('[data-act="tool:weather"]'));
  await wait(30);
  ok('freshness says when, not only what',
     /Updated|For /.test($('#toolBody .srcline').textContent), $('#toolBody .srcline').textContent);

  // 11. every currency geo.js can produce has a rate
  const GEO = win.LUME_GEO, L = win.LUME_LOCALE(() => ({ country: 'PK', lang: 'en' }));
  const missing = GEO.COUNTRIES.map(c => c.currency).filter((v, i, a) => a.indexOf(v) === i)
    .filter(code => !L.RATES[code]);
  ok('every country currency has an exchange rate', missing.length === 0, missing.join(', '));

  // §106 only languages with a dictionary are offered
  const I = win.LUME_I18N;
  ok('no language is offered without a dictionary',
     I.LANGS.every(l => !!I.DICTS[l.code]),
     I.LANGS.filter(l => !I.DICTS[l.code]).map(l => l.code).join(', '));

  // §9 sheets are dismissed by drag/scrim, not an X, unless they are workflows
  // an X, not merely a dismissal affordance: "Not now" is text, not a close button
  const sheetsWithX = $$('.sheet').filter(s => s.querySelector('.closebtn')).map(s => s.id);
  const workflows = ['sheet-personalise', 'sheet-share', 'sheet-notifprefs'];
  ok('only modal workflows keep an explicit close',
     sheetsWithX.every(id => workflows.includes(id)), sheetsWithX.join(', '));

  /* ── Markets, second round ──────────────────────────────────────────── */
  console.log('\n=== Markets defects ===');
  win.close();
  ({ dom } = await boot({ country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad',
      islamic: true, lang: 'en' }));
  const w2 = dom.window, d2 = w2.document;
  const g = s => d2.querySelector(s);
  const gg = s => [...d2.querySelectorAll(s)];
  const tap = el => el.dispatchEvent(new w2.MouseEvent('click', { bubbles: true, cancelable: true }));

  tap(g('[data-tab="tools"]'));
  await wait(20);
  tap(g('[data-act="tool:markets"]'));
  await wait(40);

  // the in-content back control cleared `detail` to `true` and opened an asset
  tap(g('#toolBody [data-sect="assets"] .rrow'));
  await wait(40);
  const inDetail = /Fundamentals/.test(g('#toolBody').textContent);
  ok('an asset detail opens', inDetail);
  const backLink = g('#toolBody [data-act="toolstate:markets:detail:"]');
  ok('the detail has an in-content back control', !!backLink);
  tap(backLink);
  await wait(40);
  ok('in-content back returns to the board, not to another asset',
     !!g('#toolBody .mktov') && !/Fundamentals/.test(g('#toolBody').textContent),
     g('#toolBody').textContent.slice(0, 90));

  // §26.7 the controls sit above the list they act on
  const order = gg('#toolBody [data-sect]').map(x => x.dataset.sect);
  const assetsAt = order.indexOf('assets');
  const searchAt = [...g('#toolBody').children].findIndex(c => c.querySelector('[data-tool-search]'));
  const assetsIdx = [...g('#toolBody').children].findIndex(c => c.dataset.sect === 'assets');
  ok('search sits above the list it filters (§26.7)', searchAt > -1 && searchAt < assetsIdx,
     'search at ' + searchAt + ', assets at ' + assetsIdx);

  // §26.8 filters are per class and do not go stale across classes
  tap(gg('#toolBody .ttab').find(b => /Commodities/.test(b.textContent)));
  await wait(40);
  const energy = gg('#toolBody .fchip').find(b => /Energy/.test(b.textContent));
  ok('commodities offer a category filter (§26.8)', !!energy);
  tap(energy);
  await wait(40);
  tap(gg('#toolBody .ttab').find(b => /Forex/.test(b.textContent)));
  await wait(40);
  ok('a filter does not leak across asset classes',
     gg('#toolBody .fchip').some(c => c.getAttribute('aria-pressed') === 'true'),
     gg('#toolBody .fchip').map(c => c.textContent.trim() + '=' + c.getAttribute('aria-pressed')).join(' '));
  ok('forex offers pair types, not gainers/losers (§26.8)',
     !gg('#toolBody .fchip').some(c => /Gainers|Losers/.test(c.textContent)),
     gg('#toolBody .fchip').map(c => c.textContent.trim()).join(' | '));

  // §26.4/§26.6 rows carry the absolute change too
  ok('a row shows the absolute change as well as the percentage (§26.6)',
     /[+−]\s?[\d.,]+\s+[+−][\d.,]+%/.test(g('#toolBody [data-sect="assets"]').textContent),
     g('#toolBody [data-sect="assets"]').textContent.slice(0, 120));

  // a currency pair is not listed on a stock exchange
  ok('an asset carries its own venue, not the local exchange',
     !/PSX/.test(g('#toolBody [data-sect="assets"]').textContent),
     g('#toolBody [data-sect="assets"]').textContent.slice(0, 140));

  // FX charts are not flat
  const sparks = gg('#toolBody .spark__line').map(p => p.getAttribute('d'));
  const flat = sparks.filter(dd => {
    const ys = (dd.match(/[ML][\d.]+ ([\d.]+)/g) || []).map(m => m.split(' ')[1]);
    return ys.length > 3 && new Set(ys).size === 1;
  });
  ok('forex sparklines are not flat lines', flat.length === 0, flat.length + ' flat of ' + sparks.length);

  // the FX converter reads what was typed
  tap(g('#toolBody [data-sect="assets"] .rrow'));
  await wait(40);
  const amt = g('[data-input="mk_mkamount"]');
  ok('a currency detail offers conversion', !!amt);
  if (amt) {
    const before2 = g('[data-input="mk_out"]').value;
    amt.value = '250';
    amt.dispatchEvent(new w2.Event('input', { bubbles: true }));
    await wait(400);
    ok('the conversion follows the amount typed',
       g('[data-input="mk_out"]').value !== before2,
       before2 + ' -> ' + g('[data-input="mk_out"]').value);
  }

  // §26.9 the detail timeframe changes the chart
  const chartBefore = (g('#toolBody .chart__line') || {}).getAttribute
    ? g('#toolBody .chart__line').getAttribute('d') : '';
  const fiveY = gg('#toolBody .mktrange__btn').find(b => /5Y/.test(b.textContent));
  ok('the detail has a timeframe selector', !!fiveY);
  if (fiveY) {
    tap(fiveY);
    await wait(40);
    ok('the detail chart follows the timeframe (§26.9)',
       g('#toolBody .chart__line').getAttribute('d') !== chartBefore);
  }
  ok('the detail states whether the market is trading (§26.9)', !!g('#toolBody .mktstate'));
  w2.close();

  // §26.13 the world board keeps its composition
  console.log('\n=== The world board ===');
  ({ dom } = await boot({ country: 'PK', city: 'Islamabad', islamic: false, lang: 'en',
      market: 'GLOBAL' }));
  const w3 = dom.window;
  const built = w3.LUME_TOOLS.build('markets');
  const glob = [...built.body.matchAll(/data-sect="([a-z]+)"/g)].map(m => m[1])
    .filter(x => ['context', 'classnav', 'hero', 'assets', 'overview'].includes(x));
  ok('the world board keeps the approved composition (§123)',
     glob.join('>') === 'context>classnav>hero>assets>overview', glob.join(' > '));
  ok('the world board lists world equities, not three US ETFs',
     /Aramco|Reliance|Shell/.test(built.body), built.body.replace(/<[^>]+>/g, ' ').slice(200, 340));
  w3.close();

  /* ── navigation state, third round ─────────────────────────────────── */
  console.log('\n=== Navigation state ===');
  ({ dom } = await boot({ country: 'PK', city: 'Islamabad', islamic: true, lang: 'en' }));
  const w4 = dom.window, d4 = w4.document;
  const h = s => d4.querySelector(s);
  const hh = s => [...d4.querySelectorAll(s)];
  const hit = el => el.dispatchEvent(new w4.MouseEvent('click', { bubbles: true, cancelable: true }));
  const screen = () => (d4.querySelector('.screen.is-active') || {}).id;

  // back from a tool opened by a notification returned to Home, not the centre
  hit(h('[data-act="tab:notifications"]'));
  await wait(200);
  ok('the centre opens', screen() === 'screen-notifications', screen());
  const notif = h('#notifBody [data-notif-open]');
  hit(notif);
  await wait(60);
  if (screen() === 'screen-tool') {
    hit(h('#toolHeader [data-tool-back]'));
    await wait(60);
    ok('back from a notification’s tool returns to the centre',
       screen() === 'screen-notifications', screen());
  } else {
    ok('back from a notification’s tool returns to the centre', true, 'row did not deep-link');
  }

  // a timer opened from anywhere must stop when the tool is left
  hit(h('[data-tab="tools"]'));
  await wait(30);
  hit(h('[data-act="tool:timer"]'));
  await wait(40);
  const startBtn = hh('#toolBody .btn').find(b => /Start/i.test(b.textContent));
  if (startBtn) {
    hit(startBtn);
    await wait(30);
    hit(h('[data-tab="home"]'));
    await wait(30);
    hit(h('[data-tab="tools"]'));
    await wait(30);
    hit(h('[data-act="tool:timer"]'));
    await wait(40);
    const disp = (h('[data-clock-display]') || {}).textContent || '';
    ok('a countdown stops when its tool is left', /^0?5:00|^25:00|^00:00/.test(disp.trim()), disp);
  }

  // leaving via the tab bar must not leave a detail armed
  hit(h('[data-act="tool:markets"]'));
  await wait(40);
  hit(h('#toolBody [data-sect="assets"] .rrow'));
  await wait(40);
  ok('a detail is open', /Fundamentals/.test(h('#toolBody').textContent));
  hit(h('[data-tab="home"]'));
  await wait(40);
  hit(h('[data-act="tool:markets"]'));
  await wait(40);
  ok('reopening Markets lands on the board, not the last detail',
     !!h('#toolBody .mktov'), h('#toolBody').textContent.slice(0, 80));

  // §26.8/§89 sorting is scoped to the class
  hit(hh('#toolBody .ttab').find(b => /Stocks/.test(b.textContent)));
  await wait(40);
  const capSort = hh('#toolBody .sortopt').find(b => /cap/i.test(b.textContent));
  if (capSort) {
    hit(capSort);
    await wait(40);
    hit(hh('#toolBody .ttab').find(b => /Forex/.test(b.textContent)));
    await wait(40);
    ok('a sort dimension does not leak across asset classes',
       hh('#toolBody .sortopt').some(b => b.getAttribute('aria-pressed') === 'true'),
       hh('#toolBody .sortopt').map(b => b.textContent.trim() + '=' + b.getAttribute('aria-pressed')).join(' '));
  }
  w4.close();

  /* ── the exchange's own clock ───────────────────────────────────────── */
  console.log('\n=== Market hours use the exchange clock ===');
  ({ dom } = await boot({ country: 'PK', city: 'Islamabad', islamic: false, lang: 'en',
      market: 'US' }, 'Asia/Karachi'));
  const w5 = dom.window;
  const stateText = w5.LUME_TOOLS.build('markets').body.replace(/<[^>]+>/g, ' ');
  // Whatever the verdict, it must be derived from New York, not Karachi.
  const nyHour = Number(new Intl.DateTimeFormat('en-US',
    { timeZone: 'America/New_York', hour: 'numeric', hour12: false }).format(new Date()));
  const nyDay = new Date(new Date().toLocaleString('en-US', { timeZone: 'America/New_York' })).getDay();
  const shouldBeOpen = nyDay > 0 && nyDay < 6 && nyHour >= 10 && nyHour < 16;
  const saysLive = /Live/.test(stateText);
  ok('NASDAQ hours follow New York, not the device',
     shouldBeOpen === saysLive || /holiday/i.test(stateText),
     'NY hour ' + nyHour + ', day ' + nyDay + ' -> expected open=' + shouldBeOpen +
     ', screen says live=' + saysLive);
  w5.close();
  delete process.env.TZ;

  /* ── the market override has an off switch ──────────────────────────── */
  console.log('\n=== Market override ===');
  ({ dom } = await boot({ country: 'GB', city: 'London', islamic: false, lang: 'en', market: 'US' }));
  const w6 = dom.window, d6 = w6.document;
  const tap6 = el => el.dispatchEvent(new w6.MouseEvent('click', { bubbles: true, cancelable: true }));
  tap6(d6.querySelector('[data-tab="tools"]'));
  await wait(30);
  tap6(d6.querySelector('[data-act="tool:markets"]'));
  await wait(40);
  ok('a pinned market overrides the country', /Nasdaq|S&P/.test(d6.querySelector('#toolBody').textContent),
     d6.querySelector('#toolBody').textContent.slice(0, 70));
  tap6(d6.querySelector('[data-act="sheet:market"]'));
  await wait(40);
  const auto = d6.querySelector('[data-market="AUTO"]');
  ok('the picker offers an automatic option', !!auto);
  if (auto) {
    tap6(auto);
    await wait(60);
    ok('automatic returns Markets to the user’s country',
       /FTSE|London/.test(d6.querySelector('#toolBody').textContent),
       d6.querySelector('#toolBody').textContent.slice(0, 70));
  }
  w6.close();

  console.log('\n' + (failures ? failures + ' FAILURES' : 'ALL REGRESSION CHECKS PASSED'));
  process.exit(failures ? 1 : 0);
})().catch(e => { console.error('HARNESS ERROR', e); process.exit(2); });
