/* ============================================================
   Lume - Explore screen

   Context beyond the saved plan - weather, what is around,
   live sport, news and curated discovery.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createExploreScreen(ctx) {
  return defineScreen({
    id: 'explore',
    template: function () {
      return `
  <section class="screen" id="screen-explore" role="tabpanel" aria-label="Explore">

    <div class="page-head">
      <div class="page-head__bar">
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
    }
  });
}
