/* Dump every feature's and category's name in all three languages.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/dump_feature_names.mjs  *     > docs/conversion_archive/measurements/feature_names.json
 *
 * The prototype ships `f.<id>` for every feature in Urdu and Arabic and seeds
 * the English from the catalogue itself. This reads all three out of the live
 * dictionaries, so the ARBs are filled from the design's own translations
 * rather than from a second-hand list. Six features have no Urdu or Arabic
 * entry; those are translated by hand and marked in the ARB.
 */
import { LUME_I18N } from './assets/js/i18n/core.js';
import './assets/js/i18n/tools.js';
import './assets/js/i18n/account.js';
import './assets/js/i18n/crud.js';
import { LUME } from './assets/js/data/catalogue.js';
const D = LUME_I18N.DICTS;
const out = {};
for (const f of LUME.FEATURES) {
  const k = 'f.' + f.id;
  out[f.id] = { en: D.en[k] ?? f.n, ur: D.ur[k] ?? null, ar: D.ar[k] ?? null };
}
for (const c of LUME.CATEGORIES) {
  out['cat:' + c.id] = { en: D.en['cat.' + c.id], ur: D.ur['cat.' + c.id], ar: D.ar['cat.' + c.id] };
  out['catsub:' + c.id] = { en: D.en['cat.' + c.id + 'Sub'], ur: D.ur['cat.' + c.id + 'Sub'], ar: D.ar['cat.' + c.id + 'Sub'] };
}
process.stdout.write(JSON.stringify(out, null, 1));
