/* ============================================================
   Lume — birthdays

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'birthdays',

  build: function (c) {
    var b = c.birthdays();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('birthdays.next'),
        value: b.next.name,
        caption: c.t('common.inDays', { n: b.next.days }) + ' · ' + b.next.date,
        stats: [
          { value: String(b.list.length), label: c.t('birthdays.tracked') },
          { value: String(b.thisMonth), label: c.t('birthdays.thisMonth') },
          { value: b.next.turning + '', label: c.t('birthdays.turning') }
        ]
      }) }) +
      UI.section({ title: c.t('birthdays.upcoming'), body: UI.rows(b.list.map(function (x) {
        return UI.richRow({
          logo: x.initials, logoTone: 'var(--tone-' + x.tone + ')',
          title: x.name, sub: x.kind,
          meta: [x.date, c.t('birthdays.turns', { n: x.turning })],
          value: c.t('common.inDays', { n: x.days }),
          act: 'toast:' + x.name, chevron: true
        });
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('birthdays.add'), act: 'toast:' + c.t('birthdays.adding') });
  }
};
