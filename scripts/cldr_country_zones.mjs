// Writes scripts/data/cldr_country_zones.json: the IANA zones CLDR lists for
// every country in assets/data/countries.json, and each zone's localized
// location label in the app's languages — both as the running Node's ICU
// reports them (`Intl.Locale.prototype.getTimeZones`, and the generic
// location format of `Intl.DateTimeFormat`).
//
//   node scripts/cldr_country_zones.mjs
//
// Input to scripts/generate_zone_aliases.dart, which canonicalises the
// identifiers against the pinned tz data. Run only as part of a deliberate
// update (WORLD_CLOCK_TIMEZONE.md), and review the diff: the ICU and CLDR
// versions are recorded in the output.
//
// A label is the `{0}` of CLDR's generic location format ("{0} Time",
// "{0} وقت", "توقيت {0}"): the country's name for a zone that is its
// country's only or primary one, else the zone's exemplar city — CLDR's own
// localized text, never a translation made here. Where ICU answers a zone
// with an abbreviation instead ("ET", "GMT"), the next English variant is
// asked; a zone that is its country's only one then takes the country's
// CLDR name; anything else has no label, and the app shows the identifier.

import { readFileSync, writeFileSync } from 'node:fs';

const table = JSON.parse(readFileSync('assets/data/countries.json', 'utf8'));
const zones = {};
for (const c of table.countries) {
  const l = new Intl.Locale(`und-${c.code}`);
  const list = (l.getTimeZones ? l.getTimeZones() : l.timeZones) ?? [];
  zones[c.code] = [...list].sort();
}

// Every identifier the pinned tz data holds, and every one CLDR lists.
const tzdb = readFileSync('lib/core/time/lume_zone_aliases.dart', 'utf8');
const ids = new Set(
  [...tzdb.matchAll(/^ {2}'([^']+)'[,:]/gm)].map((m) => m[1]),
);
for (const list of Object.values(zones)) for (const z of list) ids.add(z);

const languages = {
  en: { tags: ['en-001', 'en-IN', 'en'], format: /^(.+) Time$/ },
  ur: { tags: ['ur'], format: /^(.+) وقت$/ },
  ar: { tags: ['ar'], format: /^توقيت (.+)$/ },
};
const at = new Date(Date.UTC(2026, 0, 15));
function location(tag, id) {
  try {
    return new Intl.DateTimeFormat(tag, { timeZone: id, timeZoneName: 'shortGeneric' })
      .formatToParts(at)
      .find((p) => p.type === 'timeZoneName').value;
  } catch {
    return null;
  }
}
// The country of a zone that is that country's only one.
const soleCountry = {};
const listedIn = {};
for (const [code, list] of Object.entries(zones)) {
  for (const z of list) (listedIn[z] ??= []).push(code);
}
for (const [z, codes] of Object.entries(listedIn)) {
  if (codes.length === 1 && zones[codes[0]].length === 1) soleCountry[z] = codes[0];
}

// Each language's generic location pattern ("{0} Time"), read off one
// zone's formatted name rather than written here.
const formats = {};
for (const [lang, { tags }] of Object.entries(languages)) {
  const country = new Intl.DisplayNames([lang], { type: 'region' }).of('PK');
  const whole = location(tags[0], 'Asia/Karachi');
  if (!whole.includes(country)) throw new Error(`no pattern for ${lang}: ${whole}`);
  formats[lang] = whole.replace(country, '{0}');
}

const labels = {};
const unlabelled = {};
for (const [lang, { tags, format }] of Object.entries(languages)) {
  const names = new Intl.DisplayNames([lang], { type: 'region' });
  labels[lang] = {};
  unlabelled[lang] = [];
  for (const id of [...ids].sort()) {
    let label = null;
    for (const tag of tags) {
      const m = format.exec(location(tag, id) ?? '');
      if (m) {
        label = m[1];
        break;
      }
    }
    if (label == null && soleCountry[id]) label = names.of(soleCountry[id]);
    if (label == null) unlabelled[lang].push(id);
    else labels[lang][id] = label;
  }
}

const out = {
  source: 'CLDR via ICU (Intl.Locale.getTimeZones; generic location format)',
  icu: process.versions.icu,
  cldr: process.versions.cldr,
  node: process.version,
  zones,
  formats,
  labels,
  unlabelled,
};
writeFileSync(
  'scripts/data/cldr_country_zones.json',
  JSON.stringify(out, null, 1) + '\n',
);
const empty = Object.keys(zones).filter((k) => zones[k].length === 0);
console.log(`wrote ${Object.keys(zones).length} countries; none listed: ${empty.join(',') || '-'}`);
for (const lang of Object.keys(languages)) {
  console.log(`${lang}: ${Object.keys(labels[lang]).length} labels, ${unlabelled[lang].length} without`);
}
