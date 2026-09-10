/* ============================================================
   Lume — onboarding

   The first run: what the product is, what the user is here
   for, and where they are. It is a full-canvas flow rather than
   a destination, so it is not in the tab set and not in the
   screen outlet — it covers the shell until it is finished.

   Two rules run through it.

   Islamic interests are offered inside "What are you here for?"
   and are never preselected. Choosing one is what switches the
   Islamic experience on; the product never asks whether someone
   is Muslim, and never infers it.

   Country and city are asked for separately from everything
   else, because where a person is says nothing about who they
   are. Skipping is a first-class outcome: an untouched name
   field is not an instruction to erase a name.
   ============================================================ */
import { $, $$ } from '../core/dom.js';

export function createOnboarding(deps) {
  const t = deps.t, L = deps.L, esc = deps.esc;
  const C = deps.catalogue;
  const getProfile = deps.profile;
  const store = deps.store;
  const account = deps.account;
  const PICKERS = deps.pickers;
  const saveProfile = deps.save;
  const syncFaithFromInterests = deps.syncFaith;
  const forgetPrayerTimes = deps.forgetPrayerTimes;
  const toast = deps.toast;
  const applyStrings = deps.applyStrings;
  const sheetClose = deps.sheetClose;
  const renderAll = deps.render;
  const renderProfile = deps.renderProfile;
  const renderHome = deps.renderHome;
  const prayerState = deps.prayerState;
  const applyVisibility = deps.applyVisibility;
  const openAuth = deps.openAuth;
  const sheetOpen = deps.sheetOpen;

  var onb = $('#onb');
  var onbSteps = $$('.onb-step');
  var onbSegs = $$('#onbProgress .onb__seg');
  var onbBack = $('#onbBack');
  var onbSkip = $('#onbSkip');
  var onbStep = 0;
  var onbDraft = { country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad' };

  var onbCountryPicker = null, onbCityPicker = null;

  function mountOnbCountry() {
    if (!onbCountryPicker) {
      onbCountryPicker = PICKERS.makeLocationPicker($('#onbCountry'), function () { return onbDraft; }, {
        stage: 'country',
        onChange: function () { mountOnbCity(); }
      });
    } else { onbCountryPicker.render(); }
  }

  function mountOnbCity() {
    var host = $('#onbCity');
    if (!host) return;
    if (!onbCityPicker) {
      onbCityPicker = PICKERS.makeLocationPicker(host, function () { return onbDraft; }, { stage: 'city' });
    } else { onbCityPicker.reset('city'); }
    var label = $('#onbCityCountry');
    if (label) label.textContent = L.countryName(onbDraft.country);
  }

  function onbShow(i, back) {
    i = Math.max(0, Math.min(onbSteps.length - 1, i));
    onbStep = i;

    onbSteps.forEach(function (s, n) {
      s.classList.toggle('is-active', n === i);
      s.classList.toggle('is-back', n === i && !!back);
      if (n === i) s.scrollTop = 0;
    });
    onbSegs.forEach(function (seg, n) { seg.classList.toggle('is-done', n <= i); });

    onbBack.disabled = i === 0;
    onbSkip.disabled = i === onbSteps.length - 1;

    if (i === 3) mountOnbCountry();
    if (i === 4) mountOnbCity();
    if (i === 5 && onbPicker) onbPicker.refresh();
    /* §124.4 — the field is prefilled from whatever Lume already holds,
       which for a first run is nothing at all. It asks the same resolver
       every other surface asks: for an account holder the name lives on the
       account, not on the device, and reading the device here opened the
       field empty and then saved that emptiness over their name. */
    if (i === 7) {
      var nameInput = $('#onbName');
      if (nameInput) nameInput.value = account.displayName() || '';
    }
    if (i === 6) {
      var loc = $('#onbLocSub');
      if (loc) loc.textContent = getProfile().islamic
        ? 'For prayer times, Qibla, weather and nearby places'
        : 'For weather, local services and nearby places';
      var nt = $('#onbNotifSub');
      if (nt) nt.textContent = getProfile().islamic
        ? 'A quiet nudge 5 minutes before each adhan'
        : 'A quiet nudge for the things you asked us to watch';
      applyVisibility();
    }
    if (i === onbSteps.length - 1) {
      /* §124.5 / §125 — two designed branches, and the neutral one is not
         the lesser of them. */
      var who = account.displayName();
      var title = $('#onbDoneTitle');
      if (title) title.textContent = who ? t('onb.readyNamed', { name: who }) : t('onb.readyTitle');
      var el = $('#onbDoneText');
      if (el) {
        el.innerHTML = getProfile().islamic
          ? t('onb.readyFaith', { prayer: '<b>' + esc(prayerState().next.name) + '</b>' })
          : esc(t('onb.readyGeneral'));
      }
    }
  }

  function onbFinish(msg) {
    if (!onb) return;
    onb.classList.add('is-leaving');
    store.set('lume-onboarded', '1');
    setTimeout(function () {
      onb.hidden = true;
      onb.classList.remove('is-leaving');
      if (msg) toast(msg);
    }, 380);
  }

  /* The one place onboarding writes an identity. An empty field writes an
     empty name — it does not leave the previous one standing (§125). */
  function commitName(value) {
    var name = String(value || '').trim().slice(0, 40);
    /* An account holder is naming their account; a guest is naming this
       device. The two never write to each other (§125). */
    if (account.isAuthed()) account.updateUser({ displayName: name });
    else getProfile().displayName = name;
    saveProfile();
    /* A name shows up in three places at once: the greeting, the avatar and
       the profile screen. Rendering the screen that carries the first two is
       how they stay in step, rather than two separate pokes at their nodes. */
    renderHome();
    renderProfile();
  }

  function onbCommit(list, faith) {
    getProfile().interests = list;
    getProfile().islamic = !!faith;
    getProfile().country = onbDraft.country;
    getProfile().region = onbDraft.region;
    getProfile().city = onbDraft.city;
    forgetPrayerTimes();
    syncFaithFromInterests();
    saveProfile();
    renderAll();
  }

  var onbPicker = PICKERS.makeInterestPicker($('#onbPicker'), $('#onbPickCount'), $('#onbPickClear'), function (enough) {
    var b = $('#onbPickNext');
    if (b) b.disabled = !enough;
  }, function () { return { country: onbDraft.country, islamic: true }; });

  function onbStart() {
    /* The tour quotes the size of the catalogue. It is onboarding's own
       copy to keep up to date, not something the Tools screen reaches out
       of its root to write. */
    var onbCount = $('#onbToolCount');
    if (onbCount) onbCount.textContent = C.FEATURES.length;

    if (!onb) return;
    onbDraft = { country: getProfile().country, region: getProfile().region, city: getProfile().city };
    if (onbPicker) onbPicker.set(getProfile().interests.slice(), getProfile().islamic);
    onb.hidden = false;
    onb.classList.remove('is-leaving');
    onbShow(0);
  }

  if (onb) {
    var pickNext = $('#onbPickNext');
    if (pickNext) {
      pickNext.addEventListener('click', function () {
        onbCommit(onbPicker.get(), onbPicker.faith());
        onbShow(onbStep + 1);
      });
    }

    $$('[data-onb-next]').forEach(function (b) {
      b.addEventListener('click', function () {
        /* Location commits before the interest step so the picker can drop
           interests that lead nowhere in this country. */
        if (onbStep === 4) {
          getProfile().country = onbDraft.country;
          getProfile().region = onbDraft.region;
          getProfile().city = onbDraft.city;
          forgetPrayerTimes();
        }
        onbShow(onbStep + 1);
      });
    });
    onbBack.addEventListener('click', function () { onbShow(onbStep - 1, true); });
    onbSkip.addEventListener('click', function () {
      if (!getProfile().interests.length) {
        onbCommit(C.DEFAULT_INTERESTS.slice(), false);
        onbFinish('Set up with our defaults — edit them in Profile');
      } else {
        onbFinish('Tour skipped — find it again in Profile');
      }
    });

    var nameNext = $('#onbNameNext');
    if (nameNext) {
      nameNext.addEventListener('click', function () {
        var input = $('#onbName');
        var typed = input ? input.value : '';
        /* An untouched field is not an instruction to erase anything. */
        if (String(typed).trim() !== String(account.displayName() || '')) commitName(typed);
        onbShow(onbStep + 1);
      });
    }

    /* §124.4 — skipping is a first-class outcome, not a deletion. Re-running
       the tour and skipping this step used to wipe a name the user had
       already given, while the header's own Skip left it alone: two skip
       controls on one screen doing opposite things. */
    var nameSkip = $('#onbNameSkip');
    if (nameSkip) {
      nameSkip.addEventListener('click', function () { onbShow(onbStep + 1); });
    }

    var finish = $('#onbFinish');
    if (finish) finish.addEventListener('click', function () { onbFinish('Welcome to Lume'); });

    /* §124.6 — "already have an account" leads to authentication, not to a
       toast that pretends someone signed in. */
    var signIn = $('#onbSignIn');
    if (signIn) signIn.addEventListener('click', function () {
      if (!getProfile().interests.length) onbCommit(C.DEFAULT_INTERESTS.slice(), false);
      onbFinish();
      openAuth('signin');
    });

    $$('[data-onb-toggle]').forEach(function (row) {
      row.addEventListener('click', function () {
        var on = !row.classList.contains('is-on');
        row.classList.toggle('is-on', on);
        var sw = $('.switch', row);
        if (sw) sw.classList.toggle('is-on', on);
      });
    });

    var method = $('#onbMethod');
    if (method) {
      method.addEventListener('click', function (e) {
        var b = e.target.closest('button');
        if (!b) return;
        $$('button', method).forEach(function (x) { x.classList.remove('is-active'); });
        b.classList.add('is-active');
      });
    }

    var sx2 = 0, sy2 = 0;
    onb.addEventListener('touchstart', function (e) {
      sx2 = e.touches[0].clientX; sy2 = e.touches[0].clientY;
    }, { passive: true });
    onb.addEventListener('touchend', function (e) {
      var dx = e.changedTouches[0].clientX - sx2;
      var dy = e.changedTouches[0].clientY - sy2;
      if (Math.abs(dx) < 56 || Math.abs(dy) > Math.abs(dx)) return;
      if (dx < 0 && onbStep < onbSteps.length - 1 && onbStep !== 5 && onbStep !== 7) onbShow(onbStep + 1);
      if (dx > 0 && onbStep > 0) onbShow(onbStep - 1, true);
    }, { passive: true });

    var forced = /[?&]tour=1/.test(location.search);
    if (forced || !store.get('lume-onboarded')) onbStart();

    var replay = $('#replayTour');
    if (replay) replay.addEventListener('click', function () { sheetClose(); onbStart(); });
  }


  return {
    start: onbStart,
    commitName: commitName
  };
}

export function onboardingTemplate() {
  return `
  <div class="onb" id="onb" hidden>
    <div class="onb__bg" aria-hidden="true"></div>

    <header class="onb__top">
      <button class="onb__nav pressable" id="onbBack" aria-label="Back" disabled>
        <svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-l"/></svg>
      </button>
      <div class="onb__progress" id="onbProgress" aria-hidden="true">
        <span class="onb__seg"></span><span class="onb__seg"></span><span class="onb__seg"></span>
        <span class="onb__seg"></span><span class="onb__seg"></span><span class="onb__seg"></span>
        <span class="onb__seg"></span><span class="onb__seg"></span>
        <span class="onb__seg"></span>
      </div>
      <button class="onb__skip" id="onbSkip">Skip</button>
    </header>

    <div class="onb__steps" id="onbSteps">

      <!-- 1 · Welcome -->
      <section class="onb-step is-active" data-step="0">
        <div class="onb__art">
          <svg viewBox="0 0 292 244" fill="none" aria-hidden="true">
            <circle cx="146" cy="118" r="98" fill="var(--accent)" opacity=".07"/>
            <circle cx="146" cy="118" r="66" fill="var(--accent)" opacity=".06"/>
            <g class="onb__float">
              <rect x="44" y="46" width="72" height="72" rx="24" fill="var(--card)" stroke="var(--border)"/>
              <path d="M64 82h32M80 66v32" stroke="var(--accent)" stroke-width="3" stroke-linecap="round"/>
            </g>
            <g class="onb__float onb__float--b">
              <rect x="140" y="30" width="72" height="72" rx="24" fill="var(--card)" stroke="var(--border)"/>
              <circle cx="176" cy="66" r="18" fill="none" stroke="var(--violet)" stroke-width="3"/>
              <path d="M176 54v12l8 6" stroke="var(--violet)" stroke-width="3" stroke-linecap="round"/>
            </g>
            <g class="onb__float onb__float--c">
              <rect x="96" y="128" width="90" height="90" rx="28" fill="var(--accent)"/>
              <circle cx="141" cy="173" r="28" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="3"/>
              <path d="M141 145a28 28 0 0 1 0 56 14 14 0 0 1 0-28 14 14 0 0 0 0-28" fill="#fff" opacity=".9"/>
            </g>
            <g class="onb__float">
              <rect x="196" y="122" width="66" height="66" rx="22" fill="var(--card)" stroke="var(--border)"/>
              <path d="M212 162c5-4 10-4 15 0M212 148c10-8 21-8 31 0" stroke="var(--sky)" stroke-width="3" stroke-linecap="round"/>
              <circle cx="228" cy="172" r="3" fill="var(--sky)"/>
            </g>
            <path d="m20 108 3 7.4 7.4 3-7.4 3-3 7.4-3-7.4-7.4-3 7.4-3z" fill="var(--accent)" opacity=".5"/>
            <circle cx="268" cy="72" r="5" fill="var(--violet)" opacity=".4"/>
            <circle cx="70" cy="212" r="4" fill="var(--sky)" opacity=".45"/>
          </svg>
        </div>

        <div class="onb__brand">
          <span class="onb__mark"><svg class="ico" viewBox="0 0 24 24"><use href="#i-lume"/></svg></span>
          <span class="onb__wordmark">Lume<span>Your day, in one place</span></span>
        </div>

        <h1 class="onb__title" data-i18n="onb.welcomeTitle">Everything your day needs, quietly organised.</h1>
        <p class="onb__text" data-i18n="onb.welcomeText">Plans, money, travel, reading and the small tools you reach for — without the clutter.</p>

        <div class="onb__foot">
          <button class="btn btn--accent btn--block pressable" data-onb-next>Get started <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></button>
          <button class="onb__link pressable" id="onbSignIn">Already have an account? <b>Sign in</b></button>
        </div>
      </section>

      <!-- 2 · Plan -->
      <section class="onb-step" data-step="1">
        <div class="onb__art">
          <svg viewBox="0 0 292 244" fill="none" aria-hidden="true">
            <circle cx="146" cy="120" r="98" fill="var(--accent)" opacity=".06"/>
            <rect x="54" y="34" width="184" height="176" rx="30" fill="var(--card)" stroke="var(--border)"/>
            <rect x="76" y="60" width="80" height="10" rx="5" fill="var(--text)" opacity=".14"/>
            <rect x="76" y="82" width="46" height="8" rx="4" fill="var(--text)" opacity=".08"/>
            <g class="onb__float">
              <rect x="76" y="106" width="140" height="34" rx="12" fill="var(--tint-accent)"/>
              <circle cx="96" cy="123" r="8" fill="var(--accent)" opacity=".28"/>
              <path d="m92 123 3 3 6-6.4" stroke="var(--accent)" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
              <rect x="112" y="119" width="70" height="8" rx="4" fill="var(--accent)" opacity=".26"/>
            </g>
            <g class="onb__float onb__float--b">
              <rect x="76" y="148" width="140" height="34" rx="12" fill="var(--tint-neutral)"/>
              <circle cx="96" cy="165" r="8" fill="none" stroke="var(--text-3)" stroke-width="2"/>
              <rect x="112" y="161" width="54" height="8" rx="4" fill="var(--text)" opacity=".12"/>
            </g>
            <path d="m30 84 2.8 6.8 6.8 2.8-6.8 2.8-2.8 6.8-2.8-6.8-6.8-2.8 6.8-2.8z" fill="var(--accent)" opacity=".45"/>
            <circle cx="262" cy="152" r="5" fill="var(--violet)" opacity=".4"/>
          </svg>
        </div>

        <p class="onb__kicker" data-i18n="onb.planKicker">Plan</p>
        <h1 class="onb__title" data-i18n="onb.planTitle">Your day, laid out before it starts</h1>
        <p class="onb__text">Tasks, reminders and events on one timeline — with everything that matters already in the right place.</p>

        <div class="onb__foot">
          <button class="btn btn--accent btn--block pressable" data-onb-next>Continue <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></button>
        </div>
      </section>

      <!-- 3 · Tools -->
      <section class="onb-step" data-step="2">
        <div class="onb__art">
          <svg viewBox="0 0 292 244" fill="none" aria-hidden="true">
            <circle cx="146" cy="116" r="96" fill="var(--violet)" opacity=".07"/>
            <circle cx="146" cy="116" r="62" fill="var(--accent)" opacity=".06"/>
            <g class="onb__float">
              <rect x="46" y="42" width="62" height="62" rx="20" fill="var(--card)" stroke="var(--border)"/>
              <rect x="63" y="57" width="28" height="32" rx="7" fill="none" stroke="var(--accent)" stroke-width="2.2"/>
              <path d="M69 66h16M69 75h.01M77 75h.01M85 75h.01M69 82h.01M77 82h.01" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
            </g>
            <g class="onb__float onb__float--b">
              <rect x="122" y="26" width="62" height="62" rx="20" fill="var(--card)" stroke="var(--border)"/>
              <path d="M140 68v-8M148 68V50M156 68v-12M164 68V44" stroke="var(--violet)" stroke-width="3" stroke-linecap="round"/>
            </g>
            <g class="onb__float onb__float--c">
              <rect x="198" y="52" width="62" height="62" rx="20" fill="var(--card)" stroke="var(--border)"/>
              <path d="M215 90c-3-6-2-13 3-17s13-4 18 1M243 76c3 6 2 13-3 17" stroke="var(--sky)" stroke-width="2.2" stroke-linecap="round"/>
              <circle cx="229" cy="82" r="6" fill="var(--sky)" opacity=".5"/>
            </g>
            <g class="onb__float onb__float--b">
              <rect x="28" y="128" width="62" height="62" rx="20" fill="var(--card)" stroke="var(--border)"/>
              <rect x="45" y="145" width="28" height="28" rx="8" fill="none" stroke="var(--accent)" stroke-width="2.2"/>
              <path d="M45 154h28M54 141v6M64 141v6" stroke="var(--accent)" stroke-width="2.2" stroke-linecap="round"/>
            </g>
            <g class="onb__float">
              <rect x="106" y="112" width="76" height="76" rx="24" fill="var(--accent)"/>
              <path d="M144 134v20M134 144h20" stroke="#fff" stroke-width="3.4" stroke-linecap="round"/>
              <circle cx="144" cy="150" r="26" fill="none" stroke="#fff" stroke-opacity=".3" stroke-width="2"/>
            </g>
            <g class="onb__float onb__float--c">
              <rect x="200" y="140" width="62" height="62" rx="20" fill="var(--card)" stroke="var(--border)"/>
              <path d="M217 178c4-3 8-3 12 0M217 166c8-6 16-6 24 0M226 186h.01" stroke="var(--amber)" stroke-width="2.4" stroke-linecap="round"/>
              <circle cx="231" cy="160" r="5" fill="var(--amber)" opacity=".5"/>
            </g>
            <path d="m18 96 2.8 6.8 6.8 2.8-6.8 2.8-2.8 6.8-2.8-6.8-6.8-2.8 6.8-2.8z" fill="var(--accent)" opacity=".5"/>
            <circle cx="272" cy="126" r="4.5" fill="var(--violet)" opacity=".4"/>
            <circle cx="96" cy="212" r="4" fill="var(--sky)" opacity=".4"/>
          </svg>
        </div>

        <p class="onb__kicker" data-i18n="onb.toolsKicker">Tools</p>
        <h1 class="onb__title"><span id="onbToolCount">70</span>-odd tools, one or two taps away</h1>
        <p class="onb__text">Calculator, converters, weather, scanner, rates, trackers — sorted, so you never hunt for them.</p>

        <div class="onb__foot">
          <button class="btn btn--accent btn--block pressable" data-onb-next>Continue <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></button>
        </div>
      </section>

      <!-- 4 · Where are you based? -->
      <section class="onb-step onb-step--list" data-step="3">
        <div class="onb__lead">
          <p class="onb__kicker" data-i18n="onb.localKicker">Make it local</p>
          <h1 class="onb__title" data-i18n="onb.whereTitle">Where are you based?</h1>
          <p class="onb__text" data-i18n="onb.whereText">This helps us personalise local information and services. It says nothing about who you are.</p>
        </div>
        <div class="locpicker" id="onbCountry"></div>
        <div class="onb__foot onb__foot--sticky">
          <button class="btn btn--accent btn--block pressable" data-onb-next>
            <span data-i18n="a.continue">Continue</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg>
          </button>
        </div>
      </section>

      <!-- 5 · Which city? -->
      <section class="onb-step onb-step--list" data-step="4">
        <div class="onb__lead">
          <p class="onb__kicker" id="onbCityCountry">Pakistan</p>
          <h1 class="onb__title" data-i18n="onb.cityTitle">Which city are you in?</h1>
          <p class="onb__text" data-i18n="onb.cityText">Used for weather, prayer times where relevant, and anything local.</p>
        </div>
        <div class="locpicker" id="onbCity"></div>
        <div class="onb__foot onb__foot--sticky">
          <button class="btn btn--accent btn--block pressable" data-onb-next>
            <span data-i18n="a.continue">Continue</span> <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg>
          </button>
        </div>
      </section>

      <!-- 5 · What are you here for? -->
      <section class="onb-step" data-step="5">
        <div style="padding-top:14px">
          <p class="onb__kicker" data-i18n="onb.yoursKicker">Make it yours</p>
          <h1 class="onb__title" data-i18n="onb.hereForTitle">What are you here for?</h1>
          <p class="onb__text">Pick 5 to 10. Your home screen, tools and reading are built around them — change them whenever you like.</p>
        </div>

        <div style="margin-top:18px">
          <div class="picker__bar">
            <span class="picker__count" id="onbPickCount">0 selected</span>
            <button class="picker__clear pressable" id="onbPickClear">Clear</button>
          </div>
          <div id="onbPicker"></div>
        </div>

        <div class="onb__foot onb__foot--sticky">
          <button class="btn btn--accent btn--block pressable" id="onbPickNext" disabled>
            Continue <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg>
          </button>
        </div>
      </section>

      <!-- 6 · Set up -->
      <section class="onb-step" data-step="6">
        <div class="onb__art" style="flex:0 0 auto;min-height:0;padding:2px 0 10px">
          <svg viewBox="0 0 292 128" fill="none" aria-hidden="true" style="max-width:242px">
            <circle cx="146" cy="72" r="60" fill="var(--accent)" opacity=".07"/>
            <circle cx="146" cy="72" r="40" fill="var(--accent)" opacity=".07"/>
            <circle cx="146" cy="72" r="60" fill="none" stroke="var(--accent)" stroke-opacity=".22" stroke-width="1.5" stroke-dasharray="3 8"/>
            <path d="M146 34a26 26 0 0 1 26 26c0 19-26 42-26 42s-26-23-26-42a26 26 0 0 1 26-26" fill="var(--accent)"/>
            <circle cx="146" cy="60" r="9.5" fill="#fff" opacity=".95"/>
            <path d="m56 30 2.6 6.4 6.4 2.6-6.4 2.6L56 48l-2.6-6.4-6.4-2.6 6.4-2.6z" fill="var(--accent)" opacity=".5"/>
            <circle cx="238" cy="42" r="4.5" fill="var(--violet)" opacity=".45"/>
            <circle cx="248" cy="96" r="3.5" fill="var(--sky)" opacity=".45"/>
          </svg>
        </div>

        <h1 class="onb__title" data-i18n="onb.setupTitle">Set it up once</h1>
        <p class="onb__text" data-i18n="onb.setupText">Two permissions, and you can change either of them later.</p>

        <div class="onb-rows">
          <button class="onb-row pressable is-on" data-onb-toggle>
            <span class="onb-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-pin"/></svg></span>
            <span class="onb-row__body">
              <span class="onb-row__title" data-i18n="onb.permLocation">Use your location</span>
              <span class="onb-row__sub" id="onbLocSub">For weather, local services and nearby places</span>
            </span>
            <span class="switch is-on"><span class="switch__knob"></span></span>
          </button>
          <button class="onb-row pressable is-on" data-onb-toggle>
            <span class="onb-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-bell-ring"/></svg></span>
            <span class="onb-row__body">
              <span class="onb-row__title" data-i18n="onb.permNotify">Gentle reminders</span>
              <span class="onb-row__sub" id="onbNotifSub">A quiet nudge for the things you asked us to watch</span>
            </span>
            <span class="switch is-on"><span class="switch__knob"></span></span>
          </button>
        </div>

        <!-- Only shown when Islamic features are on -->
        <div data-faith="islamic">
          <p class="group-label" style="padding:0;margin:18px 0 9px">Prayer calculation method</p>
          <div class="onb-choice" id="onbMethod">
            <button class="is-active">University of Karachi</button>
            <button>Muslim World League</button>
            <button>ISNA</button>
            <button>Umm al-Qura</button>
            <button>Egyptian</button>
          </div>
        </div>

        <div class="onb__foot">
          <button class="btn btn--accent btn--block pressable" data-onb-next>Looks good <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></button>
          <p class="onb__note" data-i18n="onb.onDevice">Lume keeps this on your device. Nothing is uploaded.</p>
        </div>
      </section>

      <!-- 7 · What should we call you? (optional — §124.4) -->
      <section class="onb-step" data-step="7">
        <div class="onb__art" style="flex:0 0 auto;min-height:0;padding:6px 0 4px">
          <svg viewBox="0 0 292 132" fill="none" aria-hidden="true" style="max-width:250px">
            <circle cx="146" cy="70" r="58" fill="var(--accent)" opacity=".07"/>
            <g class="onb__float">
              <rect x="66" y="30" width="160" height="52" rx="18" fill="var(--card)" stroke="var(--border)"/>
              <rect x="84" y="48" width="66" height="10" rx="5" fill="var(--text)" opacity=".14"/>
              <rect x="156" y="46" width="2.6" height="16" rx="1.3" fill="var(--accent)"/>
            </g>
            <g class="onb__float onb__float--b">
              <circle cx="146" cy="104" r="20" fill="var(--tint-accent)"/>
              <circle cx="146" cy="99" r="6.4" fill="none" stroke="var(--accent)" stroke-width="2.4"/>
              <path d="M137 114a9.6 9.6 0 0 1 18 0" stroke="var(--accent)" stroke-width="2.4" fill="none" stroke-linecap="round"/>
            </g>
            <path d="m44 42 2.6 6.4 6.4 2.6-6.4 2.6L44 60l-2.6-6.4-6.4-2.6 6.4-2.6z" fill="var(--accent)" opacity=".45"/>
            <circle cx="248" cy="96" r="4.5" fill="var(--violet)" opacity=".4"/>
          </svg>
        </div>

        <p class="onb__kicker" data-i18n="onb.nameKicker">One last thing</p>
        <h1 class="onb__title" data-i18n="onb.nameTitle">What should we call you?</h1>
        <p class="onb__text" data-i18n="onb.nameText">Only used to greet you. You can change it later, or skip it entirely.</p>

        <div class="onb__namefield">
          <label class="field field--wide">
            <span class="field__label" data-i18n="acct.f.displayName">Display name</span>
            <span class="field__box">
              <input type="text" id="onbName" autocomplete="given-name" maxlength="40"
                     data-i18n-ph="onb.namePlaceholder" placeholder="Your name">
            </span>
          </label>
        </div>

        <div class="onb__foot">
          <button class="btn btn--accent btn--block pressable" id="onbNameNext">
            <span data-i18n="a.continue">Continue</span>
            <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg>
          </button>
          <button class="onb__link pressable" id="onbNameSkip" data-i18n="onb.nameSkip">Skip for now</button>
          <p class="onb__note" data-i18n="onb.nameNote">Lume keeps this on your device.</p>
        </div>
      </section>

      <!-- 8 · Done -->
      <section class="onb-step" data-step="8">
        <div class="onb__art">
          <div class="onb__seal">
            <svg viewBox="0 0 268 244" fill="none" aria-hidden="true">
              <circle cx="134" cy="118" r="98" fill="var(--accent)" opacity=".06"/>
              <circle cx="134" cy="118" r="64" fill="var(--tint-accent)"/>
              <circle class="onb__ring-draw" cx="134" cy="118" r="64" fill="none"
                      stroke="var(--accent)" stroke-width="5" stroke-linecap="round"
                      transform="rotate(-90 134 118)"/>
              <path class="onb__tick-draw" d="m102 118 22 24 46-52" stroke="var(--accent)" stroke-width="8"
                    stroke-linecap="round" stroke-linejoin="round" fill="none"/>
              <path class="onb__pop" d="m40 60 3.4 8.2 8.2 3.4-8.2 3.4L40 83l-3.4-8-8.2-3.4 8.2-3.4z" fill="var(--accent)" opacity=".6"/>
              <path class="onb__pop" d="m226 78 2.8 6.8 6.8 2.8-6.8 2.8-2.8 6.8-2.8-6.8-6.8-2.8 6.8-2.8z" fill="var(--violet)" opacity=".55"/>
              <circle class="onb__pop" cx="52" cy="176" r="6" fill="var(--sky)" opacity=".5"/>
              <circle class="onb__pop" cx="222" cy="166" r="4.5" fill="var(--accent)" opacity=".55"/>
            </svg>
          </div>
        </div>

        <p class="onb__kicker" data-i18n="onb.allSet">All set</p>
        <h1 class="onb__title" id="onbDoneTitle" data-i18n="onb.readyTitle">You’re all set</h1>
        <p class="onb__text" id="onbDoneText">Today’s plan is waiting on the home screen.</p>

        <div class="onb__foot">
          <button class="btn btn--accent btn--block pressable" id="onbFinish">Enter Lume <svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-r"/></svg></button>
          <p class="onb__note" data-i18n="onb.revisit">You can revisit this tour any time from Profile.</p>
        </div>
      </section>

    </div>
  </div>
`;
}
