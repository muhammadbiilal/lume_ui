/* ============================================================
   Lume — notification engine  (Master Spec §100)

   Notifications are a platform capability, not a feature of any
   one tool. Lume owns the infrastructure; tools declare what
   they would tell the user about, and the engine decides
   whether, when and how that reaches them.

       Engine → in-app (badge · centre · banner)
              → push   (OS notification)

   Both paths share one model: category, priority, read state,
   deep link, grouping and privacy rules. A bell icon on its own
   is not a notification system.
   ============================================================ */
import { LUME_DATA } from '../data/tool-data.js';
export const LUME_NOTIFY = function (deps) {
  'use strict';

  var t = deps.t, L = deps.L;
  var P = deps.profile, ctxFor = deps.ctx;
  var featureFor = deps.featureFor, isVisible = deps.isVisible;

  /* ---------------------------------------------------------
     §100.7 categories · §100.6 priority
     --------------------------------------------------------- */
  var CATEGORIES = [
    { id: 'faith',     icon: 'i-prayer',   key: 'ncat.faith',     faith: true },
    { id: 'finance',   icon: 'i-wallet',   key: 'ncat.finance' },
    { id: 'markets',   icon: 'i-trending', key: 'ncat.markets' },
    { id: 'travel',    icon: 'i-plane',    key: 'ncat.travel' },
    { id: 'weather',   icon: 'i-cloud-sun',key: 'ncat.weather' },
    { id: 'news',      icon: 'i-news',     key: 'ncat.news' },
    { id: 'personal',  icon: 'i-user',     key: 'ncat.personal' },
    { id: 'reminders', icon: 'i-bell',     key: 'ncat.reminders' },
    { id: 'documents', icon: 'i-folder',   key: 'ncat.documents' },
    { id: 'health',    icon: 'i-pulse',    key: 'ncat.health',    sensitive: true },
    { id: 'system',    icon: 'i-settings', key: 'ncat.system' }
  ];

  var PRIORITY = { critical: 3, high: 2, normal: 1, low: 0 };

  /* A source states how long ago its event happened relative to when Lume
     started; anchoring to the session means "18 min ago" becomes "24 min
     ago" six minutes later instead of standing still forever. */
  var ANCHOR = Date.now();

  /* Bumped by every write, so a memoised list can never go stale. */
  var version = 0;
  function touch() { version++; cache = null; }

  function category(id) {
    for (var i = 0; i < CATEGORIES.length; i++) if (CATEGORIES[i].id === id) return CATEGORIES[i];
    return CATEGORIES[CATEGORIES.length - 1];
  }

  /* ---------------------------------------------------------
     Persisted state: what has been read, what has been
     dismissed, and the user's preferences (§100.8–§100.10).
     --------------------------------------------------------- */
  var DEFAULT_PREFS = {
    push: false, inApp: true, sound: true, haptics: true, badge: true,
    quietFrom: 22, quietTo: 7, quiet: false,
    preview: true, sensitivePreview: false,
    cats: {}, types: {}
  };

  function prefs() {
    var p = P();
    p.notify = p.notify || {};
    for (var k in DEFAULT_PREFS) {
      if (p.notify[k] === undefined) {
        p.notify[k] = (k === 'cats' || k === 'types') ? {} : DEFAULT_PREFS[k];
      }
    }
    /* Every category is on until the user says otherwise. */
    CATEGORIES.forEach(function (c) {
      if (p.notify.cats[c.id] === undefined) p.notify.cats[c.id] = true;
    });
    return p.notify;
  }

  /* Preferences gate the build, so changing one must invalidate it. The
     shell calls this after writing a preference. */
  function prefsChanged() { touch(); }

  function readSet() {
    var p = P();
    p.notifyRead = p.notifyRead || {};
    return p.notifyRead;
  }

  function actionedSet() {
    var p = P();
    p.notifyActed = p.notifyActed || {};
    return p.notifyActed;
  }

  /* §100.13 — a dismissal applies to *this* occurrence, not to the event
     for all time. "3 tasks left today" dismissed this morning must be able
     to come back tomorrow; a permanent tombstone would silence it forever. */
  function dismissedSet() {
    var p = P();
    p.notifyGone = p.notifyGone || {};
    return p.notifyGone;
  }

  /* Which instance of a recurring event this is. Anything that recurs daily
     stamps the day; anything tied to a specific record stamps the record. */
  function occurrenceOf(src, made) {
    if (src.occurrence === 'day' || !made.entity) {
      var d = new Date();
      return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();
    }
    return String(made.entity);
  }

  /* §100.19 — state is pruned to what is still live plus a short tail, so
     localStorage cannot grow without bound. */
  function prune(live) {
    var keep = {};
    live.forEach(function (n) { keep[n.id] = 1; });
    [readSet(), dismissedSet(), actionedSet()].forEach(function (set) {
      var keys = Object.keys(set);
      if (keys.length <= 120) return;
      keys.forEach(function (k) {
        if (!keep[k] && k.indexOf('group:') !== 0) delete set[k];
      });
    });
  }

  /* ---------------------------------------------------------
     §100.5 — what each tool would tell the user about.

     A source describes an event, not a message: the engine asks
     it whether the event is true right now, and the source
     answers from the same context the tool screen reads. That is
     why the notification list can never claim "3 tasks left"
     when the user has none.
     --------------------------------------------------------- */
  var SOURCES = [
    {
      id: 'prayer.next', tool: 'prayer', cat: 'faith', type: 'prayerReminder',
      priority: 'normal', expiresMins: 60, occurrence: 'day',
      build: function (c) {
        var st = c.prayerState();
        if (st.minutes > 45) return null;
        return {
          title: t('n.prayer.title', { name: t('prayer.' + st.next.key) }),
          body: t('n.prayer.body', { time: L.time(st.next.h, st.next.m), n: Math.round(st.minutes) }),
          ago: 0, deepLink: 'tool:prayer', action: { key: 'n.act.viewPrayer', act: 'tool:prayer' },
          entity: st.next.key
        };
      }
    },
    {
      id: 'bills.overdue', tool: 'bills', cat: 'finance', type: 'billOverdue',
      priority: 'high', sensitive: true,
      build: function (c) {
        var b = c.bills();
        if (!b.overdueCount) return null;
        return {
          title: t('n.bill.title', { n: b.overdueCount }),
          body: t('n.bill.body', { amount: L.money(b.overdue) }),
          bodyPrivate: t('n.bill.private'),
          ago: 180, deepLink: 'tool:bills', action: { key: 'n.act.pay', act: 'tool:bills' },
          entity: 'overdue'
        };
      }
    },
    {
      id: 'bills.due', tool: 'bills', cat: 'finance', type: 'billDue',
      priority: 'normal', sensitive: true,
      build: function (c) {
        var b = c.bills();
        var soon = b.list.filter(function (x) { return x.state === 'due'; })[0];
        if (!soon) return null;
        return {
          title: t('n.billDue.title', { name: soon.name }),
          body: soon.dueLabel + ' · ' + L.money(soon.amount),
          bodyPrivate: soon.dueLabel,
          ago: 640, deepLink: 'tool:bills', action: { key: 'n.act.pay', act: 'tool:bills' },
          entity: soon.name
        };
      }
    },
    {
      id: 'markets.move', tool: 'markets', cat: 'markets', type: 'marketMove',
      priority: 'normal',
      build: function (c) {
        var ex = c.exchange();
        var ix = ex ? ex.indices[0] : null;
        if (!ix || Math.abs(ix.pct) < 0.5) return null;
        return {
          title: t('n.market.title', { name: ix.name, pct: c.pct(ix.pct) }),
          body: t('n.market.body', { value: L.num(ix.value, { maximumFractionDigits: 2 }),
            exchange: ex.name }),
          ago: 2, deepLink: 'toolstate:markets:detail:indices|' + ix.sym,
          action: { key: 'n.act.viewMarket', act: 'tool:markets' },
          entity: ix.sym
        };
      }
    },
    {
      id: 'parcel.transit', tool: 'parcel', cat: 'travel', type: 'parcelUpdate',
      priority: 'normal',
      build: function (c) {
        var p = LUME_DATA.PARCELS.filter(function (x) { return x.state === 'live'; })[0];
        if (!p) return null;
        return {
          title: t('n.parcel.title', { item: p.item }),
          body: t('n.parcel.body', { carrier: p.carrier, eta: p.eta }),
          ago: 18, deepLink: 'toolstate:parcel:parcel:' + p.ref,
          action: { key: 'n.act.track', act: 'tool:parcel' },
          entity: p.ref
        };
      }
    },
    {
      id: 'flights.delay', tool: 'flights', cat: 'travel', type: 'flightChange',
      priority: 'high',
      build: function () {
        var f = LUME_DATA.FLIGHTS.filter(function (x) { return x.delay > 15; })[0];
        if (!f) return null;
        return {
          title: t('n.flight.title', { no: f.no }),
          body: t('n.flight.body', { n: f.delay, eta: f.eta, to: f.to }),
          ago: 34, deepLink: 'toolstate:flights:flight:' + f.no,
          action: { key: 'n.act.viewFlight', act: 'tool:flights' },
          entity: f.no
        };
      }
    },
    {
      id: 'trains.delay', tool: 'trains', cat: 'travel', type: 'trainDelay',
      priority: 'normal',
      build: function (c) {
        var tr = LUME_DATA.TRAINS.filter(function (x) { return x.delay > 0; })[0];
        if (!tr) return null;
        return {
          title: t('n.train.title', { name: tr.name }),
          body: t('n.train.body', { n: tr.delay, next: tr.next }),
          ago: 52, deepLink: 'toolstate:trains:train:' + tr.no,
          action: { key: 'n.act.viewTrain', act: 'tool:trains' },
          entity: tr.no
        };
      }
    },
    {
      id: 'weather.alert', tool: 'weather', cat: 'weather', type: 'severeWeather',
      /* §100.6 — a severe-weather advisory is the one thing in this product
         that is allowed through quiet hours. */
      priority: 'critical', expiresMins: 720,
      build: function (c) {
        var w = c.weather();
        if (!w.alert) return null;
        return {
          title: w.alert.title, body: w.alert.text,
          ago: 96, deepLink: 'tool:weather',
          action: { key: 'n.act.viewWeather', act: 'tool:weather' }, entity: 'alert'
        };
      }
    },
    {
      id: 'weather.tomorrow', tool: 'weather', cat: 'weather', type: 'forecast',
      priority: 'low', occurrence: 'day', expiresMins: 900,
      build: function (c) {
        var w = c.weather();
        var d = w.daily[1];
        return {
          title: t('n.weather.title', { city: P().city }),
          body: t('weather.hilo', { hi: L.temp(d.hi), lo: L.temp(d.lo) }) + ' · ' +
                L.num(d.rain) + '% ' + t('weather.rain'),
          ago: 300, deepLink: 'tool:weather', entity: 'tomorrow'
        };
      }
    },
    {
      id: 'loadshed.next', tool: 'loadshed', cat: 'system', type: 'outage',
      priority: 'normal',
      build: function (c) {
        var ls = c.loadshed();
        return {
          title: ls.now ? t('n.outage.now') : t('n.outage.title', { time: ls.slot.from }),
          body: ls.area + ' · ' + ls.slot.duration,
          ago: 12, deepLink: 'tool:loadshed', entity: ls.slot.from
        };
      }
    },
    {
      id: 'documents.expiring', tool: 'documents', cat: 'documents', type: 'docExpiry',
      priority: 'high', sensitive: true,
      build: function (c) {
        var d = c.documents();
        var soon = d.list.filter(function (x) { return x.days !== null && x.days >= 0 && x.days < 45; })[0];
        if (!soon) return null;
        return {
          title: t('n.doc.title', { name: soon.name }),
          body: t('n.doc.body', { n: soon.days, date: soon.expires }),
          bodyPrivate: t('n.doc.private'),
          ago: 1440, deepLink: 'tool:documents',
          action: { key: 'n.act.viewDoc', act: 'tool:documents' }, entity: soon.name
        };
      }
    },
    {
      id: 'subs.renewal', tool: 'subs', cat: 'finance', type: 'subRenewal',
      priority: 'normal', sensitive: true,
      build: function (c) {
        var s = c.subscriptions();
        if (!s.next || s.next.days > 7) return null;
        return {
          title: t('n.sub.title', { name: s.next.name }),
          body: t('n.sub.body', { n: s.next.days, amount: L.money(s.next.price) }),
          bodyPrivate: t('n.sub.private', { n: s.next.days }),
          ago: 720, deepLink: 'tool:subs', entity: s.next.name
        };
      }
    },
    {
      id: 'todos.today', tool: 'todos', cat: 'reminders', type: 'taskReminder',
      priority: 'normal', occurrence: 'day', expiresMins: 720,
      build: function (c) {
        var td = c.todos();
        var left = td.today.filter(function (x) { return !x.done; });
        if (!left.length) return null;
        return {
          title: t('notif.tasksLeft', { n: left.length }),
          body: t('notif.taskNext', { title: left[0].label }),
          ago: 200, deepLink: 'tool:todos',
          action: { key: 'n.act.complete', act: 'tool:todos' }, entity: 'today'
        };
      }
    },
    {
      id: 'meds.dose', tool: 'meds', cat: 'health', type: 'medication',
      priority: 'high', sensitive: true, occurrence: 'day', expiresMins: 240,
      build: function (c) {
        var m = c.meds();
        if (!m.next || m.next.state === 'done') return null;
        return {
          title: t('n.med.title'), body: t('n.med.body', { at: m.next.at }),
          bodyPrivate: t('n.med.private'),
          ago: 8, deepLink: 'tool:meds', entity: m.next.name
        };
      }
    },
    {
      id: 'habits.streak', tool: 'habits', cat: 'personal', type: 'habitReminder',
      priority: 'low', occurrence: 'day', expiresMins: 600,
      build: function (c) {
        var h = c.habits();
        if (h.doneToday >= h.list.length) return null;
        return {
          title: t('n.habit.title', { n: h.list.length - h.doneToday }),
          body: t('n.habit.body', { n: h.streak }),
          ago: 420, deepLink: 'tool:habits', entity: 'today'
        };
      }
    }
  ];

  /* ---------------------------------------------------------
     Building the live list
     --------------------------------------------------------- */
  function allowed(src) {
    /* A notification obeys the same visibility rules as its tool: a hidden
       feature cannot reach the user through the notification centre either
       (§64). */
    var f = featureFor(src.tool);
    if (!f || !isVisible(f)) return false;
    var p = prefs();
    if (p.cats[src.cat] === false) return false;
    if (p.types[src.id] === false) return false;
    return true;
  }

  /* Every call constructed fifteen tool contexts and recomputed prayer
     times, weather, bills, documents, subscriptions, meds and habits — three
     times per render of the centre, and once a minute forever. The result is
     stable within a tick, so it is memoised and invalidated on any write. */
  var cache = null, cacheAt = 0, cacheVersion = 0;
  var CACHE_MS = 4000;

  function invalidate() { cache = null; }

  function build(opts) {
    opts = opts || {};
    var now = Date.now();
    if (!opts.fresh && cache && now - cacheAt < CACHE_MS && cacheVersion === version) {
      return cache;
    }
    var out = [], seen = {};

    SOURCES.forEach(function (src) {
      /* The gate is inside the guard too: a throw here used to abort the
         whole build and take every remaining source with it. */
      var made, ctx;
      try {
        if (!allowed(src)) return;
        ctx = ctxFor(src.tool);
        if (!ctx) return;
        made = src.build(ctx);
      } catch (e) {
        if (window.console && window.console.warn) {
          window.console.warn('Lume notification source "' + src.id + '" failed', e);
        }
        return;
      }
      if (!made || !made.title) return;

      var id = src.id + (made.entity ? ':' + made.entity : '');
      var occurrence = occurrenceOf(src, made);
      var baseAgo = made.ago === undefined ? 0 : made.ago;
      var createdAt = ANCHOR - baseAgo * 60000;
      var agoMins = Math.max(0, Math.round((now - createdAt) / 60000));
      var expiresAt = src.expiresMins ? createdAt + src.expiresMins * 60000 : null;
      var expired = !!(expiresAt && now > expiresAt);

      /* A dismissal only silences the occurrence it was made against. */
      if (dismissedSet()[id] === occurrence) return;

      /* §100.13 — the same event said twice in a short window is one event. */
      var dedupeKey = src.id + '|' + made.title;
      if (seen[dedupeKey] !== undefined && Math.abs(seen[dedupeKey] - agoMins) < 30) return;
      seen[dedupeKey] = agoMins;

      out.push({
        id: id, sourceId: src.id, tool: src.tool, category: src.cat, type: src.type,
        entityId: made.entity || null, occurrence: occurrence,
        priority: src.priority, priorityRank: PRIORITY[src.priority] || 1,
        title: made.title,
        body: bodyFor(src, made),
        image: made.image || null,
        createdAt: createdAt, expiresAt: expiresAt, agoMins: agoMins,
        deepLink: made.deepLink, action: made.action,
        icon: category(src.cat).icon,
        read: !!readSet()[id],
        actioned: !!actionedSet()[id],
        expired: expired,
        /* §100.13 — a group is repetition of one event, not a category of
           unrelated ones. Grouping travel + parcels + trains told the user
           nothing; four updates about the same index tells them a lot. */
        groupId: src.id
      });
    });

    /* §100.6 — priority first, then recency. An expired entry sinks. */
    out.sort(function (a, b) {
      if (a.expired !== b.expired) return a.expired ? 1 : -1;
      if (a.priorityRank !== b.priorityRank) return b.priorityRank - a.priorityRank;
      return a.agoMins - b.agoMins;
    });

    if (!opts.raw) prune(out);
    cache = out; cacheAt = now; cacheVersion = version;
    return out;
  }

  /* §100.16 — a sensitive notification withholds its detail unless the user
     has asked for previews of sensitive content. */
  function bodyFor(src, made) {
    var p = prefs();
    if (!p.preview) return t('n.hidden');
    if (src.sensitive && !p.sensitivePreview && made.bodyPrivate) return made.bodyPrivate;
    return made.body;
  }

  /* §100.13 — three or more updates from the *same* event become one row,
     so the user reads "KSE-100 activity — 4 updates" rather than four
     near-identical lines. Unrelated events are never folded together. */
  function grouped(rows) {
    var byGroup = {}, order = [];
    rows.forEach(function (n) {
      if (!byGroup[n.groupId]) { byGroup[n.groupId] = []; order.push(n.groupId); }
      byGroup[n.groupId].push(n);
    });
    var out = [];
    order.forEach(function (g) {
      var items = byGroup[g];
      if (items.length < 3) { out = out.concat(items); return; }
      var head = items[0];
      out.push(head);
      out.push({
        id: 'group:' + g, grouped: true, groupId: g,
        category: head.category, icon: head.icon,
        title: t('n.group.title', { name: head.title }),
        body: t('n.group.body', { n: items.length - 1 }),
        agoMins: items[1].agoMins, priorityRank: 0,
        items: items.slice(1),
        read: items.slice(1).every(function (x) { return x.read; })
      });
    });
    return out;
  }

  /* An expired notification stays in history but stops presenting as
     something to act on (§100.13, §100.21). */
  function list(filter) {
    var all = build();
    if (filter === 'unread') return all.filter(function (n) { return !n.read && !n.expired; });
    if (filter === 'important') return all.filter(function (n) { return n.priorityRank >= 2 && !n.expired; });
    if (filter && filter !== 'all') return all.filter(function (n) { return n.category === filter; });
    return all;
  }

  function unreadCount() {
    return build().filter(function (n) { return !n.read && !n.expired; }).length;
  }

  /* Rows and groups are addressed the same way, but a group id is
     synthetic — it must never be written into persisted state. */
  function resolve(id, rows) {
    var flat = rows || build();
    var direct = flat.filter(function (x) { return x.id === id; })[0];
    if (direct) return [direct];
    if (String(id).indexOf('group:') === 0) {
      var g = String(id).slice(6);
      return flat.filter(function (x) { return x.groupId === g; });
    }
    return [];
  }

  function markRead(id, rows) {
    if (!id) {
      build().forEach(function (n) { readSet()[n.id] = 1; });
    } else {
      resolve(id, rows).forEach(function (n) { readSet()[n.id] = 1; });
    }
    touch();
    deps.save();
  }

  function markActioned(id, rows) {
    resolve(id, rows).forEach(function (n) {
      actionedSet()[n.id] = 1;
      readSet()[n.id] = 1;
    });
    touch();
    deps.save();
  }

  function dismiss(id, rows) {
    resolve(id, rows).forEach(function (n) { dismissedSet()[n.id] = n.occurrence; });
    touch();
    deps.save();
  }

  /* The control says "Restore dismissed", so it restores dismissed — it does
     not also mark everything unread. */
  function restoreAll() {
    P().notifyGone = {};
    touch();
    deps.save();
  }

  /* ---------------------------------------------------------
     §100.10 quiet hours — suppression applies to *presentation*.
     Nothing is lost: the centre still holds everything.
     --------------------------------------------------------- */
  function inQuietHours() {
    var p = prefs();
    if (!p.quiet) return false;
    var h = new Date().getHours();
    return p.quietFrom > p.quietTo ? (h >= p.quietFrom || h < p.quietTo)
                                   : (h >= p.quietFrom && h < p.quietTo);
  }

  function mayInterrupt(n) {
    var p = prefs();
    if (!p.inApp) return false;
    if (!inQuietHours()) return n.priorityRank >= 2;
    return n.priorityRank >= 3;          /* only critical breaks quiet hours */
  }

  /* ---------------------------------------------------------
     §100.5/§100.11 — the push bridge. Permission is asked for
     in context, never cold, and a refusal is final.
     --------------------------------------------------------- */
  function pushSupported() {
    return typeof window !== 'undefined' && 'Notification' in window;
  }

  function pushPermission() {
    if (!pushSupported()) return 'unsupported';
    try { return window.Notification.permission; } catch (e) { return 'unsupported'; }
  }

  function pushEnabled() {
    return prefs().push && pushPermission() === 'granted';
  }

  function requestPush(done) {
    if (!pushSupported()) { done && done('unsupported'); return; }
    try {
      var r = window.Notification.requestPermission(function (res) { finish(res); });
      if (r && typeof r.then === 'function') r.then(finish);
    } catch (e) { done && done('error'); }

    function finish(result) {
      if (result === 'granted') { prefs().push = true; deps.save(); }
      done && done(result);
    }
  }

  /* Sent when the user is away; the same event that would have been an
     in-app banner had they been here (§100.12). */
  function push(n) {
    if (!pushEnabled()) return false;
    if (inQuietHours() && n.priorityRank < 3) return false;
    try {
      var note = new window.Notification(n.title, {
        body: n.body, tag: n.id, icon: 'favicon.ico', silent: !prefs().sound
      });
      note.onclick = function () {
        window.focus();
        deps.open(n.deepLink);
        note.close();
      };
      return true;
    } catch (e) { return false; }
  }

  /* ---------------------------------------------------------
     §100.12 — the event reaches the user exactly once, through
     whichever surface is right for where they are: a push when
     they are away, a banner when they are here and it matters,
     the centre otherwise. Nothing is presented twice.
     --------------------------------------------------------- */
  function presentedSet() {
    var p = P();
    p.notifySeen = p.notifySeen || {};
    return p.notifySeen;
  }

  /* The next thing worth interrupting for, or null. */
  function nextToPresent() {
    var seen = presentedSet();
    var candidates = build().filter(function (n) {
      return !n.read && !n.expired && !seen[n.id];
    });
    return candidates[0] || null;
  }

  function markPresented(n) {
    presentedSet()[n.id] = 1;
    touch();
    deps.save();
  }

  /* Called on a tick by the shell. Returns what it did, so the shell can
     draw a banner without deciding policy itself. */
  function present(away) {
    var n = nextToPresent();
    if (!n) return null;

    if (away) {
      if (push(n)) { markPresented(n); return { surface: 'push', notification: n }; }
      return null;                      /* keep it for when they come back */
    }
    if (!mayInterrupt(n)) {
      /* Not worth interrupting for: it waits in the centre, which is a
         surface too. Mark it so it is not reconsidered every tick. */
      markPresented(n);
      return { surface: 'centre', notification: n };
    }
    markPresented(n);
    return { surface: 'banner', notification: n };
  }

  return {
    CATEGORIES: CATEGORIES, PRIORITY: PRIORITY, SOURCES: SOURCES,
    present: present, nextToPresent: nextToPresent, markActioned: markActioned,
    category: category, prefs: prefs, prefsChanged: prefsChanged,
    list: list, grouped: grouped, unreadCount: unreadCount,
    markRead: markRead, dismiss: dismiss, restoreAll: restoreAll,
    inQuietHours: inQuietHours, mayInterrupt: mayInterrupt,
    pushSupported: pushSupported, pushPermission: pushPermission,
    pushEnabled: pushEnabled, requestPush: requestPush, push: push
  };
};
