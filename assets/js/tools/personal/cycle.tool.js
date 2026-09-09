/* ============================================================
   Lume — cycle

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'cycle',

  build: function (c) {
    var cy = c.cycle();
    return UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('cycle.day'),
        value: String(cy.day),
        unit: '/ ' + cy.length,
        caption: cy.phaseLabel,
        aside: UI.progressRing({ value: cy.day / cy.length, centre: cy.day + '', label: c.t('cycle.day') })
      }) }) +
      UI.section({ body: c.monthGrid() }) +
      UI.section({ title: c.t('cycle.history'), body: UI.rows(cy.history.map(function (h) {
        return UI.compactRow({ icon: 'i-cycle', label: h.month, sub: h.note, value: h.length + ' ' + c.t('common.days') });
      })) }) +
      UI.section({ body: UI.noteCard({ tone: 'lock', icon: 'i-lock',
        title: c.t('cycle.privacy.title'), text: c.t('cycle.privacy.text') }) });
  }
};
