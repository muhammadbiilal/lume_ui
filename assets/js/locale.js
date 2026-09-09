/* ============================================================
   Lume — locale engine
   Everything that has to change when the user's language,
   country, units, currency or clock changes lives here, so no
   screen has to know how to format anything.

   Built as a factory over a profile getter: app.js owns the
   profile, this owns the presentation of it.
   ============================================================ */
import { LUME_GEO } from './geo.js';
import { LUME_I18N } from './i18n.js';
export const LUME_LOCALE = function (getProfile) {
  'use strict';

  var GEO = LUME_GEO;
  var I18N = LUME_I18N;

  /* Approximate units of currency per 1 USD. Demo figures are authored in
     USD and converted, so a Karachi grocery total reads as rupees and a
     Tokyo one as yen without hand-writing 190 sets of numbers. */
  var RATES = {
    USD: 1, EUR: 0.92, GBP: 0.79, JPY: 157, CNY: 7.25, INR: 84, PKR: 283,
    BDT: 118, LKR: 305, NPR: 134, AFN: 71, IRR: 42000, IQD: 1310, SAR: 3.75,
    AED: 3.67, QAR: 3.64, KWD: 0.31, BHD: 0.38, OMR: 0.385, JOD: 0.71,
    ILS: 3.7, LBP: 89500, SYP: 13000, YER: 250, EGP: 48, MAD: 9.9, DZD: 134,
    TND: 3.1, LYD: 4.8, SDG: 600, TRY: 34, RUB: 92, UAH: 41, KZT: 480,
    UZS: 12800, AZN: 1.7, GEL: 2.7, AMD: 388, BYN: 3.3, MDL: 17.8, RON: 4.6,
    BGN: 1.8, RSD: 108, MKD: 57, ALL: 93, BAM: 1.8, HUF: 365, CZK: 23.5,
    PLN: 3.95, HRK: 6.9, ISK: 138, NOK: 10.8, SEK: 10.6, DKK: 6.9, CHF: 0.88,
    CAD: 1.36, AUD: 1.52, NZD: 1.66, SGD: 1.34, MYR: 4.45, IDR: 15800,
    THB: 34.5, VND: 25400, PHP: 58, KRW: 1360, TWD: 32.4, HKD: 7.8, MMK: 2100,
    KHR: 4100, LAK: 21500, MNT: 3400, BND: 1.34, MVR: 15.4, BTN: 84,
    ZAR: 18.2, NGN: 1600, GHS: 15.5, KES: 129, TZS: 2700, UGX: 3700,
    RWF: 1330, ETB: 122, SOS: 571, DJF: 178, ERN: 15, MZN: 64, ZMW: 26,
    ZWG: 25, MWK: 1740, BWP: 13.6, NAD: 18.2, LSL: 18.2, SZL: 18.2,
    MUR: 46, SCR: 14, MGA: 4600, KMF: 452, AOA: 910, CVE: 101, STN: 22.6,
    GMD: 70, GNF: 8600, LRD: 190, SLE: 22.5, XOF: 604, XAF: 604, CDF: 2800,
    SSP: 3200, MRU: 39.7, TJS: 10.7, TMT: 3.5, KGS: 86, PGK: 3.9, FJD: 2.25,
    SBD: 8.4, VUV: 119, WST: 2.75, TOP: 2.35, MXN: 20.1, BRL: 5.8, ARS: 1010,
    CLP: 970, COP: 4350, PEN: 3.75, BOB: 6.9, PYG: 7800, UYU: 42, VES: 47,
    GTQ: 7.7, HNL: 25, NIO: 36.8, CRC: 510, PAB: 1, DOP: 60, CUP: 24,
    JMD: 157, TTD: 6.8, BBD: 2, BSD: 1, BZD: 2, XCD: 2.7, GYD: 209,
    SRD: 35, HTG: 131, BIF: 2900
  };

  /* Round to something a human would actually see on a price tag. */
  function tidy(v) {
    if (v >= 100000) return Math.round(v / 1000) * 1000;
    if (v >= 10000) return Math.round(v / 100) * 100;
    if (v >= 1000) return Math.round(v / 10) * 10;
    if (v >= 100) return Math.round(v);
    if (v >= 10) return Math.round(v * 2) / 2;
    return Math.round(v * 10) / 10;
  }

  function p() { return getProfile(); }

  function country() { return GEO.get(p().country) || GEO.get('US'); }

  function lang() { return p().lang || 'en'; }

  function langMeta() {
    var code = lang();
    for (var i = 0; i < I18N.LANGS.length; i++) if (I18N.LANGS[i].code === code) return I18N.LANGS[i];
    return I18N.LANGS[0];
  }

  function dir() { return langMeta().dir; }

  function locale() { return lang() + '-' + p().country; }

  function currencyCode() {
    var pref = p().currency;
    return pref && pref !== 'auto' ? pref : country().currency;
  }

  function unitSystem() {
    var pref = p().units;
    return pref && pref !== 'auto' ? pref : country().units;
  }

  function clock() {
    var pref = p().clock;
    if (pref === '12') return 12;
    if (pref === '24') return 24;
    return country().clock;
  }

  /* §124.17 — automatic follows the user's region; a manual choice overrides
     it. Neither is the device's clock, and neither is a venue's: a market, a
     flight and a train each carry their own (§26.10). */
  function timezone() {
    var manual = p().tz;
    return manual ? manual : country().tz;
  }

  /* ---- strings ---- */

  function t(key, vars) {
    var d = I18N.DICTS[lang()] || I18N.DICTS.en;
    var s = d[key];
    if (s === undefined) s = I18N.DICTS.en[key];       /* graceful fallback */
    if (s === undefined) return key;
    if (vars) {
      s = s.replace(/\{(\w+)\}/g, function (whole, k) {
        return vars[k] !== undefined ? vars[k] : whole;
      });
    }
    return s;
  }

  /* ---- names, via Intl so they localise for free ---- */

  function safeDisplay(type, code) {
    try {
      var dn = new Intl.DisplayNames([lang(), 'en'], { type: type });
      return dn.of(code) || code;
    } catch (e) { return code; }
  }

  function countryName(code) { return safeDisplay('region', code); }
  function languageName(code) { return safeDisplay('language', code); }

  /* ---- numbers, money, dates ---- */

  function num(n, opts) {
    try { return new Intl.NumberFormat(locale(), opts).format(n); }
    catch (e) { return String(n); }
  }

  /* Amounts are authored in USD; convert, tidy, then format. */
  function money(usd, opts) {
    var code = currencyCode();
    var rate = RATES[code] || 1;
    var value = tidy(usd * rate);
    try {
      return new Intl.NumberFormat(locale(), {
        style: 'currency', currency: code,
        maximumFractionDigits: (opts && opts.decimals !== undefined) ? opts.decimals : 0
      }).format(value);
    } catch (e) { return code + ' ' + num(value); }
  }

  /* For a figure already expressed in the local currency (a published fuel
     price, say) — format it without converting. */
  function moneyRaw(value, code, decimals) {
    try {
      return new Intl.NumberFormat(locale(), {
        style: 'currency', currency: code || currencyCode(),
        maximumFractionDigits: decimals === undefined ? 2 : decimals
      }).format(value);
    } catch (e) { return (code || currencyCode()) + ' ' + num(value); }
  }

  /* Compact notation, so a turnover figure reads "Rs 18.4 crore" in India
     and "$184M" in New York rather than being sliced by a regex. */
  function compact(n) {
    try { return new Intl.NumberFormat(locale(), { notation: 'compact', maximumFractionDigits: 1 }).format(n); }
    catch (e) { return num(Math.round(n)); }
  }

  function compactMoney(value, code) {
    try {
      return new Intl.NumberFormat(locale(), {
        style: 'currency', currency: code || currencyCode(),
        notation: 'compact', maximumFractionDigits: 1
      }).format(value);
    } catch (e) { return (code || currencyCode()) + ' ' + compact(value); }
  }

  function date(d, opts) {
    try { return new Intl.DateTimeFormat(locale(), opts).format(d); }
    catch (e) { return d.toDateString(); }
  }

  function dateLong(d) { return date(d, { weekday: 'long', day: 'numeric', month: 'long' }); }
  function dateShort(d) { return date(d, { weekday: 'short', day: 'numeric', month: 'short' }); }

  /* Prayer times and timetables are stored as 24h h/m pairs. */
  function time(h, m) {
    var d = new Date();
    d.setHours(h, m, 0, 0);
    try {
      return new Intl.DateTimeFormat(locale(), {
        hour: 'numeric', minute: '2-digit', hour12: clock() === 12
      }).format(d);
    } catch (e) {
      return (h < 10 ? '0' : '') + h + ':' + (m < 10 ? '0' : '') + m;
    }
  }

  function weekStart() {
    try {
      var lw = new Intl.Locale(locale()).weekInfo;
      if (lw && lw.firstDay) return lw.firstDay;
    } catch (e) {}
    return 1;
  }

  /* ---- units ---- */

  function temp(celsius) {
    if (unitSystem() === 'imperial') return Math.round(celsius * 9 / 5 + 32) + '°';
    return Math.round(celsius) + '°';
  }

  function tempUnit() { return unitSystem() === 'imperial' ? 'F' : 'C'; }

  function speed(kmh) {
    if (unitSystem() === 'imperial') return Math.round(kmh * 0.621) + ' ' + t('unit.mph');
    return Math.round(kmh) + ' ' + t('unit.kmh');
  }

  function distance(km) {
    if (unitSystem() === 'imperial') {
      var mi = km * 0.621;
      return (mi < 10 ? mi.toFixed(1) : Math.round(mi)) + ' ' + t('unit.mi');
    }
    if (km < 1) return Math.round(km * 1000) + ' m';
    return (km < 10 ? km.toFixed(1) : Math.round(km)) + ' ' + t('unit.km');
  }

  return {
    t: t, dir: dir, lang: lang, langMeta: langMeta, locale: locale,
    country: country, countryName: countryName, languageName: languageName,
    currencyCode: currencyCode, unitSystem: unitSystem, clock: clock, timezone: timezone,
    num: num, money: money, moneyRaw: moneyRaw, compact: compact, compactMoney: compactMoney,
    date: date, dateLong: dateLong, dateShort: dateShort, time: time, weekStart: weekStart,
    temp: temp, tempUnit: tempUnit, speed: speed, distance: distance,
    RATES: RATES
  };
};
