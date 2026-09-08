/* ============================================================
   Lume — Prayer & Islam screens  (Master Spec §24)

   These are faith-gated: the visibility system decides whether
   they exist at all, so nothing in this file asks. What it does
   decide is composition — a calm spiritual dashboard for prayer,
   an instrument for Qibla, a reader for the Qur'an, a focused
   interaction for Tasbih. Never one template applied 17 times.
   ============================================================ */
(function () {
  'use strict';

  var UI = window.LUME_UI;
  var D = window.LUME_DATA;
  var T = window.LUME_TOOLS;

  /* ---------------------------------------------------------
     24.1 Prayer Times — spiritual dashboard, high density
     --------------------------------------------------------- */
  T.register('prayer', function (c) {
    var set = c.prayerTimes();
    var st = c.prayerState();
    var sun = c.sunTimes();

    var hero = UI.summaryCard({
      tone: 'prayer',
      kicker: c.t('prayer.next'),
      value: UI.esc(c.t('prayer.' + st.next.key)),
      unit: c.time(st.next.h, st.next.m),
      caption: '<span class="summary__count" data-prayer-count>' + UI.esc(st.countdown) + '</span>',
      aside: UI.progressRing({ value: st.progress, centre: st.pctLabel, label: c.t('prayer.progress') }),
      foot: UI.progressBar({ value: st.progress, label: c.t('prayer.progress') })
    });

    /* The five-prayer timeline is the primary information block: what
       has passed, what is next, what remains (§24.1). */
    var line = UI.timeline(set.map(function (p, i) {
      var state = i < st.index ? 'done' : i === st.index ? 'now' : '';
      return {
        time: c.time(p.h, p.m),
        title: c.t('prayer.' + p.key),
        sub: i === st.index ? c.t('prayer.upnext') : (i < st.index ? c.t('prayer.passed') : ''),
        state: state,
        icon: i < st.index ? 'i-check' : null,
        value: i === st.index ? UI.statusBadge({ label: st.short, tone: 'live' }) : ''
      };
    }));

    var sunCard = UI.card(
      '<div class="duo">' +
        '<div class="duo__half"><span class="duo__icon">' + UI.ico('i-sun') + '</span>' +
          '<b>' + c.time(sun.sunrise.h, sun.sunrise.m) + '</b><i>' + UI.esc(c.t('sun.sunrise')) + '</i></div>' +
        '<div class="duo__half"><span class="duo__icon">' + UI.ico('i-moon') + '</span>' +
          '<b>' + c.time(sun.sunset.h, sun.sunset.m) + '</b><i>' + UI.esc(c.t('sun.sunset')) + '</i></div>' +
      '</div>');

    var method = UI.rows([
      UI.compactRow({ icon: 'i-sliders', label: c.t('prayer.method'), value: c.profile.method, act: 'sheet:personalise' }),
      UI.compactRow({ icon: 'i-scales', label: c.t('prayer.asrmethod'), value: c.t('prayer.asr.standard') }),
      UI.compactRow({ icon: 'i-pin', label: c.t('settings.location'), value: c.profile.city, act: 'sheet:personalise' }),
      UI.compactRow({ icon: 'i-globe', label: c.t('settings.timezone'), value: c.L.timezone() })
    ]);

    /* Upcoming days: three days of Fajr and Maghrib drift, which is what
       people actually plan around. */
    var upcoming = UI.table({
      label: c.t('prayer.upcoming'),
      cols: [{ label: c.t('common.day') }, { label: c.t('prayer.fajr'), align: 'right' },
             { label: c.t('prayer.dhuhr'), align: 'right' }, { label: c.t('prayer.maghrib'), align: 'right' }],
      rows: c.upcomingPrayerDays(4).map(function (d) {
        return { cells: [UI.esc(d.label), c.time(d.fajr.h, d.fajr.m), c.time(d.dhuhr.h, d.dhuhr.m),
                         c.time(d.maghrib.h, d.maghrib.m)] };
      })
    });

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city, act: 'sheet:personalise' },
        { label: c.dateLong(new Date()) },
        { label: c.hijri().label }
      ]) }) +
      UI.section({ body: hero }) +
      UI.section({ title: c.t('prayer.today'), body: line }) +
      UI.section({ title: c.t('sun.title'), body: sunCard }) +
      UI.section({ title: c.t('prayer.upcoming'), body: upcoming }) +
      UI.section({ title: c.t('prayer.settings'), body: method });
  });

  /* ---------------------------------------------------------
     24.2 Qibla — instrument
     --------------------------------------------------------- */
  T.register('qibla', function (c) {
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
  });

  /* ---------------------------------------------------------
     24.3 Nearby Mosques — map + list
     --------------------------------------------------------- */
  T.register('mosques', function (c) {
    var list = c.nearbyMosques();
    var radius = c.filter('radius', '3');
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = list.filter(function (m) {
      if (m.km > Number(radius)) return false;
      if (query && m.name.toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ flush: true, body: UI.contextBar([{ icon: 'i-pin', label: c.profile.city, act: 'sheet:personalise' }]) }) +
      UI.section({ body: UI.map({
        label: c.t('mosques.map'),
        caption: c.profile.city,
        markers: list.map(function (m, i) {
          return { x: m.x, y: m.y, icon: 'i-mosque', label: m.name, active: i === 0 };
        })
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('mosques.search'), target: 'mosques', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'radius', label: c.t('mosques.radius'), items: [
        { value: '1', label: c.L.distance(1), on: radius === '1' },
        { value: '3', label: c.L.distance(3), on: radius === '3' },
        { value: '5', label: c.L.distance(5), on: radius === '5' }
      ] }], 'mosques') }) +
      UI.section({ title: c.t('mosques.nearby'), body: shown.length ? UI.rows(shown.map(function (m) {
        return UI.richRow({
          icon: 'i-mosque', iconTone: 'accent',
          title: m.name,
          sub: m.address,
          meta: [c.L.distance(m.km), m.walk + ' ' + c.t('unit.walk'), m.facilities.join(' · ')],
          value: c.time(m.next.h, m.next.m),
          valueSub: c.t('prayer.' + m.next.key),
          act: 'toast:' + m.name + ' · ' + c.L.distance(m.km),
          chevron: true
        });
      })) : UI.emptyState({ icon: 'i-mosque', title: c.t('mosques.noneNear'),
        text: c.t('mosques.noneNearText'),
        action: { label: c.L.distance(5), act: 'toolstate:mosques:radius:5', icon: 'i-navigation' } }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('mosques.directions'), tone: 'accent', icon: 'i-navigation', act: 'toast:' + c.t('mosques.opening') },
        { label: c.t('mosques.addyours'), icon: 'i-plus', act: 'toast:' + c.t('mosques.suggest') }
      ]) });
  });

  /* ---------------------------------------------------------
     24.4 Prayer Tracker — habit dashboard
     --------------------------------------------------------- */
  T.register('praytrack', function (c) {
    var tr = c.prayerTracker();
    var set = c.prayerTimes();

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('track.today'),
        value: tr.doneToday + ' <small>/ 5</small>',
        caption: c.t('track.streak', { n: tr.streak }),
        aside: UI.progressRing({ value: tr.doneToday / 5, centre: Math.round(tr.doneToday / 5 * 100) + '%', label: c.t('track.today') }),
        stats: [
          { value: tr.streak, label: c.t('track.streakLabel') },
          { value: Math.round(tr.month * 100) + '%', label: c.t('track.month') },
          { value: tr.qada, label: c.t('track.qada') }
        ]
      }) }) +
      UI.section({ title: c.t('track.mark'), body: UI.rows(set.map(function (p, i) {
        var done = i < tr.doneToday;
        return UI.richRow({
          icon: done ? 'i-check-circle' : 'i-prayer', iconTone: done ? 'accent' : null,
          title: c.t('prayer.' + p.key),
          sub: c.time(p.h, p.m),
          value: done ? UI.statusBadge({ label: c.t('track.done'), tone: 'ok' })
                      : UI.statusBadge({ label: c.t('track.pending'), tone: 'neutral' }),
          act: 'track:' + p.key
        });
      })) }) +
      UI.section({ title: c.t('track.heat'), body: UI.card(
        UI.heatmap({ days: tr.heat, label: c.t('track.heat'), less: c.t('common.less'), more: c.t('common.more') }),
        { pad: true }) }) +
      UI.section({ title: c.t('track.stats'), body: UI.card(
        UI.barChart({ values: tr.byPrayer, labels: ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
          label: c.t('track.byPrayer'), caption: c.t('track.byPrayerCap') })) }) +
      UI.section({ title: c.t('track.qadaPlan'), body: UI.card(
        UI.meterRow({ label: c.t('track.qadaOutstanding'), value: tr.qada + ' ' + c.t('track.prayers'),
          pct: 1 - tr.qada / 40, foot: c.t('track.qadaHint') }) +
        UI.buttonRow([{ label: c.t('track.logQada'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('track.qadaLogged') }])) });
  });

  /* ---------------------------------------------------------
     24.5 Ramadan — seasonal dashboard
     --------------------------------------------------------- */
  T.register('ramadan', function (c) {
    var r = c.ramadan();
    var sun = c.sunTimes();
    var set = c.prayerTimes();

    if (!r.active) {
      return UI.section({ body: UI.summaryCard({
          tone: 'night',
          kicker: c.t('ramadan.countdown'),
          value: r.daysUntil + ' <small>' + UI.esc(c.t('common.days')) + '</small>',
          caption: c.t('ramadan.starts', { date: r.startLabel }),
          stats: [
            { value: r.hijriYear, label: c.t('ramadan.year') },
            { value: r.expectedFasts, label: c.t('ramadan.fasts') },
            { value: c.time(sun.sunset.h, sun.sunset.m), label: c.t('ramadan.iftarToday') }
          ]
        }) }) +
        UI.section({ title: c.t('ramadan.prepare'), body: UI.rows([
          UI.richRow({ icon: 'i-check-circle', title: c.t('ramadan.prep.qada'), sub: c.t('ramadan.prep.qadaSub'), act: 'tool:fasting', chevron: true }),
          UI.richRow({ icon: 'i-book', title: c.t('ramadan.prep.quran'), sub: c.t('ramadan.prep.quranSub'), act: 'tool:quran', chevron: true }),
          UI.richRow({ icon: 'i-wallet', title: c.t('ramadan.prep.zakat'), sub: c.t('ramadan.prep.zakatSub'), act: 'tool:zakat', chevron: true })
        ]) }) +
        UI.section({ title: c.t('ramadan.dates'), body: UI.rows(D.ISLAMIC_EVENTS.map(function (e) {
          return UI.compactRow({ icon: 'i-moon-star', label: e.name, sub: e.hijri, value: e.greg });
        })) });
    }

    return UI.section({ body: UI.summaryCard({
        tone: 'night',
        kicker: c.t('ramadan.day', { n: r.day }),
        value: c.time(sun.sunset.h, sun.sunset.m),
        caption: c.t('ramadan.iftarIn', { time: r.iftarIn }),
        stats: [
          { value: c.time(sun.sunrise.h - 1, 42), label: c.t('ramadan.suhoor') },
          { value: c.time(sun.sunset.h, sun.sunset.m), label: c.t('ramadan.iftar') },
          { value: (30 - r.day) + '', label: c.t('ramadan.remaining') }
        ]
      }) }) +
      UI.section({ title: c.t('ramadan.dayTimeline'), body: UI.timeline([
        { time: c.time(sun.sunrise.h - 1, 42), title: c.t('ramadan.suhoorEnds'),
          sub: c.t('ramadan.suhoorSub'), icon: 'i-moon', state: 'done' }
      ].concat(set.map(function (p) {
        var now = new Date().getHours() * 60 + new Date().getMinutes();
        return { time: c.time(p.h, p.m), title: c.t('prayer.' + p.key),
          state: p.h * 60 + p.m < now ? 'done' : '' };
      })).concat([
        { time: c.time(sun.sunset.h, sun.sunset.m), title: c.t('ramadan.iftar'),
          sub: c.t('ramadan.iftarSub'), icon: 'i-utensils', state: '' },
        { time: c.time(20, 45), title: c.t('f.taraweeh'), sub: c.t('ramadan.taraweehSub'),
          icon: 'i-prayer', state: '' }
      ])) }) +
      UI.section({ title: c.t('ramadan.month'), body: UI.card(
        UI.heatmap({ days: r.heat, label: c.t('ramadan.month'),
          less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('ramadan.progress'), body: UI.card(
        UI.meterRow({ label: c.t('ramadan.fastsKept'), value: r.kept + ' / ' + r.day, pct: r.kept / Math.max(1, r.day) }) +
        UI.meterRow({ label: c.t('ramadan.quranJuz'), value: r.juz + ' / 30', pct: r.juz / 30 }) +
        UI.meterRow({ label: c.t('ramadan.charity'), value: c.money(r.charity) + ' / ' + c.money(r.charityGoal), pct: r.charity / r.charityGoal })) });
  });

  /* ---------------------------------------------------------
     24.6 Fasting Tracker
     --------------------------------------------------------- */
  T.register('fasting', function (c) {
    var f = c.fasting();
    var kind = c.filter('kind', 'all');
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('fast.thisMonth'),
        value: f.kept + ' <small>' + UI.esc(c.t('fast.days')) + '</small>',
        caption: c.t('fast.streak', { n: f.streak }),
        aside: UI.progressRing({ value: f.kept / f.target, centre: f.kept + '/' + f.target, label: c.t('fast.progress') }),
        stats: [
          { value: f.voluntary, label: c.t('fast.voluntary') },
          { value: f.obligatory, label: c.t('fast.obligatory') },
          { value: f.missed, label: c.t('fast.missed') }
        ]
      }) }) +
      UI.section({ body: UI.filterBar([{ id: 'kind', label: c.t('fast.kind'), items: [
        { value: 'all', label: c.t('common.all'), on: kind === 'all' },
        { value: 'sunnah', label: c.t('fast.sunnah'), on: kind === 'sunnah' },
        { value: 'qada', label: c.t('fast.qada'), on: kind === 'qada' }
      ] }], 'fasting') }) +
      UI.section({ title: c.t('fast.calendar'), body: UI.card(
        UI.heatmap({ days: f.heat, label: c.t('fast.calendar'), less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('fast.recent'), body: UI.rows(f.recent.filter(function (d) {
        return kind === 'all' || d.kind === c.t('fast.' + kind);
      }).map(function (d) {
        return UI.richRow({
          icon: d.kept ? 'i-check-circle' : 'i-x', iconTone: d.kept ? 'accent' : null,
          title: d.label, sub: d.kind,
          value: UI.statusBadge({ label: d.kept ? c.t('fast.kept') : c.t('fast.notkept'), tone: d.kept ? 'ok' : 'neutral' })
        });
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('fast.log'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('fast.logged') }]) });
  });

  /* ---------------------------------------------------------
     24.7 Taraweeh — schedule + location
     --------------------------------------------------------- */
  T.register('taraweeh', function (c) {
    var list = c.nearbyMosques();
    var rakaat = c.filter('rakaat', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = list.filter(function (m) {
      if (rakaat !== 'all' && String(m.rakaat) !== rakaat) return false;
      if (query && m.name.toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city, act: 'sheet:personalise' },
        { label: c.t('taraweeh.season') }]) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('taraweeh.search'), target: 'taraweeh', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'rakaat', label: c.t('taraweeh.rakaat'), items: [
        { value: 'all', label: c.t('common.all'), on: rakaat === 'all' },
        { value: '8', label: '8 ' + c.t('taraweeh.rakaatShort'), on: rakaat === '8' },
        { value: '20', label: '20 ' + c.t('taraweeh.rakaatShort'), on: rakaat === '20' }
      ] }], 'taraweeh') }) +
      UI.section({ body: UI.map({
        label: c.t('taraweeh.map'), caption: c.profile.city,
        markers: shown.map(function (m, i) {
          return { x: m.x, y: m.y, icon: 'i-mosque', label: m.name, active: i === 0 };
        })
      }) }) +
      UI.section({ title: c.t('taraweeh.nearby'), body: shown.length ? UI.rows(shown.map(function (m) {
        return UI.richRow({
          icon: 'i-mosque', iconTone: 'accent',
          title: m.name, sub: m.address,
          meta: [c.L.distance(m.km), m.rakaat + ' ' + c.t('taraweeh.rakaatShort'), m.reciter],
          value: c.time(m.taraweeh.h, m.taraweeh.m), valueSub: c.t('taraweeh.starts'),
          act: 'toast:' + m.name, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-mosque', title: c.t('taraweeh.noMatch'),
        text: c.t('taraweeh.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:taraweeh:rakaat:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('taraweeh.selected'), body: UI.card(
        UI.metrics([
          { icon: 'i-clock', value: c.time(shown[0] ? shown[0].taraweeh.h : 20, shown[0] ? shown[0].taraweeh.m : 45),
            label: c.t('taraweeh.starts') },
          { icon: 'i-route', value: c.L.distance(shown[0] ? shown[0].km : 0), label: c.t('qibla.distance') },
          { icon: 'i-beads', value: String(shown[0] ? shown[0].rakaat : 20), label: c.t('taraweeh.rakaat') }
        ], 3)) }) +
      UI.section({ body: UI.noteCard({ icon: 'i-bell', tone: 'info',
        title: c.t('taraweeh.remind.title'), text: c.t('taraweeh.remind.text') }) });
  });

  /* ---------------------------------------------------------
     24.8 Ayah of the Day — reader card
     --------------------------------------------------------- */
  T.register('ayah', function (c) {
    var a = c.ayahOfDay();
    return UI.section({ body: UI.card(
      '<p class="reader__ref">' + UI.esc(a.surah) + ' · ' + a.s + ':' + a.a + '</p>' +
      '<p class="arabic arabic--lg">' + UI.esc(a.ar) + '</p>' +
      '<p class="reader__tl">' + UI.esc(a.tl) + '</p>' +
      '<p class="reader__tr">' + UI.esc(a.tr) + '</p>' +
      '<div class="reader__acts">' +
        UI.button({ label: c.t('common.share'), icon: 'i-share', tone: 'accent', act: 'share:ayah' }) +
        UI.button({ label: c.t('common.save'), icon: 'i-bookmark', act: 'bookmark:ayah' }) +
        UI.button({ label: c.t('reader.listen'), icon: 'i-play', act: 'toast:' + c.t('reader.playing') }) +
      '</div>', { tone: 'reader' }) }) +
      UI.section({ title: c.t('ayah.tafsir'), body: UI.card(
        '<p class="kard__lead">' + UI.esc(a.tafsir) + '</p>', { tone: 'quiet' }) }) +
      UI.section({ title: c.t('ayah.more'), body: UI.rows(D.AYAT.map(function (x) {
        return UI.richRow({ icon: 'i-book', title: x.surah + ' ' + x.s + ':' + x.a,
          sub: x.tr.slice(0, 62) + '…', act: 'tool:quran', chevron: true });
      })) });
  });

  /* ---------------------------------------------------------
     24.9 Al-Qur'an — reader + library
     --------------------------------------------------------- */
  T.register('quran', function (c) {
    var p = c.quranProgress();
    var view = c.filter('quranview', 'surah');
    var query = (c.state('q') || '').trim().toLowerCase();
    var surahs = D.SURAHS.filter(function (s) {
      return !query || (s.name + ' ' + s.meaning + ' ' + s.n).toLowerCase().indexOf(query) !== -1;
    });
    var juzList = [];
    for (var j = 1; j <= 30; j++) {
      juzList.push({ n: j, start: D.SURAHS[(j - 1) % D.SURAHS.length].name, pages: 20 });
    }
    var bookmarks = [
      { surah: 'Al-Kahf', ayah: 42, when: c.t('common.yesterday') },
      { surah: 'Ar-Rahman', ayah: 13, when: '4 Sep' }
    ];
    return UI.section({ body: UI.card(
        '<div class="continue">' +
          '<div class="continue__body">' +
            '<p class="continue__kicker">' + UI.esc(c.t('quran.continue')) + '</p>' +
            '<p class="continue__title">' + UI.esc(p.surah) + ' · ' + UI.esc(c.t('quran.ayah')) + ' ' + p.ayah + '</p>' +
            '<p class="continue__meta">' + UI.esc(c.t('quran.juz')) + ' ' + p.juz + ' · ' +
              UI.esc(c.t('quran.lastread', { when: p.lastRead })) + '</p>' +
          '</div>' +
          UI.progressRing({ value: p.pct, centre: Math.round(p.pct * 100) + '%', label: c.t('quran.progress') }) +
        '</div>' +
        UI.progressBar({ value: p.pct, label: c.t('quran.progress') }) +
        UI.buttonRow([{ label: c.t('quran.resume'), tone: 'accent', icon: 'i-play', act: 'toast:' + p.surah + ' ' + p.ayah }])) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('quran.search'), target: 'quran', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.segmented({ id: 'quranview', label: c.t('quran.browse'), tool: 'quran', items: [
        { value: 'surah', label: c.t('quran.surah'), on: view === 'surah' },
        { value: 'juz', label: c.t('quran.juz'), on: view === 'juz' },
        { value: 'bookmarks', label: c.t('quran.bookmarks'), on: view === 'bookmarks' }
      ] }) }) +
      (view === 'juz'
        ? UI.section({ title: c.t('quran.juzList'), body: UI.rows(juzList.map(function (j) {
            return UI.richRow({
              logo: String(j.n), logoTone: 'var(--tint-neutral)',
              title: c.t('quran.juz') + ' ' + j.n, sub: j.start,
              meta: [c.t('quran.pages', { n: j.pages })],
              value: j.n <= p.juz ? UI.statusBadge({ label: c.t('common.done'), tone: 'ok' }) : '',
              act: 'toast:' + c.t('quran.juz') + ' ' + j.n, chevron: true
            });
          })) })
        : view === 'bookmarks'
        ? UI.section({ title: c.t('quran.bookmarks'), body: bookmarks.length
            ? UI.rows(bookmarks.map(function (b) {
                return UI.richRow({ icon: 'i-bookmark', iconTone: 'accent', title: b.surah,
                  sub: c.t('quran.ayah') + ' ' + b.ayah, meta: [b.when], act: 'toast:' + b.surah, chevron: true });
              }))
            : UI.emptyState({ icon: 'i-bookmark', title: c.t('quran.noBookmarks'),
                text: c.t('quran.noBookmarksText') }) })
        : UI.section({ title: c.t('quran.surahs'), body: surahs.length ? UI.rows(surahs.map(function (s) {
            return UI.richRow({
              logo: String(s.n), logoTone: 'var(--tint-accent)',
              title: s.name, sub: s.meaning,
              meta: [s.ayat + ' ' + c.t('quran.ayat'), c.t('quran.' + s.place.toLowerCase())],
              value: '<span class="arabic">' + UI.esc(s.ar) + '</span>',
              act: 'toast:' + s.name, chevron: true
            });
          })) : UI.emptyState({ icon: 'i-search', title: c.t('quran.noMatch'), text: c.t('quran.noMatchText') }) })) +
      UI.section({ title: c.t('quran.reader'), body: UI.card(
        UI.rows([
          UI.compactRow({ icon: 'i-globe', label: c.t('quran.translation'), value: c.t('quran.translation.value'), act: 'toast:' + c.t('quran.translation.change') }),
          UI.compactRow({ icon: 'i-play', label: c.t('quran.reciter'), value: 'Mishary Alafasy', act: 'toast:' + c.t('quran.reciter.change') }),
          UI.compactRow({ icon: 'i-ruler', label: c.t('quran.textsize'), value: c.t('common.medium') }),
          UI.compactRow({ icon: 'i-eye', label: c.t('quran.transliteration'), value: c.t('common.on') })
        ], { flat: true }), { pad: false }) });
  });

  /* ---------------------------------------------------------
     24.10 Search the Qur'an — search explorer
     --------------------------------------------------------- */
  T.register('quransearch', function (c) {
    var results = c.quranSearch(c.state('q') || '');
    return UI.section({ body: UI.searchBar({
        placeholder: c.t('quransearch.placeholder'), target: 'quransearch', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([
        { id: 'scope', label: c.t('quransearch.scope'), items: [
          { value: 'all', label: c.t('common.all'), on: true },
          { value: 'ar', label: c.t('quransearch.arabic') },
          { value: 'tr', label: c.t('quransearch.translation') }
        ] },
        { id: 'place', label: c.t('quransearch.revealed'), items: [
          { value: 'meccan', label: c.t('quran.meccan') },
          { value: 'medinan', label: c.t('quran.medinan') }
        ] }
      ]) }) +
      (results.length
        ? UI.section({ title: c.t('quransearch.results', { n: results.length }), body: UI.rows(results.map(function (r) {
            return UI.richRow({
              logo: r.s + ':' + r.a, logoTone: 'var(--tint-accent)',
              title: r.surah, sub: r.tr,
              meta: [c.t('quran.ayah') + ' ' + r.a, r.place || ''],
              act: 'tool:quran', chevron: true
            });
          })) })
        : UI.section({ body: UI.emptyState({
            icon: 'i-search', title: c.t('quransearch.empty.title'), text: c.t('quransearch.empty.text') }) })) +
      UI.section({ title: c.t('quransearch.suggested'), body: '<div class="chips">' +
        ['rahman', 'sabr', 'light', 'mercy', 'ar-rahman', 'yaseen'].map(function (s) {
          return '<button class="chip" data-act="toolsearch:quransearch:' + s + '">' + UI.esc(s) + '</button>';
        }).join('') + '</div>' });
  });

  /* ---------------------------------------------------------
     24.11 Hadith — library + reader
     --------------------------------------------------------- */
  T.register('hadith', function (c) {
    var h = D.HADITH[c.dayIndex(D.HADITH.length)];
    var coll = c.filter('collection', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = D.HADITH.filter(function (x) {
      if (coll !== 'all' && x.collection !== coll) return false;
      if (query && (x.text + ' ' + x.narrator + ' ' + x.src).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ body: UI.card(
        '<p class="reader__ref">' + UI.esc(h.src) + ' · ' + UI.esc(h.ref) + '</p>' +
        '<p class="reader__body">' + UI.esc(h.text) + '</p>' +
        '<div class="metaline">' +
          '<span>' + UI.esc(c.t('hadith.narrator')) + ': ' + UI.esc(h.narrator) + '</span>' +
          UI.statusBadge({ label: h.grade, tone: h.grade === 'Sahih' ? 'ok' : 'info' }) +
        '</div>' +
        '<div class="reader__acts">' +
          UI.button({ label: c.t('common.share'), icon: 'i-share', tone: 'accent', act: 'share:hadith' }) +
          UI.button({ label: c.t('common.save'), icon: 'i-bookmark', act: 'bookmark:hadith' }) +
        '</div>', { tone: 'reader' }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('hadith.search'), target: 'hadith', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'collection', label: c.t('hadith.collection'), items: [
        { value: 'all', label: c.t('common.all'), on: coll === 'all' },
        { value: 'Bukhari', label: 'Bukhari', count: 7563, on: coll === 'Bukhari' },
        { value: 'Muslim', label: 'Muslim', count: 5362, on: coll === 'Muslim' },
        { value: 'Tabarani', label: 'Tabarani', count: 3956, on: coll === 'Tabarani' }
      ] }], 'hadith') }) +
      UI.section({ title: c.t('hadith.browse'), body: shown.length ? UI.rows(shown.map(function (x) {
        return UI.richRow({
          icon: 'i-quote',
          title: x.text.length > 58 ? x.text.slice(0, 58) + '…' : x.text,
          sub: x.src + ' · ' + x.ref,
          meta: [x.narrator, x.grade],
          badge: { label: x.grade, tone: x.grade === 'Sahih' ? 'ok' : 'info' },
          act: 'toast:' + x.src + ' ' + x.ref, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-quote', title: c.t('hadith.noMatch'), text: c.t('hadith.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:hadith:collection:all', icon: 'i-refresh' } }) });
  });

  /* ---------------------------------------------------------
     24.12 Daily Duas — category library
     --------------------------------------------------------- */
  T.register('duas', function (c) {
    var featured = D.DUAS[c.dayIndex(D.DUAS.length)];
    var cat = c.filter('cat', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var catLabel = (D.DUA_CATEGORIES.filter(function (x) { return x.id === cat; })[0] || {}).label || '';
    var shown = D.DUAS.filter(function (d) {
      if (cat !== 'all' && d.cat !== cat) return false;
      if (query && (d.title + ' ' + d.tr).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ body: UI.card(
        '<p class="reader__ref">' + UI.esc(c.t('duas.today')) + ' · ' + UI.esc(featured.title) + '</p>' +
        '<p class="arabic arabic--lg">' + UI.esc(featured.ar) + '</p>' +
        '<p class="reader__tr">' + UI.esc(featured.tr) + '</p>' +
        '<p class="reader__src">' + UI.esc(featured.src) + '</p>' +
        '<div class="reader__acts">' +
          UI.button({ label: c.t('common.share'), icon: 'i-share', tone: 'accent', act: 'share:dua' }) +
          UI.button({ label: c.t('reader.listen'), icon: 'i-play', act: 'toast:' + c.t('reader.playing') }) +
        '</div>', { tone: 'reader' }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('duas.search'), target: 'duas', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('duas.categories'), body: '<div class="tiles">' +
        D.DUA_CATEGORIES.map(function (x) {
          var count = D.DUAS.filter(function (d) { return d.cat === x.id; }).length;
          return '<button class="tile pressable' + (cat === x.id ? ' is-on' : '') +
            '" data-act="toolstate:duas:cat:' + x.id + '" aria-pressed="' + (cat === x.id ? 'true' : 'false') + '">' +
            '<span class="tile__icon">' + UI.ico(x.icon) + '</span>' +
            '<span class="tile__label">' + UI.esc(x.label) + '</span>' +
            '<span class="tile__meta">' + count + ' ' + UI.esc(c.t('duas.count')) + '</span>' +
          '</button>';
        }).join('') + '</div>' }) +
      UI.section({ title: cat === 'all' ? c.t('duas.all') : c.t('duas.inCategory', { name: catLabel }),
        link: cat === 'all' ? null : { label: c.t('common.all'), act: 'toolstate:duas:cat:all' },
        body: shown.length ? UI.rows(shown.map(function (d) {
          return UI.richRow({
            icon: 'i-heart', iconTone: 'accent',
            title: d.title, sub: d.tr,
            meta: [d.src],
            value: '<span class="arabic">' + UI.esc(d.ar.slice(0, 16)) + '</span>',
            act: 'share:duas', chevron: true
          });
        })) : UI.emptyState({ icon: 'i-heart', title: c.t('duas.noMatch'), text: c.t('duas.noMatchText'),
          action: { label: c.t('common.all'), act: 'toolstate:duas:cat:all', icon: 'i-refresh' } }) });
  });

  /* ---------------------------------------------------------
     24.13 99 Names — learning grid + detail
     --------------------------------------------------------- */
  T.register('names99', function (c) {
    var learned = 12;
    var query = (c.state('q') || '').trim().toLowerCase();
    var names = D.NAMES99.filter(function (n) {
      return !query || (n.tl + ' ' + n.meaning).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('names.title'),
        value: learned + ' <small>/ 99</small>',
        caption: c.t('names.learned'),
        aside: UI.progressRing({ value: learned / 99, centre: Math.round(learned / 99 * 100) + '%', label: c.t('names.progress') })
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('names.search'), target: 'names99', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('names.all'), body: names.length ? '<div class="ngrid">' +
        names.map(function (n) {
          return '<button class="ncard pressable" data-act="toast:' + UI.esc(n.tl + ' — ' + n.meaning) + '">' +
            '<span class="ncard__n">' + n.n + '</span>' +
            '<span class="ncard__ar arabic">' + UI.esc(n.ar) + '</span>' +
            '<span class="ncard__tl">' + UI.esc(n.tl) + '</span>' +
            '<span class="ncard__meaning">' + UI.esc(n.meaning) + '</span>' +
          '</button>';
        }).join('') + '</div>'
        : UI.emptyState({ icon: 'i-search', title: c.t('names.noMatch'), text: c.t('names.noMatchText') }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('names.practise'), tone: 'accent', icon: 'i-play', act: 'toast:' + c.t('names.practising') },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:names99' }]) });
  });

  /* ---------------------------------------------------------
     24.14 Islamic Calendar
     --------------------------------------------------------- */
  T.register('hijri', function (c) {
    var h = c.hijri();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('hijri.today'),
        value: h.day + ' ' + UI.esc(h.month),
        unit: h.year + ' AH',
        caption: c.dateLong(new Date())
      }) }) +
      UI.section({ body: c.monthGrid() }) +
      UI.section({ title: c.t('hijri.events'), body: UI.rows(D.ISLAMIC_EVENTS.map(function (e) {
        return UI.richRow({ icon: 'i-moon-star', iconTone: 'accent', title: e.name, sub: e.hijri,
          meta: [e.greg], value: c.t('common.inDays', { n: e.days }) });
      })) }) +
      UI.section({ title: c.t('hijri.convert'), body: UI.card(
        UI.formGrid([
          UI.field({ label: c.t('hijri.gregorian'), name: 'greg', type: 'date', value: c.isoToday() }),
          UI.field({ label: c.t('hijri.hijri'), name: 'hij', value: h.day + ' ' + h.month + ' ' + h.year })
        ])) }) +
      UI.section({ title: c.t('hijri.months'), body: UI.rows(D.HIJRI_MONTHS.map(function (m, i) {
        return UI.compactRow({ label: m, value: String(i + 1), chevron: false });
      }), { flat: true }) });
  });

  /* ---------------------------------------------------------
     24.15 Tasbih — focused interaction, deliberately low density
     --------------------------------------------------------- */
  T.register('tasbih', function (c) {
    var s = c.tasbih();
    var dh = D.DHIKR[s.dhikrIndex];
    return '<div class="tasbih">' +
      '<div class="tasbih__pick">' +
        D.DHIKR.map(function (d, i) {
          return '<button class="tasbih__opt' + (i === s.dhikrIndex ? ' is-on' : '') + '" data-dhikr="' + i + '">' +
            UI.esc(d.tl) + '</button>';
        }).join('') +
      '</div>' +
      '<p class="tasbih__ar arabic">' + UI.esc(dh.ar) + '</p>' +
      '<p class="tasbih__tr">' + UI.esc(dh.tr) + '</p>' +
      '<button class="tasbih__counter pressable" data-tasbih-count aria-label="' + UI.esc(c.t('tasbih.count')) + '">' +
        '<svg class="tasbih__ring" viewBox="0 0 200 200" aria-hidden="true">' +
          '<circle cx="100" cy="100" r="88" class="tasbih__ringbg" fill="none" stroke-width="8"/>' +
          '<circle cx="100" cy="100" r="88" class="tasbih__ringfg" fill="none" stroke-width="8"' +
            ' stroke-dasharray="' + (2 * Math.PI * 88).toFixed(1) + '"' +
            ' stroke-dashoffset="' + ((1 - s.count / dh.target) * 2 * Math.PI * 88).toFixed(1) + '"' +
            ' data-tasbih-ring/>' +
        '</svg>' +
        '<span class="tasbih__num" data-tasbih-num>' + s.count + '</span>' +
        '<span class="tasbih__target" data-tasbih-target>' + c.t('tasbih.of', { n: dh.target }) + '</span>' +
      '</button>' +
      '<div class="tasbih__acts">' +
        UI.button({ label: c.t('tasbih.reset'), icon: 'i-refresh', act: 'tasbihreset' }) +
        UI.button({ label: c.t('tasbih.sets', { n: s.sets }), icon: 'i-beads' }) +
      '</div>' +
    '</div>' +
    UI.section({ title: c.t('tasbih.history'), body: UI.rows(s.history.map(function (h) {
      return UI.compactRow({ icon: 'i-beads', label: h.dhikr, sub: h.when, value: String(h.count) });
    })) });
  });

  /* ---------------------------------------------------------
     24.16 Zakat — calculator + financial breakdown
     --------------------------------------------------------- */
  T.register('zakat', function (c) {
    var z = c.zakat();
    return UI.section({ flush: true, body: UI.contextBar([
        { label: c.t('zakat.nisabGold') + ': ' + c.moneyRaw(z.nisabGold, c.L.currencyCode(), 0) },
        { label: c.t('zakat.rate') + ': 2.5%' }]) }) +
      UI.section({ id: 'inputs', title: c.t('zakat.assets'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('zakat.cash'), name: 'z_cash', type: 'number', value: z.f.cash, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('zakat.gold'), name: 'z_gold', type: 'number', value: z.f.gold, suffix: c.t('unit.gram') }),
        UI.field({ label: c.t('zakat.silver'), name: 'z_silver', type: 'number', value: z.f.silver, suffix: c.t('unit.gram') }),
        UI.field({ label: c.t('zakat.investments'), name: 'z_inv', type: 'number', value: z.f.inv, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('zakat.business'), name: 'z_biz', type: 'number', value: z.f.biz, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('zakat.liabilities'), name: 'z_liab', type: 'number', value: z.f.liab, prefix: c.L.currencyCode() })
      ])) }) +
      UI.section({ id: 'result', body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('zakat.payable'),
        value: '<span data-zakat-total>' + c.moneyRaw(z.due, c.L.currencyCode(), 0) + '</span>',
        caption: z.eligible ? c.t('zakat.aboveNisab') : c.t('zakat.belowNisab'),
        stats: [
          { value: '<span data-zakat-net>' + c.moneyRaw(z.net, c.L.currencyCode(), 0) + '</span>', label: c.t('zakat.netAssets') },
          { value: c.moneyRaw(z.nisabGold, c.L.currencyCode(), 0), label: c.t('zakat.nisab') },
          { value: '2.5%', label: c.t('zakat.rate') }
        ]
      }) }) +
      UI.section({ id: 'breakdown', title: c.t('zakat.breakdown'), body: UI.table({
        label: c.t('zakat.breakdown'),
        cols: [{ label: c.t('zakat.item') }, { label: c.t('zakat.value'), align: 'right' }],
        rows: z.lines.map(function (l) {
          return { cells: [UI.esc(l.label), c.moneyRaw(l.value, c.L.currencyCode(), 0)] };
        })
      }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('common.share'), icon: 'i-share', tone: 'accent', act: 'share:zakat' },
        { label: c.t('common.export'), icon: 'i-download', act: 'export:zakat' }]) });
  });

  /* ---------------------------------------------------------
     24.17 Faraid — guided calculator, progressive steps
     --------------------------------------------------------- */
  T.register('faraid', function (c) {
    var fr = c.faraid();
    return UI.section({ body: UI.noteCard({ icon: 'i-info', tone: 'info',
        title: c.t('faraid.note.title'), text: c.t('faraid.note.text') }) }) +
      UI.section({ body: '<ol class="steps">' +
        [c.t('faraid.step.estate'), c.t('faraid.step.debts'), c.t('faraid.step.heirs'), c.t('faraid.step.shares')]
          .map(function (label, i) {
            return '<li class="steps__item' + (i === fr.step ? ' is-on' : i < fr.step ? ' is-done' : '') + '">' +
              '<b>' + (i + 1) + '</b><span>' + UI.esc(label) + '</span></li>';
          }).join('') + '</ol>' }) +
      UI.section({ title: c.t('faraid.estate'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('faraid.gross'), name: 'fa_gross', type: 'number', value: fr.gross, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('faraid.debts'), name: 'fa_debts', type: 'number', value: fr.debts, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('faraid.bequest'), name: 'fa_bequest', type: 'number', value: fr.bequest, prefix: c.L.currencyCode(),
          hint: c.t('faraid.bequestHint') })
      ])) }) +
      UI.section({ title: c.t('faraid.heirs'), body: UI.rows(fr.heirs.map(function (h) {
        return UI.richRow({ icon: 'i-users', title: h.label, sub: h.rule,
          value: UI.stepper({ name: 'heir_' + h.id, value: h.n, label: h.label }) });
      })) }) +
      UI.section({ title: c.t('faraid.distribution'), body: UI.card(
        UI.donut({
          label: c.t('faraid.distribution'),
          centre: c.moneyRaw(fr.net, c.L.currencyCode(), 0),
          centreSub: c.t('faraid.net'),
          slices: fr.shares.map(function (s) {
            return { label: s.label, value: s.amount, color: s.color, display: s.fraction };
          })
        })) }) +
      UI.section({ title: c.t('faraid.explain'), body: UI.rows(fr.shares.map(function (s) {
        return UI.expandRow({
          head: '<span class="xrow__title">' + UI.esc(s.label) + '</span>' +
                '<span class="xrow__value">' + UI.esc(s.fraction) + ' · ' + c.moneyRaw(s.amount, c.L.currencyCode(), 0) + '</span>',
          body: '<p>' + UI.esc(s.reason) + '</p>'
        });
      })) });
  });
})();
