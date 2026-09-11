/* Turn the reference's country table into a Flutter asset.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9; the
 * asset it writes is production data and stays.
 *
 *   node docs/conversion_archive/tool/gen_countries.mjs
 *
 * `data/geo.js` holds 194 countries as pipe-delimited rows, and the prototype
 * renders each one's name through `Intl.DisplayNames('region')` — so the names
 * a user sees are ICU's, in their language, and are not in the repository at
 * all. Flutter's `intl` has no `DisplayNames`, so the names have to travel with
 * the app.
 *
 * They are read here from the same ICU tables the browser reads, for the three
 * languages Lume ships, and written next to the code and the currency. The
 * result is the same string the reference would have displayed, which is the
 * only definition of "correct" that matters for a conversion.
 *
 * Deterministic: same input, same output, sorted by code. Re-run it and diff.
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const ROOT = resolve(process.cwd());
const SRC = resolve(ROOT, 'assets/js/data/geo.js');
const OUT = resolve(ROOT, 'assets/data/countries.json');

const LANGS = ['en', 'ur', 'ar'];

const src = readFileSync(SRC, 'utf8');

/* The rows are a single-quoted pipe list, one per line, between ROWS = [ and
   the closing bracket. Read them the way geo.js reads them rather than
   re-deriving the shape. */
const rowsBlock = src.slice(src.indexOf('var ROWS'), src.indexOf('var REGIONS'));
const rows = [...rowsBlock.matchAll(/'([A-Z]{2}\|[^']*)'/g)].map((m) => m[1]);
if (rows.length === 0) throw new Error('no country rows found in geo.js');

const popularMatch = /var POPULAR = \[([^\]]*)\]/.exec(src);
if (!popularMatch) throw new Error('POPULAR not found in geo.js');
const popular = [...popularMatch[1].matchAll(/'([A-Z]{2})'/g)].map((m) => m[1]);

const display = {};
for (const lang of LANGS) {
  display[lang] = new Intl.DisplayNames([lang], { type: 'region' });
}

const countries = rows
  .map((row) => {
    const p = row.split('|');
    const code = p[0];
    const names = {};
    for (const lang of LANGS) {
      const name = display[lang].of(code);
      // ICU returns the code itself when it has no name for it. That would put
      // a bare "XK" in the list, which is worse than falling back to English.
      names[lang] = name === code && lang !== 'en' ? display.en.of(code) : name;
    }
    return {
      code,
      currency: p[1],
      language: p[2],
      timezone: p[3],
      popular: popular.includes(code),
      names,
    };
  })
  .sort((a, b) => a.code.localeCompare(b.code, 'en'));

/* The order each language's "All countries" section renders in.
 *
 * `renderCountry` sorts with `localeCompare(a, b, L.lang())`, which is ICU
 * collation — not code-point order. Dart has no collator, so the order is
 * computed here, once, with the same ICU the prototype used, and carried as a
 * list of codes. The app follows it rather than re-deriving it and getting
 * Urdu subtly wrong. */
const order = {};
for (const lang of LANGS) {
  order[lang] = countries
    .slice()
    .sort((a, b) => a.names[lang].localeCompare(b.names[lang], lang))
    .map((c) => c.code);
}

const missing = countries.filter((c) => c.names.en === c.code);
if (missing.length) {
  process.stderr.write(
    'ICU has no English name for: ' + missing.map((c) => c.code).join(', ') + '\n',
  );
}

mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(
  OUT,
  JSON.stringify(
    {
      source: 'assets/js/data/geo.js + Intl.DisplayNames',
      generator: 'docs/conversion_archive/tool/gen_countries.mjs',
      count: countries.length,
      popular,
      languages: LANGS,
      order,
      countries,
    },
    null,
    2,
  ) + '\n',
);

process.stdout.write(
  `wrote ${countries.length} countries (${popular.length} popular) to ` +
    `assets/data/countries.json\n`,
);
