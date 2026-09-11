/* Read element bounds out of the running authentication flow.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/measure_auth.mjs \
 *     --route signin --width 390 --height 844 --theme light --lang en
 *
 * Same method as `measure_onboarding.mjs`: drive the real flow to a state,
 * then report `getBoundingClientRect` for a named set of elements so the
 * Flutter side asserts against numbers rather than against a reading of the
 * stylesheet.
 *
 * `--route` names a *state*, not only a screen. `signin_error` is the sign-in
 * screen after a refused submission; `signin_busy` is the same screen during
 * the 420 ms the button spends working. Those are the states that have their
 * own layout, so those are the states that get measured.
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
const ROUTE = args.route || 'signin';
/* Also write a PNG beside the JSON. The same driver reaches the state, so a
   capture and a measurement can never be of two different screens. */
const SHOT = args.shot === '1' || args.shot === 'true';
const SHOTS = resolve(args.shots || 'docs/conversion_archive/shots/auth');
const PORT = Number(args.port || 8179);
const CDP_PORT = Number(args.cdpPort || 9357);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/* The elements whose position matters, named the way the Flutter side names
   them so a report can pair the two without a lookup table. */
const TARGETS = {
  'auth': '.auth',
  'auth.region': '.auth__region',
  'auth.panel': '.auth__panel',
  'auth.top': '.auth__top',
  'auth.back': '.auth__nav--back',
  'auth.close': '.auth__nav--close',
  'auth.stepOf': '.auth__step-of',
  'auth.brand': '.auth__brand',
  'auth.mark': '.auth__mark',
  'auth.word': '.auth__word',
  'auth.visual': '.auth__visual',
  'auth.seal': '.authseal',
  'auth.seal.disc': '.authseal__disc',
  'auth.hero': '.auth__hero',
  'auth.title': '.auth__title',
  'auth.text': '.auth__text',
  'auth.note': '.auth__note',
  'auth.steps': '.authsteps',
  'auth.steps.seg': '.authsteps__seg',
  'auth.notice': '.auth .formok',
  'auth.formerr': '.auth .formerr',
  'auth.form': '.auth__form',
  'auth.field.first': '.auth__form .field',
  'auth.fieldLabel.first': '.auth__form .field__label',
  'auth.fieldBox.first': '.auth__form .field__box',
  'auth.fieldMsg.first': '.auth__form .field__msg',
  'auth.field.second': '.auth__form .field:nth-of-type(2)',
  'auth.pwtoggle': '.auth__form .pwtoggle',
  'auth.fieldOk': '.auth__form .field__ok',
  'auth.inline': '.auth__inline',
  'auth.pwmeter': '.pwmeter',
  'auth.pwmeter.track': '.pwmeter__track',
  'auth.pwmeter.label': '.pwmeter__label',
  'auth.pwrules': '.pwrules',
  'auth.pwrules.title': '.pwrules__title',
  'auth.pwrule.first': '.pwrule',
  'auth.actions': '.auth__actions',
  'auth.submit': '.btn--auth',
  'auth.alt': '.auth__alt',
  'auth.or': '.auth__or',
  'auth.grow': '.auth__grow',
  'auth.foot': '.auth__foot',
  'auth.foot.secondary': '.auth__foot .btn--authsec',
  'auth.link.first': '.auth__foot .auth__link',
  'auth.link.quiet': '.auth__link--quiet',
  'auth.legal': '.auth__legal',
  'auth.aside': '.auth__aside',
  /* Not part of the composition — evidence for D18. The floating bar stays
     drawn over the flow, and `.screen--auth { padding-bottom: 0 }` removes
     the clearance every other screen keeps for it. */
  'shell.tabbar': '#tabbar',
};

/* Each state, as the clicks and keystrokes that reach it. `act(x)` fires a
   `data-act`; `type(name, value)` writes into a field and dispatches the
   input event the form layer listens for; `wait(ms)` covers the 420 ms
   deliberate submission delay. */
const SCRIPTS = {
  signin: "act('auth:signin')",
  signin_pending:
    "act('acct:security')",            /* a protected route opens it modal */
  signin_error:
    "act('auth:signin'); await wait(250); type('email','nobody@example.com');" +
    " type('password','Whatever1'); act('acctsubmit:signin'); await wait(800)",
  signin_invalid:
    "act('auth:signin'); await wait(250); type('email','not-an-address');" +
    " blur('email'); await wait(300)",
  signin_busy:
    "act('auth:signin'); await wait(250); type('email','a@b.com');" +
    " type('password','Whatever1'); act('acctsubmit:signin'); await wait(180)",
  signup: "act('auth:signup')",
  signup2:
    "act('auth:signup'); await wait(250); type('email','new@example.com');" +
    " act('acctsubmit:signupstep'); await wait(800)",
  signup2_typed:
    "act('auth:signup'); await wait(250); type('email','new@example.com');" +
    " act('acctsubmit:signupstep'); await wait(800); type('password','abcd1234');" +
    " await wait(300)",
  forgot: "act('auth:forgot')",
  sent:
    "act('auth:forgot'); await wait(250); type('email','someone@example.com');" +
    " act('acctsubmit:forgot'); await wait(800)",
  reset:
    "act('auth:forgot'); await wait(250); type('email','someone@example.com');" +
    " act('acctsubmit:forgot'); await wait(800); act('auth:reset'); await wait(400)",
  updated:
    "await signUpFully(); act('acctdo:authdone'); await wait(500);" +
    " act('auth:forgot'); await wait(300); type('email','amina@example.com');" +
    " act('acctsubmit:forgot'); await wait(800); act('auth:reset'); await wait(400);" +
    " type('password','Passw0rdy'); type('confirm','Passw0rdy');" +
    " act('acctsubmit:reset'); await wait(900)",
  trouble: "act('auth:trouble')",
  created: "await signUpFully()",
  expired: "act('auth:expired')",
  verify:
    "await signUpFully(); act('acctdo:authdone'); await wait(600);" +
    " act('acct:email'); await wait(500); type('email','moved@example.com');" +
    " act('acctsubmit:email'); await wait(900)",
};

const DRIVER = `
(function () {
  try { localStorage.removeItem('lume-onboarded'); } catch (e) {}
  try { localStorage.setItem('lume-onboarded', '1'); } catch (e) {}

  function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

  /* A synthetic control rather than hunting for wherever the product happens
     to draw this action: the delegation is on document, so a button carrying
     the same data-act reaches the same code. */
  function act(a) {
    var b = document.createElement('button');
    b.setAttribute('data-act', a);
    b.style.position = 'fixed';
    b.style.opacity = '0';
    b.style.pointerEvents = 'none';
    document.body.appendChild(b);
    b.click();
    b.remove();
  }

  function fieldEl(name) {
    return document.querySelector('[data-afield="' + name + '"]');
  }

  function type(name, value) {
    var el = fieldEl(name);
    if (!el) return false;
    el.focus();
    el.value = value;
    el.dispatchEvent(new Event('input', { bubbles: true }));
    return true;
  }

  function blur(name) {
    var el = fieldEl(name);
    if (!el) return false;
    el.dispatchEvent(new FocusEvent('focusout', { bubbles: true }));
    el.blur();
    return true;
  }

  /* The whole sign-up, so the states behind it are reachable. */
  async function signUpFully() {
    act('auth:signup');
    await wait(300);
    type('name', 'Amina Tariq');
    type('email', 'amina@example.com');
    act('acctsubmit:signupstep');
    await wait(800);
    type('password', 'Passw0rdy');
    type('confirm', 'Passw0rdy');
    act('acctsubmit:signup');
    await wait(1000);
  }

  async function run() {
    await wait(900);
    ${SCRIPTS[ROUTE] === undefined
      ? "throw new Error('no script for " + ROUTE + "')"
      : SCRIPTS[ROUTE]};
    await wait(500);
    var clock = document.getElementById('statusClock');
    if (clock) clock.textContent = '16:41';
    document.documentElement.setAttribute('data-measure-ready', '1');
  }

  function start() { run().catch(function (e) {
    document.documentElement.setAttribute('data-measure-error', String(e && e.message || e));
  }); }
  if (document.readyState === 'complete') start();
  else window.addEventListener('load', start);
})();
`;

function stage() {
  const work = mkdtempSync(join(tmpdir(), 'lume-auth-'));
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
    if (!ready) throw new Error('the flow never reached ' + ROUTE);

    await cdp.evaluate(`(function () {
      document.documentElement.dataset.theme = ${JSON.stringify(THEME)};
      document.documentElement.lang = ${JSON.stringify(LANG)};
      document.documentElement.dir = ${JSON.stringify(DIR)};
      document.body.classList.toggle('is-rtl', ${DIR === 'rtl'});
      return true;
    })()`);
    await sleep(300);

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
        var lh = parseFloat(cs.lineHeight);
        var lines = Number.isFinite(lh) && lh > 0
          ? Math.round(r.height / lh)
          : null;
        out[name] = {
          x: Math.round(r.x * 100) / 100,
          y: Math.round(r.y * 100) / 100,
          width: Math.round(r.width * 100) / 100,
          height: Math.round(r.height * 100) / 100,
          lines: lines,
          font: cs.font || (cs.fontWeight + ' ' + cs.fontSize + '/' + cs.lineHeight),
          radius: cs.borderRadius,
          pad: cs.padding,
          margin: cs.margin,
          text: (el.textContent || '').trim().slice(0, 160) || null
        };
      });
      var scroll = {};
      [['screen', '.screen--auth'], ['panel', '.auth__panel'],
       ['region', '.auth__region'], ['body', '#authBody']].forEach(function (pair) {
        var el = document.querySelector(pair[1]);
        if (!el) return;
        scroll[pair[0]] = {
          clientHeight: el.clientHeight,
          scrollHeight: el.scrollHeight,
          scrolls: el.scrollHeight > el.clientHeight + 0.5,
          overflowY: getComputedStyle(el).overflowY
        };
      });
      var root = document.querySelector('.auth');
      return {
        bounds: out, missing: missing, scroll: scroll,
        id: root ? root.getAttribute('data-auth') : null,
        status: root ? root.classList.contains('auth--status') : null,
        busy: !!document.querySelector('.btn--auth.is-busy'),
        invalid: document.querySelectorAll('.field.is-invalid').length,
        valid: document.querySelectorAll('.field.is-valid').length,
        rulesOk: document.querySelectorAll('.pwrule.is-ok').length,
        rulesTotal: document.querySelectorAll('.pwrule').length,
        meterOn: document.querySelectorAll('.pwmeter__seg.is-on').length,
        segsOn: document.querySelectorAll('.authsteps__seg.is-on').length,
        segsTotal: document.querySelectorAll('.authsteps__seg').length,
        ariaLabel: (document.getElementById('screen-auth') || {}).ariaLabel || null
      };
    })()`);

    mkdirSync(OUT, { recursive: true });
    const cell = `auth_${ROUTE}_${WIDTH}x${HEIGHT}_${THEME}_${LANG}`;

    if (SHOT) {
      const shot = await cdp.send('Page.captureScreenshot', {
        format: 'png',
        captureBeyondViewport: false,
      });
      // Beside the Flutter capture, which `captureLume` files under a folder
      // named for the screen. `compare.mjs` pairs on the whole path.
      const dir = join(SHOTS, `auth_${ROUTE}`);
      mkdirSync(dir, { recursive: true });
      writeFileSync(join(dir, `${cell}.web.png`), Buffer.from(shot.data, 'base64'));
    }
    writeFileSync(
      join(OUT, `${cell}.json`),
      JSON.stringify(
        {
          cell,
          route: ROUTE,
          viewport: { width: WIDTH, height: HEIGHT, innerWidth },
          id: result.id,
          status: result.status,
          theme: THEME,
          lang: LANG,
          dir: DIR,
          state: {
            busy: result.busy,
            invalid: result.invalid,
            valid: result.valid,
            rules: { ok: result.rulesOk, total: result.rulesTotal },
            meterOn: result.meterOn,
            steps: { on: result.segsOn, total: result.segsTotal },
            ariaLabel: result.ariaLabel,
          },
          missing: result.missing,
          scroll: result.scroll,
          bounds: result.bounds,
        },
        null,
        2,
      ) + '\n',
    );

    process.stdout.write(
      `measured ${ROUTE} (${result.id}) at ${WIDTH}x${HEIGHT} ${THEME}/${LANG} · ` +
        `${Object.keys(result.bounds).length} elements` +
        (result.missing.length ? ` · absent ${result.missing.length}` : '') +
        '\n',
    );
  } finally {
    cleanup();
  }
}

main().catch((e) => {
  process.stderr.write(`auth measurement failed: ${e.message}\n`);
  process.exit(1);
});
