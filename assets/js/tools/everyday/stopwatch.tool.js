/* ============================================================
   Lume — stopwatch

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { clockScreen } from '../shared/clock.js';

export default {
  id: 'stopwatch',

  build: function (c) {
    var s = c.stopwatch();
    return clockScreen(c, { display: s.display, sub: c.t('stopwatch.hint'),
      primary: c.t('common.start'), primaryAct: 'clock:stopwatch:start', resetAct: 'clock:stopwatch:reset' }) +
      UI.section({ title: c.t('stopwatch.laps'), body: s.laps.length
        ? UI.rows(s.laps.map(function (l, i) {
            return UI.compactRow({ label: c.t('stopwatch.lap', { n: i + 1 }), value: l });
          }))
        : UI.emptyState({ icon: 'i-stopwatch', title: c.t('stopwatch.empty.title'), text: c.t('stopwatch.empty.text') }) });
  }
};
