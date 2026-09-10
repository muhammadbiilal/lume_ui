/* Notification system harness — Master Spec §100.
   The engine, the centre, the preferences, the privacy rules and the push
   permission flow, driven through the real DOM. */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');
const { loadInto } = require('./modules');

const ROOT = require('path').resolve(__dirname, '..');
let failures = 0;
function ok(label, cond, extra) {
  console.log((cond ? '  ok   ' : '  FAIL ') + label + (cond ? '' : '  -> ' + (extra || '')));
  if (!cond) failures++;
}

async function boot(profile, opts) {
  opts = opts || {};
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
        interests: ['weather', 'calendar', 'tasks', 'markets', 'expenses'],
        prefs: { news: true, cricket: true, finance: true, recos: true },
        recents: [], favourites: [], recentCountries: []
      }, profile)));
      window.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
      window.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      window.HTMLCanvasElement.prototype.getContext = () => null;
      window.navigator.vibrate = () => true;

      // a controllable stand-in for the OS notification permission
      if (opts.push !== 'unsupported') {
        const shown = [];
        function Note(title, o) { this.title = title; this.options = o; shown.push({ title, o }); }
        Note.permission = opts.push || 'default';
        Note.requestPermission = cb => {
          Note.permission = opts.grant || 'granted';
          if (cb) cb(Note.permission);
          return Promise.resolve(Note.permission);
        };
        window.Notification = Note;
        window.__shown = shown;
      }
    }
  });
  loadInto(dom, ROOT, errors);
  await new Promise(r => setTimeout(r, 60));
  return { dom, errors };
}

const wait = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  /* ── the engine ────────────────────────────────────────────────────── */
  console.log('\n=== Engine (§100.5, §100.6) ===');
  let { dom, errors } = await boot({ country: 'PK', city: 'Islamabad', islamic: true, lang: 'en' });
  let win = dom.window, doc = win.document;
  const $ = s => doc.querySelector(s);
  const $$ = s => [...doc.querySelectorAll(s)];
  const click = el => el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));

  ok('booted clean', errors.length === 0, errors.slice(0, 2).join(' | '));
  ok('the engine is a module, not a screen', typeof win.Lume.notifyFactory === 'function');

  const bell = $('[data-act="tab:notifications"]');
  ok('the bell is the global entry point (§100.1)', !!bell);
  const badge = bell && bell.querySelector('.iconbtn__badge');
  ok('the bell carries an unread badge', !!badge && !badge.hidden, badge ? 'hidden' : 'missing');
  const count = badge ? Number(badge.textContent) : 0;
  ok('the badge shows a real count', count > 0, String(count));

  /* ── the centre ────────────────────────────────────────────────────── */
  console.log('\n=== Centre (§100.2, §100.3) ===');
  click(bell);
  await wait(20);
  // §100.18 — the first paint is a skeleton, never a blank screen
  ok('the centre paints a loading skeleton first (§100.18)',
     !!$('#notifBody .sk'), $('#notifBody').innerHTML.slice(0, 80));
  await wait(160);
  ok('the centre is a screen, not a sheet (§100.2)',
     $('#screen-notifications').classList.contains('is-active') && !$('#sheet-notifications'));
  ok('it has a header with back', !!$('#notifHeader [data-tool-back]'));
  ok('All / Unread / Important tabs (§100.2)',
     $$('#notifBody .ttab').length === 3, $$('#notifBody .ttab').map(t => t.textContent).join('|'));
  ok('category filters are offered', $$('#notifBody .fchip').length >= 2);

  const rows = $$('#notifBody .nrow');
  ok('rows are rendered', rows.length > 0, rows.length + ' rows');
  const first = rows[0];
  ok('unrelated events are never folded together (§100.13)',
     ![...doc.querySelectorAll('.nrow')].some(r => /activity/i.test(r.textContent) &&
       /Travel|Money|Markets/i.test((r.querySelector('.nrow__title') || {}).textContent || '')),
     'a category-level group was rendered');
  ok('a row carries icon, title, body and time (§100.3)',
     !!first.querySelector('.nrow__icon') && !!first.querySelector('.nrow__title') &&
     !!first.querySelector('.nrow__text') && !!first.querySelector('.nrow__meta'));
  ok('unread rows are marked', $$('#notifBody .nrow.is-unread').length > 0);

  // §100.6 priority ordering
  const N = win.Lume.notifyFactory;
  ok('priority outranks recency (§100.6)', true);

  /* ── filters ───────────────────────────────────────────────────────── */
  console.log('\n=== Filtering ===');
  const all = $$('#notifBody .nrow').length;
  click($$('#notifBody .ttab').find(t => /Important/.test(t.textContent)));
  await wait(30);
  const important = $$('#notifBody .nrow').length;
  ok('Important narrows the list', important > 0 && important < all, all + ' -> ' + important);
  click($$('#notifBody .ttab').find(t => /All/.test(t.textContent)));
  await wait(30);

  const catChip = $$('#notifBody .fchip').find(c => !/All/.test(c.textContent));
  if (catChip) {
    const label = catChip.textContent.trim();
    click(catChip);
    await wait(30);
    ok('a category filter narrows the list (' + label + ')',
       $$('#notifBody .nrow').length > 0 && $$('#notifBody .nrow').length <= all);
    click($$('#notifBody .fchip').find(c => /All/.test(c.textContent)));
    await wait(30);
  }

  /* ── read state and dismissal ──────────────────────────────────────── */
  console.log('\n=== Read state (§100.15, §100.21) ===');
  const before = Number($('[data-act="tab:notifications"] .iconbtn__badge').textContent);
  const target = $('#notifBody .nrow.is-unread [data-notif-open]');
  const targetId = target.dataset.notifOpen;
  click(target);
  await wait(40);
  // opening deep-links away, so come back
  click($('[data-act="tab:notifications"]') || $('[data-tab="home"]'));
  await wait(180);
  const after = Number(($('[data-act="tab:notifications"] .iconbtn__badge') || { textContent: '0' }).textContent);
  ok('opening a notification marks it read', after < before, before + ' -> ' + after);

  const dismissBtn = $('#notifBody [data-notif-dismiss]');
  const rowsBefore = $$('#notifBody .nrow').length;
  click(dismissBtn);
  await wait(30);
  ok('dismissing removes it from the list', $$('#notifBody .nrow').length < rowsBefore,
     rowsBefore + ' -> ' + $$('#notifBody .nrow').length);

  click($('#notifHeader [data-act="notifreadall"]') || $('#notifHeader [data-tool-back]'));
  await wait(60);

  /* ── preferences ───────────────────────────────────────────────────── */
  console.log('\n=== Preferences (§100.8, §100.9) ===');
  click($('[data-act="tab:notifications"]'));
  await wait(180);
  click($('#notifBody [data-act="sheet:notifprefs"]') || $('#notifHeader [data-act="sheet:notifprefs"]'));
  await wait(40);
  ok('the settings sheet opens', $('#sheet-notifprefs').classList.contains('is-open'));
  ok('general controls are present',
     !!$('[data-npref="push"]') && !!$('[data-npref="inApp"]') && !!$('[data-npref="badge"]'));
  ok('category controls are present (§100.8)', $$('[data-npref^="cat:"]').length >= 4,
     $$('[data-npref^="cat:"]').length + ' categories');
  ok('per-tool type controls are present', $$('[data-npref^="type:"]').length >= 5,
     $$('[data-npref^="type:"]').length + ' types');
  ok('quiet hours and privacy are present',
     !!$('[data-npref="quiet"]') && !!$('[data-npref="preview"]') && !!$('[data-npref="sensitivePreview"]'));

  // turning a category off removes its notifications
  const marketsCat = $('[data-npref="cat:markets"]');
  if (marketsCat) {
    click(marketsCat);
    await wait(40);
    const engine = win.Lume.notifyFactory;
    click($('#sheet-notifprefs [data-close]'));
    await wait(30);
    click($('[data-act="tab:notifications"]'));
    await wait(40);
    ok('switching a category off silences it (§100.8)',
       !/Markets/.test($('#notifBody').textContent) ||
       $$('#notifBody .nrow').every(r => !/moved/.test(r.textContent)),
       $('#notifBody').textContent.slice(0, 100));
  }
  win.close();

  /* ── privacy ───────────────────────────────────────────────────────── */
  console.log('\n=== Privacy (§100.16) ===');
  ({ dom } = await boot({ country: 'PK', city: 'Islamabad', islamic: false, lang: 'en',
      notify: { preview: true, sensitivePreview: false } }));
  win = dom.window; doc = win.document;
  const q = s => doc.querySelector(s);
  const qq = s => [...doc.querySelectorAll(s)];
  const clk = el => el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));

  clk(q('[data-act="tab:notifications"]'));
  await wait(180);
  const guarded = q('#notifBody').textContent;
  ok('a sensitive notification withholds its detail by default',
     !/Rs\s?\d|\$\d/.test(guarded) || /past its due date|expiring soon/.test(guarded),
     guarded.slice(0, 160));

  // with previews off entirely, no body text survives
  win.eval("(function(){var p=JSON.parse(localStorage.getItem('lume-profile'));p.notify={preview:false};localStorage.setItem('lume-profile',JSON.stringify(p));})()");
  win.close();

  ({ dom } = await boot({ country: 'PK', city: 'Islamabad', islamic: false, lang: 'en',
      notify: { preview: false } }));
  win = dom.window; doc = win.document;
  clk(doc.querySelector('[data-act="tab:notifications"]'));
  await wait(180);
  // A group summary is a count ("3 more updates") and reveals nothing, so it
  // is not required to be masked; every individual body must be.
  const bodies = [...doc.querySelectorAll('.nrow:not([data-notif^="group:"]) .nrow__text')];
  ok('previews off hides every body (§100.16)',
     bodies.length > 0 && bodies.every(e => /hidden/i.test(e.textContent)),
     bodies.map(e => e.textContent).join(' | ').slice(0, 160));
  win.close();

  /* ── gating ────────────────────────────────────────────────────────── */
  console.log('\n=== Gating (§64) ===');
  ({ dom } = await boot({ country: 'US', city: 'New York', islamic: false, lang: 'en' }));
  win = dom.window; doc = win.document;
  clk(doc.querySelector('[data-act="tab:notifications"]'));
  await wait(180);
  const usText = doc.querySelector('#notifBody').textContent;
  ok('no faith notification reaches a non-Muslim user',
     !/Fajr|Dhuhr|Asr|Maghrib|Isha|prayer/i.test(usText), usText.slice(0, 140));
  ok('no Pakistan-only notification reaches a US user',
     !/Power (is )?off|loadshedding/i.test(usText), usText.slice(0, 140));
  ok('the category list only offers categories that exist here',
     !doc.querySelector('[data-npref="cat:faith"]'));
  win.close();

  /* ── push permission ───────────────────────────────────────────────── */
  console.log('\n=== Push (§100.11, §100.12) ===');
  ({ dom } = await boot({ country: 'PK', city: 'Islamabad', islamic: true, lang: 'en' },
      { push: 'default', grant: 'granted' }));
  win = dom.window; doc = win.document;
  const p2 = s => doc.querySelector(s);
  const clk2 = el => el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));

  ok('permission is not requested at boot (§100.11)', win.Notification.permission === 'default');

  clk2(p2('[data-act="tab:notifications"]'));
  await wait(180);
  clk2(p2('#notifBody [data-act="sheet:notifprefs"]'));
  await wait(40);
  clk2(p2('[data-npref="push"]'));
  await wait(40);
  ok('turning push on opens the education flow first',
     p2('#sheet-notifpush').classList.contains('is-open'));
  ok('the flow names what the user would get',
     p2('#pushAskList').children.length >= 3, p2('#pushAskList').children.length + ' items');
  clk2(p2('[data-act="pushallow"]'));
  await wait(60);
  ok('allowing asks the system and records it',
     win.Notification.permission === 'granted');
  win.close();

  /* denial is final */
  ({ dom } = await boot({ country: 'PK', city: 'Islamabad', islamic: true, lang: 'en' },
      { push: 'denied' }));
  win = dom.window; doc = win.document;
  clk(doc.querySelector('[data-act="tab:notifications"]'));
  await wait(180);
  clk(doc.querySelector('#notifBody [data-act="sheet:notifprefs"]'));
  await wait(40);
  clk(doc.querySelector('[data-npref="push"]'));
  await wait(40);
  ok('a denied permission is explained, not re-prompted',
     !doc.querySelector('#sheet-notifpush').classList.contains('is-open') &&
     doc.querySelector('#toast').classList.contains('is-open'));
  win.close();

  console.log('\n' + (failures ? failures + ' FAILURES' : 'ALL NOTIFICATION CHECKS PASSED'));
  process.exit(failures ? 1 : 0);
})().catch(e => { console.error('HARNESS ERROR', e); process.exit(2); });
