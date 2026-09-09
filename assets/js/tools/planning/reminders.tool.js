/* ============================================================
   Lume — reminders

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'reminders',

  build: function (c) {
    var r = c.reminders();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('reminders.today'), value: String(r.today.length),
        caption: r.next ? c.t('reminders.next', { label: r.next.label, at: r.next.at }) : c.t('reminders.none') }) }) +
      UI.section({ title: c.t('reminders.upcoming'), body: UI.timeline(r.all.map(function (x) {
        return { time: x.at, title: x.label, sub: x.repeat, state: x.state };
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('reminders.add'), act: 'toast:' + c.t('reminders.adding') });
  }
};
