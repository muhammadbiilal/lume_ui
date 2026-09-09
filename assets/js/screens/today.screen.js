/* ============================================================
   Lume — Today screen

   The day as a plan rather than a data dump: how far through
   the day the user is, a few statistics worth glancing at, the
   agenda in chronological order, and the task list.

   Everything with a time in it is carried as {h, m} and
   formatted only when it is drawn. A locale-formatted string
   cannot be sorted or compared, and the agenda has to do both.

   The ring is the only thing here that moves on its own, so it
   is the only thing this screen has to stop when it leaves.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $ } from '../core/dom.js';

export function createTodayScreen(ctx) {

  /* ---------------------------------------------------------
     Statistics — chosen for the user, not a fixed row
     --------------------------------------------------------- */
  function renderStats(root) {
    const host = $('#todayStats', root);
    if (!host) return;
    const t = ctx.t, L = ctx.L, esc = ctx.ui.esc;
    const stats = [];

    function unit(u) { return ' <span>' + esc(t('unit.' + u)) + '</span>'; }

    if (ctx.profile().islamic) {
      stats.push({ icon: 'i-flame', value: L.num(12) + unit('days'), label: t('today.prayerStreak') });
      stats.push({ icon: 'i-book', value: L.num(18) + unit('min'), label: t('today.readToday') });
    } else {
      stats.push({ icon: 'i-flame', value: L.num(12) + unit('days'), label: t('today.dailyStreak') });
      stats.push({ icon: 'i-pulse', value: L.num(4.2) + unit('k'), label: t('today.steps') });
    }
    stats.push({ icon: 'i-check-circle', value: L.num(2) + '<span>/' + L.num(5) + '</span>', label: t('today.tasksDone') });

    host.innerHTML = stats.map(function (s) {
      return '<article class="stat"><span class="stat__icon">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#' + s.icon + '"/></svg></span>' +
        '<p class="stat__value num">' + s.value + '</p>' +
        '<p class="stat__label">' + s.label + '</p></article>';
    }).join('');
  }

  /* ---------------------------------------------------------
     Agenda — assembled from what is true today, then sorted
     --------------------------------------------------------- */
  function renderAgenda(root) {
    const host = $('#agenda', root);
    if (!host) return;
    const t = ctx.t, L = ctx.L, esc = ctx.ui.esc;
    const profile = ctx.profile();

    const events = [
      { h: 9, m: 30, title: t('agenda.standup'), meta: t('agenda.standupMeta'), icon: 'i-check-circle', done: true },
      { h: 14, m: 0, title: t('agenda.review'), meta: t('agenda.reviewMeta'), icon: 'i-clock', now: true },
      { h: 18, m: 30, title: t('agenda.groceries'), meta: t('agenda.groceriesMeta'), icon: 'i-cart', act: 'tool:shopping' }
    ];

    /* Regional items join the agenda only where they are available — the
       same eligibility rule every other surface asks. */
    const loadshed = ctx.eligible.feature('loadshed');
    if (loadshed && ctx.eligible.visible(loadshed)) {
      const ls = ctx.toolCtx('loadshed').loadshed();
      events.push({
        h: Math.floor(ls.slot.fromM / 60), m: ls.slot.fromM % 60,
        title: t('loadshed.outage'), meta: ls.area + ' · ' + ls.slot.duration,
        icon: 'i-bolt', act: 'tool:loadshed'
      });
    }

    if (profile.islamic) {
      const state = ctx.prayer.state();
      const atNow = new Date().getHours() * 60 + new Date().getMinutes();
      state.main.forEach(function (p) {
        const past = ctx.prayer.minutes(p) < atNow;
        events.push({
          h: p.h, m: p.m, title: t('prayer.' + (ctx.prayer.KEYS[p.name] || 'fajr')),
          meta: past ? t('agenda.prayed') : t('agenda.adhanOn'),
          icon: past ? 'i-check-circle' : 'i-bell',
          done: past, act: 'tool:prayer'
        });
      });
    }

    events.sort(function (a, b) { return (a.h * 60 + a.m) - (b.h * 60 + b.m); });

    const nowM = new Date().getHours() * 60 + new Date().getMinutes();
    host.innerHTML = events.map(function (e) {
      const at = e.h * 60 + e.m;
      const done = e.done || (at < nowM && !e.now);
      const cls = e.now ? ' is-now' : done ? ' is-done' : '';
      return '<div class="tl-item' + cls + '">' +
        '<span class="tl-time num">' + esc(L.time(e.h, e.m)) + '</span>' +
        '<span class="tl-line"><span class="tl-node"></span></span>' +
        '<button class="tl-card pressable" data-act="' + (e.act || ('toast:' + e.title)) + '">' +
          '<span class="tl-card__body"><span class="tl-card__title">' + esc(e.title) + '</span>' +
          '<span class="tl-card__meta">' + esc(e.meta) + '</span></span>' +
          '<span class="tl-card__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + e.icon + '"/></svg></span>' +
        '</button></div>';
    }).join('');

    const sub = $('#agendaSub', root);
    if (sub) sub.textContent = t(profile.islamic ? 'today.agendaMuslim' : 'today.agendaGeneral');
  }

  /* ---------------------------------------------------------
     The day ring — how far through the day it is
     --------------------------------------------------------- */
  function drawRing(root) {
    const ring = $('#dayRing', root), value = $('#dayRingValue', root);
    if (!ring) return;
    const now = new Date();
    const through = (now.getHours() * 60 + now.getMinutes()) / 1440;
    const circumference = 2 * Math.PI * 42;
    ring.style.strokeDashoffset = (circumference * (1 - through)).toFixed(1);
    /* The share of the day is text as well as an arc, so the progress is
       not carried by the drawing alone. */
    if (value) value.textContent = Math.round(through * 100) + '%';
  }

  let ringTimer = null;

  return defineScreen({
    id: 'today',
    template: function () {
      return `
  <section class="screen" id="screen-today" role="tabpanel" aria-label="Today">

    <div class="page-head">
      <div class="page-head__bar">
        <div>
          <h1 class="page-head__title" data-i18n="today.title">Today</h1>
          <p class="page-head__sub" id="todaySub">Tuesday, 8 September</p>
        </div>
        <button class="iconbtn pressable" data-toast="New task added" aria-label="Add">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-plus"/></svg>
        </button>
      </div>
    </div>

    <!-- Day progress -->
    <div class="section" style="margin-top:18px">
      <div class="row-gap">
        <article class="card ring-card">
          <span class="sticker sticker--slow" style="top:-12px;right:-6px" aria-hidden="true">
            <svg width="46" height="46" viewBox="0 0 46 46"><path d="m23 8 3 7.4 7.4 3-7.4 3-3 7.4-3-7.4-7.4-3 7.4-3z" fill="var(--accent)" opacity=".14"/></svg>
          </span>
          <div class="ring">
            <svg viewBox="0 0 100 100" aria-hidden="true">
              <circle class="ring__bg" cx="50" cy="50" r="42" fill="none" stroke-width="9"/>
              <circle class="ring__fg" id="dayRing" cx="50" cy="50" r="42" fill="none" stroke-width="9"
                      stroke-dasharray="263.9" stroke-dashoffset="263.9"/>
            </svg>
            <div class="ring__label">
              <span class="ring__value num" id="dayRingValue">0%</span>
              <span class="ring__unit" data-i18n="today.ofDay">of day</span>
            </div>
          </div>
          <div class="ring-card__body">
            <h2 class="ring-card__title" data-i18n="today.onTrack">You’re on track</h2>
            <p class="ring-card__text" id="dayRingText">2 of 5 tasks done. One meeting left this afternoon.</p>
          </div>
        </article>
      </div>
    </div>

    <!-- Stats -->
    <div class="section">
      <div class="stats" id="todayStats"></div>
    </div>

    <!-- Ayah of the day -->
    <div class="section" data-faith="islamic">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="today.ayah">Ayah of the day</h2>
          <p class="section__sub">Ar-Ra’d · 13:28</p>
        </div>
      </div>
      <div class="row-gap">
        <article class="card card--pad quote">
          <span class="quote__mark" aria-hidden="true"><svg class="ico" viewBox="0 0 24 24"><use href="#i-quote"/></svg></span>
          <p class="arabic" dir="rtl" lang="ar">أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ</p>
          <p class="quote__text">Truly, it is in the remembrance of God that hearts find rest.</p>
          <div class="card__foot">
            <p class="quote__by">Ar-Ra’d 13:28</p>
            <div class="card__actions">
              <button class="ghostbtn pressable" data-bookmark aria-label="Bookmark this ayah"><svg class="ico" viewBox="0 0 24 24"><use href="#i-bookmark"/></svg></button>
              <button class="ghostbtn pressable" data-share="ayah" data-i18n-aria="a.share" aria-label="Share"><svg class="ico" viewBox="0 0 24 24"><use href="#i-share"/></svg></button>
            </div>
          </div>
        </article>
      </div>
    </div>

    <!-- Today's thought — the counterpart for everyone else -->
    <div class="section" data-faith="none">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="today.thought">Today’s thought</h2>
          <p class="section__sub" data-i18n="today.thoughtSub">A minute of perspective</p>
        </div>
      </div>
      <div class="row-gap">
        <article class="card card--pad quote">
          <span class="quote__mark" aria-hidden="true"><svg class="ico" viewBox="0 0 24 24"><use href="#i-quote"/></svg></span>
          <p class="quote__text">Small things done consistently beat big things done occasionally.</p>
          <div class="card__foot">
            <p class="quote__by">On building habits</p>
            <div class="card__actions">
              <button class="ghostbtn pressable" data-bookmark aria-label="Bookmark"><svg class="ico" viewBox="0 0 24 24"><use href="#i-bookmark"/></svg></button>
              <button class="ghostbtn pressable" data-share="quote" data-i18n-aria="a.share" aria-label="Share"><svg class="ico" viewBox="0 0 24 24"><use href="#i-share"/></svg></button>
            </div>
          </div>
        </article>
      </div>
    </div>

    <!-- Agenda -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="today.yourDay">Your day</h2>
          <p class="section__sub" id="agendaSub">Everything in order</p>
        </div>
        <button class="section__link" data-toast="Switched to week view"><span data-i18n="a.week">Week</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></button>
      </div>
      <div class="timeline" id="agenda"></div>
    </div>

    <!-- Tasks -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="today.tasks">Tasks</h2>
          <p class="section__sub" data-i18n="today.tasksSub">Tap to tick one off</p>
        </div>
        <button class="section__link" data-toast="New task added"><span data-i18n="a.add">Add</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-plus"/></svg></button>
      </div>
      <div class="row-gap">
        <div class="list" id="taskList">
          <button class="task is-done">
            <span class="task__box"><svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg></span>
            <span class="task__label" data-loc="PK">Pay the K-Electric bill</span>
            <span class="task__label" data-loc="global">Pay the electricity bill</span>
            <span class="task__time num">07:00</span>
          </button>
          <button class="task is-done">
            <span class="task__box"><svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg></span>
            <span class="task__label">Reply to Sara’s email</span>
            <span class="task__time num">10:15</span>
          </button>
          <button class="task">
            <span class="task__box"><svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg></span>
            <span class="task__label">Finish the Q3 summary</span>
            <span class="task__time num">15:00</span>
          </button>
          <button class="task" data-faith="islamic">
            <span class="task__box"><svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg></span>
            <span class="task__label">Read two pages of Al-Kahf</span>
            <span class="task__time num">Evening</span>
          </button>
          <button class="task">
            <span class="task__box"><svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg></span>
            <span class="task__label">Call home</span>
            <span class="task__time num">21:00</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Habits -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="today.habits">Habits</h2>
          <p class="section__sub" data-i18n="today.habitsSub">Last seven days</p>
        </div>
      </div>
      <div class="row-gap">
        <div class="card habits">
          <div class="habit" data-faith="islamic">
            <span class="habit__name">Fajr on time</span>
            <span class="habit__days">
              <i class="habit__day is-on"></i><i class="habit__day is-on"></i><i class="habit__day is-on"></i>
              <i class="habit__day"></i><i class="habit__day is-on"></i><i class="habit__day is-on"></i>
              <i class="habit__day is-on is-today"></i>
            </span>
            <span class="habit__streak"><svg class="ico" viewBox="0 0 24 24"><use href="#i-flame"/></svg>6</span>
          </div>
          <div class="habit" data-faith="islamic">
            <span class="habit__name">Qur’an daily</span>
            <span class="habit__days">
              <i class="habit__day is-on"></i><i class="habit__day is-on"></i><i class="habit__day"></i>
              <i class="habit__day is-on"></i><i class="habit__day is-on"></i><i class="habit__day is-on"></i>
              <i class="habit__day is-on is-today"></i>
            </span>
            <span class="habit__streak"><svg class="ico" viewBox="0 0 24 24"><use href="#i-flame"/></svg>4</span>
          </div>
          <div class="habit">
            <span class="habit__name">Walk 6k steps</span>
            <span class="habit__days">
              <i class="habit__day is-on"></i><i class="habit__day is-on"></i><i class="habit__day"></i>
              <i class="habit__day is-on"></i><i class="habit__day is-on"></i><i class="habit__day"></i>
              <i class="habit__day is-on is-today"></i>
            </span>
            <span class="habit__streak"><svg class="ico" viewBox="0 0 24 24"><use href="#i-flame"/></svg>2</span>
          </div>
          <div class="habit">
            <span class="habit__name">8 glasses</span>
            <span class="habit__days">
              <i class="habit__day is-on"></i><i class="habit__day"></i><i class="habit__day is-on"></i>
              <i class="habit__day is-on"></i><i class="habit__day"></i><i class="habit__day is-on"></i>
              <i class="habit__day is-today"></i>
            </span>
            <span class="habit__streak"><svg class="ico" viewBox="0 0 24 24"><use href="#i-flame"/></svg>1</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Private — sensitive features stay one deliberate tap away -->
    <div class="section">
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="today.private">Private</h2>
          <p class="section__sub" data-i18n="today.privateSub">Only on this device, only for you</p>
        </div>
      </div>
      <div class="row-gap">
        <button class="card card--pad private-card pressable" data-toast="Unlock to see private records">
          <span class="private-card__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-lock"/></svg></span>
          <span class="private-card__body">
            <span class="private-card__title" data-i18n="today.privateTitle">Health, documents &amp; money</span>
            <span class="private-card__text" data-i18n="today.privateText">Records, medication and expenses stay locked until you open them.</span>
          </span>
          <svg class="ico private-card__chev" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg>
        </button>
      </div>
    </div>

  </section>
`;
    },

    bind: function (root, signal) {
      /* Ticking a task is this screen's own interaction, so the listener
         lives on this screen's root and leaves with it. */
      root.addEventListener('click', function (e) {
        const task = e.target.closest('#taskList .task');
        if (!task) return;
        const done = task.classList.toggle('is-done');
        ctx.toast(done ? ctx.t('today.taskDone') : ctx.t('today.taskUndone'));
      }, { signal: signal });
    },

    render: function (root) {
      renderStats(root);
      renderAgenda(root);
      drawRing(root);
    },

    /* The ring is redrawn once a minute, and only while it can be seen. */
    onEnter: function (root) {
      drawRing(root);
      ringTimer = setInterval(function () { drawRing(root); }, 60000);
    },

    onLeave: function () {
      clearInterval(ringTimer);
      ringTimer = null;
    }
  });
}
