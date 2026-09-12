/* What the prototype's notification engine puts in the header badge, and why.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/probe_notifications.mjs --state muslim_pk
 *
 * The badge is `NOTIFY.unreadCount()`, which is `build()` filtered by
 * `!read && !expired`. `build()` walks sixteen declared sources and drops each
 * one whose *tool* the user cannot see — `allowed(src)` asks the same
 * eligibility gate the catalogue asks — and then whichever the user's category
 * and type preferences switch off.
 *
 * So the count is not a number the engine invents; it is a count of the
 * sources that survive a given profile. This drives the shell to the
 * notification centre and reports which ones did, so a Flutter fixture can
 * carry the right value for each captured state rather than a flat guess.
 */
import { spawn } from 'node:child_process';
import { mkdtempSync, cpSync, writeFileSync, readFileSync, rmSync, mkdirSync } from 'node:fs';
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
const STATE = args.state || 'muslim_pk';
const PORT = Number(args.port || 8185);
const CDP_PORT = Number(args.cdpPort || 9363);

const DEFAULTS = ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news'];
const ISLAMIC = ['prayer', 'quran', 'duas'];

/* The same seven profiles `measure_destinations.mjs` captures. */
const STATES = {
  default_pk: { country: 'PK', city: 'Islamabad', islamic: false },
  muslim_pk: { country: 'PK', city: 'Islamabad', islamic: true },
  named_pk: { country: 'PK', city: 'Islamabad', islamic: false, displayName: 'Ayesha' },
  no_interests_pk: { country: 'PK', city: 'Islamabad', islamic: false, interests: [] },
  prefs_off_pk: {
    country: 'PK', city: 'Islamabad', islamic: false,
    prefs: { news: false, cricket: false, finance: false, recos: false },
  },
  muslim_gb: { country: 'GB', region: 'England', city: 'London', islamic: true },
  default_us: { country: 'US', region: 'New York', city: 'New York', islamic: false },
};

const chosen = STATES[STATE];
if (!chosen) {
  process.stderr.write(`unknown state: ${STATE}\n`);
  process.exit(2);
}

const PROFILE = {
  displayName: '', photo: '',
  region: 'Islamabad Capital Territory',
  lang: 'en', units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
  interests: chosen.islamic ? [...DEFAULTS, ...ISLAMIC] : DEFAULTS,
  prefs: { news: true, cricket: true, finance: true, recos: true },
  recents: [], favourites: [], market: null, recentCountries: [],
  ...chosen,
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const DRIVER = `
(function () {
  var FIXED = new Date(2026, 8, 7, 16, 41, 32).getTime();
  var Real = Date;
  function Frozen(a, b, c, d, e, f, g) {
    if (!(this instanceof Frozen)) return new Real(FIXED).toString();
    switch (arguments.length) {
      case 0: return new Real(FIXED);
      case 1: return new Real(a);
      default: return new Real(a, b, c, d, e, f, g);
    }
  }
  Frozen.prototype = Real.prototype;
  Frozen.now = function () { return FIXED; };
  Frozen.parse = Real.parse; Frozen.UTC = Real.UTC;
  window.Date = Frozen;
})();
(function () {
  try {
    localStorage.setItem('lume-onboarded', '1');
    localStorage.setItem('lume-profile', ${JSON.stringify(JSON.stringify(PROFILE))});
  } catch (e) {}
  function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }
  function tab(id) {
    var b = document.createElement('button');
    b.setAttribute('data-tab', id);
    b.style.cssText = 'position:fixed;opacity:0;pointer-events:none';
    document.body.appendChild(b); b.click(); b.remove();
  }
  async function run() {
    await wait(900);
    tab('home');
    await wait(700);
    /* The badge is read off Home, the rows off the centre, so both are
       measured from the same profile in the same run. */
    var bell = document.querySelector('#screen-home .iconbtn__badge');
    window.__badge = bell && !bell.hidden ? bell.textContent : null;
    tab('notifications');
    await wait(1200);
    document.documentElement.setAttribute('data-measure-ready', '1');
  }
  if (document.readyState === 'complete') run();
  else window.addEventListener('load', run);
})();
`;

function stage() {
  const work = mkdtempSync(join(tmpdir(), 'lume-notif-'));
  cpSync(join(REF, 'index.html'), join(work, 'index.html'));
  cpSync(join(REF, 'assets'), join(work, 'assets'), { recursive: true });
  mkdirSync(join(work, 'scripts'), { recursive: true });
  cpSync(join(REF, 'scripts/serve.js'), join(work, 'scripts/serve.js'));
  writeFileSync(join(work, 'notif-driver.js'), DRIVER);
  const html = readFileSync(join(work, 'index.html'), 'utf8');
  writeFileSync(
    join(work, 'index.html'),
    html.replace('</body>', '<script src="notif-driver.js"></script>\n</body>'),
  );
  return work;
}

class Cdp {
  constructor(ws) {
    this.ws = ws; this.id = 0; this.pending = new Map();
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
      expression, returnByValue: true, awaitPromise: true,
    });
    if (r.exceptionDetails) throw new Error(r.exceptionDetails.text);
    return r.result.value;
  }
}

async function main() {
  const work = stage();
  const server = spawn(process.execPath, ['scripts/serve.js'], {
    cwd: work, env: { ...process.env, PORT: String(PORT) }, stdio: 'ignore',
  });
  const chrome = spawn(CHROME, [
    '--headless=new', `--remote-debugging-port=${CDP_PORT}`, '--disable-gpu',
    '--hide-scrollbars', '--force-prefers-reduced-motion', '--no-first-run',
    '--user-data-dir=' + join(work, 'chrome-profile'), 'about:blank',
  ], { stdio: 'ignore' });

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
        const list = await fetch(`http://127.0.0.1:${CDP_PORT}/json/list`).then((r) => r.json());
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
      width: 390, height: 844, deviceScaleFactor: 1, mobile: true,
    });
    await cdp.send('Page.navigate', { url: `http://127.0.0.1:${PORT}/index.html` });

    for (let i = 0; i < 300; i++) {
      await sleep(100);
      try {
        if (await cdp.evaluate("document.documentElement.getAttribute('data-measure-ready') === '1'")) break;
      } catch (e) { /* navigating */ }
    }

    const out = await cdp.evaluate(`(function () {
      var rows = Array.prototype.slice.call(
        document.querySelectorAll('#screen-notifications .nrow'));
      function title(r) {
        var t = r.querySelector('.nrow__title');
        return t ? t.textContent.trim() : null;
      }
      function category(r) {
        var i = r.querySelector('.nrow__icon');
        if (!i) return null;
        var m = /nrow__icon--([a-z]+)/.exec(i.className);
        return m ? m[1] : null;
      }
      var unread = rows.filter(function (r) {
        return r.className.indexOf('is-unread') !== -1;
      });
      return {
        badge: window.__badge,
        rows: rows.length,
        unread: unread.length,
        entries: unread.map(function (r) {
          return { title: title(r), category: category(r) };
        }),
      };
    })()`);

    process.stdout.write(JSON.stringify({ state: STATE, ...out }, null, 2) + '\n');
  } finally {
    cleanup();
  }
}

main().catch((e) => {
  process.stderr.write(`probe failed: ${e.message}\n`);
  process.exit(1);
});
