/* ============================================================
   Lume — qibla

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'qibla',

  /* ---------------------------------------------------------
     24.2 Qibla — instrument
     --------------------------------------------------------- */
  build: function (c) {
    var q = c.qibla();
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city + ', ' + c.L.countryName(c.profile.country), act: 'sheet:personalise' }
      ]) }) +
      UI.section({ body:
        '<div class="compass" data-compass>' +
          '<div class="compass__face">' +
            '<span class="compass__cardinal compass__cardinal--n">N</span>' +
            '<span class="compass__cardinal compass__cardinal--e">E</span>' +
            '<span class="compass__cardinal compass__cardinal--s">S</span>' +
            '<span class="compass__cardinal compass__cardinal--w">W</span>' +
            '<span class="compass__ticks" aria-hidden="true"></span>' +
            '<span class="compass__needle" data-compass-needle style="--deg:' + q.bearing + 'deg">' +
              UI.ico('i-navigation') + '</span>' +
            '<span class="compass__kaaba" style="--deg:' + q.bearing + 'deg"><i></i></span>' +
          '</div>' +
          '<p class="compass__deg"><b data-compass-deg>' + Math.round(q.bearing) + '°</b>' +
            '<i>' + UI.esc(q.compassPoint) + '</i></p>' +
        '</div>' }) +
      UI.section({ body: UI.metrics([
        { icon: 'i-navigation', value: Math.round(q.bearing) + '°', label: c.t('qibla.direction') },
        { icon: 'i-route', value: c.L.distance(q.distanceKm), label: c.t('qibla.distance') },
        { icon: 'i-compass', value: c.t('qibla.calibrated'), label: c.t('qibla.calibration') }
      ], 3) }) +
      UI.section({ body: UI.noteCard({
        icon: 'i-compass', tone: 'info',
        title: c.t('qibla.calibrate.title'), text: c.t('qibla.calibrate.text') }) }) +
      UI.section({ title: c.t('qibla.reference'), body: UI.rows([
        UI.compactRow({ icon: 'i-mosque', label: c.t('qibla.kaaba'), value: c.coords(21.4225, 39.8262) }),
        UI.compactRow({ icon: 'i-pin', label: c.t('qibla.yourpos'), value: c.coords(q.lat, q.lon) }),
        UI.compactRow({ icon: 'i-globe', label: c.t('qibla.magnetic'), value: q.magnetic })
      ]) });
  }
};
