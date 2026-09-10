/* ============================================================
   Lume — Trains screen

   Pakistan promotes Trains to a first-class destination, so it
   gets a screen rather than only a tool. Nothing here asks which
   country it is in: whether this destination is in the tab set
   at all is the router's question, answered from the profile.

   The roster is the same one the Trains tool shows, formatted by
   the locale rather than hard-coded to rupees and English, so
   the two never disagree about a fare or a departure.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $ } from '../core/dom.js';

export function createTrainsScreen(ctx) {

  function renderRoster(root) {
    const host = $('#trainList', root);
    if (!host) return;
    const t = ctx.t, L = ctx.L, esc = ctx.ui.esc;
    const currency = L.country().currency;

    host.innerHTML = ctx.data.TRAINS.map(function (train) {
      const status = t(train.statusKey, { n: train.delay });
      return '<button class="list-row pressable" data-act="tool:trains" data-fid="trains">' +
        '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-train"/></svg></span>' +
        '<span class="list-row__body">' +
          '<span class="list-row__title">' + esc(train.name) + ' <span class="trainno num">' + esc(train.no) + '</span></span>' +
          '<span class="list-row__sub"><span class="num">' + esc(train.dep) + '</span> → <span class="num">' +
            esc(train.arr) + '</span> · ' + esc(train.dur) + ' · ' + esc(L.moneyRaw(train.fare, currency, 0)) + '</span>' +
        '</span>' +
        '<span class="list-row__end"><span class="status status--' + (train.delay ? 'late' : 'ok') + '">' +
          esc(status) + '</span></span></button>';
    }).join('');
  }

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
    },

    render: function (root) {
      renderRoster(root);
    }
  });
}
