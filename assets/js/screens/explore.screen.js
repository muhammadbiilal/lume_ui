/* ============================================================
   Lume — Explore screen

   Useful context beyond the user's own plan: the weather where
   they actually are, what is around them, live sport when it is
   eligible, the news, and a few curated ways in.

   Everything here is localised rather than translated. The
   temperature follows the chosen units, the sunset follows the
   city and time zone, and the news follows the country — so
   this screen must never show a market, a unit or a venue from
   somewhere the user is not.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $ } from '../core/dom.js';

export function createExploreScreen(ctx) {


  /* ---------------------------------------------------------
     Around you — the regional configuration made visible

     It lists whichever local services this country actually has,
     with a live value pulled from the same context the tool screen
     uses. Nothing here knows the name of a country: each entry asks
     the eligibility selector whether its feature exists, and the
     ones that do not simply do not appear.
     --------------------------------------------------------- */
  const LOCAL_SERVICES = [
    { id: 'fuel', icon: 'i-fuel',
      value: function () {
        const f = ctx.data.fuelFor(ctx.profile().country);
        return ctx.L.moneyRaw(f.items[0].v, f.ccy, 2);
      },
      sub: function () {
        /* Fuel grades carry a translation key, not a name — reading `.n`
           here used to render the row as a row of empty separators. */
        return ctx.data.fuelFor(ctx.profile().country).items
          .slice(0, 3)
          .map(function (item) { return ctx.t(item.nk); })
          .join(' · ');
      } },
    { id: 'loadshed', icon: 'i-bolt',
      value: function (c) {
        const ls = c.loadshed();
        return ls.now ? ls.endsIn : ls.slot.from;
      },
      sub: function (c) {
        const ls = c.loadshed();
        return ls.area + ' · ' + (ls.now
          ? ctx.t('loadshed.currentlyOff')
          : ctx.t('loadshed.nextOutage', { from: ls.slot.from, to: ls.slot.to }));
      } },
    { id: 'goldrates', icon: 'i-coins',
      value: function (c) {
        const g = c.metals();
        return ctx.L.moneyRaw(g.gold.perTola, g.ccy, 0);
      },
      sub: function () { return ctx.t('rates.openMarket') + ' · ' + ctx.t('rates.gold24'); } },
    { id: 'trains', icon: 'i-train',
      value: function () { return ''; },
      sub: function () {
        const train = ctx.data.TRAINS[0];
        return train.name + ' · ' + ctx.t(train.statusKey, { n: train.delay });
      } },
    { id: 'emergency', icon: 'i-shield',
      value: function () { return ctx.data.emergencyFor(ctx.profile().country)[0].num; },
      sub: function () { return ctx.data.emergencyFor(ctx.profile().country)[0].n; } },
    { id: 'holidays', icon: 'i-calendar',
      value: function () { return ctx.data.holidaysFor(ctx.profile().country)[0].date; },
      sub: function () { return ctx.data.holidaysFor(ctx.profile().country)[0].name; } }
  ];

  function renderAround(root) {
    const wrap = $('#aroundWrap', root), host = $('#aroundList', root), tag = $('#aroundTag', root);
    if (!wrap || !host) return;
    const esc = ctx.ui.esc;

    const rows = [];
    LOCAL_SERVICES.forEach(function (svc) {
      const f = ctx.eligible.feature(svc.id);
      if (!f || !ctx.eligible.visible(f)) return;
      const c = ctx.toolCtx(svc.id);
      let value = '', sub = '';
      /* A service that cannot answer right now is left out rather than
         shown with a blank where its number should be. */
      try { value = svc.value(c); sub = svc.sub(c); } catch (e) { return; }
      rows.push('<button class="list-row pressable" data-act="tool:' + f.id + '" data-fid="' + f.id + '">' +
        '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + svc.icon + '"/></svg></span>' +
        '<span class="list-row__body"><span class="list-row__title">' + esc(ctx.eligible.name(f)) + '</span>' +
        '<span class="list-row__sub">' + esc(sub) + '</span></span>' +
        '<span class="list-row__end">' + (value ? '<span class="list-row__value num">' + esc(value) + '</span>' : '') +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span></button>');
    });

    /* One local service is not a section. */
    wrap.hidden = rows.length < 2;
    host.innerHTML = rows.join('');
    if (tag) tag.textContent = ctx.L.countryName(ctx.profile().country);
  }

  /* ---------------------------------------------------------
     Weather — the city's, in the user's units
     --------------------------------------------------------- */
  /* The two subtitles that say what this screen is showing and where. */
  function renderHeadings(root) {
    const t = ctx.t, profile = ctx.profile();

    const sub = $('#exploreSub', root);
    if (sub) {
      sub.textContent = t(ctx.eligible.localisedCountries().indexOf(profile.country) !== -1
        ? 'explore.subLocal' : 'explore.subGlobal');
    }

    const weatherSub = $('#weatherSub', root);
    if (weatherSub) weatherSub.textContent = t('explore.weatherSub', { city: profile.city, n: ctx.L.num(4) });
  }

  function renderWeather(root) {
    const L = ctx.L, esc = ctx.ui.esc, profile = ctx.profile();
    const w = ctx.catalogue.weatherFor(profile.country, L.country().tz);

    function set(id, value) {
      const el = $(id, root);
      if (el) el.textContent = value;
    }

    set('#weatherCity', profile.city);
    set('#weatherDesc', w.desc + ' · ' + L.temp(w.feels));
    set('#weatherRain', L.num(w.rain / 100, { style: 'percent' }));
    set('#weatherWind', L.speed(w.wind));

    const temp = $('#weatherTemp', root);
    if (temp) temp.innerHTML = esc(L.temp(w.temp)).replace('°', '<sup>°</sup>');

    const icon = $('#weatherIcon use', root);
    if (icon) icon.setAttribute('href', '#' + w.icon);

    /* Sunset comes from the same solar calculation the prayer times use,
       so the two cannot disagree about when the sun goes down here. */
    const sunset = $('#weatherSunset', root);
    if (sunset) {
      const times = ctx.prayer.times();
      const maghrib = times.filter(function (x) { return x.name === 'Maghrib'; })[0] || times[4];
      sunset.textContent = L.time(maghrib.h, maghrib.m);
    }
  }

  /* ---------------------------------------------------------
     News — local where there is a local edition, global otherwise
     --------------------------------------------------------- */
  const TONES = {
    accent: ['#E7F4F1', '#A5DED4', '#10998A'],
    violet: ['#EDEAFB', '#B7AEF6', '#6E62E5'],
    amber: ['#FBEEDD', '#EFC894', '#C9793F']
  };

  function renderNews(root) {
    const host = $('#newsList', root);
    if (!host) return;
    const esc = ctx.ui.esc;
    const items = ctx.profile().country === 'PK' ? ctx.catalogue.NEWS.PK : ctx.catalogue.NEWS.GLOBAL;

    host.innerHTML = items.map(function (article, i) {
      const tone = TONES[article.tone] || TONES.accent;
      return '<button class="article pressable" data-toast="Opening the story">' +
        '<span class="article__art"><svg viewBox="0 0 62 62"><defs>' +
          '<linearGradient id="nw' + i + '" x1="0" y1="0" x2="1" y2="1">' +
          '<stop offset="0" stop-color="' + tone[0] + '"/><stop offset="1" stop-color="' + tone[1] + '"/></linearGradient></defs>' +
          '<rect width="62" height="62" fill="url(#nw' + i + ')"/>' +
          '<circle cx="44" cy="18" r="12" fill="' + tone[2] + '" opacity=".3"/>' +
          '<path d="M0 48c12-8 20 4 32-3s18-14 30-8v25H0z" fill="' + tone[2] + '" opacity=".3"/></svg></span>' +
        '<span class="article__body">' +
          '<span class="article__cat">' + esc(article.cat) + '</span>' +
          '<span class="article__title">' + esc(article.title) + '</span>' +
          '<span class="article__meta">' + esc(article.meta) + '</span>' +
        '</span></button>';
    }).join('');
  }

  return defineScreen({
    id: 'explore',
    template: function () {
      return `
  <section class="screen" id="screen-explore" role="tabpanel" aria-label="Explore">

    <div class="page-head">
      <div class="page-head__bar">
        <!-- Explore is reachable in Pakistan even though it is not a tab
             there, so it carries its own way back. The router shows it only
             when no tab is selected. -->
        <button class="iconbtn pressable" id="exploreBack" data-act="tab:home" aria-label="Back to home" hidden>
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-l"/></svg>
        </button>
        <div>
          <h1 class="page-head__title" data-i18n="explore.title">Explore</h1>
          <p class="page-head__sub" id="exploreSub">What’s happening around you</p>
        </div>
        <button class="iconbtn pressable" data-sheet="search" aria-label="Search everything">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg>
        </button>
      </div>
    </div>

    <!-- Featured — Islamic edition -->
    <div class="section" style="margin-top:18px" data-faith="islamic">
      <article class="feature pressable" data-toast="Opening “Forty duas for ordinary days”">
        <div class="feature__art" aria-hidden="true">
          <svg viewBox="0 0 350 216" preserveAspectRatio="xMidYMid slice">
            <circle cx="300" cy="26" r="80" fill="#fff" opacity=".09"/>
            <circle cx="320" cy="200" r="64" fill="#04322C" opacity=".18"/>
            <g transform="translate(238 44)">
              <circle cx="46" cy="46" r="42" fill="none" stroke="#fff" stroke-opacity=".25" stroke-width="1.5"/>
              <circle cx="46" cy="46" r="28" fill="none" stroke="#fff" stroke-opacity=".18" stroke-width="1.5"/>
              <path d="M46 4v84M4 46h84" stroke="#fff" stroke-opacity=".12" stroke-width="1.2"/>
              <path d="m46 22 5.4 13.6L65 41l-13.6 5.4L46 60l-5.4-13.6L27 41l13.6-5.4z" fill="#fff" opacity=".8"/>
            </g>
            <path d="m206 40 2.6 6.4 6.4 2.6-6.4 2.6-2.6 6.4-2.6-6.4-6.4-2.6 6.4-2.6z" fill="#fff" opacity=".6"/>
            <circle cx="196" cy="110" r="4" fill="#fff" opacity=".3"/>
            <path d="M-10 176c56-20 92 14 144-2s94-48 148-26" stroke="#fff" stroke-opacity=".12" stroke-width="1.5" fill="none"/>
          </svg>
        </div>
        <span class="feature__tag"><svg class="ico" viewBox="0 0 24 24"><use href="#i-sparkles"/></svg> Featured collection</span>
        <h2 class="feature__title">Forty duas for ordinary days</h2>
        <p class="feature__text">Short supplications for the commute, the queue and the quiet minute before sleep.</p>
        <p class="feature__meta"><span>40 duas</span><span class="dot"></span><span>Audio included</span><span class="dot"></span><span>12 min</span></p>
      </article>
    </div>

    <!-- Featured — everyone else -->
    <div class="section" style="margin-top:18px" data-faith="none">
      <article class="feature pressable" data-toast="Opening “A calmer week”">
        <div class="feature__art" aria-hidden="true">
          <svg viewBox="0 0 350 216" preserveAspectRatio="xMidYMid slice">
            <circle cx="300" cy="26" r="80" fill="#fff" opacity=".09"/>
            <circle cx="320" cy="200" r="64" fill="#04322C" opacity=".18"/>
            <g transform="translate(232 46)">
              <rect x="0" y="0" width="86" height="86" rx="26" fill="#fff" opacity=".2"/>
              <path d="M18 30h50M18 46h34M18 62h42" stroke="#fff" stroke-opacity=".55" stroke-width="4" stroke-linecap="round"/>
            </g>
            <path d="m206 40 2.6 6.4 6.4 2.6-6.4 2.6-2.6 6.4-2.6-6.4-6.4-2.6 6.4-2.6z" fill="#fff" opacity=".6"/>
            <circle cx="196" cy="110" r="4" fill="#fff" opacity=".3"/>
            <path d="M-10 176c56-20 92 14 144-2s94-48 148-26" stroke="#fff" stroke-opacity=".12" stroke-width="1.5" fill="none"/>
          </svg>
        </div>
        <span class="feature__tag"><svg class="ico" viewBox="0 0 24 24"><use href="#i-sparkles"/></svg> Featured collection</span>
        <h2 class="feature__title">A calmer week, in seven steps</h2>
        <p class="feature__text">Small routines for planning, spending and winding down — one for each day.</p>
        <p class="feature__meta"><span>7 days</span><span class="dot"></span><span>3 min each</span><span class="dot"></span><span>Free</span></p>
      </article>
    </div>

    <!-- Weather -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="explore.weather">Weather</h2>
          <p class="section__sub" id="weatherSub"><span id="weatherCity">Karachi</span> · updated 4 min ago</p>
        </div>
        <button class="section__link" data-toast="Weather refreshed"><svg class="ico" viewBox="0 0 24 24"><use href="#i-refresh"/></svg> <span data-i18n="a.refresh">Refresh</span></button>
      </div>
      <div class="row-gap">
        <article class="card weather">
          <span class="weather__icon"><svg class="ico" viewBox="0 0 24 24" id="weatherIcon" style="width:40px;height:40px"><use href="#i-sun"/></svg></span>
          <div>
            <p class="weather__temp num" id="weatherTemp">34<sup>°</sup></p>
            <p class="weather__desc" id="weatherDesc">Hazy sun · feels like 38°</p>
          </div>
          <div class="weather__grid">
            <span class="weather__stat"><svg class="ico" viewBox="0 0 24 24"><use href="#i-droplet"/></svg> <b id="weatherRain">8%</b></span>
            <span class="weather__stat"><svg class="ico" viewBox="0 0 24 24"><use href="#i-wind"/></svg> <b id="weatherWind">14 km/h</b></span>
            <span class="weather__stat"><svg class="ico" viewBox="0 0 24 24"><use href="#i-moon"/></svg> <b class="num" id="weatherSunset">18:36</b></span>
          </div>
        </article>
      </div>
    </div>

    <!-- Around you — built from the user's regional configuration (§105) -->
    <div class="section" id="aroundWrap" hidden>
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="explore.around">Around you</h2>
          <p class="section__sub" data-i18n="explore.aroundSub">Local services, kept current</p>
        </div>
        <span class="tag tag--neutral" id="aroundTag"></span>
      </div>
      <div class="row-gap"><div class="list" id="aroundList"></div></div>
    </div>

    <!-- Cricket -->
    <div class="section" data-int="cricket">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="explore.cricket">Cricket</h2>
          <p class="section__sub">Live · 2nd Test, day 2</p>
        </div>
        <button class="section__link" data-act="tool:cricket">Scorecard <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></button>
      </div>
      <div class="row-gap">
        <article class="card card--pad score" data-act="tool:cricket">
          <div class="score__side">
            <span class="score__flag">PAK</span>
            <span class="score__runs num">214<span>/4</span></span>
            <span class="score__overs num">58.2 ov</span>
          </div>
          <span class="score__vs">vs</span>
          <div class="score__side score__side--away">
            <span class="score__flag">SA</span>
            <span class="score__runs num">301</span>
            <span class="score__overs num">all out</span>
          </div>
          <p class="score__note">Pakistan trail by 87 runs · Babar 78*</p>
        </article>
      </div>
    </div>

    <!-- News -->
    <div class="section" data-int="news">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="explore.reads">Today’s reads</h2>
          <p class="section__sub" data-i18n="explore.readsSub">Balanced, no doomscroll</p>
        </div>
        <button class="section__link" data-toast="All stories"><span data-i18n="a.all">All</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></button>
      </div>
      <div class="row-gap">
        <div class="list" id="newsList"></div>
      </div>
    </div>

    <!-- Collections -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="explore.collections">Collections</h2>
          <p class="section__sub" data-i18n="explore.collectionsSub">Curated for a quiet moment</p>
        </div>
        <button class="section__link" data-toast="All collections"><span data-i18n="a.all">All</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></button>
      </div>
      <div class="hscroll">
        <button class="minicard pressable" data-faith="islamic" data-act="tool:quran">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="c1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1E2C6B"/><stop offset="1" stop-color="#4A54A8"/></linearGradient></defs><rect width="148" height="84" fill="url(#c1)"/><circle cx="112" cy="24" r="18" fill="#FFE9B8" opacity=".9"/><circle cx="104" cy="20" r="15" fill="#2A3670"/><circle cx="40" cy="56" r="3" fill="#fff" opacity=".7"/><circle cx="66" cy="30" r="2" fill="#fff" opacity=".5"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">Night surahs</span>
            <span class="minicard__meta">6 surahs · 9 min</span>
          </span>
        </button>
        <button class="minicard pressable" data-toast="Opening “Focus sounds”">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="c2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E7F4F1"/><stop offset="1" stop-color="#34B39D"/></linearGradient></defs><rect width="148" height="84" fill="url(#c2)"/><path d="M18 42h8M32 30v24M46 20v44M60 34v16M74 26v32M88 38v8M102 28v28M116 36v12M130 42h4" stroke="#0B6F62" stroke-opacity=".55" stroke-width="4" stroke-linecap="round"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">Focus sounds</span>
            <span class="minicard__meta">8 tracks</span>
          </span>
        </button>
        <button class="minicard pressable" data-toast="Opening “Gratitude prompts”">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="c3" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FDEEF0"/><stop offset="1" stop-color="#EFA6B0"/></linearGradient></defs><rect width="148" height="84" fill="url(#c3)"/><path d="M74 62s-24-13-24-30a11 11 0 0 1 24-7 11 11 0 0 1 24 7c0 17-24 30-24 30" fill="#DE6B7A" opacity=".55"/><circle cx="26" cy="22" r="5" fill="#fff" opacity=".7"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">Gratitude prompts</span>
            <span class="minicard__meta">30 days</span>
          </span>
        </button>
        <button class="minicard pressable" data-toast="Opening “Budget basics”">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="c4" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FBEEDD"/><stop offset="1" stop-color="#EFC894"/></linearGradient></defs><rect width="148" height="84" fill="url(#c4)"/><path d="M12 62 44 38l24 16 30-30 26 18" fill="none" stroke="#C9793F" stroke-opacity=".55" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/><circle cx="96" cy="24" r="5" fill="#C9793F" opacity=".7"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">Budget basics</span>
            <span class="minicard__meta">5 lessons</span>
          </span>
        </button>
      </div>
    </div>

    <!-- Nearby -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="explore.nearby">Nearby</h2>
          <p class="section__sub" data-i18n="explore.nearbySub">Within walking distance</p>
        </div>
      </div>
      <div class="row-gap">
        <div class="list">
          <button class="list-row pressable" data-faith="islamic" data-toast="Masjid-e-Tooba · jamaat for Asr at 16:15">
            <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-mosque"/></svg></span>
            <span class="list-row__body">
              <span class="list-row__title">Masjid-e-Tooba</span>
              <span class="list-row__sub">Jamaat for Asr at 16:15</span>
            </span>
            <span class="list-row__end"><span class="list-row__value num">650 m</span><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span>
          </button>
          <button class="list-row pressable" data-toast="Chai Shai · open until 01:00">
            <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-pin"/></svg></span>
            <span class="list-row__body">
              <span class="list-row__title">Chai Shai</span>
              <span class="list-row__sub">Quiet café · open till 01:00</span>
            </span>
            <span class="list-row__end"><span class="list-row__value num">1.1 km</span><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span>
          </button>
          <button class="list-row pressable" data-toast="Hill Park · good for a sunset walk">
            <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-globe"/></svg></span>
            <span class="list-row__body">
              <span class="list-row__title">Hill Park</span>
              <span class="list-row__sub">Good for a sunset walk</span>
            </span>
            <span class="list-row__end"><span class="list-row__value num">1.4 km</span><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span>
          </button>
        </div>
      </div>
    </div>

  </section>
`;
    },

    render: function (root) {
      renderHeadings(root);
      renderWeather(root);
      renderAround(root);
      renderNews(root);
    }
  });
}
