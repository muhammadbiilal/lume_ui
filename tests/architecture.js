/* ============================================================
   Lume — architecture checks

   The rules that keep the screen-based structure from decaying
   back into one file. These are not about what the app shows;
   they are about who is allowed to know what.

     · the module graph is acyclic and every specifier resolves
     · the same graph resolves over real HTTP, not only through
       the harness bundler
     · every catalogue feature has exactly one tool module, and
       every tool module is a catalogue feature
     · a screen module reaches only its own DOM
     · the lifecycle honours its ordering guarantees
     · navigating away and back leaves no duplicate listeners
       and no surviving timers
   ============================================================ */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { JSDOM, VirtualConsole } = require('jsdom');
const { order, codeMatches, IMPORT_RE, resolveSpec, loadInto } = require('./modules');

const ROOT = path.resolve(__dirname, '..');
const ENTRY = 'assets/js/main.js';

let failures = 0;
function ok(label, cond, extra) {
  console.log((cond ? '  ok   ' : '  FAIL ') + label + (cond ? '' : '  -> ' + (extra || '')));
  if (!cond) failures++;
}

const wait = ms => new Promise(r => setTimeout(r, ms));

function allModules() {
  return order(ENTRY, ROOT);
}

async function boot(profile, extra) {
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const vc = new VirtualConsole();
  const errors = [];
  vc.on('jsdomError', e => errors.push(String(e.message || e)));
  vc.on('error', (...a) => errors.push(a.map(String).join(' ')));
  const timers = { intervals: new Set(), listeners: [] };

  const dom = new JSDOM(html, {
    url: 'http://localhost/index.html',
    runScripts: 'dangerously',
    virtualConsole: vc,
    pretendToBeVisual: true,
    beforeParse(window) {
      window.localStorage.setItem('lume-onboarded', '1');
      window.localStorage.setItem('lume-profile', JSON.stringify(Object.assign({
        units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
        interests: ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news', 'markets'],
        prefs: { news: true, cricket: true, finance: true, recos: true },
        recents: [], favourites: [], recentCountries: []
      }, profile || {})));
      window.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
      window.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      window.cancelAnimationFrame = id => clearTimeout(id);
      window.HTMLCanvasElement.prototype.getContext = () => null;
      window.navigator.vibrate = () => true;
      window.scrollTo = () => {};

      /* Count what the app leaves running and listening, so a screen that
         forgets to clean up is visible rather than merely slow. */
      const realSetInterval = window.setInterval;
      const realClearInterval = window.clearInterval;
      window.setInterval = function (fn, ms) {
        const id = realSetInterval.call(window, fn, ms);
        timers.intervals.add(id);
        return id;
      };
      window.clearInterval = function (id) {
        timers.intervals.delete(id);
        return realClearInterval.call(window, id);
      };
      const realAdd = window.document.addEventListener.bind(window.document);
      window.document.addEventListener = function (type, fn, opts) {
        timers.listeners.push(type);
        return realAdd(type, fn, opts);
      };
      if (extra) extra(window);
    }
  });
  loadInto(dom, ROOT, errors);
  await wait(80);
  return { dom, win: dom.window, doc: dom.window.document, errors, timers };
}

(async () => {
  /* ── 1. the module graph ─────────────────────────────────────────────── */
  console.log('\n=== The module graph ===');

  let modules = null;
  try {
    modules = allModules();
    ok('the graph resolves from one entry point and has no cycle', true);
  } catch (e) {
    ok('the graph resolves from one entry point and has no cycle', false, e.message);
  }

  if (modules) {
    console.log('  ' + modules.length + ' modules reachable from ' + ENTRY);

    /* Dependency direction: core knows nothing about screens or tools. */
    const violations = [];
    for (const key of modules) {
      const src = fs.readFileSync(path.join(ROOT, key), 'utf8');
      const targets = codeMatches(src, IMPORT_RE).map(m => resolveSpec(key, m[3], ROOT));
      if (/\/core\//.test(key)) {
        targets.filter(x => /\/screens\/|\/tools\//.test(x))
          .forEach(x => violations.push(key + ' -> ' + x));
      }
      if (/\/tools\//.test(key)) {
        targets.filter(x => /\/screens\//.test(x))
          .forEach(x => violations.push(key + ' -> ' + x));
      }
    }
    ok('core never imports a screen, and a tool never imports a screen',
       violations.length === 0, violations.join(', '));

    /* Nothing may be orphaned in assets/js — an unreachable file is either
       dead or a missing import, and both are worth failing over. */
    const onDisk = [];
    (function walk(dir) {
      for (const name of fs.readdirSync(path.join(ROOT, dir))) {
        const rel = dir + '/' + name;
        if (fs.statSync(path.join(ROOT, rel)).isDirectory()) walk(rel);
        else if (name.endsWith('.js')) onDisk.push(rel);
      }
    })('assets/js');
    const unreachable = onDisk.filter(f => modules.indexOf(f) === -1);
    ok('every file under assets/js is reachable from the entry point',
       unreachable.length === 0, unreachable.join(', '));
  }

  /* ── 2. the same graph over real HTTP ────────────────────────────────── */
  console.log('\n=== The graph a browser would walk ===');
  {
    const server = http.createServer((req, res) => {
      const rel = decodeURIComponent(req.url.split('?')[0]).replace(/^\//, '') || 'index.html';
      const file = path.join(ROOT, rel);
      if (!file.startsWith(ROOT) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        res.writeHead(404); res.end('not found'); return;
      }
      const type = file.endsWith('.js') ? 'text/javascript'
        : file.endsWith('.css') ? 'text/css' : 'text/html';
      res.writeHead(200, { 'Content-Type': type });
      res.end(fs.readFileSync(file));
    });
    await new Promise(r => server.listen(0, '127.0.0.1', r));
    const port = server.address().port;

    const get = url => new Promise(resolve => {
      http.get(url, res => {
        const chunks = [];
        res.on('data', c => chunks.push(c));
        res.on('end', () => resolve({ status: res.statusCode, body: Buffer.concat(chunks).toString('utf8') }));
      }).on('error', () => resolve({ status: 0, body: '' }));
    });

    const page = await get('http://127.0.0.1:' + port + '/index.html');
    ok('index.html is served', page.status === 200);

    const entryTag = /<script[^>]+type="module"[^>]+src="([^"]+)"/.exec(page.body);
    ok('and asks for exactly one module entry point',
       !!entryTag && (page.body.match(/<script[^>]+src=/g) || []).length === 1,
       page.body.match(/<script[^>]+src=[^>]*>/g));

    /* Every stylesheet the shell names must exist too. */
    const styles = [...page.body.matchAll(/<link[^>]+rel="stylesheet"[^>]+href="(assets\/[^"]+)"/g)].map(m => m[1]);
    const missingCss = [];
    for (const href of styles) {
      const r = await get('http://127.0.0.1:' + port + '/' + href);
      if (r.status !== 200) missingCss.push(href);
    }
    ok('every stylesheet it links resolves', missingCss.length === 0, missingCss.join(', '));

    /* Splitting a stylesheet is only safe where nothing is declared twice.
       A selector that appears in two sheets is decided by load order, so
       the pairs that do it are listed deliberately here — anything else
       showing up means a rule was moved into a file where it can be
       silently overridden, or silently start overriding. */
    const ALLOWED_OVERRIDES = [
      // screen sheets deliberately override the shared component sheet
      'components.css|screens/today.css',
      'components.css|screens/explore.css',
      'components.css|screens/home.css',
      // themes and keyframes, declared per sheet by design
      'auth.css|tokens.css',
      'auth.css|tokens.css|tools/shared.css',
      'auth.css|base.css',
      'auth.css|base.css|onboarding.css',
      'auth.css|components.css',
      'auth.css|screens/shared.css',
      'base.css|onboarding.css',
      'components.css|tools/shared.css',
      'screens/shared.css|tools/shared.css'
    ];
    const declaredIn = new Map();
    for (const href of styles) {
      const body = (await get('http://127.0.0.1:' + port + '/' + href)).body
        .replace(/\/\*[\s\S]*?\*\//g, '');
      const sheet = href.replace('assets/css/', '');
      for (const m of body.matchAll(/(^|\})\s*([^{}@]+?)\s*\{/g)) {
        for (const raw of m[2].split(',')) {
          const sel = raw.split(/\s+/).filter(Boolean).join(' ');
          if (!sel) continue;
          if (!declaredIn.has(sel)) declaredIn.set(sel, new Set());
          declaredIn.get(sel).add(sheet);
        }
      }
    }
    const unexpected = [];
    for (const [sel, sheets] of declaredIn) {
      if (sheets.size < 2) continue;
      const key = [...sheets].sort().join('|');
      if (ALLOWED_OVERRIDES.indexOf(key) === -1) unexpected.push(sel + ' in ' + key);
    }
    ok('no selector is split across stylesheets by accident',
       unexpected.length === 0, unexpected.slice(0, 6).join('; '));

    /* Walk the import graph the way a browser does: fetch, read the
       specifiers out of what came back, fetch those. A path that only works
       because the harness normalised it fails here. */
    if (entryTag) {
      const seen = new Set();
      const missing = [];
      async function walk(rel) {
        if (seen.has(rel)) return;
        seen.add(rel);
        const r = await get('http://127.0.0.1:' + port + '/' + rel);
        if (r.status !== 200) { missing.push(rel); return; }
        for (const m of codeMatches(r.body, IMPORT_RE)) {
          const next = path.posix.normalize(path.posix.join(path.posix.dirname(rel), m[3]));
          await walk(next);
        }
      }
      await walk(entryTag[1]);
      ok('every import specifier resolves to a served file over HTTP',
         missing.length === 0, missing.join(', '));
      ok('and the served graph is the same size as the bundled one',
         !modules || seen.size === modules.length,
         'http=' + seen.size + ' bundle=' + (modules ? modules.length : '?'));
    }
    server.close();
  }

  /* ── 3. the tool registry ────────────────────────────────────────────── */
  console.log('\n=== The tool registry ===');
  {
    const { win, errors } = await boot();
    if (errors.length) errors.slice(0, 3).forEach(e => ok('boot is clean', false, e));

    const cat = win.Lume.catalogue.FEATURES.map(f => f.id);
    const registered = win.Lume.tools.ids();

    ok('every catalogue feature has a tool module',
       cat.every(id => registered.indexOf(id) !== -1),
       cat.filter(id => registered.indexOf(id) === -1).join(', '));
    ok('every registered tool is a catalogue feature',
       registered.every(id => cat.indexOf(id) !== -1),
       registered.filter(id => cat.indexOf(id) === -1).join(', '));
    ok('no id is registered twice',
       registered.length === new Set(registered).size);
    ok('the counts agree with the catalogue',
       cat.length === registered.length, cat.length + ' vs ' + registered.length);
  }

  /* ── 4. the lifecycle contract ───────────────────────────────────────── */
  console.log('\n=== The lifecycle ===');
  {
    const { win } = await boot();
    const make = win.Lume.createLifecycle;
    ok('the lifecycle controller is reachable for testing', typeof make === 'function');

    if (typeof make === 'function') {
      const log = [];
      const screen = {
        id: 'probe',
        mount() { log.push('mount'); },
        render() { log.push('render'); },
        onEnter() { log.push('enter'); },
        onLeave() { log.push('leave'); },
        unmount() { log.push('unmount'); }
      };
      const lc = make({});
      lc.register(screen);

      lc.mount('probe', win.document.createElement('div'));
      lc.mount('probe', win.document.createElement('div'));
      ok('mounting twice mounts once', log.filter(x => x === 'mount').length === 1);

      lc.enter('probe');
      lc.enter('probe');
      ok('entering twice enters once', log.filter(x => x === 'enter').length === 1);

      lc.leave('probe');
      lc.leave('probe');
      ok('leaving twice leaves once', log.filter(x => x === 'leave').length === 1);

      lc.enter('probe');
      lc.unmount('probe');
      ok('unmounting a visible screen lets it leave first',
         log.join('>').endsWith('enter>leave>unmount'), log.join('>'));

      lc.leave('probe');
      ok('and a screen never leaves after it has unmounted',
         log.filter(x => x === 'leave').length === 2, log.join('>'));

      const thrower = make({ onError: () => log.push('caught') });
      thrower.register({ id: 'bad', mount() { throw new Error('boom'); } });
      let survived = true;
      try { thrower.mount('bad', win.document.createElement('div')); } catch (e) { survived = false; }
      ok('a screen that throws while mounting does not take navigation down', survived);

      ok('an unknown screen is a no-op, not a crash',
         lc.enter('nope') === false && lc.leave('nope') === false && lc.unmount('nope') === false);
    }
  }

  /* ── 5. repeat navigation ────────────────────────────────────────────── */
  console.log('\n=== Repeat navigation ===');
  {
    const { win, doc, timers, errors } = await boot({ country: 'PK', islamic: true });
    const click = sel => {
      const el = doc.querySelector(sel);
      if (el) el.dispatchEvent(new win.MouseEvent('click', { bubbles: true }));
      return !!el;
    };

    const listenersAtRest = timers.listeners.length;
    const intervalsAtRest = timers.intervals.size;

    /* Round-trip every tab several times. */
    const tabs = [...doc.querySelectorAll('.tab')].map(t => t.dataset.tab);
    ok('the tab bar rendered', tabs.length >= 4, tabs.join(','));
    for (let round = 0; round < 4; round++) {
      for (const tab of tabs) {
        click('.tab[data-tab="' + tab + '"]');
        await wait(5);
      }
    }
    await wait(40);

    ok('re-entering a screen binds no further document listeners',
       timers.listeners.length === listenersAtRest,
       'was ' + listenersAtRest + ', now ' + timers.listeners.length);
    /* Fewer is not a failure: a screen that stops its countdown on the way
       out is the point. Growth across identical round trips is the defect. */
    ok('and leaves no extra interval running',
       timers.intervals.size <= intervalsAtRest,
       'was ' + intervalsAtRest + ', now ' + timers.intervals.size);
    ok('exactly one screen is showing afterwards',
       doc.querySelectorAll('.screen.is-active').length === 1,
       String(doc.querySelectorAll('.screen.is-active').length));
    ok('exactly one tab is selected',
       doc.querySelectorAll('.tab[aria-selected="true"]').length === 1);
    ok('nothing threw along the way', errors.length === 0, errors.slice(0, 2).join(' | '));

    /* Open a tool, leave it, open it again — the tool host is the screen
       most likely to leave a countdown behind.

       The measurement takes one warm-up cycle first and compares against
       that, not against the state before any of it. Landing back on a
       screen that legitimately starts a timer would otherwise read as a
       leak on the first cycle and hide a real one on the later cycles;
       what actually matters is whether identical cycles keep adding. */
    async function toolRoundTrip() {
      win.eval(`(function(){
        var b=document.createElement('button');
        b.setAttribute('data-act','tool:timer');
        document.body.appendChild(b);
        b.dispatchEvent(new MouseEvent('click',{bubbles:true}));
        b.remove();
      })()`);
      await wait(10);
      if (!click('#screen-tool [data-act="back"]')) click('.tab[data-tab="home"]');
      await wait(10);
    }

    await toolRoundTrip();
    await wait(20);
    const afterFirstTrip = timers.intervals.size;

    for (let i = 0; i < 3; i++) await toolRoundTrip();
    await wait(30);

    ok('three more trips through a tool add no timer to the first',
       timers.intervals.size <= afterFirstTrip,
       'after one trip ' + afterFirstTrip + ', after four ' + timers.intervals.size);
  }

  /* ── 6. the first run ────────────────────────────────────────────────── */
  console.log('\n=== The first run ===');
  {
    /* Onboarding and the pickers are the code least likely to be reached by
       a test that starts from a settled profile, and most likely to be left
       holding a name that moved during a refactor. Walking the tour once,
       watching for anything thrown, is what makes that visible. */
    const { win, doc, errors } = await boot(null, w => {
      w.localStorage.removeItem('lume-onboarded');
    });
    const hit = el => el && el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));

    ok('the tour runs on a first launch', !doc.querySelector('#onb').hidden);

    const nextIn = () => [...doc.querySelectorAll(
      '.onb-step.is-active [data-onb-next], .onb-step.is-active #onbPickNext')][0];
    for (let step = 0; step < 10; step++) {
      const button = nextIn();
      if (!button || button.disabled) break;
      hit(button);
      await wait(40);
    }

    const named = doc.querySelector('#onbName');
    ok('it reaches the step that asks for a name', !!named);
    if (named) {
      named.value = 'Ayesha';
      named.dispatchEvent(new win.Event('input', { bubbles: true }));
      hit(doc.querySelector('#onbNameNext'));
      await wait(60);
      ok('and the name it was given is the name it uses',
         /Ayesha/.test((doc.querySelector('#onbDoneTitle') || {}).textContent || ''),
         (doc.querySelector('#onbDoneTitle') || {}).textContent);
    }

    hit(doc.querySelector('#onbFinish'));
    await wait(80);
    ok('finishing lands in the app', !!doc.querySelector('.screen.is-active'));

    /* The location and interest pickers, which onboarding and the
       Personalisation sheet share. */
    hit(doc.querySelector('[data-sheet="personalise"]') || doc.querySelector('[data-act="sheet:personalise"]'));
    await wait(80);
    ok('the Personalisation sheet opens', !!doc.querySelector('#sheet-personalise.is-open'));
    ok('and its interest picker is filled',
       (doc.querySelector('#setPicker') || { children: [] }).children.length > 0);

    ok('nothing threw across the whole first run', errors.length === 0,
       errors.slice(0, 3).join(' | '));
  }

  /* ── 7. screen isolation ─────────────────────────────────────────────── */
  console.log('\n=== Screen isolation ===');
  {
    const dir = path.join(ROOT, 'assets/js/screens');
    if (!fs.existsSync(dir)) {
      console.log('  (no screen modules yet)');
    } else {
      const files = fs.readdirSync(dir).filter(f => f.endsWith('.js'));
      ok('there are screen modules to check', files.length > 0);
      const leaks = [];
      for (const file of files) {
        const own = file.replace(/\.screen\.js$/, '');
        const src = fs.readFileSync(path.join(dir, file), 'utf8');
        /* A screen naming another screen's root by id is reaching across
           the boundary the whole refactor exists to draw. */
        for (const m of src.matchAll(/#screen-([a-z]+)/g)) {
          if (m[1] !== own) leaks.push(file + ' -> #screen-' + m[1]);
        }
      }
      ok('no screen module reaches into another screen\'s DOM',
         leaks.length === 0, leaks.join(', '));
    }
  }

  console.log(failures ? '\n' + failures + ' FAILURE(S)' : '\nALL ARCHITECTURE CHECKS PASSED');
  process.exit(failures ? 1 : 0);
})().catch(e => { console.error('HARNESS ERROR', e); process.exit(2); });
