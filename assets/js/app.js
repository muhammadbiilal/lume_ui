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
    set: function (k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  };

  /* ---------------------------------------------------------
     Profile — the single source of personalisation
     --------------------------------------------------------- */
  var profile = {
    name: 'Zeeshan',
    initials: 'ZK',

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

    /* data-loc takes a comma-separated country list, or "global" for markup
       that should show everywhere the listed markets do not. */
    $$('[data-loc]').forEach(function (el) {
      var want = el.dataset.loc;
      gate(el, want === 'global'
        ? !localMarkets().length || localMarkets().indexOf(profile.country) === -1
        : want.split(',').indexOf(profile.country) !== -1);
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
    var dark = theme === 'dark';
    var sw = $('#themeSwitch');
    if (sw) sw.classList.toggle('is-on', dark);
    var sub = $('#themeSub');
    if (sub) sub.textContent = dark ? 'On — easier on the eyes at night' : 'Off — following a light palette';
    var icon = $('#themeIcon use');
    if (icon) icon.setAttribute('href', dark ? '#i-moon' : '#i-sun');
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', dark ? '#0A0A0B' : '#F6F6F4');
  }
  setTheme(root.dataset.theme, false);

  var themeRow = $('#themeRow');
  if (themeRow) {
    themeRow.addEventListener('click', function () {
      setTheme(root.dataset.theme === 'dark' ? 'light' : 'dark', true);
    });
  }

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
    if (g) g.textContent = t(greetFor(d.getHours()));
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

    /* A screen that is no longer a tab must not stay open. */
    if (tabOrder().indexOf(current) === -1 && current !== 'explore') current = 'home';
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

    if (name === 'personalise' && setPicker) hydratePersonalise();
    if (name === 'search') {
      resetSearch();
      setTimeout(function () { var i = $('#globalSearch'); if (i) i.focus(); }, 320);
    }
    animateBars(sheet);
  }

  function sheetClose() {
    if (openSheet) openSheet.classList.remove('is-open');
    openSheet = null;
    scrim.classList.remove('is-open');
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
    if (kind === 'sheet') sheetOpen(arg);
    else if (kind === 'tab') goTo(arg);
    else if (kind === 'toast') toast(arg);
    else if (kind === 'theme') { setTheme(root.dataset.theme === 'dark' ? 'light' : 'dark', true); toast('Theme switched'); }
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

    var events = [
      { t: '09:30', title: t('agenda.standup'), meta: t('agenda.standupMeta'), icon: 'i-check-circle', done: true },
      { t: '14:00', title: t('agenda.review'), meta: t('agenda.reviewMeta'), icon: 'i-clock', now: true },
      { t: '18:30', title: t('agenda.groceries'), meta: t('agenda.groceriesMeta'), icon: 'i-cart', act: 'tool:shopping' }
    ];

    var lsf = feature('loadshed');
    if (lsf && visible(lsf)) {
      var ls = toolCtx('loadshed').loadshed();
      events.push({ t: ls.slot.from, title: t('loadshed.outage'),
        meta: ls.area + ' · ' + ls.slot.duration, icon: 'i-bolt', act: 'tool:loadshed' });
    }

    if (profile.islamic) {
      var st = prayerState();
      st.main.forEach(function (p) {
        var past = mins(p) < (new Date().getHours() * 60 + new Date().getMinutes());
        events.push({
          t: hhmm(p), title: p.name,
          meta: past ? t('agenda.prayed') : t('agenda.adhanOn'),
          icon: past ? 'i-check-circle' : 'i-bell',
          done: past, act: 'tool:prayer'
        });
      });
    }

    events.sort(function (a, b) { return a.t.localeCompare(b.t); });

    var nowM = new Date().getHours() * 60 + new Date().getMinutes();
    host.innerHTML = events.map(function (e) {
      var em = parseInt(e.t.slice(0, 2), 10) * 60 + parseInt(e.t.slice(3), 10);
      var done = e.done || (em < nowM && !e.now);
      var cls = e.now ? ' is-now' : done ? ' is-done' : '';
      return '<div class="tl-item' + cls + '">' +
        '<span class="tl-time num">' + esc(L.time(parseInt(e.t.slice(0, 2), 10), parseInt(e.t.slice(3), 10))) + '</span>' +
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

  function toolCard(f) {
    var badge = '';
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

  function renderNotifications() {
    var host = $('#notifList');
    if (!host) return;
    var items = [];

    if (profile.islamic) {
      var st = prayerState();
      items.push({ icon: 'i-prayer',
        title: t('notif.prayerIn', { name: t('prayer.' + (PKEYS[st.next.name] || 'fajr')), time: fmtShort(st.toNext) }),
        sub: t('notif.adhanAt', { time: hhmm(st.next) }), fresh: true });
    }
    if (profile.country === 'PK') {
      var ls = toolCtx('loadshed').loadshed();
      items.push({ icon: 'i-bolt', title: t('notif.loadshed', { time: ls.slot.from }),
        sub: ls.area + ' · ' + ls.slot.duration, fresh: true });
    }
    items.push({ icon: 'i-check-square', title: '3 tasks left today', sub: 'Next: finish the Q3 summary at 15:00' });
    var wx = toolCtx('weather').weather();
    items.push({ icon: 'i-cloud-sun', title: t('notif.tomorrow', { city: profile.city }),
      sub: t('weather.hilo', { hi: L.temp(wx.daily[1].hi), lo: L.temp(wx.daily[1].lo) }) +
        ' · ' + wx.daily[1].rain + '% ' + t('weather.rain') });

    host.innerHTML = items.map(function (n) {
      return '<div class="list-row" style="cursor:default">' +
        '<span class="list-row__icon"' + (n.fresh ? ' style="background:var(--tint-accent);color:var(--accent)"' : '') + '>' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + n.icon + '"/></svg></span>' +
        '<span class="list-row__body"><span class="list-row__title">' + esc(n.title) + '</span>' +
        '<span class="list-row__sub">' + esc(n.sub) + '</span></span>' +
        (n.fresh ? '<span class="list-row__end"><span class="notif-dot"></span></span>' : '') +
      '</div>';
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
     Tasbih
     --------------------------------------------------------- */
  var tCount = $('#tasbeehCount'), tRing = $('#tasbeehRing');
  var tCirc = 2 * Math.PI * 45;

  var tBtn = $('#tasbeehBtn');
  if (tBtn) {
    tBtn.addEventListener('click', function () {
      beads++;
        tCount.classList.remove('bump');
      void tCount.offsetWidth;
      tCount.classList.add('bump');
      if (navigator.vibrate) navigator.vibrate(8);
      if (beads === TARGET) toast('33 complete — well done');
      else if (beads > 0 && beads % TARGET === 0) toast(beads + ' counted');
    });
  }
  var tReset = $('#tasbeehReset');
  if (tReset) tReset.addEventListener('click', function () { beads = 0; renderBeads(); toast('Counter reset'); });
  var tSave = $('#tasbeehSave');
  if (tSave) tSave.addEventListener('click', function () { toast('Saved ' + beads + ' to today'); });

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
      profile.lang = keep;
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
    var count = $('#profileInterestCount');
    if (count) count.textContent = profile.interests.length;

    var label = $('#profileInterests');
    if (label) {
      label.textContent = profile.interests.length
        ? profile.interests.slice(0, 3).map(interestLabel).join(', ') +
          (profile.interests.length > 3 ? ' +' + (profile.interests.length - 3) + ' more' : '')
        : t('profile.interestsSub');
    }

    var ctry = $('#profileCountry');
    if (ctry) {
      ctry.textContent = [L.countryName(profile.country), profile.region, profile.city]
        .filter(Boolean).join(' · ');
    }
    var langRow = $('#profileLangValue');
    if (langRow) {
      langRow.textContent = (L.languageName(L.lang()) || L.lang()) + ' · ' +
        L.currencyCode() + ' · ' + (L.unitSystem() === 'imperial' ? t('pers.unitsImperial') : t('pers.unitsMetric'));
    }

    var content = $('#profileContent');
    if (content) {
      var bits = [t('pers.islamic') + (profile.islamic ? ' ✓' : ' ✕')];
      if (profile.prefs.news) bits.push(t('pers.news'));
      if (profile.prefs.cricket) bits.push(t('pers.sport'));
      if (profile.prefs.finance) bits.push(t('pers.finance'));
      content.textContent = bits.join(' · ');
    }

    var avatars = [$('#appbarAvatar'), $('#profileAvatar')];
    avatars.forEach(function (a) { if (a) a.textContent = profile.initials; });

    var bm = $('#profileBookmarks');
    if (bm) bm.textContent = profile.islamic ? 'Ayahs, hadith and quotes' : 'Saved reads and quotes';

    var lang = $('#profileLang');
    if (lang) lang.textContent = profile.country === 'PK'
      ? 'English · اردو available'
      : 'English · اردو and العربية available';

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
    renderNotifications();
    renderProfileSummary();
    initHeader();
    updatePrayer();
    /* Rendered content lands inside gated containers, so the gate is applied
       again once everything exists. Otherwise a freshly injected row inside a
       hidden section would still be addressable (§64). */
    applyVisibility();
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
      var el = $('#onbDoneText');
      if (el) {
        el.innerHTML = profile.islamic
          ? 'Your next prayer is <b>' + esc(prayerState().next.name) + '</b>, and today’s plan is waiting on the home screen.'
          : 'Today’s plan is waiting on the home screen.';
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

    var finish = $('#onbFinish');
    if (finish) finish.addEventListener('click', function () { onbFinish('Welcome to Lume'); });

    var signIn = $('#onbSignIn');
    if (signIn) signIn.addEventListener('click', function () {
      if (!profile.interests.length) onbCommit(C.DEFAULT_INTERESTS.slice(), false);
      onbFinish('Welcome back');
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
      if (dx < 0 && onbStep < onbSteps.length - 1 && onbStep !== 5) onbShow(onbStep + 1);
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
    ayah: {
      kind: 'quran',
      arabic: 'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
      text: 'Truly, it is in the remembrance of God that hearts find rest.',
      source: 'Ar-Ra’d 13:28'
    },
    hadith: {
      kind: 'hadith',
      text: 'The most beloved deeds to God are those done consistently, even if they are few.',
      source: 'Sahih al-Bukhari 6464'
    },
    dua: {
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

  function closeTool() {
    if (toolStack.length) { currentTool = toolStack.pop(); renderTool(); return; }
    currentTool = null;
    goTo(toolReturnTab);
  }

  /* Leaving through the tab bar abandons the whole tool stack. */
  var goToBase = goTo;
  goTo = function (name, quiet) {
    currentTool = null;
    toolStack.length = 0;
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

  /* ---- the action vocabulary tool screens speak ---- */
  function toolAction(kind, arg) {
    var bits = String(arg).split(':');

    if (kind === 'tool') { openTool(bits[0]); return true; }

    if (kind === 'toolstate') {
      /* toolstate:<tool>:<key>:<value> — a tab, a filter, a selected row */
      var id = bits.shift(), key = bits.shift(), value = bits.join(':');
      var c = toolCtx(id);
      if (c) c.setState(key, value === '' ? true : value);
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
    if (kind === 'export') { toast(t('tool.exported')); return true; }
    if (kind === 'fav') { toast(t('tool.favourited')); return true; }
    if (kind === 'bookmark') { toast(t('tool.bookmarked')); return true; }

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

    if (kind === 'speedtest') { runSpeedTest(); return true; }
    if (kind === 'tasbihreset') { resetToolTasbih(); return true; }
    if (kind === 'cvswap' || kind === 'ucswap') { swapConverter(kind); return true; }
    if (kind === 'clock') { runClock(bits); return true; }

    return false;
  }

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
        if (isSearch) again.value = value;
        again.focus();
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
    var key = FIELD_ALIAS[name] || (name.indexOf('_') !== -1 ? name.split('_').slice(1).join('_') : name);
    c.setField(key, el.type === 'number' ? (el.value === '' ? 0 : Number(el.value)) : el.value);
    reflowSoon();
  });

  /* ---- steppers ---- */
  document.addEventListener('click', function (e) {
    var up = e.target.closest('[data-step-up]');
    var down = up ? null : e.target.closest('[data-step-down]');
    if ((!up && !down) || !currentTool) return;
    var name = up ? up.dataset.stepUp : down.dataset.stepDown;
    var key = FIELD_ALIAS[name] || name;
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

  /* ---- back ---- */
  document.addEventListener('click', function (e) {
    if (e.target.closest('[data-tool-back]')) closeTool();
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && currentTool && !openSheet) closeTool();
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
     Boot
     --------------------------------------------------------- */
  ensureExploreBack();
  applyWidth();
  tickClock();
  renderAll();
  updateDayRing();

  setInterval(tickClock, 15000);
  setInterval(function () { updatePrayer(); }, 1000);
  setInterval(updateDayRing, 60000);

  requestAnimationFrame(function () {
    movePill($('.tab.is-active'));
    animateBars($('#screen-home'));
  });
})();
