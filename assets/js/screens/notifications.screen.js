/* ============================================================
   Lume — the notification centre

   The engine decides what is true; this decides how it looks.
   That split is why the engine is not in here: the badge on
   Home's app bar and the banner that appears over whatever is
   showing ask it the same questions, and none of the three is
   the owner of the others.

   Three rules the centre has to keep, all of which are about
   what must never reach it:

     · a notification for a feature this user cannot see is not
       shown, whether it is hidden by faith or by country;
     · a sensitive tool's detail is withheld when previews are
       off — the row says something happened, not what;
     · priority outranks recency, so an important item does not
       fall off the bottom because three ordinary ones arrived.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $, $$, esc } from '../core/dom.js';

export function createNotificationsScreen(ctx) {
  /* The shell's names, bound once, the first time anything here runs —
     which is a render, so the shell is up by then. */
  let bound = false;
  let t, L, UI, NOTIFY, router, profile, feature, visible, fname, toast, applyStrings, refreshBadge;

  /* Which tab or category is selected. It is presentation state, so it
     lives with the screen that presents it rather than in the engine. */
  let notifFilter = 'all';

  function bindShell() {
    if (bound) return;
    bound = true;
    t = ctx.t; L = ctx.L; UI = ctx.ui; NOTIFY = ctx.notify; router = ctx.router;
    refreshBadge = ctx.refreshNotifBadge;
    profile = ctx.profile();
    feature = ctx.eligible.feature; visible = ctx.eligible.visible;
    fname = ctx.eligible.name; toast = ctx.toast; applyStrings = ctx.applyStrings;
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

  /* Whether the centre has ever been shown. The skeleton belongs to
     arriving, not to rendering: the shell renders every screen at boot,
     and a skeleton spent while the screen was hidden is one the user never
     sees — leaving them a blank centre on the first real visit. */
  let everShown = false;
  let settleTimer = null;

  function paintSkeleton() {
    const head = $('#notifHeader'), body = $('#notifBody');
    if (!head || !body) return;
    head.innerHTML = UI.toolHeader({ title: t('nav.notifications'), backLabel: t('a11y.back') });
    body.innerHTML = UI.section({ body: UI.skeleton('row', 4) });
  }

  function renderNotifCentre() {
    var head = $('#notifHeader'), body = $('#notifBody');
    if (!head || !body) return;

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
    refreshBadge();
  }

  return defineScreen({
    id: 'notifications',

    /* Set by the shell when an action changes the filter. */
    setFilter: function (value) { notifFilter = value || 'all'; },
    filter: function () { return notifFilter; },

    template: function () {
      return `
  <section class="screen screen--tool" id="screen-notifications" role="tabpanel" aria-label="Notifications">
    <div id="notifHeader"></div>
    <div id="notifBody"></div>
  </section>
`;
    },

    render: function () {
      bindShell();
      /* While the skeleton is up, a render would replace it with the very
         content it is standing in for. */
      if (settleTimer) return;
      renderNotifCentre();
    },

    /* The shape of what is coming, never a blank screen — once, on the
       first visit. */
    onEnter: function () {
      bindShell();
      if (everShown) { renderNotifCentre(); return; }
      everShown = true;
      paintSkeleton();
      settleTimer = setTimeout(function () {
        settleTimer = null;
        renderNotifCentre();
      }, 90);
    },

    onLeave: function () {
      clearTimeout(settleTimer);
      settleTimer = null;
    }
  });
}
