/* Every shared Lume component, rendered once, deterministically.
 *
 * CONVERSION-ONLY. This file and its host page exist so the Flutter
 * conversion can measure real components under the real cascade, instead of
 * reading a declaration and hoping it is the one that wins. They import the
 * production builders and load the production stylesheets, and they change
 * neither. Both are deleted at Phase F9.
 *
 * Each specimen names the element the measurer should read. A component with
 * states lists one specimen per state, because a state is exactly the case
 * where a declaration is not the final value.
 */
import { LUME_UI as UI } from '../../../../assets/js/ui/components.js';
import { LUME_CRUD_UI as K } from '../../../../assets/js/ui/crud.js';

const rows = (list) => UI.rows(list);
const recs = (list) => K.recordRows(list);
const act = { act: 'noop', label: 'Do it' };

/* The navigation markup the shell emits, reproduced verbatim from
   `renderTabBar()` so the measurement is of the real thing. */
const DESTS = [
  ['home', 'i-home', 'Home'],
  ['tools', 'i-grid', 'Tools'],
  ['today', 'i-sun', 'Today'],
  ['explore', 'i-compass', 'Explore'],
  ['profile', 'i-user', 'Profile'],
];
const ico = (n) =>
  '<svg class="ico" viewBox="0 0 24 24"><use href="#' + n + '"/></svg>';
const tabs = (activeIndex) =>
  '<span class="tabbar__pill" id="tabPill"></span>' +
  DESTS.map(([id, icon, label], i) =>
    '<button class="tab' + (i === activeIndex ? ' is-active' : '') +
    '" data-tab="' + id + '" role="tab" aria-selected="' +
    (i === activeIndex) + '">' + ico(icon) +
    '<span class="tab__label">' + label + '</span></button>').join('');
const navtabs = (activeIndex) =>
  '<span class="navside__brand">Lume</span>' +
  DESTS.map(([id, icon, label], i) =>
    '<button class="navtab' + (i === activeIndex ? ' is-active' : '') +
    '" data-tab="' + id + '" role="tab" aria-selected="' +
    (i === activeIndex) + '">' + ico(icon) +
    '<span class="navtab__label">' + label + '</span></button>').join('');

const NAV = {
  bar: '<nav class="tabbar" role="tablist" aria-label="Main">' + tabs(-1) + '</nav>',
  barActive: '<nav class="tabbar" role="tablist" aria-label="Main">' + tabs(0) + '</nav>',
  side: '<nav class="navside" role="tablist" aria-label="Main">' + navtabs(-1) + '</nav>',
  sideActive: '<nav class="navside" role="tablist" aria-label="Main">' + navtabs(0) + '</nav>',
  status:
    '<div class="statusbar">' +
      '<span class="statusbar__brand" aria-hidden="true">' + ico('i-lume') + 'Lume</span>' +
      '<span class="num statusbar__clock">16:41</span>' +
      '<span class="statusbar__icons">' + ico('i-signal') + ico('i-wifi') + ico('i-battery') + '</span>' +
    '</div>',
};

/** name -> { html, sel } — `sel` is the element that gets measured. */
export const SPECIMENS = {
  // ---- Navigation and chrome -------------------------------------------
  'toolbar': {
    html: UI.toolHeader({
      title: 'Currency',
      sub: 'Live rates',
      actions: [{ icon: 'i-share', label: 'Share' }],
    }),
    sel: '.toolbar',
  },
  'toolbar.title': { html: UI.toolHeader({ title: 'Currency' }), sel: '.toolbar__title' },
  'toolbar.sub': { html: UI.toolHeader({ title: 'C', sub: 'Live rates' }), sel: '.toolbar__sub' },
  'iconbtn': { html: UI.toolHeader({ title: 'X' }), sel: '.iconbtn' },
  'textbtn': {
    html: UI.toolHeader({ title: 'X', actions: [{ text: 'Save', label: 'Save' }] }),
    sel: '.textbtn',
  },
  'ctxbar': { html: UI.contextBar(['Islamabad', { label: 'PKR', act: 'noop' }]), sel: '.ctxbar' },
  'ctxbar.item': { html: UI.contextBar(['Islamabad']), sel: '.ctxbar__item' },
  'sect': { html: UI.section({ title: 'Rates', body: '<p>x</p>' }), sel: '.sect' },
  'sect.title': { html: UI.section({ title: 'Rates', body: '' }), sel: '.sect__title' },
  'sect.sub': { html: UI.section({ title: 'R', sub: 'Today', body: '' }), sel: '.sect__sub' },
  'sect.link': {
    html: UI.section({ title: 'R', link: { label: 'All', act: 'noop' }, body: '' }),
    sel: '.sect__link',
  },

  // ---- Actions ----------------------------------------------------------
  'btn.accent': { html: UI.button({ label: 'Continue', tone: 'accent' }), sel: '.btn' },
  'btn.ghost': { html: UI.button({ label: 'Cancel' }), sel: '.btn' },
  'btn.block': { html: UI.button({ label: 'Continue', tone: 'accent', block: true }), sel: '.btn' },
  'btn.small': { html: UI.button({ label: 'Edit', small: true }), sel: '.btn' },
  'btnrow': { html: UI.buttonRow([{ label: 'A' }, { label: 'B' }]), sel: '.btnrow' },
  'fab': { html: UI.fab({ label: 'Add' }), sel: '.fab' },

  // ---- Inputs and selection --------------------------------------------
  'search': { html: UI.searchBar({ placeholder: 'Search' }), sel: '.search' },
  'tsearch': { html: UI.searchBar({}), sel: '.tsearch' },
  'field': { html: UI.field({ label: 'Amount', value: '100' }), sel: '.field' },
  'field.label': { html: UI.field({ label: 'Amount' }), sel: '.field__label' },
  'field.box': { html: UI.field({ label: 'Amount' }), sel: '.field__box' },
  'field.hint': { html: UI.field({ label: 'A', hint: 'Optional' }), sel: '.field__hint' },
  'field.affix': { html: UI.field({ label: 'A', prefix: 'PKR' }), sel: '.field__affix' },
  'field.select': {
    html: UI.selectField({ label: 'From', options: [{ value: 'a', label: 'A' }] }),
    sel: '.field__box--select',
  },
  'fgrid': {
    html: UI.formGrid([UI.field({ label: 'A' }), UI.field({ label: 'B' })]),
    sel: '.fgrid',
  },
  'stepper': { html: UI.stepper({ label: 'People', name: 'n', value: 2 }), sel: '.stepper' },
  'stepper.btn': { html: UI.stepper({ label: 'P', name: 'n', value: 2 }), sel: '.stepper__btn' },
  'stepper.val': { html: UI.stepper({ label: 'P', name: 'n', value: 2 }), sel: '.stepper__val' },
  'fchip': { html: UI.chip({ label: 'All', group: 'g', value: 'a' }), sel: '.fchip' },
  'fchip.on': { html: UI.chip({ label: 'All', group: 'g', value: 'a', on: true }), sel: '.fchip' },
  'fchip.count': {
    html: UI.chip({ label: 'All', group: 'g', value: 'a', count: 12 }),
    sel: '.fchip__n',
  },
  'filterbar': {
    html: UI.filterBar([
      { id: 'g', label: 'G', items: [{ value: 'a', label: 'A', on: true }, { value: 'b', label: 'B' }] },
    ]),
    sel: '.filterbar',
  },
  'segmented': {
    html: UI.segmented({
      id: 's', label: 'S',
      items: [{ value: 'a', label: 'Day', on: true }, { value: 'b', label: 'Week' }],
    }),
    sel: '.segmented',
  },
  'seg': {
    html: UI.segmented({ id: 's', label: 'S', items: [{ value: 'a', label: 'Day' }] }),
    sel: '.seg',
  },
  'seg.on': {
    html: UI.segmented({ id: 's', label: 'S', items: [{ value: 'a', label: 'Day', on: true }] }),
    sel: '.seg',
  },
  'ttabs': {
    html: UI.tabs({
      id: 't',
      items: [{ value: 'a', label: 'All', on: true, count: 3 }, { value: 'b', label: 'Due' }],
    }),
    sel: '.ttabs',
  },
  'ttab': { html: UI.tabs({ id: 't', items: [{ value: 'a', label: 'All' }] }), sel: '.ttab' },
  'ttab.on': {
    html: UI.tabs({ id: 't', items: [{ value: 'a', label: 'All', on: true }] }),
    sel: '.ttab',
  },
  'sortbar': {
    html: UI.sortBar({
      label: 'Sort',
      items: [{ value: 'a', label: 'Name', on: true, dir: 'asc' }, { value: 'b', label: 'Date' }],
    }),
    sel: '.sortbar',
  },
  'sortbar.label': {
    html: UI.sortBar({ label: 'Sort', items: [{ value: 'a', label: 'N' }] }),
    sel: '.sortbar__label',
  },
  'sortopt': { html: UI.sortBar({ items: [{ value: 'a', label: 'Name' }] }), sel: '.sortopt' },
  'sortopt.on': {
    html: UI.sortBar({ items: [{ value: 'a', label: 'N', on: true, dir: 'asc' }] }),
    sel: '.sortopt',
  },

  // ---- Content and data display ----------------------------------------
  'kard': { html: UI.card('<p>x</p>'), sel: '.kard' },
  'summary': {
    html: UI.summaryCard({
      kicker: 'Balance', value: '12,400', unit: 'PKR', caption: 'This month',
      stats: [{ value: '3', label: 'Bills' }],
    }),
    sel: '.summary',
  },
  'summary.kicker': { html: UI.summaryCard({ kicker: 'B', value: '1' }), sel: '.summary__kicker' },
  'summary.value': { html: UI.summaryCard({ value: '12,400' }), sel: '.summary__value' },
  'summary.unit': { html: UI.summaryCard({ value: '1', unit: 'PKR' }), sel: '.summary__unit' },
  'summary.caption': { html: UI.summaryCard({ value: '1', caption: 'x' }), sel: '.summary__caption' },
  'summary.stat': {
    html: UI.summaryCard({ value: '1', stats: [{ value: '3', label: 'B' }] }),
    sel: '.summary__stat',
  },
  'metric': { html: UI.metric({ value: '42', label: 'Tasks', icon: 'i-check' }), sel: '.metric' },
  'metric.value': { html: UI.metric({ value: '42', label: 'T' }), sel: '.metric__value' },
  'metric.label': { html: UI.metric({ value: '42', label: 'Tasks' }), sel: '.metric__label' },
  'metrics': {
    html: UI.metrics([{ value: '1', label: 'A' }, { value: '2', label: 'B' }]),
    sel: '.metrics',
  },
  'delta.up': { html: UI.delta({ value: 1, text: '2.4%' }), sel: '.delta' },
  'delta.down': { html: UI.delta({ value: -1, text: '2.4%' }), sel: '.delta' },
  'rrow': {
    html: rows([UI.richRow({
      title: 'USD', sub: 'US Dollar', value: '278.50', meta: ['Buy', 'Sell'],
      icon: 'i-currency', chevron: true,
    })]),
    sel: '.rrow',
  },
  'rrow.title': { html: rows([UI.richRow({ title: 'USD' })]), sel: '.rrow__title' },
  'rrow.sub': { html: rows([UI.richRow({ title: 'U', sub: 'US Dollar' })]), sel: '.rrow__sub' },
  'rrow.meta': { html: rows([UI.richRow({ title: 'U', meta: ['a', 'b'] })]), sel: '.rrow__meta' },
  'rrow.value': { html: rows([UI.richRow({ title: 'U', value: '278.50' })]), sel: '.rrow__value' },
  'rrow.icon': { html: rows([UI.richRow({ title: 'U', icon: 'i-currency' })]), sel: '.rrow__icon' },
  'rows': { html: rows([UI.richRow({ title: 'A' }), UI.richRow({ title: 'B' })]), sel: '.rows' },
  'crow': {
    html: UI.compactRow({ label: 'Fajr', value: '05:12', icon: 'i-clock' }),
    sel: '.crow',
  },
  'crow.label': { html: UI.compactRow({ label: 'Fajr' }), sel: '.crow__label' },
  'crow.value': { html: UI.compactRow({ label: 'F', value: '05:12' }), sel: '.crow__value' },
  'xrow': { html: UI.expandRow({ head: '<span>More</span>', body: '<p>x</p>' }), sel: '.xrow' },
  'xrow.head': { html: UI.expandRow({ head: '<span>More</span>', body: '' }), sel: '.xrow__head' },
  'dtable': {
    html: UI.table({
      label: 'T',
      cols: [{ label: 'Name' }, { label: 'Value', align: 'right' }],
      rows: [{ cells: ['A', '1'] }],
    }),
    sel: '.dtable',
  },
  'tablewrap': {
    html: UI.table({ label: 'T', cols: [{ label: 'A' }], rows: [{ cells: ['1'] }] }),
    sel: '.tablewrap',
  },
  'notecard': { html: UI.noteCard({ title: 'Heads up', text: 'Something' }), sel: '.notecard' },
  'imgcard': { html: UI.imageCard({ title: 'Story', kicker: 'News', seed: 3 }), sel: '.imgcard' },
  'hstrip': { html: UI.hscroll([UI.imageCard({ title: 'A', seed: 1 })]), sel: '.hstrip' },
  'related': {
    html: UI.relatedTools([{ id: 'calculator', name: 'Calculator', icon: 'i-calculator' }]),
    sel: '.related',
  },
  'related.item': {
    html: UI.relatedTools([{ id: 'c', name: 'C', icon: 'i-calculator' }]),
    sel: '.related__item',
  },
  'tline': {
    html: UI.timeline([
      { time: '09:00', title: 'Depart', sub: 'Lahore' },
      { time: '13:00', title: 'Arrive' },
    ]),
    sel: '.tline',
  },
  'tline.item': {
    html: UI.timeline([{ time: '09:00', title: 'Depart' }]),
    sel: '.tline__item',
  },
  'tline.time': {
    html: UI.timeline([{ time: '09:00', title: 'D' }]),
    sel: '.tline__time',
  },
  'tline.title': {
    html: UI.timeline([{ time: '09:00', title: 'Depart' }]),
    sel: '.tline__title',
  },
  'tline.node': {
    html: UI.timeline([{ time: '09:00', title: 'D' }]),
    sel: '.tline__node',
  },
  'journey': {
    html: UI.journey({
      steps: [{ label: 'Sent', done: true }, { label: 'In transit', now: true }, { label: 'Delivered' }],
    }),
    sel: '.journey',
  },
  'pbar': { html: UI.progressBar({ value: 0.4, label: 'Progress' }), sel: '.pbar' },
  'pbar.fill': { html: UI.progressBar({ value: 0.4, label: 'P' }), sel: '.pbar__fill' },
  'progressring': { html: UI.progressRing({ value: 0.4, label: 'P' }), sel: '.pring' },
  'meter': {
    html: UI.meterRow({ label: 'Water', value: '6 of 10', pct: 0.6 }),
    sel: '.meter',
  },
  'meter.label': {
    html: UI.meterRow({ label: 'Water', value: '6', pct: 0.6 }),
    sel: '.meter__label',
  },
  'meter.value': {
    html: UI.meterRow({ label: 'W', value: '6 of 10', pct: 0.6 }),
    sel: '.meter__value',
  },

  // ---- Status and feedback ---------------------------------------------
  'badge.neutral': { html: UI.statusBadge('Draft'), sel: '.badge' },
  'badge.live': { html: UI.statusBadge({ label: 'Live', tone: 'live' }), sel: '.badge' },
  'badge.ok': { html: UI.statusBadge({ label: 'Paid', tone: 'ok' }), sel: '.badge' },
  'badge.warn': { html: UI.statusBadge({ label: 'Due', tone: 'warn' }), sel: '.badge' },
  'badge.late': { html: UI.statusBadge({ label: 'Late', tone: 'late' }), sel: '.badge' },
  'badge.off': { html: UI.statusBadge({ label: 'Off', tone: 'off' }), sel: '.badge' },
  'fresh.live': { html: UI.freshness({ quality: 'live', label: 'Live' }), sel: '.fresh' },
  'fresh.cached': { html: UI.freshness({ quality: 'cached', label: 'Cached' }), sel: '.fresh' },
  'fresh.delayed': { html: UI.freshness({ quality: 'delayed', label: 'Delayed' }), sel: '.fresh' },
  'srcline': { html: UI.sourceLine({ source: 'SBP', updated: '5 min ago' }), sel: '.srcline' },
  'state.empty': {
    html: UI.emptyState({ title: 'Nothing yet', text: 'Add one', action: { label: 'Add' } }),
    sel: '.state--empty',
  },
  'state.title': { html: UI.emptyState({ title: 'Nothing yet' }), sel: '.state__title' },
  'state.text': { html: UI.emptyState({ title: 'N', text: 'Add one' }), sel: '.state__text' },
  'state.error': {
    html: UI.errorState({ title: 'Could not load', text: 'Try again' }),
    sel: '.state--error',
  },
  'obanner': {
    html: UI.offlineBanner({ title: 'You are offline', text: 'Cached' }),
    sel: '.obanner',
  },
  'sk.row': { html: UI.skeleton('row', 1), sel: '.sk--row' },
  'sk.card': { html: UI.skeleton('card', 1), sel: '.sk--card' },
  'sk.metric': { html: UI.skeleton('metric', 1), sel: '.sk--metric' },
  'sk.chart': { html: UI.skeleton('chart', 1), sel: '.sk--chart' },
  'skgroup': { html: UI.skeleton('row', 3), sel: '.skgroup' },

  // ---- CRUD primitives --------------------------------------------------
  'rrec': {
    html: recs([K.recordRow({
      title: 'Groceries', sub: 'Food', meta: ['Today'], value: '1,240', initial: 'G', act: 'noop',
    })]),
    sel: '.rrec',
  },
  'rrec.selected': {
    html: recs([K.recordRow({ title: 'G', initial: 'G', selected: true, act: 'noop' })]),
    sel: '.rrec',
  },
  'rrec.done': {
    html: recs([K.recordRow({ title: 'G', done: true, check: 'noop' })]),
    sel: '.rrec',
  },
  'rrec.title': { html: recs([K.recordRow({ title: 'G', initial: 'G' })]), sel: '.rrec__title' },
  'rrec.sub': {
    html: recs([K.recordRow({ title: 'G', sub: 'Food', initial: 'G' })]),
    sel: '.rrec__sub',
  },
  'rrec.meta': {
    html: recs([K.recordRow({ title: 'G', meta: ['a', 'b'], initial: 'G' })]),
    sel: '.rrec__meta',
  },
  'rrec.value': {
    html: recs([K.recordRow({ title: 'G', value: '1,240', initial: 'G' })]),
    sel: '.rrec__value',
  },
  'rrec.disc': { html: recs([K.recordRow({ title: 'G', initial: 'G' })]), sel: '.rrec__disc' },
  'rrec.check': { html: recs([K.recordRow({ title: 'G', check: 'noop' })]), sel: '.rrec__check' },
  'rrecs': {
    html: recs([K.recordRow({ title: 'A', initial: 'A' }), K.recordRow({ title: 'B', initial: 'B' })]),
    sel: '.rrecs',
  },
  'crud.count': { html: K.listCount('12 expenses'), sel: '.crud__count' },
  'cchip': {
    html: K.filterChips([{ label: 'Food', count: 3 }]),
    sel: '.cchip',
  },
  'cchip.on': { html: K.filterChips([{ label: 'All', count: 12, on: true }]), sel: '.cchip' },
  'cchips': { html: K.filterChips([{ label: 'All', count: 1 }]), sel: '.cchips' },
  'chero': {
    html: K.recordHero({
      kicker: 'Expense', value: '1,240', title: 'Groceries', caption: 'Today', tone: 'accent',
    }),
    sel: '.chero',
  },
  'chero.kicker': { html: K.recordHero({ kicker: 'E', value: '1' }), sel: '.chero__kicker' },
  'chero.value': { html: K.recordHero({ value: '1,240' }), sel: '.chero__value' },
  'chero.title': { html: K.recordHero({ value: '1', title: 'G' }), sel: '.chero__title' },
  'chero.caption': { html: K.recordHero({ value: '1', caption: 'Today' }), sel: '.chero__caption' },
  'cfacts': {
    html: K.factCard([{ label: 'Category', value: 'Food' }, { label: 'Date', value: 'Today' }]),
    sel: '.cfacts',
  },
  'cfact': { html: K.factCard([{ label: 'Category', value: 'Food' }]), sel: '.cfact' },
  'cfact.label': { html: K.factCard([{ label: 'Category', value: 'F' }]), sel: '.cfact__label' },
  'cfact.value': { html: K.factCard([{ label: 'C', value: 'Food' }]), sel: '.cfact__value' },
  'cacts': { html: K.detailActions({ edit: act, remove: act }), sel: '.cacts' },
  'cact.edit': { html: K.detailActions({ edit: act }), sel: '.cact--edit' },
  'cact.danger': { html: K.detailActions({ edit: act, remove: act }), sel: '.cact--danger' },
  'cfield': { html: K.formField({ name: 'a', label: 'Title', value: 'x' }), sel: '.cfield' },
  'cfield.label': { html: K.formField({ name: 'a', label: 'Title' }), sel: '.cfield__label' },
  'cfield.box': { html: K.formField({ name: 'a', label: 'Title' }), sel: '.cfield__box' },
  'cfield.invalid': {
    html: K.formField({ name: 'a', label: 'Title', error: 'Required' }),
    sel: '.cfield__box',
  },
  'cfield.err': {
    html: K.formField({ name: 'a', label: 'T', error: 'Required' }),
    sel: '.cfield__err',
  },
  'cfield.hint': {
    html: K.formField({ name: 'a', label: 'T', hint: 'Optional' }),
    sel: '.cfield__hint',
  },
  'cfield.opt': {
    html: K.formField({ name: 'a', label: 'T', optional: true, optionalLabel: 'Optional' }),
    sel: '.cfield__opt',
  },
  'cfield.textarea': {
    html: K.formField({ name: 'a', label: 'T', kind: 'textarea' }),
    sel: '.cfield__box textarea',
  },
  'cfield.checkbox': {
    html: K.formField({ name: 'a', label: 'T', kind: 'check' }),
    sel: '.cfield__checkbox',
  },
  'cfield.select': {
    html: K.formField({ name: 'a', label: 'T', kind: 'select', options: [{ value: '1', label: 'A' }] }),
    sel: '.cfield__select',
  },
  'cattach': {
    html: K.formField({ name: 'a', label: 'T', kind: 'attach', attachLabel: 'Add photo' }),
    sel: '.cattach',
  },
  'cform': { html: K.formGrid([K.formField({ name: 'a', label: 'A' })]), sel: '.cform' },
  'cformcard': {
    html: K.formCard({ body: K.formField({ name: 'a', label: 'A' }) }),
    sel: '.cformcard',
  },
  'csubmit': {
    html: K.submitBar({ label: 'Save', act: 'noop', cancel: { label: 'Cancel', act: 'noop' } }),
    sel: '.csubmit',
  },
  'csubmit.busy': {
    html: K.submitBar({ label: 'Save', busy: true, busyLabel: 'Saving…' }),
    sel: '.csubmit .btn',
  },
  'cnotice.error': {
    html: K.saveError({ title: 'Could not save', text: 'Nothing lost', retry: act }),
    sel: '.cnotice--error',
  },
  'cnotice.warn': {
    html: K.conflictNotice({ title: 'Changed elsewhere', text: 'Review', review: act, reload: act }),
    sel: '.cnotice--warn',
  },
  'cnotice.offline': {
    html: K.offlineNotice({ title: 'Offline', text: 'Cached' }),
    sel: '.cnotice--offline',
  },
  'cnotice.act': {
    html: K.saveError({ title: 'x', text: 'y', retry: act }),
    sel: '.cnotice__act',
  },
  'csks': { html: K.loadingRows(3), sel: '.csks' },
  'csk': { html: K.loadingRows(1), sel: '.csk' },
  'cstate.empty': {
    html: K.emptyCollection({ title: 'Nothing yet', text: 'Add one', cta: act }),
    sel: '.cstate',
  },
  'cstate.title': {
    html: K.emptyCollection({ title: 'Nothing yet', text: 'x', cta: act }),
    sel: '.cstate__title',
  },
  'cstate.text': {
    html: K.emptyCollection({ title: 'N', text: 'Add one', cta: act }),
    sel: '.cstate__text',
  },
  'cstate.error': {
    html: K.loadError({ title: 'Could not load', text: 'x', retry: act }),
    sel: '.cstate--error',
  },
  'cstate.quiet': {
    html: K.noMatches({ title: 'No matches', text: 'x', clear: act }),
    sel: '.cstate--quiet',
  },
  'cstate.pane': {
    html: K.noSelection({ title: 'Select a record', text: 'x' }),
    sel: '.cstate--pane',
  },
  'panes': { html: K.panes({ list: '<p>l</p>', detail: '<p>d</p>' }), sel: '.panes' },
  'crud.id': { html: K.recordId('#1024'), sel: '.crud__id' },
  // ---- Navigation (F3) ---------------------------------------------------
  // The shell builds these from tabOrder(); reproduced here as markup so a
  // specimen exists without booting the whole application. Same classes, same
  // structure, same stylesheet — so the same computed values.
  'tabbar': { html: NAV.bar, sel: '.tabbar' },
  'tab': { html: NAV.bar, sel: '.tab' },
  'tab.active': { html: NAV.barActive, sel: '.tab.is-active' },
  'tab.label': { html: NAV.bar, sel: '.tab__label' },
  'tabbar.pill': { html: NAV.bar, sel: '.tabbar__pill' },
  'navside': { html: NAV.side, sel: '.navside' },
  'navside.brand': { html: NAV.side, sel: '.navside__brand' },
  'navtab': { html: NAV.side, sel: '.navtab' },
  'navtab.active': { html: NAV.sideActive, sel: '.navtab.is-active' },
  'navtab.label': { html: NAV.side, sel: '.navtab__label' },
  'statusbar': { html: NAV.status, sel: '.statusbar' },
  'statusbar.brand': { html: NAV.status, sel: '.statusbar__brand' },
  'screen': { html: '<section class="screen is-active"><p>x</p></section>', sel: '.screen' },
};

