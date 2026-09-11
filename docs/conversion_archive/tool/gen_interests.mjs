/* Turn the reference's interest catalogue into a Flutter asset.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9; the
 * asset it writes is production data and stays.
 *
 *   node docs/conversion_archive/tool/gen_interests.mjs
 *
 * Two things are read out of `data/catalogue.js`, and they answer two
 * different questions:
 *
 *   INTEREST_GROUPS   what the picker *offers* — 31 ids in 6 groups
 *   FEATURES[].ints   what an interest can *lead to*
 *
 * `liveItems` in ui/pickers.js keeps an ordinary interest only when some
 * visible feature declares it, so the second list is what decides whether a
 * chip is rendered at all. Two interests — `sleep` and `quotes` — are declared
 * in a group and referenced by no feature, so the prototype never renders
 * them. That is recorded here rather than quietly dropped, because it is a
 * finding about the reference and not a decision about the conversion.
 *
 * Labels are **not** carried: the prototype hard-codes English ones in the
 * catalogue and never translates them, which is a defect the Flutter app does
 * not reproduce. They live in the ARBs instead, in all three languages.
 *
 * Deterministic: same input, same output.
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const ROOT = resolve(process.cwd());
const SRC = resolve(ROOT, 'assets/js/data/catalogue.js');
const OUT = resolve(ROOT, 'assets/data/interests.json');

const src = readFileSync(SRC, 'utf8');

/* ---- the groups, and the 31 ids ---------------------------------------- */
const block = src.slice(
  src.indexOf('var INTEREST_GROUPS'),
  src.indexOf('var FAITH_INTERESTS'),
);
if (!block) throw new Error('INTEREST_GROUPS not found');

const headers = [
  ...block.matchAll(
    /\{ id: '([a-z]+)', label: '([^']+)'(, faith: true)?, items: \[/g,
  ),
];
const bodies = block
  .split(/\{ id: '[a-z]+', label: '[^']+'(?:, faith: true)?, items: \[/)
  .slice(1);

const groups = headers.map((h, i) => {
  const items = [
    ...bodies[i].matchAll(
      /\{ id: '([a-z]+)',\s*label: '([^']*)',\s*icon: '([a-z-]+)'\s*\}/g,
    ),
  ];
  return {
    id: h[1],
    faith: Boolean(h[3]),
    // The English label is kept only as a comment for the ARB author; nothing
    // reads it at runtime.
    referenceLabel: h[2],
    items: items.map((m) => ({
      id: m[1],
      // The sprite ids are `i-cloud-sun`; the Flutter assets are
      // `cloud-sun.svg` and `LumeIcons` names them without the prefix. Strip
      // it here rather than at every call site — a name that does not resolve
      // renders nothing at all, silently, which is how the first pass shipped
      // chips with no glyphs.
      icon: m[3].replace(/^i-/, ''),
      referenceLabel: m[2],
    })),
  };
});

const ids = groups.flatMap((g) => g.items.map((i) => i.id));
if (new Set(ids).size !== ids.length) throw new Error('duplicate interest id');

/* ---- what a feature can lead to ---------------------------------------- */
const referenced = new Set();
for (const m of src.matchAll(/ints:\s*\[([^\]]*)\]/g)) {
  for (const n of m[1].matchAll(/'([a-z]+)'/g)) referenced.add(n[1]);
}

const unreachable = ids.filter((id) => !referenced.has(id));

/* ---- FAITH_INTERESTS, which the switch uses to clear ------------------- */
const faithMatch = /var FAITH_INTERESTS = \[([^\]]*)\]/.exec(src);
if (!faithMatch) throw new Error('FAITH_INTERESTS not found');
const faithInterests = [...faithMatch[1].matchAll(/'([a-z]+)'/g)].map(
  (m) => m[1],
);

/* ---- the defaults a skipped picker falls back to ----------------------- */
const defaultsMatch = /var DEFAULT_INTERESTS = \[([^\]]*)\]/.exec(src);
const defaults = defaultsMatch
  ? [...defaultsMatch[1].matchAll(/'([a-z]+)'/g)].map((m) => m[1])
  : [];

mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(
  OUT,
  JSON.stringify(
    {
      source: 'assets/js/data/catalogue.js',
      generator: 'docs/conversion_archive/tool/gen_interests.mjs',
      groupCount: groups.length,
      interestCount: ids.length,
      minimum: 5,
      maximum: 10,
      faithInterests,
      defaults,
      // Every interest some feature declares. `liveItems` offers an ordinary
      // interest only when it is in here *and* that feature is visible.
      referencedByFeatures: [...referenced].sort(),
      // Declared in a group, referenced by nothing: never rendered.
      unreachable,
      groups,
    },
    null,
    2,
  ) + '\n',
);

process.stdout.write(
  `wrote ${groups.length} groups, ${ids.length} interests ` +
    `(${unreachable.length} unreachable: ${unreachable.join(', ') || 'none'}) ` +
    `to assets/data/interests.json\n`,
);
