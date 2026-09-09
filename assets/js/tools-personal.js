/* ============================================================
   Lume — Personal screens  (Master Spec §57–§79)

   Personal data is the most sensitive material in the product,
   so these screens follow §61, §62 and §104: values are masked,
   secure records say they are secure, and nothing here is
   promoted onto Home just because the tool exists.

   Composition still varies by job — Expenses is a financial
   dashboard, Documents a secure records manager, Recipes a
   visual library, Habits a tracker.
   ============================================================ */
import { LUME_UI } from './toolkit.js';
import { LUME_DATA } from './tooldata.js';
import { LUME_TOOLS } from './tools.js';
(function () {
  'use strict';

  var UI = LUME_UI;
  var D = LUME_DATA;
  var T = LUME_TOOLS;

  /* ---------------------------------------------------------
     §76 Expenses — financial dashboard, very high density
     --------------------------------------------------------- */
  T.register('expenses', function (c) {
    var e = c.expenses();
    var range = c.state('range') || 'month';
    var cat = c.filter('cat', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();

    var tx = e.transactions.filter(function (x) {
      if (cat !== 'all' && x.catId !== cat) return false;
      if (query && (x.title + ' ' + x.catLabel + ' ' + x.method).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    tx = c.sortBy(tx, {
      date: function (x) { return x.order; },
      amount: function (x) { return Math.abs(x.amount); },
      cat: function (x) { return x.catLabel; }
    }, 'date', 'desc');

    return UI.section({ body: UI.segmented({ id: 'exprange', label: c.t('expenses.range'), items: [
        { value: 'week', label: c.t('common.week'), on: range === 'week', act: 'toolstate:expenses:range:week' },
        { value: 'month', label: c.t('common.month'), on: range === 'month', act: 'toolstate:expenses:range:month' },
        { value: 'year', label: c.t('common.year'), on: range === 'year', act: 'toolstate:expenses:range:year' }
      ] }) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('expenses.spent'),
        value: c.money(e.spent),
        caption: c.t('expenses.ofBudget', { budget: c.money(e.budget), pct: Math.round(e.ratio * 100) + '%' }),
        aside: UI.progressRing({ value: e.ratio, centre: Math.round(e.ratio * 100) + '%', label: c.t('expenses.budgetUse') }),
        stats: [
          { value: c.money(e.income), label: c.t('expenses.income') },
          { value: c.money(e.balance), label: c.t('expenses.balance') },
          { value: c.money(e.dailyAvg), label: c.t('expenses.dailyAvg') }
        ],
        foot: UI.progressBar({ value: e.ratio, tone: e.ratio > 0.9 ? 'warn' : null, label: c.t('expenses.budgetUse') })
      }) }) +
      UI.section({ title: c.t('expenses.trend'), body: UI.card(
        UI.barChart({ values: e.trend, labels: e.trendLabels, highlight: e.trend.length - 1,
          label: c.t('expenses.trend'), caption: c.t('expenses.trendCap', { avg: c.money(e.dailyAvg) }) })) }) +
      UI.section({ title: c.t('expenses.categories'), body: UI.card(UI.donut({
        label: c.t('expenses.categories'),
        centre: c.money(e.spent), centreSub: c.t('common.total'),
        slices: e.categories.map(function (x) {
          return { label: x.label, value: x.amount, color: x.color, display: c.money(x.amount) };
        })
      })) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('expenses.search'), target: 'expenses', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'cat', label: c.t('expenses.category'), items: [
        { value: 'all', label: c.t('common.all'), on: cat === 'all' }
      ].concat(D.EXPENSE_CATEGORIES.map(function (x) {
        return { value: x.id, label: x.label, icon: x.icon, on: cat === x.id };
      })) }], 'expenses') }) +
      UI.section({ body: UI.sortBar({ tool: 'expenses', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'date', label: c.t('common.date') },
          { value: 'amount', label: c.t('common.amount') },
          { value: 'cat', label: c.t('expenses.category') }
        ], 'date', 'desc') }) }) +
      UI.section({ title: c.t('expenses.transactions'), body: tx.length
        ? UI.rows(tx.map(function (x) {
            return UI.richRow({
              icon: x.icon, iconTone: x.income ? 'accent' : null,
              title: x.title, sub: x.catLabel,
              meta: [x.when, x.method],
              value: (x.income ? '+' : '−') + c.money(Math.abs(x.amount)),
              cls: x.income ? 'is-income' : ''
            });
          }))
        : UI.emptyState({ icon: 'i-wallet', title: c.t('expenses.noMatch'),
            text: c.t('expenses.noMatchText'),
            action: { label: c.t('common.all'), act: 'toolstate:expenses:cat:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('expenses.budgets'), body: UI.card(e.budgets.map(function (b) {
        return UI.meterRow({ label: b.label, value: c.money(b.spent) + ' / ' + c.money(b.limit),
          pct: b.spent / b.limit, tone: b.spent > b.limit ? 'warn' : null });
      }).join('')) }) +
      UI.section({ title: c.t('expenses.recurring'), body: UI.rows(e.recurring.map(function (r) {
        return UI.compactRow({ icon: 'i-refresh', label: r.label, sub: r.when, value: c.money(r.amount) });
      })) }) +
      UI.section({ title: c.t('expenses.insights'), body: UI.rows(e.insights.map(function (i) {
        return UI.richRow({ icon: i.icon, iconTone: 'accent', title: i.title, sub: i.text });
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('expenses.add'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('expenses.adding') },
        { label: c.t('common.export'), icon: 'i-download', act: 'export:expenses' }]) });
  });

  /* ---------------------------------------------------------
     §77 Savings goals — goal dashboard
     --------------------------------------------------------- */
  T.register('goals', function (c) {
    var g = c.goals();
    if (!g.list.length) {
      return UI.section({ body: UI.emptyState({
        icon: 'i-target', title: c.t('goals.empty.title'), text: c.t('goals.empty.text'),
        action: { label: c.t('goals.create'), act: 'toast:' + c.t('goals.creating'), icon: 'i-plus' } }) });
    }
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('goals.saved'),
        value: c.money(g.saved),
        caption: c.t('goals.ofTarget', { target: c.money(g.target) }),
        aside: UI.progressRing({ value: g.ratio, centre: Math.round(g.ratio * 100) + '%', label: c.t('goals.progress') }),
        stats: [
          { value: String(g.list.length), label: c.t('goals.active') },
          { value: c.money(g.monthly), label: c.t('goals.monthly') },
          { value: g.nextComplete, label: c.t('goals.nextDone') }
        ]
      }) }) +
      UI.section({ title: c.t('goals.yours'), body: g.list.map(function (x) {
        return UI.card(
          '<div class="goal">' +
            '<span class="goal__icon goal__icon--' + x.tone + '">' + UI.ico(x.icon) + '</span>' +
            '<div class="goal__body">' +
              '<p class="goal__name">' + UI.esc(x.name) + '</p>' +
              '<p class="goal__meta">' + c.money(x.saved) + ' ' + UI.esc(c.t('common.of')) + ' ' + c.money(x.target) +
                ' · ' + UI.esc(c.t('goals.by', { date: x.by })) + '</p>' +
            '</div>' +
            '<span class="goal__pct">' + Math.round(x.pct * 100) + '%</span>' +
          '</div>' +
          UI.progressBar({ value: x.pct, label: x.name }) +
          '<p class="goal__foot">' + UI.esc(c.t('goals.remaining', { amount: c.money(x.target - x.saved) })) + ' · ' +
            UI.esc(c.t('goals.projection', { date: x.projected })) + '</p>');
      }).join('') }) +
      UI.section({ title: c.t('goals.contributions'), body: UI.card(
        UI.barChart({ values: g.history, labels: g.historyLabels, highlight: g.history.length - 1,
          label: c.t('goals.contributions') })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('goals.contribute'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('goals.contributing') },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:goals' }]) });
  });

  /* ---------------------------------------------------------
     §78 Subscriptions — recurring expense manager
     --------------------------------------------------------- */
  T.register('subs', function (c) {
    var s = c.subscriptions();
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = c.sortBy(s.list.filter(function (x) {
      return !query || (x.name + ' ' + x.cat).toLowerCase().indexOf(query) !== -1;
    }), {
      renews: function (x) { return x.days; },
      price: function (x) { return x.price; },
      name: function (x) { return x.name; }
    }, 'renews', 'asc');

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('subs.monthly'),
        value: c.money(s.monthly),
        caption: c.t('subs.yearly', { amount: c.money(s.yearly) }),
        stats: [
          { value: String(s.list.length), label: c.t('subs.active') },
          { value: s.next.name, label: c.t('subs.nextRenewal') },
          { value: c.t('common.inDays', { n: s.next.days }), label: c.t('subs.renewsIn') }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('subs.search'), target: 'subs', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.sortBar({ tool: 'subs', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'renews', label: c.t('subs.renewal') },
          { value: 'price', label: c.t('common.amount') },
          { value: 'name', label: c.t('common.name') }
        ], 'renews', 'asc') }) }) +
      UI.section({ title: c.t('subs.all'), body: UI.rows(shown.map(function (x) {
        return UI.richRow({
          logo: x.logo, logoTone: 'var(--tone-' + x.tone + ')',
          title: x.name, sub: x.cat,
          meta: [x.cycle, c.t('subs.renews', { date: x.renews })],
          badge: x.days <= 7 ? { label: c.t('common.inDays', { n: x.days }), tone: 'warn' } : null,
          value: c.money(x.price), valueSub: c.t('common.perMonth'),
          act: 'toast:' + x.name, chevron: true
        });
      })) }) +
      UI.section({ title: c.t('subs.byCategory'), body: UI.card(UI.donut({
        label: c.t('subs.byCategory'), centre: c.money(s.monthly), centreSub: c.t('common.perMonth'),
        slices: s.byCategory
      })) }) +
      UI.section({ title: c.t('subs.timeline'), body: UI.timeline(s.list.slice(0, 4).map(function (x) {
        return { time: x.renews, title: x.name, sub: x.cat, value: c.money(x.price), state: x.days <= 7 ? 'now' : '' };
      })) });
  });

  /* ---------------------------------------------------------
     §67 Documents — secure records manager, very high density
     --------------------------------------------------------- */
  T.register('documents', function (c) {
    var d = c.documents();
    var cat = c.filter('cat', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();

    function keep(x) {
      if (cat !== 'all' && x.cat !== cat) return false;
      if (query && (x.name + ' ' + x.cat + ' ' + x.holder).toLowerCase().indexOf(query) === -1) return false;
      return true;
    }
    var groups = d.groups.map(function (g) {
      return { label: g.label, items: c.sortBy(g.items.filter(keep), {
        expiry: function (x) { return x.days === null ? 1e9 : x.days; },
        cat: function (x) { return x.cat; },
        updated: function (x) { return x.files; }
      }, 'expiry', 'asc') };
    }).filter(function (g) { return g.items.length; });

    return UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('docs.vault'),
        value: String(d.list.length),
        caption: d.expiring ? c.t('docs.expiringSoon', { n: d.expiring }) : c.t('docs.allValid'),
        aside: '<span class="lockmark">' + UI.ico('i-lock') + '</span>',
        stats: [
          { value: String(d.expired), label: c.t('docs.expired') },
          { value: String(d.expiring), label: c.t('docs.expiring') },
          { value: String(d.files), label: c.t('docs.files') }
        ]
      }) }) +
      (d.expiring ? UI.section({ body: UI.noteCard({ tone: 'warn', icon: 'i-alert',
        title: c.t('docs.renew.title', { n: d.expiring }), text: c.t('docs.renew.text') }) }) : '') +
      UI.section({ body: UI.searchBar({ placeholder: c.t('docs.search'), target: 'documents', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'cat', label: c.t('docs.category'), items: [
        { value: 'all', label: c.t('common.all'), on: cat === 'all', count: d.list.length }
      ].concat(d.categories.map(function (x) {
        return { value: x.id, label: x.label, count: x.n, on: cat === x.id };
      })) }], 'documents') }) +
      UI.section({ body: UI.sortBar({ tool: 'documents', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'expiry', label: c.t('docs.expiry') },
          { value: 'cat', label: c.t('docs.category') },
          { value: 'updated', label: c.t('docs.updated') }
        ], 'expiry', 'asc') }) }) +
      (groups.length ? '' : UI.section({ body: UI.emptyState({ icon: 'i-folder',
        title: c.t('docs.noMatch'), text: c.t('docs.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:documents:cat:all', icon: 'i-refresh' } }) })) +
      groups.map(function (grp) {
        return UI.section({ title: grp.label, body: UI.rows(grp.items.map(function (x) {
          return UI.richRow({
            icon: x.icon, iconTone: x.tone,
            title: x.name, sub: x.num,
            meta: [x.holder, c.t('docs.filesN', { n: x.files })],
            badge: x.badge,
            value: x.expires,
            valueSub: x.days === null ? '' : c.t('common.inDays', { n: x.days }),
            act: 'toast:' + c.t('docs.unlockToView'), chevron: true
          });
        })) });
      }).join('') +
      UI.section({ body: UI.buttonRow([
        { label: c.t('docs.add'), tone: 'accent', icon: 'i-plus', act: 'tool:docscan' },
        { label: c.t('common.export'), icon: 'i-download', act: 'export:documents' }]) });
  });

  /* ---------------------------------------------------------
     §69 Health records — personal health record manager
     --------------------------------------------------------- */
  T.register('health', function (c) {
    var h = c.health();
    var kind = c.filter('kind', 'all');
    var records = h.records.filter(function (r) { return kind === 'all' || r.kind === kind; });

    return UI.section({ flush: true, body: '<div class="people">' +
        h.people.map(function (p) {
          return '<button class="person' + (p.id === h.selected ? ' is-on' : '') + '" data-act="toolstate:health:person:' + p.id + '">' +
            '<span class="person__avatar">' + UI.esc(p.initials) + '</span>' +
            '<span class="person__name">' + UI.esc(p.name) + '</span>' +
          '</button>';
        }).join('') + '</div>' }) +
      UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: h.person.name,
        value: h.upcoming + ' <small>' + UI.esc(c.t('health.upcoming')) + '</small>',
        caption: h.nextLabel,
        stats: [
          { value: h.person.blood, label: c.t('health.blood') },
          { value: String(h.person.age), label: c.t('health.age') },
          { value: c.money(h.spend), label: c.t('health.spendYear') }
        ]
      }) }) +
      UI.section({ body: UI.filterBar([{ id: 'kind', label: c.t('health.recordType'), items: [
        { value: 'all', label: c.t('common.all'), on: kind === 'all' }
      ].concat(h.kinds.map(function (k) {
        return { value: k.id, label: k.label, count: k.n, on: kind === k.id };
      })) }], 'health') }) +
      UI.section({ title: c.t('health.timeline'), body: records.length
        ? UI.timeline(records.map(function (r) {
        return { time: r.date, title: r.title, sub: r.who,
          meta: r.flag ? UI.statusBadge({ label: r.flag, tone: 'warn' }) : r.kind,
          value: r.cost ? c.money(r.cost) : '', state: r.state === 'upcoming' ? 'now' : 'done' };
          }))
        : UI.emptyState({ icon: 'i-pulse', title: c.t('health.noRecords'),
            text: c.t('health.noRecordsText'),
            action: { label: c.t('health.addRecord'), act: 'toast:' + c.t('health.adding'), icon: 'i-plus' } }) }) +
      UI.section({ title: c.t('health.vitals'), body: UI.card(
        UI.lineChart({ values: h.vitals, labels: [c.t('range.6m'), c.t('range.3m'), c.t('common.now')],
          label: c.t('health.weight'), caption: c.t('health.weightCap') })) }) +
      UI.section({ title: c.t('health.related'), body: UI.rows([
        UI.compactRow({ icon: 'i-syringe', label: c.t('f.vaccines'), value: c.t('health.doses', { n: h.vaccineDue }), act: 'tool:vaccines' }),
        UI.compactRow({ icon: 'i-pill', label: c.t('f.meds'), value: c.t('health.activeMeds', { n: 2 }), act: 'tool:meds' }),
        UI.compactRow({ icon: 'i-folder', label: c.t('f.documents'), value: c.t('common.locked'), act: 'tool:documents' })
      ]) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('health.addRecord'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('health.adding') },
        { label: c.t('health.exportSummary'), icon: 'i-download', act: 'export:health' }]) });
  });

  /* ---------------------------------------------------------
     §68 Vaccinations — health timeline
     --------------------------------------------------------- */
  T.register('vaccines', function (c) {
    var v = c.vaccines();
    return UI.section({ flush: true, body: '<div class="people">' +
        D.HEALTH_PEOPLE.map(function (p) {
          return '<button class="person' + (p.id === v.selected ? ' is-on' : '') + '" data-act="toolstate:vaccines:person:' + p.id + '">' +
            '<span class="person__avatar">' + UI.esc(p.initials) + '</span>' +
            '<span class="person__name">' + UI.esc(p.name) + '</span></button>';
        }).join('') + '</div>' }) +
      UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('vaccines.schedule'),
        value: v.done + ' <small>/ ' + v.total + '</small>',
        caption: v.due ? c.t('vaccines.dueSoon', { n: v.due }) : c.t('vaccines.upToDate'),
        aside: UI.progressRing({ value: v.done / v.total, centre: Math.round(v.done / v.total * 100) + '%', label: c.t('vaccines.schedule') })
      }) }) +
      UI.section({ title: c.t('vaccines.records'), body: v.list.length
        ? UI.rows(v.list.map(function (x) {
        return UI.richRow({
          icon: 'i-syringe', iconTone: x.state === 'done' ? 'accent' : 'warn',
          title: x.name, sub: x.dose,
          meta: [x.by],
          badge: { label: x.state === 'done' ? c.t('common.done') : c.t('common.due'), tone: x.state === 'done' ? 'ok' : 'warn' },
          value: x.date
        });
          }))
        : UI.emptyState({ icon: 'i-syringe', title: c.t('vaccines.empty.title'),
            text: c.t('vaccines.empty.text'),
            action: { label: c.t('vaccines.add'), act: 'toast:' + c.t('vaccines.adding'), icon: 'i-plus' } }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('vaccines.add'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('vaccines.adding') },
        { label: c.t('vaccines.remind'), icon: 'i-bell', act: 'toast:' + c.t('vaccines.reminded') }]) });
  });

  /* ---------------------------------------------------------
     §79 Medication reminders — schedule + adherence
     --------------------------------------------------------- */
  T.register('meds', function (c) {
    var m = c.meds();
    return UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('meds.nextDose'),
        value: m.next.name,
        unit: m.next.at,
        caption: m.next.dose,
        aside: UI.progressRing({ value: m.adherence, centre: Math.round(m.adherence * 100) + '%', label: c.t('meds.adherence') })
      }) }) +
      UI.section({ title: c.t('meds.today'), body: UI.timeline(m.today.map(function (d) {
        return { time: d.at, title: d.name, sub: d.dose, state: d.state,
          value: d.state === 'done' ? UI.statusBadge({ label: c.t('common.taken'), tone: 'ok' })
                                    : UI.statusBadge({ label: c.t('common.due'), tone: 'info' }) };
      })) }) +
      UI.section({ title: c.t('meds.active'), body: UI.rows(D.MEDS.map(function (x) {
        return UI.richRow({
          icon: 'i-pill', iconTone: 'accent',
          title: x.name, sub: x.dose,
          meta: [x.when, c.t('meds.left', { a: x.left, b: x.of })],
          value: x.adherence !== null ? Math.round(x.adherence * 100) + '%' : '—',
          valueSub: c.t('meds.adherence')
        }) + '<div class="rowmeter">' + UI.progressBar({ value: x.left / x.of, label: x.name }) + '</div>';
      })) }) +
      (function () {
        var low = D.MEDS.filter(function (x) { return x.left / x.of < 0.5; });
        if (!low.length) return '';
        return UI.section({ title: c.t('meds.refill'), body: UI.rows(low.map(function (x) {
          return UI.compactRow({ icon: 'i-alert', label: x.name, sub: c.t('meds.runningLow'),
            value: c.t('meds.left', { a: x.left, b: x.of }) });
        })) });
      })();
  });

  /* ---------------------------------------------------------
     §59 Parcel tracker — tracking timeline
     --------------------------------------------------------- */
  T.register('parcel', function (c) {
    var sel = c.state('parcel') || D.PARCELS[0].ref;
    var p = D.PARCELS.filter(function (x) { return x.ref === sel; })[0] || D.PARCELS[0];
    return UI.section({ body: UI.card(UI.formGrid([
        UI.field({ label: c.t('parcel.tracking'), name: 'pc_ref', placeholder: c.t('parcel.placeholder'), wide: true })
      ]) + UI.buttonRow([{ label: c.t('parcel.track'), tone: 'accent', icon: 'i-search', block: true,
        act: 'toast:' + c.t('parcel.tracking2') }])) }) +
      UI.section({ title: c.t('parcel.active'), body: UI.rows(D.PARCELS.map(function (x) {
        return UI.richRow({
          logo: x.logo, logoTone: 'var(--tone-' + x.tone + ')',
          title: x.item, sub: x.carrier + ' · ' + x.ref,
          meta: [x.place, x.eta],
          badge: { label: x.status, tone: x.state },
          act: 'toolstate:parcel:parcel:' + x.ref,
          cls: x.ref === sel ? 'is-selected' : ''
        });
      })) }) +
      UI.section({ title: p.item, body: UI.card(
        UI.metrics([
          { icon: 'i-package', value: p.carrier, label: c.t('parcel.carrier') },
          { icon: 'i-pin', value: p.place, label: c.t('parcel.location') },
          { icon: 'i-clock', value: p.eta, label: c.t('parcel.eta') }
        ], 3) +
        UI.progressBar({ value: p.progress, label: p.item })) }) +
      UI.section({ title: c.t('parcel.events'), body: UI.timeline(p.events.map(function (e) {
        return { time: e[2], title: e[0], sub: e[1], state: e[3] === 'done' ? 'done' : e[3] === 'now' ? 'now' : '' };
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('parcel.notify'), tone: 'accent', icon: 'i-bell', act: 'toast:' + c.t('parcel.notifying') },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:parcel' }]) });
  });

  /* ---------------------------------------------------------
     §57.1 To-dos · §58 Notes · reminders · events
     --------------------------------------------------------- */
  T.register('todos', function (c) {
    var t = c.todos();
    var when = c.filter('when', 'today');
    var prio = c.filter('priority', 'any');
    var query = (c.state('q') || '').trim().toLowerCase();

    var pool = when === 'today' ? t.today : t.today.concat(t.upcoming);
    var visible = pool.filter(function (x) {
      if (prio !== 'any' && (x.priority || 'normal') !== prio) return false;
      if (query && (x.label + ' ' + x.list).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('todos.today'),
        value: t.doneToday + ' <small>/ ' + t.today.length + '</small>',
        caption: t.overdue ? c.t('todos.overdueN', { n: t.overdue }) : c.t('todos.onTrack'),
        aside: UI.progressRing({ value: t.today.length ? t.doneToday / t.today.length : 0,
          centre: Math.round((t.today.length ? t.doneToday / t.today.length : 0) * 100) + '%', label: c.t('todos.today') }),
        stats: [
          { value: String(t.overdue), label: c.t('common.overdue') },
          { value: String(t.upcoming.length), label: c.t('todos.upcoming') },
          { value: String(t.done7), label: c.t('todos.done7') }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('todos.search'), target: 'todos', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([
        { id: 'when', label: c.t('todos.when'), items: [
          { value: 'today', label: c.t('common.today'), on: when === 'today' },
          { value: 'week', label: c.t('common.week'), on: when === 'week' },
          { value: 'all', label: c.t('common.all'), on: when === 'all' } ] },
        { id: 'priority', label: c.t('todos.priority'), items: [
          { value: 'any', label: c.t('common.all'), on: prio === 'any' },
          { value: 'high', label: c.t('todos.high'), on: prio === 'high' },
          { value: 'normal', label: c.t('todos.normal'), on: prio === 'normal' } ] }
      ], 'todos') }) +
      UI.section({ title: c.t('todos.today'), body: visible.length
        ? UI.rows(visible.map(function (x) {
        return '<button class="taskrow pressable' + (x.done ? ' is-done' : '') + '" data-task="' + UI.esc(x.id) + '"' +
          ' role="checkbox" aria-checked="' + (x.done ? 'true' : 'false') + '">' +
          '<span class="taskrow__box">' + UI.ico('i-check') + '</span>' +
          '<span class="taskrow__body"><span class="taskrow__label">' + UI.esc(x.label) + '</span>' +
            '<span class="taskrow__meta">' + UI.esc(x.list) + (x.due ? ' · ' + UI.esc(x.due) : '') + '</span></span>' +
          (x.priority === 'high' ? UI.statusBadge({ label: c.t('todos.high'), tone: 'warn' }) : '') +
        '</button>';
          }))
        : UI.emptyState({ icon: 'i-check-circle', title: c.t('todos.clear'), text: c.t('todos.clearText') }) }) +
      UI.section({ title: c.t('todos.upcoming'), body: UI.rows(t.upcoming.map(function (x) {
        return UI.compactRow({ icon: 'i-check-square', label: x.label, sub: x.list, value: x.due });
      })) }) +
      UI.section({ title: c.t('todos.lists'), body: UI.rows(t.lists.map(function (l) {
        return UI.compactRow({ icon: l.icon, label: l.label, value: l.open + ' ' + c.t('todos.open') });
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('todos.add'), act: 'toast:' + c.t('todos.adding') });
  });

  T.register('notes', function (c) {
    var n = c.notes();
    var query = (c.state('q') || '').trim().toLowerCase();
    var notesShown = n.all.filter(function (x) {
      return !query || (x.title + ' ' + x.excerpt + ' ' + x.folder).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.searchBar({ placeholder: c.t('notes.search'), target: 'notes', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.metrics([
        { value: String(n.all.length), label: c.t('notes.total') },
        { value: String(n.pinned.length), label: c.t('notes.pinned') },
        { value: String(n.folders.length), label: c.t('notes.folders') }
      ], 3) }) +
      (n.pinned.length ? UI.section({ title: c.t('notes.pinned'), flush: true, body:
        UI.hscroll(n.pinned.map(function (x) {
          return '<button class="notecardx pressable" data-act="toast:' + UI.esc(x.title) + '">' +
            '<span class="notecardx__title">' + UI.esc(x.title) + '</span>' +
            '<span class="notecardx__body">' + UI.esc(x.excerpt) + '</span>' +
            '<span class="notecardx__meta">' + UI.esc(x.when) + '</span></button>';
        })) }) : '') +
      UI.section({ title: c.t('notes.folders'), body: UI.rows(n.folders.map(function (f) {
        return UI.compactRow({ icon: 'i-folder', label: f.label, value: String(f.n) });
      })) }) +
      UI.section({ title: c.t('notes.recent'), body: notesShown.length ? UI.rows(notesShown.map(function (x) {
        return UI.richRow({ icon: 'i-note', title: x.title, sub: x.excerpt,
          meta: [x.folder, x.when], act: 'toast:' + x.title, chevron: true });
      })) : UI.emptyState({ icon: 'i-note', title: c.t('notes.noMatch'), text: c.t('notes.noMatchText') }) }) +
      UI.fab({ icon: 'i-plus', label: c.t('notes.new'), act: 'toast:' + c.t('notes.creating') });
  });

  T.register('reminders', function (c) {
    var r = c.reminders();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('reminders.today'), value: String(r.today.length),
        caption: r.next ? c.t('reminders.next', { label: r.next.label, at: r.next.at }) : c.t('reminders.none') }) }) +
      UI.section({ title: c.t('reminders.upcoming'), body: UI.timeline(r.all.map(function (x) {
        return { time: x.at, title: x.label, sub: x.repeat, state: x.state };
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('reminders.add'), act: 'toast:' + c.t('reminders.adding') });
  });

  T.register('events', function (c) {
    var e0 = c.events();
    var query = (c.state('q') || '').trim().toLowerCase();
    var e = e0.filter(function (x) {
      return !query || (x.title + ' ' + x.where).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.searchBar({ placeholder: c.t('events.search'), target: 'events', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('events.upcoming'), body: e.length ? UI.rows(e.map(function (x) {
        return UI.richRow({ icon: 'i-calendar', iconTone: 'accent', title: x.title, sub: x.where,
          meta: [x.when, x.people], act: 'toast:' + x.title, chevron: true });
      })) : UI.emptyState({ icon: 'i-calendar', title: c.t('events.noMatch'), text: c.t('events.noMatchText') }) });
  });

  /* ---------------------------------------------------------
     §39.1 Calendar — calendar + agenda
     --------------------------------------------------------- */
  T.register('calendar', function (c) {
    var cal = c.calendar();
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country) },
        { label: c.L.timezone() }
      ].concat(c.profile.islamic ? [{ label: c.hijri().label }] : [])) }) +
      UI.section({ body: UI.segmented({ id: 'calview', label: c.t('calendar.view'), items: [
        { value: 'month', label: c.t('calendar.month'), on: cal.view === 'month', act: 'toolstate:calendar:view:month' },
        { value: 'week', label: c.t('calendar.week'), on: cal.view === 'week', act: 'toolstate:calendar:view:week' },
        { value: 'day', label: c.t('calendar.day'), on: cal.view === 'day', act: 'toolstate:calendar:view:day' }
      ] }) }) +
      UI.section({ body: c.monthGrid() }) +
      UI.section({ title: c.t('calendar.agenda'), body: UI.timeline(cal.agenda.map(function (a) {
        return { time: a.time, title: a.title, sub: a.sub, state: a.state, icon: a.icon };
      })) }) +
      UI.section({ title: c.t('calendar.holidays'), body: UI.rows(cal.holidays.map(function (h) {
        return UI.compactRow({ icon: 'i-star', label: h.name, sub: h.kind, value: h.date });
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('calendar.add'), act: 'toast:' + c.t('calendar.adding') });
  });

  /* ---------------------------------------------------------
     §60 Shopping list · §61 Birthdays
     --------------------------------------------------------- */
  T.register('shopping', function (c) {
    var s = c.shopping();
    var query = (c.state('q') || '').trim().toLowerCase();
    var shopGroups = s.groups.map(function (g) {
      return { label: g.label, items: g.items.filter(function (i) {
        return !query || i.label.toLowerCase().indexOf(query) !== -1;
      }) };
    }).filter(function (g) { return g.items.length; });

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('shopping.list'),
        value: s.remaining + ' <small>/ ' + s.items.length + '</small>',
        caption: c.t('shopping.estimated', { amount: c.money(s.estimate) }),
        aside: UI.progressRing({ value: s.checked / s.items.length,
          centre: s.checked + '/' + s.items.length, label: c.t('shopping.progress') })
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('shopping.add'), target: 'shopping', value: c.state('q') || '' }) }) +
      shopGroups.map(function (g) {
        return UI.section({ title: g.label, body: UI.rows(g.items.map(function (x) {
          return '<button class="taskrow pressable' + (x.done ? ' is-done' : '') + '" data-shop="' + UI.esc(x.id) + '"' +
            ' role="checkbox" aria-checked="' + (x.done ? 'true' : 'false') + '">' +
            '<span class="taskrow__box">' + UI.ico('i-check') + '</span>' +
            '<span class="taskrow__body"><span class="taskrow__label">' + UI.esc(x.label) + '</span>' +
              '<span class="taskrow__meta">' + UI.esc(x.qty) + '</span></span>' +
            '<span class="taskrow__value">' + c.money(x.price) + '</span></button>';
        })) });
      }).join('') +
      UI.section({ body: UI.buttonRow([
        { label: c.t('shopping.share'), icon: 'i-share', act: 'toast:' + c.t('shopping.sharing') },
        { label: c.t('shopping.clear'), icon: 'i-refresh', act: 'toast:' + c.t('shopping.cleared') }]) });
  });

  T.register('birthdays', function (c) {
    var b = c.birthdays();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('birthdays.next'),
        value: b.next.name,
        caption: c.t('common.inDays', { n: b.next.days }) + ' · ' + b.next.date,
        stats: [
          { value: String(b.list.length), label: c.t('birthdays.tracked') },
          { value: String(b.thisMonth), label: c.t('birthdays.thisMonth') },
          { value: b.next.turning + '', label: c.t('birthdays.turning') }
        ]
      }) }) +
      UI.section({ title: c.t('birthdays.upcoming'), body: UI.rows(b.list.map(function (x) {
        return UI.richRow({
          logo: x.initials, logoTone: 'var(--tone-' + x.tone + ')',
          title: x.name, sub: x.kind,
          meta: [x.date, c.t('birthdays.turns', { n: x.turning })],
          value: c.t('common.inDays', { n: x.days }),
          act: 'toast:' + x.name, chevron: true
        });
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('birthdays.add'), act: 'toast:' + c.t('birthdays.adding') });
  });

  /* ---------------------------------------------------------
     §62 Daily streak · §72 Habits · §73 Water
     --------------------------------------------------------- */
  T.register('habits', function (c) {
    var h = c.habits();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('habits.today'),
        value: h.doneToday + ' <small>/ ' + h.list.length + '</small>',
        caption: c.t('habits.streak', { n: h.streak }),
        aside: UI.progressRing({ value: h.doneToday / h.list.length,
          centre: Math.round(h.doneToday / h.list.length * 100) + '%', label: c.t('habits.today') }),
        stats: [
          { value: String(h.streak), label: c.t('habits.currentStreak') },
          { value: String(h.best), label: c.t('habits.bestStreak') },
          { value: Math.round(h.rate * 100) + '%', label: c.t('habits.completion') }
        ]
      }) }) +
      UI.section({ title: c.t('habits.yours'), body: UI.card('<div class="habitgrid">' +
        h.list.map(function (x) {
          return '<div class="habitrow">' +
            '<span class="habitrow__name">' + UI.esc(x.name) + '</span>' +
            '<span class="habitrow__days">' + x.days.map(function (on, i) {
              return '<i class="habitrow__day' + (on ? ' is-on' : '') + (i === 6 ? ' is-today' : '') + '"></i>';
            }).join('') + '</span>' +
            '<span class="habitrow__streak">' + UI.ico('i-flame') + x.streak + '</span>' +
          '</div>';
        }).join('') + '</div>') }) +
      UI.section({ title: c.t('habits.month'), body: UI.card(
        UI.heatmap({ days: h.heat, label: c.t('habits.month'), less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('habits.insights'), body: UI.rows(h.insights.map(function (i) {
        return UI.richRow({ icon: i.icon, iconTone: 'accent', title: i.title, sub: i.text });
      })) });
  });

  T.register('streak', function (c) {
    var s = c.streaks();
    return UI.section({ body: UI.summaryCard({
        tone: 'flame',
        kicker: c.t('streak.current'),
        value: s.current + ' <small>' + UI.esc(c.t('common.days')) + '</small>',
        caption: c.t('streak.best', { n: s.best }),
        stats: [
          { value: String(s.thisMonth), label: c.t('streak.thisMonth') },
          { value: Math.round(s.rate * 100) + '%', label: c.t('streak.rate') },
          { value: s.nextMilestone + '', label: c.t('streak.next') }
        ]
      }) }) +
      UI.section({ title: c.t('streak.calendar'), body: UI.card(
        UI.heatmap({ days: s.heat, label: c.t('streak.calendar'), less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('streak.milestones'), body: UI.rows(s.milestones.map(function (m) {
        return UI.compactRow({ icon: m.done ? 'i-check-circle' : 'i-star', label: m.label,
          value: m.done ? c.t('common.done') : c.t('common.inDays', { n: m.inDays }) });
      })) });
  });

  T.register('water', function (c) {
    var w = c.water();
    return UI.section({ body: UI.summaryCard({
        tone: 'sky',
        kicker: c.t('water.today'),
        value: w.consumedLabel,
        caption: c.t('water.ofTarget', { target: w.targetLabel }),
        aside: UI.progressRing({ value: w.pct, centre: Math.round(w.pct * 100) + '%', label: c.t('water.progress') }),
        stats: [
          { value: w.remainingLabel, label: c.t('water.remaining') },
          { value: String(w.glasses), label: c.t('water.glasses') },
          { value: String(w.streak), label: c.t('water.streak') }
        ]
      }) }) +
      UI.section({ body: UI.buttonRow([
        { label: '+ ' + w.unitSmall, tone: 'accent', icon: 'i-plus', act: 'water:small' },
        { label: '+ ' + w.unitLarge, icon: 'i-droplet', act: 'water:large' }]) }) +
      UI.section({ title: c.t('water.timeline'), body: UI.timeline(w.log.map(function (l) {
        return { time: l.at, title: l.amount, sub: l.kind, state: 'done', icon: 'i-droplet' };
      })) }) +
      UI.section({ title: c.t('water.week'), body: UI.card(
        UI.barChart({ values: w.week, labels: c.weekLabels(), highlight: 6,
          label: c.t('water.week'), max: w.target })) });
  });

  /* ---------------------------------------------------------
     §63 Recipes — visual library + reader
     --------------------------------------------------------- */
  T.register('recipes', function (c) {
    var cuisine = c.state('cuisine') || 'all';
    var query = (c.state('q') || '').trim().toLowerCase();
    var list = (cuisine === 'all' ? D.RECIPES : D.RECIPES.filter(function (r) { return r.cuisine === cuisine; }))
      .filter(function (r) {
        return !query || (r.name + ' ' + r.cuisine + ' ' + r.tags.join(' ')).toLowerCase().indexOf(query) !== -1;
      });
    var cuisines = ['all'].concat(D.RECIPES.map(function (r) { return r.cuisine; })
      .filter(function (v, i, a) { return a.indexOf(v) === i; }));

    return UI.section({ body: UI.searchBar({ placeholder: c.t('recipes.search'), target: 'recipes', value: c.state('q') || '' }) }) +
      UI.section({ flush: true, body: '<div class="chips chips--scroll">' +
        cuisines.map(function (x) {
          return '<button class="chip' + (x === cuisine ? ' is-on' : '') + '" data-act="toolstate:recipes:cuisine:' + UI.esc(x) + '">' +
            UI.esc(x === 'all' ? c.t('common.all') : x) + '</button>';
        }).join('') + '</div>' }) +
      UI.section({ title: c.t('recipes.favourites'), flush: true, body: UI.hscroll(
        D.RECIPES.filter(function (r) { return r.fav; }).map(function (r) {
          return UI.imageCard({
            tone: r.tone, seed: r.name.length, glyph: r.glyph,
            kicker: r.cuisine, title: r.name,
            meta: (r.prep + r.cook) + ' ' + c.t('unit.min') + ' · ' + c.t('recipes.serves', { n: r.serves }),
            act: 'toast:' + r.name
          });
        })) }) +
      UI.section({ title: c.t('recipes.all'), body: list.length ? UI.rows(list.map(function (r) {
        return UI.richRow({
          thumb: UI.art({ tone: r.tone, seed: r.name.length, glyph: r.glyph }),
          title: r.name, sub: r.cuisine,
          meta: [c.t('recipes.prepCook', { prep: r.prep, cook: r.cook }),
                 c.t('recipes.serves', { n: r.serves }),
                 c.num(r.kcal) + ' ' + c.t('unit.kcal'),
                 c.t('recipes.stepsN', { n: r.steps }),
                 r.ingredients + ' ' + c.t('recipes.ingredients'),
                 r.tags.join(' · ')],
          badge: r.fav ? { label: c.t('common.saved'), tone: 'ok' } : null,
          act: 'toast:' + r.name, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-utensils', title: c.t('recipes.noMatch'),
        text: c.t('recipes.noMatchText') }) }) +
      UI.section({ title: c.t('recipes.related'), body: UI.rows([
        UI.compactRow({ icon: 'i-calendar', label: c.t('f.mealplan'), act: 'tool:mealplan' }),
        UI.compactRow({ icon: 'i-cart', label: c.t('f.shopping'), act: 'tool:shopping' })
      ]) });
  });

  /* ---------------------------------------------------------
     §64 Meal planner · §65 Alarms · §66 Learning · §70 Play
     --------------------------------------------------------- */
  T.register('mealplan', function (c) {
    var m = c.mealPlan();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('meal.thisWeek'),
        value: m.planned + ' <small>/ ' + m.slots + '</small>',
        caption: c.t('meal.planned'),
        stats: [
          { value: c.num(m.kcal), label: c.t('meal.avgKcal') },
          { value: String(m.shopItems), label: c.t('meal.shopItems') },
          { value: c.money(m.cost), label: c.t('meal.estCost') }
        ]
      }) }) +
      UI.section({ title: c.t('meal.calories'), body: UI.card(
        UI.barChart({ values: m.kcalByDay, labels: c.weekLabels(), highlight: 0,
          label: c.t('meal.calories'), caption: c.t('meal.caloriesCap', { n: c.num(m.kcal) }) })) }) +
      UI.section({ title: c.t('meal.week'), body: UI.rows(m.days.map(function (d) {
        return UI.expandRow({
          open: d.today,
          head: '<span class="xrow__title">' + UI.esc(d.label) + '</span>' +
                '<span class="xrow__value">' + UI.esc(d.summary) + '</span>',
          body: UI.rows(d.meals.map(function (x) {
            return UI.compactRow({ icon: x.icon, label: x.slot, sub: x.recipe, value: x.kcal + ' ' + c.t('unit.kcal') });
          }), { flat: true })
        });
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('meal.toShopping'), tone: 'accent', icon: 'i-cart', act: 'tool:shopping' },
        { label: c.t('meal.browse'), icon: 'i-utensils', act: 'tool:recipes' }]) });
  });

  T.register('alarms', function (c) {
    var a = c.alarms();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('alarms.next'), value: a.next ? a.next.at : '—',
        caption: a.next ? a.next.label + ' · ' + a.next.inLabel : c.t('alarms.none') }) }) +
      UI.section({ title: c.t('alarms.all'), body: UI.rows(a.list.map(function (x) {
        return UI.richRow({
          icon: 'i-alarm', iconTone: x.on ? 'accent' : null,
          title: x.at, sub: x.label,
          meta: [x.repeat],
          value: '<span class="switch' + (x.on ? ' is-on' : '') + '"><i class="switch__knob"></i></span>',
          act: 'alarmtoggle:' + x.id
        });
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('alarms.add'), act: 'toast:' + c.t('alarms.adding') });
  });

  T.register('learning', function (c) {
    var l = c.learning();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('learning.thisWeek'),
        value: l.minutes + ' <small>' + UI.esc(c.t('unit.min')) + '</small>',
        caption: c.t('learning.streak', { n: l.streak }),
        aside: UI.progressRing({ value: l.weekPct, centre: Math.round(l.weekPct * 100) + '%', label: c.t('learning.goal') }),
        stats: [
          { value: String(D.COURSES.length), label: c.t('learning.courses') },
          { value: String(l.streak), label: c.t('learning.streakLabel') },
          { value: l.milestone, label: c.t('learning.milestone') }
        ]
      }) }) +
      UI.section({ title: c.t('learning.inProgress'), body: D.COURSES.map(function (x) {
        return UI.card(
          '<div class="course"><span class="course__icon course__icon--' + x.tone + '">' + UI.ico('i-graduation') + '</span>' +
          '<div class="course__body"><p class="course__name">' + UI.esc(x.name) + '</p>' +
          '<p class="course__meta">' + UI.esc(x.provider) + ' · ' + x.mins + ' ' + UI.esc(c.t('unit.min')) + '</p></div>' +
          '<span class="course__pct">' + Math.round(x.progress * 100) + '%</span></div>' +
          UI.progressBar({ value: x.progress, label: x.name }));
      }).join('') }) +
      UI.section({ title: c.t('learning.week'), body: UI.card(
        UI.barChart({ values: l.week, labels: c.weekLabels(), highlight: 6, label: c.t('learning.week') })) }) +
      UI.section({ title: c.t('learning.consistency'), body: UI.card(
        UI.heatmap({ days: l.heat, label: c.t('learning.consistency'),
          less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('habits.insights'), body: UI.rows(l.insights.map(function (i) {
        return UI.richRow({ icon: i.icon, iconTone: 'accent', title: i.title, sub: i.text });
      })) });
  });

  T.register('play', function (c) {
    return UI.section({ title: c.t('play.games'), body: '<div class="tiles tiles--play">' +
        D.GAMES.map(function (g) {
          return '<button class="tile pressable" data-act="toast:' + UI.esc(g.name) + '">' +
            '<span class="tile__glyph">' + UI.esc(g.glyph) + '</span>' +
            '<span class="tile__label">' + UI.esc(g.name) + '</span>' +
            '<span class="tile__meta">' + UI.esc(g.kind) + ' · ' + UI.esc(g.best) + '</span></button>';
        }).join('') + '</div>' }) +
      UI.section({ title: c.t('play.recent'), body: UI.rows(D.GAMES.slice(0, 3).map(function (g) {
        return UI.compactRow({ icon: 'i-play', label: g.name, sub: g.kind,
          value: c.t('play.plays', { n: g.plays }) });
      })) });
  });

  /* ---------------------------------------------------------
     §71 Baby budget · §74 Cycle · §75 Pregnancy
     --------------------------------------------------------- */
  T.register('babybudget', function (c) {
    var b = c.babyBudget();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('baby.monthly'),
        value: c.money(b.monthly),
        caption: c.t('baby.vsPlan', { pct: Math.round(b.ratio * 100) + '%' }),
        aside: UI.progressRing({ value: b.ratio, centre: Math.round(b.ratio * 100) + '%', label: c.t('baby.plan') })
      }) }) +
      UI.section({ title: c.t('baby.categories'), body: UI.card(UI.donut({
        label: c.t('baby.categories'), centre: c.money(b.monthly), centreSub: c.t('common.perMonth'),
        slices: b.categories
      })) }) +
      UI.section({ title: c.t('baby.trend'), body: UI.card(
        UI.barChart({ values: b.trend, labels: b.trendLabels, highlight: b.trend.length - 1,
          label: c.t('baby.trend'), caption: c.t('baby.trendCap') })) }) +
      UI.section({ title: c.t('baby.upcoming'), body: UI.rows(b.upcoming.map(function (x) {
        return UI.compactRow({ icon: 'i-baby', label: x.label, sub: x.when, value: c.money(x.amount) });
      })) }) +
      UI.section({ title: c.t('baby.oneOff'), body: UI.rows(b.oneOff.map(function (x) {
        return UI.compactRow({ icon: 'i-cart', label: x.label, sub: x.when, value: c.money(x.amount) });
      })) });
  });

  T.register('cycle', function (c) {
    var cy = c.cycle();
    return UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('cycle.day'),
        value: String(cy.day),
        unit: '/ ' + cy.length,
        caption: cy.phaseLabel,
        aside: UI.progressRing({ value: cy.day / cy.length, centre: cy.day + '', label: c.t('cycle.day') })
      }) }) +
      UI.section({ body: c.monthGrid() }) +
      UI.section({ title: c.t('cycle.history'), body: UI.rows(cy.history.map(function (h) {
        return UI.compactRow({ icon: 'i-cycle', label: h.month, sub: h.note, value: h.length + ' ' + c.t('common.days') });
      })) }) +
      UI.section({ body: UI.noteCard({ tone: 'lock', icon: 'i-lock',
        title: c.t('cycle.privacy.title'), text: c.t('cycle.privacy.text') }) });
  });

  T.register('pregnancy', function (c) {
    var p = c.pregnancy();
    return UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('pregnancy.week'),
        value: String(p.week),
        unit: '/ 40',
        caption: p.trimesterLabel + ' · ' + c.t('pregnancy.due', { date: p.dueDate }),
        aside: UI.progressRing({ value: p.week / 40, centre: Math.round(p.week / 40 * 100) + '%', label: c.t('pregnancy.progress') })
      }) }) +
      UI.section({ title: c.t('pregnancy.thisWeek'), body: UI.card(
        '<p class="kard__lead">' + UI.esc(p.note) + '</p>' +
        UI.metrics([
          { value: p.size, label: c.t('pregnancy.size') },
          { value: p.weight, label: c.t('pregnancy.weight') },
          { value: String(40 - p.week), label: c.t('pregnancy.weeksLeft') }
        ], 3)) }) +
      UI.section({ title: c.t('pregnancy.appointments'), body: UI.timeline(p.appointments.map(function (a) {
        return { time: a.when, title: a.title, sub: a.who, state: a.state };
      })) });
  });

  /* ---------------------------------------------------------
     Focused instruments: stopwatch, timer, focus, calculator
     --------------------------------------------------------- */
  function clockScreen(c, o) {
    return '<div class="clockface">' +
      '<p class="clockface__time" data-clock-display>' + o.display + '</p>' +
      (o.sub ? '<p class="clockface__sub">' + UI.esc(o.sub) + '</p>' : '') +
      '<div class="clockface__acts">' +
        UI.button({ label: o.primary, tone: 'accent', icon: 'i-play', act: o.primaryAct }) +
        UI.button({ label: c.t('common.reset'), icon: 'i-refresh', act: o.resetAct }) +
      '</div>' +
    '</div>';
  }

  T.register('stopwatch', function (c) {
    var s = c.stopwatch();
    return clockScreen(c, { display: s.display, sub: c.t('stopwatch.hint'),
      primary: c.t('common.start'), primaryAct: 'clock:stopwatch:start', resetAct: 'clock:stopwatch:reset' }) +
      UI.section({ title: c.t('stopwatch.laps'), body: s.laps.length
        ? UI.rows(s.laps.map(function (l, i) {
            return UI.compactRow({ label: c.t('stopwatch.lap', { n: i + 1 }), value: l });
          }))
        : UI.emptyState({ icon: 'i-stopwatch', title: c.t('stopwatch.empty.title'), text: c.t('stopwatch.empty.text') }) });
  });

  T.register('timer', function (c) {
    var s = c.timer();
    return clockScreen(c, { display: s.display, sub: c.t('timer.hint'),
      primary: c.t('common.start'), primaryAct: 'clock:timer:start', resetAct: 'clock:timer:reset' }) +
      UI.section({ title: c.t('timer.presets'), body: '<div class="chips">' +
        s.presets.map(function (p) {
          return '<button class="chip" data-act="clock:timer:set:' + p.secs + '">' + UI.esc(p.label) + '</button>';
        }).join('') + '</div>' }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(s.history.map(function (h) {
        return UI.compactRow({ icon: 'i-timer', label: h.label, value: h.when });
      })) });
  });

  T.register('focus', function (c) {
    var s = c.focus();
    return clockScreen(c, { display: s.display, sub: c.t('focus.session', { n: s.session, of: s.of }),
      primary: c.t('focus.start'), primaryAct: 'clock:focus:start', resetAct: 'clock:focus:reset' }) +
      UI.section({ body: UI.metrics([
        { icon: 'i-timer', value: s.todayMins + '', label: c.t('focus.todayMins') },
        { icon: 'i-flame', value: String(s.streak), label: c.t('focus.streak') },
        { icon: 'i-check', value: String(s.sessions), label: c.t('focus.sessions') }
      ], 3) }) +
      UI.section({ title: c.t('focus.week'), body: UI.card(
        UI.barChart({ values: s.week, labels: c.weekLabels(), highlight: 6, label: c.t('focus.week') })) });
  });

  T.register('calculator', function (c) {
    var KEYS = [
      ['AC', 'ac'], ['÷', 'op:/'], ['×', 'op:*'], ['⌫', 'back'],
      ['7', 'n:7'], ['8', 'n:8'], ['9', 'n:9'], ['−', 'op:-'],
      ['4', 'n:4'], ['5', 'n:5'], ['6', 'n:6'], ['+', 'op:+'],
      ['1', 'n:1'], ['2', 'n:2'], ['3', 'n:3'], ['%', 'pct'],
      ['0', 'n:0'], ['.', 'dot'], ['=', 'eq']
    ];
    return '<div class="calc">' +
        '<div class="calc__screen"><p class="calc__expr" data-calc-expr></p>' +
          '<p class="calc__out" data-calc-out>0</p></div>' +
        '<div class="calc__keys">' + KEYS.map(function (k) {
          var kind = k[1].split(':')[0];
          var cls = kind === 'n' || kind === 'dot' ? 'calc__key' :
                    kind === 'eq' ? 'calc__key calc__key--eq' :
                    kind === 'op' ? 'calc__key calc__key--op' : 'calc__key calc__key--fn';
          return '<button class="' + cls + (k[0] === '0' ? ' calc__key--wide' : '') +
            '" data-calckey="' + UI.esc(k[1]) + '">' + UI.esc(k[0]) + '</button>';
        }).join('') + '</div>' +
      '</div>' +
      UI.section({ title: c.t('common.history'), body: UI.rows(c.calcHistory().map(function (h) {
        return UI.compactRow({ label: h.expr, value: h.result });
      })) });
  });
})();
