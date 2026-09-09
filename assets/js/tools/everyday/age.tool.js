/* ============================================================
   Lume — age

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'age',

  build: function (c) {
    var a = c.age();
    return UI.section({ id: 'inputs', body: UI.card(UI.formGrid([
        UI.field({ label: c.t('age.dob'), name: 'age_dob', type: 'date', value: a.f.dob, wide: true })
      ])) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('age.youAre'),
        value: '<span data-age-y>' + a.years + '</span>',
        unit: c.t('common.years'),
        caption: c.t('age.exact', { m: a.months, d: a.days }),
        stats: [
          { value: c.num(a.totalDays), label: c.t('age.days') },
          { value: c.num(a.totalWeeks), label: c.t('age.weeks') },
          { value: c.num(a.totalHours), label: c.t('age.hours') }
        ]
      }) }) +
      UI.section({ title: c.t('age.nextBirthday'), body: UI.card(
        UI.meterRow({ label: a.nextDate, value: c.t('common.inDays', { n: a.untilNext }), pct: 1 - a.untilNext / 365 })) }) +
      UI.section({ title: c.t('age.milestones'), body: UI.rows(a.milestones.map(function (m) {
        return UI.compactRow({ icon: 'i-star', label: m.label, value: m.when });
      })) });
  }
};
