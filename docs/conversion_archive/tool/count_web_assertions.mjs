/* The canonical count of the web oracle's assertions.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/count_web_assertions.mjs
 *
 * The ten suites print one line per assertion, and **they do not all print it
 * the same way**: nine write `  ok   <text>` and `tests/verify.js` writes
 * `  ok: <text>`. A count that matches `ok` followed by whitespace silently
 * drops `verify.js` whole — twelve assertions — and that is exactly how the
 * F5A correction report came to say 703 against an earlier 715. Nothing had
 * been deleted, skipped, or lost; the grep was wrong.
 *
 * So the count lives here rather than in a shell one-liner in somebody's
 * notes. One pattern, stated once, applied to every suite, printed per suite
 * as well as in total — because a per-suite table is what makes the next
 * discrepancy legible in one glance instead of an afternoon.
 *
 *   --json   machine-readable, for a report
 *
 * Exits non-zero if any suite fails or prints no assertions at all.
 */
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';

/* `npm test`'s own order, which is the order a failure is hit in. */
const SUITES = [
  'architecture',
  'verify',
  'interact',
  'controls',
  'regress',
  'notify',
  'account',
  'auth',
  'design',
  'crud',
];

/* An assertion line from either dialect: `  ok   x` or `  ok: x`. Anchored, so
   the word "ok" inside an assertion's own text cannot be counted. */
const OK = /^\s+ok(\s|:)/;

/* A suite that fails says so in one of these. The `-i` that matched "failed"
   inside an assertion's text is the other half of the 703 mistake, so this is
   anchored and case-sensitive. */
const BAD = /^\s+(not ok|FAIL)\b/;

const json = process.argv.includes('--json');
const root = resolve(process.cwd());

const rows = [];
let total = 0;
let failed = false;

for (const suite of SUITES) {
  const run = spawnSync(process.execPath, [`tests/${suite}.js`], {
    cwd: root,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
  });
  const lines = `${run.stdout ?? ''}\n${run.stderr ?? ''}`.split(/\r?\n/);
  const ok = lines.filter((l) => OK.test(l)).length;
  const bad = lines.filter((l) => BAD.test(l)).length;
  const passed = run.status === 0 && bad === 0 && ok > 0;
  if (!passed) failed = true;
  total += ok;
  rows.push({ suite, assertions: ok, failures: bad, exit: run.status, passed });
}

if (json) {
  process.stdout.write(
    `${JSON.stringify({ suites: rows.length, total, rows }, null, 2)}\n`,
  );
} else {
  const w = Math.max(...SUITES.map((s) => s.length));
  for (const r of rows) {
    process.stdout.write(
      `  ${r.suite.padEnd(w)}  ${String(r.assertions).padStart(4)}` +
        `${r.passed ? '' : `   FAILED (exit ${r.exit}, ${r.failures} bad)`}\n`,
    );
  }
  process.stdout.write(`  ${'total'.padEnd(w)}  ${String(total).padStart(4)}`);
  process.stdout.write(`   across ${rows.length} suites\n`);
}

process.exit(failed ? 1 : 0);
