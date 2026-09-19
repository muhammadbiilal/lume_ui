// Writes scripts/data/cldr_country_zones.json: the IANA zones CLDR lists for
// every country in assets/data/countries.json, as the running Node's ICU
// reports them (`Intl.Locale.prototype.getTimeZones`).
//
//   node scripts/cldr_country_zones.mjs
//
// Input to scripts/generate_zone_aliases.dart, which canonicalises the
// identifiers against the pinned tz data and groups them into civil times.
// Run only as part of a deliberate update (WORLD_CLOCK_TIMEZONE.md), and
// review the diff: the ICU and CLDR versions are recorded in the output.

import { readFileSync, writeFileSync } from 'node:fs';

const table = JSON.parse(readFileSync('assets/data/countries.json', 'utf8'));
const zones = {};
for (const c of table.countries) {
  const l = new Intl.Locale(`und-${c.code}`);
  const list = (l.getTimeZones ? l.getTimeZones() : l.timeZones) ?? [];
  zones[c.code] = [...list].sort();
}
const out = {
  source: 'CLDR via ICU (Intl.Locale.getTimeZones)',
  icu: process.versions.icu,
  cldr: process.versions.cldr,
  node: process.version,
  zones,
};
writeFileSync(
  'scripts/data/cldr_country_zones.json',
  JSON.stringify(out, null, 1) + '\n',
);
const empty = Object.keys(zones).filter((k) => zones[k].length === 0);
console.log(`wrote ${Object.keys(zones).length} countries; none listed: ${empty.join(',') || '-'}`);
