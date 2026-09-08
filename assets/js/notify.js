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
window.LUME_NOTIFY = function (deps) {
  'use strict';

  var t = deps.t, L = deps.L, store = deps.store;
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

  function readSet() {
    var p = P();
    p.notifyRead = p.notifyRead || {};
    return p.notifyRead;
  }

  function dismissedSet() {
    var p = P();
    p.notifyGone = p.notifyGone || {};
    return p.notifyGone;
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
      priority: 'normal', expiresMins: 60,
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
        var p = window.LUME_DATA.PARCELS.filter(function (x) { return x.state === 'live'; })[0];
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
        var f = window.LUME_DATA.FLIGHTS.filter(function (x) { return x.delay > 15; })[0];
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
        var tr = window.LUME_DATA.TRAINS.filter(function (x) { return x.delay > 0; })[0];
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
      priority: 'high',
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
      priority: 'low',
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
      priority: 'normal',
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
      priority: 'high', sensitive: true,
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
      priority: 'low',
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

  function build() {
    var out = [];
    SOURCES.forEach(function (src) {
      if (!allowed(src)) return;
      var made;
      try { made = src.build(ctxFor(src.tool)); } catch (e) { made = null; }
      if (!made) return;

      var id = src.id + (made.entity ? ':' + made.entity : '');
      if (dismissedSet()[id]) return;

      out.push({
        id: id, sourceId: src.id, tool: src.tool, category: src.cat, type: src.type,
        priority: src.priority, priorityRank: PRIORITY[src.priority] || 1,
        title: made.title,
        body: bodyFor(src, made),
        agoMins: made.ago === undefined ? 0 : made.ago,
        deepLink: made.deepLink, action: made.action,
        icon: category(src.cat).icon,
        read: !!readSet()[id],
        expiresMins: src.expiresMins || null,
        groupId: src.cat
      });
    });

    /* §100.6 — priority first, then recency. */
    out.sort(function (a, b) {
      if (a.priorityRank !== b.priorityRank) return b.priorityRank - a.priorityRank;
      return a.agoMins - b.agoMins;
    });
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

  /* §100.13 — repetition becomes one entry, not four. */
  function grouped(list) {
    var byGroup = {}, order = [];
    list.forEach(function (n) {
      if (!byGroup[n.groupId]) { byGroup[n.groupId] = []; order.push(n.groupId); }
      byGroup[n.groupId].push(n);
    });
    var out = [];
    order.forEach(function (g) {
      var items = byGroup[g];
      if (items.length <= 2) { out = out.concat(items); return; }
      var head = items[0];
      out.push(head);
      out.push({
        id: 'group:' + g, grouped: true, category: g, icon: category(g).icon,
        title: t('n.group.title', { name: t(category(g).key) }),
        body: t('n.group.body', { n: items.length - 1 }),
        agoMins: items[1].agoMins, priorityRank: 0,
        items: items.slice(1),
        read: items.slice(1).every(function (x) { return x.read; })
      });
    });
    return out;
  }

  function list(filter) {
    var all = build();
    if (filter === 'unread') return all.filter(function (n) { return !n.read; });
    if (filter === 'important') return all.filter(function (n) { return n.priorityRank >= 2; });
    if (filter && filter !== 'all') return all.filter(function (n) { return n.category === filter; });
    return all;
  }

  function unreadCount() {
    return build().filter(function (n) { return !n.read; }).length;
  }

  function markRead(id) {
    if (id) readSet()[id] = 1;
    else build().forEach(function (n) { readSet()[n.id] = 1; });
    deps.save();
  }

  function dismiss(id) {
    var n = build().filter(function (x) { return x.id === id; })[0];
    if (n && n.items) n.items.forEach(function (x) { dismissedSet()[x.id] = 1; });
    else dismissedSet()[id] = 1;
    deps.save();
  }

  function restoreAll() {
    var p = P();
    p.notifyGone = {};
    p.notifyRead = {};
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

  return {
    CATEGORIES: CATEGORIES, PRIORITY: PRIORITY, SOURCES: SOURCES,
    category: category, prefs: prefs,
    list: list, grouped: grouped, unreadCount: unreadCount,
    markRead: markRead, dismiss: dismiss, restoreAll: restoreAll,
    inQuietHours: inQuietHours, mayInterrupt: mayInterrupt,
    pushSupported: pushSupported, pushPermission: pushPermission,
    pushEnabled: pushEnabled, requestPush: requestPush, push: push
  };
};
