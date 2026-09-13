/* Read Home and the Tools hub out of the running prototype.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/measure_destinations.mjs \
 *     --screen home --state muslim_pk --width 390 --height 844 \
 *     --theme light --lang en --shot 1
 *
 * Same method as `measure_auth.mjs`, with one addition that matters more here
 * than it did there: besides `getBoundingClientRect` for a named set of
 * elements, this dumps the **composition** — which slides the carousel kept and
 * in what order, which eight tools filled the grid, which live cards survived,
 * which categories rendered and how many tools each holds.
 *
 * Those lists are the part of Home and Tools that is easiest to get subtly
 * wrong and impossible to see in a screenshot: a round-robin that drains one
 * interest, a category count that disagrees with the grid under it, a hidden
 * feature that reappears through recents. So they are captured as data and the
 * Flutter side asserts against them.
 *
 * A state is set by writing `lume-profile` before the app boots, which is the
 * same store `app-store.js` reads. Nothing is driven through the interface, so
 * the state cannot depend on a click landing.
 */
import { spawn } from 'node:child_process';
import {
  mkdtempSync, cpSync, writeFileSync, readFileSync, mkdirSync, rmSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const argv = process.argv.slice(2);
const args = {};
for (let i = 0; i < argv.length; i++) {
  if (argv[i].startsWith('--')) args[argv[i].slice(2)] = argv[i + 1];
}

const REF = resolve(args.ref || process.cwd());
const CHROME =
  args.chrome || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = resolve(args.out || 'docs/conversion_archive/measurements');
const WIDTH = Number(args.width || 390);
const HEIGHT = Number(args.height || 844);
const THEME = args.theme || 'light';
const LANG = args.lang || 'en';
const DIR = args.dir || (LANG === 'en' ? 'ltr' : 'rtl');
const SCREEN = args.screen || 'home';
const STATE = args.state || 'default_pk';
/* Profile renders three identity states and the profile store knows about
   none of them: the account lives in `lume-accounts` / `lume-session`, which
   is a different store with a different shape. `guest` is the absence of
   both. */
const ACCOUNT = args.account || 'guest';
/* One of `ui/account-ui.js`'s twenty-one routes, opened after the profile tab
   is shown. Empty measures the tab itself. */
const ROUTE = args.route || '';
/* What to call the cell. The default spells out the whole state, which is
   right for a destination; an account route is named after the route, so the
   web capture and the Flutter one share a basename and `compare.mjs` can put
   them side by side. */
const CELL = args.cell || '';
const SHOT = args.shot === '1' || args.shot === 'true';
const SHOTS = resolve(args.shots || 'docs/conversion_archive/shots/destinations');
/* How far down the active screen is scrolled before anything is read. The
   screen is its own scroller, so a page-level capture cannot reach the lower
   sections; this moves the screen instead of the window. */
const SCROLL = Number(args.scroll || 0);
const PORT = Number(args.port || 8181);
const CDP_PORT = Number(args.cdpPort || 9359);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/* ---- the states ---------------------------------------------------------
 * Each is a whole profile, written to `lume-profile`. The seven default
 * interests are what `app-store.js` gives an onboarded user who chose none.
 */
const DEFAULTS = ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news'];

const base = {
  displayName: '', photo: '',
  country: 'PK', region: 'Islamabad Capital Territory', city: 'Islamabad',
  islamic: false, lang: 'en', units: 'auto', currency: 'auto', clock: 'auto',
  method: 'MWL', interests: DEFAULTS.slice(),
  prefs: { news: true, cricket: true, finance: true, recos: true },
  recents: [], favourites: [], market: null, recentCountries: [],
};

/* One device, so "Active sessions" lists this browser once rather than once
   per capture, and one account, created far enough back that "member since"
   has a year worth printing. No digest worth the name: nothing signs in
   during a measurement, and a capture must not carry a credential. */
const DEVICE = 'dev-measure';
const ACCOUNT_EMAIL = 'amina@example.com';
const MEASURE_USER = {
  id: 'usr-measure',
  email: ACCOUNT_EMAIL,
  displayName: 'Amina Rahman',
  firstName: 'Amina',
  lastName: 'Rahman',
  phone: '',
  photo: '',
  digest: '',
  createdAt: new Date(2024, 2, 18, 9, 12).getTime(),
  status: 'active',
  emailVerified: true,
  pendingEmail: '',
  twoFactor: false,
  /* The same three the Flutter fixture seeds, so "Active sessions" and the
     count on Security describe the same account on both sides. One device
     would put the reference on its "no other devices" state and Flutter on
     its list, and the comparison would be about the fixture. */
  sessions: [
    {
      id: DEVICE,
      label: 'Pixel 6 Pro · Lume',
      place: 'Islamabad, Pakistan',
      created: new Date(2024, 2, 18, 9, 12).getTime(),
      lastSeen: new Date(2026, 8, 7, 16, 30).getTime(),
    },
    {
      id: 'dev-mac',
      label: 'MacBook Air · Safari',
      place: 'Islamabad, Pakistan',
      created: new Date(2025, 5, 2, 11, 0).getTime(),
      lastSeen: new Date(2026, 8, 6, 21, 14).getTime(),
    },
    {
      id: 'dev-ipad',
      label: 'iPad · Lume',
      place: 'Lahore, Pakistan',
      created: new Date(2025, 9, 14, 18, 30).getTime(),
      lastSeen: new Date(2026, 7, 29, 9, 2).getTime(),
    },
  ],
};

/* §124.14 — an account with no name is a real state, and the one that gets
   the invitation to complete itself. The address is the identity. */
const NAMELESS_USER = {
  ...MEASURE_USER,
  displayName: '',
  firstName: '',
  lastName: '',
};

const STATES = {
  /* Non-Muslim, Pakistan. The primary cell. */
  default_pk: { ...base },
  /* Muslim, Pakistan — the faith dimension on, with faith interests. */
  muslim_pk: {
    ...base,
    islamic: true,
    interests: [...DEFAULTS, 'prayer', 'quran', 'duas'],
  },
  /* Muslim, United Kingdom — faith on, no Pakistani service. */
  muslim_gb: {
    ...base,
    islamic: true,
    country: 'GB', region: 'England', city: 'London',
    interests: [...DEFAULTS, 'prayer', 'quran'],
  },
  /* Non-Muslim, United States. */
  default_us: {
    ...base,
    country: 'US', region: 'New York', city: 'New York',
  },
  /* Someone with a name, favourites and a history. */
  named_pk: {
    ...base,
    displayName: 'Amina Tariq',
    favourites: ['currency', 'qibla', 'notes'],
    recents: ['calculator', 'weather', 'todos'],
  },
  /* Content switches off — the third gate, which nothing else exercises. */
  prefs_off_pk: {
    ...base,
    prefs: { news: false, cricket: false, finance: false, recos: true },
  },
  /* Nobody chose anything. The quick grid falls back. */
  no_interests_pk: { ...base, interests: [] },
};

/* ---- what is measured --------------------------------------------------- */
const TRAINS_TARGETS = {
  'screen': '#screen-trains',
  'pagehead': '#screen-trains .page-head',
  'pagehead.title': '#screen-trains .page-head__title',
  'pagehead.sub': '#screen-trains .page-head__sub',
  'pagehead.saved': '#screen-trains .page-head .iconbtn',
  'railsearch': '#screen-trains .railsearch',
  'railsearch.row': '#screen-trains .railsearch__row',
  'railfield': '#screen-trains .railfield',
  'railfield.label': '#screen-trains .railfield__label',
  'railfield.value': '#screen-trains .railfield__value',
  'railswap': '#screen-trains .railswap',
  'railsearch.foot': '#screen-trains .railsearch__foot',
  'railchip': '#screen-trains .railchip',
  'railchip.active': '#screen-trains .railchip.is-active',
  'railsearch.go': '#screen-trains .railsearch__go',
  'tracking.title': '#screen-trains .section:has(.live-train) .section__title',
  'tracking.sub': '#screen-trains .section:has(.live-train) .section__sub',
  'tracking.link': '#screen-trains .section:has(.live-train) .section__link',
  'livetrain': '#screen-trains .live-train',
  'livetrain.no': '#screen-trains .live-train__no',
  'livetrain.name': '#screen-trains .live-train__name',
  'livetrain.route': '#screen-trains .live-train__route',
  'livetrain.status': '#screen-trains .live-train__head .status',
  'livetrain.track': '#screen-trains .live-train__track',
  'livetrain.pin': '#screen-trains .live-train__pin',
  'livetrain.stops': '#screen-trains .live-train__stops',
  'departures.title': '#screen-trains .section:has(#trainList) .section__title',
  'departures.sub': '#screen-trains .section:has(#trainList) .section__sub',
  'departures.link': '#screen-trains .section:has(#trainList) .section__link',
  'trainlist': '#trainList',
  'train.row': '#trainList .list-row',
  'train.icon': '#trainList .list-row__icon',
  'train.title': '#trainList .list-row__title',
  'train.no': '#trainList .trainno',
  'train.sub': '#trainList .list-row__sub',
  'train.status': '#trainList .status',
  'popular.title': '#screen-trains .section:has(.routecard) .section__title',
  'popular.sub': '#screen-trains .section:has(.routecard) .section__sub',
  'popular.hscroll': '#screen-trains .section:has(.routecard) .hscroll',
  'routecard': '#screen-trains .routecard',
  'routecard.pair': '#screen-trains .routecard__pair',
  'routecard.meta': '#screen-trains .routecard__meta',
  'routecard.fare': '#screen-trains .routecard__fare',
  'shell.tabbar': '.tabbar',
};

const PROFILE_TARGETS = {
  'screen': '#screen-profile',
  'pagehead': '#screen-profile .page-head',
  'pagehead.title': '#screen-profile .page-head__title',
  'pagehead.sub': '#screen-profile .page-head__sub',
  'pagehead.prefs': '#screen-profile .page-head .iconbtn',
  'identity': '#screen-profile [data-sect="identity"]',
  'phead': '#screen-profile .phead',
  'phead.avatar': '#screen-profile .pavatar',
  'phead.name': '#screen-profile .phead__name',
  'phead.mail': '#screen-profile .phead__mail',
  'phead.meta': '#screen-profile .phead__meta',
  'phead.acts': '#screen-profile .phead__acts',
  'guestwhy': '#screen-profile .guestwhy',
  'phead.complete': '#screen-profile [data-sect="identity"] .notecard',
  'phead.completecta': '#screen-profile [data-sect="identity"] .btnrow',
  'group.lume': '#screen-profile [data-sect="lume"]',
  'group.label': '#screen-profile .group-label',
  'group.list': '#screen-profile [data-sect="lume"] .list',
  'srow': '#screen-profile .list-row',
  'srow.icon': '#screen-profile .list-row__icon',
  'srow.title': '#screen-profile .list-row__title',
  'srow.sub': '#screen-profile .list-row__sub',
  'srow.value': '#screen-profile .srow__value',
  'srow.chev': '#screen-profile .list-row__end .ico',
  'group.account': '#screen-profile [data-sect="account"]',
  'group.support': '#screen-profile [data-sect="support"]',
  'session': '#screen-profile [data-sect="session"]',
  'session.row': '#screen-profile [data-sect="session"] .list-row',
  'version': '#screen-profile .meta',
  'shell.tabbar': '.tabbar',
};

const HOME_TARGETS = {
  'screen': '#screen-home',
  'appbar': '.appbar',
  'appbar.text': '.appbar__text',
  'appbar.greet': '.appbar__greet',
  'appbar.sub': '.appbar__sub',
  'appbar.city': '#appbarCity',
  'appbar.search': '.appbar .iconbtn[data-sheet="search"]',
  'appbar.bell': '.appbar .iconbtn[data-act="tab:notifications"]',
  'appbar.avatar': '#appbarAvatar',
  'ctx': '#screen-home .ctx:not([hidden])',
  'ctx.icon': '#screen-home .ctx:not([hidden]) .ctx__icon',
  'ctx.label': '#screen-home .ctx:not([hidden]) .ctx__label',
  'ctx.title': '#screen-home .ctx:not([hidden]) .ctx__title',
  'ctx.count': '#screen-home .ctx:not([hidden]) .ctx__count',
  'ctx.unit': '#screen-home .ctx:not([hidden]) .ctx__unit',
  'hero': '.hero',
  'hero.track': '#heroTrack',
  'hero.slide': '#heroTrack .slide:not(.is-off)',
  'hero.kicker': '#heroTrack .slide:not(.is-off) .slide__kicker',
  'hero.title': '#heroTrack .slide:not(.is-off) .slide__title',
  'hero.text': '#heroTrack .slide:not(.is-off) .slide__text',
  'hero.cta': '#heroTrack .slide:not(.is-off) .slide__cta',
  'hero.pill': '#heroTrack .slide:not(.is-off) .slide__pill',
  'hero.dots': '#heroDots',
  'hero.dot': '#heroDots .hero__dot',
  'qactions': '#quickActions',
  'qaction': '#quickActions .qaction',
  'qaction.icon': '#quickActions .qaction__icon',
  'qaction.label': '#quickActions .qaction__label',
  'quick.section': '#quickTools',
  'quick.head': '#screen-home .section:has(#quickTools) .section__head',
  'quick.title': '#screen-home .section:has(#quickTools) .section__title',
  'quick.sub': '#quickToolsSub',
  'quick.link': '#screen-home .section:has(#quickTools) .section__link',
  'tool': '#quickTools .tool',
  'tool.icon': '#quickTools .tool__icon',
  'tool.label': '#quickTools .tool__label',
  'tool.value': '#quickTools .tool__value',
  'live.wrap': '#liveWrap',
  'live.title': '#liveWrap .section__title',
  'live.sub': '#liveSub',
  'livecard': '#liveNow .livecard',
  'livecard.icon': '#liveNow .livecard__icon',
  'livecard.title': '#liveNow .livecard__title',
  'livecard.meta': '#liveNow .livecard__meta',
  'livecard.value': '#liveNow .livecard__value',
  'livecard.sub': '#liveNow .livecard__sub',
  'livecard.delta': '#liveNow .delta',
  'glance.title': '#screen-home .section:has(#glanceSub) .section__title',
  'glance.sub': '#glanceSub',
  'glance.link': '#screen-home .section:has(#glanceSub) .section__link',
  'progress': '#screen-home .progress-card:not([hidden])',
  'progress.art': '#screen-home .progress-card:not([hidden]) .progress-card__art',
  'progress.title': '#screen-home .progress-card:not([hidden]) .progress-card__title',
  'progress.meta': '#screen-home .progress-card:not([hidden]) .progress-card__meta',
  'progress.bar': '#screen-home .progress-card:not([hidden]) .bar',
  'progress.fill': '#screen-home .progress-card:not([hidden]) .bar__fill',
  'progress.round': '#screen-home .progress-card:not([hidden]) .roundbtn',
  'statrow': '#screen-home .stat-row:not([hidden])',
  'statrow.icon': '#screen-home .stat-row:not([hidden]) .stat-row__icon',
  'statrow.title': '#screen-home .stat-row:not([hidden]) .stat-row__title',
  'statrow.tag': '#screen-home .stat-row:not([hidden]) .tag',
  'statrow.meta': '#screen-home .stat-row:not([hidden]) .stat-row__meta',
  'statrow.value': '#screen-home .stat-row:not([hidden]) .stat-row__value',
  'statrow.delta': '#screen-home .stat-row:not([hidden]) .stat-row__delta',
  'upcoming.wrap': '#upcomingWrap',
  'upcoming.title': '#upcomingWrap .section__title',
  'upcoming.rows': '#upcomingList .rows',
  'crow': '#upcomingList .crow',
  'crow.icon': '#upcomingList .crow__icon',
  'crow.label': '#upcomingList .crow__label',
  'crow.value': '#upcomingList .crow__value',
  'discover.title': '#screen-home .section:has(#homeDiscover) .section__title',
  'discover.link': '#screen-home .section:has(#homeDiscover) .section__link',
  'hscroll': '#homeDiscover',
  'minicard': '#homeDiscover .minicard:not([hidden])',
  'minicard.art': '#homeDiscover .minicard:not([hidden]) .minicard__art',
  'minicard.title': '#homeDiscover .minicard:not([hidden]) .minicard__title',
  'minicard.meta': '#homeDiscover .minicard:not([hidden]) .minicard__meta',
  'shell.tabbar': '#tabbar',
};

const TODAY_TARGETS = {
  'screen': '#screen-today',
  'pagehead': '#screen-today .page-head',
  'pagehead.title': '#screen-today .page-head__title',
  'pagehead.sub': '#todaySub',
  'pagehead.add': '#screen-today .page-head .iconbtn',
  'ring.card': '#screen-today .ring-card',
  'ring': '#screen-today .ring',
  'ring.value': '#dayRingValue',
  'ring.unit': '#screen-today .ring__unit',
  'ring.title': '#screen-today .ring-card__title',
  'ring.text': '#dayRingText',
  'stats': '#todayStats',
  'stat': '#todayStats .stat',
  'stat.icon': '#todayStats .stat__icon',
  'stat.value': '#todayStats .stat__value',
  'stat.label': '#todayStats .stat__label',
  'quote.section': '#screen-today .section:has(.quote):not([hidden])',
  'quote.title': '#screen-today .section:has(.quote):not([hidden]) .section__title',
  'quote.sub': '#screen-today .section:has(.quote):not([hidden]) .section__sub',
  'quote': '#screen-today .section:not([hidden]) > .row-gap > .quote',
  'quote.mark': '#screen-today .section:not([hidden]) > .row-gap > .quote .quote__mark',
  'quote.arabic': '#screen-today .section:not([hidden]) > .row-gap > .quote .arabic',
  'quote.text': '#screen-today .section:not([hidden]) > .row-gap > .quote .quote__text',
  'quote.by': '#screen-today .section:not([hidden]) > .row-gap > .quote .quote__by',
  'agenda.title': '#screen-today .section:has(#agenda) .section__title',
  'agenda.sub': '#agendaSub',
  'agenda.link': '#screen-today .section:has(#agenda) .section__link',
  'timeline': '#agenda',
  'tl.item': '#agenda .tl-item',
  'tl.time': '#agenda .tl-item .tl-time',
  'tl.node': '#agenda .tl-item .tl-node',
  'tl.card': '#agenda .tl-item .tl-card',
  'tl.title': '#agenda .tl-item .tl-card__title',
  'tl.meta': '#agenda .tl-item .tl-card__meta',
  'tasks.title': '#screen-today .section:has(#taskList) .section__title',
  'tasks.link': '#screen-today .section:has(#taskList) .section__link',
  'tasks.list': '#taskList',
  'task': '#taskList .task',
  'task.box': '#taskList .task .task__box',
  'task.label': '#taskList .task .task__label:not([hidden])',
  'task.time': '#taskList .task .task__time',
  'habits.title': '#screen-today .section:has(.habits) .section__title',
  'habits': '#screen-today .habits',
  'habit': '#screen-today .habit:not([hidden])',
  'habit.name': '#screen-today .habit:not([hidden]) .habit__name',
  'habit.days': '#screen-today .habit:not([hidden]) .habit__days',
  'habit.day': '#screen-today .habit:not([hidden]) .habit__day',
  'habit.streak': '#screen-today .habit:not([hidden]) .habit__streak',
  'private.title': '#screen-today .section:has(.private-card) .section__title',
  'private': '#screen-today .private-card',
  'private.icon': '#screen-today .private-card__icon',
  'private.cardtitle': '#screen-today .private-card__title',
  'private.text': '#screen-today .private-card__text',
  'shell.tabbar': '#tabbar',
};

const EXPLORE_TARGETS = {
  'screen': '#screen-explore',
  'pagehead': '#screen-explore .page-head',
  'pagehead.title': '#screen-explore .page-head__title',
  'pagehead.sub': '#exploreSub',
  'pagehead.search': '#screen-explore .page-head .iconbtn[data-sheet="search"]',
  'feature': '#screen-explore .section:not([hidden]) .feature',
  'feature.tag': '#screen-explore .section:not([hidden]) .feature__tag',
  'feature.title': '#screen-explore .section:not([hidden]) .feature__title',
  'feature.text': '#screen-explore .section:not([hidden]) .feature__text',
  'feature.meta': '#screen-explore .section:not([hidden]) .feature__meta',
  'weather.title': '#screen-explore .section:has(.weather) .section__title',
  'weather.sub': '#weatherSub',
  'weather.link': '#screen-explore .section:has(.weather) .section__link',
  'weather': '#screen-explore .weather',
  'weather.icon': '#screen-explore .weather__icon',
  'weather.temp': '#weatherTemp',
  'weather.desc': '#weatherDesc',
  'weather.grid': '#screen-explore .weather__grid',
  'weather.stat': '#screen-explore .weather__stat',
  'around.wrap': '#aroundWrap',
  'around.title': '#aroundWrap .section__title',
  'around.sub': '#aroundWrap .section__sub',
  'around.tag': '#aroundTag',
  'around.list': '#aroundList',
  'around.row': '#aroundList .list-row',
  'around.row.icon': '#aroundList .list-row__icon',
  'around.row.title': '#aroundList .list-row__title',
  'around.row.sub': '#aroundList .list-row__sub',
  'around.row.value': '#aroundList .list-row__value',
  'cricket.title': '#screen-explore .section:has(.score) .section__title',
  'cricket.sub': '#screen-explore .section:has(.score) .section__sub',
  'cricket.link': '#screen-explore .section:has(.score) .section__link',
  'score': '#screen-explore .score',
  'score.flag': '#screen-explore .score__flag',
  'score.runs': '#screen-explore .score__runs',
  'score.overs': '#screen-explore .score__overs',
  'score.vs': '#screen-explore .score__vs',
  'score.note': '#screen-explore .score__note',
  'news.title': '#screen-explore .section:has(#newsList) .section__title',
  'news.link': '#screen-explore .section:has(#newsList) .section__link',
  'news.list': '#newsList',
  'article': '#newsList .article',
  'article.art': '#newsList .article__art',
  'article.cat': '#newsList .article__cat',
  'article.title': '#newsList .article__title',
  'article.meta': '#newsList .article__meta',
  'collections.title': '#screen-explore .section:has(.hscroll) .section__title',
  'collections.hscroll': '#screen-explore .hscroll',
  'collections.card': '#screen-explore .hscroll .minicard:not([hidden])',
  'nearby.title': '#screen-explore .section:last-child .section__title',
  'nearby.row': '#screen-explore .section:last-child .list-row',
  'nearby.row.title': '#screen-explore .section:last-child .list-row__title',
  'nearby.row.value': '#screen-explore .section:last-child .list-row__value',
  'shell.tabbar': '#tabbar',
};

const TOOLS_TARGETS = {
  'screen': '#screen-tools',
  'pagehead': '#screen-tools .page-head',
  'pagehead.bar': '#screen-tools .page-head__bar',
  'pagehead.title': '.page-head__title',
  'pagehead.sub': '#toolSub',
  'pagehead.action': '#screen-tools .page-head .iconbtn',
  'search': '#screen-tools .search',
  'search.input': '#toolSearch',
  'chips': '#toolChips',
  'chip': '#toolChips .chip',
  'chip.active': '#toolChips .chip.is-active',
  'recent.wrap': '#toolRecent',
  'recent.title': '#toolRecent .section__title',
  'recent': '#toolRecentList .recent',
  'recent.icon': '#toolRecentList .recent__icon',
  'recent.label': '#toolRecentList .recent__label',
  'cat': '#toolCats .cat:not([style*="display: none"])',
  'cat.head': '#toolCats .cat:not([style*="display: none"]) .cat__head',
  'cat.dot': '#toolCats .cat:not([style*="display: none"]) .cat__dot',
  'cat.title': '#toolCats .cat:not([style*="display: none"]) .cat__title',
  'cat.sub': '#toolCats .cat:not([style*="display: none"]) .cat__sub',
  'cat.count': '#toolCats .cat:not([style*="display: none"]) .cat__count',
  'cat.grid': '#toolCats .cat:not([style*="display: none"]) .cat-grid',
  'cattool': '#toolCats .cat-tool:not(.is-hidden)',
  'cattool.icon': '#toolCats .cat-tool:not(.is-hidden) .cat-tool__icon',
  'cattool.label': '#toolCats .cat-tool:not(.is-hidden) .cat-tool__label',
  'cattool.meta': '#toolCats .cat-tool:not(.is-hidden) .cat-tool__meta',
  'cattool.pin': '#toolCats .cat-tool__pin',
  'cattool.flag': '#toolCats .cat-tool__flag',
  'empty': '#toolEmpty',
  'empty.title': '#toolEmpty .empty__title',
  'empty.text': '#toolEmpty .empty__text',
  'shell.tabbar': '#tabbar',
};

/* The account host: one header and one body, whichever of the twenty-one
   routes is in it. The body's own blocks are named rather than indexed,
   because a route that renders nothing would otherwise measure as "the first
   section is missing" rather than as an empty screen. */
const ACCOUNT_TARGETS = {
  'screen': '#screen-account',
  'toolbar': '#screen-account .toolbar',
  'toolbar.back': '#screen-account .toolbar .iconbtn',
  'toolbar.title': '#screen-account .toolbar__title',
  'toolbar.sub': '#screen-account .toolbar__sub',
  'body': '#accountBody',
  'sect': '#accountBody .sect',
  'list': '#accountBody .list',
  'srow': '#accountBody .list-row',
  'srow.icon': '#accountBody .list-row__icon',
  'srow.title': '#accountBody .list-row__title',
  'srow.value': '#accountBody .srow__value',
  'optlist': '#accountBody .optlist',
  'optrow': '#accountBody .optrow',
  'optrow.on': '#accountBody .optrow.is-on',
  'notecard': '#accountBody .notecard',
  'field': '#accountBody .field',
  'field.box': '#accountBody .field__box',
  'btn': '#accountBody .btn',
  'danger': '#accountBody .danger',
  'storegroup': '#accountBody .storegroup',
  'sessrow': '#accountBody .sessrow',
  'conseq': '#accountBody .conseq',
  'state': '#accountBody .state',
  'shell.tabbar': '.tabbar',
};

/* Extra steps a state needs once the app is up. `chip(id)` selects a category;
   `search(q)` types into the hub's field. */
/* Global search is a sheet over the screen that raised it (Q10), so these
   are measured over Home with the sheet up. `#scrim` and `.tabbar` are here
   so the stacking — scrim over the bar, sheet over the scrim — is a number
   rather than an impression. */
const SEARCH_TARGETS = {
  'screen': '.screen.is-active',
  'scrim': '#scrim',
  'shell.tabbar': '.tabbar',
  'sheet': '#sheet-search',
  'sheet.grab': '#sheet-search .sheet__grab',
  'sheet.head': '#sheet-search .sheet__head',
  'sheet.body': '#sheet-search .sheet__body',
  'search': '#sheet-search .search',
  'search.input': '#globalSearch',
  'idle': '#searchIdle',
  'idle.try': '#searchIdle > p:nth-of-type(1)',
  'idle.jump': '#searchIdle > p:nth-of-type(2)',
  'chips': '#searchSuggest',
  'chip': '#searchSuggest .chip',
  'recents': '#searchRecent',
  'recent': '#searchRecent .list-row',
  'recent.icon': '#searchRecent .list-row__icon',
  'results': '#searchResults:not([hidden])',
  'result': '#searchResults .list-row',
  'result.icon': '#searchResults .list-row__icon',
  'result.title': '#searchResults .list-row__title',
  'result.sub': '#searchResults .list-row__sub',
  'result.end': '#searchResults .list-row__end',
  'empty': '#searchEmpty.is-shown',
  'empty.title': '#searchEmpty.is-shown .empty__title',
};

/* The notification centre, reached by its own tab id — the bell's
   `data-act="tab:notifications"` is the same `goTo`. The first row is the one
   measured; the probe reads every row's content separately. */
const NOTIFICATION_TARGETS = {
  'screen': '#screen-notifications',
  'header': '#notifHeader',
  'toolbar': '#notifHeader .toolbar',
  'toolbar.title': '#notifHeader .toolbar__title',
  'toolbar.sub': '#notifHeader .toolbar__sub',
  'tabs': '#screen-notifications .ttabs',
  'tab': '#screen-notifications .ttab',
  'filterbar': '#screen-notifications .filterbar',
  'chip': '#screen-notifications .filterbar .chip',
  'list': '#screen-notifications .nlist',
  'row': '#screen-notifications .nrow',
  'row.main': '#screen-notifications .nrow__main',
  'row.icon': '#screen-notifications .nrow__icon',
  'row.titleline': '#screen-notifications .nrow__titleline',
  'row.badge': '#screen-notifications .nrow__titleline > :not(.nrow__title)',
  'row.title': '#screen-notifications .nrow__title',
  'row.text': '#screen-notifications .nrow__text',
  'row.meta': '#screen-notifications .nrow__meta',
  'row.dot': '#screen-notifications .nrow__dot',
  'row.acts': '#screen-notifications .nrow__acts',
  'row.act': '#screen-notifications .nrow__act',
  'row.dismiss': '#screen-notifications .nrow__dismiss',
  'row2': '#screen-notifications .nrow:nth-child(2)',
  'row2.main': '#screen-notifications .nrow:nth-child(2) .nrow__main',
  'row2.acts': '#screen-notifications .nrow:nth-child(2) .nrow__acts',
  'row5': '#screen-notifications .nrow:nth-child(5)',
  'shell.tabbar': '.tabbar',
};

/* The engine's own demo banner, which every other capture hides. Measured
   over Home, where it fires. */
const BANNER_TARGETS = {
  'screen': '.screen.is-active',
  'banner': '#notifBanner:not([hidden])',
  'banner.main': '#notifBanner .nbanner__main',
  'banner.icon': '#notifBanner .nbanner__icon',
  'banner.title': '#notifBanner .nbanner__title',
  'banner.text': '#notifBanner .nbanner__text',
  'banner.close': '#notifBanner .nbanner__close',
  'shell.tabbar': '.tabbar',
};

/* `#sheet-notifpush` and `#sheet-notifprefs` — the only two notification
   sheets the reference raises. */
const sheetTargets = (id) => ({
  'screen': '.screen.is-active',
  'scrim': '#scrim',
  'sheet': `#sheet-${id}`,
  'sheet.grab': `#sheet-${id} .sheet__grab`,
  'sheet.head': `#sheet-${id} .sheet__head`,
  'sheet.title': `#sheet-${id} .sheet__title`,
  'sheet.body': `#sheet-${id} .sheet__body`,
  'sheet.btn': `#sheet-${id} .btn`,
  'sheet.row': `#sheet-${id} .list-row`,
  'sheet.switch': `#sheet-${id} .switch`,
  'shell.tabbar': '.tabbar',
});

const AFTER = {
  tools_search: "search('petrol')",
  tools_noresults: "search('zzzzz')",
  tools_all: "chip('all')",
  tools_islamic: "chip('islamic')",
  search_idle: "await openSearch('')",
  search_results: "await openSearch('ca')",
  search_petrol: "await openSearch('petrol')",
  search_empty: "await openSearch('zzzz nothing')",
  /* The same sheet over the other destination that raises it, by that
     destination's own control. */
  search_explore: "await openSearch('', '#screen-explore .page-head .iconbtn[data-sheet=\"search\"]')",
  banner: "await waitFor('#notifBanner:not([hidden])', 6000); await wait(500)",
  notifpush: "sheet('notifpush'); await wait(900)",
  notifprefs: "sheet('notifprefs'); await wait(900)",
};

/* The instant everything is captured at: Monday 7 September 2026, 16:41:32
   local — `kFixtureInstant` on the Flutter side, so both render the same day,
   the same greeting and the same "what is open now".

   The prototype reads `new Date()` in a dozen places (the greeting, the live
   row, the outage, the market session), so the page's clock is replaced before
   any module evaluates. Without this, Home is a different screen at breakfast
   and at midnight and nothing can be compared. */
const FREEZE = `
(function () {
  var FIXED = new Date(2026, 8, 7, 16, 41, 32).getTime();
  var Real = Date;
  function Frozen(a, b, c, d, e, f, g) {
    if (!(this instanceof Frozen)) return new Real(FIXED).toString();
    switch (arguments.length) {
      case 0: return new Real(FIXED);
      case 1: return new Real(a);
      case 2: return new Real(a, b);
      case 3: return new Real(a, b, c);
      case 4: return new Real(a, b, c, d);
      case 5: return new Real(a, b, c, d, e);
      case 6: return new Real(a, b, c, d, e, f);
      default: return new Real(a, b, c, d, e, f, g);
    }
  }
  Frozen.prototype = Real.prototype;
  Frozen.now = function () { return FIXED; };
  Frozen.parse = Real.parse;
  Frozen.UTC = Real.UTC;
  window.Date = Frozen;
})();
`;

const DRIVER = (profile, screen, after, account, route, keepBanner) => FREEZE + `
(function () {
  try {
    localStorage.setItem('lume-onboarded', '1');
    localStorage.setItem('lume-profile', ${JSON.stringify(JSON.stringify(profile))});
    var acct = ${JSON.stringify(account)};
    if (acct !== 'guest') {
      localStorage.setItem('lume-device', ${JSON.stringify(DEVICE)});
      localStorage.setItem('lume-accounts', acct === 'noname'
        ? ${JSON.stringify(
            JSON.stringify({ [ACCOUNT_EMAIL]: NAMELESS_USER }),
          )}
        : ${JSON.stringify(
            JSON.stringify({ [ACCOUNT_EMAIL]: MEASURE_USER }),
          )});
      localStorage.setItem('lume-session', JSON.stringify({
        email: ${JSON.stringify(ACCOUNT_EMAIL)},
        token: 'tok-measure',
        issued: Date.now() - 86400000,
        /* An expired session is a session, not a missing one: the record
           stays and only the expiry moves behind us. */
        expires: acct === 'expired' ? Date.now() - 1000 : Date.now() + 86400000 * 29,
        device: ${JSON.stringify(DEVICE)}
      }));
    }
  } catch (e) {}

  function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

  function act(a) {
    var b = document.createElement('button');
    b.setAttribute('data-act', a);
    b.style.cssText = 'position:fixed;opacity:0;pointer-events:none';
    document.body.appendChild(b);
    b.click();
    b.remove();
  }

  function tab(id) {
    var b = document.createElement('button');
    b.setAttribute('data-tab', id);
    b.style.cssText = 'position:fixed;opacity:0;pointer-events:none';
    document.body.appendChild(b);
    b.click();
    b.remove();
  }

  function chip(id) {
    var c = document.querySelector('#toolChips .chip[data-filter="' + id + '"]');
    if (c) c.click();
  }

  /* A sheet, raised by the same data-sheet attribute its callers carry. */
  function sheet(id) {
    var b = document.createElement('button');
    b.setAttribute('data-sheet', id);
    b.style.cssText = 'position:fixed;opacity:0;pointer-events:none';
    document.body.appendChild(b);
    b.click();
    b.remove();
  }

  async function waitFor(sel, ms) {
    for (var i = 0; i < (ms || 4000) / 100; i++) {
      if (document.querySelector(sel)) return true;
      await wait(100);
    }
    throw new Error('never appeared: ' + sel);
  }

  /* The global search sheet, raised the way a reader raises it — by the
     app bar's own control — and typed into after it has finished rising and
     taken focus (320 ms in the shell, plus the sheet's slow transition). */
  async function openSearch(q, control) {
    var b = document.querySelector(control || '.appbar .iconbtn[data-sheet="search"]');
    if (b) b.click();
    await wait(900);
    if (q) {
      var el = document.getElementById('globalSearch');
      if (el) {
        el.value = q;
        el.dispatchEvent(new Event('input', { bubbles: true }));
      }
      await wait(300);
    }
  }

  function search(q) {
    var el = document.getElementById('toolSearch');
    if (!el) return;
    el.value = q;
    el.dispatchEvent(new Event('input', { bubbles: true }));
  }

  async function run() {
    await wait(900);
    tab(${JSON.stringify(screen)});
    await wait(600);
    /* The account host is reached the way a reader reaches it: by the same
       data-act a row carries. Nothing here pokes at internals. */
    if (${JSON.stringify(route)}) {
      act('acct:' + ${JSON.stringify(route)});
      await wait(500);
    }
    ${after || ''};
    await wait(400);
    var clock = document.getElementById('statusClock');
    if (clock) clock.textContent = '16:41';
    /* The notification engine fires a demo banner a second after boot and it
       covers the app bar. It is transient chrome, not part of the screen
       being measured, so it is taken out of the capture rather than waited
       out — waiting would make the capture depend on a timer. */
    var suppress = document.createElement('style');
    suppress.textContent = ${JSON.stringify(
      keepBanner
        ? '.toast{display:none!important}'
        : '.nbanner,.toast{display:none!important}',
    )};
    document.head.appendChild(suppress);
    document.documentElement.setAttribute('data-measure-ready', '1');
  }

  function start() {
    run().catch(function (e) {
      document.documentElement.setAttribute(
        'data-measure-error', String((e && e.message) || e));
    });
  }
  if (document.readyState === 'complete') start();
  else window.addEventListener('load', start);
})();
`;

function stage(driver) {
  const work = mkdtempSync(join(tmpdir(), 'lume-dest-'));
  cpSync(join(REF, 'index.html'), join(work, 'index.html'));
  cpSync(join(REF, 'assets'), join(work, 'assets'), { recursive: true });
  mkdirSync(join(work, 'scripts'), { recursive: true });
  cpSync(join(REF, 'scripts/serve.js'), join(work, 'scripts/serve.js'));
  writeFileSync(join(work, 'measure-driver.js'), driver);

  const html = readFileSync(join(work, 'index.html'), 'utf8');
  writeFileSync(
    join(work, 'index.html'),
    html.replace('</body>', '<script src="measure-driver.js"></script>\n</body>'),
  );
  return work;
}

class Cdp {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    ws.addEventListener('message', (e) => {
      const msg = JSON.parse(e.data);
      const p = this.pending.get(msg.id);
      if (!p) return;
      this.pending.delete(msg.id);
      if (msg.error) p.reject(new Error(JSON.stringify(msg.error)));
      else p.resolve(msg.result);
    });
  }

  send(method, params = {}) {
    const id = ++this.id;
    return new Promise((res, rej) => {
      this.pending.set(id, { resolve: res, reject: rej });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async evaluate(expression) {
    const r = await this.send('Runtime.evaluate', {
      expression,
      returnByValue: true,
      awaitPromise: true,
    });
    if (r.exceptionDetails) {
      throw new Error(
        r.exceptionDetails.text +
          ' — ' +
          (r.exceptionDetails.exception?.description || ''),
      );
    }
    return r.result.value;
  }
}

async function main() {
  const profile = STATES[STATE];
  if (!profile) throw new Error('no state named ' + STATE);
  const targets = {
    tools: TOOLS_TARGETS,
    today: TODAY_TARGETS,
    explore: EXPLORE_TARGETS,
    trains: TRAINS_TARGETS,
    profile: ROUTE ? ACCOUNT_TARGETS : PROFILE_TARGETS,
    notifications: NOTIFICATION_TARGETS,
  }[SCREEN] || HOME_TARGETS;
  const after = String(args.after || '');
  const measured =
    after.startsWith('search_') ? SEARCH_TARGETS
      : after === 'banner' ? BANNER_TARGETS
        : after === 'notifpush' || after === 'notifprefs' ? sheetTargets(after)
          : targets;

  const work = stage(
    DRIVER(profile, SCREEN, AFTER[after] || '', ACCOUNT, ROUTE, after === 'banner'),
  );
  const server = spawn(process.execPath, ['scripts/serve.js'], {
    cwd: work,
    env: { ...process.env, PORT: String(PORT) },
    stdio: 'ignore',
  });
  const chrome = spawn(
    CHROME,
    [
      '--headless=new',
      `--remote-debugging-port=${CDP_PORT}`,
      '--disable-gpu',
      '--hide-scrollbars',
      '--force-prefers-reduced-motion',
      '--no-first-run',
      '--user-data-dir=' + join(work, 'chrome-profile'),
      'about:blank',
    ],
    { stdio: 'ignore' },
  );

  const cleanup = () => {
    try { chrome.kill(); } catch (e) { /* gone */ }
    try { server.kill(); } catch (e) { /* gone */ }
    try { rmSync(work, { recursive: true, force: true }); } catch (e) { /* ok */ }
  };

  try {
    let target = null;
    for (let i = 0; i < 100 && !target; i++) {
      await sleep(120);
      try {
        const list = await fetch(`http://127.0.0.1:${CDP_PORT}/json/list`).then(
          (r) => r.json(),
        );
        target = list.find((t) => t.type === 'page');
      } catch (e) { /* not up */ }
    }
    if (!target) throw new Error('Chrome never opened its debugging port');

    const ws = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((r) => ws.addEventListener('open', r, { once: true }));
    const cdp = new Cdp(ws);
    await cdp.send('Page.enable');
    await cdp.send('Runtime.enable');
    await cdp.send('Emulation.setDeviceMetricsOverride', {
      width: WIDTH,
      height: HEIGHT,
      deviceScaleFactor: 1,
      mobile: WIDTH < 600,
    });
    await cdp.send('Page.navigate', {
      url: `http://127.0.0.1:${PORT}/index.html?theme=${THEME}&lang=${LANG}`,
    });

    let ready = false;
    let failure = null;
    for (let i = 0; i < 300 && !ready && !failure; i++) {
      await sleep(100);
      try {
        ready = await cdp.evaluate(
          "document.documentElement.getAttribute('data-measure-ready') === '1'",
        );
        failure = await cdp.evaluate(
          "document.documentElement.getAttribute('data-measure-error')",
        );
      } catch (e) { /* navigating */ }
    }
    if (failure) throw new Error('driver failed: ' + failure);
    if (!ready) throw new Error('the shell never reached ' + SCREEN);

    await cdp.evaluate(`(function () {
      document.documentElement.dataset.theme = ${JSON.stringify(THEME)};
      document.documentElement.lang = ${JSON.stringify(LANG)};
      document.documentElement.dir = ${JSON.stringify(DIR)};
      document.body.classList.toggle('is-rtl', ${DIR === 'rtl'});
      return true;
    })()`);
    await sleep(400);

    if (SCROLL) {
      await cdp.evaluate(`(function () {
        var el = document.querySelector('.screen.is-active');
        if (el) el.scrollTop = ${SCROLL};
        return el ? el.scrollTop : null;
      })()`);
      await sleep(250);
    }

    const innerWidth = await cdp.evaluate('window.innerWidth');
    if (innerWidth !== WIDTH) {
      throw new Error(`viewport did not take: asked ${WIDTH}, got ${innerWidth}`);
    }

    const result = await cdp.evaluate(`(function () {
      var targets = ${JSON.stringify(measured)};
      var out = {};
      var missing = [];
      Object.keys(targets).forEach(function (name) {
        var el = document.querySelector(targets[name]);
        if (!el) { missing.push(name); return; }
        var r = el.getBoundingClientRect();
        var cs = getComputedStyle(el);
        var lh = parseFloat(cs.lineHeight);
        out[name] = {
          x: Math.round(r.x * 100) / 100,
          y: Math.round(r.y * 100) / 100,
          width: Math.round(r.width * 100) / 100,
          height: Math.round(r.height * 100) / 100,
          lines: Number.isFinite(lh) && lh > 0 ? Math.round(r.height / lh) : null,
          font: cs.fontWeight + ' ' + cs.fontSize + '/' + cs.lineHeight +
                ' ' + cs.letterSpacing,
          color: cs.color,
          background: cs.backgroundColor,
          radius: cs.borderRadius,
          pad: cs.padding,
          gap: cs.gap,
          text: (el.textContent || '').trim().slice(0, 160) || null
        };
      });

      function ids(sel, attr) {
        return Array.prototype.map.call(
          document.querySelectorAll(sel),
          function (el) { return el.dataset[attr]; });
      }
      function texts(sel) {
        return Array.prototype.map.call(
          document.querySelectorAll(sel),
          function (el) { return (el.textContent || '').trim(); });
      }

      /* The composition — the part a screenshot cannot show.
         Every screen stays mounted, so this asks which one is *active*
         rather than which one exists. */
      var active = document.querySelector('.screen.is-active');
      var activeId = active ? active.id : null;
      var composition = {};
      if (activeId === 'screen-home') {
        var shown = Array.prototype.filter.call(
          document.querySelectorAll('#heroTrack .slide'),
          function (el) { return !el.classList.contains('is-off'); });
        shown.sort(function (a, b) { return a.offsetLeft - b.offsetLeft; });
        composition.hero = shown.map(function (el) { return el.dataset.slide; });
        composition.quickTools = ids('#quickTools .tool', 'fid');
        composition.quickToolLabels = texts('#quickTools .tool__label');
        composition.quickToolValues = texts('#quickTools .tool__value');
        composition.quickActions = ids('#quickActions .qaction', 'fid');
        composition.quickActionLabels = texts('#quickActions .qaction__label');
        composition.live = ids('#liveNow .livecard', 'fid');
        composition.liveTitles = texts('#liveNow .livecard__title');
        composition.liveMetas = texts('#liveNow .livecard__meta');
        composition.liveValues = texts('#liveNow .livecard__value');
        composition.upcoming = texts('#upcomingList .crow__label');
        composition.upcomingValues = texts('#upcomingList .crow__value');
        composition.discover = Array.prototype.filter.call(
          document.querySelectorAll('#homeDiscover .minicard'),
          function (el) { return !el.hidden; })
          .map(function (el) {
            return {
              title: (el.querySelector('.minicard__title') || {}).textContent,
              meta: (el.querySelector('.minicard__meta') || {}).textContent
            };
          });
        composition.glance = Array.prototype.filter.call(
          document.querySelectorAll('#screen-home .row-gap > .card'),
          function (el) { return !el.hidden; })
          .map(function (el) {
            return {
              cls: el.className,
              faith: el.dataset.faith || null,
              loc: el.dataset.loc || null,
              text: (el.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 120)
            };
          });
        composition.sections = Array.prototype.map.call(
          document.querySelectorAll('#screen-home > *'),
          function (el) {
            return {
              tag: el.tagName.toLowerCase(),
              cls: el.className,
              id: el.id || null,
              hidden: el.hidden || el.classList.contains('is-hidden'),
              y: Math.round(el.getBoundingClientRect().y * 100) / 100,
              height: Math.round(el.getBoundingClientRect().height * 100) / 100
            };
          });
      }
      function sectionsOf(id) {
        return Array.prototype.map.call(
          document.querySelectorAll('#' + id + ' > *'),
          function (el) {
            var r = el.getBoundingClientRect();
            return {
              tag: el.tagName.toLowerCase(),
              cls: el.className,
              id: el.id || null,
              faith: el.dataset.faith || null,
              int: el.dataset.int || null,
              hidden: el.hidden || el.classList.contains('is-hidden'),
              title: (el.querySelector('.section__title, .page-head__title') || {}).textContent || null,
              y: Math.round(r.y * 100) / 100,
              height: Math.round(r.height * 100) / 100
            };
          });
      }

      if (activeId === 'screen-today') {
        composition.sections = sectionsOf('screen-today');
        composition.dateLine = (document.querySelector('#todaySub') || {}).textContent;
        composition.ring = {
          value: (document.querySelector('#dayRingValue') || {}).textContent,
          text: (document.querySelector('#dayRingText') || {}).textContent
        };
        composition.stats = Array.prototype.map.call(
          document.querySelectorAll('#todayStats .stat'),
          function (el) {
            return {
              value: (el.querySelector('.stat__value') || {}).textContent,
              label: (el.querySelector('.stat__label') || {}).textContent
            };
          });
        composition.agenda = Array.prototype.map.call(
          document.querySelectorAll('#agenda .tl-item'),
          function (el) {
            return {
              time: (el.querySelector('.tl-time') || {}).textContent,
              title: (el.querySelector('.tl-card__title') || {}).textContent,
              meta: (el.querySelector('.tl-card__meta') || {}).textContent,
              state: el.classList.contains('is-now')
                ? 'now'
                : el.classList.contains('is-done') ? 'done' : 'upcoming',
              act: (el.querySelector('.tl-card') || {dataset: {}}).dataset.act || null
            };
          });
        composition.tasks = Array.prototype.map.call(
          document.querySelectorAll('#taskList .task'),
          function (el) {
            var label = Array.prototype.filter.call(
              el.querySelectorAll('.task__label'),
              function (x) { return !x.hidden; })[0];
            return {
              label: label ? label.textContent : null,
              time: (el.querySelector('.task__time') || {}).textContent,
              done: el.classList.contains('is-done'),
              faith: el.dataset.faith || null,
              hidden: el.hidden
            };
          });
        composition.habits = Array.prototype.filter.call(
          document.querySelectorAll('#screen-today .habit'),
          function (el) { return !el.hidden; })
          .map(function (el) {
            return {
              name: (el.querySelector('.habit__name') || {}).textContent,
              days: Array.prototype.map.call(
                el.querySelectorAll('.habit__day'),
                function (d) {
                  return (d.classList.contains('is-on') ? 'on' : 'off') +
                    (d.classList.contains('is-today') ? '+today' : '');
                }),
              streak: (el.querySelector('.habit__streak') || {}).textContent
            };
          });
        composition.quote = Array.prototype.filter.call(
          document.querySelectorAll('#screen-today .section'),
          function (el) { return !el.hidden && el.querySelector('.quote'); })
          .map(function (el) {
            return {
              title: (el.querySelector('.section__title') || {}).textContent,
              sub: (el.querySelector('.section__sub') || {}).textContent,
              arabic: (el.querySelector('.arabic') || {}).textContent || null,
              text: (el.querySelector('.quote__text') || {}).textContent,
              by: (el.querySelector('.quote__by') || {}).textContent
            };
          });
      }

      if (activeId === 'screen-explore') {
        composition.sections = sectionsOf('screen-explore');
        composition.sub = (document.querySelector('#exploreSub') || {}).textContent;
        composition.feature = Array.prototype.filter.call(
          document.querySelectorAll('#screen-explore .section'),
          function (el) { return !el.hidden && el.querySelector('.feature'); })
          .map(function (el) {
            return {
              tag: (el.querySelector('.feature__tag') || {}).textContent,
              title: (el.querySelector('.feature__title') || {}).textContent,
              text: (el.querySelector('.feature__text') || {}).textContent,
              meta: (el.querySelector('.feature__meta') || {}).textContent
            };
          });
        composition.weather = {
          sub: (document.querySelector('#weatherSub') || {}).textContent,
          temp: (document.querySelector('#weatherTemp') || {}).textContent,
          desc: (document.querySelector('#weatherDesc') || {}).textContent,
          stats: texts('#screen-explore .weather__stat')
        };
        composition.aroundHidden = (document.querySelector('#aroundWrap') || {}).hidden;
        composition.aroundTag = (document.querySelector('#aroundTag') || {}).textContent;
        composition.around = Array.prototype.map.call(
          document.querySelectorAll('#aroundList .list-row'),
          function (el) {
            return {
              fid: el.dataset.fid,
              title: (el.querySelector('.list-row__title') || {}).textContent,
              sub: (el.querySelector('.list-row__sub') || {}).textContent,
              value: (el.querySelector('.list-row__value') || {}).textContent || null
            };
          });
        composition.news = Array.prototype.map.call(
          document.querySelectorAll('#newsList .article'),
          function (el) {
            return {
              cat: (el.querySelector('.article__cat') || {}).textContent,
              title: (el.querySelector('.article__title') || {}).textContent,
              meta: (el.querySelector('.article__meta') || {}).textContent
            };
          });
        composition.collections = Array.prototype.filter.call(
          document.querySelectorAll('#screen-explore .hscroll .minicard'),
          function (el) { return !el.hidden; })
          .map(function (el) {
            return {
              title: (el.querySelector('.minicard__title') || {}).textContent,
              meta: (el.querySelector('.minicard__meta') || {}).textContent
            };
          });
        composition.nearby = Array.prototype.filter.call(
          document.querySelectorAll('#screen-explore .section:last-child .list-row'),
          function (el) { return !el.hidden; })
          .map(function (el) {
            return {
              title: (el.querySelector('.list-row__title') || {}).textContent,
              sub: (el.querySelector('.list-row__sub') || {}).textContent,
              value: (el.querySelector('.list-row__value') || {}).textContent
            };
          });
      }

      if (activeId === 'screen-tools') {
        composition.chips = ids('#toolChips .chip', 'filter');
        composition.chipLabels = texts('#toolChips .chip');
        composition.activeChip =
          (document.querySelector('#toolChips .chip.is-active') || {}).dataset;
        composition.activeChip = composition.activeChip
          ? composition.activeChip.filter : null;
        composition.categories = Array.prototype.filter.call(
          document.querySelectorAll('#toolCats .cat'),
          function (el) { return el.style.display !== 'none'; })
          .map(function (el) {
            return {
              id: el.dataset.cat,
              title: (el.querySelector('.cat__title') || {}).textContent,
              sub: (el.querySelector('.cat__sub') || {}).textContent,
              count: (el.querySelector('.cat__count') || {}).textContent,
              tools: Array.prototype.filter.call(
                el.querySelectorAll('.cat-tool'),
                function (t) { return !t.classList.contains('is-hidden'); })
                .map(function (t) {
                  return {
                    id: t.dataset.fid,
                    label: (t.querySelector('.cat-tool__label') || {}).textContent,
                    meta: (t.querySelector('.cat-tool__meta') || {}).textContent,
                    pin: !!t.querySelector('.cat-tool__pin'),
                    flag: !!t.querySelector('.cat-tool__flag'),
                    count: (t.querySelector('.cat-tool__count') || {}).textContent || null
                  };
                })
            };
          });
        composition.recents = ids('#toolRecentList .recent', 'fid');
        composition.emptyShown =
          document.getElementById('toolEmpty').classList.contains('is-shown');
        composition.sections = Array.prototype.map.call(
          document.querySelectorAll('#screen-tools > *'),
          function (el) {
            return {
              tag: el.tagName.toLowerCase(),
              cls: el.className,
              id: el.id || null,
              hidden: el.hidden,
              y: Math.round(el.getBoundingClientRect().y * 100) / 100,
              height: Math.round(el.getBoundingClientRect().height * 100) / 100
            };
          });
      }

      var screenEl = active;
      return {
        bounds: out,
        activeScreen: activeId,
        missing: missing,
        composition: composition,
        tabs: Array.prototype.map.call(
          document.querySelectorAll('#tabbar .tab'),
          function (el) { return el.dataset.tab; }),
        activeTab: (document.querySelector('#tabbar .tab.is-active') || {}).dataset
          ? document.querySelector('#tabbar .tab.is-active').dataset.tab : null,
        scroll: screenEl ? {
          clientHeight: screenEl.clientHeight,
          scrollHeight: screenEl.scrollHeight,
          paddingBottom: getComputedStyle(screenEl).paddingBottom
        } : null
      };
    })()`);

    mkdirSync(OUT, { recursive: true });
    /* The account is part of the cell's identity: `profile_default_pk` is a
       guest, and the same profile signed in is a different screen. */
    const SUFFIX =
      `${STATE}${ACCOUNT === 'guest' ? '' : '_' + ACCOUNT}` +
      `${ROUTE ? '_' + ROUTE : ''}` +
      `${args.after ? '_' + args.after : ''}`;
    const cell =
      `${CELL || SCREEN + '_' + SUFFIX}${SCROLL ? '_s' + SCROLL : ''}` +
      `_${WIDTH}x${HEIGHT}_${THEME}_${LANG}`;

    if (SHOT) {
      const shot = await cdp.send('Page.captureScreenshot', {
        format: 'png',
        captureBeyondViewport: false,
      });
      const dir = join(SHOTS, CELL || `${SCREEN}_${SUFFIX}`);
      mkdirSync(dir, { recursive: true });
      writeFileSync(join(dir, `${cell}.web.png`), Buffer.from(shot.data, 'base64'));
    }

    writeFileSync(
      join(OUT, `${cell}.json`),
      JSON.stringify(
        {
          cell,
          screen: SCREEN,
          state: STATE,
          account: ACCOUNT,
          route: ROUTE || null,
          after: args.after || null,
          profile: { country: profile.country, city: profile.city,
                     islamic: profile.islamic, interests: profile.interests,
                     favourites: profile.favourites, recents: profile.recents,
                     prefs: profile.prefs, displayName: profile.displayName },
          viewport: { width: WIDTH, height: HEIGHT, innerWidth },
          scrollTop: SCROLL,
          theme: THEME, lang: LANG, dir: DIR,
          tabs: result.tabs,
          activeTab: result.activeTab,
          scroll: result.scroll,
          missing: result.missing,
          composition: result.composition,
          bounds: result.bounds,
        },
        null,
        2,
      ) + '\n',
    );

    process.stdout.write(
      `measured ${SCREEN}/${STATE} at ${WIDTH}x${HEIGHT} ${THEME}/${LANG} · ` +
        `${Object.keys(result.bounds).length} elements` +
        (result.missing.length ? ` · absent ${result.missing.length}` : '') +
        '\n',
    );
  } finally {
    cleanup();
  }
}

main().catch((e) => {
  process.stderr.write(`destination measurement failed: ${e.message}\n`);
  process.exit(1);
});
