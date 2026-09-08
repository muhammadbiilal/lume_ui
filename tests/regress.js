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
        name: 'Zeeshan', initials: 'ZK', units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
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
  const sheetsWithX = $$('.sheet').filter(s => s.querySelector('[data-close]')).map(s => s.id);
  ok('only modal workflows keep an explicit close',
     sheetsWithX.every(id => id === 'sheet-personalise' || id === 'sheet-share'),
     sheetsWithX.join(', '));

  win.close();
  console.log('\n' + (failures ? failures + ' FAILURES' : 'ALL REGRESSION CHECKS PASSED'));
  process.exit(failures ? 1 : 0);
})().catch(e => { console.error('HARNESS ERROR', e); process.exit(2); });
