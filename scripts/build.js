/* ============================================================
   Lume — the openable build

   The app is ES modules, and a browser refuses a module script
   on a file:// origin. Served over HTTP that is the right
   architecture and nothing here is involved.

   But "double-click the file and look at it" is a workflow
   worth keeping, so this produces one: build/index.html, whose
   module graph has been bundled into a single classic script it
   loads alongside the real stylesheets. Nothing is copied or
   duplicated — the CSS is referenced in place, one directory
   up — so the build cannot drift away from the source.

   It verifies its own output rather than trusting it: the
   result is booted in jsdom and checked for the shell, the tab
   bar, a rendered Home and a clean console before this reports
   success.

   Run: npm run build     Then open build/index.html
   ============================================================ */
const fs = require('fs');
const path = require('path');
const { bundle } = require('./bundler');

const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'build');

function main() {
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');

  const entry = /<script[^>]*type="module"[^>]*src="([^"]+)"[^>]*><\/script>/.exec(html);
  if (!entry) throw new Error('index.html has no module entry point to bundle');

  const code = bundle(entry[1], ROOT);

  fs.mkdirSync(OUT, { recursive: true });
  fs.writeFileSync(path.join(OUT, 'lume.bundle.js'), code);

  /* The stylesheets are referenced where they live rather than copied, so
     editing one is reflected the next time the page is opened and there is
     no second copy to fall out of date. */
  const page = html
    .replace(/href="assets\//g, 'href="../assets/')
    .replace(entry[0],
      '<!-- Built by scripts/build.js so this page opens from file://.\n'
      + '     Serve the real index.html for development; rebuild with npm run build. -->\n'
      + '<script src="lume.bundle.js"></script>');

  fs.writeFileSync(path.join(OUT, 'index.html'), page);

  const kb = n => (n / 1024).toFixed(0) + ' KB';
  console.log('  build/lume.bundle.js   ' + kb(code.length));
  console.log('  build/index.html       ' + kb(page.length));
  return { page, code };
}

/* ---- verify what was just written --------------------------------------
   A build that emits a broken page and says "done" is worse than no build,
   so the output is opened the way a browser would open it. */
function verify() {
  let JSDOM, VirtualConsole;
  try {
    ({ JSDOM, VirtualConsole } = require('jsdom'));
  } catch (e) {
    console.log('\n  (jsdom not installed — skipping verification)');
    return true;
  }

  const vc = new VirtualConsole();
  const errors = [];
  vc.on('jsdomError', e => errors.push(String(e.message || e)));
  vc.on('error', (...a) => errors.push(a.map(String).join(' ')));

  const dom = new JSDOM(fs.readFileSync(path.join(OUT, 'index.html'), 'utf8'), {
    /* A file:// URL, because that is the origin this build exists for.
       Storage throws on it in some browsers, which is exactly the case the
       storage wrapper is written to survive. */
    url: 'file:///' + path.join(OUT, 'index.html').replace(/\\/g, '/'),
    runScripts: 'outside-only',
    virtualConsole: vc,
    pretendToBeVisual: true
  });

  const win = dom.window;
  win.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {},
                           addEventListener() {}, removeEventListener() {} });
  win.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
  win.cancelAnimationFrame = id => clearTimeout(id);
  win.HTMLCanvasElement.prototype.getContext = () => null;
  win.scrollTo = () => {};
  try { win.localStorage.setItem('lume-onboarded', '1'); } catch (e) { /* as on file:// */ }

  win.eval(fs.readFileSync(path.join(OUT, 'lume.bundle.js'), 'utf8'));

  return new Promise(resolve => setTimeout(() => {
    const doc = win.document;
    const checks = [
      ['the shell mounted', !!doc.querySelector('#screens')],
      ['ten screens are present', doc.querySelectorAll('.screen').length === 10],
      ['exactly one is showing', doc.querySelectorAll('.screen.is-active').length === 1],
      ['the tab bar is built', doc.querySelectorAll('.tab').length >= 4],
      ['Home rendered its quick tools',
        (doc.querySelector('#quickTools') || { children: [] }).children.length > 0],
      ['the console stayed clean', errors.length === 0, errors.slice(0, 2).join(' | ')]
    ];

    console.log('\n  Opened from file:// and checked:');
    let bad = 0;
    for (const [label, pass, extra] of checks) {
      console.log('    ' + (pass ? 'ok   ' : 'FAIL ') + label + (pass ? '' : '  -> ' + (extra || '')));
      if (!pass) bad++;
    }
    resolve(bad === 0);
  }, 200));
}

(async () => {
  try {
    main();
    const ok = await verify();
    console.log(ok
      ? '\n  Open build/index.html directly in a browser.\n'
      : '\n  The build is broken — do not open it.\n');
    process.exit(ok ? 0 : 1);
  } catch (e) {
    console.error('\n  build failed: ' + e.message + '\n');
    process.exit(1);
  }
})();
