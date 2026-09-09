/* ============================================================
   Lume — timer

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { clockScreen } from '../shared/clock.js';

export default {
  id: 'timer',

  build: function (c) {
    var s = c.timer();
    return clockScreen(c, { display: s.display, sub: c.t('timer.hint'),
      primary: c.t('common.start'), primaryAct: 'clock:timer:start', resetAct: 'clock:timer:reset' }) +
      UI.section({ title: c.t('timer.presets'), body: '<div class="chips">' +
        s.presets.map(function (p) {
          return '<button class="chip" data-act="clock:timer:set:' + p.secs + '">' + UI.esc(p.label) + '</button>';
        }).join('') + '</div>' }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(s.history.map(function (h) {
        return UI.compactRow({ icon: 'i-timer', label: h.label, value: h.when });
      })) });
  }
};
