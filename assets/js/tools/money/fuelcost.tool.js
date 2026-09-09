/* ============================================================
   Lume — fuelcost

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'fuelcost',

  /* ---------------------------------------------------------
     §28 Fuel cost — calculator
     --------------------------------------------------------- */
  build: function (c) {
    var fc = c.fuelCost();
    return UI.section({ id: 'inputs', title: c.t('tool.inputs'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('fuelcost.distance'), name: 'fc_dist', type: 'number', value: fc.f.dist,
          suffix: c.L.unitSystem() === 'imperial' ? c.t('unit.mi') : c.t('unit.km') }),
        UI.field({ label: c.t('fuelcost.economy'), name: 'fc_econ', type: 'number', value: fc.f.econ,
          suffix: fc.econUnit }),
        UI.field({ label: c.t('fuelcost.price'), name: 'fc_price', type: 'number', value: fc.f.price,
          prefix: fc.ccy, hint: c.t('fuelcost.priceHint') }),
        UI.field({ label: c.t('fuelcost.people'), name: 'fc_people', type: 'number', value: fc.f.people })
      ])) }) +
      UI.section({ id: 'result', body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('fuelcost.total'),
        value: '<span data-fc-total>' + c.moneyRaw(fc.total, fc.ccy, 0) + '</span>',
        caption: c.t('fuelcost.forTrip', { d: fc.distLabel }),
        stats: [
          { value: '<span data-fc-fuel>' + fc.fuelUsed + '</span>', label: c.t('fuelcost.used') },
          { value: '<span data-fc-per>' + c.moneyRaw(fc.perPerson, fc.ccy, 0) + '</span>', label: c.t('fuelcost.perPerson') },
          { value: c.moneyRaw(fc.perUnit, fc.ccy, 2), label: fc.perUnitLabel }
        ]
      }) }) +
      UI.section({ title: c.t('fuelcost.compare'), body: UI.table({
        label: c.t('fuelcost.compare'),
        cols: [{ label: c.t('fuelcost.scenario') }, { label: c.t('fuelcost.consumption'), align: 'right' },
               { label: c.t('fuelcost.cost'), align: 'right' }],
        rows: fc.scenarios.map(function (s) {
          return { cells: [UI.esc(s.label), s.fuel, c.moneyRaw(s.cost, fc.ccy, 0)] };
        })
      }) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(fc.history.map(function (h) {
        return UI.compactRow({ icon: 'i-route', label: h.label, sub: h.when, value: c.moneyRaw(h.cost, fc.ccy, 0) });
      })) });
  }
};
