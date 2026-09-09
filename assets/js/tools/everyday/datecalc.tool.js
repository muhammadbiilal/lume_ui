/* ============================================================
   Lume — datecalc

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'datecalc',

  build: function (c) {
    var d = c.dateCalc();
    return UI.section({ body: UI.segmented({ id: 'datemode', label: c.t('datecalc.mode'), items: [
        { value: 'diff', label: c.t('datecalc.difference'), on: d.mode === 'diff', act: 'toolstate:datecalc:mode:diff' },
        { value: 'add', label: c.t('datecalc.addSubtract'), on: d.mode === 'add', act: 'toolstate:datecalc:mode:add' }
      ] }) }) +
      UI.section({ body: UI.card(d.mode === 'diff'
        ? UI.formGrid([
            UI.field({ label: c.t('datecalc.from'), name: 'dc_from', type: 'date', value: d.f.from }),
            UI.field({ label: c.t('datecalc.to'), name: 'dc_to', type: 'date', value: d.f.to })
          ])
        : UI.formGrid([
            UI.field({ label: c.t('datecalc.start'), name: 'dc_start', type: 'date', value: d.f.from }),
            UI.field({ label: c.t('datecalc.days'), name: 'dc_days', type: 'number', value: d.f.days })
          ])) }) +
      UI.section({ body: UI.summaryCard({
        kicker: d.mode === 'diff' ? c.t('datecalc.between') : c.t('datecalc.result'),
        value: '<span data-dc-out>' + d.headline + '</span>',
        caption: d.caption,
        stats: d.stats
      }) }) +
      UI.section({ title: c.t('datecalc.business'), body: UI.rows([
        UI.compactRow({ icon: 'i-calendar', label: c.t('datecalc.weekdays'), value: c.num(d.weekdays) }),
        UI.compactRow({ icon: 'i-sun', label: c.t('datecalc.weekends'), value: c.num(d.weekends) }),
        UI.compactRow({ icon: 'i-star', label: c.t('datecalc.holidays'), value: c.num(d.holidays) })
      ]) });
  }
};
