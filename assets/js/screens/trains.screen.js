/* ============================================================
   Lume - Trains screen

   The Pakistan transport destination, promoted to a tab
   where it is a first-class part of the day.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createTrainsScreen(ctx) {
  return defineScreen({
    id: 'trains',
    template: function () {
      return `
  <section class="screen" id="screen-trains" data-loc="PK" role="tabpanel" aria-label="Trains">

    <div class="page-head">
      <div class="page-head__bar">
        <div>
          <h1 class="page-head__title" data-i18n="trains.title">Trains</h1>
          <p class="page-head__sub">Pakistan Railways · live running status</p>
        </div>
        <button class="iconbtn pressable" data-toast="Saved journeys" aria-label="Saved journeys">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-bookmark"/></svg>
        </button>
      </div>
    </div>

    <!-- Route search -->
    <div class="section" style="margin-top:18px">
      <div class="row-gap">
        <div class="card railsearch">
          <div class="railsearch__art" aria-hidden="true">
            <svg viewBox="0 0 350 150" preserveAspectRatio="xMidYMid slice">
              <circle cx="322" cy="10" r="54" fill="var(--accent)" opacity=".07"/>
              <circle cx="300" cy="140" r="32" fill="var(--indigo)" opacity=".06"/>
              <path d="m286 44 2.4 5.8 5.8 2.4-5.8 2.4-2.4 5.8-2.4-5.8-5.8-2.4 5.8-2.4z" fill="var(--accent)" opacity=".22"/>
            </svg>
          </div>
          <div class="railsearch__row">
            <span class="railsearch__dots" aria-hidden="true">
              <i class="railsearch__dot"></i><i class="railsearch__line"></i><i class="railsearch__dot railsearch__dot--end"></i>
            </span>
            <div class="railsearch__fields">
              <button class="railfield pressable" data-toast="Choose a departure station">
                <span class="railfield__label" data-i18n="trains.from">From</span>
                <span class="railfield__value">Karachi Cantt</span>
              </button>
              <button class="railfield pressable" data-toast="Choose a destination">
                <span class="railfield__label" data-i18n="trains.to">To</span>
                <span class="railfield__value">Lahore Junction</span>
              </button>
            </div>
            <button class="railswap pressable" data-toast="Stations swapped" aria-label="Swap stations">
              <svg class="ico" viewBox="0 0 24 24"><use href="#i-swap"/></svg>
            </button>
          </div>
          <div class="railsearch__foot">
            <button class="railchip pressable is-active">Today</button>
            <button class="railchip pressable">Tomorrow</button>
            <button class="railchip pressable" aria-label="Pick a date"><svg class="ico" viewBox="0 0 24 24"><use href="#i-calendar"/></svg></button>
            <button class="btn btn--accent pressable railsearch__go" data-toast="5 trains on this route today">
              <svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg> Search
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Tracked train -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="trains.tracking">You are tracking</h2>
          <p class="section__sub">Updated 2 minutes ago</p>
        </div>
        <button class="section__link" data-toast="Live status refreshed"><svg class="ico" viewBox="0 0 24 24"><use href="#i-refresh"/></svg> <span data-i18n="a.refresh">Refresh</span></button>
      </div>
      <div class="row-gap">
        <article class="card card--pad live-train">
          <div class="live-train__head">
            <span class="live-train__no num">5UP</span>
            <div class="live-train__title">
              <p class="live-train__name">Green Line Express</p>
              <p class="live-train__route">Karachi Cantt → Islamabad</p>
            </div>
            <span class="status status--ok"><span class="live"></span>On time</span>
          </div>
          <div class="live-train__track">
            <span class="live-train__fill" data-fill="62"></span>
            <span class="live-train__pin"><svg class="ico" viewBox="0 0 24 24"><use href="#i-train"/></svg></span>
          </div>
          <div class="live-train__stops">
            <span><b class="num">22:00</b>Karachi</span>
            <span class="is-now"><b>Now</b>Near Rohri</span>
            <span><b class="num">17:30</b>Islamabad</span>
          </div>
        </article>
      </div>
    </div>

    <!-- Departures -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="trains.departures">Today’s departures</h2>
          <p class="section__sub">From Karachi Cantt</p>
        </div>
        <button class="section__link" data-toast="All departures"><span data-i18n="a.all">All</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></button>
      </div>
      <div class="row-gap">
        <div class="list" id="trainList"></div>
      </div>
    </div>

    <!-- Popular routes -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="trains.popular">Popular routes</h2>
          <p class="section__sub" data-i18n="trains.popularSub">Tap to check fares and seats</p>
        </div>
      </div>
      <div class="hscroll">
        <button class="routecard pressable" data-toast="Karachi → Lahore · 4 trains · from ₨ 2,400">
          <span class="routecard__pair"><b>KHI</b><svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg><b>LHR</b></span>
          <span class="routecard__meta">17h 45m · 4 trains</span>
          <span class="routecard__fare num">from ₨ 2,400</span>
        </button>
        <button class="routecard pressable" data-toast="Karachi → Islamabad · 2 trains · from ₨ 3,100">
          <span class="routecard__pair"><b>KHI</b><svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg><b>ISB</b></span>
          <span class="routecard__meta">19h 30m · 2 trains</span>
          <span class="routecard__fare num">from ₨ 3,100</span>
        </button>
        <button class="routecard pressable" data-toast="Lahore → Rawalpindi · 6 trains · from ₨ 1,150">
          <span class="routecard__pair"><b>LHR</b><svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg><b>RWP</b></span>
          <span class="routecard__meta">4h 20m · 6 trains</span>
          <span class="routecard__fare num">from ₨ 1,150</span>
        </button>
      </div>
    </div>

  </section>
`;
    }
  });
}
