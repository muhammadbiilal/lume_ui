/* ============================================================
   Lume — calendar

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'calendar',

  /* ---------------------------------------------------------
     §39.1 Calendar — calendar + agenda
     --------------------------------------------------------- */
  build: function (c) {
    var cal = c.calendar();
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country) },
        { label: c.L.timezone() }
      ].concat(c.profile.islamic ? [{ label: c.hijri().label }] : [])) }) +
      UI.section({ body: UI.segmented({ id: 'calview', label: c.t('calendar.view'), items: [
        { value: 'month', label: c.t('calendar.month'), on: cal.view === 'month', act: 'toolstate:calendar:view:month' },
        { value: 'week', label: c.t('calendar.week'), on: cal.view === 'week', act: 'toolstate:calendar:view:week' },
        { value: 'day', label: c.t('calendar.day'), on: cal.view === 'day', act: 'toolstate:calendar:view:day' }
      ] }) }) +
      UI.section({ body: c.monthGrid() }) +
      UI.section({ title: c.t('calendar.agenda'), body: UI.timeline(cal.agenda.map(function (a) {
        return { time: a.time, title: a.title, sub: a.sub, state: a.state, icon: a.icon };
      })) }) +
      UI.section({ title: c.t('calendar.holidays'), body: UI.rows(cal.holidays.map(function (h) {
        return UI.compactRow({ icon: 'i-star', label: h.name, sub: h.kind, value: h.date });
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('calendar.add'), act: 'toast:' + c.t('calendar.adding') });
  }
};
