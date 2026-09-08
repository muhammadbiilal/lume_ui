/* ============================================================
   Lume — Daily Life screens  (Master Spec §39–§56, §80)

   Four different information architectures live in this file
   on purpose (§113):

     Weather   → environmental dashboard
     Flights   → live board + map
     News      → editorial feed, images carry information
     Emergency → action interface, deliberately low density

   None of them share a layout; all of them share the design
   language.
   ============================================================ */
(function () {
  'use strict';

  var UI = window.LUME_UI;
  var D = window.LUME_DATA;
  var T = window.LUME_TOOLS;

  function pad2(n) { return n < 10 ? '0' + n : '' + n; }

  /* ---------------------------------------------------------
     §40 Weather — environmental dashboard
     --------------------------------------------------------- */
  T.register('weather', function (c) {
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
  });

  /* ---------------------------------------------------------
     §80 Air quality explorer
     --------------------------------------------------------- */
  T.register('aqi', function (c) {
    var aq = D.aqiFor(c.profile.country);
    return UI.section({ flush: true, body: UI.contextBar([{ icon: 'i-pin', label: c.profile.city }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('aqi.index'),
        value: String(aq.value),
        caption: UI.statusBadge({ label: c.t(aq.band.key + '.label'), tone: aq.band.tone }),
        aside: UI.progressRing({ value: Math.min(1, aq.value / 300), centre: String(aq.value), label: c.t('aqi.index') })
      }) }) +
      UI.section({ body: UI.noteCard({ tone: aq.band.tone === 'ok' ? 'ok' : 'warn', icon: 'i-info',
        title: c.t('aqi.advice'), text: c.t(aq.band.key + '.advice') }) }) +
      UI.section({ title: c.t('aqi.pollutants'), body: UI.rows(aq.parts.map(function (p) {
        return UI.richRow({ icon: 'i-wind', title: p.n, sub: c.t('aqi.measured'),
          value: String(p.v), valueSub: p.unit });
      })) }) +
      UI.section({ title: c.t('aqi.trend'), body: UI.card(
        UI.lineChart({ values: D.walk(aq.value, 24, aq.value, 0.08), labels: [c.t('range.24h'), c.t('range.12h'), c.t('common.now')],
          label: c.t('aqi.trend') })) });
  });

  /* ---------------------------------------------------------
     §80 Sun & moon
     --------------------------------------------------------- */
  T.register('sunmoon', function (c) {
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
  });

  /* ---------------------------------------------------------
     §41 Loadshedding — schedule dashboard
     --------------------------------------------------------- */
  T.register('loadshed', function (c) {
    var ls = c.loadshed();
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: ls.area, act: 'sheet:personalise' },
        { label: ls.provider }]) }) +
      UI.section({ body: UI.summaryCard({
        tone: ls.now ? 'warn' : 'accent',
        kicker: ls.now ? c.t('loadshed.currentlyOff') : c.t('loadshed.currentlyOn'),
        value: ls.now ? ls.endsIn : ls.nextIn,
        caption: ls.now ? c.t('loadshed.powerBack', { time: ls.slot.to })
                        : c.t('loadshed.nextOutage', { from: ls.slot.from, to: ls.slot.to }),
        stats: [
          { value: ls.hoursToday + 'h', label: c.t('loadshed.today') },
          { value: ls.slots.length + '', label: c.t('loadshed.slots') },
          { value: ls.reliability + '%', label: c.t('loadshed.reliability') }
        ]
      }) }) +
      UI.section({ title: c.t('loadshed.schedule'), body: UI.timeline(ls.slots.map(function (s) {
        return { time: s.from, title: c.t('loadshed.outage'), sub: c.t('loadshed.until', { time: s.to }),
          value: s.duration, state: s.state, icon: s.state === 'now' ? 'i-bolt' : null };
      })) }) +
      UI.section({ title: c.t('loadshed.week'), body: UI.card(
        UI.barChart({ values: ls.week, labels: c.weekLabels(), highlight: ls.todayIndex,
          label: c.t('loadshed.week'), caption: c.t('loadshed.weekCap') })) }) +
      UI.section({ body: UI.rows([
        UI.compactRow({ icon: 'i-bell', label: c.t('loadshed.notify'), value: c.t('common.on'), act: 'toast:' + c.t('loadshed.notifyOn') }),
        UI.compactRow({ icon: 'i-receipt', label: c.t('f.bills'), value: c.t('loadshed.billHint'), act: 'tool:bills' })
      ]) });
  });

  /* ---------------------------------------------------------
     §42 Trains — live tracking, very high density
     --------------------------------------------------------- */
  T.register('trains', function (c) {
    var sel = c.state('train') || D.TRAINS[0].no;
    var train = D.TRAINS.filter(function (t) { return t.no === sel; })[0] || D.TRAINS[0];
    var ccy = c.L.country().currency;
    var onTime = D.TRAINS.filter(function (t) { return !t.delay; }).length;
    var status = c.filter('status', 'all');
    var shown = D.TRAINS.filter(function (t) {
      return status === 'all' || (status === 'ontime' ? !t.delay : !!t.delay);
    });

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city, act: 'sheet:personalise' },
        { label: c.t('trains.operator') }]) }) +
      UI.section({ body: UI.card(UI.formGrid([
        UI.field({ label: c.t('trains.from'), name: 'tr_from', value: train.from }),
        UI.field({ label: c.t('trains.to'), name: 'tr_to', value: train.to })
      ]) + UI.buttonRow([{ label: c.t('trains.find'), tone: 'accent', icon: 'i-search', block: true,
        act: 'toast:' + c.t('trains.searching') }])) }) +
      UI.section({ body: UI.metrics([
        { value: String(D.TRAINS.length), label: c.t('trains.running') },
        { value: String(onTime), label: c.t('trains.onTime') },
        { value: String(D.TRAINS.length - onTime), label: c.t('trains.delayed') }
      ], 3) }) +
      UI.section({ body: UI.filterBar([{ id: 'status', label: c.t('common.status'), items: [
        { value: 'all', label: c.t('common.all'), on: status === 'all' },
        { value: 'ontime', label: c.t('trains.onTime'), on: status === 'ontime' },
        { value: 'late', label: c.t('trains.delayed'), on: status === 'late' }
      ] }], 'trains') }) +
      UI.section({ title: c.t('trains.departures'), body: shown.length ? UI.rows(shown.map(function (t) {
        return UI.richRow({
          logo: t.no.replace(/[A-Z]+/, ''), logoTone: t.delay ? 'var(--tone-amber)' : 'var(--tint-accent)',
          title: t.name,
          sub: t.from + ' → ' + t.to,
          meta: [t.dep + ' – ' + t.arr, t.dur, c.t('trains.platform') + ' ' + t.platform],
          badge: { label: c.t(t.statusKey, { n: t.delay }), tone: t.tone === 'ok' ? 'ok' : 'late' },
          value: c.moneyRaw(t.fare, ccy, 0),
          valueSub: c.t('trains.from2'),
          act: 'toolstate:trains:train:' + t.no,
          cls: t.no === sel ? 'is-selected' : ''
        });
      })) : UI.emptyState({ icon: 'i-train', title: c.t('trains.noMatch'), text: c.t('trains.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:trains:status:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('trains.selected', { name: train.name }), body: UI.card(
        UI.journey({
          fromCode: train.fromCode, from: train.from, fromTime: train.dep,
          toCode: train.toCode, to: train.to, toTime: train.arr,
          duration: train.dur, progress: train.progress, icon: 'i-train'
        }) +
        UI.metrics([
          { value: c.L.speed(train.speed), label: c.t('trains.speed') },
          { value: train.next, label: c.t('trains.nextStop') },
          { value: train.delay ? '+' + train.delay + 'm' : c.t('trains.onTime'), label: c.t('trains.delay') }
        ], 3)) }) +
      UI.section({ body: UI.map({
        label: c.t('trains.route'), caption: train.from + ' → ' + train.to,
        route: 'M8 84 C 30 70, 40 44, 62 30 S 88 14, 94 8',
        markers: [
          { x: 8, y: 84, icon: 'i-pin', label: train.from },
          { x: 8 + (94 - 8) * train.progress, y: 84 - (84 - 8) * train.progress, icon: 'i-train', label: train.name, active: true },
          { x: 94, y: 8, icon: 'i-pin', label: train.to }
        ]
      }) }) +
      UI.section({ title: c.t('trains.stops'), body: UI.timeline(D.TRAIN_STOPS.map(function (s) {
        return { time: s.sched, title: s.st,
          sub: s.act !== '—' ? c.t('trains.actual', { time: s.act }) : c.t('trains.scheduled'),
          meta: c.L.distance(s.km), state: s.state === 'done' ? 'done' : s.state === 'now' ? 'now' : '' };
      })) }) +
      UI.section({ title: c.t('trains.fares'), body: UI.table({
        label: c.t('trains.fares'),
        cols: [{ label: c.t('trains.class') }, { label: c.t('trains.fare'), align: 'right' },
               { label: c.t('trains.seats'), align: 'right' }],
        rows: train.classes.map(function (cl, i) {
          return { cells: [UI.esc(cl), c.moneyRaw(train.fare * (i ? 0.72 : 1), ccy, 0), String(48 - i * 17)] };
        })
      }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('trains.remind'), tone: 'accent', icon: 'i-bell', act: 'toast:' + c.t('trains.reminded', { name: train.name }) },
        { label: c.t('common.share'), icon: 'i-share', act: 'toast:' + train.name }]) });
  });

  /* ---------------------------------------------------------
     §43 Flights — live board + map, very high density
     --------------------------------------------------------- */
  T.register('flights', function (c) {
    var sel = c.state('flight') || D.FLIGHTS[0].no;
    var fl = D.FLIGHTS.filter(function (f) { return f.no === sel; })[0] || D.FLIGHTS[0];
    var view = c.state('view') || 'arrivals';
    var enRoute = D.FLIGHTS.filter(function (f) { return f.statusKey === 'flights.st.enroute'; }).length;

    return UI.section({ body: UI.searchBar({
        placeholder: c.t('flights.search'), target: 'flights' }) }) +
      UI.section({ body: UI.segmented({ id: 'flightview', label: c.t('flights.board'), items: [
        { value: 'arrivals', label: c.t('flights.arrivals'), on: view === 'arrivals', act: 'toolstate:flights:view:arrivals' },
        { value: 'departures', label: c.t('flights.departures'), on: view === 'departures', act: 'toolstate:flights:view:departures' },
        { value: 'tracked', label: c.t('flights.tracked'), on: view === 'tracked', act: 'toolstate:flights:view:tracked' }
      ] }) }) +
      UI.section({ body: UI.metrics([
        { value: String(D.FLIGHTS.length), label: c.t('flights.total') },
        { value: String(enRoute), label: c.t('flights.enRoute') },
        { value: String(D.FLIGHTS.filter(function (f) { return f.delay > 0; }).length), label: c.t('flights.delayed') }
      ], 3) }) +
      UI.section({ body: UI.map({
        tall: true, label: c.t('flights.map'), caption: fl.fromCode + ' → ' + fl.toCode,
        route: 'M10 78 C 34 50, 58 30, 90 16',
        markers: [
          { x: 10, y: 78, icon: 'i-pin', label: fl.from },
          { x: 10 + 80 * fl.progress, y: 78 - 62 * fl.progress, icon: 'i-plane', label: fl.no, active: true },
          { x: 90, y: 16, icon: 'i-pin', label: fl.to }
        ]
      }) }) +
      UI.section({ title: c.t('flights.live'), body: UI.rows(D.FLIGHTS.map(function (f) {
        return UI.richRow({
          logo: f.logo, logoTone: 'var(--tone-' + f.tone + ')',
          title: f.no,
          sub: f.airline + ' · ' + f.craft,
          meta: [f.fromCode + ' → ' + f.toCode, c.t('flights.gate') + ' ' + f.gate,
                 f.delay ? '+' + f.delay + 'm' : c.t('flights.onTime')],
          badge: { label: c.t(f.statusKey), tone: f.tone2 },
          value: f.arr,
          valueSub: f.delay ? c.t('flights.eta') + ' ' + f.eta : c.t('flights.scheduled'),
          act: 'toolstate:flights:flight:' + f.no,
          cls: f.no === sel ? 'is-selected' : ''
        });
      })) }) +
      UI.section({ title: fl.no + ' · ' + fl.airline, body: UI.card(
        UI.journey({
          fromCode: fl.fromCode, from: fl.from, fromTime: fl.actual,
          toCode: fl.toCode, to: fl.to, toTime: fl.eta,
          duration: c.t('flights.remaining', { d: c.L.distance(Math.round(fl.dist * (1 - fl.progress))) }),
          progress: fl.progress, icon: 'i-plane'
        })) }) +
      UI.section({ title: c.t('flights.aircraft'), body: UI.table({
        label: c.t('flights.aircraft'),
        cols: [{ label: c.t('common.field') }, { label: c.t('common.value'), align: 'right' }],
        rows: [
          { cells: [c.t('flights.type'), UI.esc(fl.craft)] },
          { cells: [c.t('flights.registration'), UI.esc(fl.reg)] },
          { cells: [c.t('flights.altitude'), c.num(fl.alt) + ' ' + c.t('unit.ft')] },
          { cells: [c.t('flights.speed'), c.L.speed(fl.speed)] },
          { cells: [c.t('flights.distance'), c.L.distance(fl.dist)] },
          { cells: [c.t('flights.terminal'), UI.esc(fl.term) + ' · ' + c.t('flights.gate') + ' ' + UI.esc(fl.gate)] }
        ]
      }) }) +
      UI.section({ title: c.t('flights.timeline'), body: UI.timeline([
        { time: fl.dep, title: c.t('flights.scheduledDep'), sub: fl.from, state: 'done' },
        { time: fl.actual, title: c.t('flights.actualDep'), sub: fl.delay ? c.t('flights.lateBy', { n: fl.delay }) : c.t('flights.onTime'), state: 'done' },
        { time: '—', title: c.t('flights.cruise'), sub: c.num(fl.alt) + ' ' + c.t('unit.ft') + ' · ' + c.L.speed(fl.speed), state: fl.progress < 1 ? 'now' : 'done' },
        { time: fl.eta, title: c.t('flights.estArrival'), sub: fl.to, state: fl.progress >= 1 ? 'done' : '' }
      ]) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('flights.track'), tone: 'accent', icon: 'i-bell', act: 'toast:' + c.t('flights.tracking', { no: fl.no }) },
        { label: c.t('common.share'), icon: 'i-share', act: 'toast:' + fl.no }]) });
  });

  /* ---------------------------------------------------------
     §44 News — editorial feed. Images earn their place here.
     --------------------------------------------------------- */
  T.register('news', function (c) {
    var cat = c.state('cat') || 'Top';
    var all = D.newsFor(c.profile.country);
    var list = cat === 'Top' ? all : all.filter(function (n) { return n.cat === cat; });
    var lead = list[0] || null;
    var rest = list.slice(1);

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.t('news.edition') }]) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('news.search'), target: 'news' }) }) +
      UI.section({ flush: true, body: '<div class="chips chips--scroll">' +
        D.NEWS_CATEGORIES.map(function (x) {
          return '<button class="chip' + (x === cat ? ' is-on' : '') + '" data-act="toolstate:news:cat:' + UI.esc(x) + '">' +
            UI.esc(x) + '</button>';
        }).join('') + '</div>' }) +
      (lead ? UI.section({ title: c.t('news.top'), body:
        '<button class="lead pressable" data-act="toast:' + UI.esc(lead.title) + '">' +
          UI.art({ tone: lead.tone, seed: lead.title.length, cls: 'lead__art' }) +
          '<span class="lead__body">' +
            '<span class="lead__cat">' + UI.esc(lead.cat) + '</span>' +
            '<span class="lead__title">' + UI.esc(lead.title) + '</span>' +
            '<span class="lead__meta">' + UI.esc(lead.src) + ' · ' + UI.esc(lead.ago) + ' · ' +
              UI.esc(c.t('news.readTime', { n: lead.mins })) + '</span>' +
          '</span>' +
        '</button>' }) : '') +
      UI.section({ title: c.t('news.latest'), body: rest.length ? UI.rows(rest.map(function (n) {
        return UI.richRow({
          thumb: UI.art({ tone: n.tone, seed: n.title.length + n.mins }),
          title: n.title,
          sub: n.src,
          meta: [n.cat, n.ago, c.t('news.readTime', { n: n.mins })],
          act: 'toast:' + n.title, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-news', title: c.t('news.empty.title'), text: c.t('news.empty.text') }) }) +
      UI.section({ title: c.t('news.saved'), body: UI.rows([
        UI.compactRow({ icon: 'i-bookmark', label: c.t('news.savedCount', { n: 4 }), act: 'toast:' + c.t('news.savedOpen') }),
        UI.compactRow({ icon: 'i-sliders', label: c.t('news.sources'), value: c.t('news.sourcesValue', { n: 8 }), act: 'toast:' + c.t('news.sourcesEdit') })
      ]) });
  });

  /* ---------------------------------------------------------
     §45 Cricket — live sports dashboard
     --------------------------------------------------------- */
  T.register('cricket', function (c) {
    var k = D.CRICKET, m = k.live;
    var tab = c.state('tab') || 'live';
    return UI.section({ body: UI.card(
        '<div class="score">' +
          '<div class="score__side"><b>' + UI.esc(m.t1) + '</b><span>' + UI.esc(m.t1full) + '</span></div>' +
          '<div class="score__mid">' +
            '<p class="score__runs">' + UI.esc(m.s1) + '</p>' +
            '<p class="score__overs">' + UI.esc(m.o1) + ' ' + UI.esc(c.t('cricket.overs')) + '</p>' +
            UI.freshness({ quality: 'live', label: c.t('cricket.live') }) +
          '</div>' +
          '<div class="score__side score__side--away"><b>' + UI.esc(m.t2) + '</b><span>' + UI.esc(m.t2full) + '</span>' +
            (m.s2 && m.s2 !== '—' ? '<i class="score__second">' + UI.esc(m.s2) + ' (' + UI.esc(m.o2) + ')</i>' : '') + '</div>' +
        '</div>' +
        '<p class="score__status">' + UI.esc(c.t(m.statusKey, { team: m.t1full })) + '</p>' +
        UI.metrics([
          { value: c.num(m.rr, { minimumFractionDigits: 2, maximumFractionDigits: 2 }), label: c.t('cricket.runRate') },
          { value: m.format, label: c.t('cricket.format') },
          { value: m.venue.split(',')[0], label: c.t('cricket.venue') }
        ], 3), { tone: 'sport' }) }) +
      UI.section({ flush: true, body: UI.tabs({ id: 'cricket', items: [
        { value: 'live', label: c.t('cricket.live'), on: tab === 'live', act: 'toolstate:cricket:tab:live' },
        { value: 'fixtures', label: c.t('cricket.fixtures'), on: tab === 'fixtures', act: 'toolstate:cricket:tab:fixtures' },
        { value: 'standings', label: c.t('cricket.standings'), on: tab === 'standings', act: 'toolstate:cricket:tab:standings' }
      ] }) }) +
      (tab === 'fixtures'
        ? UI.section({ title: c.t('cricket.upcoming'), body: UI.rows(k.fixtures.map(function (f) {
            return UI.richRow({ icon: 'i-cricket', title: f.t1 + ' v ' + f.t2, sub: f.venue,
              meta: [f.format], value: f.when.split(' · ')[0], valueSub: f.when.split(' · ')[1] });
          })) })
        : tab === 'standings'
        ? UI.section({ title: c.t('cricket.table'), body: UI.table({
            label: c.t('cricket.table'),
            cols: [{ label: c.t('cricket.team') }, { label: c.t('cricket.played'), align: 'right' },
                   { label: c.t('cricket.won'), align: 'right' }, { label: c.t('cricket.lost'), align: 'right' },
                   { label: c.t('cricket.points'), align: 'right' }, { label: c.t('cricket.nrr'), align: 'right' }],
            rows: k.standings.map(function (s) {
              return { cells: [UI.esc(s.team), c.num(s.p), c.num(s.w), c.num(s.l),
                               '<b>' + c.num(s.pts) + '</b>', UI.esc(s.nrr)] };
            })
          }) })
        : UI.section({ title: c.t('cricket.batting'), body: UI.table({
            label: c.t('cricket.batting'),
            cols: [{ label: c.t('cricket.batter') }, { label: c.t('cricket.runs'), align: 'right' },
                   { label: c.t('cricket.balls'), align: 'right' }, { label: c.t('cricket.fours'), align: 'right' },
                   { label: c.t('cricket.sixes'), align: 'right' }, { label: c.t('cricket.strikeRate'), align: 'right' }],
            rows: m.batters.map(function (b) {
              return { cells: ['<b>' + UI.esc(b.n) + '</b>' + (b.out ? '' : ' <i class="cellsub">' + UI.esc(c.t('cricket.notOut')) + '</i>'),
                               c.num(b.r), c.num(b.b), c.num(b.f), c.num(b.s), c.num(b.sr, { maximumFractionDigits: 1 })] };
            })
          }) }) +
          UI.section({ title: c.t('cricket.bowling'), body: UI.table({
            label: c.t('cricket.bowling'),
            cols: [{ label: c.t('cricket.bowler') }, { label: c.t('cricket.overs2'), align: 'right' },
                   { label: c.t('cricket.maidens'), align: 'right' }, { label: c.t('cricket.runs'), align: 'right' },
                   { label: c.t('cricket.wickets'), align: 'right' }, { label: c.t('cricket.economy'), align: 'right' }],
            rows: m.bowlers.map(function (b) {
              return { cells: ['<b>' + UI.esc(b.n) + '</b>', c.num(b.o), c.num(b.m), c.num(b.r),
                               '<b>' + c.num(b.w) + '</b>', c.num(b.ec, { maximumFractionDigits: 2 })] };
            })
          }) }));
  });

  /* ---------------------------------------------------------
     §46 Emergency — action interface. Low density on purpose:
     the actions must be unmissable.
     --------------------------------------------------------- */
  T.register('emergency', function (c) {
    var list = D.emergencyFor(c.profile.country);
    var primary = list[0];
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city + ', ' + c.L.countryName(c.profile.country) }]) }) +
      UI.section({ body:
        '<a class="sos pressable" href="tel:' + UI.esc(primary.num) + '">' +
          '<span class="sos__icon">' + UI.ico('i-shield') + '</span>' +
          '<span class="sos__body"><b>' + UI.esc(primary.n) + '</b>' +
          '<i>' + UI.esc(c.t(primary.kindKey)) + '</i></span>' +
          '<span class="sos__num">' + UI.esc(primary.num) + '</span>' +
        '</a>' }) +
      UI.section({ title: c.t('emergency.services'), body: '<div class="calls">' +
        list.slice(1).map(function (e) {
          return '<a class="call pressable" href="tel:' + UI.esc(e.num) + '">' +
            '<span class="call__icon">' + UI.ico(e.icon) + '</span>' +
            '<span class="call__name">' + UI.esc(e.n) + '</span>' +
            '<span class="call__num">' + UI.esc(e.num) + '</span>' +
            '<span class="call__kind">' + UI.esc(c.t(e.kindKey)) + '</span>' +
          '</a>';
        }).join('') + '</div>' }) +
      UI.section({ title: c.t('emergency.yourInfo'), body: UI.rows([
        UI.compactRow({ icon: 'i-pulse', label: c.t('emergency.medical'), value: c.t('emergency.setUp'), act: 'tool:health' }),
        UI.compactRow({ icon: 'i-folder', label: c.t('emergency.documents'), value: c.t('common.locked'), act: 'tool:documents' }),
        UI.compactRow({ icon: 'i-pin', label: c.t('emergency.shareLocation'), value: c.profile.city, act: 'toast:' + c.t('emergency.locationShared') })
      ]) }) +
      UI.section({ body: UI.noteCard({ tone: 'info', icon: 'i-info',
        title: c.t('emergency.note.title'), text: c.t('emergency.note.text') }) });
  });

  /* ---------------------------------------------------------
     §47 Unit converter
     --------------------------------------------------------- */
  T.register('converter', function (c) {
    var u = c.converter();
    return UI.section({ flush: true, body: '<div class="chips chips--scroll">' +
        u.categories.map(function (cat) {
          return '<button class="chip' + (cat.id === u.category ? ' is-on' : '') +
            '" data-act="toolstate:converter:cat:' + cat.id + '">' + UI.ico(cat.icon) + UI.esc(cat.label) + '</button>';
        }).join('') + '</div>' }) +
      UI.section({ body: UI.card(
        '<div class="convert">' +
          '<div class="convert__side">' +
            '<span class="convert__code">' + UI.esc(u.from.short) + '</span>' +
            '<input class="convert__input" type="number" inputmode="decimal" value="' + u.amount + '" data-input="uc_amount">' +
            '<span class="convert__name">' + UI.esc(u.from.label) + '</span>' +
          '</div>' +
          '<button class="convert__swap pressable" data-act="ucswap" aria-label="' + UI.esc(c.t('convert.swap')) + '">' +
            UI.ico('i-swap') + '</button>' +
          '<div class="convert__side convert__side--to">' +
            '<span class="convert__code">' + UI.esc(u.to.short) + '</span>' +
            '<span class="convert__out" data-uc-out>' + c.num(u.result, { maximumFractionDigits: 4 }) + '</span>' +
            '<span class="convert__name">' + UI.esc(u.to.label) + '</span>' +
          '</div>' +
        '</div>') }) +
      UI.section({ title: c.t('convert.allUnits'), body: UI.rows(u.units.map(function (x) {
        return UI.compactRow({ label: x.label, sub: x.short, value: c.num(u.amount * u.from.factor / x.factor, { maximumFractionDigits: 4 }) });
      })) }) +
      UI.section({ title: c.t('convert.recent'), body: UI.rows(u.recent.map(function (r) {
        return UI.compactRow({ icon: 'i-clock', label: r.label, value: r.value });
      })) });
  });

  /* ---------------------------------------------------------
     §48 BMI · §49 Age · date calculator
     --------------------------------------------------------- */
  T.register('bmi', function (c) {
    var b = c.bmi();
    return UI.section({ id: 'inputs', body: UI.card(UI.formGrid([
        UI.field({ label: c.t('bmi.height'), name: 'bmi_h', type: 'number', value: b.f.height, suffix: b.heightUnit }),
        UI.field({ label: c.t('bmi.weight'), name: 'bmi_w', type: 'number', value: b.f.weight, suffix: b.weightUnit })
      ])) }) +
      UI.section({ body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('bmi.your'),
        value: '<span data-bmi-value>' + b.bmi.toFixed(1) + '</span>',
        caption: UI.statusBadge({ label: b.band.label, tone: b.band.tone }),
        aside: UI.progressRing({ value: Math.min(1, b.bmi / 40), centre: c.num(b.bmi, { minimumFractionDigits: 1, maximumFractionDigits: 1 }), label: c.t('bmi.your') })
      }) }) +
      UI.section({ title: c.t('bmi.scale'), body: UI.card(
        '<div class="scale">' + b.bands.map(function (x) {
          return '<span class="scale__seg scale__seg--' + x.tone + (x.on ? ' is-on' : '') + '">' +
            '<i>' + UI.esc(x.label) + '</i><b>' + UI.esc(x.range) + '</b></span>';
        }).join('') + '</div>') }) +
      UI.section({ title: c.t('bmi.healthy'), body: UI.rows([
        UI.compactRow({ icon: 'i-target', label: c.t('bmi.healthyRange'), value: b.healthyRange }),
        UI.compactRow({ icon: 'i-scales', label: c.t('bmi.idealWeight'), value: b.idealWeight })
      ]) }) +
      UI.section({ title: c.t('common.history'), body: UI.card(
        UI.lineChart({ values: b.history, labels: [c.t('range.6m'), c.t('range.3m'), c.t('common.now')], label: c.t('bmi.trend') })) });
  });

  T.register('age', function (c) {
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
  });

  T.register('datecalc', function (c) {
    var d = c.dateCalc();
    return UI.section({ body: UI.segmented({ id: 'datemode', label: c.t('datecalc.mode'), items: [
        { value: 'diff', label: c.t('datecalc.difference'), on: d.mode === 'diff', act: 'toolstate:datecalc:mode:diff' },
        { value: 'add', label: c.t('datecalc.addSubtract'), on: d.mode === 'add', act: 'toolstate:datecalc:mode:add' }
      ] }) }) +
      UI.section({ body: UI.card(d.mode === 'diff'
        ? UI.formGrid([
            UI.field({ label: c.t('datecalc.from'), name: 'dc_from', type: 'date', value: d.f.from }),
            UI.field({ label: c.t('datecalc.to'), name: 'dc_to', type: 'date', value: d.f.to })
          ])
        : UI.formGrid([
            UI.field({ label: c.t('datecalc.start'), name: 'dc_start', type: 'date', value: d.f.from }),
            UI.field({ label: c.t('datecalc.days'), name: 'dc_days', type: 'number', value: d.f.days })
          ])) }) +
      UI.section({ body: UI.summaryCard({
        kicker: d.mode === 'diff' ? c.t('datecalc.between') : c.t('datecalc.result'),
        value: '<span data-dc-out>' + d.headline + '</span>',
        caption: d.caption,
        stats: d.stats
      }) }) +
      UI.section({ title: c.t('datecalc.business'), body: UI.rows([
        UI.compactRow({ icon: 'i-calendar', label: c.t('datecalc.weekdays'), value: c.num(d.weekdays) }),
        UI.compactRow({ icon: 'i-sun', label: c.t('datecalc.weekends'), value: c.num(d.weekends) }),
        UI.compactRow({ icon: 'i-star', label: c.t('datecalc.holidays'), value: c.num(d.holidays) })
      ]) });
  });

  /* ---------------------------------------------------------
     §50 QR · §51 Document scanner · §52 Passport photos
     Camera workflows: the composition is the specification.
     --------------------------------------------------------- */
  function scannerScreen(c, o) {
    return UI.section({ body:
        '<div class="scanner">' +
          '<div class="scanner__view">' +
            '<span class="scanner__frame"></span>' +
            '<span class="scanner__beam"></span>' +
            '<p class="scanner__hint">' + UI.esc(o.hint) + '</p>' +
          '</div>' +
          UI.buttonRow([
            { label: o.cta, tone: 'accent', icon: o.icon, act: 'toast:' + o.acting },
            { label: c.t('scan.fromGallery'), icon: 'i-image', act: 'toast:' + c.t('scan.picking') }
          ]) +
        '</div>' }) +
      UI.section({ title: o.stepsTitle, body: UI.timeline(o.steps) }) +
      UI.section({ title: c.t('common.history'), body: o.history.length
        ? UI.rows(o.history.map(function (h) {
            return UI.richRow({ icon: h.icon, title: h.title, sub: h.sub, meta: [h.when], act: 'toast:' + h.title, chevron: true });
          }))
        : UI.emptyState({ icon: 'i-scan', title: c.t('scan.empty.title'), text: c.t('scan.empty.text') }) });
  }

  T.register('qr', function (c) {
    return scannerScreen(c, {
      hint: c.t('qr.hint'), cta: c.t('qr.scan'), icon: 'i-qr', acting: c.t('qr.scanning'),
      stepsTitle: c.t('qr.detects'),
      steps: [
        { time: '1', title: c.t('qr.step.point'), state: 'now' },
        { time: '2', title: c.t('qr.step.detect') },
        { time: '3', title: c.t('qr.step.act') }
      ],
      history: [
        { icon: 'i-globe', title: 'lume.app/tools', sub: c.t('qr.kind.link'), when: c.t('common.today') },
        { icon: 'i-wifi', title: 'Home-WiFi', sub: c.t('qr.kind.wifi'), when: c.t('common.yesterday') }
      ]
    });
  });

  T.register('docscan', function (c) {
    return scannerScreen(c, {
      hint: c.t('docscan.hint'), cta: c.t('docscan.capture'), icon: 'i-scan', acting: c.t('docscan.capturing'),
      stepsTitle: c.t('docscan.workflow'),
      steps: [
        { time: '1', title: c.t('docscan.step.edges'), state: 'now' },
        { time: '2', title: c.t('docscan.step.crop') },
        { time: '3', title: c.t('docscan.step.enhance') },
        { time: '4', title: c.t('docscan.step.export') }
      ],
      history: [
        { icon: 'i-folder', title: c.t('docscan.recent1'), sub: '3 ' + c.t('docscan.pages'), when: c.t('common.today') },
        { icon: 'i-folder', title: c.t('docscan.recent2'), sub: '1 ' + c.t('docscan.page'), when: '4 Sep' }
      ]
    });
  });

  T.register('passport', function (c) {
    var specs = c.passportSpecs();
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' }]) }) +
      UI.section({ body: UI.card(
        '<div class="photoguide">' +
          '<span class="photoguide__frame"><i class="photoguide__head"></i></span>' +
          '<div class="photoguide__specs">' + specs.map(function (s) {
            return '<span class="photoguide__spec"><b>' + UI.esc(s.value) + '</b><i>' + UI.esc(s.label) + '</i></span>';
          }).join('') + '</div>' +
        '</div>' +
        UI.buttonRow([
          { label: c.t('passport.capture'), tone: 'accent', icon: 'i-image', act: 'toast:' + c.t('passport.capturing') },
          { label: c.t('passport.import'), icon: 'i-download', act: 'toast:' + c.t('passport.importing') }
        ])) }) +
      UI.section({ title: c.t('passport.requirements'), body: UI.rows([
        UI.compactRow({ icon: 'i-check', label: c.t('passport.req.background') }),
        UI.compactRow({ icon: 'i-check', label: c.t('passport.req.expression') }),
        UI.compactRow({ icon: 'i-check', label: c.t('passport.req.glasses') }),
        UI.compactRow({ icon: 'i-check', label: c.t('passport.req.recent') })
      ]) }) +
      UI.section({ title: c.t('passport.sizes'), body: UI.table({
        label: c.t('passport.sizes'),
        cols: [{ label: c.t('passport.document') }, { label: c.t('passport.size'), align: 'right' },
               { label: c.t('passport.dpi'), align: 'right' }],
        rows: [
          { cells: [c.t('passport.passport'), '35 × 45 mm', '600'] },
          { cells: [c.t('passport.visaUS'), '2 × 2 in', '600'] },
          { cells: [c.t('passport.idCard'), '35 × 45 mm', '600'] }
        ]
      }) });
  });

  /* ---------------------------------------------------------
     §53 Vehicle & fines — vehicle manager
     --------------------------------------------------------- */
  T.register('vehicle', function (c) {
    var cfg = c.vehicleCosts();
    var ccy = cfg.ccy;
    var fines = D.VEHICLES.reduce(function (a, v) { return a + v.fines; }, 0);
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('vehicle.fleet'),
        value: String(D.VEHICLES.length),
        caption: fines ? c.t('vehicle.openFines', { n: fines }) : c.t('vehicle.noFines'),
        stats: [
          { value: c.money(D.VEHICLES.reduce(function (a, v) { return a + v.fineAmount; }, 0)),
            label: c.t('vehicle.outstanding') },
          { value: D.VEHICLES[0].token, label: c.t('vehicle.nextToken') },
          { value: c.L.distance(D.VEHICLES[0].odo), label: c.t('vehicle.odometer') }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('vehicle.search'), target: 'vehicle' }) }) +
      UI.section({ title: c.t('vehicle.yours'), body: UI.rows(D.VEHICLES.map(function (v) {
        return UI.richRow({
          logo: v.plate.slice(0, 3), logoTone: 'var(--tone-' + v.tone + ')',
          title: v.plate, sub: v.make + ' · ' + v.year,
          meta: [c.t('vehicle.token') + ' ' + v.token, c.t('vehicle.insurance') + ' ' + v.insurance],
          badge: v.fines ? { label: c.t('vehicle.fines', { n: v.fines }), tone: 'warn' }
                         : { label: c.t('vehicle.clear'), tone: 'ok' },
          value: c.L.distance(v.odo), valueSub: '',
          act: 'toast:' + v.plate, chevron: true
        });
      })) }) +
      UI.section({ title: c.t('vehicle.check'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('vehicle.registration'), name: 'veh_reg', placeholder: 'ABC-123', wide: true })
      ]) + UI.buttonRow([{ label: c.t('vehicle.lookup'), tone: 'accent', icon: 'i-search', block: true,
        act: 'toast:' + c.t('vehicle.lookingUp') }])) }) +
      UI.section({ title: c.t('vehicle.reminders'), body: UI.timeline([
        { time: '30 Sep', title: c.t('vehicle.tokenTax'), sub: 'ABC-124', state: 'now', value: c.money(cfg.tokenCar) },
        { time: '11 Nov', title: c.t('vehicle.tokenTax'), sub: 'LEB-8842', value: c.money(cfg.tokenBike) },
        { time: '14 Dec', title: c.t('vehicle.insuranceRenewal'), sub: 'ABC-124', value: c.money(cfg.insurance) }
      ]) });
  });

  /* ---------------------------------------------------------
     §54 Media saver · §55 WhatsApp status
     --------------------------------------------------------- */
  T.register('mediasaver', function (c) {
    var items = c.savedMedia();
    return UI.section({ body: UI.card(UI.formGrid([
        UI.field({ label: c.t('media.link'), name: 'ms_link', placeholder: 'https://…', wide: true })
      ]) + UI.buttonRow([{ label: c.t('media.fetch'), tone: 'accent', icon: 'i-download', block: true,
        act: 'toast:' + c.t('media.fetching') }])) }) +
      UI.section({ body: UI.metrics([
        { value: String(items.length), label: c.t('media.saved') },
        { value: '182 ' + c.t('unit.mb'), label: c.t('media.storage') },
        { value: c.t('common.today'), label: c.t('media.lastSave') }
      ], 3) }) +
      UI.section({ title: c.t('media.library'), body: items.length
        ? '<div class="mgrid">' + items.map(function (m) {
            return '<button class="mtile pressable" data-act="toast:' + UI.esc(m.title) + '">' +
              UI.art({ tone: m.tone, seed: m.title.length, glyph: m.glyph }) +
              '<span class="mtile__label">' + UI.esc(m.title) + '</span>' +
              '<span class="mtile__meta">' + UI.esc(m.size) + '</span></button>';
          }).join('') + '</div>'
        : UI.emptyState({ icon: 'i-download', title: c.t('media.empty.title'), text: c.t('media.empty.text') }) });
  });

  T.register('wastatus', function (c) {
    return UI.section({ body: UI.noteCard({ tone: 'info', icon: 'i-message',
        title: c.t('wastatus.android.title'), text: c.t('wastatus.android.text') }) }) +
      UI.section({ title: c.t('wastatus.detected'), body: UI.emptyState({
        icon: 'i-message', title: c.t('wastatus.empty.title'), text: c.t('wastatus.empty.text'),
        action: { label: c.t('wastatus.grant'), act: 'toast:' + c.t('wastatus.granting'), icon: 'i-folder' } }) });
  });

  /* ---------------------------------------------------------
     §56 Speed test — live instrument
     --------------------------------------------------------- */
  T.register('speedtest', function (c) {
    var s = c.speedTest();
    return UI.section({ body: UI.card(
        '<div class="gauge" data-gauge>' +
          '<svg viewBox="0 0 200 120" aria-hidden="true">' +
            '<path class="gauge__track" d="M20 108 A 80 80 0 0 1 180 108"/>' +
            '<path class="gauge__fill" d="M20 108 A 80 80 0 0 1 180 108" style="--p:' + s.pct.toFixed(3) + '"/>' +
          '</svg>' +
          '<div class="gauge__mid"><b data-speed-value>' + s.down.toFixed(1) + '</b><i>Mbps</i></div>' +
        '</div>' +
        UI.buttonRow([{ label: c.t('speed.start'), tone: 'accent', icon: 'i-play', block: true, act: 'speedtest' }])) }) +
      UI.section({ body: UI.metrics([
        { icon: 'i-download', value: c.num(s.down, { maximumFractionDigits: 1 }), label: c.t('speed.download') },
        { icon: 'i-arrow-ur', value: c.num(s.up, { maximumFractionDigits: 1 }), label: c.t('speed.upload') },
        { icon: 'i-timer', value: c.num(s.ping) + ' ' + c.t('unit.ms'), label: c.t('speed.ping') }
      ], 3) }) +
      UI.section({ title: c.t('speed.connection'), body: UI.rows([
        UI.compactRow({ icon: 'i-wifi', label: c.t('speed.type'), value: s.type }),
        UI.compactRow({ icon: 'i-signal', label: c.t('speed.server'), value: s.server }),
        UI.compactRow({ icon: 'i-globe', label: c.t('speed.isp'), value: s.isp })
      ]) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(s.history.map(function (h) {
        return UI.richRow({ icon: 'i-wifi', title: h.when, sub: h.type,
          meta: [c.t('speed.ping') + ' ' + c.num(h.ping) + ' ' + c.t('unit.ms')],
          spark: UI.sparkline(h.series, { tone: 'up' }),
          value: c.num(h.down, { maximumFractionDigits: 1 }), valueSub: c.t('unit.mbps') });
      })) });
  });

  /* ---------------------------------------------------------
     §80 World clock · public holidays
     --------------------------------------------------------- */
  T.register('worldclock', function (c) {
    var zones = c.worldClock();
    return UI.section({ body: UI.summaryCard({
        kicker: c.profile.city,
        value: c.clockNow(),
        caption: c.L.timezone() + ' · ' + c.dateLong(new Date())
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('clock.search'), target: 'worldclock' }) }) +
      UI.section({ title: c.t('clock.cities'), body: UI.rows(zones.map(function (z) {
        return UI.richRow({
          logo: z.cc, logoTone: 'var(--tint-neutral)',
          title: z.city, sub: z.tz,
          meta: [z.offsetLabel, z.dayLabel],
          value: z.time, valueSub: z.period
        });
      })) }) +
      UI.section({ title: c.t('clock.converter'), body: UI.card(UI.formGrid([
        UI.selectField({ label: c.t('clock.from'), name: 'wc_from', value: c.L.timezone(),
          options: zones.map(function (z) { return { value: z.tz, label: z.city }; }) }),
        UI.selectField({ label: c.t('clock.to'), name: 'wc_to', value: zones[0].tz,
          options: zones.map(function (z) { return { value: z.tz, label: z.city }; }) })
      ])) });
  });

  T.register('holidays', function (c) {
    var list = D.holidaysFor(c.profile.country);
    var kind = c.filter('kind', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var kinds = list.map(function (h) { return h.kind; })
      .filter(function (v, i, a) { return a.indexOf(v) === i; });
    var shown = list.filter(function (h) {
      if (kind !== 'all' && h.kind !== kind) return false;
      if (query && h.name.toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('holidays.next'),
        value: list[0].name,
        caption: list[0].date + ' · ' + list[0].kind,
        stats: [{ value: String(list.length), label: c.t('holidays.thisYear') }]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('holidays.search'), target: 'holidays', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'kind', label: c.t('holidays.kind'), items: [
        { value: 'all', label: c.t('common.all'), on: kind === 'all' }
      ].concat(kinds.map(function (k) { return { value: k, label: k, on: kind === k }; })) }], 'holidays') }) +
      UI.section({ body: c.monthGrid() }) +
      UI.section({ title: c.t('holidays.calendar'), body: shown.length
        ? UI.rows(shown.map(function (h) {
            return UI.richRow({ icon: 'i-calendar', iconTone: 'accent', title: h.name, sub: h.kind, value: h.date });
          }))
        : UI.emptyState({ icon: 'i-calendar', title: c.t('holidays.noMatch'), text: c.t('holidays.noMatchText'),
            action: { label: c.t('common.all'), act: 'toolstate:holidays:kind:all', icon: 'i-refresh' } }) }) +
      (c.profile.islamic ? UI.section({ title: c.t('holidays.islamic'), body: UI.rows(D.ISLAMIC_EVENTS.map(function (e) {
        return UI.compactRow({ icon: 'i-moon-star', label: e.name, sub: e.hijri, value: e.greg });
      })) }) : '');
  });
})();
