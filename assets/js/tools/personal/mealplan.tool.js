/* ============================================================
   Lume — mealplan

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'mealplan',

  /* ---------------------------------------------------------
     §64 Meal planner · §65 Alarms · §66 Learning · §70 Play
     --------------------------------------------------------- */
  build: function (c) {
    var m = c.mealPlan();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('meal.thisWeek'),
        value: m.planned + ' <small>/ ' + m.slots + '</small>',
        caption: c.t('meal.planned'),
        stats: [
          { value: c.num(m.kcal), label: c.t('meal.avgKcal') },
          { value: String(m.shopItems), label: c.t('meal.shopItems') },
          { value: c.money(m.cost), label: c.t('meal.estCost') }
        ]
      }) }) +
      UI.section({ title: c.t('meal.calories'), body: UI.card(
        UI.barChart({ values: m.kcalByDay, labels: c.weekLabels(), highlight: 0,
          label: c.t('meal.calories'), caption: c.t('meal.caloriesCap', { n: c.num(m.kcal) }) })) }) +
      UI.section({ title: c.t('meal.week'), body: UI.rows(m.days.map(function (d) {
        return UI.expandRow({
          open: d.today,
          head: '<span class="xrow__title">' + UI.esc(d.label) + '</span>' +
                '<span class="xrow__value">' + UI.esc(d.summary) + '</span>',
          body: UI.rows(d.meals.map(function (x) {
            return UI.compactRow({ icon: x.icon, label: x.slot, sub: x.recipe, value: x.kcal + ' ' + c.t('unit.kcal') });
          }), { flat: true })
        });
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('meal.toShopping'), tone: 'accent', icon: 'i-cart', act: 'tool:shopping' },
        { label: c.t('meal.browse'), icon: 'i-utensils', act: 'tool:recipes' }]) });
  }
};
