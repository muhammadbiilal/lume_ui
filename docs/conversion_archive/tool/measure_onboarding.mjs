/* Read element bounds out of the running onboarding flow.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/measure_onboarding.mjs \
 *     --step 3 --width 390 --height 844 --theme light --lang en
 *
 * `measure_components.mjs` measures specimens in a fixture, which is the right
 * tool for a component's own box. It cannot answer where that box sits on a
 * real screen, and "the picker bar is eight pixels high in the prototype and
 * sixteen here" is exactly the kind of difference that only shows up as a
 * position.
 *
 * So this drives the real flow to a step, the way `capture_web.mjs` does, and
 * reports `getBoundingClientRect` plus the rendered line count for a named set
 * of elements. The Flutter side asserts against the numbers rather than
 * against a guess at what the stylesheet meant.
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
const STEP = Number(args.step ?? 3);
/* Whether to turn the Islamic experience on at the interests step, which is
   what makes the method block exist two steps later. */
const FAITH = args.faith === '1' || args.faith === 'true';
const PORT = Number(args.port || 8177);
const CDP_PORT = Number(args.cdpPort || 9355);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/* The elements whose *position* matters, named the way the Flutter side names
   them so a report can pair the two without a lookup table. */
const TARGETS = {
  'onb.top': '.onb__top',
  'onb.nav': '.onb__nav',
  'onb.progress': '.onb__progress',
  'onb.seg.first': '.onb__seg',
  'onb.skip': '.onb__skip',
  'onb.step': '.onb-step.is-active',
  'onb.art': '.onb-step.is-active .onb__art',
  'onb.brand': '.onb-step.is-active .onb__brand',
  'onb.mark': '.onb-step.is-active .onb__mark',
  'onb.wordmark': '.onb-step.is-active .onb__wordmark',
  'onb.link': '.onb-step.is-active .onb__link',
  'onb.namefield': '.onb-step.is-active .onb__namefield',
  'onb.kicker': '.onb-step.is-active .onb__kicker',
  'onb.title': '.onb-step.is-active .onb__title',
  'onb.text': '.onb-step.is-active .onb__text',
  'onb.foot': '.onb-step.is-active .onb__foot',
  'onb.continue': '.onb-step.is-active .onb__foot .btn',
  // country
  'locpicker': '.onb-step.is-active .locpicker',
  'locsearch': '.onb-step.is-active .search--sm',
  'locscroll': '.onb-step.is-active .locscroll',
  'locgroup.first': '.onb-step.is-active .locgroup',
  'loclist.first': '.onb-step.is-active .loclist',
  'locrow.first': '.onb-step.is-active .locrow',
  'locaction': '.onb-step.is-active .locrow--action',
  // interests
  'picker.bar': '#screen-onb .picker__bar, .onb-step.is-active .picker__bar',
  'picker.count': '.onb-step.is-active .picker__count',
  'picker.clear': '.onb-step.is-active .picker__clear',
  'pickgroup.first': '.onb-step.is-active .pickgroup',
  'pickgroup.label.first': '.onb-step.is-active .pickgroup__label',
  'pick.first': '.onb-step.is-active .pick',
  'pickgroup.faith': '.onb-step.is-active .pickgroup--faith',
  // set up
  'onb.rows': '.onb-step.is-active .onb-rows',
  'onb.row.first': '.onb-step.is-active .onb-row',
  'onb.row.title': '.onb-step.is-active .onb-row__title',
  'onb.row.sub': '.onb-step.is-active .onb-row__sub',
  'onb.methodLabel': '.onb-step.is-active .group-label',
  'onb.choice': '.onb-step.is-active .onb-choice',
  'onb.choice.first': '.onb-step.is-active .onb-choice button',
  'onb.note': '.onb-step.is-active .onb__note',
  // name
  'onb.field': '.onb-step.is-active .field',
  'onb.fieldLabel': '.onb-step.is-active .field__label',
  'onb.fieldBox': '.onb-step.is-active .field__box',
  'onb.skipStep': '#onbNameSkip',
  // done
  'onb.seal': '.onb-step.is-active .onb__seal',
};

const DRIVER = `
(function () {
  try { localStorage.removeItem('lume-onboarded'); } catch (e) {}
  var wantStep = ${STEP};
  function settle() {
    var clock = document.getElementById('statusClock');
    if (clock) clock.textContent = '16:41';
    document.documentElement.setAttribute('data-measure-ready', '1');
  }
  function advance(done) {
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
      /* The interests step will not advance until five are chosen, and the
         button re-disables itself on every render, so choosing has to happen
         before clicking rather than instead of it. */
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
      /* Steps 5 and 7 gate their own buttons and do not carry the hook. */
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
  const work = mkdtempSync(join(tmpdir(), 'lume-onb-'));
  cpSync(join(REF, 'index.html'), join(work, 'index.html'));
  cpSync(join(REF, 'assets'), join(work, 'assets'), { recursive: true });
  mkdirSync(join(work, 'scripts'), { recursive: true });
  cpSync(join(REF, 'scripts/serve.js'), join(work, 'scripts/serve.js'));
  writeFileSync(join(work, 'measure-driver.js'), DRIVER);
  
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
  const work = stage();
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
        const list = await fetch(
          `http://127.0.0.1:${CDP_PORT}/json/list`,
        ).then((r) => r.json());
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

    await cdp.evaluate(`(function () {
      document.documentElement.dataset.theme = ${JSON.stringify(THEME)};
      document.documentElement.lang = ${JSON.stringify(LANG)};
      document.documentElement.dir = ${JSON.stringify(DIR)};
      return true;
    })()`);

    let ready = false;
    for (let i = 0; i < 250 && !ready; i++) {
      await sleep(100);
      try {
        ready = await cdp.evaluate(
          "document.documentElement.getAttribute('data-measure-ready') === '1'",
        );
      } catch (e) { /* navigating */ }
    }
    if (!ready) throw new Error('the flow never reached step ' + STEP);

    await cdp.evaluate(`(function () {
      document.documentElement.dataset.theme = ${JSON.stringify(THEME)};
      document.documentElement.lang = ${JSON.stringify(LANG)};
      document.documentElement.dir = ${JSON.stringify(DIR)};
      document.body.classList.toggle('is-rtl', ${DIR === 'rtl'});
      return true;
    })()`);
    await sleep(400);

    const innerWidth = await cdp.evaluate('window.innerWidth');
    if (innerWidth !== WIDTH) {
      throw new Error(`viewport did not take: asked ${WIDTH}, got ${innerWidth}`);
    }

    const result = await cdp.evaluate(`(function () {
      var targets = ${JSON.stringify(TARGETS)};
      var out = {};
      var missing = [];
      Object.keys(targets).forEach(function (name) {
        var el = document.querySelector(targets[name]);
        if (!el) { missing.push(name); return; }
        var r = el.getBoundingClientRect();
        var cs = getComputedStyle(el);
        /* Rendered line count, for the wrapping comparison: the element's own
           height over one line's height. A paragraph that wraps to three lines
           in one engine and four in the other is a real difference, and it is
           invisible in a box measurement. */
        var lh = parseFloat(cs.lineHeight);
        var lines = Number.isFinite(lh) && lh > 0
          ? Math.round(el.getBoundingClientRect().height / lh)
          : null;
        out[name] = {
          x: Math.round(r.x * 100) / 100,
          y: Math.round(r.y * 100) / 100,
          width: Math.round(r.width * 100) / 100,
          height: Math.round(r.height * 100) / 100,
          lines: lines,
          /* The whole element's text, children included: a heading that
             wraps a count in a span still has a sentence in it, and the
             comparison needs to read it. */
          text: (el.textContent || '').trim().slice(0, 120) || null
        };
      });
      /* Whether a box is scrolling, and by how much. A short viewport is
         answered by an overflow rule somewhere, and which box takes the
         scroll is the whole question - a box measurement alone cannot say. */
      var scroll = {};
      [['step', '.onb-step.is-active'],
       ['locscroll', '.onb-step.is-active .locscroll'],
       ['pickscroll', '.onb-step.is-active .pickscroll'],
       ['shell', '.onb']].forEach(function (pair) {
        var el = document.querySelector(pair[1]);
        if (!el) return;
        scroll[pair[0]] = {
          clientHeight: el.clientHeight,
          scrollHeight: el.scrollHeight,
          scrolls: el.scrollHeight > el.clientHeight + 0.5,
          overflowY: getComputedStyle(el).overflowY
        };
      });
      return { bounds: out, missing: missing, scroll: scroll,
               step: Number((document.querySelector('.onb-step.is-active') || {}).dataset ?
                 document.querySelector('.onb-step.is-active').dataset.step : -1),
               segsDone: document.querySelectorAll('.onb__seg.is-done').length,
               segsTotal: document.querySelectorAll('.onb__seg').length };
    })()`);

    mkdirSync(OUT, { recursive: true });
    const cell =
      `onboarding_step${STEP}_${WIDTH}x${HEIGHT}_${THEME}_${LANG}` +
      (FAITH ? '_faith' : '');
    writeFileSync(
      join(OUT, `${cell}.json`),
      JSON.stringify(
        {
          cell,
          viewport: { width: WIDTH, height: HEIGHT, innerWidth },
          step: result.step,
          progress: { done: result.segsDone, total: result.segsTotal },
          theme: THEME,
          lang: LANG,
          dir: DIR,
          missing: result.missing,
          scroll: result.scroll,
          bounds: result.bounds,
        },
        null,
        2,
      ) + '\n',
    );

    process.stdout.write(
      `measured step ${result.step} at ${WIDTH}x${HEIGHT} ${THEME}/${LANG} · ` +
        `${Object.keys(result.bounds).length} elements · ` +
        `progress ${result.segsDone}/${result.segsTotal}` +
        (result.missing.length ? ` · missing ${result.missing.join(',')}` : '') +
        '\n',
    );
  } finally {
    cleanup();
  }
}

main().catch((e) => {
  process.stderr.write(`onboarding measurement failed: ${e.message}\n`);
  process.exit(1);
});
