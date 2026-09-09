/* ============================================================
   Lume — focus

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { clockScreen } from '../shared/clock.js';

export default {
  id: 'focus',

  build: function (c) {
    var s = c.focus();
    return clockScreen(c, { display: s.display, sub: c.t('focus.session', { n: s.session, of: s.of }),
      primary: c.t('focus.start'), primaryAct: 'clock:focus:start', resetAct: 'clock:focus:reset' }) +
      UI.section({ body: UI.metrics([
        { icon: 'i-timer', value: s.todayMins + '', label: c.t('focus.todayMins') },
        { icon: 'i-flame', value: String(s.streak), label: c.t('focus.streak') },
        { icon: 'i-check', value: String(s.sessions), label: c.t('focus.sessions') }
      ], 3) }) +
      UI.section({ title: c.t('focus.week'), body: UI.card(
        UI.barChart({ values: s.week, labels: c.weekLabels(), highlight: 6, label: c.t('focus.week') })) });
  }
};
