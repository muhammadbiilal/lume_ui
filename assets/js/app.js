/* ============================================================
   Lume — app behaviour
   Vanilla JS, no dependencies. Runs from file:// too.

   The whole app hangs off one profile object. Religion and
   country are separate fields, and every surface — home, tools,
   today, search, explore, nav, notifications — asks the same
   visible() function. Nothing gets its own rule.
   ============================================================ */
import { LUME } from './catalogue.js';
import { LUME_GEO } from './geo.js';
import { LUME_SPEC } from './toolspec.js';
import { LUME_TOOLS } from './tools.js';
import { LUME_UI } from './toolkit.js';
import { LUME_DATA } from './tooldata.js';
import { LUME_SOLAR } from './solar.js';
import { LUME_I18N } from './i18n.js';
import { LUME_LOCALE } from './locale.js';
import { LUME_NOTIFY } from './notify.js';
import { LUME_ACCOUNT } from './account.js';
import { LUME_ACCOUNT_UI } from './account-ui.js';
import { LUME_CTX } from './toolctx.js';
import { store } from './core/storage.js';
import { $, $$, pad2, esc } from './core/dom.js';
import { createProfileStore } from './core/app-store.js';
import { createEligibility } from './core/eligibility.js';
import { createLifecycle } from './core/lifecycle.js';
import { createRouter } from './core/router.js';
import { createScreens } from './screens/index.js';
import { createShellContext } from './core/shell-context.js';
import { createAccountForms } from './services/account-forms.js';
import { sheetsTemplate } from './ui/sheets-markup.js';
import { onboardingTemplate } from './screens/onboarding.screen.js';

/* The two live instances the inspection surface in main.js publishes.
   They are filled in while the shell boots, below; main.js reads them
   after every import has evaluated, so they are never seen unset. */
export let account = null;
export let accountUI = null;

(function () {
  'use strict';

  var C = LUME;
  var GEO = LUME_GEO;
  var SPEC = LUME_SPEC;
  var TOOLS = LUME_TOOLS;
  var UI = LUME_UI;
  var C_DATA = LUME_DATA;
  var SOLAR = LUME_SOLAR;
  var I18N = LUME_I18N;

  /* ---------------------------------------------------------
     The screen set

     index.html is a shell: it ships the outlet, not the screens.
     Each screen builds its own root here, in the order it occupies
     the outlet, before anything below looks for a node inside one.
     --------------------------------------------------------- */
  var LIFECYCLE = createLifecycle({
    onError: function (id, hook, err) {
      /* A screen failing to clean up is a defect worth seeing, but it must
         not strand the user on the screen they asked to leave. */
      console.error('screen ' + id + '.' + hook + ' failed', err);
    }
  });

  /* Screens read this during render and never during mount; see
     core/shell-context.js for why that ordering is what makes it safe to
     hand out an object the shell has not finished filling in. */
  var SHELL = createShellContext();

  var screenOutlet = $('#screens');
  createScreens(SHELL).forEach(function (screen) {
    LIFECYCLE.register(screen);
    LIFECYCLE.mount(screen.id, screenOutlet);
  });

  /* The overlays sit outside the screen outlet on purpose: a sheet belongs
     to the shell, not to whichever screen happened to raise it. */
  $('#overlay-root').innerHTML = sheetsTemplate();
  $('#onboarding-root').innerHTML = onboardingTemplate();

  /* ---------------------------------------------------------
     Profile — the single source of personalisation
     --------------------------------------------------------- */
  var APP_VERSION = '4.1.0';

  /* The profile store owns the shape, the defaults, the load and the save.
     `profile` stays a live reference to the same object the store hands to
     the locale engine and the account engine, so nothing here holds a copy
     that can drift. */
  var STORE = createProfileStore(C);
  var profile = STORE.load();
  var saveProfile = STORE.save;
  var syncFaithFromInterests = STORE.syncFaithFromInterests;
  var hasInterest = STORE.has;


  /* Language, formatting and names all come from here. */
  var L = LUME_LOCALE(function () { return profile; });
  var t = L.t;

  /* The identity engine (§124). Constructed here because onboarding, the
     greeting and the profile surface all ask it the same question, and it
     must be able to answer "nothing" before any of them render. */
  var ACCT = LUME_ACCOUNT({
    t: t, L: L, store: store,
    profile: function () { return profile; },
    save: saveProfile,
    onSignOut: function () { resetNotificationsForAccount(); }
  });
  account = ACCT;

  /* Language drives text direction; country never does. */
  function applyLanguage() {
    root.lang = L.lang();
    root.dir = L.dir();
    document.body.classList.toggle('is-rtl', L.dir() === 'rtl');
  }

  /* ---------------------------------------------------------
     Visibility — the one rule everything obeys
     --------------------------------------------------------- */
  /* One selector, asked by every surface. See core/eligibility.js for the
     two rules and why they are kept apart. */
  var ELIGIBLE = createEligibility({ catalogue: C, profile: function () { return profile; }, t: t });
  var visibleIn = ELIGIBLE.visibleIn;
  var visible = ELIGIBLE.visible;
  var visibleFeatures = ELIGIBLE.visibleFeatures;
  var fname = ELIGIBLE.name;
  var feature = ELIGIBLE.feature;
  var actFor = ELIGIBLE.actFor;

  /* Every user-facing string in the markup carries a key, so switching
     language re-renders the whole shell without touching any screen. */
  function applyStrings(scope) {
    $$('[data-i18n]', scope).forEach(function (el) {
      el.textContent = t(el.dataset.i18n);
    });
    $$('[data-i18n-ph]', scope).forEach(function (el) {
      el.setAttribute('placeholder', t(el.dataset.i18nPh));
    });
    $$('[data-i18n-aria]', scope).forEach(function (el) {
      el.setAttribute('aria-label', t(el.dataset.i18nAria));
    });
  }

  /* Hiding is not the same as disabling (§64). A gated node loses its action
     and its tab stop as well as its box, so a stray querySelector, a stale
     deep link or a screen reader cannot reach through it. */
  function disarm(el, ok) {
    if (ok) {
      if (el.dataset.actOff !== undefined) { el.dataset.act = el.dataset.actOff; delete el.dataset.actOff; }
      if (el.dataset.sheetOff !== undefined) { el.dataset.sheet = el.dataset.sheetOff; delete el.dataset.sheetOff; }
      if (el.dataset.tabOff !== undefined) { el.removeAttribute('tabindex'); delete el.dataset.tabOff; }
      el.removeAttribute('aria-hidden');
    } else {
      if (el.dataset.act !== undefined) { el.dataset.actOff = el.dataset.act; delete el.dataset.act; }
      if (el.dataset.sheet !== undefined) { el.dataset.sheetOff = el.dataset.sheet; delete el.dataset.sheet; }
      el.setAttribute('aria-hidden', 'true');
      el.setAttribute('tabindex', '-1');
      el.dataset.tabOff = '1';
    }
  }

  function gate(el, ok) {
    el.classList.toggle('is-off', !ok);
    el.hidden = !ok;
    disarm(el, ok);
    /* A gated section takes its whole subtree with it — otherwise the
       section is hidden but the buttons inside it are still addressable. */
    $$('[data-act], [data-sheet], [data-act-off], [data-sheet-off]', el).forEach(function (child) {
      disarm(child, ok);
    });
  }

  /* Static markup opts in with data-faith / data-loc / data-int. */
  function applyVisibility() {
    $$('[data-faith]').forEach(function (el) {
      var want = el.dataset.faith;
      gate(el, want === 'islamic' ? profile.islamic : !profile.islamic);
    });

    /* data-loc takes a comma-separated country list, or "global" for the
       fallback copy shown when no sibling claims the user's country. It is
       resolved against the siblings, not against the whole catalogue —
       otherwise a country that has *any* localised feature would lose the
       fallback and render nothing at all. */
    $$('[data-loc="global"]').forEach(function (el) {
      var claimed = false;
      var parent = el.parentNode;
      if (parent) {
        $$('[data-loc]', parent).forEach(function (sib) {
          if (sib === el || sib.dataset.loc === 'global') return;
          if (sib.dataset.loc.split(',').indexOf(profile.country) !== -1) claimed = true;
        });
      }
      gate(el, !claimed);
    });

    $$('[data-loc]').forEach(function (el) {
      var want = el.dataset.loc;
      if (want === 'global') return;
      gate(el, want.split(',').indexOf(profile.country) !== -1);
    });

    /* Interests only re-order relevance; they never hide a tool outright,
       so this stays a soft toggle rather than a gate. */
    $$('[data-int]').forEach(function (el) {
      if (!profile.interests.length) { gate(el, true); return; }
      gate(el, el.dataset.int.split(/\s+/).some(hasInterest));
    });
  }

  /* ---------------------------------------------------------
     Theme
     --------------------------------------------------------- */
  var root = document.documentElement;

  function setTheme(theme, remember) {
    root.dataset.theme = theme;
    if (remember) store.set('lume-theme', theme);
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', theme === 'dark' ? '#0A0A0B' : '#F6F6F4');
  }
  setTheme(root.dataset.theme, false);

  /* §124.27 — three states, not two: an explicit light, an explicit dark,
     and following the system, which is the absence of a stored choice. */
  function setThemeMode(mode) {
    if (mode === 'system') {
      store.set('lume-theme', '');
      var dark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
      setTheme(dark ? 'dark' : 'light', false);
      return;
    }
    setTheme(mode, true);
  }

  /* "Follow the system" has to actually follow it, rather than sampling the
     preference once at startup and freezing. */
  (function watchSystemTheme() {
    if (!window.matchMedia) return;
    var mq = window.matchMedia('(prefers-color-scheme: dark)');
    var onChange = function () {
      if (store.get('lume-theme')) return;     /* an explicit choice wins */
      setTheme(mq.matches ? 'dark' : 'light', false);
      if (typeof renderProfile === 'function') renderProfile();
    };
    if (mq.addEventListener) mq.addEventListener('change', onChange);
    else if (mq.addListener) mq.addListener(onChange);
  })();

  /* ---------------------------------------------------------
     Clock, greeting, date
     --------------------------------------------------------- */
  function tickClock() {
    var el = $('#statusClock');
    if (!el) return;
    var d = new Date();
    el.textContent = d.getHours() + ':' + pad2(d.getMinutes());
  }

  /* ---------------------------------------------------------
     Toast
     --------------------------------------------------------- */
  var toastEl = $('#toast'), toastText = $('#toastText'), toastTimer;
  function toast(msg) {
    if (!toastEl) return;
    toastText.textContent = msg;
    toastEl.classList.add('is-open');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.classList.remove('is-open'); }, 2100);
  }

  /* ---------------------------------------------------------
     Navigation — the tab set itself is personalised
     --------------------------------------------------------- */
  var TAB_META = {
    home:    { key: 'nav.home',    icon: 'i-home' },
    tools:   { key: 'nav.tools',   icon: 'i-grid' },
    trains:  { key: 'nav.trains',  icon: 'i-train' },
    today:   { key: 'nav.today',   icon: 'i-sun' },
    explore: { key: 'nav.explore', icon: 'i-compass' },
    profile: { key: 'nav.profile', icon: 'i-user' }
  };

  function tabOrder() {
    /* Trains is a first-class destination in Pakistan; everywhere else
       Explore takes that slot and Trains lives in Tools. */
    return profile.country === 'PK'
      ? ['home', 'tools', 'trains', 'today', 'profile']
      : ['home', 'tools', 'today', 'explore', 'profile'];
  }

  var PKEYS = { Fajr: 'fajr', Sunrise: 'sunrise', Dhuhr: 'dhuhr', Asr: 'asr', Maghrib: 'maghrib', Isha: 'isha' };

  /* Navigation lives in core/router.js and core/lifecycle.js. What stays
     here is the two things the router asks the product: which destinations
     are tabs right now, and what a tab looks like. */
  function renderTabBar() {
    var bar = $('#tabbar');
    if (!bar) return;
    var pill = '<span class="tabbar__pill" id="tabPill"></span>';
    bar.innerHTML = pill + tabOrder().map(function (id) {
      var m = TAB_META[id];
      return '<button class="tab" data-tab="' + id + '" role="tab" aria-selected="false">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#' + m.icon + '"/></svg>' +
        '<span class="tab__label">' + esc(t(m.key)) + '</span></button>';
    }).join('');
  }

  var ROUTER = createRouter({
    lifecycle: LIFECYCLE,
    tabOrder: tabOrder,
    renderTabBar: renderTabBar,
    onActivate: function (name, previous, opts) {
      /* A nested route does not survive navigating away from the screen
         that hosts it. Each of the three that has one — the tool host, the
         account and authentication — releases its own in onLeave, so
         there is nothing for the router to clear on their behalf. */

      /* The centre is a destination rather than a tab, so it remembers
         where the user was and its back control returns them there. Only
         a tab is somewhere to come back to: a tool that opened the centre
         is not, or Back would return to an empty tool screen. */
      if (name === 'notifications') {
        if (previous !== 'notifications') notifReturnTab = ROUTER.isTab(previous) ? previous : 'home';
        renderNotifCentre();
      }

      if (!opts.quiet) animateBars($('#screen-' + name));
    }
  });

  /* The names the rest of this file still calls navigation by. */
  function goTo(name, quiet) { ROUTER.go(name, { quiet: quiet }); }
  function renderTabs() { ROUTER.refreshTabs(); }
  function movePill(tab) { ROUTER.movePill(tab); }

  /* §116 — above a real desktop width the shell stops presenting itself as a
     handset and the compositions inside gain columns. Everything below that
     stays exactly as designed for a phone. */
  function applyWidth() {
    var el = $('#app');
    if (el) el.classList.toggle('app--wide', window.innerWidth >= 1180);
  }

  window.addEventListener('resize', function () {
    applyWidth();
    movePill($('.tab.is-active'));
  });

  function animateBars(scope) {
    $$('[data-fill]', scope).forEach(function (bar) {
      bar.style.width = '0%';
      requestAnimationFrame(function () {
        requestAnimationFrame(function () { bar.style.width = bar.dataset.fill + '%'; });
      });
    });
    var pin = $('.live-train__pin', scope);
    if (pin) {
      pin.style.left = '0%';
      requestAnimationFrame(function () {
        requestAnimationFrame(function () { pin.style.left = '62%'; });
      });
    }
  }

  /* ---------------------------------------------------------
     Sheets
     --------------------------------------------------------- */
  var scrim = $('#scrim');
  var openSheet = null;

  function sheetOpen(name) {
    var sheet = $('#sheet-' + name);
    if (!sheet) return;
    if (openSheet && openSheet !== sheet) openSheet.classList.remove('is-open');
    sheet.classList.add('is-open');
    scrim.classList.add('is-open');
    openSheet = sheet;

    /* §101 — while a modal sheet is up, the screen behind it is not a place
       to tab into, and focus starts inside the dialog rather than on the
       destructive button it happens to contain first. */
    var behind = $('.screen.is-active');
    /* Only if the visibility system has not already hidden it for its own
       reasons — restoring blindly would un-hide a gated screen (§64). */
    if (behind && !behind.hasAttribute('aria-hidden')) {
      behind.setAttribute('aria-hidden', 'true');
      sheetHid = behind;
    }
    sheetOpener = document.activeElement;

    if (name === 'personalise' && setPicker) hydratePersonalise();
    if (name === 'market') TOOL_HOST.fillMarketPicker();
    if (name === 'notifprefs') renderNotifPrefs();
    if (name === 'notifpush') renderPushAsk();
    if (name === 'search') {
      resetSearch();
      setTimeout(function () { var i = $('#globalSearch'); if (i) i.focus(); }, 320);
    }
    animateBars(sheet);
    setTimeout(function () {
      var first = $('[data-close], .btn--ghost, button', sheet);
      if (first && first.focus) { try { first.focus(); } catch (e) {} }
    }, 60);
  }

  var sheetOpener = null, sheetHid = null;

  function sheetClose() {
    if (openSheet) openSheet.classList.remove('is-open');
    openSheet = null;
    scrim.classList.remove('is-open');
    if (sheetHid) { sheetHid.removeAttribute('aria-hidden'); sheetHid = null; }
    if (sheetOpener && sheetOpener.focus) { try { sheetOpener.focus(); } catch (e) {} }
    sheetOpener = null;
  }

  scrim.addEventListener('click', sheetClose);
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && openSheet) sheetClose();
  });
  $$('[data-close]').forEach(function (b) { b.addEventListener('click', sheetClose); });

  /* Swipe a sheet down to dismiss */
  $$('.sheet').forEach(function (sheet) {
    var startY = 0, dy = 0, dragging = false;
    var handles = [$('.sheet__grab', sheet), $('.sheet__head', sheet)].filter(Boolean);

    function down(y) { startY = y; dy = 0; dragging = true; sheet.style.transition = 'none'; }
    function move(y) {
      if (!dragging) return;
      dy = Math.max(0, y - startY);
      sheet.style.transform = 'translateY(' + dy + 'px)';
    }
    function up() {
      if (!dragging) return;
      dragging = false;
      sheet.style.transition = '';
      sheet.style.transform = '';
      if (dy > 90) sheetClose();
    }

    handles.forEach(function (h) {
      h.style.touchAction = 'none';
      h.addEventListener('touchstart', function (e) { down(e.touches[0].clientY); }, { passive: true });
      h.addEventListener('touchmove',  function (e) { move(e.touches[0].clientY); }, { passive: true });
      h.addEventListener('touchend', up);
      h.addEventListener('mousedown', function (e) {
        if (e.target.closest('button, input')) return;
        down(e.clientY);
      });
    });
    document.addEventListener('mousemove', function (e) { move(e.clientY); });
    document.addEventListener('mouseup', up);
  });

  /* ---------------------------------------------------------
     One action vocabulary for every tappable thing
     --------------------------------------------------------- */
  function runAct(act, label) {
    if (!act) return;
    var bits = act.split(':');
    var kind = bits.shift();
    var arg = bits.join(':');
    /* Tool screens own most of the vocabulary now; the shell keeps the rest. */
    if (typeof toolAction === 'function' && toolAction(kind, arg)) return;

    /* Notifications and sharing are the shell's, not any tool's. They used
       to be cases in the tool action switch, which meant a tool screen was
       nominally responsible for browser permission and the share sheet. */
    if (kind === 'share') { openShare(bits[0] || TOOL_HOST.openId()); return; }

    if (kind === 'pushallow') {
      NOTIFY.requestPush(function (result) {
        sheetClose();
        if (result === 'granted') {
          toast(t('n.push.thanks'));
          var pending = TOOL_HOST.takePendingAlert();
          if (pending) toast(t('n.armed', { name: pending.entity || pending.tool }));
        } else if (result === 'denied') {
          toast(t('n.push.deniedHelp'));
        } else {
          toast(t('n.push.unsupported'));
        }
        renderNotifBadge();
        if (ROUTER.current() === 'notifications') renderNotifCentre();
      });
      return;
    }

    if (kind === 'notifrestore') {
      NOTIFY.restoreAll();
      toast(t('n.restored'));
      renderNotifBadge();
      if (ROUTER.current() === 'notifications') renderNotifCentre();
      return;
    }

    if (kind === 'notiffilter') { NOTIF_CENTRE.setFilter(bits[0]); renderNotifCentre(); return; }
    if (kind === 'notifreadall') { NOTIFY.markRead(); renderNotifCentre(); return; }
    if (typeof accountAction === 'function' && accountAction(kind, arg)) return;
    if (kind === 'sheet') sheetOpen(arg);
    else if (kind === 'tab') goTo(arg);
    else if (kind === 'toast') toast(arg);
    else if (kind === 'theme') {
      /* Through the same door as the Appearance screen, so the two cannot
         disagree — and in the user's language. */
      setThemeMode(root.dataset.theme === 'dark' ? 'light' : 'dark');
      renderProfile();
      toast(t('acct.themeSwitched', {
        mode: t(root.dataset.theme === 'dark' ? 'acct.appearanceDark' : 'acct.appearanceLight')
      }));
    }
    else if (label) toast(label);
  }

  document.addEventListener('click', function (e) {
    var el = e.target.closest('[data-tab], [data-act], [data-sheet], [data-toast], [data-bookmark], [data-switch], [data-pref]');
    if (!el) return;

    /* data-tab covers both the tab bar and every in-page "Explore →" style
       link, so those navigate the same way wherever they appear. */
    if (el.dataset.tab) { goTo(el.dataset.tab); return; }

    if (el.dataset.fid) noteRecent(el.dataset.fid);

    if (el.hasAttribute('data-bookmark')) {
      var on = el.classList.toggle('is-on');
      toast(on ? 'Saved to your bookmarks' : 'Removed from bookmarks');
      return;
    }
    if (el.hasAttribute('data-switch') || el.hasAttribute('data-pref')) {
      var sw = el.matches('.switch') ? el : $('.switch', el);
      if (sw) {
        var isOn = sw.classList.toggle('is-on');
        if (el.dataset.pref) {
          profile.prefs[el.dataset.pref] = isOn;
          saveProfile();
          renderAll();
        }
      }
      return;
    }
    if (el.dataset.act) { runAct(el.dataset.act); return; }
    if (el.dataset.sheet) { sheetOpen(el.dataset.sheet); return; }
    if (el.dataset.toast) { toast(el.dataset.toast); }
  });

  /* ---------------------------------------------------------
     Prayer times — location aware, only ever used when Islamic
     content is on
     --------------------------------------------------------- */
  /* Where the user actually is: city coordinates when we have them, the
     country's own point otherwise. */
  function here() {
    return SOLAR.coordsFor(L.country(), profile.city);
  }

  var prayerCache = null;
  function prayerSet() {
    var pos = here();
    var key = profile.country + '|' + profile.city + '|' + profile.method + '|' +
              new Date().toDateString();
    if (prayerCache && prayerCache.key === key) return prayerCache.list;
    prayerCache = {
      key: key,
      list: SOLAR.prayerTimes({
        lat: pos.lat, lon: pos.lon, tz: L.country().tz,
        method: profile.method, date: new Date()
      })
    };
    return prayerCache.list;
  }

  function mins(p) { return p.h * 60 + p.m; }
  function hhmm(p) { return L.time(p.h, p.m); }

  function prayerState() {
    var list = prayerSet();
    var main = list.filter(function (p) { return !p.minor; });
    var now = new Date();
    var nowM = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;

    var next = null, prev = null;
    for (var i = 0; i < main.length; i++) {
      if (mins(main[i]) > nowM) { next = main[i]; prev = main[i - 1] || null; break; }
    }
    if (!next) { next = main[0]; prev = main[main.length - 1]; }

    var toNext = mins(next) - nowM;
    if (toNext < 0) toNext += 1440;
    var span = prev ? mins(next) - mins(prev) : 1440;
    if (span <= 0) span += 1440;

    return { list: list, main: main, next: next, prev: prev, toNext: toNext, progress: Math.max(0, Math.min(1, 1 - toNext / span)) };
  }

  /* ---------------------------------------------------------
     Recently used

     Written by whoever opens a tool, read by the Tools screen. It lives
     here rather than on that screen because opening a tool is not a Tools
     screen event: it happens from Home, from search, from a notification
     and from a related-tools row.
     --------------------------------------------------------- */
  function noteRecent(id) {
    var f = feature(id);
    /* A feature this user cannot see does not enter their history. */
    if (!f || !visible(f)) return;
    STORE.patch({
      recents: [id].concat(profile.recents.filter(function (x) { return x !== id; })).slice(0, 6)
    });
  }

  /* ---------------------------------------------------------
     Global search
     --------------------------------------------------------- */
  var EXTRA_INDEX = [
    { nk: 'extra.darkMode', sub: 'Settings', i: 'i-moon', act: 'theme', kw: 'theme night light appearance' },
    { nk: 'extra.personalise', sub: 'Settings', i: 'i-sliders', act: 'sheet:personalise', kw: 'interests country islamic content preferences religion' },
    { n: 'Surah Ar-Rahman', sub: 'Qur’an · chapter 55', i: 'i-book', act: 'tool:quran', faith: 1, kw: 'surah rahman 55 recite' },
    { n: 'Surah Al-Kahf', sub: 'Qur’an · chapter 18', i: 'i-book', act: 'tool:quran', faith: 1, kw: 'surah kahf 18 friday cave' },
    { n: 'Surah Yaseen', sub: 'Qur’an · chapter 36', i: 'i-book', act: 'tool:quran', faith: 1, kw: 'surah yaseen yasin 36' },
    { n: 'Karachi Cantt', sub: 'Station · Pakistan Railways', i: 'i-train', act: 'tab:trains', loc: 'PK', kw: 'station karachi cantt platform' },
    { n: 'Masjid-e-Tooba', sub: 'Nearby · 650 m', i: 'i-mosque', act: 'toast:Masjid-e-Tooba · 650 m', faith: 1, kw: 'mosque masjid nearby' }
  ];

  function searchIndex() {
    var out = visibleFeatures().map(function (f) {
      var cat = C.CATEGORIES.filter(function (c) { return c.id === f.c; })[0];
      return { n: fname(f), sub: cat ? t('cat.' + cat.id) : '', i: f.i, act: actFor(f), fid: f.id,
               hay: (f.n + ' ' + fname(f) + ' ' + (f.kw || '')).toLowerCase() };
    });
    EXTRA_INDEX.forEach(function (x) {
      if (x.faith && !profile.islamic) return;
      if (x.loc && x.loc !== profile.country) return;
      /* Proper nouns (a surah, a station) stay as written; anything that is
         really a UI label carries a key instead (§47, §106). */
      var name = x.nk ? t(x.nk) : x.n;
      out.push({ n: name, sub: x.subk ? t(x.subk) : x.sub, i: x.i, act: x.act,
                 hay: (name + ' ' + x.n + ' ' + (x.kw || '')).toLowerCase() });
    });
    return out;
  }

  function runSearch(q) {
    q = q.trim().toLowerCase();
    var idle = $('#searchIdle'), results = $('#searchResults'), empty = $('#searchEmpty');
    if (!results) return;

    if (!q) {
      idle.hidden = false; results.hidden = true;
      empty.classList.remove('is-shown');
      return;
    }
    idle.hidden = true; results.hidden = false;

    var words = q.split(/\s+/).filter(Boolean);
    var hits = searchIndex().map(function (item) {
      var score = 0;
      words.forEach(function (w) {
        var at = item.hay.indexOf(w);
        if (at === -1) { score = -99; return; }
        score += at === 0 ? 6 : item.hay.indexOf(' ' + w) !== -1 ? 4 : 2;
      });
      return { item: item, score: score };
    }).filter(function (h) { return h.score > 0; })
      .sort(function (a, b) { return b.score - a.score; })
      .slice(0, 14);

    empty.classList.toggle('is-shown', !hits.length);
    results.innerHTML = hits.length ? '<div class="list list--flat">' + hits.map(function (h) {
      var it = h.item;
      return '<button class="list-row pressable" data-act="' + it.act + '"' +
        (it.fid ? ' data-fid="' + it.fid + '"' : '') + ' data-searchhit>' +
        '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + it.i + '"/></svg></span>' +
        '<span class="list-row__body"><span class="list-row__title">' + esc(it.n) + '</span>' +
        '<span class="list-row__sub">' + esc(it.sub) + '</span></span>' +
        '<span class="list-row__end"><svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-ur"/></svg></span>' +
      '</button>';
    }).join('') + '</div>' : '';
  }

  function resetSearch() {
    var i = $('#globalSearch');
    if (i) i.value = '';
    runSearch('');
    renderSearchIdle();
  }

  function renderSearchIdle() {
    var host = $('#searchSuggest');
    if (host) {
      var picks = [];
      if (profile.country === 'PK') picks.push('petrol', 'trains', 'bills');
      if (profile.islamic) picks.push('qibla', 'surah rahman');
      picks.push('currency', 'calculator', 'weather');
      host.innerHTML = picks.slice(0, 6).map(function (p) {
        return '<button class="chip" data-suggest="' + esc(p) + '">' + esc(p) + '</button>';
      }).join('');
    }
    var rec = $('#searchRecent');
    if (rec) {
      var items = profile.recents.map(feature).filter(function (f) { return f && visible(f); }).slice(0, 4);
      if (!items.length) items = ['calculator', 'weather', 'calendar'].map(feature).filter(function (f) { return f && visible(f); });
      rec.innerHTML = items.map(function (f) {
        return '<button class="list-row pressable" data-act="' + actFor(f) + '" data-fid="' + f.id + '">' +
          '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg></span>' +
          '<span class="list-row__body"><span class="list-row__title">' + esc(fname(f)) + '</span>' +
          '<span class="list-row__sub">' + esc(f.m || '') + '</span></span>' +
          '<span class="list-row__end"><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span></button>';
      }).join('');
    }
  }

  var globalSearch = $('#globalSearch');
  if (globalSearch) globalSearch.addEventListener('input', function () { runSearch(this.value); });

  document.addEventListener('click', function (e) {
    var s = e.target.closest('[data-suggest]');
    if (s) {
      var i = $('#globalSearch');
      if (i) { i.value = s.dataset.suggest; runSearch(i.value); }
      return;
    }
    if (e.target.closest('[data-searchhit]')) setTimeout(sheetClose, 60);
  });

  /* ---------------------------------------------------------
     Feature metadata

     A catalogue entry carries the line shown under its name on a tool
     card — "23° Clear", "Asr 3:39 pm", a running total. Those lines
     are the catalogue's, not any one screen's: the same card appears in
     Tools, in search, in recents and in related tools. So they are kept
     in step here, once, before the screens that display them render.

     Every figure below is a share of a monthly budget rather than a
     converted amount, so the numbers stay believable in Karachi, Tokyo
     and New York alike. Converting one country's figures at the exchange
     rate would not.
     --------------------------------------------------------- */
  var SPEND = { ledger: 0.106, subs: 0.052 };

  function budget() {
    var b = C.BUDGET[profile.country];
    if (b !== undefined) return b;
    /* No local figure: fall back to a typical 300 USD, converted. */
    return 300 * (L.RATES[L.currencyCode()] || 1);
  }

  function syncFeatureMeta() {
    var b = budget();

    var weather = feature('weather');
    if (weather) {
      /* Or the tool card would still claim 34° in New York. */
      var w = C.weatherFor(profile.country, L.country().tz);
      weather.m = L.temp(w.temp) + ' ' + w.desc.split(' · ')[0];
    }

    var ledger = feature('ledger');
    if (ledger) ledger.m = L.moneyRaw(Math.round(b * SPEND.ledger), null, 0);

    var subs = feature('subs');
    if (subs) subs.m = L.moneyRaw(Math.round(b * SPEND.subs), null, 0);

    var prayer = feature('prayer');
    if (prayer && profile.islamic) {
      var st = prayerState();
      prayer.m = st.next.name + ' ' + hhmm(st.next);
    }
  }

  /* ---------------------------------------------------------
     Calculator
     --------------------------------------------------------- */
  var calc = { acc: null, op: null, entry: '0', fresh: true };
  var calcValue = $('#calcValue'), calcHistory = $('#calcHistory');

  function trimNum(n) {
    if (!isFinite(n)) return 'Error';
    return String(Math.round(n * 1e10) / 1e10);
  }

  /* ---------------------------------------------------------
     Interest picker — grouped, with the faith group behind a switch
     --------------------------------------------------------- */
  var PICK_MIN = 5, PICK_MAX = 10;

  function makePicker(host, countEl, clearEl, onChange, ctxFn) {
    if (!host) return null;
    ctxFn = ctxFn || function () { return profile; };
    var sel = new Set();
    var faithOpen = false;

    /* Do not offer an interest that cannot lead anywhere — "Trains" is a dead
       choice outside Pakistan. The faith group is the exception: it is the
       switch that makes its own features exist. */
    function liveItems(g) {
      if (g.faith) return g.items;
      var ctx = ctxFn();
      return g.items.filter(function (it) {
        return C.FEATURES.some(function (f) {
          return f.ints && f.ints.indexOf(it.id) !== -1 && visibleIn(f, ctx);
        });
      });
    }

    function build() {
      host.innerHTML = C.INTEREST_GROUPS.map(function (g) {
        if (g.faith) {
          return '<div class="pickgroup pickgroup--faith" data-group="faith">' +
            '<button type="button" class="faithtoggle' + (faithOpen ? ' is-on' : '') + '" data-faithtoggle aria-pressed="' + faithOpen + '">' +
              '<span class="faithtoggle__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-moon-star"/></svg></span>' +
              '<span class="faithtoggle__body">' +
                '<span class="faithtoggle__title">' + esc(t('pers.islamic')) + '</span>' +
                '<span class="faithtoggle__sub">' + esc(t('pers.islamicSub')) + '</span>' +
              '</span>' +
              '<span class="switch' + (faithOpen ? ' is-on' : '') + '"><span class="switch__knob"></span></span>' +
            '</button>' +
            '<div class="picker picker--nested"' + (faithOpen ? '' : ' hidden') + '>' +
              g.items.map(pickBtn).join('') +
            '</div>' +
          '</div>';
        }
        var items = liveItems(g);
        if (!items.length) return '';
        return '<div class="pickgroup"><p class="pickgroup__label">' + esc(t('ig.' + g.id)) + '</p>' +
          '<div class="picker">' + items.map(pickBtn).join('') + '</div></div>';
      }).join('');
      sync();
    }

    function pickBtn(it) {
      return '<button type="button" class="pick" data-id="' + it.id + '" aria-pressed="false">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#' + it.icon + '"/></svg>' +
        '<span>' + esc(it.label) + '</span></button>';
    }

    function sync() {
      var full = sel.size >= PICK_MAX;
      $$('.pick', host).forEach(function (b) {
        var on = sel.has(b.dataset.id);
        b.classList.toggle('is-on', on);
        b.classList.toggle('is-muted', !on && full);
        b.setAttribute('aria-pressed', on ? 'true' : 'false');
      });
      if (countEl) {
        countEl.innerHTML = sel.size < PICK_MIN
          ? t('onb.minimum', { n: '<b>' + L.num(sel.size) + '</b>', min: L.num(PICK_MIN) })
          : t('onb.selected', { n: '<b>' + L.num(sel.size) + '</b>', max: L.num(PICK_MAX) });
      }
      if (onChange) onChange(sel.size >= PICK_MIN, Array.from(sel), faithOpen);
    }

    host.addEventListener('click', function (e) {
      var ft = e.target.closest('[data-faithtoggle]');
      if (ft) {
        faithOpen = !faithOpen;
        if (!faithOpen) C.FAITH_INTERESTS.forEach(function (id) { sel.delete(id); });
        else ['prayer', 'quran', 'duas'].forEach(function (id) { if (sel.size < PICK_MAX) sel.add(id); });
        build();
        return;
      }
      var b = e.target.closest('.pick');
      if (!b) return;
      var id = b.dataset.id;
      if (sel.has(id)) {
        sel.delete(id);
      } else if (sel.size >= PICK_MAX) {
        toast('Up to ' + PICK_MAX + ' — remove one first');
        return;
      } else {
        sel.add(id);
        b.classList.remove('bump');
        void b.offsetWidth;
        b.classList.add('bump');
      }
      sync();
    });

    if (clearEl) clearEl.addEventListener('click', function () { sel.clear(); sync(); });

    build();
    return {
      get: function () { return Array.from(sel); },
      faith: function () { return faithOpen; },
      refresh: build,
      set: function (list, faith) {
        sel = new Set(list || []);
        faithOpen = faith !== undefined ? faith
          : (list || []).some(function (id) { return C.FAITH_INTERESTS.indexOf(id) !== -1; });
        build();
      }
    };
  }

  /* ---------------------------------------------------------
     Personalisation sheet
     --------------------------------------------------------- */
  var draft = { country: profile.country, city: profile.city, islamic: profile.islamic };

  var setPicker = makePicker($('#setPicker'), $('#setPickCount'), $('#setPickClear'), function (enough, list, faith) {
    var b = $('#setPickSave');
    if (b) b.disabled = !enough;
    if (faith !== draft.islamic) { draft.islamic = faith; syncIslamicRow(); }
  }, function () { return draft; });

  function syncIslamicRow() {
    var sw = $('#setIslamicSwitch');
    if (sw) sw.classList.toggle('is-on', draft.islamic);
    var icon = $('#setIslamicIcon');
    if (icon) {
      icon.style.background = draft.islamic ? 'var(--tint-accent)' : '';
      icon.style.color = draft.islamic ? 'var(--accent)' : '';
    }
  }

  /* ---------------------------------------------------------
     Location picker — country → region → city, searchable across
     the whole world. One component, mounted in onboarding and in
     Personalisation, so both stay identical.
     --------------------------------------------------------- */
  function makeLocationPicker(host, draftRef, opts) {
    if (!host) return null;
    opts = opts || {};
    var stage = opts.stage || 'country';
    var query = '';

    function countryRow(code, active) {
      var c = GEO.get(code);
      return '<button class="locrow pressable' + (active ? ' is-on' : '') + '" data-pick-country="' + code + '">' +
        '<span class="locrow__code">' + esc(code) + '</span>' +
        '<span class="locrow__name">' + esc(L.countryName(code)) + '</span>' +
        '<span class="locrow__meta">' + esc(c.currency) + '</span>' +
      '</button>';
    }

    function section(labelKey, codes, activeCode) {
      if (!codes.length) return '';
      return '<p class="locgroup">' + esc(t(labelKey)) + '</p>' +
             '<div class="loclist">' + codes.map(function (c) {
               return countryRow(c, c === activeCode);
             }).join('') + '</div>';
    }

    function renderCountry() {
      var d = draftRef();
      var q = query.trim().toLowerCase();
      var body = '';

      if (q) {
        var hits = GEO.COUNTRIES.filter(function (c) {
          return L.countryName(c.code).toLowerCase().indexOf(q) !== -1 ||
                 c.code.toLowerCase() === q ||
                 c.currency.toLowerCase() === q;
        }).slice(0, 60);
        body = hits.length
          ? '<div class="loclist">' + hits.map(function (c) { return countryRow(c.code, c.code === d.country); }).join('') + '</div>'
          : '<p class="locempty">' + esc(t('search.nothing')) + '</p>';
      } else {
        var recent = (profile.recentCountries || []).filter(function (c) { return GEO.get(c); }).slice(0, 4);
        body += section('pers.recent', recent, d.country);
        body += section('pers.popular', GEO.POPULAR, d.country);
        body += section('pers.allCountries',
          GEO.COUNTRIES.map(function (c) { return c.code; })
            .sort(function (a, b) { return L.countryName(a).localeCompare(L.countryName(b), L.lang()); }),
          d.country);
      }

      host.innerHTML =
        '<label class="search search--sm">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg>' +
          '<input type="search" class="locsearch" value="' + esc(query) + '" ' +
          'placeholder="' + esc(t('pers.searchCountries')) + '" aria-label="' + esc(t('pers.searchCountries')) + '">' +
        '</label>' +
        '<div class="locscroll">' + body + '</div>';
    }

    function renderCity() {
      var d = draftRef();
      var c = GEO.get(d.country);
      var q = query.trim().toLowerCase();
      var body = '';

      function cityRow(city, region) {
        return '<button class="locrow pressable' + (city === d.city ? ' is-on' : '') + '" ' +
          'data-pick-city="' + esc(city) + '"' + (region ? ' data-pick-region="' + esc(region) + '"' : '') + '>' +
          '<span class="locrow__name">' + esc(city) + '</span>' +
          (region ? '<span class="locrow__meta">' + esc(region) + '</span>' : '') +
        '</button>';
      }

      if (c.regions && !q) {
        Object.keys(c.regions).forEach(function (r) {
          body += '<p class="locgroup">' + esc(r) + '</p><div class="loclist">' +
            c.regions[r].map(function (city) { return cityRow(city, r); }).join('') + '</div>';
        });
      } else {
        var all = GEO.citiesOf(d.country);
        var hits = q ? all.filter(function (x) { return x.toLowerCase().indexOf(q) !== -1; }) : all;
        body = hits.length
          ? '<div class="loclist">' + hits.map(function (city) {
              return cityRow(city, GEO.regionOf(d.country, city));
            }).join('') + '</div>'
          : '<p class="locempty">' + esc(t('search.nothing')) + '</p>';
      }

      host.innerHTML =
        (opts.stage ? '' :
          '<button class="locback pressable" data-pick-back>' +
            '<svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-l"/></svg>' +
            esc(L.countryName(d.country)) +
          '</button>') +
        '<label class="search search--sm">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg>' +
          '<input type="search" class="locsearch" value="' + esc(query) + '" ' +
          'placeholder="' + esc(t('pers.searchCities')) + '" aria-label="' + esc(t('pers.searchCities')) + '">' +
        '</label>' +
        '<button class="locrow locrow--action pressable" data-pick-locate>' +
          '<span class="locrow__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-navigation"/></svg></span>' +
          '<span class="locrow__name">' + esc(t('pers.useLocation')) + '</span>' +
        '</button>' +
        '<div class="locscroll">' + body + '</div>';
    }

    function render() {
      if (stage === 'city') renderCity(); else renderCountry();
    }

    host.addEventListener('input', function (e) {
      if (!e.target.classList.contains('locsearch')) return;
      query = e.target.value;
      var pos = e.target.selectionStart;
      render();
      var input = $('.locsearch', host);
      if (input) { input.focus(); try { input.setSelectionRange(pos, pos); } catch (err) {} }
    });

    host.addEventListener('click', function (e) {
      var cb = e.target.closest('[data-pick-country]');
      if (cb) {
        var d = draftRef();
        d.country = cb.dataset.pickCountry;
        var cities = GEO.citiesOf(d.country);
        d.city = cities[0] || '';
        d.region = GEO.regionOf(d.country, d.city);
        query = '';
        if (opts.stage) { render(); }
        else { stage = 'city'; render(); }
        if (opts.onChange) opts.onChange(d);
        return;
      }
      var cy = e.target.closest('[data-pick-city]');
      if (cy) {
        var d2 = draftRef();
        d2.city = cy.dataset.pickCity;
        d2.region = cy.dataset.pickRegion || GEO.regionOf(d2.country, d2.city);
        render();
        if (opts.onChange) opts.onChange(d2);
        return;
      }
      if (e.target.closest('[data-pick-back]')) { stage = 'country'; query = ''; render(); return; }
      if (e.target.closest('[data-pick-locate]')) { useCurrentLocation(draftRef, function () { render(); if (opts.onChange) opts.onChange(draftRef()); }); }
    });

    render();
    return {
      render: render,
      reset: function (st) { stage = st || opts.stage || 'country'; query = ''; render(); }
    };
  }

  /* Optional, never required: the user can always set location by hand. */
  function useCurrentLocation(draftRef, done) {
    if (!navigator.geolocation) { toast(t('pers.useLocation') + ' — unavailable'); return; }
    toast(t('pers.useLocation') + '…');
    navigator.geolocation.getCurrentPosition(function (pos) {
      var best = null, bestD = Infinity;
      GEO.COUNTRIES.forEach(function (c) {
        var dLat = c.lat - pos.coords.latitude, dLon = c.lon - pos.coords.longitude;
        var dist = dLat * dLat + dLon * dLon;
        if (dist < bestD) { bestD = dist; best = c; }
      });
      if (best) {
        var d = draftRef();
        d.country = best.code;
        d.city = GEO.citiesOf(best.code)[0] || '';
        d.region = GEO.regionOf(best.code, d.city);
        done();
      }
    }, function () {
      toast('Location unavailable — choose it by hand');
    }, { timeout: 8000 });
  }

  /* ---- Personalisation sheet ---- */

  function syncLocationRows() {
    var cn = $('#setCountryValue');
    if (cn) cn.textContent = L.countryName(draft.country);
    var rg = $('#setRegionRow');
    if (rg) rg.hidden = !draft.region;
    var rv = $('#setRegionValue');
    if (rv) rv.textContent = draft.region || '';
    var cv = $('#setCityValue');
    if (cv) cv.textContent = draft.city;
  }

  function syncFormatRows() {
    var set = function (id, v) { var el = $(id); if (el) el.textContent = v; };
    set('#setLangValue', L.languageName(draft.lang) || draft.lang);
    set('#setUnitsValue', draft.units === 'auto' ? t('pers.unitsAuto')
      : draft.units === 'imperial' ? t('pers.unitsImperial') : t('pers.unitsMetric'));
    set('#setCurrencyValue', draft.currency === 'auto'
      ? t('pers.currencyAuto', { code: (GEO.get(draft.country) || {}).currency || '' })
      : draft.currency);
    set('#setClockValue', draft.clock === 'auto' ? t('pers.unitsAuto')
      : draft.clock === '12' ? t('pers.time12') : t('pers.time24'));
  }

  var locPicker = null;

  function hydratePersonalise() {
    draft = {
      country: profile.country, region: profile.region, city: profile.city,
      islamic: profile.islamic, lang: profile.lang, units: profile.units,
      currency: profile.currency, clock: profile.clock
    };
    setPicker.set(profile.interests.slice(), profile.islamic);
    if (!locPicker) {
      locPicker = makeLocationPicker($('#setLocation'), function () { return draft; }, {
        onChange: function () { syncLocationRows(); setPicker.refresh(); }
      });
    } else {
      locPicker.reset('country');
    }
    syncLocationRows();
    syncFormatRows();
    syncIslamicRow();
    for (var k in profile.prefs) {
      var row = $('[data-pref="' + k + '"]');
      if (row) { var sw = $('.switch', row); if (sw) sw.classList.toggle('is-on', !!profile.prefs[k]); }
    }
  }

  /* Cycle-through rows: small option sets do not deserve a whole sheet. */
  function cycle(list, current) {
    var at = list.indexOf(current);
    return list[(at + 1) % list.length];
  }

  document.addEventListener('click', function (e) {
    if (e.target.closest('#setLangRow')) {
      var codes = I18N.LANGS.map(function (x) { return x.code; });
      draft.lang = cycle(codes, draft.lang);
      /* Preview the language immediately — it is the one setting you cannot
         judge without seeing it. */
      var keep = profile.lang;
      profile.lang = draft.lang;
      applyLanguage();
      applyStrings();
      syncFormatRows();
      syncLocationRows();
      if (locPicker) locPicker.render();
      profile.lang = draft.lang;
      return;
    }
    if (e.target.closest('#setUnitsRow')) {
      draft.units = cycle(['auto', 'metric', 'imperial'], draft.units);
      syncFormatRows(); return;
    }
    if (e.target.closest('#setCurrencyRow')) {
      var cur = (GEO.get(draft.country) || {}).currency;
      draft.currency = cycle(['auto', 'USD', 'EUR', 'GBP', cur].filter(function (v, i, a) {
        return v && a.indexOf(v) === i;
      }), draft.currency);
      syncFormatRows(); return;
    }
    if (e.target.closest('#setClockRow')) {
      draft.clock = cycle(['auto', '12', '24'], draft.clock);
      syncFormatRows(); return;
    }
    if (e.target.closest('#setIslamicRow')) {
      draft.islamic = !draft.islamic;
      syncIslamicRow();
      var list = setPicker.get().filter(function (id) { return C.FAITH_INTERESTS.indexOf(id) === -1; });
      if (draft.islamic) list = list.concat(['prayer', 'quran', 'duas']).slice(0, PICK_MAX);
      setPicker.set(list, draft.islamic);
    }
  });

  var setSave = $('#setPickSave');
  if (setSave) {
    setSave.addEventListener('click', function () {
      profile.interests = setPicker.get();
      if (profile.country !== draft.country) {
        profile.recentCountries = [profile.country].concat(
          (profile.recentCountries || []).filter(function (c) { return c !== profile.country; })
        ).slice(0, 4);
      }
      /* Only visibility and formatting change here. Notes, tasks, expenses and
         every other record are untouched by design. */
      profile.country = draft.country;
      profile.region = draft.region;
      profile.city = draft.city;
      profile.islamic = draft.islamic;
      profile.lang = draft.lang;
      profile.units = draft.units;
      profile.currency = draft.currency;
      profile.clock = draft.clock;
      prayerCache = null;
      syncFaithFromInterests();
      /* Anything now hidden must not linger in history. */
      profile.recents = profile.recents.filter(function (id) {
        var f = feature(id); return f && visible(f);
      });
      saveProfile();
      renderAll();
      sheetClose();
      toast(t('pers.saved'));
    });
  }

  /* ---------------------------------------------------------
     Profile summaries
     --------------------------------------------------------- */
  function interestLabel(id) {
    for (var g = 0; g < C.INTEREST_GROUPS.length; g++) {
      var items = C.INTEREST_GROUPS[g].items;
      for (var i = 0; i < items.length; i++) if (items[i].id === id) return items[i].label;
    }
    return id;
  }

  function ensureExploreBack() {
    if ($('#exploreBack')) return;
    var bar = $('#screen-explore .page-head__bar');
    if (!bar) return;
    var b = document.createElement('button');
    b.className = 'iconbtn pressable';
    b.id = 'exploreBack';
    b.setAttribute('aria-label', 'Back to home');
    b.innerHTML = '<svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-l"/></svg>';
    b.addEventListener('click', function () { goTo('home'); });
    b.hidden = true;
    bar.insertBefore(b, bar.firstChild);
  }

  /* ---------------------------------------------------------
     Render everything from the profile
     --------------------------------------------------------- */
  function renderAll() {
    /* Language first: everything below renders through t(). */
    applyLanguage();
    applyStrings();
    applyVisibility();
    /* Metadata first: the screens below render cards that quote it. */
    syncFeatureMeta();
    renderTabs();
    /* Every screen, not a list of screens somebody has to remember to add
       to. A screen that is registered is a screen that gets rendered. */
    LIFECYCLE.ids().forEach(function (id) { LIFECYCLE.render(id); });
    renderNotifBadge();
    renderProfile();
    /* Rendered content lands inside gated containers, so the gate is applied
       again once everything exists. Otherwise a freshly injected row inside a
       hidden section would still be addressable (§64). */
    applyVisibility();
    /* A settings or authentication screen is as much a part of the render as
       Home is: a language change has to reach the picker that made it. */
    if (ROUTER.current() === 'account') renderAccount();
    else if (ROUTER.current() === 'auth') renderAuth();
  }

  /* ---------------------------------------------------------
     Onboarding
     --------------------------------------------------------- */
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
      onbCountryPicker = makeLocationPicker($('#onbCountry'), function () { return onbDraft; }, {
        stage: 'country',
        onChange: function () { mountOnbCity(); }
      });
    } else { onbCountryPicker.render(); }
  }

  function mountOnbCity() {
    var host = $('#onbCity');
    if (!host) return;
    if (!onbCityPicker) {
      onbCityPicker = makeLocationPicker(host, function () { return onbDraft; }, { stage: 'city' });
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
      if (nameInput) nameInput.value = ACCT.displayName() || '';
    }
    if (i === 6) {
      var loc = $('#onbLocSub');
      if (loc) loc.textContent = profile.islamic
        ? 'For prayer times, Qibla, weather and nearby places'
        : 'For weather, local services and nearby places';
      var nt = $('#onbNotifSub');
      if (nt) nt.textContent = profile.islamic
        ? 'A quiet nudge 5 minutes before each adhan'
        : 'A quiet nudge for the things you asked us to watch';
      applyVisibility();
    }
    if (i === onbSteps.length - 1) {
      /* §124.5 / §125 — two designed branches, and the neutral one is not
         the lesser of them. */
      var who = ACCT.displayName();
      var title = $('#onbDoneTitle');
      if (title) title.textContent = who ? t('onb.readyNamed', { name: who }) : t('onb.readyTitle');
      var el = $('#onbDoneText');
      if (el) {
        el.innerHTML = profile.islamic
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
    if (ACCT.isAuthed()) ACCT.updateUser({ displayName: name });
    else profile.displayName = name;
    saveProfile();
    /* A name shows up in three places at once: the greeting, the avatar and
       the profile screen. Rendering the screen that carries the first two is
       how they stay in step, rather than two separate pokes at their nodes. */
    LIFECYCLE.render('home');
    renderProfile();
  }

  function onbCommit(list, faith) {
    profile.interests = list;
    profile.islamic = !!faith;
    profile.country = onbDraft.country;
    profile.region = onbDraft.region;
    profile.city = onbDraft.city;
    prayerCache = null;
    syncFaithFromInterests();
    saveProfile();
    renderAll();
  }

  var onbPicker = makePicker($('#onbPicker'), $('#onbPickCount'), $('#onbPickClear'), function (enough) {
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
    onbDraft = { country: profile.country, region: profile.region, city: profile.city };
    if (onbPicker) onbPicker.set(profile.interests.slice(), profile.islamic);
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
          profile.country = onbDraft.country;
          profile.region = onbDraft.region;
          profile.city = onbDraft.city;
          prayerCache = null;
        }
        onbShow(onbStep + 1);
      });
    });
    onbBack.addEventListener('click', function () { onbShow(onbStep - 1, true); });
    onbSkip.addEventListener('click', function () {
      if (!profile.interests.length) {
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
        if (String(typed).trim() !== String(ACCT.displayName() || '')) commitName(typed);
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
      if (!profile.interests.length) onbCommit(C.DEFAULT_INTERESTS.slice(), false);
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

  /* ---------------------------------------------------------
     Share cards
     Shareable content leaves the app as a picture, not as plain
     text. Drawn on a canvas so the export is a real PNG and so
     Arabic and Urdu shape and align correctly.
     --------------------------------------------------------- */
  var SHARE_CONTENT = {
    names99: {
      kind: 'dua',
      arabic: 'الرَّحْمَٰن',
      text: 'Ar-Rahman — The Most Compassionate.',
      source: 'Asma ul Husna'
    },
    hadith: {
      kind: 'hadith',
      text: 'The best of people are those who are most beneficial to people.',
      source: 'Al-Mu‘jam al-Awsat 5787'
    },
    ayah: {
      kind: 'quran',
      arabic: 'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
      text: 'Truly, it is in the remembrance of God that hearts find rest.',
      source: 'Ar-Ra’d 13:28'
    },
    duas: {
      kind: 'dua',
      arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
      text: 'Our Lord, give us good in this world.',
      source: 'Al-Baqarah 2:201'
    },
    quote: {
      kind: 'quote',
      text: 'Small things done consistently beat big things done occasionally.',
      source: 'On building habits'
    },
    reminder: {
      kind: 'reminder',
      text: 'A quiet minute now is worth an hour later.',
      source: 'Lume'
    }
  };

  var THEMES = {
    quran:    ['#1B2A5E', '#3E4E9E', '#FFE9B8'],
    hadith:   ['#1D4E4A', '#2F7F6E', '#8FE6D2'],
    dua:      ['#4A3F9E', '#6E62E5', '#D9D3FF'],
    quote:    ['#0E8C7E', '#25B7A2', '#DFF5EF'],
    reminder: ['#3A3A44', '#5C5C6B', '#E6E6EA']
  };

  var shareData = null;

  function wrapText(ctx, text, maxWidth) {
    var words = String(text).split(/\s+/);
    var lines = [], line = '';
    for (var i = 0; i < words.length; i++) {
      var test = line ? line + ' ' + words[i] : words[i];
      if (ctx.measureText(test).width > maxWidth && line) {
        lines.push(line);
        line = words[i];
      } else { line = test; }
    }
    if (line) lines.push(line);
    return lines;
  }

  function drawShareCard(data) {
    var canvas = $('#shareCanvas');
    if (!canvas) return;
    var ctx = canvas.getContext('2d');
    var W = canvas.width, H = canvas.height;
    var theme = THEMES[data.kind] || THEMES.quote;
    var rtl = L.dir() === 'rtl';

    ctx.clearRect(0, 0, W, H);

    var grad = ctx.createLinearGradient(0, 0, W, H);
    grad.addColorStop(0, theme[0]);
    grad.addColorStop(1, theme[1]);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, W, H);

    /* Decorative shapes, same language as the rest of the app. */
    ctx.save();
    ctx.globalAlpha = 0.10;
    ctx.fillStyle = '#fff';
    ctx.beginPath(); ctx.arc(W - 90, 150, 300, 0, Math.PI * 2); ctx.fill();
    ctx.globalAlpha = 0.08;
    ctx.beginPath(); ctx.arc(120, H - 120, 220, 0, Math.PI * 2); ctx.fill();
    ctx.restore();

    function sparkle(x, y, r, alpha) {
      ctx.save();
      ctx.globalAlpha = alpha;
      ctx.fillStyle = theme[2];
      ctx.beginPath();
      ctx.moveTo(x, y - r);
      ctx.quadraticCurveTo(x, y, x + r, y);
      ctx.quadraticCurveTo(x, y, x, y + r);
      ctx.quadraticCurveTo(x, y, x - r, y);
      ctx.quadraticCurveTo(x, y, x, y - r);
      ctx.fill();
      ctx.restore();
    }
    sparkle(150, 190, 34, 0.75);
    sparkle(W - 190, H - 300, 22, 0.5);
    sparkle(W - 130, 470, 14, 0.35);

    var pad = 110;
    var maxW = W - pad * 2;

    /* Measure first so the block sits optically centred rather than
       hugging the top of the card. */
    var aLines = [];
    if (data.arabic) {
      ctx.font = '600 62px "Noto Naskh Arabic", serif';
      aLines = wrapText(ctx, data.arabic, maxW);
    }
    ctx.font = '700 54px "Plus Jakarta Sans", system-ui, sans-serif';
    var tLines = wrapText(ctx, data.text, maxW);
    var blockH = aLines.length * 96 + (aLines.length ? 40 : 0) + tLines.length * 74 + 58;
    var y = Math.max(300, Math.round((H - 190 - blockH) / 2) + 60);

    /* Arabic first, when the content has it. */
    if (data.arabic) {
      ctx.direction = 'rtl';
      ctx.textAlign = 'right';
      ctx.fillStyle = theme[2];
      ctx.font = '600 62px "Noto Naskh Arabic", serif';
      aLines.forEach(function (ln) {
        ctx.fillText(ln, W - pad, y);
        y += 96;
      });
      y += 40;
    }

    ctx.direction = rtl ? 'rtl' : 'ltr';
    ctx.textAlign = rtl ? 'right' : 'left';
    var anchorX = rtl ? W - pad : pad;

    ctx.fillStyle = '#ffffff';
    ctx.font = '700 54px "Plus Jakarta Sans", system-ui, sans-serif';
    tLines.forEach(function (ln) {
      ctx.fillText(ln, anchorX, y);
      y += 74;
    });

    y += 24;
    ctx.globalAlpha = 0.75;
    ctx.font = '500 34px "Plus Jakarta Sans", system-ui, sans-serif';
    ctx.fillText(data.source, anchorX, y);
    ctx.globalAlpha = 1;

    /* Footer: the same wordmark the app uses. */
    var fy = H - 110;
    ctx.globalAlpha = 0.28;
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(pad, fy - 70); ctx.lineTo(W - pad, fy - 70); ctx.stroke();
    ctx.globalAlpha = 1;

    var markX = rtl ? W - pad - 26 : pad + 26;
    ctx.save();
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 4;
    ctx.beginPath(); ctx.arc(markX, fy - 8, 26, 0, Math.PI * 2); ctx.stroke();
    ctx.beginPath(); ctx.arc(markX, fy - 8, 26, -Math.PI / 2, Math.PI / 2); ctx.fillStyle = '#fff'; ctx.fill();
    ctx.restore();

    ctx.textAlign = rtl ? 'right' : 'left';
    ctx.fillStyle = '#fff';
    ctx.font = '800 40px "Plus Jakarta Sans", system-ui, sans-serif';
    ctx.fillText('Lume', rtl ? markX - 46 : markX + 46, fy);
    ctx.globalAlpha = 0.7;
    ctx.font = '500 26px "Plus Jakarta Sans", system-ui, sans-serif';
    ctx.fillText(t('app.tagline'), rtl ? markX - 46 : markX + 46, fy + 38);
    ctx.globalAlpha = 1;
  }

  function openShare(id) {
    shareData = shareForTool(id) || SHARE_CONTENT[id] || SHARE_CONTENT.quote;
    sheetOpen('share');
    /* Wait for the webfonts, or the first draw falls back to a system face. */
    var draw = function () { drawShareCard(shareData); };
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(draw);
    else draw();
    draw();
  }

  function canvasBlob(cb) {
    var canvas = $('#shareCanvas');
    if (!canvas) return;
    if (canvas.toBlob) canvas.toBlob(cb, 'image/png');
    else cb(null);
  }

  var saveBtn = $('#shareSave');
  if (saveBtn) {
    saveBtn.addEventListener('click', function () {
      canvasBlob(function (blob) {
        if (!blob) { toast(t('share.saved')); return; }
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = 'lume-' + (shareData ? shareData.kind : 'card') + '.png';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
        toast(t('share.saved'));
      });
    });
  }

  var sendBtn = $('#shareSend');
  if (sendBtn) {
    sendBtn.addEventListener('click', function () {
      canvasBlob(function (blob) {
        /* The image is the primary artifact, with text only as a caption. */
        if (blob && navigator.canShare && window.File) {
          var file = new File([blob], 'lume.png', { type: 'image/png' });
          if (navigator.canShare({ files: [file] })) {
            navigator.share({ files: [file], text: shareData.text + ' — ' + shareData.source })
              .then(function () { toast(t('share.shared')); })
              .catch(function () {});
            return;
          }
        }
        if (navigator.share) {
          navigator.share({ text: shareData.text + ' — ' + shareData.source })
            .then(function () { toast(t('share.shared')); })
            .catch(function () {});
          return;
        }
        toast(t('share.shared'));
      });
    });
  }

  document.addEventListener('click', function (e) {
    var el = e.target.closest('[data-share]');
    if (el) openShare(el.dataset.share);
  });

  /* ---------------------------------------------------------
     Skeletons on first paint
     --------------------------------------------------------- */
  (function skeletons() {
    var targets = $$('#screen-home .progress-card__body > p, #screen-home .stat-row__body > p');
    targets.forEach(function (el) { el.classList.add('skeleton'); });
    setTimeout(function () {
      targets.forEach(function (el) { el.classList.remove('skeleton'); });
    }, 850);
  })();

  /* A clipped shell can still be scrolled programmatically — by focus moving to
     an off-screen node, or scrollIntoView. Pin it so the layout never drifts. */
  var appEl = $('#app');
  if (appEl) {
    appEl.addEventListener('scroll', function () {
      if (appEl.scrollTop || appEl.scrollLeft) { appEl.scrollTop = 0; appEl.scrollLeft = 0; }
    });
  }


  /* ---------------------------------------------------------
     Tool screens  (Master Spec §7, §8, §64, §109)

     One host, one router, one back stack. Opening a tool is
     gated by the same visible() every other surface uses, so a
     hidden feature cannot be reached through a deep link, a
     related-tool card or a search result either.
     --------------------------------------------------------- */
  var toolCtx = LUME_CTX({
    L: L, t: t,
    profile: function () { return profile; },
    store: store,
    featureFor: feature,
    fname: fname,
    isVisible: visible
  });
  TOOLS.init(toolCtx);

  /* The tool host owns opening, rendering, the back stack and cleanup.
     What the shell keeps is the ways in: a request to open or close a
     tool, the action vocabulary tool screens speak, and the share snapshot
     a tool can produce. */
  /* ---- Back, wherever the user is ----------------------------------
     One handler, because "back" means something different on each of the
     four nested destinations and only one of them can be showing. */
  document.addEventListener('click', function (e) {
    if (!e.target.closest('[data-tool-back]')) return;
    if (ROUTER.current() === 'notifications') { goTo(notifReturnTab); return; }
    if (ROUTER.current() === 'account') { closeAccount(); return; }
    if (ROUTER.current() === 'auth') { closeAuth(); return; }
    closeTool();
  });

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape' || openSheet) return;
    if (ROUTER.current() === 'account') { closeAccount(); return; }
    if (ROUTER.current() === 'auth') { closeAuth(); return; }
    if (toolIsOpen()) closeTool();
  });

  var TOOL_HOST = LIFECYCLE.get('tool');
  function openTool(id, opts) { TOOL_HOST.open(id, opts); }
  function closeTool() { TOOL_HOST.close(); }
  function toolAction(kind, arg) { return TOOL_HOST.action(kind, arg); }
  function shareForTool(id) { return TOOL_HOST.shareFor(id); }
  function toolIsOpen() { return TOOL_HOST.isOpen(); }

  /* ---------------------------------------------------------
     Notification centre  (Master Spec §100)

     The engine decides what is true; this decides how it looks.
     Tools never build a notification themselves — they declare
     an event and the engine turns it into one.
     --------------------------------------------------------- */
  var NOTIFY = LUME_NOTIFY({
    t: t, L: L, store: store,
    profile: function () { return profile; },
    ctx: function (id) { return toolCtx(id); },
    featureFor: feature, isVisible: visible,
    save: saveProfile,
    open: function (link) { runAct(link); }
  });

  var notifReturnTab = 'home';
  var bannerTimer = null;

  /* §100.12 — an event reaches the user through exactly one surface. Push
     when they are away, a banner when they are here and it is worth
     interrupting for, the centre otherwise. Never two for one event. */
  function showBanner(n) {
    var host = $('#notifBanner');
    if (!host) return;
    host.innerHTML =
      '<button class="nbanner__main pressable" data-notif-open="' + esc(n.id) + '">' +
        '<span class="nbanner__icon nrow__icon--' + esc(n.category) + '">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + esc(n.icon) + '"/></svg></span>' +
        '<span class="nbanner__body">' +
          '<span class="nbanner__title">' + esc(n.title) + '</span>' +
          '<span class="nbanner__text">' + esc(n.body) + '</span>' +
        '</span>' +
      '</button>' +
      '<button class="nbanner__close pressable" data-banner-close aria-label="' + esc(t('n.dismiss')) + '">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#i-x"/></svg></button>';
    host.hidden = false;
    requestAnimationFrame(function () { host.classList.add('is-open'); });
    if (NOTIFY.prefs().haptics && navigator.vibrate) navigator.vibrate(12);
    clearTimeout(bannerTimer);
    bannerTimer = setTimeout(hideBanner, 6000);
  }

  function hideBanner() {
    var host = $('#notifBanner');
    if (!host) return;
    host.classList.remove('is-open');
    clearTimeout(bannerTimer);
    setTimeout(function () { if (!host.classList.contains('is-open')) host.hidden = true; }, 260);
  }

  document.addEventListener('click', function (e) {
    if (e.target.closest('[data-banner-close]')) hideBanner();
  });

  /* The tick that presents. Away means the tab is hidden — the same event
     then goes out as a push instead of a banner. */
  function notifyTick() {
    if (!NOTIFY.prefs().inApp && !NOTIFY.pushEnabled()) { renderNotifBadge(); return; }
    var away = typeof document.hidden === 'boolean' ? document.hidden : false;
    var result = NOTIFY.present(away);
    if (result && result.surface === 'banner' && ROUTER.current() !== 'notifications') {
      showBanner(result.notification);
    }
    renderNotifBadge();
  }

  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) { renderNotifBadge(); }
  });

  /* §100.1 — one badge, in the app header, formatted compactly. */
  function renderNotifBadge() {
    var n = NOTIFY.unreadCount();
    $$('.iconbtn__badge').forEach(function (b) {
      var host = b.parentNode;
      if (!host || !host.matches('[data-act="tab:notifications"]')) return;
      b.hidden = !n || !NOTIFY.prefs().badge;
      b.textContent = n > 99 ? '99+' : String(n);
    });
  }

  /* The centre's own rendering lives on its screen. What is left here is
     the engine and the two surfaces that are not the centre: the badge in
     Home's app bar and the banner that can appear over anything. */
  var NOTIF_CENTRE = LIFECYCLE.get('notifications');
  function renderNotifCentre() { LIFECYCLE.render('notifications'); }

  function renderNotifPrefs(host) {
    if (!host) {
      [$('#notifPrefsBody'), $('#acctNotifPrefs')].forEach(function (h) {
        if (h) renderNotifPrefs(h);
      });
      return;
    }
    var p = NOTIFY.prefs();

    function toggle(key, label, sub, on) {
      return '<button class="list-row pressable" data-npref="' + esc(key) + '">' +
        '<span class="list-row__body">' +
          '<span class="list-row__title">' + esc(label) + '</span>' +
          (sub ? '<span class="list-row__sub">' + esc(sub) + '</span>' : '') +
        '</span>' +
        '<span class="list-row__end"><span class="switch' + (on ? ' is-on' : '') +
          '"><i class="switch__knob"></i></span></span></button>';
    }

    var pushState = NOTIFY.pushPermission();
    var pushSub = pushState === 'granted' ? t('n.push.granted')
      : pushState === 'denied' ? t('n.push.denied')
      : pushState === 'unsupported' ? t('n.push.unsupported')
      : t('n.push.ask');

    /* Only the tools the user can actually see (§64). */
    var byTool = {};
    NOTIFY.SOURCES.forEach(function (src) {
      var f = feature(src.tool);
      if (!f || !visible(f)) return;
      (byTool[src.tool] = byTool[src.tool] || []).push(src);
    });

    host.innerHTML =
      UI.sectionHead({ title: t('n.pref.general') }) +
      '<div class="list">' +
        toggle('push', t('n.pref.push'), pushSub, p.push && pushState === 'granted') +
        toggle('inApp', t('n.pref.inApp'), t('n.pref.inAppSub'), p.inApp) +
        toggle('sound', t('n.pref.sound'), null, p.sound) +
        toggle('haptics', t('n.pref.haptics'), null, p.haptics) +
        toggle('badge', t('n.pref.badge'), t('n.pref.badgeSub'), p.badge) +
      '</div>' +

      UI.sectionHead({ title: t('n.pref.categories'), sub: t('n.pref.categoriesSub') }) +
      '<div class="list">' + NOTIFY.CATEGORIES.filter(function (c) {
        if (c.faith && !profile.islamic) return false;
        return NOTIFY.SOURCES.some(function (src) {
          var f = feature(src.tool);
          return src.cat === c.id && f && visible(f);
        });
      }).map(function (c) {
        return toggle('cat:' + c.id, t(c.key), null, p.cats[c.id] !== false);
      }).join('') + '</div>' +

      UI.sectionHead({ title: t('n.pref.perTool'), sub: t('n.pref.perToolSub') }) +
      Object.keys(byTool).map(function (tool) {
        var f = feature(tool);
        return '<p class="npref__tool">' + esc(fname(f)) + '</p><div class="list">' +
          byTool[tool].map(function (src) {
            return toggle('type:' + src.id, t('ntype.' + src.type), null, p.types[src.id] !== false);
          }).join('') + '</div>';
      }).join('') +

      UI.sectionHead({ title: t('n.pref.quiet'), sub: t('n.pref.quietSub') }) +
      '<div class="list">' +
        toggle('quiet', t('n.pref.quietOn'),
          L.time(p.quietFrom, 0) + ' – ' + L.time(p.quietTo, 0), p.quiet) +
        '<div class="list-row" style="cursor:default">' +
          '<span class="list-row__body"><span class="list-row__title">' + esc(t('n.pref.from')) + '</span></span>' +
          '<span class="list-row__end">' +
            UI.stepper({ name: 'quietFrom', value: L.time(p.quietFrom, 0), label: t('n.pref.from'),
              less: t('n.pref.earlier'), more: t('n.pref.later') }) + '</span>' +
        '</div>' +
        '<div class="list-row" style="cursor:default">' +
          '<span class="list-row__body"><span class="list-row__title">' + esc(t('n.pref.to')) + '</span></span>' +
          '<span class="list-row__end">' +
            UI.stepper({ name: 'quietTo', value: L.time(p.quietTo, 0), label: t('n.pref.to'),
              less: t('n.pref.earlier'), more: t('n.pref.later') }) + '</span>' +
        '</div>' +
      '</div>' +

      UI.sectionHead({ title: t('n.pref.privacy'), sub: t('n.pref.privacySub') }) +
      '<div class="list">' +
        toggle('preview', t('n.pref.preview'), t('n.pref.previewSub'), p.preview) +
        toggle('sensitivePreview', t('n.pref.sensitive'), t('n.pref.sensitiveSub'), p.sensitivePreview) +
      '</div>' +

      '<div class="btnrow" style="margin-top:20px">' +
        UI.button({ label: t('n.pref.restore'), icon: 'i-refresh', act: 'notifrestore' }) +
      '</div>';

    applyStrings(host);
  }

  document.addEventListener('click', function (e) {
    var row = e.target.closest('[data-npref]');
    if (!row) return;
    var key = row.dataset.npref;
    var p = NOTIFY.prefs();

    if (key === 'push') {
      if (NOTIFY.pushPermission() === 'default') { sheetOpen('notifpush'); return; }
      if (NOTIFY.pushPermission() === 'denied') { toast(t('n.push.deniedHelp')); return; }
      if (NOTIFY.pushPermission() === 'unsupported') { toast(t('n.push.unsupported')); return; }
      p.push = !p.push;
    } else if (key.indexOf('cat:') === 0) {
      var cid = key.slice(4);
      p.cats[cid] = p.cats[cid] === false;
    } else if (key.indexOf('type:') === 0) {
      var tid = key.slice(5);
      p.types[tid] = p.types[tid] === false;
    } else {
      p[key] = !p[key];
    }
    NOTIFY.prefsChanged();
    saveProfile();
    renderNotifPrefs();
    renderNotifBadge();
    if (ROUTER.current() === 'notifications') renderNotifCentre();
  });

  /* §100.11 — the education flow names what the user would actually get,
     drawn from the tools they can see, then asks the system. */
  function renderPushAsk() {
    var host = $('#pushAskList');
    if (!host) return;
    var seen = {}, items = [];
    NOTIFY.SOURCES.forEach(function (src) {
      var f = feature(src.tool);
      if (!f || !visible(f) || seen[src.cat]) return;
      seen[src.cat] = 1;
      items.push({ icon: NOTIFY.category(src.cat).icon, label: t(NOTIFY.category(src.cat).key) });
    });
    host.innerHTML = items.slice(0, 6).map(function (i) {
      return '<li class="pushask__item">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#' + i.icon + '"/></svg>' +
        esc(i.label) + '</li>';
    }).join('');
  }


  /* §100.4 — a notification knows where it goes, and reading it marks it. */
  document.addEventListener('click', function (e) {
    var open = e.target.closest('[data-notif-open]');
    if (open) {
      var id = open.dataset.notifOpen;
      /* Resolve against what is on screen: under a filter, a group holds
         different members than it would in the unfiltered list. */
      var rows = NOTIFY.list(ROUTER.current() === 'notifications' ? NOTIF_CENTRE.filter() : 'all');
      var view = NOTIFY.grouped(rows);
      var n = view.filter(function (x) { return x.id === id; })[0];
      NOTIFY.markRead(id, rows);
      hideBanner();
      if (n && n.grouped) { renderNotifCentre(); return; }
      if (n && n.deepLink) { runAct(n.deepLink); renderNotifBadge(); return; }
      renderNotifCentre();
      return;
    }
    var act = e.target.closest('[data-notif-act]');
    if (act) {
      var aid = act.dataset.notifAct;
      var rows2 = NOTIFY.list('all');
      var an = rows2.filter(function (x) { return x.id === aid; })[0];
      /* §100.21 — acting on a notification is a state of its own. */
      NOTIFY.markActioned(aid, rows2);
      if (an && an.action) runAct(an.action.act);
      renderNotifBadge();
      return;
    }
    var gone = e.target.closest('[data-notif-dismiss]');
    if (gone) {
      NOTIFY.dismiss(gone.dataset.notifDismiss, NOTIFY.list(NOTIF_CENTRE.filter()));
      renderNotifCentre();
    }
  });


  /* ---------------------------------------------------------
     Account, profile and settings  (Master Spec §124)

     Two hosts, two back stacks, one vocabulary. Authentication
     is a flow rather than a tool, so it never enters the tool
     router, the catalogue or search.
     --------------------------------------------------------- */
  var AUI = LUME_ACCOUNT_UI({
    t: t, L: L, UI: UI, account: ACCT, notify: NOTIFY, geo: GEO,
    profile: function () { return profile; },
    version: APP_VERSION,
    langs: function () { return I18N.LANGS; },
    storedTheme: function () { return store.get('lume-theme'); },
    fname: fname,
    favourites: function () {
      return (profile.favourites || []).map(feature).filter(function (f) { return f && visible(f); });
    },
    recents: function () {
      return (profile.recents || []).map(feature).filter(function (f) { return f && visible(f); });
    },
    renderNotifPrefs: renderNotifPrefs
  });
  /* The surfaces, reachable the way the engine already is — the layout
     contract in §126 is asserted against them rather than described. */
  accountUI = AUI;


  function showScreen(name) { ROUTER.go(name, { quiet: true }); }

  function homeTab() { return ROUTER.currentTab('profile'); }

  /* Profile, Account and Authentication each own a screen; the forms they
     share own a service. What is left here is the wiring between them,
     because none of the four may reach for another directly. */
  var PROFILE_SCREEN = LIFECYCLE.get('profile');
  var ACCOUNT_SCREEN = LIFECYCLE.get('account');
  var AUTH_SCREEN = LIFECYCLE.get('auth');

  function renderProfile() { LIFECYCLE.render('profile'); }
  function showScreen(name) { ROUTER.go(name, { quiet: true }); }
  function homeTab() { return ROUTER.currentTab('profile'); }

  function openAccount(route, opts) { ACCOUNT_SCREEN.open(route, opts); }
  function closeAccount() { ACCOUNT_SCREEN.close(); }
  function renderAccount() { LIFECYCLE.render('account'); }
  function guardDirty(go) { return ACCOUNT_SCREEN.guardDirty(go); }

  function openAuth(route, opts) { AUTH_SCREEN.open(route, opts); }
  function closeAuth(dismiss) { AUTH_SCREEN.close(dismiss); }
  function renderAuth() { LIFECYCLE.render('auth'); }
  function resetNotificationsForAccount() { AUTH_SCREEN.resetNotifications(); }

  var FORMS = createAccountForms(SHELL);
  function accountAction(kind, arg) { return FORMS.action(kind, arg); }
  function cancelSubmit() { FORMS.cancelSubmit(); }

  /* ---------------------------------------------------------
     Hand the screens what they are allowed to know

     Everything above exists by now, which is what makes this the
     right place for it: the context was created before the screens
     were mounted, and a screen may only read it from render onward.
     --------------------------------------------------------- */
  SHELL.provide({
    t: t,
    L: L,
    applyStrings: applyStrings,

    catalogue: C,
    data: C_DATA,
    spec: SPEC,
    ui: UI,
    tools: TOOLS,
    toolCtx: toolCtx,
    store: store,

    profile: function () { return profile; },
    eligible: ELIGIBLE,
    hasInterest: hasInterest,
    saveProfile: saveProfile,
    noteRecent: noteRecent,

    router: ROUTER,
    openTool: openTool,
    sheetOpen: sheetOpen,
    sheetClose: sheetClose,
    toast: toast,
    runAct: runAct,
    animateBars: animateBars,

    /* Prayer arithmetic belongs to the faith system, not to whichever
       screen happens to be drawing a prayer time. */
    prayer: { state: prayerState, minutes: mins, times: prayerSet, KEYS: PKEYS },
    forgetPrayerTimes: function () { prayerCache = null; },
    notify: NOTIFY,
    account: ACCT,

    geo: GEO,
    i18n: I18N,
    accountUI: AUI,
    forms: FORMS,
    /* Handed as getters: the two screens and this service are all built
       before any of them runs, and each needs the others. */
    accountScreen: function () { return ACCOUNT_SCREEN; },
    authScreen: function () { return AUTH_SCREEN; },

    openAccount: openAccount,
    openAuth: openAuth,
    applyVisibility: applyVisibility,
    renderAll: renderAll,
    setThemeMode: setThemeMode,
    startTour: onbStart,

    refreshNotifBadge: renderNotifBadge,
    refreshNotifPrefs: function () { renderNotifPrefs(); },
    /* Where a tool goes when it closes and there is nothing left on its
       stack. The centre is a destination rather than a tab, so a tool it
       opened returns there instead of to whichever tab is nominally
       current. */
    returnTab: function () { return notifReturnTab || 'home'; }
  });

  /* ---------------------------------------------------------
     Boot
     --------------------------------------------------------- */
  ensureExploreBack();
  applyWidth();
  renderNotifBadge();
  tickClock();
  renderAll();

  setInterval(tickClock, 15000);
  setInterval(notifyTick, 45000);
  setTimeout(notifyTick, 2500);

  /* §124.6 — a returning user with a dead session is told so, and taken
     back where they were going once they sign in. */
  if (ACCT.isExpired() && store.get('lume-onboarded')) openAuth('expired');

  requestAnimationFrame(function () {
    movePill($('.tab.is-active'));
    animateBars($('#screen-home'));
  });
})();
