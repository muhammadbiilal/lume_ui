/* ============================================================
   Lume — aqi

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'aqi',

  /* ---------------------------------------------------------
     §80 Air quality explorer
     --------------------------------------------------------- */
  build: function (c) {
    var aq = D.aqiFor(c.profile.country);
    return UI.section({ flush: true, body: UI.contextBar([{ icon: 'i-pin', label: c.profile.city }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('aqi.index'),
        value: String(aq.value),
        caption: UI.statusBadge({ label: c.t(aq.band.key + '.label'), tone: aq.band.tone }),
        aside: UI.progressRing({ value: Math.min(1, aq.value / 300), centre: String(aq.value), label: c.t('aqi.index') })
      }) }) +
      UI.section({ body: UI.noteCard({ tone: aq.band.tone === 'ok' ? 'ok' : 'warn', icon: 'i-info',
        title: c.t('aqi.advice'), text: c.t(aq.band.key + '.advice') }) }) +
      UI.section({ title: c.t('aqi.pollutants'), body: UI.rows(aq.parts.map(function (p) {
        return UI.richRow({ icon: 'i-wind', title: p.n, sub: c.t('aqi.estimated'),
          value: String(p.v), valueSub: p.unit });
      })) }) +
      UI.section({ title: c.t('aqi.trend'), body: UI.card(
        UI.lineChart({ values: D.walk(aq.value, 24, aq.value, 0.08), labels: [c.t('range.24h'), c.t('range.12h'), c.t('common.now')],
          label: c.t('aqi.trend') })) });
  }
};
