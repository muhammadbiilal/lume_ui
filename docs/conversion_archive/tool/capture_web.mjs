/* Capture a screen from the Lume web prototype at an exact CSS viewport.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/capture_web.mjs \
 *     --name home --width 390 --height 844 --theme dark --lang ur \
 *     --out docs/conversion_archive/shots
 *
 * Two things this does that a naive screenshot does not.
 *
 * The viewport is set through the DevTools Protocol. `--window-size` does not
 * reach the CSS viewport in headless Chrome here: the page reports
 * innerWidth 500 whatever is asked for, and the resulting images are 500px
 * layouts cropped to the requested width. Emulation.setDeviceMetricsOverride
 * is the only thing that moves it, and the capture asserts window.innerWidth
 * afterwards rather than trusting a flag.
 *
 * The prototype is copied to a scratch directory and driven there, so a
 * capture run can never write to the comparison source.
 *
 * Node 22+ has a global WebSocket, so this needs no dependencies.
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
const CHROME = args.chrome
  || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = resolve(args.out || 'docs/conversion_archive/shots');
const NAME = args.name || 'lume';
const WIDTH = Number(args.width || 390);
const HEIGHT = Number(args.height || 844);
const DPR = Number(args.dpr || 1);
const THEME = args.theme || 'light';
const LANG = args.lang || 'en';
const STEP = args.step === undefined ? null : Number(args.step);
/* Turn the Islamic experience on at the interests step. The steps after it
   are a different composition when it is on, and both need capturing. */
const FAITH = args.faith === '1' || args.faith === 'true';
const PORT = Number(args.port || 8155);
const CDP_PORT = Number(args.cdpPort || 9333);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/* Injected into the scratch copy. Pins the profile and the clock so a capture
 * is a function of its arguments and nothing else, and removes the transient
 * banner that would otherwise land in one capture and not the next. */
const DRIVER = `
(function () {
  var wantTheme = ${JSON.stringify(THEME)};
  var wantLang = ${JSON.stringify(LANG)};

  /* The page applies its theme in an inline <head> script and reads the
     profile as it boots, both of which happen before this file runs. Writing
     the values here is therefore not enough — the first load has already been
     laid out with the previous ones. So write, then reload exactly once, and
     capture the second pass. The guard is what keeps that from being a loop. */
  try {
    localStorage.setItem('lume-theme', wantTheme);
    var p = JSON.parse(localStorage.getItem('lume-profile') || '{}');
    p.lang = wantLang;
    localStorage.setItem('lume-profile', JSON.stringify(p));
  } catch (e) {}

  var applied =
    document.documentElement.dataset.theme === wantTheme &&
    document.documentElement.lang === wantLang;

  if (!applied && !sessionStorage.getItem('lume-capture-reloaded')) {
    try { sessionStorage.setItem('lume-capture-reloaded', '1'); } catch (e) {}
    location.reload();
    return;
  }

  var wantStep = ${STEP === null ? 'null' : STEP};

  function settle() {
    var b = document.querySelector('.nbanner');
    if (b) b.remove();
    var clock = document.getElementById('statusClock');
    if (clock) clock.textContent = '16:41';
    document.documentElement.setAttribute('data-capture-ready', '1');
  }

  /* Advance the first-run flow to a given step by pressing its own Continue,
     rather than by setting classes: driving the real control means the capture
     is of the state a user would actually reach. */
  function advance(done) {
    if (wantStep === null) { done(); return; }
    var tries = 0;
    var timer = setInterval(function () {
      if (++tries > 300) { clearInterval(timer); done(); return; }
      var active = document.querySelector('.onb-step.is-active');
      if (!active) return;
      if (Number(active.dataset.step) >= wantStep) {
        clearInterval(timer);
        setTimeout(done, 400);
        return;
      }
      /* The interests step will not advance until five are chosen, it
         re-disables its button on every render, and neither it nor the name
         step carries the shared hook — so choose first, then press the
         button each step actually has. */
      var picks = active.querySelectorAll('.pick');
      if (picks.length) {
        if (${FAITH ? 'true' : 'false'}) {
          var ft = active.querySelector('[data-faithtoggle]');
          if (ft && ft.getAttribute('aria-pressed') !== 'true') ft.click();
        }
        var on = active.querySelectorAll('.pick.is-on').length;
        for (var i = 0; i < picks.length && on < 5; i++) {
          if (!picks[i].classList.contains('is-on')) { picks[i].click(); on++; }
        }
      }
      var next = active.querySelector('[data-onb-next], #onbPickNext, #onbNameNext');
      if (next) { next.removeAttribute('disabled'); next.click(); }
    }, 50);
  }

  function start() { setTimeout(function () { advance(settle); }, 900); }
  if (document.readyState === 'complete') start();
  else window.addEventListener('load', start);
})();
`;

function stage() {
  const work = mkdtempSync(join(tmpdir(), 'lume-cap-'));
  cpSync(join(REF, 'index.html'), join(work, 'index.html'));
  cpSync(join(REF, 'assets'), join(work, 'assets'), { recursive: true });
  mkdirSync(join(work, 'scripts'), { recursive: true });
  cpSync(join(REF, 'scripts/serve.js'), join(work, 'scripts/serve.js'));
  writeFileSync(join(work, 'capture-driver.js'), DRIVER);
  const html = readFileSync(join(work, 'index.html'), 'utf8');
  writeFileSync(
    join(work, 'index.html'),
    html.replace('</body>', '<script src="capture-driver.js"></script>\n</body>'),
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
      expression,
      returnByValue: true,
      awaitPromise: true,
    });
    if (r.exceptionDetails) {
      throw new Error(r.exceptionDetails.text || 'evaluate threw');
    }
    return r.result.value;
  }
}

async function main() {
  const work = stage();
  const server = spawn(process.execPath, ['scripts/serve.js'], {
    cwd: work,
    env: { ...process.env, PORT: String(PORT) },
    stdio: 'ignore',
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
    try { chrome.kill(); } catch (e) { /* already gone */ }
    try { server.kill(); } catch (e) { /* already gone */ }
    try { rmSync(work, { recursive: true, force: true }); } catch (e) { /* ok */ }
  };

  try {
    // Wait for the debugging endpoint.
    let target = null;
    for (let i = 0; i < 100 && !target; i++) {
      await sleep(120);
      try {
        const list = await fetch(`http://127.0.0.1:${CDP_PORT}/json/list`)
          .then((r) => r.json());
        target = list.find((t) => t.type === 'page');
      } catch (e) { /* not up yet */ }
    }
    if (!target) throw new Error('Chrome never opened its debugging port');

    const ws = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((r) => ws.addEventListener('open', r, { once: true }));
    const cdp = new Cdp(ws);

    await cdp.send('Page.enable');
    await cdp.send('Runtime.enable');

    // The only thing that actually moves the CSS viewport.
    await cdp.send('Emulation.setDeviceMetricsOverride', {
      width: WIDTH,
      height: HEIGHT,
      deviceScaleFactor: DPR,
      mobile: WIDTH < 600,
    });

    await cdp.send('Page.navigate', {
      url: `http://127.0.0.1:${PORT}/index.html`,
    });

    // Wait for the driver to say the page has settled.
    let ready = false;
    for (let i = 0; i < 120 && !ready; i++) {
      await sleep(150);
      try {
        ready = await cdp.evaluate(
          "document.documentElement.getAttribute('data-capture-ready') === '1'",
        );
      } catch (e) { /* still navigating */ }
    }
    if (!ready) throw new Error('the page never reported ready');

    const facts = await cdp.evaluate(`(function () {
      var app = document.querySelector('.app');
      var r = app ? app.getBoundingClientRect() : null;
      return {
        innerWidth: window.innerWidth,
        innerHeight: window.innerHeight,
        dataBp: document.documentElement.dataset.bp || null,
        theme: document.documentElement.dataset.theme || null,
        lang: document.documentElement.lang || null,
        dir: getComputedStyle(document.body).direction,
        scrollWidth: document.documentElement.scrollWidth,
        clientWidth: document.documentElement.clientWidth,
        shell: r ? { x: r.x, y: r.y, width: r.width, height: r.height } : null
      };
    })()`);

    // Assert rather than trust. A capture at the wrong viewport is worse than
    // no capture: it looks like evidence.
    if (facts.innerWidth !== WIDTH) {
      throw new Error(
        `viewport did not take: asked for ${WIDTH}, page reports ` +
        `${facts.innerWidth}. The image would be a ${facts.innerWidth}px ` +
        'layout cropped to the requested width.',
      );
    }
    if (facts.scrollWidth > facts.clientWidth) {
      throw new Error(
        `the page scrolls horizontally at ${WIDTH}px ` +
        `(scrollWidth ${facts.scrollWidth} > clientWidth ${facts.clientWidth})`,
      );
    }

    // Crop to the shell. Above 600px the prototype draws a device frame with
    // air around it, and that frame is browser presentation rather than
    // application layout.
    const clip = facts.shell
      ? {
          x: Math.round(facts.shell.x),
          y: Math.round(facts.shell.y),
          width: Math.round(facts.shell.width),
          height: Math.round(facts.shell.height),
          scale: 1,
        }
      : undefined;

    const shot = await cdp.send('Page.captureScreenshot', {
      format: 'png',
      captureBeyondViewport: false,
      ...(clip ? { clip } : {}),
    });

    const suffix = STEP === null ? '' : `_step${STEP}`;
    const cell = `${NAME}_${WIDTH}x${HEIGHT}_${THEME}_${LANG}${suffix}`;
    const dir = join(OUT, NAME);
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, `${cell}.web.png`), Buffer.from(shot.data, 'base64'));
    writeFileSync(
      join(dir, `${cell}.web.json`),
      JSON.stringify(
        { requested: { width: WIDTH, height: HEIGHT, dpr: DPR, theme: THEME, lang: LANG }, measured: facts },
        null,
        2,
      ) + '\n',
    );
    process.stdout.write(
      `captured ${cell}  innerWidth=${facts.innerWidth}  ` +
      `data-bp=${facts.dataBp}  dir=${facts.dir}  ` +
      `shell=${Math.round(facts.shell?.width)}x${Math.round(facts.shell?.height)}\n`,
    );
  } finally {
    cleanup();
  }
}

main().catch((e) => {
  process.stderr.write(`capture failed: ${e.message}\n`);
  process.exit(1);
});
