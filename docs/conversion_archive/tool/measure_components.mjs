/* Measure every shared Lume component from the rendered page.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/measure_components.mjs \
 *     --theme light --width 390 --out docs/conversion_archive/measurements
 *
 * Reads `getComputedStyle` rather than the stylesheets. That is the whole
 * point: a declaration in a file is a claim, and the cascade, specificity,
 * inheritance, `color-mix`, custom properties and state classes all get a vote
 * before it becomes a pixel. The only honest source for "what does this
 * component actually look like" is the browser that just laid it out.
 *
 * Writes one JSON per (theme, width, direction) cell. The Flutter tests read
 * these and assert the widget against them, so a Flutter constant that drifts
 * from the design fails a test rather than a review.
 */
import { spawn } from 'node:child_process';
import {
  mkdtempSync, cpSync, writeFileSync, mkdirSync, rmSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const argv = process.argv.slice(2);
const args = {};
for (let i = 0; i < argv.length; i++) {
  if (argv[i].startsWith('--')) args[argv[i].slice(2)] = argv[i + 1];
}

const REF = resolve(args.ref || process.cwd());
const CHROME = args.chrome
  || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = resolve(args.out || 'docs/conversion_archive/measurements');
const WIDTH = Number(args.width || 390);
const HEIGHT = Number(args.height || 900);
const THEME = args.theme || 'light';
const DIR = args.dir || 'ltr';
const LANG = args.lang || 'en';
const PORT = Number(args.port || 8166);
const CDP_PORT = Number(args.cdpPort || 9344);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/* The properties worth recording. Everything a Flutter widget has to decide,
   and nothing that is only an artifact of the box model. */
const PROPS = [
  'display', 'position', 'boxSizing',
  'width', 'height', 'minHeight', 'minWidth', 'maxWidth',
  'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft',
  'marginTop', 'marginRight', 'marginBottom', 'marginLeft',
  'gap', 'rowGap', 'columnGap',
  'flexDirection', 'alignItems', 'justifyContent', 'flexWrap', 'flex',
  'gridTemplateColumns',
  'fontFamily', 'fontSize', 'fontWeight', 'lineHeight', 'letterSpacing',
  'textAlign', 'textTransform', 'textDecorationLine', 'whiteSpace',
  'fontVariantNumeric',
  'color', 'backgroundColor', 'backgroundImage', 'opacity',
  'borderTopWidth', 'borderRightWidth', 'borderBottomWidth', 'borderLeftWidth',
  'borderTopColor', 'borderBottomColor',
  'borderTopLeftRadius', 'borderTopRightRadius',
  'borderBottomLeftRadius', 'borderBottomRightRadius',
  'boxShadow', 'overflow', 'overflowX', 'overflowY',
  'direction', 'transform',
];

function stage() {
  const work = mkdtempSync(join(tmpdir(), 'lume-measure-'));
  cpSync(join(REF, 'index.html'), join(work, 'index.html'));
  cpSync(join(REF, 'assets'), join(work, 'assets'), { recursive: true });
  mkdirSync(join(work, 'scripts'), { recursive: true });
  cpSync(join(REF, 'scripts/serve.js'), join(work, 'scripts/serve.js'));
  mkdirSync(join(work, 'docs/conversion_archive/tool'), { recursive: true });
  cpSync(
    join(REF, 'docs/conversion_archive/tool/fixture'),
    join(work, 'docs/conversion_archive/tool/fixture'),
    { recursive: true },
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
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async evaluate(expression) {
    const r = await this.send('Runtime.evaluate', {
      expression, returnByValue: true, awaitPromise: true,
    });
    if (r.exceptionDetails) {
      throw new Error(r.exceptionDetails.text + ' — '
        + (r.exceptionDetails.exception?.description || ''));
    }
    return r.result.value;
  }
}

async function main() {
  const work = stage();
  const server = spawn(process.execPath, ['scripts/serve.js'], {
    cwd: work, env: { ...process.env, PORT: String(PORT) }, stdio: 'ignore',
  });
  const chrome = spawn(CHROME, [
    '--headless=new',
    `--remote-debugging-port=${CDP_PORT}`,
    '--disable-gpu',
    '--hide-scrollbars',
    '--force-prefers-reduced-motion',
    '--no-first-run',
    '--user-data-dir=' + join(work, 'chrome-profile'),
    'about:blank',
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
        const list = await fetch(`http://127.0.0.1:${CDP_PORT}/json/list`)
          .then((r) => r.json());
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
      width: WIDTH, height: HEIGHT, deviceScaleFactor: 1, mobile: WIDTH < 600,
    });

    await cdp.send('Page.navigate', {
      url: `http://127.0.0.1:${PORT}/docs/conversion_archive/tool/fixture/index.html`,
    });

    let ready = false;
    for (let i = 0; i < 200 && !ready; i++) {
      await sleep(100);
      try {
        ready = await cdp.evaluate(
          "document.documentElement.getAttribute('data-fixture-ready') === '1'",
        );
      } catch (e) { /* navigating */ }
    }
    if (!ready) throw new Error('the fixture never reported ready');

    // Theme, direction and width class are attributes on the root, exactly as
    // the shell sets them — not a separate stylesheet, so the cascade is
    // unchanged.
    //
    // `data-bp` matters more than it looks: the rail and the sidebar are
    // `display: none` until it says medium or expanded, and a measurement
    // taken without it reports a zero-height element with the *compact*
    // styles. `breakpoint.js` is not running in the fixture, so the measurer
    // stamps what breakpoint.js would have — from the shell width, which is
    // the viewport here because the fixture has no stage padding of its own.
    await cdp.evaluate(`(function () {
      var w = ${WIDTH};
      document.documentElement.dataset.bp =
        w >= 840 ? 'expanded' : w >= 600 ? 'medium' : 'compact';
      document.documentElement.dataset.theme = ${JSON.stringify(THEME)};
      document.documentElement.lang = ${JSON.stringify(LANG)};
      document.documentElement.dir = ${JSON.stringify(DIR)};
      document.getElementById('app').classList.toggle('is-rtl', ${DIR === 'rtl'});
      document.body.classList.toggle('is-rtl', ${DIR === 'rtl'});
      return true;
    })()`);
    // Let the change settle before reading anything back.
    await sleep(300);

    const innerWidth = await cdp.evaluate('window.innerWidth');
    if (innerWidth !== WIDTH) {
      throw new Error(`viewport did not take: asked ${WIDTH}, got ${innerWidth}`);
    }

    const measured = await cdp.evaluate(`(function () {
      var props = ${JSON.stringify(PROPS)};
      var fx = window.__LUME_FIXTURE__;
      var out = {};
      var missing = [];

      fx.names.forEach(function (name) {
        var host = document.querySelector('[data-fx="' + CSS.escape(name) + '"]');
        var el = host && host.querySelector(fx.selectors[name]);
        if (!el) { missing.push(name); return; }

        var cs = getComputedStyle(el);
        var style = {};
        props.forEach(function (p) { style[p] = cs[p]; });

        var r = el.getBoundingClientRect();
        var text = el.querySelector('*') ? null : el.textContent.trim();

        out[name] = {
          selector: fx.selectors[name],
          tag: el.tagName.toLowerCase(),
          rect: {
            width: Math.round(r.width * 100) / 100,
            height: Math.round(r.height * 100) / 100,
          },
          style: style,
          text: text,
          role: el.getAttribute('role'),
          ariaPressed: el.getAttribute('aria-pressed'),
          ariaCurrent: el.getAttribute('aria-current'),
          ariaLabel: el.getAttribute('aria-label'),
          ariaChecked: el.getAttribute('aria-checked')
        };
      });

      return { measured: out, missing: missing };
    })()`);

    if (measured.missing.length) {
      process.stderr.write(
        'specimens whose selector matched nothing: '
        + measured.missing.join(', ') + '\n',
      );
    }

    mkdirSync(OUT, { recursive: true });
    const cell = `components_${WIDTH}_${THEME}_${DIR}`;
    writeFileSync(
      join(OUT, `${cell}.json`),
      JSON.stringify({
        cell,
        viewport: { width: WIDTH, height: HEIGHT, innerWidth },
        theme: THEME,
        dir: DIR,
        lang: LANG,
        count: Object.keys(measured.measured).length,
        missing: measured.missing,
        components: measured.measured,
      }, null, 2) + '\n',
    );

    process.stdout.write(
      `measured ${Object.keys(measured.measured).length} specimens `
      + `at ${WIDTH}px ${THEME}/${DIR}`
      + (measured.missing.length ? `, ${measured.missing.length} missing` : '')
      + `\n`,
    );
    if (measured.missing.length) process.exitCode = 1;
  } finally {
    cleanup();
  }
}

main().catch((e) => {
  process.stderr.write(`measurement failed: ${e.message}\n`);
  process.exit(1);
});
