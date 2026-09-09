/* ============================================================
   Lume — vaccines

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'vaccines',

  /* ---------------------------------------------------------
     §68 Vaccinations — health timeline
     --------------------------------------------------------- */
  build: function (c) {
    var v = c.vaccines();
    return UI.section({ flush: true, body: '<div class="people">' +
        D.HEALTH_PEOPLE.map(function (p) {
          return '<button class="person' + (p.id === v.selected ? ' is-on' : '') + '" data-act="toolstate:vaccines:person:' + p.id + '">' +
            '<span class="person__avatar">' + UI.esc(p.initials) + '</span>' +
            '<span class="person__name">' + UI.esc(p.name) + '</span></button>';
        }).join('') + '</div>' }) +
      UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('vaccines.schedule'),
        value: v.done + ' <small>/ ' + v.total + '</small>',
        caption: v.due ? c.t('vaccines.dueSoon', { n: v.due }) : c.t('vaccines.upToDate'),
        aside: UI.progressRing({ value: v.done / v.total, centre: Math.round(v.done / v.total * 100) + '%', label: c.t('vaccines.schedule') })
      }) }) +
      UI.section({ title: c.t('vaccines.records'), body: v.list.length
        ? UI.rows(v.list.map(function (x) {
        return UI.richRow({
          icon: 'i-syringe', iconTone: x.state === 'done' ? 'accent' : 'warn',
          title: x.name, sub: x.dose,
          meta: [x.by],
          badge: { label: x.state === 'done' ? c.t('common.done') : c.t('common.due'), tone: x.state === 'done' ? 'ok' : 'warn' },
          value: x.date
        });
          }))
        : UI.emptyState({ icon: 'i-syringe', title: c.t('vaccines.empty.title'),
            text: c.t('vaccines.empty.text'),
            action: { label: c.t('vaccines.add'), act: 'toast:' + c.t('vaccines.adding'), icon: 'i-plus' } }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('vaccines.add'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('vaccines.adding') },
        { label: c.t('vaccines.remind'), icon: 'i-bell', act: 'toast:' + c.t('vaccines.reminded') }]) });
  }
};
