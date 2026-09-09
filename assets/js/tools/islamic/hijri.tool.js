/* ============================================================
   Lume — hijri

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'hijri',

  /* ---------------------------------------------------------
     24.14 Islamic Calendar
     --------------------------------------------------------- */
  build: function (c) {
    var h = c.hijri();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('hijri.today'),
        value: h.day + ' ' + UI.esc(h.month),
        unit: h.year + ' AH',
        caption: c.dateLong(new Date())
      }) }) +
      UI.section({ body: c.monthGrid() }) +
      UI.section({ title: c.t('hijri.events'), body: UI.rows(D.ISLAMIC_EVENTS.map(function (e) {
        return UI.richRow({ icon: 'i-moon-star', iconTone: 'accent', title: e.name, sub: e.hijri,
          meta: [e.greg], value: c.t('common.inDays', { n: e.days }) });
      })) }) +
      UI.section({ title: c.t('hijri.convert'), body: UI.card(
        UI.formGrid([
          UI.field({ label: c.t('hijri.gregorian'), name: 'greg', type: 'date', value: c.isoToday() }),
          UI.field({ label: c.t('hijri.hijri'), name: 'hij', value: h.day + ' ' + h.month + ' ' + h.year })
        ])) }) +
      UI.section({ title: c.t('hijri.months'), body: UI.rows(D.HIJRI_MONTHS.map(function (m, i) {
        return UI.compactRow({ label: m, value: String(i + 1), chevron: false });
      }), { flat: true }) });
  }
};
