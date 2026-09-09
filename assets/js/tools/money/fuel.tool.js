/* ============================================================
   Lume — fuel

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';
import { dirOf } from '../shared/direction.js';

export default {
  id: 'fuel',

  /* ---------------------------------------------------------
     §27 Fuel prices — regional data explorer
     --------------------------------------------------------- */
  build: function (c) {
    var f = D.fuelFor(c.profile.country);
    var main = f.items[0];
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.t('fuel.effective', { date: f.effectiveKey ? c.t(f.effectiveKey) : f.effective }) }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t(main.nk) + ' · ' + main.code,
        value: c.moneyRaw(main.v, f.ccy, 2),
        unit: '/ ' + c.t('unit.' + f.unit),
        caption: UI.delta({ dir: dirOf(main.v - main.prev), text: c.signed(main.v - main.prev) + ' ' + c.t('fuel.sinceLast') }),
        stats: f.items.slice(1, 4).map(function (i) {
          return { value: c.moneyRaw(i.v, f.ccy, 2), label: c.t(i.nk) };
        })
      }) }) +
      UI.section({ title: c.t('fuel.allGrades'), body: UI.table({
        label: c.t('fuel.allGrades'),
        cols: [{ label: c.t('fuel.grade') }, { label: c.t('fuel.previous'), align: 'right' },
               { label: c.t('fuel.current'), align: 'right' }, { label: c.t('common.change'), align: 'right' }],
        rows: f.items.map(function (i) {
          return { cells: [UI.esc(c.t(i.nk)) + ' <i class="cellsub">' + UI.esc(i.code) + '</i>',
                           c.moneyRaw(i.prev, f.ccy, 2), c.moneyRaw(i.v, f.ccy, 2),
                           UI.delta({ dir: dirOf(i.v - i.prev), text: c.signed(i.v - i.prev) })] };
        })
      }) }) +
      UI.section({ title: c.t('fuel.trend'), body: UI.card(
        UI.lineChart({ values: D.walk(731, 24, main.v, 0.01), labels: ['6m', '3m', c.t('common.now')],
          label: c.t('fuel.trend'), caption: c.t('fuel.trendCap') })) }) +
      UI.section({ title: c.t('fuel.related'), body: UI.rows([
        UI.richRow({ icon: 'i-route', title: c.t('f.fuelcost'), sub: c.t('fuel.tripHint'), act: 'tool:fuelcost', chevron: true }),
        UI.richRow({ icon: 'i-car', title: c.t('f.vehicle'), sub: c.t('fuel.vehicleHint'), act: 'tool:vehicle', chevron: true })
      ]) });
  }
};
