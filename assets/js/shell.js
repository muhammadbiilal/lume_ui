/* ============================================================
   Lume — the shell

   What is left when every screen, every tool and every service
   owns itself: the composition root.

   It builds the profile store, the eligibility selector, the
   router and the lifecycle; mounts the ten screens into the
   outlet; constructs the services and hands each of them the
   few things it needs; and provides the one context object a
   screen is allowed to read.

   Two responsibilities genuinely belong here rather than
   anywhere else.

   The action vocabulary. Every tappable thing in the product
   declares what it does as a string, and this is where that
   string is turned into an action — because an action can cross
   any boundary in the app, and no single screen or service can
   own that.

   The full re-render. Changing language, country or faith
   preference changes what almost every surface should show, so
   renderAll asks the lifecycle for every registered screen
   rather than keeping a list somebody has to remember to add
   to.
   ============================================================ */
import { LUME } from './data/catalogue.js';
import { LUME_GEO } from './data/geo.js';
import { LUME_SPEC } from './data/tool-specs.js';
import { LUME_TOOLS } from './tools/engine.js';
import { LUME_UI } from './ui/components.js';
import { LUME_DATA } from './data/tool-data.js';
import { LUME_SOLAR } from './data/solar.js';
import { LUME_I18N } from './i18n/core.js';
import { LUME_LOCALE } from './services/locale.js';
import { LUME_NOTIFY } from './services/notify-engine.js';
import { LUME_ACCOUNT } from './services/account.js';
import { LUME_ACCOUNT_UI } from './ui/account-ui.js';
import { LUME_CTX } from './tools/context.js';
import { store } from './core/storage.js';
import { $, $$, pad2, esc } from './core/dom.js';
import { createProfileStore } from './core/app-store.js';
import { createEligibility } from './core/eligibility.js';
import { createLifecycle } from './core/lifecycle.js';
import { createRouter } from './core/router.js';
import { createBreakpoint } from './core/breakpoint.js';
import { createRecords } from './core/records.js';
import { seedsFor } from './data/record-schemas.js';
import { createScreens } from './screens/index.js';
import { createShellContext } from './core/shell-context.js';
import { createAccountForms } from './services/account-forms.js';
import { createTheme } from './services/theme.js';
import { createSheets } from './ui/sheets.js';
import { createPrayer } from './services/prayer.js';
import { createShareCards } from './services/share-cards.js';
import { createSearch } from './services/search.js';
import { createPickers } from './ui/pickers.js';
import { createOnboarding } from './screens/onboarding.screen.js';
import { createNotifications } from './services/notifications.js';
import { sheetsTemplate } from './ui/sheets-markup.js';
import { onboardingTemplate } from './screens/onboarding.screen.js';

/* The two live instances the inspection surface in main.js publishes.
   They are filled in while the shell boots, below; main.js reads them
   after every import has evaluated, so they are never seen unset. */
export let account = null;
export let accountUI = null;
/* The record store and the width class, published for the same reason the
   two above are: the harness drives them, and nothing in the app reads
   this. */
export let records = null;
export let breakpoint = null;

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

  /* Appearance lives in services/theme.js. The shell keeps the root
     element, which several other things here also write to. */
  var root = document.documentElement;
  var THEME = createTheme({ onChange: function () { renderProfile(); } });
  var setThemeMode = THEME.setMode;

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
  var toastEl = $('#toast'), toastText = $('#toastText'), toastAct = $('#toastAct'), toastTimer;

  /* A toast confirms and gets out of the way. It may carry exactly one
     action — Undo, where reversal is safe — and it stays a little longer
     when it does, because an action nobody has time to reach is not one
     (CRUD guide §7, §10). */
  function toast(msg, action) {
    if (!toastEl) return;
    toastText.textContent = msg;
    if (toastAct) {
      if (action && action.act) {
        toastAct.textContent = action.label;
        toastAct.dataset.act = action.act;
        toastAct.hidden = false;
      } else {
        toastAct.hidden = true;
        delete toastAct.dataset.act;
      }
    }
    toastEl.classList.toggle('toast--action', !!(action && action.act));
    toastEl.classList.add('is-open');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      toastEl.classList.remove('is-open');
      /* The undo entry goes with the toast that offered it: an Undo the
         user can no longer see must not still be armed somewhere. */
      if (action && action.act === 'rec:undo') RECORDS.forgetUndo();
    }, action && action.act ? 6000 : 2100);
  }

  function hideToast() {
    if (!toastEl) return;
    toastEl.classList.remove('is-open');
    clearTimeout(toastTimer);
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
  /* One destination set, three presentations (Design System §6). Both bars
     are drawn from the same tabOrder(), carry the same data-tab and the
     same .tab class, so the router selects a destination once rather than
     keeping three navigations in step by hand. */
  function renderTabBar() {
    var order = tabOrder();

    var bar = $('#tabbar');
    if (bar) {
      var pill = '<span class="tabbar__pill" id="tabPill"></span>';
      bar.innerHTML = pill + order.map(function (id) {
        var m = TAB_META[id];
        return '<button class="tab" data-tab="' + id + '" role="tab" aria-selected="false">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + m.icon + '"/></svg>' +
          '<span class="tab__label">' + esc(t(m.key)) + '</span></button>';
      }).join('');
    }

    /* The rail and the sidebar are the same element at two widths: the
       stylesheet decides whether the label sits beside the icon or under
       it, so there is one piece of markup rather than two. */
    var side = $('#navside');
    if (side) {
      side.innerHTML = '<span class="navside__brand">Lume</span>' + order.map(function (id) {
        var m = TAB_META[id];
        return '<button class="navtab" data-tab="' + id + '" role="tab" aria-selected="false">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + m.icon + '"/></svg>' +
          '<span class="navtab__label">' + esc(t(m.key)) + '</span></button>';
      }).join('');
    }
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

  /* ---------------------------------------------------------
     Width

     Which of the three width classes is showing is answered
     once, by core/breakpoint.js, and stamped on <html>. Two
     things react to it here: the compositions that gain columns
     at desk width, and every screen — because a screen that
     rendered a phone list must re-render as a master-detail
     when a pane appears beneath it, and back again when it goes
     (Design System §6, CRUD guide §8).
     --------------------------------------------------------- */
  var BP = createBreakpoint({ shell: $('#app') });
  breakpoint = BP;

  /* ---------------------------------------------------------
     Records

     Everything the user creates — tasks, notes, expenses, doses,
     documents, measurements, items, events — lives in one store
     (CRUD guide §1). It is constructed here because it belongs
     to no single tool: Home reads a count from it, the tool host
     writes to it, and the notification engine will one day read
     due dates from it.

     Changing country, language or faith preference does not
     touch it. That is §37 of the product brief, and it is true
     here by construction rather than by care: nothing in the
     personalisation path writes to this key.
     --------------------------------------------------------- */
  var RECORDS = createRecords({ store: store, seeds: seedsFor });
  records = RECORDS;

  /* §116 — above a real desktop width the compositions inside the capped
     reading column gain columns. This is a refinement of `expanded`, not a
     fourth width class. */
  function applyWidth() {
    var el = $('#app');
    if (el) el.classList.toggle('app--wide', BP.is('expanded') && window.innerWidth >= 1180);
  }

  BP.subscribe(function () {
    applyWidth();
    /* Re-render rather than reflow: a compact list and an expanded
       master-detail are different compositions of the same data, not the
       same markup at two sizes. */
    LIFECYCLE.ids().forEach(function (id) { LIFECYCLE.render(id); });
    movePill();
  });

  window.addEventListener('resize', function () {
    BP.refresh();
    applyWidth();
    movePill();
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

  /* Sheets live in ui/sheets.js. What stays here is which sheet needs
     filling in before it opens, because that is product knowledge rather
     than sheet behaviour. */
  var SHEETS = createSheets({
    animateBars: function (el) { animateBars(el); },
    onOpen: function (name) {
      if (name === 'personalise' && PICKERS.hasPersonalise()) hydratePersonalise();
      if (name === 'market') TOOL_HOST.fillMarketPicker();
      if (name === 'notifprefs') renderNotifPrefs();
      if (name === 'notifpush') renderPushAsk();
      if (name === 'search') {
        resetSearch();
        setTimeout(function () { var i = $('#globalSearch'); if (i) i.focus(); }, 320);
      }
    }
  });
  var sheetOpen = SHEETS.open;
  var sheetClose = SHEETS.close;
  function openSheetName() { return SHEETS.current(); }

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
    if (el.dataset.act) {
      /* Tapping the toast's own action dismisses it: the confirmation has
         been answered and should not linger over the result. */
      if (el === toastAct) hideToast();
      runAct(el.dataset.act);
      return;
    }
    if (el.dataset.sheet) { sheetOpen(el.dataset.sheet); return; }
    if (el.dataset.toast) { toast(el.dataset.toast); }
  });

  /* Prayer arithmetic lives in services/prayer.js. It is a service rather
     than a screen's business because Home, Today, the tool host and the
     notification engine all ask it the same questions. */
  var PRAYER = createPrayer({
    profile: function () { return profile; },
    locale: function () { return L; },
    solar: SOLAR
  });
  var prayerSet = PRAYER.times;
  var prayerState = PRAYER.state;
  var mins = PRAYER.minutes;
  function hhmm(p) { return L.time(p.h, p.m); }

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

  /* Global search lives in services/search.js. It asks the same
     eligibility selector the catalogue does, so a hidden feature cannot be
     found by typing its name. */
  var SEARCH = createSearch({
    t: t, L: L, esc: esc,
    catalogue: C, spec: SPEC,
    profile: function () { return profile; },
    eligible: ELIGIBLE,
    router: ROUTER,
    openTool: function (id) { openTool(id); },
    sheetClose: function () { sheetClose(); },
    toast: toast
  });
  function resetSearch() { SEARCH.reset(); }

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

  /* The three pickers live in ui/pickers.js: interests, location and the
     Personalisation sheet that hosts both. */
  var PICKERS = createPickers({
    t: t, L: L, esc: esc,
    catalogue: C, geo: GEO, i18n: I18N,
    applyStrings: function (scope) { applyStrings(scope); },
    sheetClose: function () { sheetClose(); },
    profile: function () { return profile; },
    store: store,
    eligible: ELIGIBLE,
    save: saveProfile,
    syncFaith: syncFaithFromInterests,
    toast: toast,
    render: function () { renderAll(); },
    forgetPrayerTimes: PRAYER.forget
  });
  var makePicker = PICKERS.makeInterestPicker;
  var makeLocationPicker = PICKERS.makeLocationPicker;
  var hydratePersonalise = PICKERS.hydratePersonalise;

  /* ---------------------------------------------------------
     Profile summaries
     --------------------------------------------------------- */
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

  /* The first-run flow owns its own module. */
  var ONBOARDING = createOnboarding({
    t: t, L: L, esc: esc,
    catalogue: C,
    profile: function () { return profile; },
    store: store,
    account: ACCT,
    pickers: PICKERS,
    save: saveProfile,
    syncFaith: syncFaithFromInterests,
    forgetPrayerTimes: PRAYER.forget,
    toast: toast,
    applyStrings: function (scope) { applyStrings(scope); },
    sheetClose: function () { sheetClose(); },
    render: function () { renderAll(); },
    renderProfile: function () { renderProfile(); },
    renderHome: function () { LIFECYCLE.render('home'); },
    prayerState: function () { return prayerState(); },
    applyVisibility: function () { applyVisibility(); },
    openAuth: function (route, opts) { openAuth(route, opts); },
    sheetOpen: function (name) { sheetOpen(name); }
  });
  var onbStart = ONBOARDING.start;
  var commitName = ONBOARDING.commitName;

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
    records: RECORDS,
    breakpoint: BP,
    /* Late-bound on purpose: the context is built before the tool host, and
       the host is what knows how to redraw a tool. */
    rerender: function () { if (TOOL_HOST && TOOL_HOST.isOpen()) TOOL_HOST.rerender(); },
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
    if (e.key !== 'Escape' || openSheetName()) return;
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

  /* The notification engine and the two surfaces that are not the centre
     — the badge in Home's app bar and the banner that can appear over
     anything — live in services/notifications.js. The centre itself is a
     screen. */
  var NOTIFICATIONS = createNotifications({
    t: t, L: L, esc: esc, ui: UI, engine: LUME_NOTIFY,
    profile: function () { return profile; },
    store: store,
    eligible: ELIGIBLE,
    toolCtx: function (id) { return toolCtx(id); },
    save: saveProfile,
    router: ROUTER,
    run: function (link) { runAct(link); },
    sheetOpen: function (name) { sheetOpen(name); },
    sheetClose: function () { sheetClose(); },
    toast: toast,
    applyStrings: function (scope) { applyStrings(scope); },
    renderCentre: function () { renderNotifCentre(); },
    centreFilter: function () { return NOTIF_CENTRE.filter(); }
  });
  /* The centre is a destination rather than a tab, so it remembers where
     the user was and its back control returns them there. */
  var notifReturnTab = 'home';

  var NOTIF_CENTRE = LIFECYCLE.get('notifications');
  function renderNotifCentre() { LIFECYCLE.render('notifications'); }

  var NOTIFY = NOTIFICATIONS.engine;
  var renderNotifBadge = NOTIFICATIONS.renderBadge;
  var renderNotifPrefs = NOTIFICATIONS.renderPrefs;
  var renderPushAsk = NOTIFICATIONS.renderPushAsk;
  var notifyTick = NOTIFICATIONS.tick;

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
    breakpoint: BP,
    records: RECORDS,
    openTool: openTool,
    sheetOpen: sheetOpen,
    sheetClose: sheetClose,
    toast: toast,
    runAct: runAct,
    animateBars: animateBars,

    /* Prayer arithmetic belongs to the faith system, not to whichever
       screen happens to be drawing a prayer time. */
    prayer: { state: prayerState, minutes: mins, times: prayerSet, KEYS: PKEYS },
    forgetPrayerTimes: PRAYER.forget,
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
    movePill();
    animateBars($('#screen-home'));
  });
})();
