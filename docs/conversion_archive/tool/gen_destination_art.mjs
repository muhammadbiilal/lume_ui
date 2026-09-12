/* Lift the destinations' illustrations out of the prototype's templates.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9; the
 * assets it writes are production art and stay.
 *
 *   node docs/conversion_archive/tool/gen_destination_art.mjs
 *
 * Home carries thirteen bespoke drawings written inline in `home.screen.js`:
 * six hero slides, the two context strips the faith dimension swaps between,
 * and five Discover cards. The Tools hub carries one — the dashed magnifier
 * over its empty state. Same method and the same sentinel table as
 * `gen_onboarding_art.mjs` — geometry copied byte for byte, `var(--token)`
 * replaced by a colour that appears nowhere else, and the Flutter side mapping
 * the sentinels back to the live theme so the art is right in both.
 *
 * Deterministic: same template, same output.
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve, join } from 'node:path';

const ROOT = resolve(process.cwd());
const SRC = resolve(ROOT, 'assets/js/screens/home.screen.js');
const TOOLS_SRC = resolve(ROOT, 'assets/js/screens/tools.screen.js');
const TODAY_SRC = resolve(ROOT, 'assets/js/screens/today.screen.js');
const EXPLORE_SRC = resolve(ROOT, 'assets/js/screens/explore.screen.js');
const OUT = resolve(ROOT, 'assets/images/home');
const TOOLS_OUT = resolve(ROOT, 'assets/images/tools');
const TODAY_OUT = resolve(ROOT, 'assets/images/today');
const EXPLORE_OUT = resolve(ROOT, 'assets/images/explore');

/* The same table `gen_onboarding_art.mjs` uses, so one `ColorMapper` serves
   both and a sentinel means the same thing everywhere. */
const TOKENS = {
  '--accent': '#FF0001',
  '--accent-400': '#FF0002',
  '--accent-600': '#FF0003',
  '--accent-700': '#FF0004',
  '--violet': '#FF0005',
  '--sky': '#FF0006',
  '--card': '#FF0007',
  '--card-2': '#FF0008',
  '--border': '#FF0009',
  '--border-2': '#FF0012',
  '--text': '#FF000A',
  '--text-2': '#FF000B',
  '--text-3': '#FF000C',
  '--tint-accent': '#FF000D',
  '--tint-neutral': '#FF000E',
  '--bg': '#FF000F',
  '--amber': '#FF0010',
  '--rose': '#FF0011',
};

const src = readFileSync(SRC, 'utf8');

function detokenise(svg, name) {
  let out = svg;
  for (const [token, sentinel] of Object.entries(TOKENS)) {
    out = out.split(`var(${token})`).join(sentinel);
  }
  const left = out.match(/var\(--[a-z0-9-]+\)/g);
  if (left) {
    throw new Error(`${name}: unmapped ${[...new Set(left)].join(', ')}`);
  }
  /* One `xmlns`, because the inline SVG in an HTML document has none and a
     standalone asset needs it. */
  if (!/xmlns=/.test(out)) {
    out = out.replace('<svg', '<svg xmlns="http://www.w3.org/2000/svg"');
  }
  return out.trim() + '\n';
}

mkdirSync(OUT, { recursive: true });
const written = [];

/* ---- the six hero slides ------------------------------------------------ */
const slides = [
  ...src.matchAll(
    /<article class="slide[^"]*" data-slide="([a-z]+)"[^>]*>([\s\S]*?)<\/article>/g,
  ),
];
if (slides.length !== 6) {
  throw new Error(`expected 6 hero slides, found ${slides.length}`);
}
for (const [, id, body] of slides) {
  const svg = body.match(/<svg[\s\S]*?<\/svg>/);
  if (!svg) throw new Error(`slide ${id} has no artwork`);
  const file = `hero_${id}.svg`;
  writeFileSync(join(OUT, file), detokenise(svg[0], file));
  written.push(file);
}

/* ---- the two context strips -------------------------------------------- */
const strips = [
  ...src.matchAll(
    /<button class="ctx pressable" data-faith="([a-z]+)"[\s\S]*?<span class="ctx__art"[^>]*>([\s\S]*?)<\/span>/g,
  ),
];
if (strips.length !== 2) {
  throw new Error(`expected 2 context strips, found ${strips.length}`);
}
for (const [, faith, body] of strips) {
  const svg = body.match(/<svg[\s\S]*?<\/svg>/);
  if (!svg) throw new Error(`context strip ${faith} has no artwork`);
  const file = `ctx_${faith}.svg`;
  writeFileSync(join(OUT, file), detokenise(svg[0], file));
  written.push(file);
}

/* ---- the five Discover cards -------------------------------------------
 * They have no id of their own in the markup, so they are named by the
 * gradient each one declares — `d1`…`d5` — which is stable and is what the
 * template itself distinguishes them by. The Flutter enum is in the same
 * order, and `home_art_test.dart` asserts the pairing.
 */
const discoverNames = ['cricket', 'weather', 'outage', 'duas', 'parcel'];
const minicards = [
  ...src.matchAll(
    /<span class="minicard__art">([\s\S]*?)<\/span>/g,
  ),
];
if (minicards.length !== 5) {
  throw new Error(`expected 5 Discover cards, found ${minicards.length}`);
}
minicards.forEach(([, body], i) => {
  const svg = body.match(/<svg[\s\S]*?<\/svg>/);
  if (!svg) throw new Error(`Discover card ${i} has no artwork`);
  const file = `discover_${discoverNames[i]}.svg`;
  writeFileSync(join(OUT, file), detokenise(svg[0], file));
  written.push(file);
});

/* ---- the hub's empty state ---------------------------------------------- */
const toolsSrc = readFileSync(TOOLS_SRC, 'utf8');
const emptyBlock = toolsSrc.slice(
  toolsSrc.indexOf('<div class="empty" id="toolEmpty">'),
  toolsSrc.indexOf('</div>', toolsSrc.indexOf('<div class="empty"')),
);
const emptySvg = emptyBlock.match(/<svg[\s\S]*?<\/svg>/);
if (!emptySvg) throw new Error('the hub has no empty-state drawing');
mkdirSync(TOOLS_OUT, { recursive: true });
writeFileSync(
  join(TOOLS_OUT, 'empty.svg'),
  detokenise(emptySvg[0], 'tools/empty.svg'),
);
written.push('../tools/empty.svg');

/* ---- Today's one drawing -----------------------------------------------
 * The sparkle that drifts behind the ring card. It is the only illustration
 * on the screen; everything else there is type, a ring and coloured squares.
 */
const todaySrc = readFileSync(TODAY_SRC, 'utf8');
const sticker = todaySrc.match(
  /<span class="sticker sticker--slow"[\s\S]*?(<svg[\s\S]*?<\/svg>)/,
);
if (!sticker) throw new Error('Today has no sticker');
mkdirSync(TODAY_OUT, { recursive: true });
writeFileSync(
  join(TODAY_OUT, 'sticker.svg'),
  detokenise(sticker[1], 'today/sticker.svg'),
);
written.push('../today/sticker.svg');

/* ---- Explore's six --------------------------------------------------------
 * Two featured cards, faith-swapped, and four collection cards. Named by what
 * they are rather than by their gradient id, because unlike the Discover
 * strip these carry a `data-faith` or a title that says so.
 */
const exploreSrc = readFileSync(EXPLORE_SRC, 'utf8');
mkdirSync(EXPLORE_OUT, { recursive: true });

const features = [
  ...exploreSrc.matchAll(
    /<div class="section" style="margin-top:18px" data-faith="([a-z]+)">[\s\S]*?<div class="feature__art"[^>]*>([\s\S]*?)<\/div>/g,
  ),
];
if (features.length !== 2) {
  throw new Error(`expected 2 featured cards, found ${features.length}`);
}
for (const [, faith, body] of features) {
  const svg = body.match(/<svg[\s\S]*?<\/svg>/);
  if (!svg) throw new Error(`featured ${faith} has no artwork`);
  const file = `featured_${faith === 'islamic' ? 'duas' : 'calm'}.svg`;
  writeFileSync(join(EXPLORE_OUT, file), detokenise(svg[0], file));
  written.push(`../explore/${file}`);
}

const collectionNames = ['night_surahs', 'focus', 'gratitude', 'budget'];
const collections = [
  ...exploreSrc.matchAll(/<span class="minicard__art">([\s\S]*?)<\/span>/g),
];
if (collections.length !== 4) {
  throw new Error(`expected 4 collection cards, found ${collections.length}`);
}
collections.forEach(([, body], i) => {
  const svg = body.match(/<svg[\s\S]*?<\/svg>/);
  if (!svg) throw new Error(`collection ${i} has no artwork`);
  const file = `collection_${collectionNames[i]}.svg`;
  writeFileSync(join(EXPLORE_OUT, file), detokenise(svg[0], file));
  written.push(`../explore/${file}`);
});

writeFileSync(
  join(OUT, 'manifest.json'),
  JSON.stringify(
    {
      note:
        'Generated by docs/conversion_archive/tool/gen_destination_art.mjs ' +
        'from assets/js/screens/home.screen.js, tools.screen.js, ' +
        'today.screen.js and explore.screen.js. Colours ' +
        'that were CSS custom properties are sentinels; LumeArtColours maps ' +
        'them to the theme.',
      files: written,
    },
    null,
    2,
  ) + '\n',
);

process.stdout.write(`wrote ${written.length} drawings to assets/images/home\n`);
