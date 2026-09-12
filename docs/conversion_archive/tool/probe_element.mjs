/* Ask the running prototype everything about one element.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/probe_element.mjs \
 *     --screen home --state muslim_pk --selector "#screen-home .bar"
 *
 * `measure_destinations.mjs` reports a fixed set of properties for a fixed set
 * of elements. This reports *everything* about one selector — the whole
 * computed style, the box, the ancestors and their display modes — which is
 * what settling "is this element absent, hidden, or broken" actually takes.
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
const SCREEN = args.screen || 'home';
const SELECTOR = args.selector;
const PORT = Number(args.port || 8183);
const CDP_PORT = Number(args.cdpPort || 9361);
if (!SELECTOR) {
  process.stderr.write('usage: probe_element.mjs --selector "<css>"\n');
  process.exit(2);
}

const DEFAULTS = ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news'];
const PROFILE = {
  displayName: '', photo: '',
  country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad',
  islamic: args.state === 'muslim_pk', lang: 'en', units: 'auto',
  currency: 'auto', clock: 'auto', method: 'MWL',
  interests: args.state === 'muslim_pk'
    ? [...DEFAULTS, 'prayer', 'quran', 'duas']
    : DEFAULTS,
  prefs: { news: true, cricket: true, finance: true, recos: true },
  recents: [], favourites: [], market: null, recentCountries: [],
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
    tab(${JSON.stringify(SCREEN)});
    /* Long enough for the entry animation and the 1.1 s bar transition to
       finish, so a zero width cannot be "it had not started yet". */
    await wait(2500);
    document.documentElement.setAttribute('data-measure-ready', '1');
  }
  if (document.readyState === 'complete') run();
  else window.addEventListener('load', run);
})();
`;

function stage() {
  const work = mkdtempSync(join(tmpdir(), 'lume-probe-'));
  cpSync(join(REF, 'index.html'), join(work, 'index.html'));
  cpSync(join(REF, 'assets'), join(work, 'assets'), { recursive: true });
  mkdirSync(join(work, 'scripts'), { recursive: true });
  cpSync(join(REF, 'scripts/serve.js'), join(work, 'scripts/serve.js'));
  writeFileSync(join(work, 'probe-driver.js'), DRIVER);
  const html = readFileSync(join(work, 'index.html'), 'utf8');
  writeFileSync(
    join(work, 'index.html'),
    html.replace('</body>', '<script src="probe-driver.js"></script>\n</body>'),
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
      var els = Array.prototype.slice.call(
        document.querySelectorAll(${JSON.stringify(SELECTOR)}));
      if (!els.length) return { found: 0 };
      function describe(el) {
        var cs = getComputedStyle(el);
        var r = el.getBoundingClientRect();
        var keep = ['display','position','width','height','minHeight','maxHeight',
          'marginTop','marginBottom','paddingTop','paddingBottom','overflow',
          'overflowX','overflowY','opacity','visibility','backgroundColor',
          'backgroundImage','borderRadius','transition','clipPath','transform',
          'flexGrow','flexShrink','flexBasis','alignSelf'];
        var style = {};
        keep.forEach(function (k) { style[k] = cs[k]; });
        return {
          tag: el.tagName.toLowerCase(),
          cls: el.className,
          inlineStyle: el.getAttribute('style'),
          dataset: Object.assign({}, el.dataset),
          rect: { x: r.x, y: r.y, w: r.width, h: r.height },
          offset: { w: el.offsetWidth, h: el.offsetHeight },
          client: { w: el.clientWidth, h: el.clientHeight },
          style: style,
          hidden: el.hidden,
          ancestors: (function () {
            var out = [], p = el.parentElement, n = 0;
            while (p && n < 4) {
              var pcs = getComputedStyle(p);
              out.push({
                tag: p.tagName.toLowerCase(), cls: p.className,
                display: pcs.display, hidden: p.hidden,
                w: p.getBoundingClientRect().width,
                h: p.getBoundingClientRect().height,
              });
              p = p.parentElement; n++;
            }
            return out;
          })(),
        };
      }
      return { found: els.length, elements: els.map(describe) };
    })()`);

    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
  } finally {
    cleanup();
  }
}

main().catch((e) => {
  process.stderr.write(`probe failed: ${e.message}\n`);
  process.exit(1);
});
