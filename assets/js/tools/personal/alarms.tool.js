/* ============================================================
   Lume — alarms

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'alarms',

  build: function (c) {
    var a = c.alarms();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('alarms.next'), value: a.next ? a.next.at : '—',
        caption: a.next ? a.next.label + ' · ' + a.next.inLabel : c.t('alarms.none') }) }) +
      UI.section({ title: c.t('alarms.all'), body: UI.rows(a.list.map(function (x) {
        return UI.richRow({
          icon: 'i-alarm', iconTone: x.on ? 'accent' : null,
          title: x.at, sub: x.label,
          meta: [x.repeat],
          value: '<span class="switch' + (x.on ? ' is-on' : '') + '"><i class="switch__knob"></i></span>',
          act: 'alarmtoggle:' + x.id
        });
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('alarms.add'), act: 'toast:' + c.t('alarms.adding') });
  }
};
