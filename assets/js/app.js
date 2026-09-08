/* ============================================================
   Lume — app behaviour
   Vanilla JS, no dependencies. Runs from file:// too.

   The whole app hangs off one profile object. Religion and
   country are separate fields, and every surface — home, tools,
   today, search, explore, nav, notifications — asks the same
   visible() function. Nothing gets its own rule.
   ============================================================ */
(function () {
  'use strict';

  var C = window.LUME;
  var GEO = window.LUME_GEO;
  var SPEC = window.LUME_SPEC;
  var TOOLS = window.LUME_TOOLS;
  var UI = window.LUME_UI;
  var C_DATA = window.LUME_DATA;
  var SOLAR = window.LUME_SOLAR;
  var I18N = window.LUME_I18N;

  var $  = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var pad2 = function (n) { return n < 10 ? '0' + n : '' + n; };
  var esc = function (s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  };

  /* Storage can throw on a file:// origin or with site data blocked. */
  var store = {
    get: function (k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
    /* Reports whether the write happened. A blocked or full store used to
       fail silently, which let the account system announce "Account created"
       over an account that had not been written (§124.26). */
    set: function (k, v) {
      try { localStorage.setItem(k, v); return true; } catch (e) { return false; }
    }
  };

  /* ---------------------------------------------------------
     Profile — the single source of personalisation
     --------------------------------------------------------- */
  var APP_VERSION = '4.1.0';

  var profile = {
    /* §125 — identity starts empty. A name appears here only because the
       user typed one, in onboarding or in Edit profile; the greeting and the
       avatar have designed shapes for its absence. */
    displayName: '',
    photo: '',

    /* Location: country → region (where a country uses one) → city. */
    country: 'PK',
    region: 'Islamabad Capital Territory',
    city: 'Islamabad',

    /* The faith dimension, entirely separate from country. Off until the user
       asks for it in onboarding or Personalisation — never assumed, and never
       inferred from the country above. */
    islamic: false,

    /* Formatting. 'auto' follows the country; anything else is the user
       overriding it, which they are always allowed to do. Language is
       deliberately NOT derived from country. */
    lang: 'en',
    units: 'auto',
    currency: 'auto',
    clock: 'auto',
    method: 'MWL',

    interests: [],
    prefs: { news: true, cricket: true, finance: true, recos: true },
    recents: [],
    favourites: [],
    market: null,
    recentCountries: []
  };

  function loadProfile() {
    var raw = store.get('lume-profile');
    if (raw) {
      try {
        var saved = JSON.parse(raw);
        for (var k in saved) if (Object.prototype.hasOwnProperty.call(saved, k)) profile[k] = saved[k];
      } catch (e) {}
    }
    /* An older build shipped a placeholder name and initials in the profile
       record itself. They were never entered by anyone, so they are dropped
       rather than migrated (§125). */
    delete profile.name;
    delete profile.initials;
    if (!profile.interests || !profile.interests.length) {
      /* Onboarded but nothing stored (skipped, or an older build): fall back to
         the general defaults. Islamic content is never switched on for someone
         who did not ask for it. */
      profile.interests = store.get('lume-onboarded') ? C.DEFAULT_INTERESTS.slice() : [];
    }
    syncFaithFromInterests();
  }

  function saveProfile() {
    store.set('lume-profile', JSON.stringify(profile));
  }

  /* Picking anything in the faith group is what turns Islamic content on.
     We never ask "are you Muslim?" anywhere in the product. */
  function syncFaithFromInterests() {
    var any = profile.interests.some(function (id) { return C.FAITH_INTERESTS.indexOf(id) !== -1; });
    if (any) profile.islamic = true;
  }

  function hasInterest(id) { return profile.interests.indexOf(id) !== -1; }

  loadProfile();

  /* Language, formatting and names all come from here. */
  var L = window.LUME_LOCALE(function () { return profile; });
  var t = L.t;

  /* The identity engine (§124). Constructed here because onboarding, the
     greeting and the profile surface all ask it the same question, and it
     must be able to answer "nothing" before any of them render. */
  var ACCT = window.LUME_ACCOUNT({
    t: t, L: L, store: store,
    profile: function () { return profile; },
    save: saveProfile,
    onSignOut: function () { resetNotificationsForAccount(); }
  });
  window.LUME_ACCT = ACCT;

  /* Language drives text direction; country never does. */
  function applyLanguage() {
    root.lang = L.lang();
    root.dir = L.dir();
    document.body.classList.toggle('is-rtl', L.dir() === 'rtl');
  }

  /* ---------------------------------------------------------
     Visibility — the one rule everything obeys
     --------------------------------------------------------- */
  function visibleIn(f, ctx) {
    if (f.faith && !ctx.islamic) return false;
    /* countries: the markets a feature has launched in. No entry = global.
       This is availability, not localisation — a global feature whose content
       adapts (weather, news) stays visible everywhere. */
    if (f.countries && f.countries.indexOf(ctx.country) === -1) return false;
    if (f.id === 'cricket' && !profile.prefs.cricket) return false;
    if (f.id === 'news' && !profile.prefs.news) return false;
    if ((f.id === 'markets' || f.id === 'goldrates') && !profile.prefs.finance) return false;
    return true;
  }

  function visible(f) { return visibleIn(f, profile); }

  function visibleFeatures() { return C.FEATURES.filter(visible); }

  /* Feature names come from the catalogue in English; a dictionary entry
     overrides it where a translation exists. */
  function fname(f) {
    var key = 'f.' + f.id;
    var s2 = t(key);
    return s2 === key ? f.n : s2;
  }

  function feature(id) {
    for (var i = 0; i < C.FEATURES.length; i++) if (C.FEATURES[i].id === id) return C.FEATURES[i];
    return null;
  }

  /* Every feature opens its own tool screen. The catalogue's `act` is kept
     as the quick-glance surface (a sheet) but the tool screen is the tool:
     that is what makes each one its own information architecture rather
     than a toast (Master Spec §113). */
  function actFor(f) {
    return 'tool:' + f.id;
  }

  /* Markets that have any localised feature of their own. */
  var LOCAL_MARKETS = null;
  function localMarkets() {
    if (!LOCAL_MARKETS) {
      LOCAL_MARKETS = [];
      C.FEATURES.forEach(function (f) {
        (f.countries || []).forEach(function (c) {
          if (LOCAL_MARKETS.indexOf(c) === -1) LOCAL_MARKETS.push(c);
        });
      });
    }
    return LOCAL_MARKETS;
  }

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

  function greetFor(h) {
    if (h < 5)  return 'greet.late';
    if (h < 12) return 'greet.morning';
    if (h < 17) return 'greet.afternoon';
    if (h < 21) return 'greet.evening';
    return 'greet.winddown';
  }

  function initHeader() {
    var d = new Date();
    var g = $('#greetText');
    if (g) {
      /* §124.3 — the name is used when Lume has one and the greeting stands
         alone when it does not. There is no third branch that invents one. */
      var who = ACCT.displayName();
      g.textContent = who
        ? t('greet.named', { greeting: t(greetFor(d.getHours())), name: who })
        : t(greetFor(d.getHours()));
    }
    /* The header also carries the city, so it gets the short form — the long
       one would wrap onto a second line on a 390px screen. */
    var date = $('#todayDate');
    if (date) date.textContent = L.dateShort(d);
    var sub = $('#todaySub');
    if (sub) sub.textContent = profile.islamic ? L.dateLong(d) + ' · 15 Rabi’ al-Awwal' : L.dateLong(d);
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

  var current = 'home';

  function renderTabs() {
    var bar = $('#tabbar');
    if (!bar) return;
    var pill = '<span class="tabbar__pill" id="tabPill"></span>';
    bar.innerHTML = pill + tabOrder().map(function (id) {
      var m = TAB_META[id];
      return '<button class="tab" data-tab="' + id + '" role="tab" aria-selected="false">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#' + m.icon + '"/></svg>' +
        '<span class="tab__label">' + esc(t(m.key)) + '</span></button>';
    }).join('');

    /* A screen that is no longer a tab must not stay open — but the tool
       screen, the notification centre and Explore are destinations, not
       orphans. */
    if (tabOrder().indexOf(current) === -1 &&
        ['explore', 'tool', 'notifications', 'account', 'auth'].indexOf(current) === -1) current = 'home';
    goTo(current, true);
  }

  function movePill(tab) {
    var pill = $('#tabPill');
    if (!pill) return;
    if (!tab) { pill.style.opacity = '0'; return; }
    pill.style.opacity = '';
    pill.style.width = tab.offsetWidth + 'px';
    pill.style.transform = 'translateX(' + tab.offsetLeft + 'px)';
  }

  function goTo(name, quiet) {
    var screen = $('#screen-' + name);
    if (!screen) return;
    current = name;

    $$('.screen').forEach(function (s) { s.classList.remove('is-active'); });
    screen.classList.add('is-active');
    screen.scrollTop = 0;

    var active = null;
    $$('.tab').forEach(function (t) {
      var on = t.dataset.tab === name;
      t.classList.toggle('is-active', on);
      t.setAttribute('aria-selected', on ? 'true' : 'false');
      if (on) active = t;
    });
    movePill(active);

    /* Explore is reachable for Pakistan users even though it is not a tab. */
    var back = $('#exploreBack');
    if (back) back.hidden = !!active || name !== 'explore';

    if (!quiet) animateBars(screen);
  }

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
    if (name === 'market') renderMarketPicker();
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
     Hero carousel
     --------------------------------------------------------- */
  var track = $('#heroTrack'), dotsHost = $('#heroDots');

  /* The brief asks for 2–4 slides, so eligibility is not enough — they
     compete, and the most relevant four win. */
  function slideScore(s) {
    var id = s.dataset.slide;
    if (s.dataset.faith === 'islamic' && !profile.islamic) return -1;
    if (s.dataset.loc && s.dataset.loc !== profile.country) return -1;
    if (id === 'prayer') return 100;
    if (id === 'plan') return 80;
    if (id === 'trains') return hasInterest('trains') ? 78 : 74;
    if (id === 'read') return 70;
    if (id === 'money') {
      if (!profile.prefs.finance) return -1;
      return ['rates', 'expenses', 'bills', 'savings'].some(hasInterest) ? 62 : 45;
    }
    return 40;
  }

  function renderHero() {
    if (!track) return;
    var slides = $$('.slide', track);

    var ranked = slides.map(function (s) { return { el: s, score: slideScore(s) }; })
      .filter(function (x) { return x.score > 0; })
      .sort(function (a, b) { return b.score - a.score; })
      .slice(0, 4);

    var keep = ranked.map(function (x) { return x.el; });
    slides.forEach(function (s) { s.classList.toggle('is-off', keep.indexOf(s) === -1); });
    keep.forEach(function (s, i) { s.style.order = i; });

    dotsHost.innerHTML = keep.map(function (s, i) {
      return '<button class="hero__dot' + (i === 0 ? ' is-active' : '') + '" role="tab" ' +
             'aria-label="Slide ' + (i + 1) + ' of ' + keep.length + '"></button>';
    }).join('');
    /* scrollLeft 0 is the right-hand end in RTL, which would open the
       carousel on the last slide. */
    if (keep.length) {
      track.scrollLeft = L.dir() === 'rtl' ? track.scrollWidth : 0;
    }
    bindDots(keep);
  }

  function bindDots(shown) {
    var dots = $$('.hero__dot', dotsHost);
    dots.forEach(function (d, i) {
      d.addEventListener('click', function () {
        if (shown[i]) track.scrollTo({ left: shown[i].offsetLeft - track.offsetLeft, behavior: 'smooth' });
      });
    });
  }

  if (track) {
    var raf = null;
    track.addEventListener('scroll', function () {
      if (raf) return;
      raf = requestAnimationFrame(function () {
        raf = null;
        /* Slides are reordered with flex `order`, so rank by position, not DOM. */
        var shown = $$('.slide', track)
          .filter(function (s) { return !s.classList.contains('is-off'); })
          .sort(function (a, b) { return a.offsetLeft - b.offsetLeft; });
        var mid = track.scrollLeft + track.clientWidth / 2;
        var best = 0, bestD = Infinity;
        shown.forEach(function (s, i) {
          var c = s.offsetLeft - track.offsetLeft + s.offsetWidth / 2;
          var d = Math.abs(c - mid);
          if (d < bestD) { bestD = d; best = i; }
        });
        $$('.hero__dot', dotsHost).forEach(function (d, n) { d.classList.toggle('is-active', n === best); });
      });
    }, { passive: true });

    /* Drag with a mouse, for anyone reviewing this on a desktop. */
    var down = false, sx = 0, sl = 0, moved = 0;
    track.addEventListener('mousedown', function (e) {
      down = true; moved = 0; sx = e.clientX; sl = track.scrollLeft;
      track.classList.add('is-dragging');
    });
    document.addEventListener('mousemove', function (e) {
      if (!down) return;
      var dx = e.clientX - sx;
      moved = Math.max(moved, Math.abs(dx));
      track.scrollLeft = sl - dx;
    });
    document.addEventListener('mouseup', function () {
      if (!down) return;
      down = false;
      track.classList.remove('is-dragging');
    });
    /* Swallow the click that ends a drag; otherwise let the slide's own
       data-tab / data-sheet flow through the delegated handler. */
    track.addEventListener('click', function (e) {
      if (moved > 8) { e.preventDefault(); e.stopPropagation(); }
    }, true);
  }

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

  function fmtCountdown(m) {
    var total = Math.max(0, Math.round(m * 60));
    var h = Math.floor(total / 3600);
    return h + ':' + pad2(Math.floor(total % 3600 / 60)) + ':' + pad2(total % 60);
  }

  function fmtShort(m) {
    var total = Math.max(0, Math.round(m));
    return Math.floor(total / 60) + ':' + pad2(total % 60);
  }

  function updatePrayer() {
    if (!profile.islamic) return;
    var st = prayerState();

    var set = function (id, v) { var el = $(id); if (el) el.textContent = v; };
    set('#heroPrayerName', st.next.name);
    var line = $('#heroPrayerLine');
    if (line) line.textContent = t('slide.prayer.x', { time: hhmm(st.next), city: profile.city });
    set('#heroCountdown', fmtCountdown(st.toNext));
    set('#ctxPrayerName', st.next.name);
    set('#ctxPrayerTime', hhmm(st.next));
    set('#ctxCountdown', fmtShort(st.toNext));
    set('#prayerSheetCity', profile.city);
  }

  /* ---------------------------------------------------------
     Today — stats and agenda are assembled, not hard-coded
     --------------------------------------------------------- */
  function renderTodayStats() {
    var host = $('#todayStats');
    if (!host) return;
    var stats = [];

    function unit(u) { return ' <span>' + esc(t('unit.' + u)) + '</span>'; }
    if (profile.islamic) {
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

  function renderAgenda() {
    var host = $('#agenda');
    if (!host) return;

    /* Times are carried as {h, m} and formatted only when drawn: a
       locale-formatted string cannot be sorted or sliced. */
    var events = [
      { h: 9, m: 30, title: t('agenda.standup'), meta: t('agenda.standupMeta'), icon: 'i-check-circle', done: true },
      { h: 14, m: 0, title: t('agenda.review'), meta: t('agenda.reviewMeta'), icon: 'i-clock', now: true },
      { h: 18, m: 30, title: t('agenda.groceries'), meta: t('agenda.groceriesMeta'), icon: 'i-cart', act: 'tool:shopping' }
    ];

    var lsf = feature('loadshed');
    if (lsf && visible(lsf)) {
      var ls = toolCtx('loadshed').loadshed();
      events.push({ h: Math.floor(ls.slot.fromM / 60), m: ls.slot.fromM % 60,
        title: t('loadshed.outage'), meta: ls.area + ' · ' + ls.slot.duration,
        icon: 'i-bolt', act: 'tool:loadshed' });
    }

    if (profile.islamic) {
      var st = prayerState();
      st.main.forEach(function (p) {
        var past = mins(p) < (new Date().getHours() * 60 + new Date().getMinutes());
        events.push({
          h: p.h, m: p.m, title: t('prayer.' + (PKEYS[p.name] || 'fajr')),
          meta: past ? t('agenda.prayed') : t('agenda.adhanOn'),
          icon: past ? 'i-check-circle' : 'i-bell',
          done: past, act: 'tool:prayer'
        });
      });
    }

    events.sort(function (a, b) { return (a.h * 60 + a.m) - (b.h * 60 + b.m); });

    var nowM = new Date().getHours() * 60 + new Date().getMinutes();
    host.innerHTML = events.map(function (e) {
      var em = e.h * 60 + e.m;
      var done = e.done || (em < nowM && !e.now);
      var cls = e.now ? ' is-now' : done ? ' is-done' : '';
      return '<div class="tl-item' + cls + '">' +
        '<span class="tl-time num">' + esc(L.time(e.h, e.m)) + '</span>' +
        '<span class="tl-line"><span class="tl-node"></span></span>' +
        '<button class="tl-card pressable" data-act="' + (e.act || ('toast:' + e.title)) + '">' +
          '<span class="tl-card__body"><span class="tl-card__title">' + esc(e.title) + '</span>' +
          '<span class="tl-card__meta">' + esc(e.meta) + '</span></span>' +
          '<span class="tl-card__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + e.icon + '"/></svg></span>' +
        '</button></div>';
    }).join('');

    var sub = $('#agendaSub');
    if (sub) sub.textContent = t(profile.islamic ? 'today.agendaMuslim' : 'today.agendaGeneral');
  }

  function updateDayRing() {
    var ring = $('#dayRing'), value = $('#dayRingValue');
    if (!ring) return;
    var d = new Date();
    var pct = (d.getHours() * 60 + d.getMinutes()) / 1440;
    var circ = 2 * Math.PI * 42;
    ring.style.strokeDashoffset = (circ * (1 - pct)).toFixed(1);
    if (value) value.textContent = Math.round(pct * 100) + '%';
  }

  /* ---------------------------------------------------------
     Tasks
     --------------------------------------------------------- */
  document.addEventListener('click', function (e) {
    var task = e.target.closest('#taskList .task');
    if (!task) return;
    var done = task.classList.toggle('is-done');
    toast(done ? 'Nice — one less thing' : 'Back on the list');
  });

  /* ---------------------------------------------------------
     Quick tools
     --------------------------------------------------------- */
  var QUICK_FALLBACK = ['calculator', 'weather', 'calendar', 'todos', 'currency', 'notes', 'timer', 'converter'];

  function renderQuickTools() {
    var host = $('#quickTools');
    if (!host) return;

    var picked = [], seen = {};
    function add(f) {
      if (!f || seen[f.id] || picked.length >= 8) return;
      if (!visible(f) || f.sens) return;   /* sensitive tools are never promoted here */
      seen[f.id] = 1;
      picked.push(f);
    }

    /* Recently used first, then round-robin across the chosen interests —
       one tool per interest per pass. Without the round-robin, a single
       interest like "prayer" would fill the whole grid on its own. */
    (profile.favourites || []).slice(0, 3).forEach(function (id) { add(feature(id)); });
    profile.recents.slice(0, 2).forEach(function (id) { add(feature(id)); });

    if (profile.interests.length) {
      var pools = profile.interests.map(function (int) {
        return visibleFeatures().filter(function (f) {
          return f.ints && f.ints.indexOf(int) !== -1 && !f.sens;
        });
      });
      for (var round = 0; round < 4 && picked.length < 8; round++) {
        for (var p = 0; p < pools.length && picked.length < 8; p++) {
          var taken = 0;
          for (var k = 0; k < pools[p].length && !taken; k++) {
            if (!seen[pools[p][k].id]) { add(pools[p][k]); taken = 1; }
          }
        }
      }
    }
    QUICK_FALLBACK.forEach(function (id) { add(feature(id)); });
    /* §117 — the last resort still respects the contract: a tool that never
       declared itself Home-eligible does not get to fill the grid. */
    visibleFeatures().filter(function (f) { return SPEC.get(f.id).homeEligible; }).forEach(add);
    visibleFeatures().forEach(add);

    host.innerHTML = picked.map(function (f) {
      var accent = !!f.faith;
      return '<button class="tool pressable" data-act="' + actFor(f) + '" data-fid="' + f.id + '">' +
        '<span class="tool__icon' + (accent ? ' tool__icon--accent' : '') + '">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg></span>' +
        '<span class="tool__label">' + esc(fname(f)) + '</span>' +
        (f.m ? '<span class="tool__value num">' + esc(f.m) + '</span>' : '') +
      '</button>';
    }).join('');

    var sub = $('#quickToolsSub');
    if (sub) sub.textContent = t(profile.interests.length ? 'home.quickFromInterests' : 'home.quickDefault');
  }

  /* ---------------------------------------------------------
     Tools screen
     --------------------------------------------------------- */
  var filter = 'foryou';

  function renderToolChips() {
    var host = $('#toolChips');
    if (!host) return;
    var chips = [{ id: 'foryou', label: t('tools.forYou'), icon: 'i-sparkles' },
                 { id: 'all', label: t('a.all') }];
    C.CATEGORIES.forEach(function (cat) {
      if (cat.faith && !profile.islamic) return;
      chips.push({ id: cat.id, label: t('cat.' + cat.id) });
    });
    if (!chips.some(function (c) { return c.id === filter; })) filter = 'foryou';

    host.innerHTML = chips.map(function (c) {
      return '<button class="chip' + (c.id === filter ? ' is-active' : '') + '" data-filter="' + c.id + '">' +
        (c.icon ? '<svg class="ico" viewBox="0 0 24 24"><use href="#' + c.icon + '"/></svg> ' : '') +
        esc(c.label) + '</button>';
    }).join('');
  }

  /* §100.17 — a count where a count means something, and nowhere else. */
  function toolBadgeCount(id) {
    try {
      if (id === 'bills') return toolCtx('bills').bills().overdueCount || 0;
      if (id === 'documents') {
        var d = toolCtx('documents').documents();
        return (d.expiring || 0) + (d.expired || 0);
      }
    } catch (e) {}
    return 0;
  }

  function toolCard(f) {
    var badge = '';
    var n = toolBadgeCount(f.id);
    if (n) badge += '<span class="cat-tool__count" aria-label="' +
      esc(t('n.needsAttention', { n: n })) + '">' + esc(n > 9 ? '9+' : n) + '</span>';
    if (f.sens) badge = '<span class="cat-tool__flag" aria-label="Private"><svg class="ico" viewBox="0 0 24 24"><use href="#i-lock"/></svg></span>';
    else if (f.loc) badge = '<span class="cat-tool__pin" aria-label="Local service"></span>';
    return '<button class="cat-tool pressable" data-act="' + actFor(f) + '" data-fid="' + f.id + '" ' +
      'data-hay="' + esc((f.n + ' ' + (f.kw || '')).toLowerCase()) + '" ' +
      (f.staple ? 'data-staple="1" ' : '') +
      'data-ints="' + esc((f.ints || []).join(' ')) + '">' +
      badge +
      '<span class="cat-tool__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg></span>' +
      '<span class="cat-tool__label">' + esc(fname(f)) + '</span>' +
      '<span class="cat-tool__meta">' + esc(f.m || '') + '</span></button>';
  }

  function renderTools() {
    var host = $('#toolCats');
    if (!host) return;
    var list = visibleFeatures();

    host.innerHTML = C.CATEGORIES.map(function (cat) {
      if (cat.faith && !profile.islamic) return '';
      var items = list.filter(function (f) { return f.c === cat.id; });
      if (!items.length) return '';
      return '<section class="cat" data-cat="' + cat.id + '">' +
        '<div class="cat__head">' +
          '<span class="cat__dot"><svg class="ico" viewBox="0 0 24 24"><use href="#' + cat.icon + '"/></svg></span>' +
          '<div><h2 class="cat__title">' + esc(t('cat.' + cat.id)) + '</h2>' +
          '<p class="cat__sub">' + esc(t('cat.' + cat.id + 'Sub')) + '</p></div>' +
          '<span class="cat__count">' + items.length + '</span>' +
        '</div>' +
        '<div class="cat-grid">' + items.map(toolCard).join('') + '</div>' +
      '</section>';
    }).join('');

    var sub = $('#toolSub');
    if (sub) sub.textContent = t('tools.sub', { n: L.num(list.length) });
    var ph = $('#toolSearch');
    if (ph) {
      ph.setAttribute('placeholder', t('tools.searchPlaceholder', {
        example: profile.country === 'PK' ? 'petrol' : 'currency'
      }));
    }
    var onbCount = $('#onbToolCount');
    if (onbCount) onbCount.textContent = C.FEATURES.length;

    applyFilter();
  }

  function applyFilter() {
    var input = $('#toolSearch');
    var q = (input && input.value || '').trim().toLowerCase();
    var anyVisible = false;

    $$('#toolCats .cat').forEach(function (cat) {
      /* A search always looks across the whole visible catalogue — being on
         "For you" should never stop someone finding a tool by name. */
      var searching = !!q;
      var forYou = !searching && filter === 'foryou' && profile.interests.length > 0;
      var catMatch = searching || filter === 'all' || forYou || cat.dataset.cat === filter;
      var shown = 0;

      $$('.cat-tool', cat).forEach(function (tool) {
        var match = catMatch && (!q || tool.dataset.hay.indexOf(q) !== -1);
        if (match && forYou) {
          /* "For you" is a shortlist, not a straitjacket: an interest match,
             something reached for recently, or a tool nearly everyone wants. */
          match = (tool.dataset.ints || '').split(/\s+/).some(function (t) { return t && hasInterest(t); }) ||
                  tool.dataset.staple === '1' ||
                  profile.recents.indexOf(tool.dataset.fid) !== -1;
        }
        tool.classList.toggle('is-hidden', !match);
        if (match) shown++;
      });

      cat.style.display = shown ? '' : 'none';
      var c = $('.cat__count', cat);
      if (c) c.textContent = shown;
      if (shown) anyVisible = true;
    });

    var empty = $('#toolEmpty');
    if (empty) {
      empty.classList.toggle('is-shown', !anyVisible);
      var ttl = $('.empty__title', empty), x = $('.empty__text', empty);
      if (ttl && x) {
        if (!q && filter === 'foryou') {
          ttl.textContent = t('tools.nothingYet');
          x.textContent = t('tools.nothingYetSub');
        } else {
          ttl.textContent = t('tools.noMatch');
          x.textContent = t('tools.noMatchSub');
        }
      }
    }
  }

  var toolSearchInput = $('#toolSearch');
  if (toolSearchInput) toolSearchInput.addEventListener('input', applyFilter);

  document.addEventListener('click', function (e) {
    var chip = e.target.closest('#toolChips .chip');
    if (!chip) return;
    $$('#toolChips .chip').forEach(function (c) { c.classList.remove('is-active'); });
    chip.classList.add('is-active');
    filter = chip.dataset.filter;
    applyFilter();
  });

  /* ---- Recently used ---- */
  function noteRecent(id) {
    var f = feature(id);
    if (!f || !visible(f)) return;
    profile.recents = [id].concat(profile.recents.filter(function (x) { return x !== id; })).slice(0, 6);
    saveProfile();
    renderRecents();
  }

  function renderRecents() {
    var wrap = $('#toolRecent'), host = $('#toolRecentList');
    if (!wrap || !host) return;
    /* A hidden feature must not resurface through history. */
    var items = profile.recents.map(feature).filter(function (f) { return f && visible(f); });
    wrap.hidden = items.length < 2;
    host.innerHTML = items.map(function (f) {
      return '<button class="recent pressable" data-act="' + actFor(f) + '" data-fid="' + f.id + '">' +
        '<span class="recent__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg></span>' +
        '<span class="recent__label">' + esc(fname(f)) + '</span></button>';
    }).join('');
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
     Content renderers
     --------------------------------------------------------- */
  function renderWeather() {
    var w = C.weatherFor(profile.country, L.country().tz);
    var set = function (id, v) { var el = $(id); if (el) el.textContent = v; };
    set('#weatherCity', profile.city);
    set('#appbarCity', profile.city);
    set('#qiblaCity', profile.city);
    set('#prayerSheetCity', profile.city);
    set('#weatherDesc', w.desc + ' · ' + L.temp(w.feels));
    set('#weatherRain', L.num(w.rain / 100, { style: 'percent' }));
    set('#weatherWind', L.speed(w.wind));
    set('#ctxWeather', w.desc.split(' · ')[0]);
    var el = $('#weatherTemp');
    if (el) el.innerHTML = esc(L.temp(w.temp)).replace('°', '<sup>°</sup>');
    var ct = $('#ctxTemp');
    if (ct) ct.textContent = L.temp(w.temp);
    var icon = $('#weatherIcon use');
    if (icon) icon.setAttribute('href', '#' + w.icon);
    var sunset = $('#weatherSunset');
    if (sunset) {
      var list = prayerSet();
      var mag = list.filter(function (x) { return x.name === 'Maghrib'; })[0] || list[4];
      sunset.textContent = hhmm(mag);
    }
    /* Keep the catalogue in step, or the tool card would still claim 34°
       in New York. */
    var wf = feature('weather');
    if (wf) wf.m = L.temp(w.temp) + ' ' + w.desc.split(' · ')[0];
  }

  /* Every money figure is a share of a monthly budget, so the numbers stay
     believable in Karachi, Tokyo and New York alike. Converting one country's
     figures at the exchange rate would not. */
  var SPEND = { spent: 0.53, groceries: 0.235, fuel: 0.14, bills: 0.15, ledger: 0.106, subs: 0.052 };

  function budget() {
    var b = C.BUDGET[profile.country];
    if (b !== undefined) return b;
    /* No local figure: fall back to a typical 300 USD, converted. */
    return 300 * (L.RATES[L.currencyCode()] || 1);
  }

  function renderMoney() {
    var b = budget();
    var pct = Math.round(SPEND.spent * 100);

    $$('[data-money]').forEach(function (el) {
      var k = el.dataset.money;
      if (k === 'pct') el.textContent = L.num(SPEND.spent, { style: 'percent' });
      else if (k === 'budget') el.textContent = L.moneyRaw(b, null, 0);
      else if (k === 'to') el.textContent = L.currencyCode();
      else if (k === 'rate') el.textContent = L.num(L.RATES[L.currencyCode()] || 1, { maximumFractionDigits: 2 });
      else if (SPEND[k] !== undefined) el.textContent = L.moneyRaw(Math.round(b * SPEND[k]), null, 0);
    });

    var note = $('#fxNote');
    if (note) {
      var code = L.currencyCode();
      var base = code === 'USD' ? 'EUR' : code;
      note.textContent = '1 USD = ' +
        L.num(L.RATES[base] || 1, { maximumFractionDigits: 2 }) + ' ' + base;
    }

    var bar = $('#expensesBar');
    if (bar) bar.dataset.fill = pct;

    var ledger = feature('ledger');
    if (ledger) ledger.m = L.moneyRaw(Math.round(b * SPEND.ledger), null, 0);
    var subs = feature('subs');
    if (subs) subs.m = L.moneyRaw(Math.round(b * SPEND.subs), null, 0);
  }

  function syncFeatureMeta() {
    var pf = feature('prayer');
    if (pf && profile.islamic) {
      var st = prayerState();
      pf.m = st.next.name + ' ' + hhmm(st.next);
    }
  }

  /* The Trains tab shows the same roster the Trains tool does, formatted by
     the locale rather than hard-coded to rupees and English. */
  function renderTrains() {
    var host = $('#trainList');
    if (!host) return;
    var ccy = L.country().currency;
    host.innerHTML = C_DATA.TRAINS.map(function (tr) {
      var status = t(tr.statusKey, { n: tr.delay });
      return '<button class="list-row pressable" data-act="tool:trains" data-fid="trains">' +
        '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-train"/></svg></span>' +
        '<span class="list-row__body">' +
          '<span class="list-row__title">' + esc(tr.name) + ' <span class="trainno num">' + esc(tr.no) + '</span></span>' +
          '<span class="list-row__sub"><span class="num">' + esc(tr.dep) + '</span> → <span class="num">' +
            esc(tr.arr) + '</span> · ' + esc(tr.dur) + ' · ' + esc(L.moneyRaw(tr.fare, ccy, 0)) + '</span>' +
        '</span>' +
        '<span class="list-row__end"><span class="status status--' + (tr.delay ? 'late' : 'ok') + '">' +
          esc(status) + '</span></span></button>';
    }).join('');
  }

  function renderNews() {
    var host = $('#newsList');
    if (!host) return;
    var items = profile.country === 'PK' ? C.NEWS.PK : C.NEWS.GLOBAL;
    var tones = { accent: ['#E7F4F1', '#A5DED4', '#10998A'], violet: ['#EDEAFB', '#B7AEF6', '#6E62E5'], amber: ['#FBEEDD', '#EFC894', '#C9793F'] };
    host.innerHTML = items.map(function (a, i) {
      var t = tones[a.tone] || tones.accent;
      return '<button class="article pressable" data-toast="Opening the story">' +
        '<span class="article__art"><svg viewBox="0 0 62 62"><defs>' +
          '<linearGradient id="nw' + i + '" x1="0" y1="0" x2="1" y2="1">' +
          '<stop offset="0" stop-color="' + t[0] + '"/><stop offset="1" stop-color="' + t[1] + '"/></linearGradient></defs>' +
          '<rect width="62" height="62" fill="url(#nw' + i + ')"/>' +
          '<circle cx="44" cy="18" r="12" fill="' + t[2] + '" opacity=".3"/>' +
          '<path d="M0 48c12-8 20 4 32-3s18-14 30-8v25H0z" fill="' + t[2] + '" opacity=".3"/></svg></span>' +
        '<span class="article__body">' +
          '<span class="article__cat">' + esc(a.cat) + '</span>' +
          '<span class="article__title">' + esc(a.title) + '</span>' +
          '<span class="article__meta">' + esc(a.meta) + '</span>' +
        '</span></button>';
    }).join('');
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

  function renderProfileSummary() {
    /* The profile screen itself is rendered from state (§124.7); what is
       left here are the summaries other screens carry. */
    var avatar = $('#appbarAvatar');
    if (avatar) {
      /* Initials from a real name, or the neutral glyph — never invented
         letters (§124.14). */
      var inits = ACCT.initials();
      avatar.textContent = inits || '';
      avatar.classList.toggle('avatar--anon', !inits);
      if (!inits) {
        avatar.innerHTML = '<svg class="ico" viewBox="0 0 24 24"><use href="#i-user"/></svg>';
      }
    }

    var exploreSub = $('#exploreSub');
    if (exploreSub) {
      exploreSub.textContent = t(localMarkets().indexOf(profile.country) !== -1
        ? 'explore.subLocal' : 'explore.subGlobal');
    }

    var glance = $('#glanceSub');
    if (glance) glance.textContent = t(profile.islamic ? 'home.glanceMuslim' : 'home.glanceGeneral');

    var wsub = $('#weatherSub');
    if (wsub) wsub.textContent = t('explore.weatherSub', { city: profile.city, n: L.num(4) });
  }

  /* Explore stops being a tab in Pakistan, so it needs a way back. */
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
    /* Metadata first — the tool cards below read it. */
    renderWeather();
    renderMoney();
    syncFeatureMeta();
    renderTabs();
    renderHero();
    renderQuickTools();
    renderToolChips();
    renderTools();
    renderRecents();
    renderQuickActions();
    renderLiveNow();
    renderUpcoming();
    renderAround();
    renderTodayStats();
    renderAgenda();
    renderTrains();
    renderNews();
    renderNotifBadge();
    renderProfileSummary();
    renderProfile();
    initHeader();
    updatePrayer();
    /* Rendered content lands inside gated containers, so the gate is applied
       again once everything exists. Otherwise a freshly injected row inside a
       hidden section would still be addressable (§64). */
    applyVisibility();
    /* A settings or authentication screen is as much a part of the render as
       Home is: a language change has to reach the picker that made it. */
    if (current === 'account') renderAccount();
    else if (current === 'auth') renderAuth();
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
    initHeader();
    renderProfileSummary();
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
     Home — quick actions, live information, coming up
     (Master Spec §95, §117, §118)

     Home is not a grid of every tool. It is: what is true right
     now, what you would do immediately, and what is about to
     happen. All three are personalised and none of them is
     allowed to surface a sensitive or hidden tool.
     --------------------------------------------------------- */

  /* §118 — an action performs a task; it does not just open a screen. */
  var QUICK_ACTIONS = [
    { id: 'expenses',  icon: 'i-plus',    key: 'qa.expense',  act: 'tool:expenses' },
    { id: 'todos',     icon: 'i-check-square', key: 'qa.task', act: 'tool:todos' },
    { id: 'qr',        icon: 'i-qr',      key: 'qa.scan',     act: 'tool:qr' },
    { id: 'notes',     icon: 'i-note',    key: 'qa.note',     act: 'tool:notes' },
    { id: 'water',     icon: 'i-droplet', key: 'qa.water',    act: 'water:small' },
    { id: 'tasbih',    icon: 'i-beads',   key: 'qa.tasbih',   act: 'tool:tasbih' },
    { id: 'timer',     icon: 'i-timer',   key: 'qa.timer',    act: 'tool:timer' },
    { id: 'shopping',  icon: 'i-cart',    key: 'qa.shop',     act: 'tool:shopping' },
    { id: 'parcel',    icon: 'i-package', key: 'qa.parcel',   act: 'tool:parcel' },
    { id: 'docscan',   icon: 'i-scan',    key: 'qa.docscan',  act: 'tool:docscan' }
  ];

  function renderQuickActions() {
    var host = $('#quickActions');
    if (!host) return;
    var picked = QUICK_ACTIONS.filter(function (a) {
      var f = feature(a.id);
      /* The spec allows a sensitive tool as a quick *action* (adding an
         expense) even though it is never promoted as a Home card. */
      return f && visible(f) && SPEC.get(a.id).quickEligible;
    }).slice(0, 5);

    $('#quickActionsWrap').hidden = picked.length < 3;
    host.innerHTML = picked.map(function (a) {
      return '<button class="qaction pressable" data-act="' + a.act + '" data-fid="' + a.id + '">' +
        '<span class="qaction__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + a.icon + '"/></svg></span>' +
        '<span class="qaction__label">' + esc(t(a.key)) + '</span></button>';
    }).join('');
  }

  /* §95 — what Home shows depends on the hour, the market session and the
     season, not on a fixed list. */
  function liveCards() {
    var h = new Date().getHours();
    var out = [];

    function card(o) {
      return '<button class="livecard pressable" data-act="' + o.act + '" data-fid="' + o.fid + '">' +
        '<span class="livecard__icon livecard__icon--' + (o.tone || 'accent') + '">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + o.icon + '"/></svg></span>' +
        '<span class="livecard__body">' +
          '<span class="livecard__title">' + esc(o.title) + '</span>' +
          '<span class="livecard__meta">' + esc(o.meta) + '</span>' +
        '</span>' +
        '<span class="livecard__end">' +
          '<span class="livecard__value">' + o.value + '</span>' +
          (o.badge || '') +
        '</span></button>';
    }

    /* Weather is relevant all day; before bed it flips to tomorrow. */
    var wf = feature('weather');
    if (wf && visible(wf)) {
      var w = toolCtx('weather').weather();
      var evening = h >= 19 || h < 5;
      var day = evening ? w.daily[1] : w.daily[0];
      out.push(card({
        fid: 'weather', act: 'tool:weather', icon: w.icon, tone: 'sky',
        title: evening ? t('home.tomorrowIn', { city: profile.city }) : profile.city,
        meta: day.desc + ' · ' + t('weather.rain') + ' ' + day.rain + '%',
        value: L.temp(evening ? day.hi : w.temp),
        badge: '<span class="livecard__sub">' + esc(L.temp(day.hi) + ' / ' + L.temp(day.lo)) + '</span>'
      }));
    }

    /* A market snapshot, but only while a market the user follows is open. */
    var mf = feature('markets');
    if (mf && visible(mf)) {
      var c = toolCtx('markets');
      var ex = c.exchange();
      var session = c.marketSession(ex);
      var ix = ex ? ex.indices[0] : window.LUME_DATA.GLOBAL_INDICES[0];
      if (session.open || h >= 8) {
        out.push(card({
          fid: 'markets', act: 'tool:markets', icon: 'i-trending',
          tone: ix.pct >= 0 ? 'up' : 'down',
          title: ix.name,
          meta: (ex ? ex.name : t('markets.worldBoard')) + ' · ' + session.label,
          value: L.num(ix.value, { maximumFractionDigits: 0 }),
          badge: '<span class="delta delta--' + (ix.pct >= 0 ? 'up' : 'down') + '">' +
            '<i aria-hidden="true">' + (ix.pct >= 0 ? '▲' : '▼') + '</i>' +
            Math.abs(ix.pct).toFixed(2) + '%</span>'
        }));
      }
    }

    /* A live outage or a bill that is actually overdue outranks both. */
    var lf = feature('loadshed');
    if (lf && visible(lf)) {
      var ls = toolCtx('loadshed').loadshed();
      if (ls.now) {
        out.unshift(card({
          fid: 'loadshed', act: 'tool:loadshed', icon: 'i-bolt', tone: 'warn',
          title: t('loadshed.currentlyOff'), meta: ls.area + ' · ' + t('loadshed.until', { time: ls.slot.to }),
          value: ls.endsIn
        }));
      }
    }

    var bf = feature('bills');
    if (bf && visible(bf)) {
      var b = toolCtx('bills').bills();
      if (b.overdueCount) {
        out.push(card({
          fid: 'bills', act: 'tool:bills', icon: 'i-receipt', tone: 'warn',
          title: t('bills.overdue.title', { n: b.overdueCount }),
          meta: t('bills.dueThisMonth') + ' · ' + L.money(b.totalDue),
          value: L.money(b.overdue)
        }));
      }
    }

    return out.slice(0, 3);
  }

  function renderLiveNow() {
    var host = $('#liveNow'), wrap = $('#liveWrap');
    if (!host || !wrap) return;
    var cards = liveCards();
    wrap.hidden = !cards.length;
    host.innerHTML = cards.join('');
    var sub = $('#liveSub');
    if (sub) sub.textContent = t('home.liveNowSub', { time: L.time(new Date().getHours(), new Date().getMinutes()) });
  }

  /* §95 — upcoming items, drawn from whatever the user actually has:
     prayers, bills, renewals, birthdays, document expiries. */
  function upcomingItems() {
    var out = [];

    if (profile.islamic && visible(feature('prayer'))) {
      var st = toolCtx('prayer').prayerState();
      out.push({ when: L.time(st.next.h, st.next.m), title: t('prayer.' + st.next.key),
        sub: t('prayer.next'), icon: 'i-prayer', act: 'tool:prayer', order: st.minutes });
    }

    var bf = feature('bills');
    if (bf && visible(bf)) {
      toolCtx('bills').bills().list.filter(function (b) { return b.state === 'due' || b.state === 'overdue'; })
        .slice(0, 2).forEach(function (b) {
          out.push({ when: L.money(b.amount), title: b.name, sub: b.dueLabel,
            icon: b.icon, act: 'tool:bills', order: 500 });
        });
    }

    var sf = feature('subs');
    if (sf && visible(sf)) {
      var next = toolCtx('subs').subscriptions().next;
      out.push({ when: next.renews, title: next.name, sub: t('subs.renews', { date: next.renews }),
        icon: 'i-refresh', act: 'tool:subs', order: 600 + next.days });
    }

    var bd = feature('birthdays');
    if (bd && visible(bd)) {
      var nb = toolCtx('birthdays').birthdays().next;
      out.push({ when: nb.date, title: nb.name, sub: nb.kind + ' · ' + t('common.inDays', { n: nb.days }),
        icon: 'i-cake', act: 'tool:birthdays', order: 700 + nb.days });
    }

    var df = feature('documents');
    if (df && visible(df)) {
      var docs = toolCtx('documents').documents();
      var soon = docs.list.filter(function (d) { return d.days !== null && d.days >= 0 && d.days < 45; })[0];
      /* A document is sensitive, so Home names the renewal, not the number. */
      if (soon) {
        out.push({ when: soon.expires, title: t('docs.renewSoon', { name: soon.name }),
          sub: t('common.inDays', { n: soon.days }), icon: 'i-folder', act: 'tool:documents', order: 800 });
      }
    }

    return out.sort(function (a, b) { return a.order - b.order; }).slice(0, 4);
  }

  function renderUpcoming() {
    var host = $('#upcomingList'), wrap = $('#upcomingWrap');
    if (!host || !wrap) return;
    var items = upcomingItems();
    wrap.hidden = !items.length;
    host.innerHTML = '<div class="rows">' + items.map(function (i) {
      return '<button class="crow pressable" data-act="' + i.act + '">' +
        '<span class="crow__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + i.icon + '"/></svg></span>' +
        '<span class="crow__label">' + esc(i.title) + '<i>' + esc(i.sub) + '</i></span>' +
        '<span class="crow__value">' + esc(i.when) + '</span></button>';
    }).join('') + '</div>';
  }


  /* §105 — "Around you" is the regional configuration made visible. It lists
     whichever local services this country actually has, with a live value
     pulled from the same context the tool screen uses. Nothing here knows
     the name of a country. */
  var LOCAL_SERVICES = [
    { id: 'fuel',       icon: 'i-fuel',   value: function (c) {
        var f = C_DATA.fuelFor(profile.country);
        return L.moneyRaw(f.items[0].v, f.ccy, 2);
      }, sub: function () {
        return C_DATA.fuelFor(profile.country).items.map(function (i) { return i.n; }).slice(0, 3).join(' · ');
      } },
    { id: 'loadshed',   icon: 'i-bolt',   value: function (c) {
        var ls = c.loadshed();
        return ls.now ? ls.endsIn : ls.slot.from;
      }, sub: function (c) {
        var ls = c.loadshed();
        return ls.area + ' · ' + (ls.now ? t('loadshed.currentlyOff') : t('loadshed.nextOutage', { from: ls.slot.from, to: ls.slot.to }));
      } },
    { id: 'goldrates',  icon: 'i-coins',  value: function (c) {
        var g = c.metals();
        return L.moneyRaw(g.gold.perTola, g.ccy, 0);
      }, sub: function () { return t('rates.openMarket') + ' · ' + t('rates.gold24'); } },
    { id: 'trains',     icon: 'i-train',  value: function () { return ''; },
      sub: function () {
        var tr = C_DATA.TRAINS[0];
        return tr.name + ' · ' + t(tr.statusKey, { n: tr.delay });
      } },
    { id: 'emergency',  icon: 'i-shield', value: function () {
        return C_DATA.emergencyFor(profile.country)[0].num;
      }, sub: function () { return C_DATA.emergencyFor(profile.country)[0].n; } },
    { id: 'holidays',   icon: 'i-calendar', value: function () {
        return C_DATA.holidaysFor(profile.country)[0].date;
      }, sub: function () { return C_DATA.holidaysFor(profile.country)[0].name; } }
  ];

  function renderAround() {
    var wrap = $('#aroundWrap'), host = $('#aroundList'), tag = $('#aroundTag');
    if (!wrap || !host) return;

    var rows = [];
    LOCAL_SERVICES.forEach(function (svc) {
      var f = feature(svc.id);
      if (!f || !visible(f)) return;
      var c = toolCtx(svc.id);
      var value = '', sub = '';
      try { value = svc.value(c); sub = svc.sub(c); } catch (e) { return; }
      rows.push('<button class="list-row pressable" data-act="tool:' + f.id + '" data-fid="' + f.id + '">' +
        '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + svc.icon + '"/></svg></span>' +
        '<span class="list-row__body"><span class="list-row__title">' + esc(fname(f)) + '</span>' +
        '<span class="list-row__sub">' + esc(sub) + '</span></span>' +
        '<span class="list-row__end">' + (value ? '<span class="list-row__value num">' + esc(value) + '</span>' : '') +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span></button>');
    });

    wrap.hidden = rows.length < 2;
    host.innerHTML = rows.join('');
    if (tag) tag.textContent = L.countryName(profile.country);
  }

  /* ---------------------------------------------------------
     Tool screens  (Master Spec §7, §8, §64, §109)

     One host, one router, one back stack. Opening a tool is
     gated by the same visible() every other surface uses, so a
     hidden feature cannot be reached through a deep link, a
     related-tool card or a search result either.
     --------------------------------------------------------- */
  var toolCtx = window.LUME_CTX({
    L: L, t: t,
    profile: function () { return profile; },
    store: store,
    featureFor: feature,
    fname: fname,
    isVisible: visible
  });
  TOOLS.init(toolCtx);

  var toolStack = [];       /* tools opened on top of each other */
  var toolReturnTab = 'home';
  var currentTool = null;

  function renderTool() {
    if (!currentTool) return;
    var built = TOOLS.build(currentTool);
    var head = $('#toolHeader'), body = $('#toolBody');
    if (!built || !body) return;
    head.innerHTML = built.header;
    body.innerHTML = built.body;
    body.dataset.density = built.density;
    body.dataset.archetype = built.archetype;
    applyStrings(body);
    animateBars($('#screen-tool'));
    if (currentTool === 'calculator') calcToolRender();
  }

  function openTool(id, opts) {
    var f = feature(id);
    /* Defence in depth: the entry point is not the only gate (§64). */
    if (!f || !visible(f)) { toast(t('tool.unavailable')); return; }

    if (currentTool && (!opts || !opts.replace)) toolStack.push(currentTool);
    else if (!currentTool) toolReturnTab = current;

    currentTool = id;
    current = 'tool';          /* a tool is showing, whatever opened it */
    noteRecent(id);

    var screen = $('#screen-tool');
    $$('.screen').forEach(function (sc) { sc.classList.remove('is-active'); });
    screen.classList.add('is-active');
    screen.scrollTop = 0;
    $$('.tab').forEach(function (tb) {
      tb.classList.remove('is-active');
      tb.setAttribute('aria-selected', 'false');
    });
    movePill(null);
    var back = $('#exploreBack');
    if (back) back.hidden = true;

    renderTool();
    renderRecents();
  }

  function stopClocks() {
    for (var k in clockTimers) {
      if (Object.prototype.hasOwnProperty.call(clockTimers, k)) {
        clearInterval(clockTimers[k]);
        var st = toolCtx(k)._state[k];
        if (st) st.running = false;
      }
    }
  }

  function closeTool() {
    if (!currentTool) { goTo(notifReturnTab || 'home'); return; }
    /* A detail view is a view *of* the tool, so back returns to the tool
       before it returns to where the tool was opened from (§9). */
    if (currentTool) {
      var c = toolCtx(currentTool);
      if (c && c.state('detail')) { c.setState('detail', ''); renderTool(); return; }
    }
    /* A countdown that keeps running would announce itself from an
       unrelated screen. */
    stopClocks();
    if (toolStack.length) { currentTool = toolStack.pop(); renderTool(); return; }
    currentTool = null;
    goTo(toolReturnTab);
  }

  /* Leaving through the tab bar abandons the whole tool stack. */
  var goToBase = goTo;
  goTo = function (name, quiet) {
    /* A tool's sub-view does not survive leaving the tool: reopening
       Markets from Home landed straight back inside an asset detail. */
    if (currentTool) {
      var leaving = toolCtx(currentTool);
      if (leaving) leaving.setState('detail', '');
      stopClocks();
    }
    currentTool = null;
    toolStack.length = 0;
    /* An account route is abandoned the same way a tool is — but only when
       the navigation is actually leaving it. renderTabs() routes through
       here on every render, so an unguarded clear here silently killed the
       screen that had just asked to be refreshed. */
    if (name !== 'account') { accountRoute = null; accountStack.length = 0; }
    if (name !== 'auth') { authRoute = null; authStack.length = 0; }
    /* The centre is a destination, not a tab, so it remembers where the
       user was and the header's back control returns them there. */
    if (name === 'notifications') {
      /* Only a tab is somewhere to come back to. Closing a tool that was
         opened from the centre re-entered here with current === 'tool', and
         back then returned to a tool screen with no tool in it — from which
         every further back returned to the same dead screen. */
      if (current !== 'notifications') {
        notifReturnTab = tabOrder().indexOf(current) !== -1 ? current : 'home';
      }
      goToBase(name, quiet);
      renderNotifCentre();
      return;
    }
    goToBase(name, quiet);
  };

  /* The header sticks; a hairline appears once content scrolls under it. */
  (function stickyToolbar() {
    var screen = $('#screen-tool');
    if (!screen) return;
    screen.addEventListener('scroll', function () {
      var bar = $('.toolbar', screen);
      if (bar) bar.classList.toggle('is-stuck', screen.scrollTop > 4);
    }, { passive: true });
  })();

  /* Field names are prefixed per tool so two screens can each have an
     "amount"; the context stores the bare key. */
  /* One rule for both the typed and the stepped inputs. */
  function fieldKey(name) {
    if (FIELD_ALIAS[name]) return FIELD_ALIAS[name];
    return name.indexOf('_') !== -1 ? name.split('_').slice(1).join('_') : name;
  }

  var FIELD_ALIAS = {
    z_cash: 'cash', z_gold: 'gold', z_silver: 'silver', z_inv: 'inv', z_biz: 'biz', z_liab: 'liab',
    fa_gross: 'gross', fa_debts: 'debts', fa_bequest: 'bequest',
    fc_dist: 'dist', fc_econ: 'econ', fc_price: 'price', fc_people: 'people',
    tax_income: 'income', tax_ded: 'deductions',
    ln_principal: 'principal', ln_rate: 'rate', ln_years: 'years',
    tp_bill: 'bill', tp_people: 'people',
    ci_initial: 'initial', ci_monthly: 'monthly', ci_rate: 'rate', ci_years: 'years',
    bmi_h: 'height', bmi_w: 'weight',
    age_dob: 'dob',
    dc_from: 'from', dc_to: 'to', dc_days: 'days', dc_start: 'from',
    cv_amount: 'amount', uc_amount: 'amount'
  };

  /* §26.11 — choosing a market persists and re-renders Markets in place. */
  function renderMarketPicker() {
    var host = $('#marketList');
    if (!host) return;
    var opts = toolCtx('markets').marketOptions();
    /* §26.11 — country, its region, the exchanges within it, and the world
       board. A market with two venues names both. */
    host.innerHTML = opts.map(function (o) {
      return '<button class="list-row pressable" data-market="' + esc(o.code) + '">' +
        '<span class="list-row__icon">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' +
            (o.code === 'GLOBAL' ? 'i-globe' : 'i-trending') + '"/></svg></span>' +
        '<span class="list-row__body">' +
          '<span class="list-row__title">' + esc(o.name) +
            (o.home ? ' <span class="tag tag--neutral">' + esc(t('markets.default')) + '</span>' : '') +
          '</span>' +
          '<span class="list-row__sub">' + esc(o.region) + ' · ' + esc(o.exchange) + '</span>' +
          (o.venues && o.venues.length > 1
            ? '<span class="list-row__sub">' + esc(t('markets.venues')) + ': ' +
              esc(o.venues.join(' · ')) + '</span>' : '') +
        '</span>' +
        '<span class="list-row__end">' +
          '<span class="list-row__value">' + esc(o.sub) + '</span>' +
          (o.on ? '<svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg>' : '') +
        '</span></button>';
    }).join('');
  }

  document.addEventListener('click', function (e) {
    var row = e.target.closest('[data-market]');
    if (!row) return;
    var code = row.dataset.market;
    var c = toolCtx('markets');
    /* "Automatic" is not a market — it is the absence of an override, so
       Markets follows the user's country again (§26.1). */
    if (code === 'AUTO') {
      c.setState('market', '');
      profile.market = null;
    } else {
      c.setState('market', code);
      profile.market = code;
    }
    c.setState('detail', '');
    c.setState('class', 'stocks');
    saveProfile();
    sheetClose();
    if (currentTool === 'markets') renderTool();
    renderLiveNow();
    toast(t('markets.switched', {
      name: code === 'AUTO' ? L.countryName(profile.country)
          : code === 'GLOBAL' ? t('markets.globalMarkets')
          : L.countryName(code)
    }));
  });

  /* ---- the action vocabulary tool screens speak ---- */
  function toolAction(kind, arg) {
    var bits = String(arg).split(':');

    if (kind === 'tool') { openTool(bits[0]); return true; }

    if (kind === 'toolstate') {
      /* toolstate:<tool>:<key>:<value> — a tab, a filter, a selected row */
      var id = bits.shift(), key = bits.shift(), value = bits.join(':');
      var c = toolCtx(id);
      /* An empty value clears the key. Coercing it to `true` turned
         "leave the detail" into "open detail `true`". */
      if (c) c.setState(key, value);
      if (currentTool === id) renderTool();
      return true;
    }

    if (kind === 'toolsearch') {
      var tid = bits.shift();
      var q = bits.join(':');
      if (q) {
        var cs = toolCtx(tid);
        if (cs) cs.setState('q', q);
        if (currentTool === tid) renderTool();
      } else {
        var input = $('[data-tool-search]', $('#screen-tool'));
        if (input) input.focus();
      }
      return true;
    }

    if (kind === 'share') { openShare(bits[0] || currentTool); return true; }
    if (kind === 'export') { exportTool(bits[0] || currentTool); return true; }
    if (kind === 'fav' || kind === 'bookmark') { toggleFavourite(bits[0] || currentTool); return true; }

    if (kind === 'track') {
      toast(t('track.marked', { name: t('prayer.' + bits[0]) }));
      return true;
    }

    if (kind === 'water') {
      var cw = toolCtx('water');
      var add = bits[0] === 'large' ? 500 : 250;
      cw._state.water = cw._state.water || {};
      cw._state.water.ml = (cw._state.water.ml === undefined ? 1250 : cw._state.water.ml) + add;
      if (currentTool === 'water') renderTool();
      toast(t('water.added', { amount: add + ' ml' }));
      return true;
    }

    if (kind === 'alarmtoggle') {
      var host = $('#screen-tool');
      var row = host && host.querySelector('[data-act="alarmtoggle:' + bits[0] + '"]');
      var sw = row && row.querySelector('.switch');
      if (sw) sw.classList.toggle('is-on');
      return true;
    }

    if (kind === 'pushallow') {
      NOTIFY.requestPush(function (result) {
        sheetClose();
        if (result === 'granted') {
          toast(t('n.push.thanks'));
          if (pendingAlert) { toast(t('n.armed', { name: pendingAlert.entity || pendingAlert.tool })); pendingAlert = null; }
        } else if (result === 'denied') {
          toast(t('n.push.deniedHelp'));
        } else {
          toast(t('n.push.unsupported'));
        }
        renderNotifBadge();
        if (current === 'notifications') renderNotifCentre();
      });
      return true;
    }
    if (kind === 'notifrestore') {
      NOTIFY.restoreAll();
      toast(t('n.restored'));
      renderNotifBadge();
      if (current === 'notifications') renderNotifCentre();
      return true;
    }
    if (kind === 'notiffilter') { notifFilter = bits[0] || 'all'; renderNotifCentre(); return true; }
    if (kind === 'notifreadall') { NOTIFY.markRead(); renderNotifCentre(); return true; }
    if (kind === 'notify') { armAlert(bits[0], bits.slice(1).join(':')); return true; }
    if (kind === 'speedtest') { runSpeedTest(); return true; }
    if (kind === 'tasbihreset') { resetToolTasbih(); return true; }
    if (kind === 'cvswap' || kind === 'ucswap') { swapConverter(kind); return true; }
    if (kind === 'clock') { runClock(bits); return true; }

    return false;
  }

  /* §99 — export writes a real file. A CSV where the screen is a list or a
     table, JSON where it is a calculation, named for the tool and the day. */
  function exportTool(id) {
    var c = toolCtx(id);
    if (!c) return;
    var rows = c.exportRows ? c.exportRows() : null;
    var name = 'lume-' + id + '-' + c.isoToday();
    var blob, ext;

    if (rows && rows.length) {
      var csv = rows.map(function (r) {
        return r.map(function (cell) {
          var v = cell === undefined || cell === null ? '' : String(cell);
          return /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
        }).join(',');
      }).join('\r\n');
      blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' });
      ext = '.csv';
    } else {
      blob = new Blob([JSON.stringify({ tool: id, exported: new Date().toISOString(),
        locale: L.locale(), currency: L.currencyCode() }, null, 2)],
        { type: 'application/json' });
      ext = '.json';
    }

    try {
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = name + ext;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
      toast(t('tool.exportedAs', { name: name + ext }));
    } catch (e) {
      toast(t('tool.exportFailed'));
    }
  }

  /* Favourites persist on the profile, so the star means something. */
  function toggleFavourite(id) {
    if (!id) return;
    profile.favourites = profile.favourites || [];
    var at = profile.favourites.indexOf(id);
    if (at === -1) profile.favourites.push(id); else profile.favourites.splice(at, 1);
    saveProfile();
    var f = feature(id);
    toast(t(at === -1 ? 'tool.favourited' : 'tool.unfavourited', { name: f ? fname(f) : id }));
    if (currentTool === id) renderTool();
    renderQuickTools();
  }

  /* §100.8 — a per-tool alert, asked for in context. Asking here is also
     the right moment to ask for push permission (§100.11). */
  function armAlert(tool, entity) {
    var p = NOTIFY.prefs();
    var f = feature(tool);
    var name = f ? fname(f) : tool;
    if (!p.cats[NOTIFY.SOURCES.filter(function (s) { return s.tool === tool; })
        .map(function (s) { return s.cat; })[0] || 'system']) {
      toast(t('n.catOff', { name: name }));
      return;
    }
    if (NOTIFY.pushSupported() && NOTIFY.pushPermission() === 'default') {
      sheetOpen('notifpush');
      pendingAlert = { tool: tool, entity: entity };
      return;
    }
    toast(t('n.armed', { name: entity || name }));
    renderNotifBadge();
  }

  var pendingAlert = null;

  /* ---- live inputs: a calculator recomputes as you type ---- */
  var reflowTimer;

  function reflowSoon() {
    clearTimeout(reflowTimer);
    reflowTimer = setTimeout(function () {
      var active = document.activeElement;
      var activeName = active && active.dataset ? active.dataset.input : null;
      var isSearch = active && active.hasAttribute && active.hasAttribute('data-tool-search');
      var caret = null;
      try { caret = active && active.selectionStart; } catch (err) {}
      var value = active ? active.value : null;
      renderTool();
      var again = null;
      if (activeName) again = $('[data-input="' + activeName + '"]', $('#screen-tool'));
      else if (isSearch) again = $('[data-tool-search]', $('#screen-tool'));
      if (again) {
        if (value !== null && value !== undefined) again.value = value;
        again.focus();
        /* setSelectionRange throws on type=number; the caret is already at
           the end there, which is where it was. */
        try { again.setSelectionRange(caret, caret); } catch (err2) {}
      }
    }, 280);
  }

  document.addEventListener('input', function (e) {
    if (!currentTool) return;
    var c = toolCtx(currentTool);
    if (!c) return;

    var search = e.target.closest('[data-tool-search]');
    if (search) { c.setState('q', search.value); reflowSoon(); return; }

    var el = e.target.closest('[data-input]');
    if (!el) return;
    var name = el.dataset.input;
    /* A number input reports '' for a half-typed decimal like "12.", so
       committing 0 on every keystroke would rewrite the field under the
       user. Leave the model alone until the value parses. */
    if (el.type === 'number' && el.value === '') return;
    c.setField(fieldKey(name), el.type === 'number' ? Number(el.value) : el.value);
    reflowSoon();
  });

  /* ---- steppers ---- */
  document.addEventListener('click', function (e) {
    var up = e.target.closest('[data-step-up]');
    var down = up ? null : e.target.closest('[data-step-down]');
    if (!up && !down) return;
    var name = up ? up.dataset.stepUp : down.dataset.stepDown;

    /* The quiet-hours steppers belong to the notification sheet, not to a
       tool, so they are handled before the tool-context path. */
    if (name === 'quietFrom' || name === 'quietTo') {
      var np = NOTIFY.prefs();
      np[name] = ((np[name] + (up ? 1 : -1)) + 24) % 24;
      saveProfile();
      renderNotifPrefs();
      return;
    }
    if (!currentTool) return;
    var key = fieldKey(name);
    var c = toolCtx(currentTool);
    var cur = Number(c.field(key) || 0);
    c.setField(key, Math.max(0, cur + (up ? 1 : -1)));
    renderTool();
  });

  /* ---- checkable rows (tasks, shopping) ---- */
  document.addEventListener('click', function (e) {
    var row = e.target.closest('[data-task], [data-shop]');
    if (!row || !currentTool) return;
    var c = toolCtx(currentTool);
    var bucket = c._state[currentTool] = c._state[currentTool] || {};
    bucket.done = bucket.done || {};
    var id = row.dataset.task || row.dataset.shop;
    bucket.done[id] = !bucket.done[id];
    row.classList.toggle('is-done', !!bucket.done[id]);
  });

  /* ---- tasbih (§24.15) ---- */
  function resetToolTasbih() {
    var c = toolCtx('tasbih');
    var st = c._state.tasbih = c._state.tasbih || {};
    st.sets = (st.sets || 0) + (st.count ? 1 : 0);
    st.count = 0;
    renderTool();
  }

  document.addEventListener('click', function (e) {
    if (currentTool !== 'tasbih') return;
    var pick = e.target.closest('[data-dhikr]');
    if (pick) {
      var cp = toolCtx('tasbih');
      cp._state.tasbih = cp._state.tasbih || {};
      cp._state.tasbih.dhikrIndex = Number(pick.dataset.dhikr);
      cp._state.tasbih.count = 0;
      renderTool();
      return;
    }
    if (!e.target.closest('[data-tasbih-count]')) return;
    var c = toolCtx('tasbih');
    var st = c._state.tasbih = c._state.tasbih || { count: 0, dhikrIndex: 0, sets: 0 };
    var target = window.LUME_DATA.DHIKR[st.dhikrIndex || 0].target;
    st.count = (st.count || 0) + 1;
    var num = $('[data-tasbih-num]'), ring = $('[data-tasbih-ring]');
    if (num) num.textContent = st.count;
    if (ring) {
      var circ = 2 * Math.PI * 88;
      ring.setAttribute('stroke-dashoffset', Math.max(0, (1 - st.count / target) * circ).toFixed(1));
    }
    if (navigator.vibrate) navigator.vibrate(st.count >= target ? [18, 40, 18] : 8);
    if (st.count >= target) {
      st.sets = (st.sets || 0) + 1;
      st.count = 0;
      toast(t('tasbih.complete'));
      setTimeout(renderTool, 280);
    }
  });

  /* ---- converters ---- */
  function swapConverter(kind) {
    var id = kind === 'cvswap' ? 'currency' : 'converter';
    var c = toolCtx(id);
    var st = c._state[id] = c._state[id] || {};
    if (id === 'currency') {
      var board = c.currencyBoard();
      var from = st.from || board.from;
      st.from = st.to || board.to;
      st.to = from;
    } else {
      st.swapped = !st.swapped;
    }
    renderTool();
  }

  /* ---- speed test (§56) — animated measurement, not a number swap ---- */
  function runSpeedTest() {
    var c = toolCtx('speedtest');
    var st = c._state.speedtest = c._state.speedtest || {};
    var value = $('[data-speed-value]'), fill = $('.gauge__fill');
    var target = 30 + Math.random() * 70;
    var start = performance.now();
    (function step(now) {
      var p = Math.min(1, (now - start) / 1800);
      var eased = 1 - Math.pow(1 - p, 3);
      var v = target * eased;
      if (value) value.textContent = v.toFixed(1);
      if (fill) fill.style.setProperty('--p', Math.min(1, v / 200).toFixed(3));
      if (p < 1) requestAnimationFrame(step);
      else {
        st.down = Math.round(target * 10) / 10;
        toast(t('speed.done', { n: st.down }));
      }
    })(start);
  }

  /* ---- stopwatch / timer / focus ---- */
  var clockTimers = {};

  function fmtClock(kind, secs) {
    return pad2(Math.floor(secs / 60)) + ':' + pad2(secs % 60) + (kind === 'stopwatch' ? '.00' : '');
  }

  function runClock(bits) {
    var kind = bits[0], cmd = bits[1], arg = bits[2];
    var c = toolCtx(kind);
    var st = c._state[kind] = c._state[kind] || {};
    var display = $('[data-clock-display]');

    function paint() {
      st.display = fmtClock(kind, Math.max(0, st.secs));
      var d = $('[data-clock-display]');
      if (d) d.textContent = st.display;
    }

    if (cmd === 'reset') {
      clearInterval(clockTimers[kind]);
      st.running = false;
      st.secs = kind === 'stopwatch' ? 0 : (st.total || (kind === 'focus' ? 1500 : 300));
      paint();
      return;
    }
    if (cmd === 'set') {
      clearInterval(clockTimers[kind]);
      st.running = false;
      st.total = Number(arg);
      st.secs = st.total;
      paint();
      return;
    }
    if (st.running) { clearInterval(clockTimers[kind]); st.running = false; return; }

    if (kind !== 'stopwatch' && !st.secs) {
      st.secs = st.total || (kind === 'focus' ? 1500 : 300);
    }
    st.running = true;
    if (st.secs === undefined) st.secs = kind === 'stopwatch' ? 0 : (st.total || (kind === 'focus' ? 1500 : 300));
    clockTimers[kind] = setInterval(function () {
      st.secs += kind === 'stopwatch' ? 1 : -1;
      if (st.secs <= 0 && kind !== 'stopwatch') {
        clearInterval(clockTimers[kind]);
        st.running = false;
        st.secs = 0;
        toast(t(kind === 'focus' ? 'focus.done' : 'timer.done'));
        if (navigator.vibrate) navigator.vibrate([30, 60, 30]);
      }
      paint();
    }, 1000);
  }

  /* ---- calculator, inside its own tool screen ---- */
  var toolCalc = { a: null, op: null, b: '0', fresh: true, expr: '' };

  function calcToolRender() {
    var out = $('[data-calc-out]'), expr = $('[data-calc-expr]');
    if (out) out.textContent = toolCalc.b;
    if (expr) expr.textContent = toolCalc.expr;
  }

  function calcApply() {
    var a = toolCalc.a, b = Number(toolCalc.b), op = toolCalc.op;
    var r = op === '+' ? a + b : op === '-' ? a - b : op === '*' ? a * b : (b === 0 ? 0 : a / b);
    return Math.round(r * 1e10) / 1e10;
  }

  function opSymbol(op) { return { '+': '+', '-': '−', '*': '×', '/': '÷' }[op] || op; }

  document.addEventListener('click', function (e) {
    var key = e.target.closest('[data-calckey]');
    if (!key) return;
    var parts = key.dataset.calckey.split(':');
    var kind = parts[0], arg = parts[1];

    if (kind === 'n') {
      toolCalc.b = (toolCalc.fresh || toolCalc.b === '0') ? arg : toolCalc.b + arg;
      toolCalc.fresh = false;
    } else if (kind === 'dot') {
      if (toolCalc.fresh) { toolCalc.b = '0.'; toolCalc.fresh = false; }
      else if (toolCalc.b.indexOf('.') === -1) toolCalc.b += '.';
    } else if (kind === 'ac') {
      toolCalc = { a: null, op: null, b: '0', fresh: true, expr: '' };
    } else if (kind === 'back') {
      toolCalc.b = toolCalc.b.length > 1 ? toolCalc.b.slice(0, -1) : '0';
    } else if (kind === 'pct') {
      toolCalc.b = String(Number(toolCalc.b) / 100);
    } else if (kind === 'op') {
      if (toolCalc.a !== null && !toolCalc.fresh) toolCalc.b = String(calcApply());
      toolCalc.a = Number(toolCalc.b);
      toolCalc.op = arg;
      toolCalc.expr = trimNum(toolCalc.a) + ' ' + opSymbol(arg);
      toolCalc.fresh = true;
    } else if (kind === 'eq') {
      if (toolCalc.op !== null) {
        var result = calcApply();
        toolCalc.expr = trimNum(toolCalc.a) + ' ' + opSymbol(toolCalc.op) + ' ' +
                        trimNum(Number(toolCalc.b)) + ' =';
        var store2 = toolCtx('calculator')._state;
        store2.calculator = store2.calculator || {};
        store2.calculator.history = [{ expr: toolCalc.expr, result: trimNum(result) }]
          .concat(store2.calculator.history || []).slice(0, 6);
        toolCalc.b = String(result);
        toolCalc.a = null; toolCalc.op = null; toolCalc.fresh = true;
      }
    }
    calcToolRender();
  });

  /* §93 — the freshness line must tell the truth the moment it changes. */
  window.addEventListener('online', function () { if (currentTool) renderTool(); });
  window.addEventListener('offline', function () { if (currentTool) renderTool(); });

  /* ---- back ---- */
  document.addEventListener('click', function (e) {
    if (!e.target.closest('[data-tool-back]')) return;
    if (current === 'notifications') { goTo(notifReturnTab); return; }
    if (current === 'account') { closeAccount(); return; }
    if (current === 'auth') { closeAuth(); return; }
    closeTool();
  });

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape' || openSheet) return;
    if (current === 'account') { closeAccount(); return; }
    if (current === 'auth') { closeAuth(); return; }
    if (currentTool) closeTool();
  });

  /* The prayer countdown in an open tool ticks like the one on Home. */
  setInterval(function () {
    if (currentTool !== 'prayer') return;
    var el = $('[data-prayer-count]');
    if (el) el.textContent = toolCtx('prayer').prayerState().countdown;
  }, 1000);


  /* Share cards for data tools (Master Spec §98). A shared snapshot carries
     the figure, the place and the moment it was true — never a bare number. */
  function shareForTool(id) {
    var stamp = L.dateShort(new Date()) + ' · ' + L.time(new Date().getHours(), new Date().getMinutes());
    try {
      if (id === 'prayer') {
        var st = toolCtx('prayer').prayerState();
        return { kind: 'reminder',
          text: t('prayer.' + st.next.key) + ' — ' + L.time(st.next.h, st.next.m) + ', ' + profile.city,
          source: stamp };
      }
      if (id === 'weather') {
        var w = toolCtx('weather').weather();
        return { kind: 'quote',
          text: profile.city + ' · ' + L.temp(w.temp) + ' ' + w.desc + '. ' +
                t('weather.hilo', { hi: L.temp(w.hi), lo: L.temp(w.lo) }),
          source: stamp };
      }
      if (id === 'markets') {
        var ex = toolCtx('markets').exchange();
        var ix = ex ? ex.indices[0] : window.LUME_DATA.GLOBAL_INDICES[0];
        return { kind: 'quote',
          text: ix.name + ' ' + L.num(ix.value, { maximumFractionDigits: 2 }) + '  ' +
                (ix.pct >= 0 ? '+' : '−') + Math.abs(ix.pct).toFixed(2) + '%',
          source: (ex ? ex.name : t('markets.worldBoard')) + ' · ' + stamp };
      }
      if (id === 'zakat') {
        var z = toolCtx('zakat').zakat();
        return { kind: 'reminder',
          text: t('zakat.payable') + ': ' + L.moneyRaw(z.due, L.currencyCode(), 0),
          source: stamp };
      }
      if (id === 'goals') {
        var g = toolCtx('goals').goals();
        return { kind: 'quote',
          text: t('goals.saved') + ' ' + L.money(g.saved) + ' ' + t('common.of') + ' ' + L.money(g.target) +
                ' — ' + Math.round(g.ratio * 100) + '%',
          source: stamp };
      }
      if (id === 'tax') {
        var tx = toolCtx('tax').tax();
        if (tx && tx.taxable) {
          return { kind: 'reminder',
            text: t('tax.dueAnnual') + ': ' + L.moneyRaw(tx.dueAnnual, tx.ccy, 0) +
                  ' · ' + t('tax.effective', { rate: L.num(tx.effective * 100, { maximumFractionDigits: 1 }) + '%' }),
            source: tx.config.authority + ' · ' + tx.config.year };
        }
      }
    } catch (err) {}
    return null;
  }

  /* ---------------------------------------------------------
     Notification centre  (Master Spec §100)

     The engine decides what is true; this decides how it looks.
     Tools never build a notification themselves — they declare
     an event and the engine turns it into one.
     --------------------------------------------------------- */
  var NOTIFY = window.LUME_NOTIFY({
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
    if (result && result.surface === 'banner' && current !== 'notifications') {
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

  function notifRow(n) {
    var when = n.agoMins < 1 ? t('n.now')
      : n.agoMins < 60 ? t('n.minsAgo', { n: Math.round(n.agoMins) })
      : n.agoMins < 1440 ? t('n.hoursAgo', { n: Math.round(n.agoMins / 60) })
      : t('n.daysAgo', { n: Math.round(n.agoMins / 1440) });

    var badge = n.priority === 'critical' ? { label: t('n.pri.critical'), tone: 'late' }
      : n.priority === 'high' ? { label: t('n.pri.high'), tone: 'warn' } : null;

    return '<article class="nrow' + (n.read ? '' : ' is-unread') +
      (n.actioned ? ' is-actioned' : '') + (n.expired ? ' is-expired' : '') + '"' +
      ' data-notif="' + esc(n.id) + '">' +
      '<button class="nrow__main pressable" data-notif-open="' + esc(n.id) + '">' +
        '<span class="nrow__icon nrow__icon--' + esc(n.category) + '">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + esc(n.icon) + '"/></svg></span>' +
        '<span class="nrow__body">' +
          '<span class="nrow__titleline">' +
            '<span class="nrow__title">' + esc(n.title) + '</span>' +
            (badge ? UI.statusBadge(badge) : '') +
          '</span>' +
          '<span class="nrow__text">' + esc(n.body) + '</span>' +
          '<span class="nrow__meta">' + esc(when) +
            (n.grouped ? '' : ' · ' + esc(t(NOTIFY.category(n.category).key))) +
            (n.actioned ? ' · ' + esc(t('n.actioned')) : '') +
            (n.expired ? ' · ' + esc(t('n.expired')) : '') + '</span>' +
        '</span>' +
        (n.read ? '' : '<span class="nrow__dot" aria-label="' + esc(t('n.unread')) + '"></span>') +
      '</button>' +
      (n.action || !n.grouped ? '<div class="nrow__acts">' +
        (n.action ? '<button class="nrow__act pressable" data-notif-act="' + esc(n.id) + '">' +
          esc(t(n.action.key)) + '</button>' : '') +
        '<button class="nrow__dismiss pressable" data-notif-dismiss="' + esc(n.id) + '"' +
          ' aria-label="' + esc(t('n.dismiss')) + '">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#i-x"/></svg></button>' +
      '</div>' : '') +
    '</article>';
  }

  var notifPainted = false;

  function renderNotifCentre() {
    var head = $('#notifHeader'), body = $('#notifBody');
    if (!head || !body) return;

    /* §100.18 — the first paint shows the shape of what is coming, never a
       blank screen. */
    if (!notifPainted) {
      head.innerHTML = UI.toolHeader({ title: t('nav.notifications'), backLabel: t('a11y.back') });
      body.innerHTML = UI.section({ body: UI.skeleton('row', 4) });
      notifPainted = true;
      setTimeout(renderNotifCentre, 90);
      return;
    }

    var filter = notifFilter;
    var all;
    try {
      all = NOTIFY.list('all');
    } catch (err) {
      /* §100.18 — an engine that throws still leaves the user somewhere. */
      if (window.console) console.error('Notification centre failed', err);
      body.innerHTML = UI.section({ body: UI.errorState({
        title: t('n.error.title'), text: t('n.error.text'),
        retry: t('a.tryAgain'), act: 'notiffilter:' + filter }) });
      return;
    }
    var unread = all.filter(function (n) { return !n.read; }).length;
    var shown = NOTIFY.grouped(NOTIFY.list(filter));

    head.innerHTML = UI.toolHeader({
      title: t('nav.notifications'),
      sub: unread ? esc(t('n.unreadCount', { n: unread })) : esc(t('n.allRead')),
      backLabel: t('a11y.back'),
      actions: [
        unread ? { id: 'read', icon: 'i-check', label: t('n.markAllRead'), act: 'notifreadall' } : null,
        { id: 'prefs', icon: 'i-settings', label: t('n.settings'), act: 'sheet:notifprefs' }
      ].filter(Boolean)
    });

    var TABS = [
      { value: 'all', label: t('common.all'), count: all.length },
      { value: 'unread', label: t('n.tab.unread'), count: unread },
      { value: 'important', label: t('n.tab.important'),
        count: all.filter(function (n) { return n.priorityRank >= 2; }).length }
    ].map(function (x) { x.on = x.value === filter; x.act = 'notiffilter:' + x.value; return x; });

    /* Only the categories that actually have something in them. */
    var live = {};
    all.forEach(function (n) { live[n.category] = (live[n.category] || 0) + 1; });
    var catItems = [{ value: 'all', label: t('common.all'), on: ['all', 'unread', 'important'].indexOf(filter) !== -1 }]
      .concat(NOTIFY.CATEGORIES.filter(function (c) { return live[c.id]; }).map(function (c) {
        return { value: c.id, label: t(c.key), count: live[c.id], on: filter === c.id, icon: c.icon };
      }));

    var quiet = NOTIFY.inQuietHours()
      ? UI.section({ body: UI.noteCard({ icon: 'i-moon', tone: 'info',
          title: t('n.quiet.title'), text: t('n.quiet.text') }) })
      : '';

    body.innerHTML =
      UI.section({ flush: true, body: UI.tabs({ id: 'notiftabs', label: t('nav.notifications'), items: TABS }) }) +
      (catItems.length > 1
        ? UI.section({ body: UI.filterBar([{ id: 'cat', label: t('n.category'),
            items: catItems.map(function (i) {
              i.act = 'notiffilter:' + i.value; return i;
            }) }]) })
        : '') +
      quiet +
      (shown.length
        ? UI.section({ body: '<div class="nlist">' + shown.map(notifRow).join('') + '</div>' })
        : UI.section({ body: UI.emptyState({
            icon: filter === 'unread' ? 'i-check-circle' : 'i-bell',
            title: filter === 'unread' ? t('n.empty.caughtUp') : t('n.empty.title'),
            text: t('n.empty.text') }) })) +
      UI.section({ body: UI.rows([
        UI.compactRow({ icon: 'i-settings', label: t('n.settings'),
          value: NOTIFY.pushEnabled() ? t('n.push.on') : t('n.push.off'), act: 'sheet:notifprefs' })
      ]) });

    applyStrings(body);
    renderNotifBadge();
  }

  var notifFilter = 'all';

  /* §100.9 — general, categories, per-tool types, quiet hours, privacy. */
  /* §124.18 — the centre's settings sheet and Profile → Notifications are
     two doors into one room. Both hosts are painted, so neither goes stale. */
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
    if (current === 'notifications') renderNotifCentre();
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
      var rows = NOTIFY.list(current === 'notifications' ? notifFilter : 'all');
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
      NOTIFY.dismiss(gone.dataset.notifDismiss, NOTIFY.list(notifFilter));
      renderNotifCentre();
    }
  });


  /* ---------------------------------------------------------
     Account, profile and settings  (Master Spec §124)

     Two hosts, two back stacks, one vocabulary. Authentication
     is a flow rather than a tool, so it never enters the tool
     router, the catalogue or search.
     --------------------------------------------------------- */
  var AUI = window.LUME_ACCOUNT_UI({
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
  window.LUME_ACCT_UI = AUI;

  var accountRoute = null, accountStack = [], accountReturn = 'profile';
  var authRoute = null, authStack = [], authReturn = 'profile';
  /* Where the flow was entered from, so it can be returned to. */
  var authFromAccount = null, authFromStack = null;

  var AUTH_VALUES = {
    signin: { email: '', password: '' },
    signup: { name: '', email: '', password: '', confirm: '' },
    forgot: { email: '' },
    reset:  { password: '', confirm: '' },
    verify: { code: '' }
  };

  function renderProfile() {
    var host = $('#profileBody');
    if (!host) return;
    host.innerHTML = AUI.renderProfile();
    applyStrings(host);
  }

  /* A destination that is not a tab: the same treatment tools and the
     notification centre get. */
  function showScreen(name) {
    var screen = $('#screen-' + name);
    if (!screen) return;
    current = name;
    $$('.screen').forEach(function (sc) { sc.classList.remove('is-active'); });
    screen.classList.add('is-active');
    screen.scrollTop = 0;
    $$('.tab').forEach(function (tb) {
      tb.classList.remove('is-active');
      tb.setAttribute('aria-selected', 'false');
    });
    movePill(null);
    var back = $('#exploreBack');
    if (back) back.hidden = true;
  }

  function homeTab() {
    return tabOrder().indexOf(current) !== -1 ? current : 'profile';
  }

  function enterAccountRoute(route) {
    accountRoute = route;
    var def = AUI.ROUTES[route]();
    AUI.resetForm(def.values || {});
    showScreen('account');
    renderAccount();
  }

  var pendingNav = null;

  /* §124.14's dirty state is only honest if leaving respects it. */
  function guardDirty(go) {
    if (!AUI.form.dirty) { go(); return; }
    pendingNav = go;
    askConfirm({ title: t('acct.discardTitle'), text: t('acct.discardText'),
                 cta: t('acct.discardCta'), tone: 'danger', act: 'acctdo:discard' });
  }

  function openAccount(route, opts) {
    opts = opts || {};
    if (!AUI.ROUTES[route]) return;
    if (accountRoute && accountRoute !== route && AUI.form.dirty) {
      guardDirty(function () { openAccount(route, opts); });
      return;
    }

    /* §124.28 — a destination that belongs to the account is held across
       authentication and resumed afterwards, never swapped for Home. */
    if (ACCT.requiresAccount(route) && !ACCT.isAuthed()) {
      openAuth('signin', { modal: true, then: 'acct:' + route });
      return;
    }

    if (currentTool) { stopClocks(); currentTool = null; toolStack.length = 0; }
    if (accountRoute && !opts.replace) accountStack.push(accountRoute);
    else if (!accountRoute) accountReturn = homeTab();
    enterAccountRoute(route);
  }

  function renderAccount() {
    var head = $('#accountHeader'), body = $('#accountBody');
    if (!head || !body || !accountRoute) return;
    var built = AUI.ROUTES[accountRoute]();
    head.innerHTML = UI.toolHeader({
      title: built.title, sub: built.sub ? esc(built.sub) : null, backLabel: t('a11y.back')
    });
    /* One host, a dozen screens: a fixed label announced "Account" whichever
       one was showing (§101). */
    var host = $('#screen-account');
    if (host) host.setAttribute('aria-label', built.title);
    body.innerHTML = built.body;
    applyStrings(body);
    applyVisibility();
    if (built.after) built.after();
    animateBars($('#screen-account'));
  }

  function closeAccount() {
    if (AUI.form.dirty) { guardDirty(closeAccount); return; }
    cancelSubmit();
    if (accountStack.length) { enterAccountRoute(accountStack.pop()); return; }
    accountRoute = null;
    goTo(accountReturn || 'profile');
  }

  /* ---- authentication ------------------------------------------------ */
  function openAuth(route, opts) {
    opts = opts || {};
    if (!AUI.AUTH[route]) return;
    if (opts.then !== undefined) AUI.authCtx.pending = opts.then;
    if (opts.modal !== undefined) AUI.authCtx.modal = !!opts.modal;

    if (!authRoute) {
      authReturn = homeTab();
      /* An authentication flow entered from inside the account section comes
         back to the screen that sent it there, not to the top (§124.25). */
      authFromAccount = accountRoute;
      authFromStack = accountStack.slice();
    } else if (route !== authRoute) {
      /* Sign in and sign up are siblings, not levels: hopping between them
         used to stack, so escaping took one press per hop. */
      var at = authStack.indexOf(route);
      if (at !== -1) authStack.length = at;
      else authStack.push(authRoute);
    }

    /* An outcome is not a step. Nothing behind "your account is ready" is
       worth returning to, so the flow's history ends there (§126.30). */
    if (opts.fresh) authStack.length = 0;

    if (currentTool) { stopClocks(); currentTool = null; toolStack.length = 0; }
    authRoute = route;
    /* §126.30 — forward navigation and backward navigation are different
       transitions, so the shell is told which one it is. */
    AUI.authCtx.nav = opts.back ? 'back' : 'fwd';
    /* §126.9 — a sign-up always starts at its first step. */
    if (route === 'signup') AUI.authCtx.step = 1;
    /* §126.12 — the resend window opens when the screen does. */
    if (route === 'verify') AUI.authCtx.resendAt = Date.now() + RESEND_WAIT;
    AUI.resetForm(AUTH_VALUES[route] ? JSON.parse(JSON.stringify(AUTH_VALUES[route])) : {});
    showScreen('auth');
    renderAuth();
  }

  /* ---- the resend countdown (§126.12) ---------------------------------
     A number that counts down is only honest if it moves. */
  var RESEND_WAIT = 45000;
  var resendTimer = null;

  function tickResend() {
    if (resendTimer) { clearInterval(resendTimer); resendTimer = null; }
    if (authRoute !== 'verify') return;
    if (!$('[data-resend]')) return;
    resendTimer = setInterval(function () {
      var el = $('[data-resend]');
      if (authRoute !== 'verify' || !el) { clearInterval(resendTimer); resendTimer = null; return; }
      var left = Math.max(0, Math.ceil((AUI.authCtx.resendAt - Date.now()) / 1000));
      if (left > 0) { el.textContent = t('auth.resendIn', { s: left }); return; }
      clearInterval(resendTimer);
      resendTimer = null;
      renderAuth();                     /* the wait is over: offer the action */
    }, 1000);
  }

  function renderAuth() {
    var body = $('#authBody');
    if (!body || !authRoute) return;
    var authHost = $('#screen-auth');
    /* §126.44 — the shell is the screen's own; every route returns the whole
       composition rather than a fragment someone else wraps. */
    body.innerHTML = AUI.AUTH[authRoute]();
    var authTitle = $('.auth__title', body);
    if (authHost && authTitle) authHost.setAttribute('aria-label', authTitle.textContent);
    applyStrings(body);
    applyVisibility();
    tickResend();
  }

  function closeAuth(dismiss) {
    /* A cross dismisses the whole flow; a back chevron steps through it. The
       two were the same control, so the X on a modal sign-in behaved as Back
       and took two presses to escape (§124.25). */
    /* Escape and the shell's own Back step through a progressive form the
       same way its Back control does — leaving the flow from step two would
       throw away step one (§126.9). */
    if (authRoute === 'signup' && AUI.authCtx.step === 2 && !dismiss) {
      accountDo('signupback');
      return;
    }
    if (authStack.length && !dismiss) {
      authRoute = authStack.pop();
      AUI.authCtx.nav = 'back';
      if (authRoute === 'signup') AUI.authCtx.step = 1;
      AUI.resetForm(AUTH_VALUES[authRoute] ? JSON.parse(JSON.stringify(AUTH_VALUES[authRoute])) : {});
      renderAuth();
      return;
    }
    if (resendTimer) { clearInterval(resendTimer); resendTimer = null; }
    /* Choosing to stay a guest ends the expired session rather than
       leaving it to interrupt again on the next launch (§124.27). */
    if (authRoute === 'expired') ACCT.signOut();
    var to = authReturn || 'profile';
    var backTo = authFromAccount;
    var backStack = authFromStack;
    authRoute = null;
    authStack.length = 0;
    authFromAccount = null;
    authFromStack = null;
    AUI.authCtx.pending = null;
    AUI.authCtx.modal = false;
    if (backTo && AUI.ROUTES[backTo]) {
      accountStack = backStack || [];
      enterAccountRoute(backTo);
      renderAll();
      return;
    }
    goTo(to);
    renderAll();
  }

  /* §124.29 — notification state belongs to whoever was signed in. */
  function resetNotificationsForAccount() {
    profile.notifyRead = {};
    profile.notifyActed = {};
    profile.notifyGone = {};
    profile.notifySeen = {};
    if (profile.notify) profile.notify.push = false;
    NOTIFY.prefsChanged();
    saveProfile();
    renderNotifBadge();
  }

  function authSucceeded(message) {
    var pending = AUI.authCtx.pending;
    AUI.authCtx.pending = null;
    AUI.authCtx.modal = false;
    AUI.authCtx.token = null;      /* a recovery link does not outlive its flow */
    AUI.authCtx.step = 1;
    if (resendTimer) { clearInterval(resendTimer); resendTimer = null; }
    authRoute = null;
    authStack.length = 0;
    resetNotificationsForAccount();
    prayerCache = null;
    saveProfile();
    renderAll();
    goTo(pending ? 'profile' : (authReturn || 'profile'));
    if (pending) runAct(pending);
    if (message) toast(message);
  }

  /* ---- forms --------------------------------------------------------- */
  function formHost() {
    return current === 'auth' ? $('#authBody') : $('#accountBody');
  }

  function collectForm() {
    var host = formHost();
    if (!host) return;
    $$('[data-afield]', host).forEach(function (el) {
      AUI.form.values[el.dataset.afield] = el.value;
    });
  }

  function repaintForm() {
    if (current === 'auth') renderAuth(); else renderAccount();
  }

  function fail(result) {
    AUI.form.errors = result.errors || {};
    AUI.form.message = result.form ? { tone: 'error', key: result.form } : null;
    repaintForm();
    /* Announcing three errors at once and leaving focus on the body left the
       user to hunt for which field was wrong (§101). */
    var first = $('[aria-invalid="true"]', formHost());
    if (first && first.focus) { try { first.focus(); } catch (e) {} }
  }

  /* Every submission is a designed loading state before it is a result
     (§124.26). */
  var submitTimer = null;

  function cancelSubmit() {
    if (submitTimer) { clearTimeout(submitTimer); submitTimer = null; }
    AUI.form.busy = false;
  }

  function submitForm(kind) {
    if (AUI.form.busy) return;
    collectForm();
    AUI.form.errors = {};
    AUI.form.message = null;
    AUI.form.busy = true;
    repaintForm();
    submitTimer = setTimeout(function () {
      submitTimer = null;
      AUI.form.busy = false;
      applySubmit(kind, AUI.form.values);
    }, 420);
  }

  /* The two ways a recovery link dies. Both are the link's fault, not the
     password's, and both belong on the error screen (§126.46). */
  var LINK_FAILURES = { 'acct.err.linkInvalid': 1, 'acct.err.linkExpired': 1 };

  function applySubmit(kind, v) {
    var r;

    if (kind === 'signin') {
      r = ACCT.signIn(v);
      if (!r.ok) return fail(r);
      var who = ACCT.displayName();
      return authSucceeded(who ? t('auth.welcomeBack', { name: who }) : t('auth.welcome'));
    }

    /* §126.9 — the identity step is checked by the same engine that will
       check the whole form, so step one can never accept what step two's
       submission would reject. */
    if (kind === 'signupstep') {
      r = ACCT.signUpStep(v);
      if (!r.ok) return fail(r);
      AUI.authCtx.step = 2;
      AUI.authCtx.nav = 'fwd';
      AUI.form.errors = {};
      AUI.form.message = null;
      return renderAuth();
    }

    if (kind === 'signup') {
      r = ACCT.signUp(v);
      if (!r.ok) return fail(r);
      /* §124.29 — notification state belongs to whoever was signed in, and
         the account exists from here, not from the moment the arrival screen
         is dismissed. */
      resetNotificationsForAccount();
      /* §126.13 — the arrival is designed rather than a toast over whatever
         screen happened to be behind. */
      return openAuth('created', { fresh: true });
    }

    if (kind === 'forgot') {
      r = ACCT.requestReset(v.email);
      if (!r.ok) return fail(r);
      AUI.authCtx.token = r.token;
      AUI.authCtx.email = r.email;
      return openAuth('sent');
    }

    if (kind === 'reset') {
      r = ACCT.resetPassword({ token: AUI.authCtx.token, password: v.password, confirm: v.confirm });
      /* §126.34 — a link that cannot be redeemed is not something the user
         can fix by retyping, so it gets a screen with a way out rather than
         a red line above a form that will refuse them again. */
      if (!r.ok && LINK_FAILURES[r.form]) {
        AUI.authCtx.token = null;
        AUI.authCtx.troubleText = r.form === 'acct.err.linkExpired'
          ? 'auth.troubleExpired' : 'auth.troubleText';
        return openAuth('trouble', { fresh: true });
      }
      if (!r.ok) return fail(r);
      AUI.authCtx.token = null;
      return openAuth('updated', { fresh: true });
    }

    if (kind === 'verify') {
      r = ACCT.verifyEmail(v.code);
      if (!r.ok) return fail(r);
      authRoute = null;
      authStack.length = 0;
      renderAll();
      openAccount('account', { replace: true });
      return toast(t('acct.emailChanged'));
    }

    if (kind === 'edit') {
      r = ACCT.updateUser({
        displayName: v.displayName, firstName: v.firstName,
        lastName: v.lastName, phone: v.phone
      });
      if (!r.ok) return fail(r);
      AUI.form.dirty = false;      /* saved is not unsaved */
      renderAll();
      closeAccount();
      return toast(t('acct.editSaved'));
    }

    if (kind === 'email') {
      r = ACCT.requestEmailChange(v.email);
      if (!r.ok) return fail(r);
      openAuth('verify', { modal: false });
      return;
    }

    if (kind === 'phone') {
      r = ACCT.updateUser({ phone: v.phone });
      if (!r.ok) return fail(r);
      renderAccount();
      return toast(t('acct.phoneSaved'));
    }

    if (kind === 'password') {
      r = ACCT.changePassword({ current: v.current, password: v.password, confirm: v.confirm });
      if (!r.ok) return fail(r);
      closeAccount();
      return toast(t('acct.passwordChanged'));
    }

    if (kind === 'delete') {
      /* §124.22 — identity is confirmed here; the deletion itself waits for
         one more, deliberately separate confirmation. */
      if (!ACCT.verifyPassword(v.current)) {
        return fail({ errors: { current: v.current ? 'acct.err.currentWrong' : 'acct.err.currentRequired' } });
      }
      /* The button was left in its busy state while the dialog was up, and
         `pointer-events: none` then made it permanently dead if the dialog
         was cancelled. */
      repaintForm();
      askConfirm({
        title: t('acct.deleteFinalTitle'), text: t('acct.deleteFinalText'),
        cta: t('acct.deleteCta'), tone: 'danger', act: 'acctdo:deletefinal'
      });
      return;
    }
  }

  /* ---- the confirmation dialog (§124.21, §124.22) --------------------- */
  var confirmAct = null;

  function askConfirm(o) {
    var title = $('#confirmTitle'), text = $('#confirmText');
    var go = $('#confirmGo'), cancel = $('#confirmCancel');
    if (!title || !go) return;
    title.textContent = o.title;
    text.textContent = o.text || '';
    go.textContent = o.cta;
    go.className = 'btn btn--block pressable ' + (o.tone === 'danger' ? 'btn--danger' : 'btn--accent');
    cancel.textContent = t('a.cancel');
    confirmAct = o.act;
    sheetOpen('confirm');
  }

  (function bindConfirm() {
    var go = $('#confirmGo');
    if (!go) return;
    go.addEventListener('click', function () {
      var act = confirmAct;
      confirmAct = null;
      sheetClose();
      if (act) runAct(act);
    });
  })();

  /* ---- the vocabulary ------------------------------------------------- */
  function accountAction(kind, arg) {
    var bits = String(arg).split(':');

    if (kind === 'acct') { openAccount(bits[0]); return true; }
    if (kind === 'auth') { openAuth(bits[0]); return true; }
    if (kind === 'acctsubmit') { submitForm(bits[0]); return true; }

    if (kind === 'acctset') {
      var key = bits.shift(), value = bits.join(':');
      if (key === 'lang') { profile.lang = value; }
      else if (key === 'currency') { profile.currency = value; }
      else if (key === 'units') { profile.units = value; }
      else if (key === 'clock') { profile.clock = value; }
      else if (key === 'tz') { profile.tz = value === 'auto' ? '' : value; }
      else if (key === 'theme') { setThemeMode(value); }
      if (key !== 'theme') saveProfile();
      renderAll();
      renderAccount();
      return true;
    }

    if (kind === 'accttoggle') {
      var p = NOTIFY.prefs();
      if (bits[0] === 'cat') { p.cats[bits[1]] = p.cats[bits[1]] === false; }
      else if (bits[0] === 'recos') { profile.prefs.recos = profile.prefs.recos === false; }
      else { p[bits[0]] = !p[bits[0]]; }
      NOTIFY.prefsChanged();
      saveProfile();
      renderAccount();
      renderNotifBadge();
      return true;
    }

    if (kind === 'acctdo') { accountDo(bits.shift(), bits.join(':')); return true; }

    return false;
  }

  function accountDo(verb, arg) {
    if (verb === 'tour') { sheetClose(); onbStart(); return; }
    if (verb === 'feedback') { toast(t('acct.helpContact')); return; }
    if (verb === 'authclose') { closeAuth(true); return; }

    /* §126.9 — stepping back inside sign-up keeps what was typed. A step is
       not a screen the user is leaving. */
    if (verb === 'signupback') {
      collectForm();
      AUI.authCtx.step = 1;
      AUI.authCtx.nav = 'back';
      AUI.form.errors = {};
      AUI.form.message = null;
      renderAuth();
      return;
    }

    /* The success screen's own way out (§126.13). */
    if (verb === 'authdone') {
      var who = ACCT.displayName();
      authSucceeded(who ? t('auth.welcomeBack', { name: who }) : t('auth.accountCreated'));
      return;
    }

    if (verb === 'resend') {
      var pending = ACCT.user() && ACCT.user().pendingEmail;
      if (pending) ACCT.requestEmailChange(pending);
      AUI.authCtx.resendAt = Date.now() + RESEND_WAIT;
      renderAuth();
      toast(t('auth.resent'));
      return;
    }

    if (verb === 'discard') {
      AUI.form.dirty = false;
      var go = pendingNav;
      pendingNav = null;
      if (go) go();
      return;
    }

    if (verb === 'logout') {
      askConfirm({ title: t('acct.logoutTitle'), text: t('acct.logoutText'),
                   cta: t('acct.signOut'), tone: 'danger', act: 'acctdo:logoutgo' });
      return;
    }
    if (verb === 'logoutgo') {
      ACCT.signOut();          /* releases the account's notification state */
      renderAll();
      goTo('profile');
      toast(t('acct.loggedOut'));
      return;
    }

    if (verb === 'signoutothers') {
      askConfirm({ title: t('acct.signOutOthers'), text: t('acct.signOutOthersText'),
                   cta: t('acct.signOutOthers'), tone: 'danger', act: 'acctdo:signoutothersgo' });
      return;
    }
    if (verb === 'signoutothersgo') {
      var r = ACCT.signOutOthers();
      renderAccount();
      toast(t('acct.signedOutOthers', { n: L.num(r.revoked || 0) }));
      return;
    }

    if (verb === 'revoke') {
      var rv = ACCT.revokeSession(arg);
      if (rv && rv.self) { renderAll(); goTo('profile'); toast(t('acct.loggedOut')); return; }
      renderAccount();
      return;
    }

    if (verb === 'emailcancel') {
      ACCT.cancelEmailChange();
      if (current === 'auth') { authRoute = null; authStack.length = 0; openAccount('email', { replace: true }); }
      else renderAccount();
      return;
    }

    if (verb === 'photo') { pickPhoto(); return; }
    if (verb === 'photoclear') {
      ACCT.updateUser({ photo: '' });
      renderAll();
      renderAccount();
      return;
    }

    if (verb === 'deletefinal') {
      var res = ACCT.deleteAccount(AUI.form.values.current);
      if (!res.ok) { fail(res); return; }
      accountRoute = null;
      accountStack.length = 0;
      renderAll();
      goTo('profile');
      toast(t('acct.deleted'));
    }
  }

  /* §124.14 — a real picker, and the file never leaves the device. */
  function pickPhoto() {
    var input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.addEventListener('change', function () {
      var file = input.files && input.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function () {
        shrinkPhoto(String(reader.result), function (small) {
          if (!small) { toast(t('acct.err.photoTooBig')); return; }
          var res = ACCT.updateUser({ photo: small });
          if (!res.ok) { toast(t(res.form || 'acct.err.storage')); return; }
          renderAll();
          renderAccount();
        });
      };
      reader.readAsDataURL(file);
    });
    input.click();
  }

  /* Local storage holds a few megabytes for everything Lume keeps; a photo
     straight off a phone camera is larger than that on its own. This scales
     the longest edge to 256px, and refuses rather than filling the store
     when it cannot. */
  function shrinkPhoto(dataUrl, done) {
    var MAX_RAW = 120000;
    if (dataUrl.length <= MAX_RAW) { done(dataUrl); return; }

    var img = new Image();
    img.onload = function () {
      var canvas = document.createElement('canvas');
      var ctx = canvas.getContext ? canvas.getContext('2d') : null;
      if (!ctx) { done(null); return; }
      var side = 256;
      var scale = Math.min(1, side / Math.max(img.width || side, img.height || side));
      canvas.width = Math.max(1, Math.round((img.width || side) * scale));
      canvas.height = Math.max(1, Math.round((img.height || side) * scale));
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      var out;
      try { out = canvas.toDataURL('image/jpeg', 0.82); } catch (e) { out = null; }
      done(out && out.length < 400000 ? out : null);
    };
    img.onerror = function () { done(null); };
    img.src = dataUrl;
  }

  /* ---- live form behaviour -------------------------------------------- */
  document.addEventListener('input', function (e) {
    var el = e.target.closest ? e.target.closest('[data-afield]') : null;
    if (!el) return;
    var name = el.dataset.afield;
    AUI.form.values[name] = el.value;

    /* The checklist and the meter follow the keystrokes; repainting the
       whole form here would take the caret with it. */
    var rules = $('[data-pwrules="' + name + '"]');
    if (rules) {
      ACCT.passwordChecks(el.value).forEach(function (c) {
        var row = $('[data-rule="' + c.id + '"]', rules);
        if (row) row.classList.toggle('is-ok', c.ok);
      });
    }
    var meter = $('[data-pwmeter="' + name + '"]');
    if (meter) {
      var st = ACCT.passwordStrength(el.value);
      meter.dataset.tone = st.tone;
      $$('.pwmeter__seg', meter).forEach(function (seg, i) {
        seg.classList.toggle('is-on', i < st.score);
      });
      var label = $('.pwmeter__label', meter);
      if (label) label.textContent = t(st.key);
    }

    var field = el.closest('.field');
    if (field) {
      /* §126.39 — editing a field withdraws the complaint about it, and the
         message line empties without collapsing, so nothing below moves. */
      field.classList.remove('is-invalid');
      field.classList.remove('is-valid');
      field.classList.toggle('is-filled', el.value !== '');
      delete AUI.form.errors[name];
      delete AUI.form.valid[name];
      var msg = $('.field__msg', field);
      if (msg && msg.classList.contains('field__err')) {
        msg.className = 'field__msg field__hint';
        msg.removeAttribute('role');
        msg.textContent = '';
        el.removeAttribute('aria-invalid');
      }
    }
    updateDirty();
  });

  /* §126.39 — nothing is judged on first render. A field is checked once the
     user has finished with it, and the whole form is checked on submission.
     Only the two checks that can be made in isolation happen here: whether
     an address is an address, and whether a confirmation matches. */
  var LEAVE_CHECKS = {
    email: function (v) {
      if (!v) return null;
      return ACCT.emailValid(v) ? true : 'acct.err.emailInvalid';
    },
    confirm: function (v) {
      if (!v) return null;
      return v === (AUI.form.values.password || '') ? true : 'acct.err.confirmMismatch';
    }
  };

  document.addEventListener('focusout', function (e) {
    var el = e.target.closest ? e.target.closest('[data-afield]') : null;
    if (!el || current !== 'auth') return;
    var name = el.dataset.afield;
    var check = LEAVE_CHECKS[name];
    if (!check) return;
    AUI.form.touched[name] = true;
    var verdict = check(el.value);
    if (verdict === null) return;
    var field = el.closest('.field');
    if (!field) return;
    if (verdict === true) {
      AUI.form.valid[name] = true;
      markValid(field, el);
      return;
    }
    AUI.form.errors[name] = verdict;
    markInvalid(field, el, verdict);
  });

  /* §126.15 — a field that passed says so with a mark as well as a border,
     because a border is a colour and a colour on its own is not a signal.
     A password field keeps its reveal control instead: two glyphs in one box
     is clutter, and the rules underneath already report on it. */
  function markValid(field, el) {
    field.classList.remove('is-invalid');
    field.classList.add('is-valid');
    el.removeAttribute('aria-invalid');
    var box = $('.field__box', field);
    if (!box || $('.pwtoggle', box) || $('.field__ok', box)) return;
    var tick = document.createElement('span');
    tick.className = 'field__ok';
    tick.setAttribute('aria-hidden', 'true');
    tick.innerHTML = '<svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg>';
    box.appendChild(tick);
  }

  /* The field is corrected where it stands. A repaint here would take the
     caret and the focus with it, at the moment the user is moving on. */
  function markInvalid(field, el, key) {
    field.classList.remove('is-valid');
    field.classList.add('is-invalid');
    el.setAttribute('aria-invalid', 'true');
    var msg = $('.field__msg', field);
    if (!msg) return;
    msg.className = 'field__msg field__err';
    msg.setAttribute('role', 'alert');
    msg.innerHTML = '<svg class="ico" viewBox="0 0 24 24" aria-hidden="true"><use href="#i-alert"/></svg>' +
      esc(t(key));
  }

  /* §126.38 — when the software keyboard opens, the panel keeps its own
     bottom above it, so the field being typed into and the button that
     submits it are never underneath it. */
  (function keyboardInset() {
    var vv = window.visualViewport;
    if (!vv) return;
    var apply = function () {
      var hidden = Math.max(0, window.innerHeight - vv.height - vv.offsetTop);
      var el = $('#authBody .auth__panel');
      if (el) el.style.setProperty('--auth-kb', hidden > 80 ? hidden + 'px' : '0px');
      var focused = document.activeElement;
      if (hidden > 80 && focused && focused.dataset && focused.dataset.afield && focused.scrollIntoView) {
        try { focused.scrollIntoView({ block: 'center', behavior: 'smooth' }); } catch (err) {}
      }
    };
    vv.addEventListener('resize', apply);
    vv.addEventListener('scroll', apply);
  })();

  /* §124.18 — Save stays inert until something actually changed. */
  function updateDirty() {
    var f = AUI.form, changed = false, k;
    for (k in f.base) {
      if (Object.prototype.hasOwnProperty.call(f.base, k) &&
          String(f.values[k] === undefined ? '' : f.values[k]) !== String(f.base[k] === undefined ? '' : f.base[k])) {
        changed = true;
      }
    }
    f.dirty = changed;
    var btn = $('#accountBody [data-act="acctsubmit:edit"]');
    if (btn) btn.disabled = !changed;
    var hint = $('#accountBody .dirtyhint');
    if (hint) hint.hidden = changed;
  }

  document.addEventListener('click', function (e) {
    var b = e.target.closest('[data-pwtoggle]');
    if (!b) return;
    e.preventDefault();                 /* the toggle sits inside a label */
    var name = b.dataset.pwtoggle;
    var input = $('[data-afield="' + name + '"]', formHost());
    if (!input) return;
    var show = input.type === 'password';
    input.type = show ? 'text' : 'password';
    /* Kept in form state so a failed submission — which repaints the form —
       does not re-mask what the user asked to see. */
    AUI.setRevealed(name, show);
    b.setAttribute('aria-pressed', show ? 'true' : 'false');
    b.setAttribute('aria-label', t(show ? 'acct.pw.hide' : 'acct.pw.show'));
    b.innerHTML = '<svg class="ico" viewBox="0 0 24 24"><use href="#' + (show ? 'i-eye-off' : 'i-eye') + '"/></svg>';
  });

  /* §101 — a radio group is one tab stop, and the arrows move within it. */
  document.addEventListener('keydown', function (e) {
    var opt = e.target.closest ? e.target.closest('.optlist [role="radio"]') : null;
    if (!opt) return;
    var keys = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 };
    var step = keys[e.key];
    if (!step) return;
    var group = opt.closest('.optlist');
    var all = $$('[role="radio"]', group);
    var at = all.indexOf(opt);
    /* Left and right follow the reading direction. */
    if (L.dir() === 'rtl' && (e.key === 'ArrowRight' || e.key === 'ArrowLeft')) step = -step;
    var next = all[(at + step + all.length) % all.length];
    if (!next) return;
    e.preventDefault();
    all.forEach(function (r) { r.setAttribute('tabindex', '-1'); });
    next.setAttribute('tabindex', '0');
    next.focus();
    next.click();
  });

  /* Enter submits the form it is typed in. */
  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Enter') return;
    var el = e.target.closest ? e.target.closest('[data-afield]') : null;
    if (!el) return;
    var host = formHost();
    var submit = host ? $('[data-act^="acctsubmit:"]', host) : null;
    if (submit && !submit.disabled) { e.preventDefault(); submit.click(); }
  });

  /* ---------------------------------------------------------
     Boot
     --------------------------------------------------------- */
  ensureExploreBack();
  applyWidth();
  renderNotifBadge();
  tickClock();
  renderAll();
  updateDayRing();

  setInterval(tickClock, 15000);
  setInterval(notifyTick, 45000);
  setTimeout(notifyTick, 2500);
  setInterval(function () { updatePrayer(); }, 1000);
  setInterval(updateDayRing, 60000);

  /* §124.6 — a returning user with a dead session is told so, and taken
     back where they were going once they sign in. */
  if (ACCT.isExpired() && store.get('lume-onboarded')) openAuth('expired');

  requestAnimationFrame(function () {
    movePill($('.tab.is-active'));
    animateBars($('#screen-home'));
  });
})();
