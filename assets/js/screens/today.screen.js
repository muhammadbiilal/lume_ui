/* ============================================================
   Lume - Today screen

   The day as a plan: progress, statistics, agenda and tasks.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createTodayScreen() {
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
    }
  });
}
