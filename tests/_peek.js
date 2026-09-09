/* Boot the real app and print what a chosen screen actually rendered. */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');
const { loadInto } = require('./modules');

const ROOT = path.resolve(__dirname, '..');

(async () => {
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const vc = new VirtualConsole();
  const errors = [];
  vc.on('jsdomError', e => errors.push(String(e.message || e)));
  vc.on('error', (...a) => errors.push(a.map(String).join(' ')));
  const dom = new JSDOM(html, {
    url: 'http://localhost/index.html', runScripts: 'dangerously',
    virtualConsole: vc, pretendToBeVisual: true,
    beforeParse(w) {
      w.localStorage.setItem('lume-onboarded', '1');
      w.localStorage.setItem('lume-profile', JSON.stringify({
        country: 'PK', city: 'Islamabad', islamic: true, lang: 'en',
        units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
        interests: ['weather', 'calendar', 'tasks', 'prayer'],
        prefs: { news: true, cricket: true, finance: true, recos: true },
        recents: [], favourites: [], recentCountries: []
      }));
      w.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
      w.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      w.HTMLCanvasElement.prototype.getContext = () => null;
      w.scrollTo = () => {};
    }
  });
  loadInto(dom, ROOT, errors);
  await new Promise(r => setTimeout(r, 120));
  const doc = dom.window.document;
  if (errors.length) console.log('ERRORS:', errors.slice(0, 3).join('\n'));
  for (const sel of process.argv.slice(2)) {
    const el = doc.querySelector(sel);
    const text = el ? (el.textContent || '').replace(/\s+/g, ' ').trim() : null;
    console.log('\n--- ' + sel + ' (' + (el ? el.innerHTML.length + ' chars' : 'MISSING') + ')');
    console.log(text === null ? 'MISSING' : (text.slice(0, 400) || '(empty)'));
  }
  process.exit(0);
})();
