/* ============================================================
   Lume — loadshed

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'loadshed',

  /* ---------------------------------------------------------
     §41 Loadshedding — schedule dashboard
     --------------------------------------------------------- */
  build: function (c) {
    var ls = c.loadshed();
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: ls.area, act: 'sheet:personalise' },
        { label: ls.provider }]) }) +
      UI.section({ body: UI.summaryCard({
        tone: ls.now ? 'warn' : 'accent',
        kicker: ls.now ? c.t('loadshed.currentlyOff') : c.t('loadshed.currentlyOn'),
        value: ls.now ? ls.endsIn : ls.nextIn,
        caption: ls.now ? c.t('loadshed.powerBack', { time: ls.slot.to })
                        : c.t('loadshed.nextOutage', { from: ls.slot.from, to: ls.slot.to }),
        stats: [
          { value: ls.hoursToday + 'h', label: c.t('loadshed.today') },
          { value: ls.slots.length + '', label: c.t('loadshed.slots') },
          { value: ls.reliability + '%', label: c.t('loadshed.reliability') }
        ]
      }) }) +
      UI.section({ title: c.t('loadshed.schedule'), body: UI.timeline(ls.slots.map(function (s) {
        return { time: s.from, title: c.t('loadshed.outage'), sub: c.t('loadshed.until', { time: s.to }),
          value: s.duration, state: s.state, icon: s.state === 'now' ? 'i-bolt' : null };
      })) }) +
      UI.section({ title: c.t('loadshed.week'), body: UI.card(
        UI.barChart({ values: ls.week, labels: c.weekLabels(), highlight: ls.todayIndex,
          label: c.t('loadshed.week'), caption: c.t('loadshed.weekCap') })) }) +
      UI.section({ body: UI.rows([
        UI.compactRow({ icon: 'i-bell', label: c.t('loadshed.notify'), value: c.t('common.on'), act: 'toast:' + c.t('loadshed.notifyOn') }),
        UI.compactRow({ icon: 'i-receipt', label: c.t('f.bills'), value: c.t('loadshed.billHint'), act: 'tool:bills' })
      ]) });
  }
};
