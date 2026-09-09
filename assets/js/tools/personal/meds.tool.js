/* ============================================================
   Lume — meds

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'meds',

  /* ---------------------------------------------------------
     §79 Medication reminders — schedule + adherence
     --------------------------------------------------------- */
  build: function (c) {
    var m = c.meds();
    return UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('meds.nextDose'),
        value: m.next.name,
        unit: m.next.at,
        caption: m.next.dose,
        aside: UI.progressRing({ value: m.adherence, centre: Math.round(m.adherence * 100) + '%', label: c.t('meds.adherence') })
      }) }) +
      UI.section({ title: c.t('meds.today'), body: UI.timeline(m.today.map(function (d) {
        return { time: d.at, title: d.name, sub: d.dose, state: d.state,
          value: d.state === 'done' ? UI.statusBadge({ label: c.t('common.taken'), tone: 'ok' })
                                    : UI.statusBadge({ label: c.t('common.due'), tone: 'info' }) };
      })) }) +
      UI.section({ title: c.t('meds.active'), body: UI.rows(D.MEDS.map(function (x) {
        return UI.richRow({
          icon: 'i-pill', iconTone: 'accent',
          title: x.name, sub: x.dose,
          meta: [x.when, c.t('meds.left', { a: x.left, b: x.of })],
          value: x.adherence !== null ? Math.round(x.adherence * 100) + '%' : '—',
          valueSub: c.t('meds.adherence')
        }) + '<div class="rowmeter">' + UI.progressBar({ value: x.left / x.of, label: x.name }) + '</div>';
      })) }) +
      (function () {
        var low = D.MEDS.filter(function (x) { return x.left / x.of < 0.5; });
        if (!low.length) return '';
        return UI.section({ title: c.t('meds.refill'), body: UI.rows(low.map(function (x) {
          return UI.compactRow({ icon: 'i-alert', label: x.name, sub: c.t('meds.runningLow'),
            value: c.t('meds.left', { a: x.left, b: x.of }) });
        })) });
      })();
  }
};
