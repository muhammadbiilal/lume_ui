/* ============================================================
   Lume - Home screen

   The daily overview: the greeting, the cards that answer
   "what matters now", and the routes into everything else.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createHomeScreen(ctx) {
  return defineScreen({
    id: 'home',
    template: function () {
      return `
  <section class="screen" id="screen-home" role="tabpanel" aria-label="Home">

    <header class="appbar">
      <div class="appbar__text">
        <h1 class="appbar__greet"><span id="greetText">Good morning</span> <span class="wave">👋</span></h1>
        <p class="appbar__sub">
          <span id="todayDate">Tuesday, 8 September</span>
          <span class="dot"></span>
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-pin"/></svg>
          <span id="appbarCity">Karachi</span>
        </p>
      </div>
      <button class="iconbtn pressable" data-sheet="search" aria-label="Search everything">
        <svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg>
      </button>
      <button class="iconbtn pressable" data-act="tab:notifications" data-i18n-aria="a11y.notifications" aria-label="Notifications">
        <svg class="ico" viewBox="0 0 24 24"><use href="#i-bell"/></svg>
        <span class="iconbtn__badge"></span>
      </button>
      <button class="avatar pressable" data-tab="profile" data-i18n-aria="a11y.yourProfile" aria-label="Your profile" id="appbarAvatar"></button>
    </header>

    <!-- ===== Contextual strip — swaps with the faith dimension ===== -->
    <div class="section" style="margin-top:14px">
      <div class="row-gap">

        <!-- Muslim: next prayer -->
        <button class="ctx pressable" data-faith="islamic" data-act="tool:prayer">
          <span class="ctx__art" aria-hidden="true">
            <svg viewBox="0 0 350 72" preserveAspectRatio="xMidYMid slice">
              <circle cx="316" cy="10" r="42" fill="var(--accent)" opacity=".07"/>
              <circle cx="292" cy="62" r="26" fill="var(--violet)" opacity=".06"/>
            </svg>
          </span>
          <span class="ctx__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-prayer"/></svg></span>
          <span class="ctx__body">
            <span class="ctx__label" data-i18n="home.nextPrayer">Next prayer</span>
            <span class="ctx__title"><b id="ctxPrayerName">Asr</b> · <span class="num" id="ctxPrayerTime">15:53</span></span>
          </span>
          <span class="ctx__end">
            <span class="ctx__count num" id="ctxCountdown">2:41</span>
            <span class="ctx__unit" data-i18n="home.toGo">to go</span>
          </span>
        </button>

        <!-- Everyone else: weather + what's next -->
        <button class="ctx pressable" data-faith="none" data-tab="today">
          <span class="ctx__art" aria-hidden="true">
            <svg viewBox="0 0 350 72" preserveAspectRatio="xMidYMid slice">
              <circle cx="316" cy="10" r="42" fill="var(--sky)" opacity=".08"/>
              <circle cx="292" cy="62" r="26" fill="var(--accent)" opacity=".06"/>
            </svg>
          </span>
          <span class="ctx__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-cloud-sun"/></svg></span>
          <span class="ctx__body">
            <span class="ctx__label" data-i18n="home.rightNow">Right now</span>
            <span class="ctx__title"><b class="num" id="ctxTemp">34°</b> · <span id="ctxWeather">Hazy sun</span></span>
          </span>
          <span class="ctx__end">
            <span class="ctx__count num">14:00</span>
            <span class="ctx__unit" data-i18n="home.nextUp">next up</span>
          </span>
        </button>

      </div>
    </div>

    <!-- ===== Hero carousel ===== -->
    <div class="hero">
      <div class="hero__track" id="heroTrack" role="region" aria-label="Highlights" tabindex="0">

        <!-- Next prayer -->
        <article class="slide slide--night" data-slide="prayer" data-faith="islamic">
          <div class="slide__art" aria-hidden="true">
            <svg viewBox="0 0 320 190" preserveAspectRatio="xMidYMid slice">
              <defs>
                <linearGradient id="g-night" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="#1B2A5E"/><stop offset="1" stop-color="#3E4E9E"/>
                </linearGradient>
                <radialGradient id="g-glow" cx=".5" cy=".5" r=".5">
                  <stop offset="0" stop-color="#FFE9B8" stop-opacity=".8"/><stop offset="1" stop-color="#FFE9B8" stop-opacity="0"/>
                </radialGradient>
              </defs>
              <rect width="320" height="190" fill="url(#g-night)"/>
              <circle cx="252" cy="44" r="58" fill="url(#g-glow)"/>
              <path d="M262 24a22 22 0 1 0 0 40 17 17 0 0 1 0-40" fill="#FFE9B8"/>
              <path d="m196 34 1.8 4.4 4.4 1.8-4.4 1.8-1.8 4.4-1.8-4.4-4.4-1.8 4.4-1.8z" fill="#fff" opacity=".75"/>
              <circle cx="222" cy="86" r="2.4" fill="#fff" opacity=".5"/>
              <circle cx="176" cy="66" r="1.8" fill="#fff" opacity=".4"/>
              <path d="M0 156c30-6 44 8 76 4s52-22 84-16 46 20 78 14 52-16 82-8v40H0z" fill="#0D1739" opacity=".45"/>
              <path d="M236 150v-22h10v22M246 128a5 5 0 0 1 10 0v22h-10M266 150v-16h8v16" fill="#0D1739" opacity=".55"/>
            </svg>
          </div>
          <span class="slide__pill"><span class="live"></span><span class="num" id="heroCountdown">2:41:08</span></span>
          <p class="slide__kicker" data-i18n="slide.prayer.k">Your next prayer</p>
          <h2 class="slide__title" id="heroPrayerName">Asr</h2>
          <p class="slide__text" id="heroPrayerLine">Adhan at 15:53 · Islamabad</p>
          <span class="slide__cta"><span data-i18n="slide.prayer.cta">Prayer times</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></span>
        </article>

        <!-- Plan your day -->
        <article class="slide" data-slide="plan" data-tab="today">
          <div class="slide__art" aria-hidden="true">
            <svg viewBox="0 0 320 190" preserveAspectRatio="xMidYMid slice">
              <defs>
                <linearGradient id="g-plan" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="#0E8C7E"/><stop offset="1" stop-color="#25B7A2"/>
                </linearGradient>
              </defs>
              <rect width="320" height="190" fill="url(#g-plan)"/>
              <circle cx="278" cy="26" r="66" fill="#fff" opacity=".08"/>
              <circle cx="300" cy="168" r="44" fill="#04322C" opacity=".16"/>
              <g transform="translate(206 42)">
                <rect x="0" y="0" width="82" height="98" rx="18" fill="#fff" opacity=".95"/>
                <rect x="14" y="18" width="54" height="7" rx="3.5" fill="#0E8C7E" opacity=".22"/>
                <rect x="14" y="34" width="40" height="7" rx="3.5" fill="#0E8C7E" opacity=".16"/>
                <rect x="14" y="50" width="48" height="7" rx="3.5" fill="#0E8C7E" opacity=".16"/>
                <circle cx="24" cy="76" r="9" fill="#0E8C7E" opacity=".18"/>
                <path d="m20 76 3 3 6-6.4" stroke="#0E8C7E" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
                <rect x="40" y="72" width="28" height="7" rx="3.5" fill="#0E8C7E" opacity=".2"/>
              </g>
              <g opacity=".9">
                <path d="m180 30 2.4 6 6 2.4-6 2.4-2.4 6-2.4-6-6-2.4 6-2.4z" fill="#fff" opacity=".65"/>
                <circle cx="196" cy="150" r="5" fill="#fff" opacity=".3"/>
              </g>
            </svg>
          </div>
          <p class="slide__kicker" data-i18n="slide.plan.k">Today</p>
          <h2 class="slide__title" data-i18n="slide.plan.t">Plan your day before it starts</h2>
          <p class="slide__text" data-i18n="slide.plan.x">Tasks, reminders and events on one timeline.</p>
          <span class="slide__cta"><span data-i18n="slide.plan.cta">Open today</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></span>
        </article>

        <!-- Read something meaningful -->
        <article class="slide slide--read" data-slide="read" data-faith="islamic" data-act="tool:quran">
          <div class="slide__art" aria-hidden="true">
            <svg viewBox="0 0 320 190" preserveAspectRatio="xMidYMid slice">
              <defs>
                <linearGradient id="g-read" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="#4A3F9E"/><stop offset="1" stop-color="#6E62E5"/>
                </linearGradient>
                <linearGradient id="g-page" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0" stop-color="#fff" stop-opacity=".98"/><stop offset="1" stop-color="#fff" stop-opacity=".84"/>
                </linearGradient>
              </defs>
              <rect width="320" height="190" fill="url(#g-read)"/>
              <circle cx="286" cy="30" r="60" fill="#fff" opacity=".08"/>
              <g transform="translate(198 52)">
                <path d="M2 12C14 4 32 4 44 12v70c-12-8-30-8-42 0z" fill="url(#g-page)"/>
                <path d="M86 12C74 4 56 4 44 12v70c12-8 30-8 42 0z" fill="url(#g-page)" opacity=".9"/>
                <path d="M12 26h22M12 38h20M12 50h24M54 26h22M54 38h20M54 50h24" stroke="#4A3F9E" stroke-opacity=".28" stroke-width="2.6" stroke-linecap="round"/>
              </g>
              <path d="m186 40 2 5 5 2-5 2-2 5-2-5-5-2 5-2z" fill="#fff" opacity=".6"/>
              <circle cx="176" cy="140" r="4" fill="#fff" opacity=".3"/>
            </svg>
          </div>
          <p class="slide__kicker" data-i18n="slide.read.k">Read</p>
          <h2 class="slide__title" data-i18n="slide.read.t">Read something meaningful</h2>
          <p class="slide__text" data-i18n="slide.read.x">You're 42 ayahs into Al-Kahf. Two minutes is enough.</p>
          <span class="slide__cta"><span data-i18n="slide.read.cta">Continue</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></span>
        </article>

        <!-- Money -->
        <article class="slide slide--money" data-slide="money" data-act="tool:goldrates">
          <div class="slide__art" aria-hidden="true">
            <svg viewBox="0 0 320 190" preserveAspectRatio="xMidYMid slice">
              <defs>
                <linearGradient id="g-money" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="#1D4E4A"/><stop offset="1" stop-color="#2F7F6E"/>
                </linearGradient>
              </defs>
              <rect width="320" height="190" fill="url(#g-money)"/>
              <circle cx="290" cy="22" r="56" fill="#fff" opacity=".07"/>
              <path d="M176 130 210 96l22 20 30-38 26 22" fill="none" stroke="#8FE6D2" stroke-opacity=".8" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>
              <circle cx="262" cy="78" r="6" fill="#8FE6D2"/>
              <g transform="translate(196 32)">
                <circle cx="18" cy="18" r="17" fill="#E9C170" opacity=".9"/>
                <circle cx="18" cy="18" r="11" fill="none" stroke="#8A6A22" stroke-opacity=".45" stroke-width="2"/>
              </g>
              <path d="m178 146 2.2 5.4 5.4 2.2-5.4 2.2-2.2 5.4-2.2-5.4-5.4-2.2 5.4-2.2z" fill="#fff" opacity=".45"/>
            </svg>
          </div>
          <p class="slide__kicker" data-i18n="slide.money.k">Money</p>
          <h2 class="slide__title" data-i18n="slide.money.t">Stay on top of your money</h2>
          <p class="slide__text" data-i18n="slide.money.x">Rates, bills and expenses in one place.</p>
          <span class="slide__cta"><span data-i18n="slide.money.cta">See money</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></span>
        </article>

        <!-- Trains (Pakistan) -->
        <article class="slide slide--rail" data-slide="trains" data-loc="PK" data-tab="trains">
          <div class="slide__art" aria-hidden="true">
            <svg viewBox="0 0 320 190" preserveAspectRatio="xMidYMid slice">
              <defs>
                <linearGradient id="g-rail" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="#2B3E7A"/><stop offset="1" stop-color="#4C68C4"/>
                </linearGradient>
              </defs>
              <rect width="320" height="190" fill="url(#g-rail)"/>
              <circle cx="284" cy="24" r="58" fill="#fff" opacity=".07"/>
              <path d="M150 168h180M150 176h180" stroke="#fff" stroke-opacity=".2" stroke-width="3" stroke-linecap="round"/>
              <path d="M168 160v-8M196 160v-8M224 160v-8M252 160v-8M280 160v-8M308 160v-8" stroke="#fff" stroke-opacity=".14" stroke-width="3" stroke-linecap="round"/>
              <g transform="translate(190 56)">
                <rect x="0" y="0" width="104" height="90" rx="26" fill="#fff" opacity=".96"/>
                <rect x="14" y="18" width="76" height="30" rx="10" fill="#2B3E7A" opacity=".18"/>
                <circle cx="28" cy="66" r="7" fill="#2B3E7A" opacity=".3"/>
                <circle cx="76" cy="66" r="7" fill="#2B3E7A" opacity=".3"/>
                <path d="M40 66h24" stroke="#2B3E7A" stroke-opacity=".22" stroke-width="3" stroke-linecap="round"/>
              </g>
              <path d="m174 40 2 5 5 2-5 2-2 5-2-5-5-2 5-2z" fill="#fff" opacity=".55"/>
              <circle cx="166" cy="112" r="4" fill="#fff" opacity=".3"/>
            </svg>
          </div>
          <p class="slide__kicker" data-i18n="slide.trains.k">Travel</p>
          <h2 class="slide__title" data-i18n="slide.trains.t">Trains, without the guesswork</h2>
          <p class="slide__text" data-i18n="slide.trains.x">Live running status, fares and seats.</p>
          <span class="slide__cta"><span data-i18n="slide.trains.cta">Find a train</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></span>
        </article>

        <!-- Tools -->
        <article class="slide slide--tools" data-slide="tools" data-tab="tools">
          <div class="slide__art" aria-hidden="true">
            <svg viewBox="0 0 320 190" preserveAspectRatio="xMidYMid slice">
              <defs>
                <linearGradient id="g-tools" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="#3A3A44"/><stop offset="1" stop-color="#5C5C6B"/>
                </linearGradient>
              </defs>
              <rect width="320" height="190" fill="url(#g-tools)"/>
              <circle cx="292" cy="20" r="54" fill="#fff" opacity=".07"/>
              <g opacity=".96">
                <rect x="188" y="34" width="46" height="46" rx="15" fill="#fff" opacity=".92"/>
                <rect x="244" y="52" width="46" height="46" rx="15" fill="#fff" opacity=".72"/>
                <rect x="188" y="92" width="46" height="46" rx="15" fill="#fff" opacity=".78"/>
                <rect x="244" y="110" width="46" height="46" rx="15" fill="#fff" opacity=".58"/>
                <path d="M203 57h16M211 49v16" stroke="#3A3A44" stroke-opacity=".55" stroke-width="3" stroke-linecap="round"/>
                <circle cx="267" cy="75" r="10" fill="none" stroke="#3A3A44" stroke-opacity=".4" stroke-width="3"/>
                <path d="M203 115h16M203 122h10" stroke="#3A3A44" stroke-opacity=".42" stroke-width="3" stroke-linecap="round"/>
              </g>
              <path d="m172 44 2.2 5.4 5.4 2.2-5.4 2.2-2.2 5.4-2.2-5.4-5.4-2.2 5.4-2.2z" fill="#fff" opacity=".5"/>
              <circle cx="164" cy="132" r="4.5" fill="#fff" opacity=".28"/>
            </svg>
          </div>
          <p class="slide__kicker" data-i18n="slide.tools.k">Tools</p>
          <h2 class="slide__title" data-i18n="slide.tools.t">Useful tools, all in one place</h2>
          <p class="slide__text" data-i18n="slide.tools.x">Calculator, converters, scanner and more.</p>
          <span class="slide__cta"><span data-i18n="slide.tools.cta">Browse tools</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></span>
        </article>

      </div>
      <div class="hero__dots" id="heroDots" role="tablist" aria-label="Slide"></div>
    </div>

    <!-- ===== Quick actions (§118) — a task, not a destination ===== -->
    <div class="section" id="quickActionsWrap">
      <div class="qactions" id="quickActions"></div>
    </div>

    <!-- ===== Quick tools ===== -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="home.quickTools">Quick tools</h2>
          <p class="section__sub" id="quickToolsSub">Picked from your interests</p>
        </div>
        <button class="section__link" data-tab="tools"><span data-i18n="a.all">All</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></button>
      </div>
      <div class="tools-grid" id="quickTools"></div>
    </div>

    <!-- ===== Right now (§95) — live, time-of-day aware ===== -->
    <div class="section" id="liveWrap" hidden>
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="home.liveNow">Right now</h2>
          <p class="section__sub" id="liveSub"></p>
        </div>
      </div>
      <div class="row-gap" id="liveNow"></div>
    </div>

    <!-- ===== Today at a glance ===== -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="home.glance">At a glance</h2>
          <p class="section__sub" id="glanceSub">What matters in the next few hours</p>
        </div>
        <button class="section__link" data-tab="today"><span data-i18n="nav.today">Today</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></button>
      </div>

      <div class="row-gap">

        <!-- Qur'an — continue reading -->
        <article class="card card--pad progress-card" data-faith="islamic" data-act="tool:quran">
          <span class="progress-card__art"><svg class="ico" viewBox="0 0 24 24"><use href="#i-book"/></svg></span>
          <div class="progress-card__body">
            <p class="progress-card__title">Continue Al-Kahf</p>
            <p class="progress-card__meta">Ayah 42 of 110 · about 6 min left</p>
            <span class="bar"><span class="bar__fill" data-fill="38"></span></span>
          </div>
          <span class="roundbtn" aria-hidden="true"><svg class="ico" viewBox="0 0 24 24"><use href="#i-play"/></svg></span>
        </article>

        <!-- Fuel — Pakistan -->
        <article class="card card--pad stat-row" data-loc="PK" data-act="tool:fuel">
          <span class="stat-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-fuel"/></svg></span>
          <div class="stat-row__body">
            <p class="stat-row__title">Petrol <span class="tag tag--neutral">Pakistan</span></p>
            <p class="stat-row__meta">Effective 1 September · OGRA</p>
          </div>
          <div class="stat-row__end">
            <p class="stat-row__value num">₨ 264.61</p>
            <p class="stat-row__delta is-up">+2.14</p>
          </div>
        </article>

        <!-- Tasks -->
        <article class="card card--pad progress-card" data-tab="today">
          <span class="progress-card__art"><svg class="ico" viewBox="0 0 24 24"><use href="#i-check-square"/></svg></span>
          <div class="progress-card__body">
            <p class="progress-card__title">3 tasks left today</p>
            <p class="progress-card__meta">Next: finish the Q3 summary · 15:00</p>
            <span class="bar"><span class="bar__fill" data-fill="40"></span></span>
          </div>
          <span class="roundbtn" aria-hidden="true"><svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></span>
        </article>

      </div>
    </div>

    <!-- ===== Coming up (§95) ===== -->
    <div class="section" id="upcomingWrap" hidden>
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="home.upcoming">Coming up</h2>
          <p class="section__sub" data-i18n="home.upcomingSub">The next few days</p>
        </div>
      </div>
      <div id="upcomingList"></div>
    </div>

    <!-- ===== Discover ===== -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="home.discover">Discover</h2>
          <p class="section__sub" data-i18n="home.discoverSub">Because you check these often</p>
        </div>
        <button class="section__link" data-tab="explore"><span data-i18n="nav.explore">Explore</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></button>
      </div>
      <div class="hscroll" id="homeDiscover">

        <button class="minicard pressable" data-loc="PK" data-act="tool:cricket">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="d1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E7F4F1"/><stop offset="1" stop-color="#8FD6C6"/></linearGradient></defs><rect width="148" height="84" fill="url(#d1)"/><ellipse cx="74" cy="52" rx="52" ry="30" fill="none" stroke="#0B7F73" stroke-opacity=".3" stroke-width="2"/><circle cx="108" cy="22" r="9" fill="#DE6B7A" opacity=".7"/><path d="M46 62 66 38" stroke="#0B7F73" stroke-opacity=".5" stroke-width="4" stroke-linecap="round"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">PAK 214/4</span>
            <span class="minicard__meta">2nd Test · Day 2</span>
          </span>
        </button>

        <button class="minicard pressable" data-tab="explore">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="d2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E4EEF8"/><stop offset="1" stop-color="#A9C9E8"/></linearGradient></defs><rect width="148" height="84" fill="url(#d2)"/><circle cx="112" cy="24" r="18" fill="#F2C14E" opacity=".85"/><path d="M0 70c26-12 44 6 74-4s48-22 74-10v28H0z" fill="#3E9BD4" opacity=".28"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">34° and hazy</span>
            <span class="minicard__meta">Feels like 38°</span>
          </span>
        </button>

        <button class="minicard pressable" data-loc="PK" data-act="tool:loadshed">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="d3" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FBEEDD"/><stop offset="1" stop-color="#EFC894"/></linearGradient></defs><rect width="148" height="84" fill="url(#d3)"/><path d="M78 16 58 48h14l-4 22 22-30H76z" fill="#C9793F" opacity=".65"/><circle cx="28" cy="24" r="7" fill="#fff" opacity=".65"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">Next outage 14:00</span>
            <span class="minicard__meta">Gulshan · 2 hours</span>
          </span>
        </button>

        <button class="minicard pressable" data-faith="islamic" data-toast="Forty duas for ordinary days">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="d4" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1E2C6B"/><stop offset="1" stop-color="#4A54A8"/></linearGradient></defs><rect width="148" height="84" fill="url(#d4)"/><circle cx="112" cy="24" r="18" fill="#FFE9B8" opacity=".9"/><circle cx="104" cy="20" r="15" fill="#2A3670"/><circle cx="40" cy="56" r="3" fill="#fff" opacity=".7"/><circle cx="66" cy="30" r="2" fill="#fff" opacity=".5"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">Forty duas</span>
            <span class="minicard__meta">For ordinary days</span>
          </span>
        </button>

        <button class="minicard pressable" data-loc="PK" data-act="tool:parcel">
          <span class="minicard__art"><svg viewBox="0 0 148 84" preserveAspectRatio="none"><defs><linearGradient id="d5" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#EDEAFB"/><stop offset="1" stop-color="#B7AEF6"/></linearGradient></defs><rect width="148" height="84" fill="url(#d5)"/><path d="m74 24 26 13v26L74 76 48 63V37z" fill="#6E62E5" opacity=".35"/><path d="m48 37 26 13 26-13M74 50v26" stroke="#4A3F9E" stroke-opacity=".4" stroke-width="2"/></svg></span>
          <span class="minicard__body">
            <span class="minicard__title">Out for delivery</span>
            <span class="minicard__meta">TCS · arrives today</span>
          </span>
        </button>

      </div>
    </div>

  </section>
`;
    }
  });
}
