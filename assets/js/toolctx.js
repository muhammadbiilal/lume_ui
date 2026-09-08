/* ============================================================
   Lume — tool screen context

   The one place a tool screen gets its data from. Screens never
   format a number, convert a unit, resolve a timezone or reach
   for a country code: they ask the context, and the context
   asks the locale engine, the solar engine and the regional
   configuration.

   That is what keeps §63 of the product brief true — no
   scattered `if country ==` and no scattered `if Muslim`.
   ============================================================ */
window.LUME_CTX = function (deps) {
  'use strict';

  var C = window.LUME;
  var D = window.LUME_DATA;
  var SPEC = window.LUME_SPEC;
  var SOLAR = window.LUME_SOLAR;
  var UI = window.LUME_UI;

  var L = deps.L, t = deps.t, getProfile = deps.profile;
  var store = deps.store;

  function pad2(n) { return n < 10 ? '0' + n : '' + n; }
  function P() { return getProfile(); }

  /* Per-tool scratch state: which tab is open, which row is selected,
     what the user typed. Survives a re-render, not a reload. */
  var STATE = {};
  function stateFor(id) { return (STATE[id] = STATE[id] || {}); }

  /* Calculator-style inputs the user edits live. Defaults come from the
     user's own context so a field is never empty on first open. */
  var FIELDS = {};
  function fieldsFor(id, defaults) {
    if (!FIELDS[id]) FIELDS[id] = defaults;
    return FIELDS[id];
  }
  function setField(id, key, value) {
    if (!FIELDS[id]) FIELDS[id] = {};
    FIELDS[id][key] = value;
  }

  /* A stable pseudo-random day index, so "today's ayah" is the same all
     day but different tomorrow. */
  function dayIndex(n) {
    var d = new Date();
    return (d.getFullYear() * 372 + d.getMonth() * 31 + d.getDate()) % n;
  }

  function here() { return SOLAR.coordsFor(L.country(), P().city); }

  /* ---------------------------------------------------------
     Time, dates, calendars
     --------------------------------------------------------- */
  function prayerList() {
    var pos = here();
    return SOLAR.prayerTimes({
      lat: pos.lat, lon: pos.lon, tz: L.country().tz,
      method: P().method, date: new Date()
    });
  }

  var PKEY = { Fajr: 'fajr', Sunrise: 'sunrise', Dhuhr: 'dhuhr', Asr: 'asr', Maghrib: 'maghrib', Isha: 'isha' };

  function prayerTimes() {
    return prayerList().filter(function (p) { return !p.minor; }).map(function (p) {
      return { key: PKEY[p.name] || p.name.toLowerCase(), name: p.name, h: p.h, m: p.m };
    });
  }

  function prayerState() {
    var set = prayerTimes();
    var now = new Date();
    var nowM = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;
    var idx = 0, next = set[0], prev = set[set.length - 1];
    for (var i = 0; i < set.length; i++) {
      if (set[i].h * 60 + set[i].m > nowM) { idx = i; next = set[i]; prev = set[i - 1] || set[set.length - 1]; break; }
      if (i === set.length - 1) { idx = 0; next = set[0]; prev = set[set.length - 1]; }
    }
    var toNext = (next.h * 60 + next.m) - nowM;
    if (toNext < 0) toNext += 1440;
    var span = (next.h * 60 + next.m) - (prev.h * 60 + prev.m);
    if (span <= 0) span += 1440;
    var secs = Math.max(0, Math.round(toNext * 60));
    return {
      index: idx, next: next, prev: prev, minutes: toNext,
      progress: Math.max(0, Math.min(1, 1 - toNext / span)),
      pctLabel: Math.round(Math.max(0, Math.min(1, 1 - toNext / span)) * 100) + '%',
      countdown: Math.floor(secs / 3600) + ':' + pad2(Math.floor(secs % 3600 / 60)) + ':' + pad2(secs % 60),
      short: t('prayer.inTime', { time: t('duration.hm', { h: Math.floor(toNext / 60), m: pad2(Math.round(toNext % 60)) }) })
    };
  }

  function upcomingPrayerDays(n) {
    var pos = here(), out = [];
    for (var i = 1; i <= n; i++) {
      var d = new Date();
      d.setDate(d.getDate() + i);
      var list = SOLAR.prayerTimes({ lat: pos.lat, lon: pos.lon, tz: L.country().tz, method: P().method, date: d })
        .filter(function (p) { return !p.minor; });
      out.push({ label: L.date(d, { weekday: 'short', day: 'numeric', month: 'short' }),
        fajr: list[0], dhuhr: list[1], maghrib: list[3] });
    }
    return out;
  }

  function sunTimes() {
    var all = prayerList();
    var sunrise = all.filter(function (p) { return p.name === 'Sunrise'; })[0] || { h: 6, m: 0 };
    var sunset = all.filter(function (p) { return p.name === 'Maghrib'; })[0] || { h: 18, m: 30 };
    var riseM = sunrise.h * 60 + sunrise.m, setM = sunset.h * 60 + sunset.m;
    var now = new Date(), nowM = now.getHours() * 60 + now.getMinutes();
    var len = setM - riseM;
    var phases = ['moon.new', 'moon.waxCrescent', 'moon.firstQuarter', 'moon.waxGibbous',
                  'moon.full', 'moon.wanGibbous', 'moon.lastQuarter', 'moon.wanCrescent'];
    var pIdx = Math.floor((dayIndex(29.53 * 100) / 100 / 29.53) * 8) % 8;
    var noonM = Math.round((riseM + setM) / 2);
    return {
      sunrise: sunrise, sunset: sunset,
      dayLength: t('duration.hm', { h: Math.floor(len / 60), m: pad2(len % 60) }),
      dayProgress: Math.max(0, Math.min(1, (nowM - riseM) / Math.max(1, len))),
      solarNoon: L.time(Math.floor(noonM / 60), noonM % 60),
      moonPhase: t(phases[pIdx]),
      moonIllum: Math.round(Math.abs(Math.cos(pIdx / 8 * Math.PI)) * 100),
      events: [
        { time: L.time(sunrise.h - 1, sunrise.m), label: t('sun.dawn'), note: t('sun.dawnNote'), icon: 'i-moon', state: 'done' },
        { time: L.time(sunrise.h, sunrise.m), label: t('sun.sunrise'), note: '', icon: 'i-sun', state: nowM > riseM ? 'done' : '' },
        { time: L.time(Math.floor(noonM / 60), noonM % 60), label: t('sun.noon'), note: '', icon: 'i-sun',
          state: nowM > noonM ? 'done' : nowM > riseM ? 'now' : '' },
        { time: L.time(sunset.h, sunset.m), label: t('sun.sunset'), note: '', icon: 'i-moon', state: nowM > setM ? 'done' : '' },
        { time: L.time(sunset.h + 1, sunset.m), label: t('sun.dusk'), note: t('sun.duskNote'), icon: 'i-moon', state: '' }
      ]
    };
  }

  /* Tabular Islamic calendar — good enough to label a day, and honest
     about being a calculation rather than a sighting. */
  function hijri() {
    var d = new Date();
    var jd = Math.floor((d.getTime() / 86400000) + 2440587.5);
    var l = jd - 1948440 + 10632;
    var n = Math.floor((l - 1) / 10631);
    l = l - 10631 * n + 354;
    var j = Math.floor((10985 - l) / 5316) * Math.floor(50 * l / 17719) +
            Math.floor(l / 5670) * Math.floor(43 * l / 15238);
    l = l - Math.floor((30 - j) / 15) * Math.floor(17719 * j / 50) -
        Math.floor(j / 16) * Math.floor(15238 * j / 43) + 29;
    var month = Math.floor(24 * l / 709);
    var day = l - Math.floor(709 * month / 24);
    var year = 30 * n + j - 30;
    var name = D.HIJRI_MONTHS[Math.max(0, Math.min(11, month - 1))];
    return { day: day, month: name, monthIndex: month - 1, year: year,
      label: day + ' ' + name + ' ' + year };
  }

  function isoToday() {
    var d = new Date();
    return d.getFullYear() + '-' + pad2(d.getMonth() + 1) + '-' + pad2(d.getDate());
  }

  /* A date the demo data expresses as "12 Aug" is stored as an offset from
     today and formatted by the locale, so it reads correctly in every
     language rather than staying English. */
  function relDate(days) {
    var d = new Date();
    d.setDate(d.getDate() + days);
    return L.date(d, { day: 'numeric', month: 'short' });
  }

  function dayName(offset) {
    var d = new Date();
    d.setDate(d.getDate() + offset);
    return L.date(d, { weekday: 'long' });
  }

  function weekLabels() {
    var start = L.weekStart(), out = [];
    for (var i = 0; i < 7; i++) {
      var d = new Date(2024, 0, 7 + start + i); /* a known Sunday-anchored week */
      out.push(L.date(d, { weekday: 'narrow' }));
    }
    return out;
  }

  function clockNow() {
    var d = new Date();
    return L.time(d.getHours(), d.getMinutes());
  }

  /* A month grid that respects the locale's first day of the week and,
     for Muslim users, carries the Hijri date underneath. */
  function monthGrid() {
    var now = new Date();
    var year = now.getFullYear(), month = now.getMonth();
    var first = new Date(year, month, 1);
    var start = L.weekStart() % 7;
    var lead = (first.getDay() - start + 7) % 7;
    var days = new Date(year, month + 1, 0).getDate();
    var h = hijri();
    var cells = '';
    for (var i = 0; i < lead; i++) cells += '<span class="mgrid__cell is-empty"></span>';
    for (var d = 1; d <= days; d++) {
      var today = d === now.getDate();
      cells += '<button class="mgrid__cell' + (today ? ' is-today' : '') + '">' +
        '<b>' + d + '</b>' +
        (P().islamic ? '<i>' + Math.max(1, h.day - (now.getDate() - d)) + '</i>' : '') +
        '</button>';
    }
    var heads = weekLabels().map(function (w) { return '<span class="mgrid__head">' + UI.esc(w) + '</span>'; }).join('');
    return '<div class="mgrid">' +
      '<div class="mgrid__title">' + UI.esc(L.date(now, { month: 'long', year: 'numeric' })) +
        (P().islamic ? ' · <i>' + UI.esc(h.month + ' ' + h.year) + '</i>' : '') + '</div>' +
      '<div class="mgrid__grid">' + heads + cells + '</div>' +
    '</div>';
  }

  /* ---------------------------------------------------------
     Faith datasets
     --------------------------------------------------------- */
  function qibla() {
    var pos = here();
    var b = SOLAR.qibla(pos.lat, pos.lon);
    var R = 6371, toRad = Math.PI / 180;
    var dLat = (SOLAR.KAABA.lat - pos.lat) * toRad, dLon = (SOLAR.KAABA.lon - pos.lon) * toRad;
    var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(pos.lat * toRad) * Math.cos(SOLAR.KAABA.lat * toRad) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    return {
      bearing: b, compassPoint: SOLAR.compassPoint(b),
      distanceKm: Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))),
      lat: pos.lat, lon: pos.lon,
      magnetic: t('qibla.trueNorth')
    };
  }

  function nearbyMosques() {
    var set = prayerTimes();
    var next = prayerState();
    var names = [t('mosques.central'), t('mosques.jamia'), t('mosques.masjidA'), t('mosques.masjidB')];
    var facilities = [[t('mosques.fac.parking'), t('mosques.fac.women')], [t('mosques.fac.wudu')],
                      [t('mosques.fac.parking')], [t('mosques.fac.women'), t('mosques.fac.wudu')]];
    return names.map(function (n, i) {
      var km = 0.4 + i * 0.7;
      return {
        name: n + ' ' + P().city, address: t('mosques.addr', { city: P().city }),
        km: km, walk: Math.round(km * 12) + ' ' + t('unit.min'),
        facilities: facilities[i], reciter: ['Qari Ahmed', 'Hafiz Bilal', 'Qari Usman', 'Hafiz Salman'][i],
        next: set[next.index] || set[0],
        /* Taraweeh belongs to the mosque, not to the row that draws it. */
        rakaat: [20, 8, 20, 8][i],
        taraweeh: { h: 20, m: [45, 50, 55, 40][i] },
        x: 22 + i * 19, y: 30 + (i % 2) * 34
      };
    });
  }

  function heatDays(n, seed, rate) {
    var r = D.seedRand(seed), out = [];
    for (var i = 0; i < n; i++) {
      var v = r();
      out.push({ level: v > rate ? (v > rate + 0.25 ? 3 : 2) : v > rate - 0.25 ? 1 : 0 });
    }
    return out;
  }

  function prayerTracker() {
    var st = prayerState();
    return {
      doneToday: st.index, streak: 12, month: 0.86, qada: 7,
      heat: heatDays(35, 4211, 0.35),
      byPrayer: [28, 30, 26, 29, 24]
    };
  }

  function ramadan() {
    var h = hijri();
    var active = h.monthIndex === 8;
    var sun = sunTimes();
    var now = new Date(), nowM = now.getHours() * 60 + now.getMinutes();
    var setM = sun.sunset.h * 60 + sun.sunset.m;
    var mins = Math.max(0, setM - nowM);
    var monthsAway = (8 - h.monthIndex + 12) % 12;
    return {
      active: active, day: active ? h.day : 0,
      kept: active ? Math.max(0, h.day - 1) : 0,
      juz: active ? Math.round(h.day) : 0,
      charity: 180, charityGoal: 400,
      iftarIn: t('duration.hm', { h: Math.floor(mins / 60), m: pad2(mins % 60) }),
      heat: heatDays(30, 3312, active ? 0.15 : 0.9),
      daysUntil: monthsAway * 29 + (30 - h.day),
      startLabel: D.ISLAMIC_EVENTS[0].greg, hijriYear: h.year + (monthsAway ? 1 : 0),
      expectedFasts: 30
    };
  }

  function fasting() {
    return {
      kept: 8, target: 12, streak: 3, voluntary: 5, obligatory: 3, missed: 1,
      heat: heatDays(30, 9182, 0.45),
      recent: [
        { label: t('common.today'), kind: t('fast.sunnah'), kept: true },
        { label: t('common.yesterday'), kind: t('fast.qada'), kept: true },
        { label: dayName(-2), kind: t('fast.sunnah'), kept: false },
        { label: dayName(-3), kind: t('fast.sunnah'), kept: true }
      ]
    };
  }

  function ayahOfDay() {
    var a = D.AYAT[dayIndex(D.AYAT.length)];
    return {
      s: a.s, a: a.a, surah: a.surah, ar: a.ar, tr: a.tr, tl: a.tl,
      tafsir: t('ayah.tafsirBody')
    };
  }

  function quranProgress() {
    return { surah: 'Al-Kahf', ayah: 42, juz: 15, pct: 0.34, lastRead: t('common.yesterday') };
  }

  function quranSearch(q) {
    if (!q) return D.AYAT.map(function (a) {
      return { s: a.s, a: a.a, surah: a.surah, tr: a.tr, place: '' };
    });
    var needle = q.toLowerCase();
    var hits = [];
    D.AYAT.forEach(function (a) {
      if ((a.tr + ' ' + a.surah).toLowerCase().indexOf(needle) !== -1) {
        hits.push({ s: a.s, a: a.a, surah: a.surah, tr: a.tr, place: '' });
      }
    });
    D.SURAHS.forEach(function (s) {
      if ((s.name + ' ' + s.meaning).toLowerCase().indexOf(needle) !== -1) {
        hits.push({ s: s.n, a: 1, surah: s.name, tr: s.meaning, place: s.place });
      }
    });
    return hits;
  }

  function tasbih() {
    var s = stateFor('tasbih');
    if (s.count === undefined) { s.count = 0; s.dhikrIndex = 0; s.sets = 0; }
    return {
      count: s.count, dhikrIndex: s.dhikrIndex, sets: s.sets,
      history: [
        { dhikr: 'SubhanAllah', when: t('common.today'), count: 33 },
        { dhikr: 'Astaghfirullah', when: t('common.yesterday'), count: 100 }
      ]
    };
  }

  function zakat() {
    var ccy = L.currencyCode();
    var rate = L.RATES[ccy] || 1;
    var f = fieldsFor('zakat', {
      cash: Math.round(4000 * rate / 100) * 100, gold: 40, silver: 0,
      inv: Math.round(2000 * rate / 100) * 100, biz: 0, liab: Math.round(500 * rate / 100) * 100
    });
    var goldPerGram = 88 * rate;      /* ≈ USD 88/g bullion */
    var silverPerGram = 1.05 * rate;
    var nisabGold = 87.48 * goldPerGram;
    var assets = Number(f.cash) + Number(f.gold) * goldPerGram + Number(f.silver) * silverPerGram +
                 Number(f.inv) + Number(f.biz);
    var net = assets - Number(f.liab);
    var eligible = net >= 87.48 * silverPerGram * 7;
    return {
      f: f, net: net, due: eligible ? net * 0.025 : 0, eligible: eligible,
      nisabGold: nisabGold,
      lines: [
        { label: t('zakat.cash'), value: Number(f.cash) },
        { label: t('zakat.gold') + ' (' + f.gold + ' ' + t('unit.gram') + ')', value: Number(f.gold) * goldPerGram },
        { label: t('zakat.silver') + ' (' + f.silver + ' ' + t('unit.gram') + ')', value: Number(f.silver) * silverPerGram },
        { label: t('zakat.investments'), value: Number(f.inv) },
        { label: t('zakat.business'), value: Number(f.biz) },
        { label: t('zakat.liabilities'), value: -Number(f.liab) },
        { label: t('zakat.netAssets'), value: net },
        { label: t('zakat.payable'), value: eligible ? net * 0.025 : 0 }
      ]
    };
  }

  function faraid() {
    var ccy = L.currencyCode(), rate = L.RATES[ccy] || 1;
    var f = fieldsFor('faraid', {
      gross: Math.round(60000 * rate / 1000) * 1000,
      debts: Math.round(5000 * rate / 1000) * 1000,
      bequest: 0
    });
    var net = Math.max(0, Number(f.gross) - Number(f.debts) - Number(f.bequest));
    /* Wife 1/8, then residue split 2:1 between sons and daughters. */
    var wife = net / 8, residue = net - wife;
    var sons = 2, daughters = 1;
    var unit = residue / (sons * 2 + daughters);
    return {
      step: 2, gross: f.gross, debts: f.debts, bequest: f.bequest, net: net,
      heirs: [
        { id: 'wife', label: t('faraid.wife'), rule: t('faraid.rule.wife'), n: 1 },
        { id: 'son', label: t('faraid.sons'), rule: t('faraid.rule.son'), n: sons },
        { id: 'daughter', label: t('faraid.daughters'), rule: t('faraid.rule.daughter'), n: daughters }
      ],
      shares: [
        { label: t('faraid.wife'), fraction: '1/8', amount: wife, color: 'var(--accent)', reason: t('faraid.reason.wife') },
        { label: t('faraid.sons'), fraction: '2:1', amount: unit * 2 * sons, color: 'var(--violet)', reason: t('faraid.reason.son') },
        { label: t('faraid.daughters'), fraction: '1', amount: unit * daughters, color: 'var(--amber)', reason: t('faraid.reason.daughter') }
      ]
    };
  }

  /* ---------------------------------------------------------
     Money
     --------------------------------------------------------- */
  function exchange() { return D.exchangeFor(P().country); }

  function marketSession(ex) {
    if (!ex) return { open: false, label: t('markets.closed'), hours: t('markets.worldBoard'),
      adv: 0, dec: 0, advPct: 50, turnover: '—', volume: '—', trades: '—', openLabel: '—', closeLabel: '—' };
    var now = new Date();
    var h = now.getHours() + now.getMinutes() / 60;
    var o = parseFloat(ex.open.split(':')[0]) + parseFloat(ex.open.split(':')[1]) / 60;
    var cl = parseFloat(ex.close.split(':')[0]) + parseFloat(ex.close.split(':')[1]) / 60;
    var open = h >= o && h <= cl && now.getDay() > 0 && now.getDay() < 6;
    var adv = ex.stocks.filter(function (s) { return s.pct > 0; }).length * 41;
    var dec = ex.stocks.filter(function (s) { return s.pct <= 0; }).length * 38;
    return {
      open: open,
      label: open ? t('markets.open') : t('markets.closed'),
      hours: ex.open + ' – ' + ex.close + ' · ' + ex.tz.split('/')[1].replace('_', ' '),
      adv: adv, dec: dec, advPct: Math.round(adv / (adv + dec) * 100),
      turnover: L.moneyRaw(184000000, ex.ccy, 0).replace(/\d{3}$/, 'M').slice(0, 12),
      volume: '412M', trades: '188,204',
      openLabel: ex.open, closeLabel: ex.close
    };
  }

  function metals() {
    var ccy = L.country().currency, rate = L.RATES[ccy] || 1;
    var goldGram = 88 * rate, silverGram = 1.05 * rate;
    var pairs = [
      { code: 'USD', name: t('ccy.usd'), flag: '$', rate: 1 },
      { code: 'EUR', name: t('ccy.eur'), flag: '€', rate: L.RATES.EUR },
      { code: 'GBP', name: t('ccy.gbp'), flag: '£', rate: L.RATES.GBP },
      { code: 'SAR', name: t('ccy.sar'), flag: '﷼', rate: L.RATES.SAR },
      { code: 'AED', name: t('ccy.aed'), flag: 'د.إ', rate: L.RATES.AED }
    ].filter(function (p) { return p.code !== ccy; }).map(function (p, i) {
      var v = rate / p.rate;
      return { code: p.code, name: p.name, flag: p.flag, buy: v * 0.996, sell: v,
        pct: [0.24, -0.12, 0.31, 0, -0.08][i] || 0 };
    });
    return {
      ccy: ccy,
      gold: { perGram: goldGram, perTola: goldGram * 11.664, perOunce: 2740, chg: goldGram * 11.664 * 0.004, pct: 0.42 },
      silver: { perGram: silverGram, perTola: silverGram * 11.664, pct: -0.18 },
      pairs: pairs
    };
  }

  function currencyBoard() {
    var s = stateFor('currency');
    var home = L.currencyCode();
    var f = fieldsFor('currency', { amount: 100 });
    var from = s.from || home, to = s.to || (home === 'USD' ? 'EUR' : 'USD');
    var rate = (L.RATES[to] || 1) / (L.RATES[from] || 1);
    var popular = ['USD', 'EUR', 'GBP', 'SAR', 'AED', 'PKR', 'INR', 'TRY']
      .filter(function (x) { return x !== from; }).slice(0, 6).map(function (code, i) {
        return { code: code, name: t('ccy.' + code.toLowerCase()) === 'ccy.' + code.toLowerCase() ? code : t('ccy.' + code.toLowerCase()),
          flag: code.slice(0, 2), rate: (L.RATES[code] || 1) / (L.RATES[from] || 1),
          pct: [0.18, -0.24, 0.06, 0, 0.42, -0.11][i] || 0 };
      });
    return {
      from: from, to: to, fromName: L.countryName ? from : from, toName: to,
      amount: f.amount, rate: rate, result: Number(f.amount) * rate,
      popular: popular,
      recent: [
        { label: '100 ' + from + ' → ' + to, value: L.num(100 * rate, { maximumFractionDigits: 2 }) },
        { label: '1,000 ' + from + ' → ' + to, value: L.num(1000 * rate, { maximumFractionDigits: 2 }) }
      ]
    };
  }

  function fuelCost() {
    var fuel = D.fuelFor(P().country);
    var imperial = L.unitSystem() === 'imperial';
    var f = fieldsFor('fuelcost', {
      dist: imperial ? 250 : 400, econ: imperial ? 32 : 12, price: fuel.items[0].v, people: 2
    });
    var used = imperial ? Number(f.dist) / Number(f.econ) : Number(f.dist) / Number(f.econ);
    var total = used * Number(f.price);
    return {
      f: f, ccy: fuel.ccy,
      econUnit: imperial ? t('unit.mpg') : t('unit.kmpl'),
      distLabel: L.distance(imperial ? Number(f.dist) * 1.609 : Number(f.dist)),
      fuelUsed: used.toFixed(1) + ' ' + t('unit.' + fuel.unit),
      total: total, perPerson: total / Math.max(1, Number(f.people)),
      perUnit: total / Math.max(1, Number(f.dist)),
      perUnitLabel: t('fuelcost.perUnit', { unit: imperial ? t('unit.mi') : t('unit.km') }),
      scenarios: [
        { label: t('fuelcost.sc.solo'), fuel: used.toFixed(1), cost: total },
        { label: t('fuelcost.sc.shared', { n: f.people }), fuel: used.toFixed(1), cost: total / Math.max(1, Number(f.people)) },
        { label: t('fuelcost.sc.return'), fuel: (used * 2).toFixed(1), cost: total * 2 }
      ],
      history: [
        { label: t('fuelcost.hist1'), when: relDate(-4), cost: total * 0.82 },
        { label: t('fuelcost.hist2'), when: relDate(-11), cost: total * 1.44 }
      ]
    };
  }

  function tax() {
    var cfg = D.taxFor(P().country);
    var s = stateFor('tax');
    var period = s.period || 'month';
    if (!cfg) return { config: null };
    var taxable = cfg.bands.length > 1;
    if (!taxable) return { config: cfg, taxable: false };

    var rate = L.RATES[cfg.ccy] || 1;
    var f = fieldsFor('tax', {
      income: Math.round(3000 * rate / 1000) * 1000, deductions: 0
    });
    var annual = period === 'month' ? Number(f.income) * 12 : Number(f.income);
    var taxableAnnual = Math.max(0, annual - Number(f.deductions));

    var due = 0, marginal = 0, lower = 0, bands = [];
    for (var i = 0; i < cfg.bands.length; i++) {
      var upper = cfg.bands[i][0], r = cfg.bands[i][1];
      var inBand = Math.max(0, Math.min(taxableAnnual, upper) - lower);
      if (inBand > 0) { due += inBand * r; marginal = r; }
      bands.push({
        label: (upper === Infinity ? t('tax.above', { v: L.moneyRaw(lower, cfg.ccy, 0) })
                                   : L.moneyRaw(lower, cfg.ccy, 0) + ' – ' + L.moneyRaw(upper, cfg.ccy, 0)),
        rate: r, tax: inBand * r
      });
      lower = upper;
      if (taxableAnnual <= upper) break;
    }
    var netAnnual = annual - due;
    return {
      config: cfg, taxable: true, ccy: cfg.ccy, f: f, period: period,
      taxableAnnual: taxableAnnual, dueAnnual: due, netAnnual: netAnnual,
      dueDisplay: period === 'month' ? due / 12 : due,
      netDisplay: period === 'month' ? netAnnual / 12 : netAnnual,
      effective: annual ? due / annual : 0, marginal: marginal, bands: bands
    };
  }

  function bills() {
    var list = D.BILLS.map(function (b) {
      var state = b.state;
      return {
        name: b.name, provider: b.provider, amount: b.amount, ref: b.ref, state: state,
        icon: { Electricity: 'i-bolt', Gas: 'i-flame', Internet: 'i-wifi', Water: 'i-droplet', Mobile: 'i-signal' }[b.name] || 'i-receipt',
        dueLabel: state === 'overdue' ? t('bills.overdueBy', { n: -b.days })
                : state === 'paid' ? t('bills.paidOn', { date: b.due })
                : t('bills.dueIn', { n: b.days }),
        badge: state === 'overdue' ? { label: t('bills.overdue'), tone: 'warn' }
             : state === 'paid' ? { label: t('common.paid'), tone: 'ok' }
             : { label: t('bills.due'), tone: 'info' }
      };
    });
    var overdue = list.filter(function (b) { return b.state === 'overdue'; });
    var paid = list.filter(function (b) { return b.state === 'paid'; });
    var due = list.filter(function (b) { return b.state === 'due'; });
    var sum = function (a) { return a.reduce(function (x, b) { return x + b.amount; }, 0); };
    return {
      list: list, totalDue: sum(overdue) + sum(due) + sum(list.filter(function (b) { return b.state === 'upcoming'; })),
      overdue: sum(overdue), upcoming: sum(list.filter(function (b) { return b.state === 'upcoming'; })), paid: sum(paid),
      overdueCount: overdue.length, dueCount: due.length, paidCount: paid.length,
      paidRatio: paid.length / list.length,
      trend: [128, 142, 118, 156, 134, 144], trendLabels: ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'],
      history: paid.concat(list.filter(function (b) { return b.state !== 'paid'; }).slice(0, 2)).map(function (b) {
        return { name: b.name, when: b.dueLabel, amount: b.amount };
      })
    };
  }

  function loan() {
    var ccy = L.currencyCode(), rate = L.RATES[ccy] || 1;
    var f = fieldsFor('loan', {
      principal: Math.round(20000 * rate / 1000) * 1000, rate: 12, years: 5
    });
    var n = Number(f.years) * 12, r = Number(f.rate) / 100 / 12;
    var emi = r ? Number(f.principal) * r * Math.pow(1 + r, n) / (Math.pow(1 + r, n) - 1)
                : Number(f.principal) / n;
    var totalPaid = emi * n, totalInterest = totalPaid - Number(f.principal);

    var balance = Number(f.principal), schedule = [];
    for (var y = 1; y <= Math.min(Number(f.years), 8); y++) {
      var pY = 0, iY = 0;
      for (var m = 0; m < 12 && balance > 0; m++) {
        var interest = balance * r;
        var principal = emi - interest;
        balance -= principal; pY += principal; iY += interest;
      }
      schedule.push({ year: y, principal: pY, interest: iY, balance: Math.max(0, balance) });
    }
    function emiAt(rt) {
      var rr = rt / 100 / 12;
      return rr ? Number(f.principal) * rr * Math.pow(1 + rr, n) / (Math.pow(1 + rr, n) - 1) : Number(f.principal) / n;
    }
    return {
      f: f, ccy: ccy, emi: emi, totalPaid: totalPaid, totalInterest: totalInterest,
      interestShare: totalInterest / totalPaid, schedule: schedule,
      compare: [
        { label: t('loan.rateAt', { r: (Number(f.rate) - 2).toFixed(1) }), sub: t('loan.lowerRate'), emi: emiAt(Number(f.rate) - 2) },
        { label: t('loan.rateAt', { r: Number(f.rate).toFixed(1) }), sub: t('loan.yourRate'), emi: emi },
        { label: t('loan.rateAt', { r: (Number(f.rate) + 2).toFixed(1) }), sub: t('loan.higherRate'), emi: emiAt(Number(f.rate) + 2) }
      ]
    };
  }

  function tipSplit() {
    var ccy = L.currencyCode(), rate = L.RATES[ccy] || 1;
    var s = stateFor('tipsplit');
    var f = fieldsFor('tipsplit', { bill: Math.round(40 * rate), tip: 10, people: 2 });
    if (s.tip !== undefined) f.tip = s.tip;
    var tipAmount = Number(f.bill) * Number(f.tip) / 100;
    var total = Number(f.bill) + tipAmount;
    var each = total / Math.max(1, Number(f.people));
    var custom = [];
    for (var i = 0; i < Number(f.people); i++) {
      custom.push({ name: t('tip.person', { n: i + 1 }), amount: each });
    }
    return { f: f, ccy: ccy, tipAmount: tipAmount, total: total, each: each, custom: custom };
  }

  function ledger() {
    var people = [
      { name: 'Ahmed', initials: 'AH', tone: 'accent', amount: 120, note: t('ledger.note1'), since: relDate(-27), due: relDate(12) },
      { name: 'Sara', initials: 'SA', tone: 'violet', amount: -45, note: t('ledger.note2'), since: relDate(-6), due: null },
      { name: 'Bilal', initials: 'BI', tone: 'amber', amount: 60, note: t('ledger.note3'), since: relDate(-52), due: relDate(-7), overdue: true }
    ];
    var lent = people.filter(function (p) { return p.amount > 0; }).reduce(function (a, p) { return a + p.amount; }, 0);
    var borrowed = -people.filter(function (p) { return p.amount < 0; }).reduce(function (a, p) { return a + p.amount; }, 0);
    return {
      people: people, lent: lent, borrowed: borrowed, net: lent - borrowed,
      entries: [
        { who: 'Ahmed', when: relDate(-27), amount: 120 },
        { who: 'Sara', when: relDate(-6), amount: -45 },
        { who: 'Bilal', when: relDate(-52), amount: 60 }
      ]
    };
  }

  function installments() {
    var plans = [
      { item: 'Laptop', merchant: 'TechMart', logo: 'TM', tone: 'indigo', monthly: 95, total: 12, paidCount: 5, next: relDate(7) },
      { item: 'Sofa set', merchant: 'HomeStore', logo: 'HS', tone: 'amber', monthly: 62, total: 9, paidCount: 7, next: relDate(12) },
      { item: 'Phone', merchant: 'Mobile Hub', logo: 'MH', tone: 'accent', monthly: 48, total: 18, paidCount: 3, next: relDate(20) }
    ];
    var monthly = plans.reduce(function (a, p) { return a + p.monthly; }, 0);
    /* What the monthly commitment falls to as each plan finishes. */
    var months = [], monthLabels = [];
    for (var m = 0; m < 6; m++) {
      months.push(plans.reduce(function (a, p) {
        return a + (p.paidCount + m < p.total ? p.monthly : 0);
      }, 0));
      var d = new Date();
      d.setMonth(d.getMonth() + m);
      monthLabels.push(L.date(d, { month: 'narrow' }));
    }
    return {
      plans: plans, monthly: monthly, months: months, monthLabels: monthLabels,
      history: plans.map(function (p) {
        return { item: p.item, when: t('inst.paidCount', { n: p.paidCount }), amount: p.monthly * p.paidCount };
      }),
      remaining: plans.reduce(function (a, p) { return a + p.monthly * (p.total - p.paidCount); }, 0),
      paid: plans.reduce(function (a, p) { return a + p.monthly * p.paidCount; }, 0),
      nextDate: relDate(7),
      schedule: plans.map(function (p, i) {
        return { date: p.next, item: p.item, merchant: p.merchant, amount: p.monthly, state: i === 0 ? 'now' : '' };
      })
    };
  }

  function committee() {
    var members = [
      { name: 'You', initials: 'ZK', tone: 'accent', paid: true, when: relDate(-7), turn: 7 },
      { name: 'Ahmed', initials: 'AH', tone: 'violet', paid: true, when: relDate(-6), turn: 1 },
      { name: 'Sara', initials: 'SA', tone: 'amber', paid: false, turn: 4 },
      { name: 'Bilal', initials: 'BI', tone: 'sky', paid: true, when: relDate(-7), turn: 2 },
      { name: 'Hina', initials: 'HI', tone: 'rose', paid: false, turn: 9 }
    ];
    return {
      pool: 500, contribution: 100, month: 4, months: 10, members: members, yourTurn: 7,
      collected: [500, 500, 400, 300, 0, 0, 0, 0, 0, 0],
      collectedLabels: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
      history: members.filter(function (m) { return m.paid; }).map(function (m) {
        return { name: m.name, when: m.when, amount: 100 };
      }),
      order: members.slice().sort(function (a, b) { return a.turn - b.turn; }).map(function (m) {
        return { month: t('committee.monthN', { n: m.turn }), name: m.name, you: m.name === 'You',
          state: m.turn < 4 ? 'done' : m.turn === 4 ? 'now' : '' };
      })
    };
  }

  function compound() {
    var ccy = L.currencyCode(), rate = L.RATES[ccy] || 1;
    var f = fieldsFor('compound', {
      initial: Math.round(1000 * rate / 100) * 100, monthly: Math.round(100 * rate / 10) * 10,
      rate: 8, years: 10
    });
    var series = [], table = [], v = Number(f.initial), contributed = Number(f.initial);
    var r = Number(f.rate) / 100 / 12;
    for (var y = 1; y <= Number(f.years); y++) {
      for (var m = 0; m < 12; m++) { v = v * (1 + r) + Number(f.monthly); contributed += Number(f.monthly); }
      series.push(Math.round(v));
      table.push({ year: y, contributed: contributed, value: v });
    }
    return { f: f, ccy: ccy, total: v, contributed: contributed, growth: v - contributed,
      series: series.length > 1 ? series : [Number(f.initial), v], table: table };
  }

  /* ---------------------------------------------------------
     Daily life
     --------------------------------------------------------- */
  function weather() {
    var base = C.weatherFor(P().country, L.timezone());
    var hourlyList = D.hourly(base.temp, P().country.charCodeAt(0) * 31 + P().country.charCodeAt(1));
    var dailyList = D.daily(base.temp, P().country.charCodeAt(0) * 17);
    var lows = dailyList.map(function (d) { return d.lo; });
    var his = dailyList.map(function (d) { return d.hi; });
    var minLo = Math.min.apply(null, lows), maxHi = Math.max.apply(null, his);
    var span = Math.max(1, maxHi - minLo);
    return {
      temp: base.temp, feels: base.feels, desc: base.desc, rain: base.rain, wind: base.wind, icon: base.icon,
      hi: dailyList[0].hi, lo: dailyList[0].lo,
      humidity: Math.min(95, 40 + base.rain), visibility: 10, pressure: 1012,
      gusts: base.wind + 9, uv: base.temp > 30 ? 9 : 5, uvLabel: base.temp > 30 ? t('weather.uvHigh') : t('weather.uvModerate'),
      dew: Math.round(base.temp - 8),
      hourly: hourlyList,
      daily: dailyList.map(function (d) {
        return { icon: d.icon, desc: d.desc, rain: d.rain, hi: d.hi, lo: d.lo,
          lowPct: Math.round((d.lo - minLo) / span * 100), hiPct: Math.round((d.hi - minLo) / span * 100) };
      }),
      alert: base.temp > 38 ? { title: t('weather.alert.heat'), text: t('weather.alert.heatText') } : null
    };
  }

  function loadshed() {
    var now = new Date(), nowM = now.getHours() * 60 + now.getMinutes();
    var slots = D.LOADSHED.map(function (s) {
      var from = parseInt(s.from, 10) * 60 + parseInt(s.from.split(':')[1], 10);
      var to = parseInt(s.to, 10) * 60 + parseInt(s.to.split(':')[1], 10);
      if (to <= from) to += 1440;
      var state = nowM >= to ? 'done' : nowM >= from ? 'now' : 'next';
      return { from: s.from, to: s.to, state: state, fromM: from, toM: to,
        duration: t('duration.h', { h: Math.round((to - from) / 60) }) };
    });
    var current = slots.filter(function (s) { return s.state === 'now'; })[0];
    var next = slots.filter(function (s) { return s.state === 'next'; })[0] || slots[0];
    var mins = current ? current.toM - nowM : Math.max(0, next.fromM - nowM);
    return {
      area: P().city, provider: t('loadshed.provider'),
      now: !!current, slot: current || next,
      slots: slots,
      endsIn: t('duration.hm', { h: Math.floor(mins / 60), m: pad2(mins % 60) }),
      nextIn: t('duration.hm', { h: Math.floor(mins / 60), m: pad2(mins % 60) }),
      hoursToday: L.num(slots.reduce(function (a, s) { return a + (s.toM - s.fromM) / 60; }, 0)),
      reliability: 78, week: [6, 5, 7, 6, 4, 5, 6], todayIndex: (now.getDay() + 6) % 7
    };
  }

  /* Unit names are words, so they carry keys rather than English. */
  var UNIT_CATS = {
    length: { key: 'uc.length', icon: 'i-ruler', units: [
      { short: 'm', key: 'uc.metre', factor: 1 }, { short: 'km', key: 'uc.kilometre', factor: 1000 },
      { short: 'cm', key: 'uc.centimetre', factor: 0.01 }, { short: 'mi', key: 'uc.mile', factor: 1609.34 },
      { short: 'ft', key: 'uc.foot', factor: 0.3048 }, { short: 'in', key: 'uc.inch', factor: 0.0254 } ] },
    mass: { key: 'uc.mass', icon: 'i-scales', units: [
      { short: 'kg', key: 'uc.kilogram', factor: 1 }, { short: 'g', key: 'uc.gram', factor: 0.001 },
      { short: 'lb', key: 'uc.pound', factor: 0.453592 }, { short: 'oz', key: 'uc.ounce', factor: 0.0283495 },
      { short: 'tola', key: 'uc.tola', factor: 0.0116638 } ] },
    volume: { key: 'uc.volume', icon: 'i-droplet', units: [
      { short: 'L', key: 'uc.litre', factor: 1 }, { short: 'mL', key: 'uc.millilitre', factor: 0.001 },
      { short: 'gal', key: 'uc.gallon', factor: 3.78541 }, { short: 'cup', key: 'uc.cup', factor: 0.24 } ] },
    area: { key: 'uc.area', icon: 'i-grid', units: [
      { short: 'm²', key: 'uc.sqmetre', factor: 1 }, { short: 'ft²', key: 'uc.sqfoot', factor: 0.092903 },
      { short: 'ac', key: 'uc.acre', factor: 4046.86 }, { short: 'marla', key: 'uc.marla', factor: 25.2929 } ] },
    speed: { key: 'uc.speed', icon: 'i-navigation', units: [
      { short: 'km/h', key: 'uc.kmh', factor: 1 }, { short: 'mph', key: 'uc.mph', factor: 1.60934 },
      { short: 'm/s', key: 'uc.ms', factor: 3.6 } ] },
    data: { key: 'uc.data', icon: 'i-download', units: [
      { short: 'MB', key: 'uc.megabyte', factor: 1 }, { short: 'GB', key: 'uc.gigabyte', factor: 1024 },
      { short: 'TB', key: 'uc.terabyte', factor: 1048576 } ] }
  };

  function namedUnit(u) { return { short: u.short, label: t(u.key), factor: u.factor }; }

  function converter() {
    var s = stateFor('converter');
    var catId = s.cat || 'length';
    var cat = UNIT_CATS[catId];
    var f = fieldsFor('converter', { amount: 1 });
    var imperial = L.unitSystem() === 'imperial';
    var swapped = !!s.swapped;
    var a = namedUnit(cat.units[0]);
    var b = namedUnit(cat.units[imperial && cat.units.length > 3 ? 3 : 1]);
    var from = swapped ? b : a, to = swapped ? a : b;
    return {
      category: catId, amount: f.amount, from: from, to: to,
      result: Number(f.amount) * from.factor / to.factor,
      units: cat.units.map(namedUnit),
      categories: Object.keys(UNIT_CATS).map(function (k) {
        return { id: k, label: t(UNIT_CATS[k].key), icon: UNIT_CATS[k].icon };
      }),
      recent: [
        { label: '10 km → mi', value: '6.21' },
        { label: '1 kg → lb', value: '2.20' }
      ]
    };
  }

  /* A health verdict must not be English-only. */
  var BMI_BANDS = [
    { max: 18.5, key: 'bmi.band.under', tone: 'info', lo: null, hi: 18.5 },
    { max: 25, key: 'bmi.band.healthy', tone: 'ok', lo: 18.5, hi: 25 },
    { max: 30, key: 'bmi.band.over', tone: 'warn', lo: 25, hi: 30 },
    { max: 99, key: 'bmi.band.obese', tone: 'late', lo: 30, hi: null }
  ];

  function bandRange(b) {
    if (b.lo === null) return '< ' + L.num(b.hi, { maximumFractionDigits: 1 });
    if (b.hi === null) return '> ' + L.num(b.lo, { maximumFractionDigits: 1 });
    return L.num(b.lo, { maximumFractionDigits: 1 }) + ' – ' + L.num(b.hi, { maximumFractionDigits: 1 });
  }

  function bmi() {
    var imperial = L.unitSystem() === 'imperial';
    var f = fieldsFor('bmi', { height: imperial ? 69 : 175, weight: imperial ? 165 : 75 });
    var hM = imperial ? Number(f.height) * 0.0254 : Number(f.height) / 100;
    var kg = imperial ? Number(f.weight) * 0.453592 : Number(f.weight);
    var value = kg / (hM * hM);
    var raw = BMI_BANDS.filter(function (b) { return value < b.max; })[0] || BMI_BANDS[3];
    var band = { label: t(raw.key), tone: raw.tone };
    var lowKg = 18.5 * hM * hM, highKg = 24.9 * hM * hM;
    function w(k) {
      return imperial ? L.num(Math.round(k / 0.453592)) + ' ' + t('unit.lb')
                      : L.num(Math.round(k)) + ' ' + t('unit.kg');
    }
    return {
      f: f, bmi: value, band: band,
      heightUnit: imperial ? 'in' : 'cm', weightUnit: imperial ? 'lb' : 'kg',
      healthyRange: w(lowKg) + ' – ' + w(highKg),
      idealWeight: w((lowKg + highKg) / 2),
      bands: BMI_BANDS.map(function (b) {
        return { label: t(b.key), range: bandRange(b), tone: b.tone, on: b === raw };
      }),
      history: [value + 1.4, value + 1.1, value + 0.6, value + 0.2, value]
    };
  }

  function age() {
    var f = fieldsFor('age', { dob: '1993-04-18' });
    var dob = new Date(f.dob), now = new Date();
    if (isNaN(dob.getTime())) dob = new Date('1993-04-18');
    var years = now.getFullYear() - dob.getFullYear();
    var months = now.getMonth() - dob.getMonth();
    var days = now.getDate() - dob.getDate();
    if (days < 0) { months--; days += new Date(now.getFullYear(), now.getMonth(), 0).getDate(); }
    if (months < 0) { years--; months += 12; }
    var totalDays = Math.floor((now - dob) / 86400000);
    var next = new Date(now.getFullYear(), dob.getMonth(), dob.getDate());
    if (next < now) next.setFullYear(next.getFullYear() + 1);
    return {
      f: f, years: years, months: months, days: days,
      totalDays: totalDays, totalWeeks: Math.floor(totalDays / 7), totalHours: totalDays * 24,
      untilNext: Math.ceil((next - now) / 86400000),
      nextDate: L.date(next, { day: 'numeric', month: 'long' }),
      milestones: [
        { label: t('age.milestone', { n: 10000 }), when: L.date(new Date(dob.getTime() + 10000 * 86400000), { day: 'numeric', month: 'short', year: 'numeric' }) },
        { label: t('age.milestone', { n: 15000 }), when: L.date(new Date(dob.getTime() + 15000 * 86400000), { day: 'numeric', month: 'short', year: 'numeric' }) },
        { label: t('age.milestone', { n: 20000 }), when: L.date(new Date(dob.getTime() + 20000 * 86400000), { day: 'numeric', month: 'short', year: 'numeric' }) }
      ]
    };
  }

  function dateCalc() {
    var s = stateFor('datecalc');
    var mode = s.mode || 'diff';
    var f = fieldsFor('datecalc', { from: isoToday(), to: isoToday(), days: 30 });
    var a = new Date(f.from), b = mode === 'diff' ? new Date(f.to) : new Date(new Date(f.from).getTime() + Number(f.days) * 86400000);
    if (isNaN(a.getTime())) a = new Date();
    if (isNaN(b.getTime())) b = new Date();
    var diff = Math.round((b - a) / 86400000);
    var abs = Math.abs(diff);
    var weekdays = 0, weekends = 0;
    for (var i = 0; i < Math.min(abs, 4000); i++) {
      var d = new Date(Math.min(a, b) + i * 86400000);
      if (d.getDay() === 0 || d.getDay() === 6) weekends++; else weekdays++;
    }
    return {
      mode: mode, f: f,
      headline: mode === 'diff' ? abs + ' ' + t('common.days') : L.date(b, { day: 'numeric', month: 'long', year: 'numeric' }),
      caption: mode === 'diff'
        ? L.date(a, { day: 'numeric', month: 'short' }) + ' → ' + L.date(b, { day: 'numeric', month: 'short' })
        : t('datecalc.fromStart', { n: f.days }),
      stats: [
        { value: Math.floor(abs / 7) + '', label: t('common.weeks') },
        { value: (abs / 30.44).toFixed(1), label: t('common.months') },
        { value: (abs / 365.25).toFixed(2), label: t('common.years') }
      ],
      weekdays: weekdays, weekends: weekends, holidays: D.holidaysFor(P().country).length
    };
  }

  function passportSpecs() {
    var country = L.countryName(P().country);
    return [
      { label: t('passport.country'), value: country },
      { label: t('passport.size'), value: P().country === 'US' ? '2 × 2 in' : '35 × 45 mm' },
      { label: t('passport.background'), value: t('passport.white') },
      { label: t('passport.headHeight'), value: P().country === 'US' ? '1 – 1⅜ in' : '32 – 36 mm' }
    ];
  }

  function savedMedia() {
    return [
      { title: t('media.item1'), tone: 'violet', glyph: '🎬', size: '18 MB' },
      { title: t('media.item2'), tone: 'accent', glyph: '📷', size: '3.2 MB' },
      { title: t('media.item3'), tone: 'amber', glyph: '🎵', size: '6.8 MB' }
    ];
  }

  /* §105 — a vehicle's statutory costs vary by market, so they live in a
     configuration keyed by country rather than in an `if` inside the screen.
     Figures are authored in USD and converted like every other amount. */
  var VEHICLE_COSTS = {
    PK: { tokenCar: 43, tokenBike: 6, insurance: 150 },
    GB: { tokenCar: 235, tokenBike: 30, insurance: 620 },
    US: { tokenCar: 90, tokenBike: 25, insurance: 1400 },
    IN: { tokenCar: 60, tokenBike: 10, insurance: 180 },
    AE: { tokenCar: 110, tokenBike: 25, insurance: 400 },
    SA: { tokenCar: 80, tokenBike: 20, insurance: 320 }
  };
  var VEHICLE_FALLBACK = { tokenCar: 120, tokenBike: 25, insurance: 480 };

  function vehicleCosts() {
    var cfg = VEHICLE_COSTS[P().country] || VEHICLE_FALLBACK;
    return { ccy: L.currencyCode(), tokenCar: cfg.tokenCar, tokenBike: cfg.tokenBike, insurance: cfg.insurance };
  }

  function speedTest() {
    var s = stateFor('speedtest');
    var down = s.down || 48.2;
    return {
      down: down, up: down * 0.42, ping: 18, pct: Math.min(1, down / 200),
      type: t('speed.wifi'), server: P().city + ' · ' + L.countryName(P().country), isp: t('speed.yourIsp'),
      history: [
        { when: t('common.today'), type: t('speed.wifi'), down: 48.2, ping: 18, series: [40, 44, 47, 48, 48.2] },
        { when: t('common.yesterday'), type: t('speed.mobile'), down: 22.4, ping: 42, series: [18, 20, 21, 22, 22.4] }
      ]
    };
  }

  function worldClock() {
    var now = new Date();
    return D.WORLD_CITIES.map(function (z) {
      var parts;
      try {
        parts = new Intl.DateTimeFormat(L.locale(), {
          timeZone: z.tz, hour: 'numeric', minute: '2-digit', hour12: L.clock() === 12, weekday: 'short'
        }).formatToParts(now);
      } catch (e) { parts = null; }
      var time = '—', period = '', dayLabel = '';
      if (parts) {
        var h = '', m = '';
        parts.forEach(function (p) {
          if (p.type === 'hour') h = p.value;
          if (p.type === 'minute') m = p.value;
          if (p.type === 'dayPeriod') period = p.value;
          if (p.type === 'weekday') dayLabel = p.value;
        });
        time = h + ':' + m;
      }
      var offset = 0;
      try {
        var local = new Date(now.toLocaleString('en-US', { timeZone: L.timezone() }));
        var there = new Date(now.toLocaleString('en-US', { timeZone: z.tz }));
        offset = Math.round((there - local) / 3600000);
      } catch (e) {}
      return { city: z.city, tz: z.tz, cc: z.cc, time: time, period: period, dayLabel: dayLabel,
        offsetLabel: offset === 0 ? t('clock.sameTime') : (offset > 0 ? '+' : '') + offset + 'h' };
    });
  }

  /* ---------------------------------------------------------
     Personal
     --------------------------------------------------------- */
  function expenses() {
    var budget = (C.BUDGET[P().country] || 1200);
    var rate = L.RATES[L.currencyCode()] || 1;
    var budgetUsd = budget / (L.RATES[L.country().currency] || 1);
    var spent = budgetUsd * 0.53;
    var byCat = D.EXPENSE_CATEGORIES.map(function (x) {
      return { label: x.label, amount: spent * x.share, color: x.color, id: x.id, icon: x.icon };
    });
    var catLabel = {};
    D.EXPENSE_CATEGORIES.forEach(function (x) { catLabel[x.id] = x; });
    return {
      spent: spent, budget: budgetUsd, ratio: 0.53, income: budgetUsd * 1.24,
      balance: budgetUsd * 0.71, dailyAvg: spent / new Date().getDate(),
      categories: byCat,
      trend: [42, 55, 38, 61, 48, 52, 44], trendLabels: weekLabels(),
      transactions: D.TRANSACTIONS.map(function (tx, i) {
        var cat = catLabel[tx.cat] || { label: tx.cat, icon: 'i-grid' };
        /* `order` is what "sort by date" sorts on; the list is authored
           newest-first, so position is the recency key. */
        return { title: tx.title, catId: tx.cat, catLabel: cat.label, icon: cat.icon,
          amount: tx.amount, when: tx.when, method: tx.method, income: tx.income,
          order: D.TRANSACTIONS.length - i };
      }),
      budgets: byCat.slice(0, 4).map(function (x) {
        return { label: x.label, spent: x.amount, limit: x.amount * (1 + (x.id === 'bills' ? -0.08 : 0.35)) };
      }),
      recurring: [
        { label: t('expenses.rec1'), when: t('expenses.monthlyOn', { day: 3 }), amount: 28 },
        { label: t('expenses.rec2'), when: t('expenses.monthlyOn', { day: 12 }), amount: 74 }
      ],
      insights: [
        { icon: 'i-trending', title: t('expenses.insight1.title'), text: t('expenses.insight1.text') },
        { icon: 'i-target', title: t('expenses.insight2.title'), text: t('expenses.insight2.text') }
      ]
    };
  }

  function goals() {
    var list = D.GOALS.map(function (g) {
      return { name: g.name, target: g.target, saved: g.saved, by: g.by, icon: g.icon, tone: g.tone,
        pct: g.saved / g.target, monthly: g.monthly,
        projected: t('goals.projectedDate', { n: Math.ceil((g.target - g.saved) / g.monthly) }) };
    });
    var saved = list.reduce(function (a, g) { return a + g.saved; }, 0);
    var target = list.reduce(function (a, g) { return a + g.target; }, 0);
    return {
      list: list, saved: saved, target: target, ratio: saved / target,
      monthly: list.reduce(function (a, g) { return a + g.monthly; }, 0),
      nextComplete: list.slice().sort(function (a, b) { return b.pct - a.pct; })[0].by,
      history: [280, 320, 410, 380, 430, 430], historyLabels: ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep']
    };
  }

  function subscriptions() {
    var monthly = D.SUBSCRIPTIONS.reduce(function (a, s) {
      return a + (s.cycle === 'Yearly' ? s.price / 12 : s.price);
    }, 0);
    var byCat = {};
    D.SUBSCRIPTIONS.forEach(function (s) {
      var v = s.cycle === 'Yearly' ? s.price / 12 : s.price;
      byCat[s.cat] = (byCat[s.cat] || 0) + v;
    });
    var colors = ['var(--accent)', 'var(--violet)', 'var(--amber)', 'var(--sky)', 'var(--rose)'];
    return {
      list: D.SUBSCRIPTIONS.slice().sort(function (a, b) { return a.days - b.days; }),
      monthly: monthly, yearly: monthly * 12,
      next: D.SUBSCRIPTIONS.slice().sort(function (a, b) { return a.days - b.days; })[0],
      byCategory: Object.keys(byCat).map(function (k, i) {
        return { label: k, value: byCat[k], color: colors[i % colors.length], display: L.money(byCat[k]) };
      })
    };
  }

  var DOC_ICONS = { Identity: 'i-user', Vehicle: 'i-car', Insurance: 'i-shield',
    Property: 'i-home', Education: 'i-graduation' };

  function documents() {
    var list = D.DOCUMENTS.map(function (d) {
      var tone = d.days === null ? null : d.days < 0 ? 'warn' : d.days < 45 ? 'warn' : null;
      return {
        name: d.name, cat: d.cat, num: d.num, expires: d.expires, days: d.days,
        holder: d.holder, files: d.files, icon: DOC_ICONS[d.cat] || 'i-folder', tone: tone,
        badge: d.days === null ? { label: t('docs.noExpiry'), tone: 'neutral' }
             : d.days < 0 ? { label: t('docs.expired'), tone: 'late' }
             : d.days < 45 ? { label: t('docs.expiringSoonShort'), tone: 'warn' }
             : { label: t('docs.valid'), tone: 'ok' }
      };
    });
    var cats = {};
    list.forEach(function (d) { cats[d.cat] = (cats[d.cat] || 0) + 1; });
    var groups = [
      { label: t('docs.needsAttention'), items: list.filter(function (d) { return d.days !== null && d.days < 45; }) },
      { label: t('docs.valid'), items: list.filter(function (d) { return d.days === null || d.days >= 45; }) }
    ].filter(function (g) { return g.items.length; });
    return {
      list: list, groups: groups,
      categories: Object.keys(cats).map(function (k) { return { id: k, label: k, n: cats[k] }; }),
      expiring: list.filter(function (d) { return d.days !== null && d.days >= 0 && d.days < 45; }).length,
      expired: list.filter(function (d) { return d.days !== null && d.days < 0; }).length,
      files: list.reduce(function (a, d) { return a + d.files; }, 0)
    };
  }

  function health() {
    var s = stateFor('health');
    var id = s.person || 'you';
    var person = D.HEALTH_PEOPLE.filter(function (p) { return p.id === id; })[0] || D.HEALTH_PEOPLE[0];
    var records = D.HEALTH_RECORDS.filter(function (r) { return r.person === id; });
    var kinds = {};
    records.forEach(function (r) { kinds[r.kind] = (kinds[r.kind] || 0) + 1; });
    var upcoming = records.filter(function (r) { return r.state === 'upcoming'; });
    return {
      people: D.HEALTH_PEOPLE, selected: id, person: person,
      records: records, upcoming: upcoming.length,
      nextLabel: upcoming.length ? t('health.next', { title: upcoming[0].title, date: upcoming[0].date })
                                 : t('health.noUpcoming'),
      kinds: Object.keys(kinds).map(function (k) { return { id: k, label: k, n: kinds[k] }; }),
      spend: records.reduce(function (a, r) { return a + (r.cost || 0); }, 0),
      vitals: [78, 77.4, 76.8, 76.2, 75.6, 75],
      vaccineDue: D.VACCINES.filter(function (v) { return v.person === id && v.state === 'due'; }).length
    };
  }

  function vaccines() {
    var s = stateFor('vaccines');
    var id = s.person || 'child';
    var list = D.VACCINES.filter(function (v) { return v.person === id; });
    return {
      selected: id, list: list,
      done: list.filter(function (v) { return v.state === 'done'; }).length,
      total: Math.max(1, list.length),
      due: list.filter(function (v) { return v.state === 'due'; }).length
    };
  }

  function meds() {
    var now = new Date(), h = now.getHours();
    var today = [
      { at: L.time(8, 0), name: 'Metformin', dose: '500 mg', state: h >= 8 ? 'done' : '' },
      { at: L.time(9, 0), name: 'Vitamin D', dose: '50,000 IU', state: h >= 9 ? 'done' : '' },
      { at: L.time(20, 0), name: 'Metformin', dose: '500 mg', state: h >= 20 ? 'done' : 'now' }
    ];
    var next = today.filter(function (d) { return d.state !== 'done'; })[0] || today[0];
    return {
      today: today, next: next,
      adherence: D.MEDS.reduce(function (a, m) { return a + (m.adherence || 0); }, 0) /
                 D.MEDS.filter(function (m) { return m.adherence !== null; }).length
    };
  }

  function todos() {
    var s = stateFor('todos');
    if (!s.done) s.done = {};
    var today = [
      { id: 't1', label: t('todos.item1'), list: t('todos.listWork'), due: L.time(14, 0), priority: 'high' },
      { id: 't2', label: t('todos.item2'), list: t('todos.listHome'), due: L.time(18, 0) },
      { id: 't3', label: t('todos.item3'), list: t('todos.listWork') },
      { id: 't4', label: t('todos.item4'), list: t('todos.listPersonal') }
    ].map(function (x) { x.done = !!s.done[x.id]; return x; });
    return {
      today: today, doneToday: today.filter(function (x) { return x.done; }).length,
      overdue: 1, done7: 12,
      upcoming: [
        { label: t('todos.item5'), list: t('todos.listHome'), due: dayName(1) },
        { label: t('todos.item6'), list: t('todos.listWork'), due: dayName(2) }
      ],
      lists: [
        { label: t('todos.listWork'), icon: 'i-grid', open: 5 },
        { label: t('todos.listHome'), icon: 'i-home', open: 3 },
        { label: t('todos.listPersonal'), icon: 'i-user', open: 2 }
      ]
    };
  }

  function notes() {
    var all = [
      { title: t('notes.n1'), excerpt: t('notes.n1x'), folder: t('notes.fWork'), when: t('common.today'), pinned: 1 },
      { title: t('notes.n2'), excerpt: t('notes.n2x'), folder: t('notes.fPersonal'), when: t('common.yesterday'), pinned: 1 },
      { title: t('notes.n3'), excerpt: t('notes.n3x'), folder: t('notes.fIdeas'), when: relDate(-4) },
      { title: t('notes.n4'), excerpt: t('notes.n4x'), folder: t('notes.fWork'), when: relDate(-6) }
    ];
    return {
      all: all, pinned: all.filter(function (n) { return n.pinned; }),
      folders: [
        { label: t('notes.fWork'), n: 5 }, { label: t('notes.fPersonal'), n: 4 },
        { label: t('notes.fIdeas'), n: 3 }
      ]
    };
  }

  function reminders() {
    var now = new Date().getHours();
    var all = [
      { at: L.time(9, 0), label: t('reminders.r1'), repeat: t('reminders.daily'), state: now >= 9 ? 'done' : '' },
      { at: L.time(14, 0), label: t('reminders.r2'), repeat: t('reminders.once'), state: now >= 14 ? 'done' : 'now' },
      { at: L.time(18, 30), label: t('reminders.r3'), repeat: t('reminders.weekly'), state: '' },
      { at: L.time(21, 0), label: t('reminders.r4'), repeat: t('reminders.daily'), state: '' }
    ];
    return { all: all, today: all, next: all.filter(function (r) { return r.state !== 'done'; })[0] };
  }

  function events() {
    return [
      { title: t('events.e1'), where: t('events.w1'), when: L.time(14, 0) + ' · ' + t('common.today'), people: t('events.people', { n: 6 }) },
      { title: t('events.e2'), where: t('events.w2'), when: dayName(2), people: t('events.people', { n: 12 }) },
      { title: t('events.e3'), where: t('events.w3'), when: dayName(5), people: t('events.people', { n: 3 }) }
    ];
  }

  function calendar() {
    var s = stateFor('calendar');
    var st = P().islamic ? prayerState() : null;
    var agenda = [
      { time: L.time(9, 0), title: t('calendar.a1'), sub: t('calendar.a1s'), state: 'done', icon: 'i-check-circle' },
      { time: L.time(14, 0), title: t('calendar.a2'), sub: t('calendar.a2s'), state: 'now', icon: 'i-users' },
      { time: L.time(18, 30), title: t('calendar.a3'), sub: t('calendar.a3s'), state: '', icon: 'i-cart' }
    ];
    if (st) {
      agenda.push({ time: L.time(st.next.h, st.next.m), title: t('prayer.' + st.next.key),
        sub: t('prayer.next'), state: '', icon: 'i-prayer' });
      agenda.sort(function (a, b) { return a.time > b.time ? 1 : -1; });
    }
    return { view: s.view || 'month', agenda: agenda, holidays: D.holidaysFor(P().country).slice(0, 4) };
  }

  function shopping() {
    var s = stateFor('shopping');
    if (!s.done) s.done = { s3: true, s6: true };
    var items = [
      { id: 's1', label: t('shop.i1'), qty: '2 kg', price: 4, group: t('shop.gProduce') },
      { id: 's2', label: t('shop.i2'), qty: '1 L', price: 2, group: t('shop.gDairy') },
      { id: 's3', label: t('shop.i3'), qty: '500 g', price: 6, group: t('shop.gDairy') },
      { id: 's4', label: t('shop.i4'), qty: '1', price: 3, group: t('shop.gProduce') },
      { id: 's5', label: t('shop.i5'), qty: '2', price: 8, group: t('shop.gHousehold') },
      { id: 's6', label: t('shop.i6'), qty: '1 pack', price: 5, group: t('shop.gHousehold') }
    ].map(function (x) { x.done = !!s.done[x.id]; return x; });
    var groups = {};
    items.forEach(function (i) { (groups[i.group] = groups[i.group] || []).push(i); });
    return {
      items: items,
      checked: items.filter(function (i) { return i.done; }).length,
      remaining: items.filter(function (i) { return !i.done; }).length,
      estimate: items.reduce(function (a, i) { return a + i.price; }, 0),
      groups: Object.keys(groups).map(function (k) { return { label: k, items: groups[k] }; })
    };
  }

  function birthdays() {
    var list = [
      { name: 'Ayesha', initials: 'AY', tone: 'rose', kind: t('birthdays.birthday'), days: 4, date: relDate(4), turning: 29 },
      { name: t('birthdays.anniversary'), initials: 'ZS', tone: 'accent', kind: t('birthdays.anniversary'), days: 18, date: relDate(18), turning: 6 },
      { name: 'Musa', initials: 'MU', tone: 'sky', kind: t('birthdays.birthday'), days: 51, date: relDate(51), turning: 5 },
      { name: 'Ammi', initials: 'AM', tone: 'violet', kind: t('birthdays.birthday'), days: 88, date: relDate(88), turning: 61 }
    ];
    return { list: list, next: list[0], thisMonth: 2 };
  }

  function habits() {
    var list = [
      { name: t('habits.h1'), days: [1, 1, 0, 1, 1, 1, 1], streak: 4 },
      { name: t('habits.h2'), days: [1, 1, 1, 1, 0, 1, 1], streak: 2 },
      { name: t('habits.h3'), days: [0, 1, 1, 1, 1, 1, 0], streak: 0 },
      { name: t('habits.h4'), days: [1, 1, 1, 1, 1, 1, 1], streak: 12 }
    ];
    return {
      list: list, doneToday: list.filter(function (h) { return h.days[6]; }).length,
      streak: 12, best: 28, rate: 0.82,
      heat: heatDays(35, 7731, 0.3),
      insights: [
        { icon: 'i-trending', title: t('habits.insight1.title'), text: t('habits.insight1.text') },
        { icon: 'i-clock', title: t('habits.insight2.title'), text: t('habits.insight2.text') }
      ]
    };
  }

  function streaks() {
    return {
      current: 12, best: 28, thisMonth: 21, rate: 0.78, nextMilestone: 14,
      heat: heatDays(35, 5521, 0.28),
      milestones: [
        { label: t('streak.m7'), done: true }, { label: t('streak.m14'), done: false, inDays: 2 },
        { label: t('streak.m30'), done: false, inDays: 18 }, { label: t('streak.m100'), done: false, inDays: 88 }
      ]
    };
  }

  function water() {
    var s = stateFor('water');
    if (s.ml === undefined) s.ml = 1250;
    var imperial = L.unitSystem() === 'imperial';
    var target = 2000;
    function label(ml) {
      return imperial ? (ml / 29.574).toFixed(0) + ' ' + t('unit.floz')
                      : (ml / 1000).toFixed(1) + ' ' + t('unit.litre');
    }
    return {
      pct: Math.min(1, s.ml / target), target: target,
      consumedLabel: label(s.ml), targetLabel: label(target),
      remainingLabel: label(Math.max(0, target - s.ml)),
      glasses: Math.round(s.ml / 250), streak: 6,
      unitSmall: imperial ? '8 ' + t('unit.floz') : '250 ml',
      unitLarge: imperial ? '17 ' + t('unit.floz') : '500 ml',
      log: [
        { at: L.time(8, 10), amount: '250 ml', kind: t('water.kindWater') },
        { at: L.time(10, 30), amount: '500 ml', kind: t('water.kindWater') },
        { at: L.time(13, 5), amount: '250 ml', kind: t('water.kindTea') },
        { at: L.time(15, 40), amount: '250 ml', kind: t('water.kindWater') }
      ],
      week: [1800, 2100, 1650, 2000, 1900, 2200, 1250]
    };
  }

  function mealPlan() {
    var days = [];
    for (var i = 0; i < 7; i++) {
      var recipes = [D.RECIPES[i % D.RECIPES.length], D.RECIPES[(i + 2) % D.RECIPES.length], D.RECIPES[(i + 4) % D.RECIPES.length]];
      days.push({
        label: i === 0 ? t('common.today') : dayName(i), today: i === 0,
        summary: recipes[1].name,
        meals: [
          { slot: t('meal.breakfast'), recipe: recipes[0].name, kcal: recipes[0].kcal, icon: 'i-sun' },
          { slot: t('meal.lunch'), recipe: recipes[1].name, kcal: recipes[1].kcal, icon: 'i-utensils' },
          { slot: t('meal.dinner'), recipe: recipes[2].name, kcal: recipes[2].kcal, icon: 'i-moon' }
        ]
      });
    }
    return {
      days: days, planned: 18, slots: 21, kcal: 1980, shopItems: 24, cost: 96,
      kcalByDay: days.map(function (d) {
        return d.meals.reduce(function (a, m) { return a + m.kcal; }, 0);
      })
    };
  }

  function alarms() {
    var list = [
      { id: 'a1', at: L.time(6, 30), label: t('alarms.a1'), repeat: t('alarms.weekdays'), on: true },
      { id: 'a2', at: L.time(7, 15), label: t('alarms.a2'), repeat: t('alarms.weekend'), on: false },
      { id: 'a3', at: L.time(22, 30), label: t('alarms.a3'), repeat: t('alarms.daily'), on: true }
    ];
    var next = list.filter(function (a) { return a.on; })[0];
    if (next) next.inLabel = t('alarms.inHours', { n: 8 });
    return { list: list, next: next };
  }

  function learning() {
    return {
      minutes: 185, streak: 9, weekPct: 0.74, milestone: t('learning.milestoneValue'),
      week: [20, 35, 0, 40, 25, 35, 30],
      heat: heatDays(35, 6612, 0.32),
      insights: [
        { icon: 'i-clock', title: t('learning.insight1.title'), text: t('learning.insight1.text') },
        { icon: 'i-trending', title: t('learning.insight2.title'), text: t('learning.insight2.text') }
      ]
    };
  }

  function babyBudget() {
    var monthly = 320;
    return {
      monthly: monthly, ratio: 0.82,
      trend: [280, 305, 290, 340, 310, 320],
      trendLabels: ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'],
      oneOff: [
        { label: t('baby.o1'), amount: 420, when: t('baby.oneOffWhen') },
        { label: t('baby.o2'), amount: 260, when: t('baby.oneOffWhen') }
      ],
      categories: [
        { label: t('baby.c1'), value: 120, color: 'var(--accent)' },
        { label: t('baby.c2'), value: 80, color: 'var(--violet)' },
        { label: t('baby.c3'), value: 70, color: 'var(--amber)' },
        { label: t('baby.c4'), value: 50, color: 'var(--sky)' }
      ],
      upcoming: [
        { label: t('baby.u1'), when: dayName(6), amount: 65 },
        { label: t('baby.u2'), when: dayName(14), amount: 140 }
      ]
    };
  }

  function cycle() {
    var day = (new Date().getDate() % 28) + 1;
    var phase = day <= 5 ? t('cycle.menstrual') : day <= 13 ? t('cycle.follicular')
              : day <= 16 ? t('cycle.ovulation') : t('cycle.luteal');
    return {
      day: day, length: 28, phaseLabel: phase,
      history: [
        { month: t('cycle.lastMonth'), length: 28, note: t('cycle.regular') },
        { month: t('cycle.twoMonths'), length: 29, note: t('cycle.regular') },
        { month: t('cycle.threeMonths'), length: 27, note: t('cycle.regular') }
      ]
    };
  }

  function pregnancy() {
    var week = 22;
    return {
      week: week, dueDate: relDate(126),
      trimesterLabel: t('pregnancy.trimester', { n: 2 }),
      note: t('pregnancy.note22'),
      size: t('pregnancy.sizeValue'), weight: '430 g',
      appointments: [
        { when: relDate(10), title: t('pregnancy.scan'), who: t('pregnancy.clinic'), state: 'now' },
        { when: relDate(38), title: t('pregnancy.checkup'), who: t('pregnancy.clinic'), state: '' }
      ],
      milestones: [
        { week: 12, label: t('pregnancy.m12'), done: week >= 12 },
        { week: 20, label: t('pregnancy.m20'), done: week >= 20 },
        { week: 28, label: t('pregnancy.m28'), done: week >= 28 },
        { week: 37, label: t('pregnancy.m37'), done: week >= 37 }
      ],
      weightSeries: [58, 59.4, 61, 62.8, 64.1, 65.2]
    };
  }

  function stopwatch() {
    var s = stateFor('stopwatch');
    return { display: s.display || '00:00.00', laps: s.laps || [] };
  }

  function timer() {
    var s = stateFor('timer');
    return {
      display: s.display || '00:00',
      presets: [{ label: '1 ' + t('unit.min'), secs: 60 }, { label: '5 ' + t('unit.min'), secs: 300 },
                { label: '10 ' + t('unit.min'), secs: 600 }, { label: '25 ' + t('unit.min'), secs: 1500 }],
      history: [{ label: '25 ' + t('unit.min'), when: t('common.today') }, { label: '5 ' + t('unit.min'), when: t('common.yesterday') }]
    };
  }

  function focus() {
    var s = stateFor('focus');
    return {
      display: s.display || '25:00', session: s.session || 1, of: 4,
      todayMins: 75, streak: 5, sessions: 3, week: [50, 75, 25, 100, 50, 75, 75]
    };
  }

  function calcHistory() {
    var s = stateFor('calculator');
    return s.history || [];
  }

  /* ---------------------------------------------------------
     Factory
     --------------------------------------------------------- */
  return function (id) {
    var f = deps.featureFor(id);
    if (!f) return null;
    var spec = SPEC.get(id);
    var s = stateFor(id);

    return {
      /* identity */
      id: id, f: f, spec: spec, profile: P(),
      /* services */
      UI: UI, D: D, L: L, t: t, esc: UI.esc,
      fname: deps.fname, featureFor: deps.featureFor, isVisible: deps.isVisible,
      /* state */
      state: function (k) { return s[k]; },
      setState: function (k, v) { s[k] = v; },

      /* §88 — the value a filter group currently holds, defaulted by the
         screen rather than by this module. */
      filter: function (group, fallback) {
        return s[group] === undefined ? fallback : s[group];
      },

      /* §89 — sorting is a dimension plus a direction. Tapping the active
         dimension flips it; the chip carries the next direction with it. */
      sortState: function (fallbackBy, fallbackDir) {
        var raw = s.sort;
        if (!raw) return { by: fallbackBy, dir: fallbackDir || 'desc' };
        var parts = String(raw).split('|');
        return { by: parts[0], dir: parts[1] || fallbackDir || 'desc' };
      },

      /* Sort a list by a named accessor, honouring the current direction. */
      sortBy: function (list, accessors, fallbackBy, fallbackDir) {
        var st = this.sortState(fallbackBy, fallbackDir);
        var get = accessors[st.by] || accessors[fallbackBy];
        if (!get) return list;
        var dir = st.dir === 'asc' ? 1 : -1;
        return list.slice().sort(function (a, b) {
          var x = get(a), y = get(b);
          if (typeof x === 'string' || typeof y === 'string') {
            return String(x).localeCompare(String(y)) * dir;
          }
          return (x - y) * dir;
        });
      },

      /* Build the items a sortBar needs, marking the active dimension. */
      sortItems: function (dims, fallbackBy, fallbackDir) {
        var st = this.sortState(fallbackBy, fallbackDir);
        return dims.map(function (d) {
          return { value: d.value, label: d.label, on: d.value === st.by, dir: d.value === st.by ? st.dir : null };
        });
      },
      field: function (k) { return (FIELDS[id] || {})[k]; },
      setField: function (k, v) { setField(id, k, v); },
      /* formatting */
      /* A percentage is a number: it takes the locale's separators and
         digits, not `toFixed` and an ASCII dot. */
      pct: function (n, dp) {
        var d = dp === undefined ? 2 : dp;
        return (n > 0 ? '+' : n < 0 ? '−' : '') +
          L.num(Math.abs(n), { minimumFractionDigits: d, maximumFractionDigits: d }) + '%';
      },
      signed: function (n, dp) {
        var d = dp === undefined ? 2 : dp;
        return (n > 0 ? '+' : n < 0 ? '−' : '') +
          L.num(Math.abs(n), { minimumFractionDigits: d, maximumFractionDigits: d });
      },
      /* Cardinal letters are language, and the decimals are numbers. */
      coords: function (lat, lon) {
        function one(v, pos, neg) {
          return L.num(Math.abs(v), { maximumFractionDigits: 4 }) + '° ' + t(v >= 0 ? pos : neg);
        }
        return one(lat, 'compass.n', 'compass.s') + ', ' + one(lon, 'compass.e', 'compass.w');
      },
      money: function (usd, o) { return L.money(usd, o); },
      moneyRaw: function (v, ccy, dp) { return L.moneyRaw(v, ccy, dp); },
      num: function (n, o) { return L.num(n, o); },
      date: function (d, o) { return L.date(d, o); },
      dateLong: function (d) { return L.dateLong(d); },
      time: function (h, m) { return L.time(h, m); },
      dayName: dayName, weekLabels: weekLabels, clockNow: clockNow,
      isoToday: isoToday, dayIndex: dayIndex, monthGrid: monthGrid,
      /* faith */
      prayerTimes: prayerTimes, prayerState: prayerState, upcomingPrayerDays: upcomingPrayerDays,
      sunTimes: sunTimes, hijri: hijri, qibla: qibla, nearbyMosques: nearbyMosques,
      prayerTracker: prayerTracker, ramadan: ramadan, fasting: fasting,
      ayahOfDay: ayahOfDay, quranProgress: quranProgress, quranSearch: quranSearch,
      tasbih: tasbih, zakat: zakat, faraid: faraid,
      /* money */
      exchange: exchange, marketSession: marketSession, metals: metals, currencyBoard: currencyBoard,
      fuelCost: fuelCost, tax: tax, bills: bills, loan: loan, tipSplit: tipSplit,
      ledger: ledger, installments: installments, committee: committee, compound: compound,
      /* daily life */
      weather: weather, loadshed: loadshed, converter: converter, bmi: bmi, age: age,
      dateCalc: dateCalc, passportSpecs: passportSpecs, savedMedia: savedMedia,
      speedTest: speedTest, worldClock: worldClock, vehicleCosts: vehicleCosts,
      /* personal */
      expenses: expenses, goals: goals, subscriptions: subscriptions, documents: documents,
      health: health, vaccines: vaccines, meds: meds, todos: todos, notes: notes,
      reminders: reminders, events: events, calendar: calendar, shopping: shopping,
      birthdays: birthdays, habits: habits, streaks: streaks, water: water,
      mealPlan: mealPlan, alarms: alarms, learning: learning, babyBudget: babyBudget,
      cycle: cycle, pregnancy: pregnancy,
      stopwatch: stopwatch, timer: timer, focus: focus, calcHistory: calcHistory,
      /* internals the shell needs */
      _state: STATE, _fields: FIELDS, _setField: setField
    };
  };
};
