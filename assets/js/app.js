/* ============================================================
   Nur — app behaviour
   Vanilla JS, no dependencies. Runs from file:// too.
   ============================================================ */
(function () {
  'use strict';

  var $  = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var pad2 = function (n) { return n < 10 ? '0' + n : '' + n; };

  /* Storage can throw on a file:// origin or with site data blocked. */
  var store = {
    get: function (k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
    set: function (k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  };

  /* ---------------------------------------------------------
     Theme
     --------------------------------------------------------- */
  var root = document.documentElement;

  function setTheme(theme, remember) {
    root.dataset.theme = theme;
    if (remember) store.set('nur-theme', theme);
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
  var MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  var DAYS = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];

  function tickClock() {
    var d = new Date();
    var el = $('#statusClock');
    if (el) el.textContent = d.getHours() + ':' + pad2(d.getMinutes());
  }

  function greetFor(h) {
    if (h < 5)  return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  (function initHeader() {
    var now = new Date();
    var g = $('#greetText');
    if (g) g.textContent = greetFor(now.getHours());
    var label = DAYS[now.getDay()] + ', ' + now.getDate() + ' ' + MONTHS[now.getMonth()];
    var d = $('#todayDate');
    if (d) d.textContent = label;
    var h = $('#todayHijri');
    if (h) h.textContent = label + " · 15 Rabi' al-Awwal";
  })();

  /* ---------------------------------------------------------
     Toast
     --------------------------------------------------------- */
  var toastEl = $('#toast'), toastText = $('#toastText'), toastTimer;

  function toast(msg) {
    if (!toastEl || !msg) return;
    toastText.textContent = msg;
    toastEl.classList.add('is-open');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.classList.remove('is-open'); }, 2100);
  }

  /* ---------------------------------------------------------
     Tab navigation
     --------------------------------------------------------- */
  var tabbar = $('#tabbar');
  var pill = $('#tabPill');
  var tabs = $$('.tab');
  var current = 'home';

  function movePill(tab) {
    if (!pill || !tab) return;
    pill.style.width = (tab.offsetWidth - 8) + 'px';
    pill.style.transform = 'translateX(' + (tab.offsetLeft + 4) + 'px)';
  }

  function goTo(name) {
    var screen = $('#screen-' + name);
    if (!screen) return;

    $$('.screen').forEach(function (s) { s.classList.remove('is-active'); });
    screen.classList.add('is-active');
    screen.scrollTop = 0;

    tabs.forEach(function (t) {
      var on = t.dataset.tab === name;
      t.classList.toggle('is-active', on);
      t.setAttribute('aria-selected', on ? 'true' : 'false');
      if (on) movePill(t);
    });

    current = name;
    animateBars(screen);
  }

  tabs.forEach(function (t) {
    t.addEventListener('click', function () { goTo(t.dataset.tab); });
  });

  window.addEventListener('resize', function () {
    var active = tabs.filter(function (t) { return t.classList.contains('is-active'); })[0];
    movePill(active);
  });

  /* Animate any progress bars inside a freshly shown screen */
  function animateBars(scope) {
    $$('[data-fill]', scope).forEach(function (bar) {
      bar.style.width = '0%';
      requestAnimationFrame(function () {
        requestAnimationFrame(function () { bar.style.width = bar.dataset.fill + '%'; });
      });
    });
  }

  /* ---------------------------------------------------------
     Bottom sheets
     --------------------------------------------------------- */
  var scrim = $('#scrim');
  var openSheet = null;

  function sheetOpen(name) {
    var el = $('#sheet-' + name);
    if (!el) return;
    if (openSheet) openSheet.classList.remove('is-open');
    openSheet = el;
    el.classList.add('is-open');
    scrim.classList.add('is-open');
    if (name === 'qibla') spinQibla();
    if (name === 'prayer') renderPrayerList();
    if (name === 'interests' && setPicker) setPicker.set(Array.from(interests));
  }

  function sheetClose() {
    if (openSheet) openSheet.classList.remove('is-open');
    openSheet = null;
    scrim.classList.remove('is-open');
  }

  scrim.addEventListener('click', sheetClose);
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') sheetClose();
  });
  $$('[data-close]').forEach(function (b) { b.addEventListener('click', sheetClose); });

  /* Swipe a sheet down to dismiss */
  $$('.sheet').forEach(function (sheet) {
    var startY = 0, dy = 0, dragging = false;
    var handles = [sheet.querySelector('.sheet__grab'), sheet.querySelector('.sheet__head')];

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
      if (!h) return;
      h.addEventListener('touchstart', function (e) { down(e.touches[0].clientY); }, { passive: true });
      h.addEventListener('touchmove',  function (e) { move(e.touches[0].clientY); }, { passive: true });
      h.addEventListener('touchend', up);
      h.addEventListener('mousedown', function (e) {
        if (e.target.closest('button')) return;   // let the close button work
        down(e.clientY);
        e.preventDefault();
      });
    });
    document.addEventListener('mousemove', function (e) { move(e.clientY); });
    document.addEventListener('mouseup', up);
  });

  /* ---------------------------------------------------------
     Global click routing: data-tab / data-sheet / data-toast
     --------------------------------------------------------- */
  document.addEventListener('click', function (e) {
    var el = e.target.closest('[data-sheet], [data-tab], [data-toast], [data-toggle], [data-switch]');
    if (!el) return;

    if (el.hasAttribute('data-toggle')) {
      el.classList.toggle('is-on');
      if (el.classList.contains('is-on')) toast(el.dataset.toast || 'Saved');
      else toast('Removed');
      return;
    }
    if (el.hasAttribute('data-switch')) {
      el.classList.toggle('is-on');
      toast(el.classList.contains('is-on') ? 'Turned on' : 'Turned off');
      return;
    }
    if (el.dataset.sheet) { sheetOpen(el.dataset.sheet); return; }
    if (el.dataset.tab && !el.classList.contains('tab')) { sheetClose(); goTo(el.dataset.tab); return; }
    if (el.dataset.toast) { toast(el.dataset.toast); }
  });

  /* ---------------------------------------------------------
     Hero carousel
     --------------------------------------------------------- */
  var track = $('#heroTrack');
  var dots = $$('#heroDots .hero__dot');

  if (track) {
    var syncing = false;

    function activeIndex() {
      var slideW = track.firstElementChild.offsetWidth + 12;
      return Math.round(track.scrollLeft / slideW);
    }

    track.addEventListener('scroll', function () {
      if (syncing) return;
      syncing = true;
      requestAnimationFrame(function () {
        var i = activeIndex();
        dots.forEach(function (d, n) { d.classList.toggle('is-active', n === i); });
        syncing = false;
      });
    }, { passive: true });

    dots.forEach(function (d, i) {
      d.addEventListener('click', function () {
        var slideW = track.firstElementChild.offsetWidth + 12;
        track.scrollTo({ left: i * slideW, behavior: 'smooth' });
      });
    });

    /* Pointer drag, so the carousel also feels right on a desktop preview */
    var down = false, startX = 0, startScroll = 0, moved = 0;

    track.addEventListener('mousedown', function (e) {
      down = true; moved = 0;
      startX = e.clientX;
      startScroll = track.scrollLeft;
      track.classList.add('is-dragging');
    });
    document.addEventListener('mousemove', function (e) {
      if (!down) return;
      var dx = e.clientX - startX;
      moved = Math.abs(dx);
      track.scrollLeft = startScroll - dx;
    });
    document.addEventListener('mouseup', function () {
      if (!down) return;
      down = false;
      track.classList.remove('is-dragging');
      var slideW = track.firstElementChild.offsetWidth + 12;
      track.scrollTo({ left: Math.round(track.scrollLeft / slideW) * slideW, behavior: 'smooth' });
    });
    /* Suppress the click that follows a real drag */
    track.addEventListener('click', function (e) {
      if (moved > 8) { e.stopPropagation(); e.preventDefault(); }
    }, true);
  }

  /* ---------------------------------------------------------
     Prayer engine
     --------------------------------------------------------- */
  var PRAYERS = [
    { name: 'Fajr',    short: 'Fajr', h: 4,  m: 52 },
    { name: 'Sunrise', short: 'Sun',  h: 6,  m: 23, minor: true },
    { name: 'Dhuhr',   short: 'Dhuhr', h: 12, m: 38 },
    { name: 'Asr',     short: 'Asr',  h: 16, m: 12 },
    { name: 'Maghrib', short: 'Mgrb', h: 19, m: 24 },
    { name: 'Isha',    short: 'Isha', h: 20, m: 47 }
  ];
  var DAY = 24 * 60;
  var MAIN = PRAYERS.filter(function (p) { return !p.minor; });

  function mins(p) { return p.h * 60 + p.m; }
  function hhmm(p) { return pad2(p.h) + ':' + pad2(p.m); }

  function prayerState() {
    var now = new Date();
    var t = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;

    var nextIdx = -1;
    for (var i = 0; i < MAIN.length; i++) {
      if (mins(MAIN[i]) > t) { nextIdx = i; break; }
    }
    var wrapped = nextIdx === -1;
    if (wrapped) nextIdx = 0;

    var next = MAIN[nextIdx];
    var prev = MAIN[(nextIdx - 1 + MAIN.length) % MAIN.length];

    var nextAt = mins(next) + (wrapped ? DAY : 0);
    var prevAt = mins(prev);
    if (prevAt > t) prevAt -= DAY;

    var remaining = nextAt - t;                         // minutes
    var progress = (t - prevAt) / (nextAt - prevAt);    // 0..1

    return {
      next: next,
      nextIdx: nextIdx,
      remaining: remaining,
      progress: Math.max(0, Math.min(1, progress)),
      nowMins: t
    };
  }

  function fmtCountdown(m) {
    var total = Math.max(0, Math.floor(m * 60));
    var h = Math.floor(total / 3600);
    var mm = Math.floor((total % 3600) / 60);
    var ss = total % 60;
    return (h > 0 ? h + ':' + pad2(mm) : mm) + ':' + pad2(ss);
  }

  function fmtShort(m) {
    var h = Math.floor(m / 60), mm = Math.floor(m % 60);
    return h > 0 ? h + 'h ' + mm + 'm' : mm + 'm';
  }

  var stepsFor = null;

  function renderSteps(state) {
    var host = $('#prayerSteps');
    if (!host || stepsFor === state.next.name) return;
    stepsFor = state.next.name;
    host.innerHTML = '';
    MAIN.forEach(function (p) {
      var el = document.createElement('span');
      el.className = 'prayer__step';
      if (mins(p) < state.nowMins) el.classList.add('is-done');
      if (p.name === state.next.name) el.classList.add('is-next');
      el.innerHTML = '<b>' + p.short + '</b>';
      host.appendChild(el);
    });
  }

  function renderPrayerList() {
    var host = $('#prayerList');
    if (!host) return;
    var state = prayerState();
    host.innerHTML = PRAYERS.map(function (p) {
      var isNext = p.name === state.next.name;
      var done = mins(p) < state.nowMins;
      return '<div class="list-row">' +
        '<span class="list-row__icon"' + (isNext ? ' style="background:var(--tint-accent);color:var(--accent)"' : '') + '>' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + (p.minor ? 'i-sun' : 'i-prayer') + '"/></svg></span>' +
        '<span class="list-row__body">' +
          '<span class="list-row__title">' + p.name + (isNext ? ' <span class="tag">Next</span>' : '') + '</span>' +
          '<span class="list-row__sub">' + (p.minor ? 'Not a prayer time' : done ? 'Passed' : 'Reminder on') + '</span>' +
        '</span>' +
        '<span class="list-row__end"><span class="list-row__value num">' + hhmm(p) + '</span></span>' +
      '</div>';
    }).join('');
  }

  function updatePrayer() {
    var s = prayerState();

    var name = $('#prayerName'), time = $('#prayerTime'), cd = $('#prayerCountdown'), fill = $('#prayerFill');
    if (name) name.textContent = s.next.name;
    if (time) time.textContent = hhmm(s.next);
    if (cd) cd.innerHTML = fmtCountdown(s.remaining) + '<small>remaining</small>';
    if (fill) fill.style.width = (s.progress * 100).toFixed(1) + '%';

    var hName = $('#heroPrayerName'), hTime = $('#heroPrayerTime'), hCd = $('#heroCountdown');
    if (hName) hName.textContent = s.next.name;
    if (hTime) hTime.textContent = hhmm(s.next);
    if (hCd) hCd.textContent = 'in ' + fmtShort(s.remaining);

    renderSteps(s);
  }

  /* ---------------------------------------------------------
     Day progress ring
     --------------------------------------------------------- */
  function updateDayRing() {
    var ring = $('#dayRing'), label = $('#dayRingValue');
    if (!ring) return;
    var now = new Date();
    var pct = (now.getHours() * 60 + now.getMinutes()) / DAY;
    var circumference = 2 * Math.PI * 42;
    ring.style.strokeDashoffset = (circumference * (1 - pct)).toFixed(1);
    if (label) label.textContent = Math.round(pct * 100) + '%';
  }

  /* ---------------------------------------------------------
     Tasks
     --------------------------------------------------------- */
  $$('#taskList .task').forEach(function (task) {
    task.addEventListener('click', function () {
      task.classList.toggle('is-done');
      toast(task.classList.contains('is-done') ? 'Nice — one less thing' : 'Marked as not done');
    });
  });

  /* ---------------------------------------------------------
     Tool search + category chips
     --------------------------------------------------------- */
  var search = $('#toolSearch');
  var chips = $$('#toolChips .chip');
  var cats = $$('#toolCats .cat');
  var emptyState = $('#toolEmpty');
  var filter = 'foryou';

  function applyFilter() {
    var q = (search && search.value || '').trim().toLowerCase();
    var anyVisible = false;

    cats.forEach(function (cat) {
      /* A search looks across the whole catalogue — being in "For you" should
         never stop someone finding a tool they typed the name of. */
      var searching = !!q;
      var forYou = !searching && filter === 'foryou' && interests.size > 0;
      var catMatch = searching || filter === 'all' || forYou || cat.dataset.cat === filter;
      var shown = 0;

      $$('.cat-tool', cat).forEach(function (tool) {
        var hay = (tool.dataset.name || '') + ' ' + tool.textContent.toLowerCase();
        var match = catMatch && (!q || hay.toLowerCase().indexOf(q) !== -1);
        if (match && forYou) {
          match = (tool.dataset.int || '').split(/\s+/).some(function (t) { return interests.has(t); });
        }
        tool.classList.toggle('is-hidden', !match);
        if (match) shown++;
      });

      cat.style.display = shown ? '' : 'none';
      var count = $('.cat__count', cat);
      if (count) count.textContent = shown;
      if (shown) anyVisible = true;
    });

    if (emptyState) {
      emptyState.classList.toggle('is-shown', !anyVisible);
      var t = $('.empty__title', emptyState), x = $('.empty__text', emptyState);
      if (t && x) {
        if (!q && filter === 'foryou') {
          t.textContent = 'Nothing here yet';
          x.textContent = 'Add a few more interests, or browse the full list under All.';
        } else {
          t.textContent = 'No tools match';
          x.textContent = 'Try a different word — or browse a category above.';
        }
      }
    }
  }

  if (search) search.addEventListener('input', applyFilter);

  chips.forEach(function (chip) {
    chip.addEventListener('click', function () {
      chips.forEach(function (c) { c.classList.remove('is-active'); });
      chip.classList.add('is-active');
      filter = chip.dataset.filter;
      applyFilter();
    });
  });

  /* ---------------------------------------------------------
     Calculator
     --------------------------------------------------------- */
  var calc = { acc: null, op: null, entry: '0', fresh: true };
  var calcValue = $('#calcValue'), calcHistory = $('#calcHistory');

  function calcRender() {
    if (!calcValue) return;
    var v = calc.entry;
    if (v.length > 12 && v.indexOf('.') !== -1) v = String(parseFloat(v).toPrecision(10));
    calcValue.textContent = v;
    calcHistory.textContent = calc.acc !== null ? trimNum(calc.acc) + ' ' + (calc.op || '') : '';
  }

  function trimNum(n) {
    if (!isFinite(n)) return 'Error';
    var s = Math.round(n * 1e10) / 1e10;
    return String(s);
  }

  function calcCompute(a, op, b) {
    switch (op) {
      case '+': return a + b;
      case '−': return a - b;
      case '×': return a * b;
      case '÷': return b === 0 ? NaN : a / b;
      default: return b;
    }
  }

  function calcKey(k) {
    if (/^[0-9]$/.test(k)) {
      calc.entry = calc.fresh || calc.entry === '0' ? k : calc.entry + k;
      calc.fresh = false;
    } else if (k === '.') {
      if (calc.fresh) { calc.entry = '0.'; calc.fresh = false; }
      else if (calc.entry.indexOf('.') === -1) calc.entry += '.';
    } else if (k === 'clear') {
      calc = { acc: null, op: null, entry: '0', fresh: true };
    } else if (k === 'back') {
      calc.entry = calc.entry.length > 1 ? calc.entry.slice(0, -1) : '0';
    } else if (k === 'sign') {
      calc.entry = calc.entry.charAt(0) === '-' ? calc.entry.slice(1) : '-' + calc.entry;
    } else if (k === 'percent') {
      calc.entry = trimNum(parseFloat(calc.entry) / 100);
    } else if (k === '+' || k === '−' || k === '×' || k === '÷') {
      var cur = parseFloat(calc.entry);
      calc.acc = calc.acc === null || calc.fresh ? (calc.fresh && calc.acc !== null ? calc.acc : cur)
                                                 : calcCompute(calc.acc, calc.op, cur);
      calc.op = k;
      calc.fresh = true;
    } else if (k === '=') {
      if (calc.op !== null) {
        var result = calcCompute(calc.acc, calc.op, parseFloat(calc.entry));
        calc.entry = trimNum(result);
        calc.acc = null;
        calc.op = null;
        calc.fresh = true;
      }
    }
    calcRender();
  }

  var calcPad = $('#calcPad');
  if (calcPad) {
    calcPad.addEventListener('click', function (e) {
      var key = e.target.closest('[data-k]');
      if (key) calcKey(key.dataset.k);
    });
  }

  document.addEventListener('keydown', function (e) {
    if (!openSheet || openSheet.id !== 'sheet-calculator') return;
    var map = { '/': '÷', '*': '×', '-': '−', '+': '+', 'Enter': '=', '=': '=', 'Backspace': 'back', 'Escape': 'clear', '%': 'percent' };
    var k = map[e.key] || (/^[0-9.]$/.test(e.key) ? e.key : null);
    if (k) { e.preventDefault(); calcKey(k); }
  });

  /* ---------------------------------------------------------
     Tasbeeh
     --------------------------------------------------------- */
  var TARGET = 33;
  var beads = 0;
  var tCount = $('#tasbeehCount'), tRing = $('#tasbeehRing');
  var tCirc = 2 * Math.PI * 45;

  function renderBeads() {
    if (tCount) tCount.textContent = beads;
    var tQuick = $('#tasbeehQuick');          // re-queried: the grid is rebuilt
    if (tQuick) tQuick.textContent = beads;
    if (tRing) tRing.style.strokeDashoffset = (tCirc * (1 - Math.min(1, beads / TARGET))).toFixed(1);
  }

  var tBtn = $('#tasbeehBtn');
  if (tBtn) {
    tBtn.addEventListener('click', function () {
      beads++;
      renderBeads();
      tCount.classList.remove('bump');
      void tCount.offsetWidth;
      tCount.classList.add('bump');
      if (navigator.vibrate) navigator.vibrate(8);
      if (beads === TARGET) toast('33 complete — well done');
      if (beads > 0 && beads % TARGET === 0 && beads !== TARGET) toast(beads + ' counted');
    });
  }
  var tReset = $('#tasbeehReset');
  if (tReset) tReset.addEventListener('click', function () { beads = 0; renderBeads(); toast('Counter reset'); });
  var tSave = $('#tasbeehSave');
  if (tSave) tSave.addEventListener('click', function () { toast('Saved ' + beads + ' to today'); });

  /* ---------------------------------------------------------
     Qibla
     --------------------------------------------------------- */
  function spinQibla() {
    var needle = $('#qiblaNeedle');
    if (!needle) return;
    needle.style.transition = 'none';
    needle.style.transform = 'rotate(-40deg)';
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        needle.style.transition = '';
        needle.style.transform = 'rotate(119deg)';
      });
    });
  }

  /* ---------------------------------------------------------
     Skeleton loading on first paint
     --------------------------------------------------------- */
  (function skeletons() {
    var targets = $$('#screen-home .quote__text, #screen-home .quote__by, #screen-home .arabic, #screen-home .card--pad > .body');
    targets.forEach(function (el) { el.classList.add('skeleton'); });
    setTimeout(function () {
      targets.forEach(function (el) { el.classList.remove('skeleton'); });
    }, 850);
  })();

  /* ---------------------------------------------------------
     Interests & personalisation
     --------------------------------------------------------- */
  var PICK_MIN = 5, PICK_MAX = 10;

  var INTERESTS = [
    { id: 'prayer',   label: 'Prayer times',   icon: 'i-prayer' },
    { id: 'quran',    label: 'Qur’an',    icon: 'i-book' },
    { id: 'hadith',   label: 'Hadith',         icon: 'i-quote' },
    { id: 'duas',     label: 'Duas',           icon: 'i-heart' },
    { id: 'dhikr',    label: 'Tasbeeh & dhikr',icon: 'i-beads' },
    { id: 'qibla',    label: 'Qibla',          icon: 'i-navigation' },
    { id: 'hijri',    label: 'Hijri & Ramadan',icon: 'i-moon-star' },
    { id: 'zakat',    label: 'Zakat & giving', icon: 'i-wallet' },
    { id: 'tasks',    label: 'Tasks & to-dos', icon: 'i-check-square' },
    { id: 'calendar', label: 'Calendar',       icon: 'i-calendar' },
    { id: 'notes',    label: 'Notes',          icon: 'i-note' },
    { id: 'habits',   label: 'Habits',         icon: 'i-flame' },
    { id: 'focus',    label: 'Focus & timers', icon: 'i-timer' },
    { id: 'money',    label: 'Money',          icon: 'i-currency' },
    { id: 'convert',  label: 'Converters',     icon: 'i-ruler' },
    { id: 'maths',    label: 'Calculators',    icon: 'i-calculator' },
    { id: 'weather',  label: 'Weather',        icon: 'i-cloud-sun' },
    { id: 'news',     label: 'News',           icon: 'i-news' },
    { id: 'nearby',   label: 'Nearby places',  icon: 'i-pin' },
    { id: 'travel',   label: 'Travel',         icon: 'i-globe' },
    { id: 'health',   label: 'Health & water', icon: 'i-droplet' },
    { id: 'sleep',    label: 'Sleep',          icon: 'i-moon' },
    { id: 'mindful',  label: 'Mindfulness',    icon: 'i-sparkles' },
    { id: 'quotes',   label: 'Daily quotes',   icon: 'i-star' },
    { id: 'reading',  label: 'Reading',        icon: 'i-eye' }
  ];

  /* Used when someone skips the picker, so the app is never unpersonalised. */
  var DEFAULT_INTERESTS = ['prayer', 'quran', 'tasks', 'calendar', 'weather', 'maths', 'dhikr', 'quotes'];

  var interests = new Set();

  function loadInterests() {
    var raw = store.get('nur-interests');
    if (raw) {
      try {
        var list = JSON.parse(raw);
        if (Array.isArray(list) && list.length) { interests = new Set(list); return; }
      } catch (e) {}
    }
    /* Onboarded already but nothing stored (skipped in an older build):
       fall back to the defaults rather than leaving the app unpersonalised. */
    interests = new Set(store.get('nur-onboarded') ? DEFAULT_INTERESTS : []);
  }

  function saveInterests(list) {
    interests = new Set(list);
    store.set('nur-interests', JSON.stringify(list));
    personalise();
  }

  function interestLabel(id) {
    for (var i = 0; i < INTERESTS.length; i++) if (INTERESTS[i].id === id) return INTERESTS[i].label;
    return id;
  }

  loadInterests();

  /* ---- Picker factory (shared by onboarding and the Profile sheet) ---- */

  function makePicker(host, countEl, clearEl, onChange) {
    if (!host) return null;
    var sel = new Set();

    host.innerHTML = INTERESTS.map(function (it) {
      return '<button type="button" class="pick" data-id="' + it.id + '" aria-pressed="false">' +
             '<svg class="ico" viewBox="0 0 24 24"><use href="#' + it.icon + '"/></svg>' +
             '<span>' + it.label + '</span></button>';
    }).join('');

    var btns = $$('.pick', host);

    function sync() {
      var full = sel.size >= PICK_MAX;
      btns.forEach(function (b) {
        var on = sel.has(b.dataset.id);
        b.classList.toggle('is-on', on);
        b.classList.toggle('is-muted', !on && full);
        b.setAttribute('aria-pressed', on ? 'true' : 'false');
      });
      if (countEl) {
        countEl.innerHTML = sel.size < PICK_MIN
          ? '<b>' + sel.size + '</b> of ' + PICK_MIN + ' minimum'
          : '<b>' + sel.size + '</b> of ' + PICK_MAX + ' selected';
      }
      if (onChange) onChange(sel.size >= PICK_MIN, Array.from(sel));
    }

    host.addEventListener('click', function (e) {
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

    sync();
    return {
      get: function () { return Array.from(sel); },
      set: function (list) { sel = new Set(list || []); sync(); }
    };
  }

  /* ---- Quick tools, chosen from the selected interests ---- */

  var TOOL_POOL = [
    { id: 'prayer',   label: 'Prayer',    icon: 'i-prayer',     act: 'data-sheet="prayer"',  ints: ['prayer'], accent: true, value: '' },
    { id: 'quran',    label: 'Qur’an', icon: 'i-book',     act: 'data-sheet="reading"', ints: ['quran', 'reading'], accent: true, value: '38%' },
    { id: 'qibla',    label: 'Qibla',     icon: 'i-navigation', act: 'data-sheet="qibla"',   ints: ['qibla', 'prayer'], accent: true, value: '119°' },
    { id: 'tasbeeh',  label: 'Tasbeeh',   icon: 'i-beads',      act: 'data-sheet="tasbeeh"', ints: ['dhikr', 'duas'], accent: true, value: '0', valueId: 'tasbeehQuick' },
    { id: 'duas',     label: 'Duas',      icon: 'i-heart',      act: 'data-toast="42 duas in your library"', ints: ['duas'], accent: true, value: '42' },
    { id: 'hijri',    label: 'Hijri',     icon: 'i-moon',       act: 'data-toast="15 Rabi’ al-Awwal 1448"', ints: ['hijri'], accent: true, value: '15' },
    { id: 'zakat',    label: 'Zakat',     icon: 'i-wallet',     act: 'data-toast="Zakat calculator"', ints: ['zakat'], accent: true, value: '' },
    { id: 'hadith',   label: 'Hadith',    icon: 'i-quote',      act: 'data-toast="Hadith of the day"', ints: ['hadith'], accent: true, value: '' },
    { id: 'calc',     label: 'Calculator',icon: 'i-calculator', act: 'data-sheet="calculator"', ints: ['maths'], value: '' },
    { id: 'currency', label: 'Currency',  icon: 'i-currency',   act: 'data-toast="GBP → EUR · 1.1842"', ints: ['money'], value: '1.1842' },
    { id: 'convert',  label: 'Convert',   icon: 'i-ruler',      act: 'data-toast="Unit converter"', ints: ['convert'], value: '32' },
    { id: 'weather',  label: 'Weather',   icon: 'i-cloud-sun',  act: 'data-tab="explore"', ints: ['weather'], value: '21°' },
    { id: 'calendar', label: 'Calendar',  icon: 'i-calendar',   act: 'data-tab="today"', ints: ['calendar'], value: '7 Sep' },
    { id: 'todo',     label: 'To-do',     icon: 'i-check-square', act: 'data-tab="today"', ints: ['tasks'], value: '2/5' },
    { id: 'notes',    label: 'Notes',     icon: 'i-note',       act: 'data-toast="Notes — 12 saved"', ints: ['notes'], value: '12' },
    { id: 'habits',   label: 'Habits',    icon: 'i-flame',      act: 'data-toast="Habit streak: 12 days"', ints: ['habits'], value: '12d' },
    { id: 'timer',    label: 'Timer',     icon: 'i-timer',      act: 'data-toast="Timer ready — 00:00"', ints: ['focus'], value: '' },
    { id: 'water',    label: 'Water',     icon: 'i-droplet',    act: 'data-toast="Water: 5 of 8 glasses"', ints: ['health'], value: '5/8' },
    { id: 'news',     label: 'News',      icon: 'i-news',       act: 'data-tab="explore"', ints: ['news'], value: '12' },
    { id: 'nearby',   label: 'Nearby',    icon: 'i-pin',        act: 'data-toast="3 mosques within 1.2 km"', ints: ['nearby', 'travel'], value: '1.2km' },
    { id: 'quotes',   label: 'Quotes',    icon: 'i-star',       act: 'data-toast="Quote of the day"', ints: ['quotes', 'mindful'], value: '' },
    { id: 'sleep',    label: 'Wind down', icon: 'i-moon',       act: 'data-toast="Wind-down routine"', ints: ['sleep'], value: '' }
  ];

  var QUICK_FALLBACK = ['calc', 'currency', 'weather', 'calendar', 'qibla', 'tasbeeh', 'notes', 'timer'];

  function renderQuickTools() {
    var host = $('#quickTools');
    if (!host) return;

    var picked = [], seen = {};
    function add(t) { if (t && !seen[t.id] && picked.length < 8) { seen[t.id] = 1; picked.push(t); } }
    function byId(id) {
      for (var i = 0; i < TOOL_POOL.length; i++) if (TOOL_POOL[i].id === id) return TOOL_POOL[i];
      return null;
    }

    /* One pass per chosen interest, in catalogue order, so the mix stays balanced */
    if (interests.size) {
      INTERESTS.forEach(function (it) {
        if (!interests.has(it.id)) return;
        TOOL_POOL.forEach(function (t) {
          if (t.ints.indexOf(it.id) !== -1) add(t);
        });
      });
    }
    QUICK_FALLBACK.forEach(function (id) { add(byId(id)); });

    host.innerHTML = picked.map(function (t) {
      return '<button class="tool pressable" ' + t.act + '>' +
        '<span class="tool__icon' + (t.accent ? ' tool__icon--accent' : '') + '">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' + t.icon + '"/></svg></span>' +
        '<span class="tool__label">' + t.label + '</span>' +
        (t.value ? '<span class="tool__value num"' + (t.valueId ? ' id="' + t.valueId + '"' : '') + '>' + t.value + '</span>' : '') +
      '</button>';
    }).join('');

    var sub = $('#quickToolsSub');
    if (sub) sub.textContent = interests.size ? 'Picked from your interests' : 'Your eight most-used, one tap away';

    renderBeads();
  }

  /* ---- Show only what matches, and drop sections left empty ---- */

  function personalise() {
    var on = interests.size > 0;

    $$('[data-int]').forEach(function (el) {
      var match = !on || el.dataset.int.split(/\s+/).some(function (t) { return interests.has(t); });
      el.classList.toggle('is-off', !match);
    });

    $$('[data-psection]').forEach(function (sec) {
      var items = $$('[data-int]', sec);
      var visible = items.filter(function (i) { return !i.classList.contains('is-off'); }).length;
      sec.classList.toggle('is-off', items.length > 0 && visible === 0);
    });

    var count = $('#profileInterestCount');
    if (count) count.textContent = interests.size;
    var label = $('#profileInterests');
    if (label) {
      label.textContent = interests.size
        ? Array.from(interests).slice(0, 3).map(interestLabel).join(', ') +
          (interests.size > 3 ? ' +' + (interests.size - 3) + ' more' : '')
        : 'Shapes your home, tools and reading';
    }

    renderQuickTools();
    applyFilter();
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

    if (i === onbSteps.length - 1) {
      var el = $('#onbNextPrayer');
      if (el) el.textContent = prayerState().next.name;
    }
  }

  function onbFinish(msg) {
    if (!onb) return;
    onb.classList.add('is-leaving');
    store.set('nur-onboarded', '1');
    setTimeout(function () {
      onb.hidden = true;
      onb.classList.remove('is-leaving');
      if (msg) toast(msg);
    }, 380);
  }

  function onbStart() {
    if (!onb) return;
    if (onbPicker) onbPicker.set(Array.from(interests));
    onb.hidden = false;
    onb.classList.remove('is-leaving');
    onbShow(0);
  }

  var onbPicker = makePicker($('#onbPicker'), $('#onbPickCount'), $('#onbPickClear'), function (enough) {
    var b = $('#onbPickNext');
    if (b) b.disabled = !enough;
  });

  if (onb) {
    var pickNext = $('#onbPickNext');
    if (pickNext) {
      pickNext.addEventListener('click', function () {
        saveInterests(onbPicker.get());
        onbShow(onbStep + 1);
      });
    }

    $$('[data-onb-next]').forEach(function (b) {
      b.addEventListener('click', function () { onbShow(onbStep + 1); });
    });
    onbBack.addEventListener('click', function () { onbShow(onbStep - 1, true); });
    onbSkip.addEventListener('click', function () {
      /* Skipping still needs a personalised app, so fall back to the defaults. */
      if (!interests.size) {
        saveInterests(DEFAULT_INTERESTS.slice());
        onbFinish('Set up with our defaults — edit them in Profile');
      } else {
        onbFinish('Tour skipped — find it again in Profile');
      }
    });

    var finish = $('#onbFinish');
    if (finish) finish.addEventListener('click', function () { onbFinish('Welcome to Nur'); });

    var signIn = $('#onbSignIn');
    if (signIn) signIn.addEventListener('click', function () {
      if (!interests.size) saveInterests(DEFAULT_INTERESTS.slice());
      onbFinish('Welcome back');
    });

    /* Permission rows */
    $$('[data-onb-toggle]').forEach(function (row) {
      row.addEventListener('click', function () {
        var on = !row.classList.contains('is-on');
        row.classList.toggle('is-on', on);
        var sw = $('.switch', row);
        if (sw) sw.classList.toggle('is-on', on);
      });
    });

    /* Calculation method */
    var method = $('#onbMethod');
    if (method) {
      method.addEventListener('click', function (e) {
        var b = e.target.closest('button');
        if (!b) return;
        $$('button', method).forEach(function (x) { x.classList.remove('is-active'); });
        b.classList.add('is-active');
      });
    }

    /* Swipe between steps */
    var sx = 0, sy = 0;
    onb.addEventListener('touchstart', function (e) {
      sx = e.touches[0].clientX; sy = e.touches[0].clientY;
    }, { passive: true });
    onb.addEventListener('touchend', function (e) {
      var dx = e.changedTouches[0].clientX - sx;
      var dy = e.changedTouches[0].clientY - sy;
      if (Math.abs(dx) < 56 || Math.abs(dy) > Math.abs(dx)) return;
      if (dx < 0 && onbStep < onbSteps.length - 1) onbShow(onbStep + 1);
      if (dx > 0 && onbStep > 0) onbShow(onbStep - 1, true);
    }, { passive: true });

    /* Show on first run, or on demand via ?tour=1 */
    var forced = /[?&]tour=1/.test(location.search);
    if (forced || !store.get('nur-onboarded')) onbStart();

    var replay = $('#replayTour');
    if (replay) replay.addEventListener('click', function () { sheetClose(); onbStart(); });
  }

  /* ---- Editing interests later, from Profile ---- */
  var setPicker = makePicker($('#setPicker'), $('#setPickCount'), $('#setPickClear'), function (enough) {
    var b = $('#setPickSave');
    if (b) b.disabled = !enough;
  });

  var setSave = $('#setPickSave');
  if (setSave) {
    setSave.addEventListener('click', function () {
      saveInterests(setPicker.get());
      sheetClose();
      toast('Interests updated');
    });
  }

  /* A clipped shell can still be scrolled programmatically — by focus moving to
     an off-screen node, or scrollIntoView. Pin it so the layout never drifts. */
  var appEl = $('#app');
  if (appEl) {
    appEl.addEventListener('scroll', function () {
      if (appEl.scrollTop || appEl.scrollLeft) { appEl.scrollTop = 0; appEl.scrollLeft = 0; }
    });
  }

  /* ---------------------------------------------------------
     Boot
     --------------------------------------------------------- */
  tickClock();
  personalise();
  updatePrayer();
  updateDayRing();
  renderBeads();
  setInterval(tickClock, 15000);
  setInterval(updatePrayer, 1000);
  setInterval(updateDayRing, 60000);

  requestAnimationFrame(function () {
    movePill($('.tab.is-active'));
    animateBars($('#screen-home'));
  });
})();
