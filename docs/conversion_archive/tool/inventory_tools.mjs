/* The tool inventory, taken mechanically from the reference.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/inventory_tools.mjs
 *
 * Imports the catalogue, the tool specifications and the record schemas as the
 * ES modules they are, reads every `*.tool.js` as text (a module that builds
 * HTML cannot be evaluated outside a document), and writes
 * `docs/conversion_archive/measurements/tool_inventory.json`:
 *
 *   counts     features, modules, shared modules, per category and archetype
 *   features   one row per catalogue entry, with its spec and its module
 *   modules    one row per module: the builders, context calls, data, charts,
 *              sheets and platform APIs it uses — the composition evidence the
 *              archetypes in TOOL_INVENTORY.md are derived from
 *   mismatches what the registry's own load-time check would not catch
 *
 * Flutter status is read from the tool registry, not guessed from where an id
 * happens to appear: an id is `built` when `lib/features/tools/application/
 * tool_registry.dart` names it, and `placeholder` otherwise, because every
 * catalogue id resolves to the fixture tool screen until then.
 */
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const ROOT = resolve(process.cwd());
const OUT = join(ROOT, 'docs/conversion_archive/measurements/tool_inventory.json');
const rel = (p) => relative(ROOT, p).replaceAll('\\', '/');
const walk = (d) => readdirSync(d).flatMap((n) => {
  const p = join(d, n);
  return statSync(p).isDirectory() ? walk(p) : [p];
});
const load = (p) => import(pathToFileURL(join(ROOT, p)).href);

const { LUME } = await load('assets/js/data/catalogue.js');
const { LUME_SPEC } = await load('assets/js/data/tool-specs.js');
const { isRecordTool } = await load('assets/js/data/record-schemas.js');

const toolDir = join(ROOT, 'assets/js/tools');
const files = walk(toolDir);
const toolFiles = files.filter((p) => p.endsWith('.tool.js'));
const sharedFiles = files.filter((p) => !p.endsWith('.tool.js'));
const host = readFileSync(join(ROOT, 'assets/js/screens/tool.screen.js'), 'utf8');
const tests = walk(join(ROOT, 'tests')).filter((p) => p.endsWith('.js'))
  .map((p) => readFileSync(p, 'utf8'));
const registryPath = join(ROOT, 'lib/features/tools/application/tool_registry.dart');
const registry = existsSync(registryPath) ? readFileSync(registryPath, 'utf8') : '';

const uniq = (a) => [...new Set(a)].sort();
const all = (src, re) => uniq([...src.matchAll(re)].map((m) => m[1]));
const CHARTS = ['sparkline', 'lineChart', 'barChart', 'donut', 'heatmap', 'map', 'journey', 'timeline'];

const modules = toolFiles.map((file) => {
  const src = readFileSync(file, 'utf8');
  const id = file.split(/[\\/]/).pop().replace('.tool.js', '');
  const shared = all(src, /from '\.\.\/shared\/([a-z]+)\.js'/g);
  return {
    id,
    file: rel(file),
    lines: src.split('\n').length,
    declares: all(src, /^\s{2}id:\s*'([a-z0-9]+)'/gm),
    shared,
    ui: all(src, /\bUI\.(\w+)\s*\(/g).filter((n) => n !== 'esc' && n !== 'ico'),
    charts: CHARTS.filter((k) => new RegExp(`UI\\.${k}\\s*\\(`).test(src)),
    context: all(src, /\bc\.(\w+)\s*\(/g),
    data: all(src, /\bD\.([A-Za-z_]\w*)/g),
    sheets: all(src, /sheet:([a-z-]+)/g),
    toolstate: all(src, /toolstate:[a-z0-9]+:([a-z0-9_.-]+):/g),
    links: all(src, /'tool:([a-z0-9]+)'/g),
    external: uniq(['tel:', 'mailto:', 'http'].filter((k) => src.includes(`"${k}`) || src.includes(`'${k}`) || src.includes(`href="${k}`))),
    /* A handler the host keeps for this one tool — the interaction lives in
       tool.screen.js, not in the module. */
    hostHandlers: all(host, new RegExp(`function (\\w*${id[0].toUpperCase() + id.slice(1)}\\w*)\\s*\\(`, 'g'))
      .concat(host.includes(`currentTool === '${id}'`) ? [`currentTool === '${id}'`] : []),
    webTestMentions: tests.reduce((n, s) => n + (s.match(new RegExp(`['"]${id}['"]`, 'g')) ?? []).length, 0),
  };
});

const features = LUME.FEATURES.map((f) => {
  const spec = LUME_SPEC.get(f.id);
  const m = modules.find((x) => x.id === f.id);
  return {
    id: f.id, name: f.n, category: f.c, group: f.g,
    faith: !!f.faith, countries: f.countries ?? null, android: !!f.android,
    act: f.act, sensitive: !!(f.sens || spec.sensitive),
    archetype: spec.archetype, density: spec.density,
    source: spec.source, freshness: spec.freshness, related: spec.related,
    supports: Object.keys(spec.supports).sort(), aware: Object.keys(spec.aware).sort(),
    needs: Object.keys(spec.needs).sort(),
    approvedComposition: spec.composition,
    recordFamily: isRecordTool(f.id),
    module: m ? m.file : null,
    flutter: new RegExp(`['"]${f.id}['"]\\s*:`).test(registry) ? 'built' : 'placeholder',
  };
});

/* The archetypes TOOL_INVENTORY.md derives, as data, so the counts are
   computed rather than typed. `reference` is the tool that proves the
   archetype; `members` are the tools that share its composition. Tools that
   belong to no archetype are listed by why. Every catalogue id must appear
   exactly once across all of it, or the script fails. */
const ARCHETYPES = {
  formCalculator: { reference: 'tax', members: ['tax', 'loan', 'compound', 'fuelcost', 'zakat', 'age', 'datecalc', 'bmi', 'tipsplit', 'faraid'] },
  recordsManager: { reference: 'documents', members: ['documents', 'health', 'meds', 'todos', 'notes', 'reminders', 'events', 'shopping', 'ledger', 'installments', 'committee', 'vehicle', 'subs', 'vaccines', 'alarms', 'mediasaver'] },
  financeDashboard: { reference: 'expenses', members: ['expenses', 'bills', 'goals', 'babybudget'] },
  contextDashboard: { reference: 'weather', members: ['weather', 'prayer', 'ramadan', 'aqi', 'sunmoon', 'loadshed', 'cricket', 'pregnancy'] },
  tracker: { reference: 'learning', members: ['learning', 'habits', 'water', 'praytrack', 'fasting', 'streak'] },
  planner: { reference: 'calendar', members: ['calendar'] },
  dataExplorer: { reference: 'goldrates', members: ['goldrates', 'currency', 'fuel', 'natsavings', 'prizebonds', 'packages', 'worldclock', 'quransearch'] },
  liveTracking: { reference: 'flights', members: ['flights', 'trains', 'parcel', 'mosques', 'taraweeh'] },
  editorialReader: { reference: 'news', members: ['news'] },
  scriptureReader: { reference: 'hadith', members: ['hadith', 'quran', 'ayah', 'duas', 'names99'] },
  visualLibrary: { reference: 'recipes', members: ['recipes', 'play'] },
  clockInstrument: { reference: 'timer', members: ['timer', 'stopwatch', 'focus'] },
  cameraInstrument: { reference: 'qr', members: ['qr', 'docscan'] },
  actionInterface: { reference: 'emergency', members: ['emergency'] },
};
const OUTSIDE = {
  /* A host handler of its own and no builder shared with another tool, or
     (Markets, D4) session and exchange rules no explorer has. */
  oneOff: ['calculator', 'converter', 'tasbih', 'speedtest', 'qibla', 'markets'],
  /* Composed on their own: share a label or a date with an archetype, not its
     structure (D3), or ask for a permission without the scanner. */
  ownComposition: ['hijri', 'holidays', 'mealplan', 'cycle', 'birthdays', 'passport', 'wastatus'],
};
{
  const seen = new Map();
  const note = (id, where) => seen.set(id, [...(seen.get(id) || []), where]);
  for (const [a, { reference, members }] of Object.entries(ARCHETYPES)) {
    if (!members.includes(reference)) throw new Error(`${a}: reference ${reference} is not a member`);
    members.forEach((id) => note(id, a));
  }
  for (const [k, ids] of Object.entries(OUTSIDE)) ids.forEach((id) => note(id, k));
  const all = LUME.FEATURES.map((f) => f.id);
  const missing = all.filter((id) => !seen.has(id));
  const twice = [...seen].filter(([, w]) => w.length > 1);
  const unknown = [...seen.keys()].filter((id) => !all.includes(id));
  if (missing.length || twice.length || unknown.length) {
    throw new Error(`archetype map: missing ${missing}, twice ${JSON.stringify(twice)}, unknown ${unknown}`);
  }
}

const featureIds = new Set(features.map((f) => f.id));
const moduleIds = new Set(modules.map((m) => m.id));
const mismatches = [
  { kind: 'catalogue feature with no module', ids: [...featureIds].filter((i) => !moduleIds.has(i)) },
  { kind: 'module with no catalogue feature', ids: [...moduleIds].filter((i) => !featureIds.has(i)) },
  { kind: 'module whose declared id is not its file name',
    ids: modules.filter((m) => m.declares[0] !== m.id).map((m) => m.id) },
  { kind: 'catalogue act that does not open the feature’s own tool',
    ids: features.filter((f) => f.act && f.act !== `tool:${f.id}`).map((f) => `${f.id} → ${f.act}`) },
  { kind: 'catalogue act left empty (opened through the hub’s tool:<id>)',
    ids: features.filter((f) => !f.act).map((f) => f.id) },
  { kind: 'duplicate catalogue id', ids: features.map((f) => f.id).filter((id, i, a) => a.indexOf(id) !== i) },
];

const count = (list, key) => Object.fromEntries(
  uniq(list.map((x) => String(x[key]))).map((k) => [k, list.filter((x) => String(x[key]) === k).length]));

const result = {
  counts: {
    features: features.length,
    modules: modules.length,
    sharedModules: sharedFiles.length,
    moduleLines: modules.reduce((n, m) => n + m.lines, 0),
    byCategory: count(features, 'category'),
    byArchetype: count(features, 'archetype'),
    byDensity: count(features, 'density'),
    recordFamilies: features.filter((f) => f.recordFamily).map((f) => f.id),
    faith: features.filter((f) => f.faith).length,
    countryGated: features.filter((f) => f.countries).map((f) => f.id),
    androidOnly: features.filter((f) => f.android).map((f) => f.id),
    sensitive: features.filter((f) => f.sensitive).map((f) => f.id),
    flutterBuilt: features.filter((f) => f.flutter === 'built').map((f) => f.id),
  },
  archetypes: {
    count: Object.keys(ARCHETYPES).length,
    references: Object.values(ARCHETYPES).map((a) => a.reference),
    members: Object.values(ARCHETYPES).reduce((n, a) => n + a.members.length, 0),
    oneOff: OUTSIDE.oneOff,
    ownComposition: OUTSIDE.ownComposition,
    recordLayer: features.filter((f) => f.recordFamily).map((f) => f.id),
    map: ARCHETYPES,
  },
  mismatches,
  sharedModules: sharedFiles.map((p) => ({ file: rel(p), lines: readFileSync(p, 'utf8').split('\n').length })),
  features,
  modules,
};

writeFileSync(OUT, JSON.stringify(result, null, 1) + '\n');
process.stdout.write(
  `inventoried ${features.length} features, ${modules.length} modules, ` +
  `${sharedFiles.length} shared · built in Flutter ${result.counts.flutterBuilt.length}\n`);
