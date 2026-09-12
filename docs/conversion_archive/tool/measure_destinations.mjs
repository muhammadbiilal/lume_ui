/* Read Home and the Tools hub out of the running prototype.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/measure_destinations.mjs \
 *     --screen home --state muslim_pk --width 390 --height 844 \
 *     --theme light --lang en --shot 1
 *
 * Same method as `measure_auth.mjs`, with one addition that matters more here
 * than it did there: besides `getBoundingClientRect` for a named set of
 * elements, this dumps the **composition** — which slides the carousel kept and
 * in what order, which eight tools filled the grid, which live cards survived,
 * which categories rendered and how many tools each holds.
 *
 * Those lists are the part of Home and Tools that is easiest to get subtly
 * wrong and impossible to see in a screenshot: a round-robin that drains one
 * interest, a category count that disagrees with the grid under it, a hidden
 * feature that reappears through recents. So they are captured as data and the
 * Flutter side asserts against them.
 *
 * A state is set by writing `lume-profile` before the app boots, which is the
 * same store `app-store.js` reads. Nothing is driven through the interface, so
 * the state cannot depend on a click landing.
 */
import { spawn } from 'node:child_process';
import {
  mkdtempSync, cpSync, writeFileSync, readFileSync, mkdirSync, rmSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const argv = process.argv.slice(2);
const args = {};
for (let i = 0; i < argv.length; i++) {
  if (argv[i].startsWith('--')) args[argv[i].slice(2)] = argv[i + 1];
}

const REF = resolve(args.ref || process.cwd());
const CHROME =
  args.chrome || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = resolve(args.out || 'docs/conversion_archive/measurements');
const WIDTH = Number(args.width || 390);
const HEIGHT = Number(args.height || 844);
const THEME = args.theme || 'light';
const LANG = args.lang || 'en';
const DIR = args.dir || (LANG === 'en' ? 'ltr' : 'rtl');
const SCREEN = args.screen || 'home';
const STATE = args.state || 'default_pk';
const SHOT = args.shot === '1' || args.shot === 'true';
const SHOTS = resolve(args.shots || 'docs/conversion_archive/shots/destinations');
/* How far down the active screen is scrolled before anything is read. The
   screen is its own scroller, so a page-level capture cannot reach the lower
   sections; this moves the screen instead of the window. */
const SCROLL = Number(args.scroll || 0);
const PORT = Number(args.port || 8181);
const CDP_PORT = Number(args.cdpPort || 9359);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/* ---- the states ---------------------------------------------------------
 * Each is a whole profile, written to `lume-profile`. The seven default
 * interests are what `app-store.js` gives an onboarded user who chose none.
 */
const DEFAULTS = ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news'];

const base = {
  displayName: '', photo: '',
  country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad',
  islamic: false, lang: 'en', units: 'auto', currency: 'auto', clock: 'auto',
  method: 'MWL', interests: DEFAULTS.slice(),
  prefs: { news: true, cricket: true, finance: true, recos: true },
  recents: [], favourites: [], market: null, recentCountries: [],
};

const STATES = {
  /* Non-Muslim, Pakistan. The primary cell. */
  default_pk: { ...base },
  /* Muslim, Pakistan — the faith dimension on, with faith interests. */
  muslim_pk: {
    ...base,
    islamic: true,
    interests: [...DEFAULTS, 'prayer', 'quran', 'duas'],
  },
  /* Muslim, United Kingdom — faith on, no Pakistani service. */
  muslim_gb: {
    ...base,
    islamic: true,
    country: 'GB', region: 'England', city: 'London',
    interests: [...DEFAULTS, 'prayer', 'quran'],
  },
  /* Non-Muslim, United States. */
  default_us: {
    ...base,
    country: 'US', region: 'New York', city: 'New York',
  },
  /* Someone with a name, favourites and a history. */
  named_pk: {
    ...base,
    displayName: 'Amina Tariq',
    favourites: ['currency', 'qibla', 'notes'],
    recents: ['calculator', 'weather', 'todos'],
  },
  /* Content switches off — the third gate, which nothing else exercises. */
  prefs_off_pk: {
    ...base,
    prefs: { news: false, cricket: false, finance: false, recos: true },
  },
  /* Nobody chose anything. The quick grid falls back. */
  no_interests_pk: { ...base, interests: [] },
};

/* ---- what is measured --------------------------------------------------- */
const HOME_TARGETS = {
  'screen': '#screen-home',
  'appbar': '.appbar',
  'appbar.text': '.appbar__text',
  'appbar.greet': '.appbar__greet',
  'appbar.sub': '.appbar__sub',
  'appbar.city': '#appbarCity',
  'appbar.search': '.appbar .iconbtn[data-sheet="search"]',
  'appbar.bell': '.appbar .iconbtn[data-act="tab:notifications"]',
  'appbar.avatar': '#appbarAvatar',
  'ctx': '#screen-home .ctx:not([hidden])',
  'ctx.icon': '#screen-home .ctx:not([hidden]) .ctx__icon',
  'ctx.label': '#screen-home .ctx:not([hidden]) .ctx__label',
  'ctx.title': '#screen-home .ctx:not([hidden]) .ctx__title',
  'ctx.count': '#screen-home .ctx:not([hidden]) .ctx__count',
  'ctx.unit': '#screen-home .ctx:not([hidden]) .ctx__unit',
  'hero': '.hero',
  'hero.track': '#heroTrack',
  'hero.slide': '#heroTrack .slide:not(.is-off)',
  'hero.kicker': '#heroTrack .slide:not(.is-off) .slide__kicker',
  'hero.title': '#heroTrack .slide:not(.is-off) .slide__title',
  'hero.text': '#heroTrack .slide:not(.is-off) .slide__text',
  'hero.cta': '#heroTrack .slide:not(.is-off) .slide__cta',
  'hero.pill': '#heroTrack .slide:not(.is-off) .slide__pill',
  'hero.dots': '#heroDots',
  'hero.dot': '#heroDots .hero__dot',
  'qactions': '#quickActions',
  'qaction': '#quickActions .qaction',
  'qaction.icon': '#quickActions .qaction__icon',
  'qaction.label': '#quickActions .qaction__label',
  'quick.section': '#quickTools',
  'quick.head': '#screen-home .section:has(#quickTools) .section__head',
  'quick.title': '#screen-home .section:has(#quickTools) .section__title',
  'quick.sub': '#quickToolsSub',
  'quick.link': '#screen-home .section:has(#quickTools) .section__link',
  'tool': '#quickTools .tool',
  'tool.icon': '#quickTools .tool__icon',
  'tool.label': '#quickTools .tool__label',
  'tool.value': '#quickTools .tool__value',
  'live.wrap': '#liveWrap',
  'live.title': '#liveWrap .section__title',
  'live.sub': '#liveSub',
  'livecard': '#liveNow .livecard',
  'livecard.icon': '#liveNow .livecard__icon',
  'livecard.title': '#liveNow .livecard__title',
  'livecard.meta': '#liveNow .livecard__meta',
  'livecard.value': '#liveNow .livecard__value',
  'livecard.sub': '#liveNow .livecard__sub',
  'livecard.delta': '#liveNow .delta',
  'glance.title': '#screen-home .section:has(#glanceSub) .section__title',
  'glance.sub': '#glanceSub',
  'glance.link': '#screen-home .section:has(#glanceSub) .section__link',
  'progress': '#screen-home .progress-card:not([hidden])',
  'progress.art': '#screen-home .progress-card:not([hidden]) .progress-card__art',
  'progress.title': '#screen-home .progress-card:not([hidden]) .progress-card__title',
  'progress.meta': '#screen-home .progress-card:not([hidden]) .progress-card__meta',
  'progress.bar': '#screen-home .progress-card:not([hidden]) .bar',
  'progress.fill': '#screen-home .progress-card:not([hidden]) .bar__fill',
  'progress.round': '#screen-home .progress-card:not([hidden]) .roundbtn',
  'statrow': '#screen-home .stat-row:not([hidden])',
  'statrow.icon': '#screen-home .stat-row:not([hidden]) .stat-row__icon',
  'statrow.title': '#screen-home .stat-row:not([hidden]) .stat-row__title',
  'statrow.tag': '#screen-home .stat-row:not([hidden]) .tag',
  'statrow.meta': '#screen-home .stat-row:not([hidden]) .stat-row__meta',
  'statrow.value': '#screen-home .stat-row:not([hidden]) .stat-row__value',
  'statrow.delta': '#screen-home .stat-row:not([hidden]) .stat-row__delta',
  'upcoming.wrap': '#upcomingWrap',
  'upcoming.title': '#upcomingWrap .section__title',
  'upcoming.rows': '#upcomingList .rows',
  'crow': '#upcomingList .crow',
  'crow.icon': '#upcomingList .crow__icon',
  'crow.label': '#upcomingList .crow__label',
  'crow.value': '#upcomingList .crow__value',
  'discover.title': '#screen-home .section:has(#homeDiscover) .section__title',
  'discover.link': '#screen-home .section:has(#homeDiscover) .section__link',
  'hscroll': '#homeDiscover',
  'minicard': '#homeDiscover .minicard:not([hidden])',
  'minicard.art': '#homeDiscover .minicard:not([hidden]) .minicard__art',
  'minicard.title': '#homeDiscover .minicard:not([hidden]) .minicard__title',
  'minicard.meta': '#homeDiscover .minicard:not([hidden]) .minicard__meta',
  'shell.tabbar': '#tabbar',
};

const TOOLS_TARGETS = {
  'screen': '#screen-tools',
  'pagehead': '#screen-tools .page-head',
  'pagehead.bar': '#screen-tools .page-head__bar',
  'pagehead.title': '.page-head__title',
  'pagehead.sub': '#toolSub',
  'pagehead.action': '#screen-tools .page-head .iconbtn',
  'search': '#screen-tools .search',
  'search.input': '#toolSearch',
  'chips': '#toolChips',
  'chip': '#toolChips .chip',
  'chip.active': '#toolChips .chip.is-active',
  'recent.wrap': '#toolRecent',
  'recent.title': '#toolRecent .section__title',
  'recent': '#toolRecentList .recent',
  'recent.icon': '#toolRecentList .recent__icon',
  'recent.label': '#toolRecentList .recent__label',
  'cat': '#toolCats .cat:not([style*="display: none"])',
  'cat.head': '#toolCats .cat:not([style*="display: none"]) .cat__head',
  'cat.dot': '#toolCats .cat:not([style*="display: none"]) .cat__dot',
  'cat.title': '#toolCats .cat:not([style*="display: none"]) .cat__title',
  'cat.sub': '#toolCats .cat:not([style*="display: none"]) .cat__sub',
  'cat.count': '#toolCats .cat:not([style*="display: none"]) .cat__count',
  'cat.grid': '#toolCats .cat:not([style*="display: none"]) .cat-grid',
  'cattool': '#toolCats .cat-tool:not(.is-hidden)',
  'cattool.icon': '#toolCats .cat-tool:not(.is-hidden) .cat-tool__icon',
  'cattool.label': '#toolCats .cat-tool:not(.is-hidden) .cat-tool__label',
  'cattool.meta': '#toolCats .cat-tool:not(.is-hidden) .cat-tool__meta',
  'cattool.pin': '#toolCats .cat-tool__pin',
  'cattool.flag': '#toolCats .cat-tool__flag',
  'empty': '#toolEmpty',
  'empty.title': '#toolEmpty .empty__title',
  'empty.text': '#toolEmpty .empty__text',
  'shell.tabbar': '#tabbar',
};

/* Extra steps a state needs once the app is up. `chip(id)` selects a category;
   `search(q)` types into the hub's field. */
const AFTER = {
  tools_search: "search('petrol')",
  tools_noresults: "search('zzzzz')",
  tools_all: "chip('all')",
  tools_islamic: "chip('islamic')",
};

/* The instant everything is captured at: Monday 7 September 2026, 16:41:32
   local — `kFixtureInstant` on the Flutter side, so both render the same day,
   the same greeting and the same "what is open now".

   The prototype reads `new Date()` in a dozen places (the greeting, the live
   row, the outage, the market session), so the page's clock is replaced before
   any module evaluates. Without this, Home is a different screen at breakfast
   and at midnight and nothing can be compared. */
const FREEZE = `
(function () {
  var FIXED = new Date(2026, 8, 7, 16, 41, 32).getTime();
  var Real = Date;
  function Frozen(a, b, c, d, e, f, g) {
    if (!(this instanceof Frozen)) return new Real(FIXED).toString();
    switch (arguments.length) {
      case 0: return new Real(FIXED);
      case 1: return new Real(a);
      case 2: return new Real(a, b);
      case 3: return new Real(a, b, c);
      case 4: return new Real(a, b, c, d);
      case 5: return new Real(a, b, c, d, e);
      case 6: return new Real(a, b, c, d, e, f);
      default: return new Real(a, b, c, d, e, f, g);
    }
  }
  Frozen.prototype = Real.prototype;
  Frozen.now = function () { return FIXED; };
  Frozen.parse = Real.parse;
  Frozen.UTC = Real.UTC;
  window.Date = Frozen;
})();
`;

const DRIVER = (profile, screen, after) => FREEZE + `
(function () {
  try {
    localStorage.setItem('lume-onboarded', '1');
    localStorage.setItem('lume-profile', ${JSON.stringify(JSON.stringify(profile))});
  } catch (e) {}

  function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

  function act(a) {
    var b = document.createElement('button');
    b.setAttribute('data-act', a);
    b.style.cssText = 'position:fixed;opacity:0;pointer-events:none';
    document.body.appendChild(b);
    b.click();
    b.remove();
  }

  function tab(id) {
    var b = document.createElement('button');
    b.setAttribute('data-tab', id);
    b.style.cssText = 'position:fixed;opacity:0;pointer-events:none';
    document.body.appendChild(b);
    b.click();
    b.remove();
  }

  function chip(id) {
    var c = document.querySelector('#toolChips .chip[data-filter="' + id + '"]');
    if (c) c.click();
  }

  function search(q) {
    var el = document.getElementById('toolSearch');
    if (!el) return;
    el.value = q;
    el.dispatchEvent(new Event('input', { bubbles: true }));
  }

  async function run() {
    await wait(900);
    tab(${JSON.stringify(screen)});
    await wait(600);
    ${after || ''};
    await wait(400);
    var clock = document.getElementById('statusClock');
    if (clock) clock.textContent = '16:41';
    /* The notification engine fires a demo banner a second after boot and it
       covers the app bar. It is transient chrome, not part of the screen
       being measured, so it is taken out of the capture rather than waited
       out — waiting would make the capture depend on a timer. */
    var suppress = document.createElement('style');
    suppress.textContent =
      '.nbanner,.toast{display:none!important}';
    document.head.appendChild(suppress);
    document.documentElement.setAttribute('data-measure-ready', '1');
  }

  function start() {
    run().catch(function (e) {
      document.documentElement.setAttribute(
        'data-measure-error', String((e && e.message) || e));
    });
  }
  if (document.readyState === 'complete') start();
  else window.addEventListener('load', start);
})();
`;

function stage(driver) {
  const work = mkdtempSync(join(tmpdir(), 'lume-dest-'));
  cpSync(join(REF, 'index.html'), join(work, 'index.html'));
  cpSync(join(REF, 'assets'), join(work, 'assets'), { recursive: true });
  mkdirSync(join(work, 'scripts'), { recursive: true });
  cpSync(join(REF, 'scripts/serve.js'), join(work, 'scripts/serve.js'));
  writeFileSync(join(work, 'measure-driver.js'), driver);

  const html = readFileSync(join(work, 'index.html'), 'utf8');
  writeFileSync(
    join(work, 'index.html'),
    html.replace('</body>', '<script src="measure-driver.js"></script>\n</body>'),
  );
  return work;
}

class Cdp {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    ws.addEventListener('message', (e) => {
      const msg = JSON.parse(e.data);
      const p = this.pending.get(msg.id);
      if (!p) return;
      this.pending.delete(msg.id);
      if (msg.error) p.reject(new Error(JSON.stringify(msg.error)));
      else p.resolve(msg.result);
    });
  }

  send(method, params = {}) {
    const id = ++this.id;
    return new Promise((res, rej) => {
      this.pending.set(id, { resolve: res, reject: rej });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async evaluate(expression) {
    const r = await this.send('Runtime.evaluate', {
      expression,
      returnByValue: true,
      awaitPromise: true,
    });
    if (r.exceptionDetails) {
      throw new Error(
        r.exceptionDetails.text +
          ' — ' +
          (r.exceptionDetails.exception?.description || ''),
      );
    }
    return r.result.value;
  }
}

async function main() {
  const profile = STATES[STATE];
  if (!profile) throw new Error('no state named ' + STATE);
  const targets = SCREEN === 'tools' ? TOOLS_TARGETS : HOME_TARGETS;

  const work = stage(DRIVER(profile, SCREEN, AFTER[args.after] || ''));
  const server = spawn(process.execPath, ['scripts/serve.js'], {
    cwd: work,
    env: { ...process.env, PORT: String(PORT) },
    stdio: 'ignore',
  });
  const chrome = spawn(
    CHROME,
    [
      '--headless=new',
      `--remote-debugging-port=${CDP_PORT}`,
      '--disable-gpu',
      '--hide-scrollbars',
      '--force-prefers-reduced-motion',
      '--no-first-run',
      '--user-data-dir=' + join(work, 'chrome-profile'),
      'about:blank',
    ],
    { stdio: 'ignore' },
  );

  const cleanup = () => {
    try { chrome.kill(); } catch (e) { /* gone */ }
    try { server.kill(); } catch (e) { /* gone */ }
    try { rmSync(work, { recursive: true, force: true }); } catch (e) { /* ok */ }
  };

  try {
    let target = null;
    for (let i = 0; i < 100 && !target; i++) {
      await sleep(120);
      try {
        const list = await fetch(`http://127.0.0.1:${CDP_PORT}/json/list`).then(
          (r) => r.json(),
        );
        target = list.find((t) => t.type === 'page');
      } catch (e) { /* not up */ }
    }
    if (!target) throw new Error('Chrome never opened its debugging port');

    const ws = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((r) => ws.addEventListener('open', r, { once: true }));
    const cdp = new Cdp(ws);
    await cdp.send('Page.enable');
    await cdp.send('Runtime.enable');
    await cdp.send('Emulation.setDeviceMetricsOverride', {
      width: WIDTH,
      height: HEIGHT,
      deviceScaleFactor: 1,
      mobile: WIDTH < 600,
    });
    await cdp.send('Page.navigate', {
      url: `http://127.0.0.1:${PORT}/index.html?theme=${THEME}&lang=${LANG}`,
    });

    let ready = false;
    let failure = null;
    for (let i = 0; i < 300 && !ready && !failure; i++) {
      await sleep(100);
      try {
        ready = await cdp.evaluate(
          "document.documentElement.getAttribute('data-measure-ready') === '1'",
        );
        failure = await cdp.evaluate(
          "document.documentElement.getAttribute('data-measure-error')",
        );
      } catch (e) { /* navigating */ }
    }
    if (failure) throw new Error('driver failed: ' + failure);
    if (!ready) throw new Error('the shell never reached ' + SCREEN);

    await cdp.evaluate(`(function () {
      document.documentElement.dataset.theme = ${JSON.stringify(THEME)};
      document.documentElement.lang = ${JSON.stringify(LANG)};
      document.documentElement.dir = ${JSON.stringify(DIR)};
      document.body.classList.toggle('is-rtl', ${DIR === 'rtl'});
      return true;
    })()`);
    await sleep(400);

    if (SCROLL) {
      await cdp.evaluate(`(function () {
        var el = document.querySelector('.screen.is-active');
        if (el) el.scrollTop = ${SCROLL};
        return el ? el.scrollTop : null;
      })()`);
      await sleep(250);
    }

    const innerWidth = await cdp.evaluate('window.innerWidth');
    if (innerWidth !== WIDTH) {
      throw new Error(`viewport did not take: asked ${WIDTH}, got ${innerWidth}`);
    }

    const result = await cdp.evaluate(`(function () {
      var targets = ${JSON.stringify(targets)};
      var out = {};
      var missing = [];
      Object.keys(targets).forEach(function (name) {
        var el = document.querySelector(targets[name]);
        if (!el) { missing.push(name); return; }
        var r = el.getBoundingClientRect();
        var cs = getComputedStyle(el);
        var lh = parseFloat(cs.lineHeight);
        out[name] = {
          x: Math.round(r.x * 100) / 100,
          y: Math.round(r.y * 100) / 100,
          width: Math.round(r.width * 100) / 100,
          height: Math.round(r.height * 100) / 100,
          lines: Number.isFinite(lh) && lh > 0 ? Math.round(r.height / lh) : null,
          font: cs.fontWeight + ' ' + cs.fontSize + '/' + cs.lineHeight +
                ' ' + cs.letterSpacing,
          color: cs.color,
          background: cs.backgroundColor,
          radius: cs.borderRadius,
          pad: cs.padding,
          gap: cs.gap,
          text: (el.textContent || '').trim().slice(0, 160) || null
        };
      });

      function ids(sel, attr) {
        return Array.prototype.map.call(
          document.querySelectorAll(sel),
          function (el) { return el.dataset[attr]; });
      }
      function texts(sel) {
        return Array.prototype.map.call(
          document.querySelectorAll(sel),
          function (el) { return (el.textContent || '').trim(); });
      }

      /* The composition — the part a screenshot cannot show.
         Every screen stays mounted, so this asks which one is *active*
         rather than which one exists. */
      var active = document.querySelector('.screen.is-active');
      var activeId = active ? active.id : null;
      var composition = {};
      if (activeId === 'screen-home') {
        var shown = Array.prototype.filter.call(
          document.querySelectorAll('#heroTrack .slide'),
          function (el) { return !el.classList.contains('is-off'); });
        shown.sort(function (a, b) { return a.offsetLeft - b.offsetLeft; });
        composition.hero = shown.map(function (el) { return el.dataset.slide; });
        composition.quickTools = ids('#quickTools .tool', 'fid');
        composition.quickToolLabels = texts('#quickTools .tool__label');
        composition.quickToolValues = texts('#quickTools .tool__value');
        composition.quickActions = ids('#quickActions .qaction', 'fid');
        composition.quickActionLabels = texts('#quickActions .qaction__label');
        composition.live = ids('#liveNow .livecard', 'fid');
        composition.liveTitles = texts('#liveNow .livecard__title');
        composition.liveMetas = texts('#liveNow .livecard__meta');
        composition.liveValues = texts('#liveNow .livecard__value');
        composition.upcoming = texts('#upcomingList .crow__label');
        composition.upcomingValues = texts('#upcomingList .crow__value');
        composition.discover = Array.prototype.filter.call(
          document.querySelectorAll('#homeDiscover .minicard'),
          function (el) { return !el.hidden; })
          .map(function (el) {
            return {
              title: (el.querySelector('.minicard__title') || {}).textContent,
              meta: (el.querySelector('.minicard__meta') || {}).textContent
            };
          });
        composition.glance = Array.prototype.filter.call(
          document.querySelectorAll('#screen-home .row-gap > .card'),
          function (el) { return !el.hidden; })
          .map(function (el) {
            return {
              cls: el.className,
              faith: el.dataset.faith || null,
              loc: el.dataset.loc || null,
              text: (el.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 120)
            };
          });
        composition.sections = Array.prototype.map.call(
          document.querySelectorAll('#screen-home > *'),
          function (el) {
            return {
              tag: el.tagName.toLowerCase(),
              cls: el.className,
              id: el.id || null,
              hidden: el.hidden || el.classList.contains('is-hidden'),
              y: Math.round(el.getBoundingClientRect().y * 100) / 100,
              height: Math.round(el.getBoundingClientRect().height * 100) / 100
            };
          });
      }
      if (activeId === 'screen-tools') {
        composition.chips = ids('#toolChips .chip', 'filter');
        composition.chipLabels = texts('#toolChips .chip');
        composition.activeChip =
          (document.querySelector('#toolChips .chip.is-active') || {}).dataset;
        composition.activeChip = composition.activeChip
          ? composition.activeChip.filter : null;
        composition.categories = Array.prototype.filter.call(
          document.querySelectorAll('#toolCats .cat'),
          function (el) { return el.style.display !== 'none'; })
          .map(function (el) {
            return {
              id: el.dataset.cat,
              title: (el.querySelector('.cat__title') || {}).textContent,
              sub: (el.querySelector('.cat__sub') || {}).textContent,
              count: (el.querySelector('.cat__count') || {}).textContent,
              tools: Array.prototype.filter.call(
                el.querySelectorAll('.cat-tool'),
                function (t) { return !t.classList.contains('is-hidden'); })
                .map(function (t) {
                  return {
                    id: t.dataset.fid,
                    label: (t.querySelector('.cat-tool__label') || {}).textContent,
                    meta: (t.querySelector('.cat-tool__meta') || {}).textContent,
                    pin: !!t.querySelector('.cat-tool__pin'),
                    flag: !!t.querySelector('.cat-tool__flag'),
                    count: (t.querySelector('.cat-tool__count') || {}).textContent || null
                  };
                })
            };
          });
        composition.recents = ids('#toolRecentList .recent', 'fid');
        composition.emptyShown =
          document.getElementById('toolEmpty').classList.contains('is-shown');
        composition.sections = Array.prototype.map.call(
          document.querySelectorAll('#screen-tools > *'),
          function (el) {
            return {
              tag: el.tagName.toLowerCase(),
              cls: el.className,
              id: el.id || null,
              hidden: el.hidden,
              y: Math.round(el.getBoundingClientRect().y * 100) / 100,
              height: Math.round(el.getBoundingClientRect().height * 100) / 100
            };
          });
      }

      var screenEl = active;
      return {
        bounds: out,
        activeScreen: activeId,
        missing: missing,
        composition: composition,
        tabs: Array.prototype.map.call(
          document.querySelectorAll('#tabbar .tab'),
          function (el) { return el.dataset.tab; }),
        activeTab: (document.querySelector('#tabbar .tab.is-active') || {}).dataset
          ? document.querySelector('#tabbar .tab.is-active').dataset.tab : null,
        scroll: screenEl ? {
          clientHeight: screenEl.clientHeight,
          scrollHeight: screenEl.scrollHeight,
          paddingBottom: getComputedStyle(screenEl).paddingBottom
        } : null
      };
    })()`);

    mkdirSync(OUT, { recursive: true });
    const cell =
      `${SCREEN}_${STATE}${args.after ? '_' + args.after : ''}` +
      `${SCROLL ? '_s' + SCROLL : ''}` +
      `_${WIDTH}x${HEIGHT}_${THEME}_${LANG}`;

    if (SHOT) {
      const shot = await cdp.send('Page.captureScreenshot', {
        format: 'png',
        captureBeyondViewport: false,
      });
      const dir = join(
        SHOTS,
        `${SCREEN}_${STATE}${args.after ? '_' + args.after : ''}`,
      );
      mkdirSync(dir, { recursive: true });
      writeFileSync(join(dir, `${cell}.web.png`), Buffer.from(shot.data, 'base64'));
    }

    writeFileSync(
      join(OUT, `${cell}.json`),
      JSON.stringify(
        {
          cell,
          screen: SCREEN,
          state: STATE,
          after: args.after || null,
          profile: { country: profile.country, city: profile.city,
                     islamic: profile.islamic, interests: profile.interests,
                     favourites: profile.favourites, recents: profile.recents,
                     prefs: profile.prefs, displayName: profile.displayName },
          viewport: { width: WIDTH, height: HEIGHT, innerWidth },
          scrollTop: SCROLL,
          theme: THEME, lang: LANG, dir: DIR,
          tabs: result.tabs,
          activeTab: result.activeTab,
          scroll: result.scroll,
          missing: result.missing,
          composition: result.composition,
          bounds: result.bounds,
        },
        null,
        2,
      ) + '\n',
    );

    process.stdout.write(
      `measured ${SCREEN}/${STATE} at ${WIDTH}x${HEIGHT} ${THEME}/${LANG} · ` +
        `${Object.keys(result.bounds).length} elements` +
        (result.missing.length ? ` · absent ${result.missing.length}` : '') +
        '\n',
    );
  } finally {
    cleanup();
  }
}

main().catch((e) => {
  process.stderr.write(`destination measurement failed: ${e.message}\n`);
  process.exit(1);
});
