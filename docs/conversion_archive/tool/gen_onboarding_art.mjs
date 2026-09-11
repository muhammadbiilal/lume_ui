/* Lift the onboarding illustrations out of the prototype's template.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9; the
 * assets it writes are production art and stay.
 *
 *   node docs/conversion_archive/tool/gen_onboarding_art.mjs
 *
 * The nine steps carry bespoke SVGs written inline in `onboardingTemplate()`,
 * and they are painted in theme variables — `var(--accent)`, `var(--card)`,
 * `var(--border)`, `var(--violet)`, `var(--sky)`, `var(--text)`,
 * `var(--tint-accent)`. `flutter_svg` cannot resolve a CSS custom property, so
 * a straight copy would render black.
 *
 * Each variable is therefore replaced by a **sentinel colour** — a value that
 * appears nowhere else in the file — and the Flutter side maps the sentinels
 * back to the live theme with a `ColorMapper`. The geometry is copied
 * byte-for-byte; only the colour literals change, and they change to something
 * that is put back at paint time.
 *
 * Deterministic: same template, same output.
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve, join } from 'node:path';

const ROOT = resolve(process.cwd());
const SRC = resolve(ROOT, 'assets/js/screens/onboarding.screen.js');
const OUT = resolve(ROOT, 'assets/images/onboarding');

/* variable → sentinel. Chosen so no real colour in the art collides. */
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

/* Every step section, in order, and the first <svg> inside each. A step may
   have none — the country and city steps are lists. */
const sections = [
  ...src.matchAll(
    /<section class="onb-step[^"]*" data-step="(\d+)">([\s\S]*?)<\/section>/g,
  ),
];
if (sections.length !== 9) {
  throw new Error(`expected 9 steps, found ${sections.length}`);
}

mkdirSync(OUT, { recursive: true });

const written = [];
for (const [, step, body] of sections) {
  /* The first <svg> in a step is not necessarily its illustration: the two
     list steps have none, and the first svg in their markup is the search
     field's 24 × 24 sprite icon. Anything on the sprite's viewBox is an icon,
     not art. */
  const candidates = [...body.matchAll(/<svg[\s\S]*?<\/svg>/g)].map((m) => m[0]);
  const svg = candidates.find((s) => !/viewBox="0 0 24 24"/.test(s));
  if (!svg) {
    written.push({ step: Number(step), file: null });
    continue;
  }

  let art = svg;

  /* The template's own animation classes do not travel: `onb__float`,
     `onb__ring-draw`, `onb__tick-draw` and `onb__pop` are CSS animations on
     the element, and Flutter animates the widget instead. The shapes stay. */
  art = art.replace(/\s+class="[^"]*"/g, '');

  for (const [name, sentinel] of Object.entries(TOKENS)) {
    art = art.split(`var(${name})`).join(sentinel);
  }

  const leftover = /var\(--[a-z0-9-]+\)/i.exec(art);
  if (leftover) {
    throw new Error(`step ${step}: unmapped variable ${leftover[0]}`);
  }

  /* A bare <svg> with no xmlns is fine inline in HTML and is not fine as a
     file. */
  if (!/xmlns=/.test(art)) {
    art = art.replace('<svg', '<svg xmlns="http://www.w3.org/2000/svg"');
  }

  const file = `step_${step}.svg`;
  writeFileSync(join(OUT, file), art + '\n');
  written.push({ step: Number(step), file });
}

writeFileSync(
  join(OUT, 'manifest.json'),
  JSON.stringify(
    {
      source: 'assets/js/screens/onboarding.screen.js',
      generator: 'docs/conversion_archive/tool/gen_onboarding_art.mjs',
      sentinels: TOKENS,
      steps: written,
    },
    null,
    2,
  ) + '\n',
);

process.stdout.write(
  `wrote ${written.filter((w) => w.file).length} illustrations to ` +
    `assets/images/onboarding (steps without art: ` +
    `${written.filter((w) => !w.file).map((w) => w.step).join(', ') || 'none'})\n`,
);
