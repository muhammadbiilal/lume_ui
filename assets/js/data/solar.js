/* ============================================================
   Lume — Qibla and prayer times
   Computed from latitude, longitude and the date rather than
   looked up, so they are correct in every city the app offers
   instead of the two we happened to hard-code.
   ============================================================ */
export const LUME_SOLAR = (function () {
  'use strict';

  var KAABA = { lat: 21.4225, lon: 39.8262 };

  var D2R = Math.PI / 180, R2D = 180 / Math.PI;
  function sin(d) { return Math.sin(d * D2R); }
  function cos(d) { return Math.cos(d * D2R); }
  function tan(d) { return Math.tan(d * D2R); }
  function asin(x) { return Math.asin(x) * R2D; }
  function acos(x) { return Math.acos(x) * R2D; }
  function atan2(y, x) { return Math.atan2(y, x) * R2D; }
  function fix(a, n) { a = a - n * Math.floor(a / n); return a < 0 ? a + n : a; }

  /* City-level coordinates where we have them; the country's own point is a
     good enough fallback for everywhere else. */
  var CITIES = {
    'PK:Islamabad': [33.69, 73.05], 'PK:Karachi': [24.86, 67.00], 'PK:Lahore': [31.55, 74.34],
    'PK:Rawalpindi': [33.60, 73.04], 'PK:Faisalabad': [31.42, 73.08], 'PK:Peshawar': [34.02, 71.58],
    'PK:Multan': [30.16, 71.52], 'PK:Quetta': [30.18, 66.98], 'PK:Hyderabad': [25.40, 68.37],
    'PK:Gujranwala': [32.16, 74.19], 'PK:Sialkot': [32.49, 74.53], 'PK:Bahawalpur': [29.40, 71.68],
    'PK:Sukkur': [27.70, 68.86], 'PK:Larkana': [27.56, 68.21], 'PK:Mardan': [34.20, 72.05],
    'PK:Abbottabad': [34.15, 73.22], 'PK:Swat': [34.78, 72.36], 'PK:Gwadar': [25.12, 62.32],
    'PK:Gilgit': [35.92, 74.31], 'PK:Skardu': [35.30, 75.63], 'PK:Muzaffarabad': [34.37, 73.47],
    'GB:London': [51.51, -0.13], 'GB:Manchester': [53.48, -2.24], 'GB:Birmingham': [52.49, -1.89],
    'GB:Glasgow': [55.86, -4.25], 'GB:Edinburgh': [55.95, -3.19], 'GB:Leeds': [53.80, -1.55],
    'GB:Liverpool': [53.41, -2.98], 'GB:Bristol': [51.45, -2.59], 'GB:Cardiff': [51.48, -3.18],
    'GB:Belfast': [54.60, -5.93], 'GB:Sheffield': [53.38, -1.47], 'GB:Newcastle': [54.98, -1.61],
    'GB:Aberdeen': [57.15, -2.09], 'GB:Swansea': [51.62, -3.94],
    'US:New York': [40.71, -74.01], 'US:Los Angeles': [34.05, -118.24], 'US:Chicago': [41.88, -87.63],
    'US:Houston': [29.76, -95.37], 'US:Dallas': [32.78, -96.80], 'US:Austin': [30.27, -97.74],
    'US:Miami': [25.76, -80.19], 'US:Seattle': [47.61, -122.33], 'US:Boston': [42.36, -71.06],
    'US:Atlanta': [33.75, -84.39], 'US:Detroit': [42.33, -83.05], 'US:Dearborn': [42.32, -83.18],
    'US:Philadelphia': [39.95, -75.17], 'US:Phoenix': [33.45, -112.07], 'US:Las Vegas': [36.17, -115.14],
    'US:San Francisco': [37.77, -122.42], 'US:San Diego': [32.72, -117.16], 'US:San Jose': [37.34, -121.89],
    'CA:Toronto': [43.65, -79.38], 'CA:Montreal': [45.50, -73.57], 'CA:Vancouver': [49.28, -123.12],
    'CA:Calgary': [51.05, -114.07], 'CA:Edmonton': [53.55, -113.49], 'CA:Ottawa': [45.42, -75.70],
    'AE:Dubai': [25.20, 55.27], 'AE:Abu Dhabi': [24.45, 54.38], 'AE:Sharjah': [25.35, 55.39],
    'SA:Riyadh': [24.71, 46.68], 'SA:Jeddah': [21.49, 39.19], 'SA:Makkah': [21.42, 39.83],
    'SA:Madinah': [24.52, 39.57], 'SA:Dammam': [26.43, 50.10],
    'IN:New Delhi': [28.61, 77.21], 'IN:Mumbai': [19.08, 72.88], 'IN:Bengaluru': [12.97, 77.59],
    'IN:Chennai': [13.08, 80.27], 'IN:Hyderabad': [17.39, 78.49], 'IN:Kolkata': [22.57, 88.36],
    'AU:Sydney': [-33.87, 151.21], 'AU:Melbourne': [-37.81, 144.96], 'AU:Perth': [-31.95, 115.86],
    'AU:Brisbane': [-27.47, 153.03],
    'TR:Istanbul': [41.01, 28.98], 'TR:Ankara': [39.93, 32.86],
    'ID:Jakarta': [-6.21, 106.85], 'MY:Kuala Lumpur': [3.14, 101.69],
    'EG:Cairo': [30.04, 31.24], 'ZA:Johannesburg': [-26.20, 28.05], 'ZA:Cape Town': [-33.92, 18.42],
    'NG:Lagos': [6.52, 3.38], 'NG:Abuja': [9.06, 7.49], 'JP:Tokyo': [35.68, 139.69],
    'DE:Berlin': [52.52, 13.40], 'FR:Paris': [48.86, 2.35], 'SG:Singapore': [1.35, 103.82]
  };

  function coordsFor(country, city) {
    var key = country.code + ':' + city;
    if (CITIES[key]) return { lat: CITIES[key][0], lon: CITIES[key][1] };
    return { lat: country.lat, lon: country.lon };
  }

  /* ---- Qibla: initial great-circle bearing towards the Kaaba ---- */
  function qibla(lat, lon) {
    var dLon = KAABA.lon - lon;
    var y = sin(dLon);
    var x = cos(lat) * tan(KAABA.lat) - sin(lat) * cos(dLon);
    return fix(atan2(y, x), 360);
  }

  function compassPoint(deg) {
    var names = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return names[Math.round(fix(deg, 360) / 45) % 8];
  }

  /* ---- Timezone offset for an IANA zone, on a given date ---- */
  function tzOffset(tz, date) {
    try {
      var parts = new Intl.DateTimeFormat('en-US', {
        timeZone: tz, timeZoneName: 'longOffset'
      }).formatToParts(date);
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].type === 'timeZoneName') {
          var m = /GMT([+-])(\d{1,2})(?::(\d{2}))?/.exec(parts[i].value);
          if (m) return (m[1] === '-' ? -1 : 1) * (parseInt(m[2], 10) + (parseInt(m[3] || '0', 10) / 60));
          return 0;                                   /* plain "GMT" */
        }
      }
    } catch (e) {}
    return -date.getTimezoneOffset() / 60;
  }

  /* ---- Solar position ---- */
  function julian(date) {
    var y = date.getFullYear(), m = date.getMonth() + 1, d = date.getDate();
    if (m <= 2) { y -= 1; m += 12; }
    var a = Math.floor(y / 100), b = 2 - a + Math.floor(a / 4);
    return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + d + b - 1524.5;
  }

  function sunPosition(jd) {
    var d = jd - 2451545.0;
    var g = fix(357.529 + 0.98560028 * d, 360);
    var q = fix(280.459 + 0.98564736 * d, 360);
    var l = fix(q + 1.915 * sin(g) + 0.020 * sin(2 * g), 360);
    var e = 23.439 - 0.00000036 * d;
    var decl = asin(sin(e) * sin(l));
    var ra = fix(atan2(cos(e) * sin(l), cos(l)) / 15, 24);
    var eqt = q / 15 - ra;                             /* equation of time, hours */
    return { decl: decl, eqt: eqt };
  }

  /* Hour angle, in hours, for the sun at a given altitude. */
  function hourAngle(alt, lat, decl) {
    var c = (sin(alt) - sin(lat) * sin(decl)) / (cos(lat) * cos(decl));
    if (c > 1 || c < -1) return null;                  /* never reached at this latitude */
    return acos(c) / 15;
  }

  /* Asr: the sun's altitude when a shadow equals the object's length (1) or
     twice it (2, Hanafi). This is an altitude above the horizon, so it stays
     positive — negating it puts Asr after Maghrib. */
  function asrAngle(factor, lat, decl) {
    return R2D * Math.atan(1 / (factor + Math.abs(tan(lat - decl))));
  }

  var METHODS = {
    'Karachi':    { fajr: 18,   isha: 18 },
    'MWL':        { fajr: 18,   isha: 17 },
    'ISNA':       { fajr: 15,   isha: 15 },
    'UmmAlQura':  { fajr: 18.5, ishaMinutes: 90 },
    'Egyptian':   { fajr: 19.5, isha: 17.5 },
    'Tehran':     { fajr: 17.7, isha: 14 },
    'Gulf':       { fajr: 19.5, ishaMinutes: 90 }
  };

  /* Returns the five prayers plus sunrise, as {name, h, m, minor}. */
  function prayerTimes(opts) {
    var date = opts.date || new Date();
    var lat = opts.lat, lon = opts.lon;
    var method = METHODS[opts.method] || METHODS.MWL;
    var asrFactor = opts.hanafi ? 2 : 1;
    var offset = tzOffset(opts.tz, date);

    var jd = julian(date) - lon / (15 * 24);
    var sp = sunPosition(jd);

    var noon = 12 - sp.eqt - lon / 15 + offset;        /* solar noon, local hours */

    function before(alt) { var ha = hourAngle(alt, lat, sp.decl); return ha === null ? null : noon - ha; }
    function after(alt)  { var ha = hourAngle(alt, lat, sp.decl); return ha === null ? null : noon + ha; }

    var sunrise = before(-0.833);
    var sunset  = after(-0.833);
    var fajr    = before(-method.fajr);
    var asr     = after(asrAngle(asrFactor, lat, sp.decl));
    var isha    = method.ishaMinutes !== undefined
      ? (sunset === null ? null : sunset + method.ishaMinutes / 60)
      : after(-method.isha);

    /* Above the polar circles the sun may never reach a twilight angle. Fall
       back to a proportion of the night so the app still shows something
       usable rather than a blank. */
    if (fajr === null && sunrise !== null) fajr = sunrise - 1.2;
    if (isha === null && sunset !== null) isha = sunset + 1.2;
    if (sunrise === null) { sunrise = 6; sunset = 18; fajr = 4.8; isha = 19.2; asr = 15.5; }

    function hm(hours, name, minor) {
      var v = fix(hours, 24);
      var h = Math.floor(v);
      var m = Math.round((v - h) * 60);
      if (m === 60) { m = 0; h = (h + 1) % 24; }
      return { name: name, h: h, m: m, minor: !!minor };
    }

    return [
      hm(fajr, 'Fajr'),
      hm(sunrise, 'Sunrise', true),
      hm(noon + 1 / 60, 'Dhuhr'),
      hm(asr, 'Asr'),
      hm(sunset, 'Maghrib'),
      hm(isha, 'Isha')
    ];
  }

  return {
    KAABA: KAABA,
    coordsFor: coordsFor,
    qibla: qibla,
    compassPoint: compassPoint,
    prayerTimes: prayerTimes,
    tzOffset: tzOffset,
    METHODS: METHODS
  };
})();
