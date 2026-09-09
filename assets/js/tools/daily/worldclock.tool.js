/* ============================================================
   Lume — worldclock

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'worldclock',

  /* ---------------------------------------------------------
     §80 World clock · public holidays
     --------------------------------------------------------- */
  build: function (c) {
    var zones = c.worldClock();
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = zones.filter(function (z) {
      return !query || (z.city + ' ' + z.tz).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.summaryCard({
        kicker: c.profile.city,
        value: c.clockNow(),
        caption: c.L.timezone() + ' · ' + c.dateLong(new Date())
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('clock.search'), target: 'worldclock', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('clock.cities'), body: shown.length ? UI.rows(shown.map(function (z) {
        return UI.richRow({
          logo: z.cc, logoTone: 'var(--tint-neutral)',
          title: z.city, sub: z.tz,
          meta: [z.offsetLabel, z.dayLabel],
          value: z.time, valueSub: z.period
        });
      })) : UI.emptyState({ icon: 'i-clock', title: c.t('clock.noMatch'), text: c.t('clock.noMatchText') }) }) +
      UI.section({ title: c.t('clock.converter'), body: UI.card(UI.formGrid([
        UI.selectField({ label: c.t('clock.from'), name: 'wc_from', value: c.L.timezone(),
          options: zones.map(function (z) { return { value: z.tz, label: z.city }; }) }),
        UI.selectField({ label: c.t('clock.to'), name: 'wc_to', value: zones[0].tz,
          options: zones.map(function (z) { return { value: z.tz, label: z.city }; }) })
      ])) });
  }
};
