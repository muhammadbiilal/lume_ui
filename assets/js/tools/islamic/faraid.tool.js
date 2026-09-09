/* ============================================================
   Lume — faraid

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'faraid',

  /* ---------------------------------------------------------
     24.17 Faraid — guided calculator, progressive steps
     --------------------------------------------------------- */
  build: function (c) {
    var fr = c.faraid();
    return UI.section({ body: UI.noteCard({ icon: 'i-info', tone: 'info',
        title: c.t('faraid.note.title'), text: c.t('faraid.note.text') }) }) +
      UI.section({ body: '<ol class="steps">' +
        [c.t('faraid.step.estate'), c.t('faraid.step.debts'), c.t('faraid.step.heirs'), c.t('faraid.step.shares')]
          .map(function (label, i) {
            return '<li class="steps__item' + (i === fr.step ? ' is-on' : i < fr.step ? ' is-done' : '') + '">' +
              '<b>' + (i + 1) + '</b><span>' + UI.esc(label) + '</span></li>';
          }).join('') + '</ol>' }) +
      UI.section({ title: c.t('faraid.estate'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('faraid.gross'), name: 'fa_gross', type: 'number', value: fr.gross, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('faraid.debts'), name: 'fa_debts', type: 'number', value: fr.debts, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('faraid.bequest'), name: 'fa_bequest', type: 'number', value: fr.bequest, prefix: c.L.currencyCode(),
          hint: c.t('faraid.bequestHint') })
      ])) }) +
      UI.section({ title: c.t('faraid.heirs'), body: UI.rows(fr.heirs.map(function (h) {
        return UI.richRow({ icon: 'i-users', title: h.label, sub: h.rule,
          value: UI.stepper({ name: 'heir_' + h.id, value: h.n, label: h.label }) });
      })) }) +
      UI.section({ title: c.t('faraid.distribution'), body: UI.card(
        UI.donut({
          label: c.t('faraid.distribution'),
          centre: c.moneyRaw(fr.net, c.L.currencyCode(), 0),
          centreSub: c.t('faraid.net'),
          slices: fr.shares.map(function (s) {
            return { label: s.label, value: s.amount, color: s.color, display: s.fraction };
          })
        })) }) +
      UI.section({ title: c.t('faraid.explain'), body: UI.rows(fr.shares.map(function (s) {
        return UI.expandRow({
          head: '<span class="xrow__title">' + UI.esc(s.label) + '</span>' +
                '<span class="xrow__value">' + UI.esc(s.fraction) + ' · ' + c.moneyRaw(s.amount, c.L.currencyCode(), 0) + '</span>',
          body: '<p>' + UI.esc(s.reason) + '</p>'
        });
      })) });
  }
};
