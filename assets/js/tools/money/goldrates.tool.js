/* ============================================================
   Lume — goldrates

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';
import { dirOf } from '../shared/direction.js';

export default {
  id: 'goldrates',

  /* ---------------------------------------------------------
     §25.1 Currency & Gold — data explorer
     --------------------------------------------------------- */
  build: function (c) {
    var g = c.metals();
    var query = (c.state('q') || '').trim().toLowerCase();
    var pairs = g.pairs.filter(function (p) {
      return !query || (p.code + ' ' + p.name).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.t('rates.openMarket') }]) }) +
      UI.section({ body: UI.summaryCard({
        tone: 'gold',
        kicker: c.t('rates.gold24'),
        value: c.moneyRaw(g.gold.perTola, g.ccy, 0),
        unit: '/ ' + c.t('unit.tola'),
        caption: UI.delta({ dir: dirOf(g.gold.pct), text: c.signed(g.gold.chg, 0) + '  ' + c.pct(g.gold.pct) }),
        stats: [
          { value: c.moneyRaw(g.gold.perGram, g.ccy, 0), label: c.t('unit.gram') },
          { value: c.moneyRaw(g.gold.perOunce, 'USD', 0), label: c.t('unit.ounce') },
          { value: c.moneyRaw(g.silver.perTola, g.ccy, 0), label: c.t('rates.silverTola') }
        ]
      }) }) +
      UI.section({ title: c.t('rates.metals'), body: UI.table({
        label: c.t('rates.metals'),
        cols: [{ label: c.t('rates.metal') }, { label: c.t('unit.gram'), align: 'right' },
               { label: c.t('unit.tola'), align: 'right' }, { label: c.t('common.change'), align: 'right' }],
        rows: [
          { cells: [c.t('rates.gold24'), c.moneyRaw(g.gold.perGram, g.ccy, 0), c.moneyRaw(g.gold.perTola, g.ccy, 0),
                    UI.delta({ dir: dirOf(g.gold.pct), text: c.pct(g.gold.pct) })] },
          { cells: [c.t('rates.gold22'), c.moneyRaw(g.gold.perGram * 0.916, g.ccy, 0), c.moneyRaw(g.gold.perTola * 0.916, g.ccy, 0),
                    UI.delta({ dir: dirOf(g.gold.pct), text: c.pct(g.gold.pct) })] },
          { cells: [c.t('rates.silver'), c.moneyRaw(g.silver.perGram, g.ccy, 0), c.moneyRaw(g.silver.perTola, g.ccy, 0),
                    UI.delta({ dir: dirOf(g.silver.pct), text: c.pct(g.silver.pct) })] }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('rates.search'), target: 'goldrates', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('rates.currencies'), body: pairs.length ? UI.rows(pairs.map(function (p) {
        return UI.richRow({
          logo: p.flag, logoTone: 'var(--tint-neutral)',
          title: p.code, sub: p.name,
          meta: [c.t('rates.buy') + ' ' + c.num(p.buy, { maximumFractionDigits: 2 }),
                 c.t('rates.sell') + ' ' + c.num(p.sell, { maximumFractionDigits: 2 })],
          spark: UI.sparkline(D.walk(Math.round(p.sell * 10), 18, p.sell, 0.008), { tone: dirOf(p.pct) }),
          value: c.num(p.sell, { maximumFractionDigits: 2 }),
          delta: { dir: dirOf(p.pct), text: c.pct(p.pct) }
        });
      })) : UI.emptyState({ icon: 'i-currency', title: c.t('rates.noMatch'),
        text: c.t('rates.noMatchText') }) }) +
      UI.section({ title: c.t('rates.history'), body: UI.card(
        UI.lineChart({ values: D.walk(9001, 30, g.gold.perTola, 0.01), labels: ['30d', '15d', c.t('common.today')],
          label: c.t('rates.goldHistory'), caption: c.t('rates.goldHistoryCap') })) }) +
      UI.section({ title: c.t('rates.converter'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('rates.weight'), name: 'g_weight', type: 'number', value: 10, suffix: c.t('unit.gram') }),
        UI.field({ label: c.t('rates.worth'), name: 'g_value', value: c.moneyRaw(g.gold.perGram * 10, g.ccy, 0) })
      ])) });
  }
};
