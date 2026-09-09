/* ============================================================
   Lume — weather

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'weather',

  /* ---------------------------------------------------------
     §40 Weather — environmental dashboard
     --------------------------------------------------------- */
  build: function (c) {
    var w = c.weather();
    var sun = c.sunTimes();
    var aq = D.aqiFor(c.profile.country);

    var hourStrip = '<div class="hourly">' + w.hourly.slice(0, 12).map(function (h, i) {
      return '<div class="hourly__col' + (i === 0 ? ' is-now' : '') + '">' +
        '<span class="hourly__t">' + (i === 0 ? UI.esc(c.t('common.now')) : c.time(h.h, 0)) + '</span>' +
        '<span class="hourly__i">' + UI.ico(h.icon) + '</span>' +
        '<span class="hourly__temp">' + c.L.temp(h.temp) + '</span>' +
        '<span class="hourly__rain">' + c.num(h.rain) + '%</span>' +
      '</div>';
    }).join('') + '</div>';

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city + ', ' + c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.dateLong(new Date()) }
      ]) }) +
      UI.section({ body: UI.summaryCard({
        tone: 'sky',
        kicker: UI.esc(w.desc),
        value: c.L.temp(w.temp),
        caption: c.t('weather.feels', { t: c.L.temp(w.feels) }) + ' · ' +
          c.t('weather.hilo', { hi: c.L.temp(w.hi), lo: c.L.temp(w.lo) }),
        aside: '<span class="wicon">' + UI.ico(w.icon) + '</span>',
        stats: [
          { value: c.num(w.rain) + '%', label: c.t('weather.rain') },
          { value: c.L.speed(w.wind), label: c.t('weather.wind') },
          { value: c.num(w.humidity) + '%', label: c.t('weather.humidity') }
        ]
      }) }) +
      (w.alert ? UI.section({ body: UI.noteCard({ tone: 'warn', icon: 'i-alert',
        title: w.alert.title, text: w.alert.text }) }) : '') +
      UI.section({ title: c.t('weather.hourly'), flush: true, body: hourStrip }) +
      UI.section({ title: c.t('weather.forecast'), body: UI.rows(w.daily.map(function (d, i) {
        return UI.richRow({
          icon: d.icon,
          title: i === 0 ? c.t('common.today') : i === 1 ? c.t('common.tomorrow') : c.dayName(i),
          sub: d.desc,
          meta: [c.num(d.rain) + '% ' + c.t('weather.rain')],
          spark: '<span class="tempbar"><i style="inset-inline-start:' + d.lowPct +
                 '%;inset-inline-end:' + (100 - d.hiPct) + '%"></i></span>',
          value: c.L.temp(d.hi),
          valueSub: c.L.temp(d.lo)
        });
      })) }) +
      UI.section({ title: c.t('weather.air'), body: UI.card(
        '<div class="aqi">' +
          '<div class="aqi__value"><b>' + aq.value + '</b><i>AQI</i></div>' +
          '<div class="aqi__body">' +
            UI.statusBadge({ label: c.t(aq.band.key + '.label'), tone: aq.band.tone }) +
            '<p class="aqi__advice">' + UI.esc(c.t(aq.band.key + '.advice')) + '</p>' +
          '</div>' +
        '</div>' +
        '<div class="aqi__parts">' + aq.parts.map(function (p) {
          return '<span class="aqi__part"><b>' + p.v + '</b><i>' + UI.esc(p.n) + '</i></span>';
        }).join('') + '</div>') }) +
      UI.section({ title: c.t('sun.title'), body: UI.card(
        '<div class="sunarc">' +
          '<svg viewBox="0 0 200 74" aria-hidden="true">' +
            '<path class="sunarc__path" d="M8 68 A 92 92 0 0 1 192 68"/>' +
            '<path class="sunarc__done" d="M8 68 A 92 92 0 0 1 192 68" style="--p:' + sun.dayProgress.toFixed(3) + '"/>' +
            '<circle class="sunarc__dot" cx="' + (8 + 184 * sun.dayProgress).toFixed(1) + '" cy="' +
              (68 - Math.sin(Math.PI * sun.dayProgress) * 58).toFixed(1) + '" r="6"/>' +
          '</svg>' +
          '<div class="sunarc__ends"><span><b>' + c.time(sun.sunrise.h, sun.sunrise.m) + '</b><i>' +
            UI.esc(c.t('sun.sunrise')) + '</i></span><span><b>' + c.time(sun.sunset.h, sun.sunset.m) +
            '</b><i>' + UI.esc(c.t('sun.sunset')) + '</i></span></div>' +
        '</div>' +
        UI.metrics([
          { value: sun.dayLength, label: c.t('sun.daylength') },
          { value: sun.moonPhase, label: c.t('sun.moon') },
          { value: c.L.temp(w.dew), label: c.t('weather.dew') }
        ], 3)) }) +
      UI.section({ title: c.t('weather.details'), body: UI.rows([
        UI.compactRow({ icon: 'i-eye', label: c.t('weather.visibility'), value: c.L.distance(w.visibility) }),
        UI.compactRow({ icon: 'i-gauge', label: c.t('weather.pressure'), value: c.num(w.pressure) + ' ' + c.t('unit.hpa') }),
        UI.compactRow({ icon: 'i-wind', label: c.t('weather.gusts'), value: c.L.speed(w.gusts) }),
        UI.compactRow({ icon: 'i-sun', label: c.t('weather.uv'), value: w.uv + ' · ' + w.uvLabel })
      ]) });
  }
};
