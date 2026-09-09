/* ============================================================
   Lume — notifications

   The engine decides what is true; the surfaces decide how it
   looks. There are three surfaces and none of them owns the
   others: the badge on Home's app bar, the banner that can
   appear over whatever screen is showing, and the centre, which
   is a screen of its own.

   An event reaches the user through exactly one of them. Push
   when they are away, a banner when they are here and it is
   worth interrupting for, the centre otherwise — never two for
   one event.

   Browser permission is never requested at boot. The user sees
   an explanation first, and a denial is explained rather than
   asked again.
   ============================================================ */
import { $, $$ } from '../core/dom.js';

export function createNotifications(deps) {
  const t = deps.t, L = deps.L, esc = deps.esc, UI = deps.ui;
  const makeEngine = deps.engine;
  const getProfile = deps.profile;
  const store = deps.store;
  const ELIGIBLE = deps.eligible;
  const toolCtx = deps.toolCtx;
  const saveProfile = deps.save;
  const router = deps.router;
  const run = deps.run;
  const sheetOpen = deps.sheetOpen, sheetClose = deps.sheetClose;
  const toast = deps.toast;
  const applyStrings = deps.applyStrings;
  const renderCentre = deps.renderCentre;
  /* Which filter the centre is showing. Resolving against what is on
     screen matters: under a filter, a group holds different members than
     it would in the unfiltered list. */
  const centreFilter = deps.centreFilter;
  const feature = ELIGIBLE.feature, visible = ELIGIBLE.visible;

  var NOTIFY = makeEngine({
    t: t, L: L, store: store,
    profile: getProfile,
    ctx: function (id) { return toolCtx(id); },
    featureFor: feature, isVisible: visible,
    save: saveProfile,
    open: function (link) { run(link); }
  });


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
    if (result && result.surface === 'banner' && router.current() !== 'notifications') {
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
        if (c.faith && !getProfile().islamic) return false;
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
        return '<p class="npref__tool">' + esc(ELIGIBLE.name(f)) + '</p><div class="list">' +
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
    if (router.current() === 'notifications') renderCentre();
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
      var rows = NOTIFY.list(router.current() === 'notifications' ? centreFilter() : 'all');
      var view = NOTIFY.grouped(rows);
      var n = view.filter(function (x) { return x.id === id; })[0];
      NOTIFY.markRead(id, rows);
      hideBanner();
      if (n && n.grouped) { renderCentre(); return; }
      if (n && n.deepLink) { run(n.deepLink); renderNotifBadge(); return; }
      renderCentre();
      return;
    }
    var act = e.target.closest('[data-notif-act]');
    if (act) {
      var aid = act.dataset.notifAct;
      var rows2 = NOTIFY.list('all');
      var an = rows2.filter(function (x) { return x.id === aid; })[0];
      /* §100.21 — acting on a notification is a state of its own. */
      NOTIFY.markActioned(aid, rows2);
      if (an && an.action) run(an.action.act);
      renderNotifBadge();
      return;
    }
    var gone = e.target.closest('[data-notif-dismiss]');
    if (gone) {
      NOTIFY.dismiss(gone.dataset.notifDismiss, NOTIFY.list(centreFilter()));
      renderCentre();
    }
  });




  return {
    engine: NOTIFY,
    renderBadge: renderNotifBadge,
    renderPrefs: renderNotifPrefs,
    renderPushAsk: renderPushAsk,
    tick: notifyTick
  };
}
