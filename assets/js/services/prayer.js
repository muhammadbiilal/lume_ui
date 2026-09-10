/* ============================================================
   Lume — Prayer times

   Where the user actually is, turned into a schedule: city
   coordinates when we have them, the country's own point
   otherwise, and the calculation method the user chose.

   The result is cached against everything that could change it
   — country, city, method and the date — so a screen redrawing
   every second is not recomputing sunrise every second, and a
   changed city cannot be served a stale schedule.

   Nothing here asks whether Islamic content is switched on.
   That is the visibility system's question, and it is asked
   before anything reaches this.
   ============================================================ */

export function createPrayer(deps) {
  const getProfile = deps.profile;
  const getLocale = deps.locale;
  const SOLAR = deps.solar;

  let prayerCache = null;

  /* Where the user actually is: city coordinates when we have them, the
     country's own point otherwise. */
  function here() {
    return SOLAR.coordsFor(getLocale().country(), getProfile().city);
  }

  function prayerSet() {
    var pos = here();
    var key = getProfile().country + '|' + getProfile().city + '|' + getProfile().method + '|' +
              new Date().toDateString();
    if (prayerCache && prayerCache.key === key) return prayerCache.list;
    prayerCache = {
      key: key,
      list: SOLAR.prayerTimes({
        lat: pos.lat, lon: pos.lon, tz: getLocale().country().tz,
        method: getProfile().method, date: new Date()
      })
    };
    return prayerCache.list;
  }

  function mins(p) { return p.h * 60 + p.m; }

  function prayerState() {
    var list = prayerSet();
    var main = list.filter(function (p) { return !p.minor; });
    var now = new Date();
    var nowM = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;

    var next = null, prev = null;
    for (var i = 0; i < main.length; i++) {
      if (mins(main[i]) > nowM) { next = main[i]; prev = main[i - 1] || null; break; }
    }
    if (!next) { next = main[0]; prev = main[main.length - 1]; }

    var toNext = mins(next) - nowM;
    if (toNext < 0) toNext += 1440;
    var span = prev ? mins(next) - mins(prev) : 1440;
    if (span <= 0) span += 1440;

    return { list: list, main: main, next: next, prev: prev, toNext: toNext, progress: Math.max(0, Math.min(1, 1 - toNext / span)) };
  }

  return {
    times: prayerSet,
    state: prayerState,
    minutes: mins,
    /* Dropped when something the schedule depends on changes underneath
       it — signing in can move the city. */
    forget: function () { prayerCache = null; }
  };
}
