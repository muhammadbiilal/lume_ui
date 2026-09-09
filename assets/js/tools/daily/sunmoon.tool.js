/* ============================================================
   Lume — sunmoon

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'sunmoon',

  /* ---------------------------------------------------------
     §80 Sun & moon
     --------------------------------------------------------- */
  build: function (c) {
    var sun = c.sunTimes();
    return UI.section({ flush: true, body: UI.contextBar([{ icon: 'i-pin', label: c.profile.city }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('sun.daylength'),
        value: sun.dayLength,
        caption: c.t('sun.range', { a: c.time(sun.sunrise.h, sun.sunrise.m), b: c.time(sun.sunset.h, sun.sunset.m) }),
        stats: [
          { value: sun.moonPhase, label: c.t('sun.moon') },
          { value: c.num(sun.moonIllum) + '%', label: c.t('sun.illumination') },
          { value: sun.solarNoon, label: c.t('sun.noon') }
        ]
      }) }) +
      UI.section({ title: c.t('sun.today'), body: UI.timeline(sun.events.map(function (e) {
        return { time: e.time, title: e.label, sub: e.note, state: e.state, icon: e.icon };
      })) });
  }
};
