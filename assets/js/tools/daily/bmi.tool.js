/* ============================================================
   Lume — bmi

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'bmi',

  /* ---------------------------------------------------------
     §48 BMI · §49 Age · date calculator
     --------------------------------------------------------- */
  build: function (c) {
    var b = c.bmi();
    return UI.section({ id: 'inputs', body: UI.card(UI.formGrid([
        UI.field({ label: c.t('bmi.height'), name: 'bmi_h', type: 'number', value: b.f.height, suffix: b.heightUnit }),
        UI.field({ label: c.t('bmi.weight'), name: 'bmi_w', type: 'number', value: b.f.weight, suffix: b.weightUnit })
      ])) }) +
      UI.section({ body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('bmi.your'),
        value: '<span data-bmi-value>' + b.bmi.toFixed(1) + '</span>',
        caption: UI.statusBadge({ label: b.band.label, tone: b.band.tone }),
        aside: UI.progressRing({ value: Math.min(1, b.bmi / 40), centre: c.num(b.bmi, { minimumFractionDigits: 1, maximumFractionDigits: 1 }), label: c.t('bmi.your') })
      }) }) +
      UI.section({ title: c.t('bmi.scale'), body: UI.card(
        '<div class="scale">' + b.bands.map(function (x) {
          return '<span class="scale__seg scale__seg--' + x.tone + (x.on ? ' is-on' : '') + '">' +
            '<i>' + UI.esc(x.label) + '</i><b>' + UI.esc(x.range) + '</b></span>';
        }).join('') + '</div>') }) +
      UI.section({ title: c.t('bmi.healthy'), body: UI.rows([
        UI.compactRow({ icon: 'i-target', label: c.t('bmi.healthyRange'), value: b.healthyRange }),
        UI.compactRow({ icon: 'i-scales', label: c.t('bmi.idealWeight'), value: b.idealWeight })
      ]) }) +
      UI.section({ title: c.t('common.history'), body: UI.card(
        UI.lineChart({ values: b.history, labels: [c.t('range.6m'), c.t('range.3m'), c.t('common.now')], label: c.t('bmi.trend') })) });
  }
};
