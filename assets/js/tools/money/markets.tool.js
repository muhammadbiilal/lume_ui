/* ============================================================
   Lume — markets

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';
import { dirOf } from '../shared/direction.js';

/* ------------------------------------------------------------
   The board's own building blocks

   These belong to Markets and to nothing else: an asset row, an
   asset's detail view, the class filters and the overview
   cells. They sit here rather than in a shared module because
   no other tool draws a market board.
   ------------------------------------------------------------ */
function assetRow(c, a, i, cls) {
  var meta = [a.exchange];
  if (a.sectorKey) meta.push(c.t(a.sectorKey));
  if (a.cat) meta.push(c.t('markets.cm.' + a.cat));
  if (a.vol) meta.push(c.t('markets.vol') + ' ' + a.vol);
  if (a.cap) meta.push(c.t('markets.cap') + ' ' + a.cap);
  if (a.unit) meta.push(c.t('markets.per', { unit: a.unit }));
  if (a.contract) meta.push(a.contract);
  if (a.fxKind) meta.push(c.t('markets.fx.' + a.fxKind));

  return UI.richRow({
    logo: a.logo, logoTone: 'var(--tone-' + (a.tone || 'slate') + ')',
    title: a.sym,
    sub: a.name,
    meta: meta,
    spark: UI.sparkline(c.seriesFor(a, '1D').slice(0, 20), { tone: dirOf(a.pct) }),
    value: c.moneyRaw(a.price, a.ccy, priceDp(a)),
    valueSub: a.ccy,
    /* §26.4/§26.6 — the absolute move as well as the percentage. */
    delta: { dir: dirOf(a.pct), text: c.signed(a.chg, priceDp(a)) + '  ' + c.pct(a.pct) },
    act: 'toolstate:markets:detail:' + cls + '|' + a.sym
  });
}

function marketDetail(c, token) {
  var parts = String(token).split('|');
  var cls = parts[0], sym = parts.slice(1).join('|');
  var range = c.filter('range', '1D');
  var d = c.assetDetail(cls, sym, range);
  if (!d) return UI.section({ body: UI.emptyState({ icon: 'i-search',
    title: c.t('markets.noAsset'), text: c.t('markets.noAssetText'),
    action: { label: c.t('common.back'), act: 'toolstate:markets:detail:', icon: 'i-chev-l' } }) });

  var a = d.asset, f = d.f, dp = priceDp(a);
  var st = c.marketState(c.exchange());
  var RANGES = ['1D', '1W', '1M', '3M', '1Y', '5Y'];

  var rows = [
    [c.t('markets.openPrice'), c.moneyRaw(f.open, a.ccy, dp)],
    [c.t('markets.high'), c.moneyRaw(f.high, a.ccy, dp)],
    [c.t('markets.low'), c.moneyRaw(f.low, a.ccy, dp)],
    [c.t('markets.prevClose'), c.moneyRaw(f.prevClose, a.ccy, dp)]
  ];
  if (a.vol) rows.push([c.t('markets.volume'), a.vol]);
  if (a.cap) rows.push([c.t('markets.cap'), a.cap]);
  if (a.unit) rows.push([c.t('markets.unit'), a.unit]);
  if (a.contract) rows.push([c.t('markets.contract'), a.contract]);
  rows.push([c.t('markets.high52'), c.moneyRaw(f.high52, a.ccy, dp)]);
  rows.push([c.t('markets.low52'), c.moneyRaw(f.low52, a.ccy, dp)]);

  return UI.section({ flush: true, body: UI.contextBar([
      { icon: 'i-chev-l', label: c.t('markets.backToMarkets'), act: 'toolstate:markets:detail:' },
      { label: a.exchange }
    ]) +
    /* §26.9 — the detail says whether what it shows is trading. */
    '<div class="mktstate mktstate--' + st.key + '">' +
      UI.freshness({ quality: st.quality, label: st.label }) +
      (st.detail ? '<span class="mktstate__detail">' + UI.esc(st.detail) + '</span>' : '') +
    '</div>' }) +
    UI.section({ body: UI.card(
      '<div class="mkthero__top">' +
        '<span class="mkthero__logo mkthero__logo--' + UI.esc(a.tone || 'slate') + '">' +
          UI.esc(a.logo) + '</span>' +
        '<span class="mkthero__id">' +
          '<span class="mkthero__name">' + UI.esc(a.sym) + '</span>' +
          '<span class="mkthero__sub">' + UI.esc(a.name) + '</span>' +
        '</span>' +
      '</div>' +
      '<div class="mkthero__quote">' +
        '<p class="mkthero__value">' + c.moneyRaw(a.price, a.ccy, dp) + '</p>' +
        '<p class="mkthero__delta">' + UI.delta({ dir: dirOf(a.pct),
          text: c.signed(a.chg, dp) + '  (' + c.pct(a.pct) + ')' }) + '</p>' +
      '</div>' +
      UI.lineChart({ values: d.series, labels: [], tone: dirOf(a.pct), h: 148, label: a.name }) +
      '<div class="mktrange">' + RANGES.map(function (r) {
        return '<button class="mktrange__btn' + (r === range ? ' is-on' : '') +
          '" aria-pressed="' + (r === range ? 'true' : 'false') +
          '" data-act="toolstate:markets:range:' + r + '">' + UI.esc(r) + '</button>';
      }).join('') + '</div>', { cls: 'kard--mkthero' }) }) +
    UI.section({ title: c.t('markets.fundamentals'), body: UI.table({
      label: c.t('markets.fundamentals'),
      cols: [{ label: c.t('common.field') }, { label: c.t('common.value'), align: 'right' }],
      rows: rows.map(function (r) { return { cells: [UI.esc(r[0]), r[1]] }; })
    }) }) +
    (a.kind === 'fx' ? (function () {
      var amount = Number(c.field('mkamount'));
      if (!amount && amount !== 0) amount = 100;
      var pair = String(a.name).split(' / ');
      return UI.section({ title: c.t('markets.convert'), body: UI.card(
        UI.formGrid([
          UI.field({ label: pair[0], name: 'mk_mkamount', type: 'number', value: amount }),
          UI.field({ label: pair[1], name: 'mk_out',
            value: c.num(amount * a.price, { maximumFractionDigits: 4 }) })
        ]) +
        '<p class="convert__rate">1 ' + UI.esc(pair[0]) + ' = ' +
          c.num(a.price, { maximumFractionDigits: 4 }) + ' ' + UI.esc(pair[1]) + '</p>') });
    })() : '') +
    (a.kind === 'stock'
      ? UI.section({ title: c.t('markets.relatedIndices'), body: UI.rows(
          c.assetsFor('indices').slice(0, 3)
            .map(function (x, i) { return assetRow(c, x, i + 40, 'indices'); })) })
      : UI.section({ title: c.t('markets.related'), body: UI.rows(
          c.assetsFor(cls).filter(function (x) { return x.sym !== a.sym; }).slice(0, 3)
            .map(function (x, i) { return assetRow(c, x, i + 40, cls); })) })) +
    UI.section({ body: UI.buttonRow([
      { label: c.t('markets.alert'), tone: 'accent', icon: 'i-bell', act: 'notify:markets:' + a.sym },
      { label: c.t('common.share'), icon: 'i-share', act: 'share:markets' }
    ]) });
}

function filterGroups(c, cls, move) {
  var key = 'move.' + cls;
  function item(v, label) { return { value: v, label: label, on: move === v }; }
  var all = item('all', c.t('common.all'));

  if (cls === 'commodities') {
    return [{ id: key, label: c.t('markets.f.category'),
      items: [all].concat(D.COMMODITY_CATS.map(function (cat) {
        return item(cat, c.t('markets.cm.' + cat));
      })) }];
  }
  if (cls === 'forex') {
    return [{ id: key, label: c.t('markets.f.pairType'),
      items: [all, item('major', c.t('markets.fx.major')), item('minor', c.t('markets.fx.minor')),
              item('pegged', c.t('markets.fx.pegged'))] }];
  }
  if (cls === 'indices') {
    return [{ id: key, label: c.t('markets.f.family'),
      items: [all, item('broad', c.t('markets.f.broad')), item('narrow', c.t('markets.f.narrow'))] }];
  }
  /* Stocks, ETFs and crypto: movement and size. */
  return [{ id: key, label: c.t('markets.filter'),
    items: [all, item('gainers', c.t('markets.gainers')), item('losers', c.t('markets.losers')),
            item('large', c.t('markets.f.largeCap')), item('active', c.t('markets.f.mostActive'))] }];
}

function classLabel(c, cls, classes) {
  var hit = classes.filter(function (k) { return k.id === cls; })[0];
  return hit ? hit.label : cls;
}

function classOverviewFor(c, cls, ex) {
  var byClass = D.classOverview(cls);
  if (byClass) {
    var o = {};
    for (var k in byClass) o[k] = byClass[k];
    o.ccy = 'USD';
    return o;
  }
  var base = c.marketCode() === 'GLOBAL' ? D.GLOBAL_OVERVIEW : D.overviewFor(c.marketCode());
  if (!base) return null;
  var out = {};
  for (var j in base) out[j] = base[j];
  out.ccy = ex ? ex.ccy : 'USD';
  return out;
}

function ovCell2(c, label, value) {
  return '<div class="mktov__cell">' +
    '<span class="mktov__label">' + UI.esc(label) + '</span>' +
    '<span class="mktov__value">' + value + '</span>' +
  '</div>';
}

function sortDims(c, cls) {
  var dims = [
    { value: 'pct', label: c.t('markets.sort.change') },
    { value: 'price', label: c.t('markets.sort.price') },
    { value: 'name', label: c.t('common.name') }
  ];
  if (cls === 'stocks' || cls === 'crypto' || cls === 'etfs') {
    dims.splice(2, 0, { value: 'vol', label: c.t('markets.sort.volume') });
    dims.splice(3, 0, { value: 'cap', label: c.t('markets.sort.cap') });
  }
  return dims;
}

function ovCell(c, label, value, pct) {
  return '<div class="mktov__cell">' +
    '<span class="mktov__label">' + UI.esc(label) + '</span>' +
    '<span class="mktov__value">' + value + '</span>' +
    '<span class="mktov__sub">' + UI.delta({ dir: dirOf(pct), text: c.pct(pct) }) + '</span>' +
  '</div>';
}

function priceDp(a) {
  if (a.decimals !== undefined) return a.decimals;
  if (a.kind === 'index') return 2;
  return a.price < 10 ? 2 : 2;
}

function volNum(v) {
  if (!v) return 0;
  var n = parseFloat(v);
  return n * (/B/.test(v) ? 1e9 : /M/.test(v) ? 1e6 : 1);
}

function capNum(v) {
  if (!v) return 0;
  var n = parseFloat(v);
  return n * (/T/.test(v) ? 1e12 : /B/.test(v) ? 1e9 : /M/.test(v) ? 1e6 : 1);
}

export default {
  id: 'markets',


  build: function (c) {
    /* §26.9 — an asset detail is a view of this tool, reached by
       selecting a row and left with the header's back control. */
    var detail = c.state('detail');
    if (detail) return marketDetail(c, detail);

    var ex = c.exchange();
    var st = c.marketState(ex);
    var classes = c.assetClasses();
    var cls = c.filter('class', 'stocks');
    if (!classes.some(function (k) { return k.id === cls; })) cls = 'stocks';

    var range = c.filter('range', '1D');
    var query = (c.state('q') || '').trim().toLowerCase();
    var hero = c.heroAsset(cls);

    /* ---------- 1. context (§26.1) ---------- */
    var context = UI.section({ id: 'context', flush: true, body:
      UI.contextBar([
        { icon: 'i-globe', label: ex ? ex.code : c.t('markets.global'), act: 'sheet:market' },
        { label: ex ? ex.name : c.t('markets.worldBoard') },
        { label: ex ? ex.ccy : c.L.currencyCode() }
      ]) +
      '<div class="mktstate mktstate--' + st.key + '">' +
        UI.freshness({ quality: st.quality, label: st.label }) +
        (st.detail ? '<span class="mktstate__detail">' + UI.esc(st.detail) + '</span>' : '') +
        '<button class="mktstate__change pressable" data-act="sheet:market">' +
          UI.esc(c.t('markets.change')) + UI.ico('i-chev-r') + '</button>' +
      '</div>' });

    /* ---------- 2. the primary control (§26.2) ---------- */
    var classnav = UI.section({ id: 'classnav', flush: true, body:
      UI.tabs({ id: 'assetclass', label: c.t('markets.assetClass'),
        items: classes.map(function (k) {
          return { value: k.id, label: k.label, on: k.id === cls,
            act: 'toolstate:markets:class:' + k.id };
        }) }) });

    /* ---------- 3. hero + chart + timeframe (§26.3) ---------- */
    var RANGES = ['1D', '1W', '1M', '3M', '1Y', '5Y'];

    var heroSection = hero ? UI.section({ id: 'hero', body: UI.card(
      '<button class="mkthero__top pressable" data-act="toolstate:markets:detail:' + cls + '|' + UI.esc(hero.sym) + '">' +
        '<span class="mkthero__logo mkthero__logo--' + UI.esc(hero.tone || 'accent') + '">' +
          UI.esc(hero.logo) + '</span>' +
        '<span class="mkthero__id">' +
          '<span class="mkthero__name">' + UI.esc(hero.name) + '</span>' +
          '<span class="mkthero__sub">' + UI.esc(hero.sub || '') + '</span>' +
        '</span>' +
        UI.ico('i-chev-r', 'ico mkthero__go') +
      '</button>' +
      '<div class="mkthero__quote">' +
        '<p class="mkthero__value">' + c.moneyRaw(hero.price, hero.ccy, priceDp(hero)) + '</p>' +
        '<p class="mkthero__delta">' + UI.delta({ dir: dirOf(hero.pct),
          text: c.signed(hero.chg, priceDp(hero)) + '  (' + c.pct(hero.pct) + ')' }) + '</p>' +
      '</div>' +
      UI.lineChart({
        values: c.seriesFor(hero, range),
        labels: [], tone: dirOf(hero.pct), h: 120, label: hero.name
      }) +
      '<div class="mktrange">' + RANGES.map(function (r) {
        return '<button class="mktrange__btn' + (r === range ? ' is-on' : '') +
          '" aria-pressed="' + (r === range ? 'true' : 'false') +
          '" data-act="toolstate:markets:range:' + r + '">' + UI.esc(r) + '</button>';
      }).join('') + '</div>', { cls: 'kard--mkthero' }) }) : '';

    /* ---------- 4. top assets (§26.4) ---------- */
    var all = c.assetsFor(cls);
    var filtered = all.filter(function (a) {
      if (!query) return true;
      return (a.sym + ' ' + a.name + ' ' + (a.sub || '')).toLowerCase().indexOf(query) !== -1;
    });

    var move = c.filter('move.' + cls, 'all');
    if (move !== 'all') {
      filtered = filtered.filter(function (a) {
        switch (move) {
          case 'gainers': return a.pct > 0;
          case 'losers': return a.pct < 0;
          case 'large': return capNum(a.cap) >= 1e11;
          case 'active': return volNum(a.vol) >= 1e7;
          case 'major': case 'minor': case 'pegged': return a.fxKind === move;
          case 'broad': return /100|500|All|Composite|General|TASI/i.test(a.name);
          case 'narrow': return !/100|500|All|Composite|General|TASI/i.test(a.name);
          default: return a.cat === move;
        }
      });
    }

    /* Sorting is scoped to the class, like filtering: "market cap" is not a
       dimension a currency pair has, and leaving it selected sorted Forex by
       nothing with no chip lit. */
    var ordered = c.sortBy(filtered, {
      pct: function (a) { return a.pct; },
      price: function (a) { return a.price; },
      vol: function (a) { return volNum(a.vol); },
      cap: function (a) { return capNum(a.cap); },
      name: function (a) { return a.name; }
    }, 'pct', 'desc', cls);

    var showAll = c.state('showAll') === 'true';
    /* The hero is already the lead asset; repeating it as row one wasted the
       most valuable line on the screen. */
    var listed = hero ? ordered.filter(function (a) { return a.sym !== hero.sym; }) : ordered;
    var visible = showAll ? listed : listed.slice(0, 5);

    /* §26.7/§26.8 — the controls sit immediately above the list they act on,
       not two sections below it. */
    var controls =
      UI.section({ tight: true, body: UI.searchBar({ placeholder: c.t('markets.search.' + cls) ===
          'markets.search.' + cls ? c.t('markets.search') : c.t('markets.search.' + cls),
        target: 'markets', value: c.state('q') || '' }) }) +
      UI.section({ tight: true, body: UI.filterBar(filterGroups(c, cls, move), 'markets') }) +
      UI.section({ tight: true, body: UI.sortBar({ tool: 'markets', scope: cls,
        label: c.t('common.sort'),
        items: c.sortItems(sortDims(c, cls), 'pct', 'desc', cls) }) });

    var assetsSection = UI.section({
      id: 'assets',
      title: c.t('markets.top.' + cls) === 'markets.top.' + cls ? c.t('markets.topAssets') : c.t('markets.top.' + cls),
      link: listed.length > 5
        ? { label: showAll ? c.t('markets.showLess') : c.t('markets.seeAll'),
            act: 'toolstate:markets:showAll:' + (showAll ? 'false' : 'true') }
        : null,
      body: visible.length
        ? UI.rows(visible.map(function (a, i) { return assetRow(c, a, i, cls); }))
        : UI.emptyState({ icon: 'i-search',
            title: query ? c.t('markets.noMatch', { q: query }) : c.t('markets.noAssets'),
            text: query ? c.t('markets.noMatchText') : c.t('markets.noAssetsText'),
            /* §26.10 — an empty state offers a way out, always. */
            action: query
              ? { label: c.t('markets.clearSearch'), act: 'toolsearch:markets:', icon: 'i-refresh' }
              : { label: c.t('markets.change'), act: 'sheet:market', icon: 'i-globe' } })
    });

    /* ---------- 5. market overview (§26.5) ---------- */
    var ov = classOverviewFor(c, cls, ex);
    var overviewSection = ov ? UI.section({ id: 'overview', title: c.t('markets.overview'),
      sub: c.t('markets.overviewFor', { name: classLabel(c, cls, classes) }), body: UI.card(
      '<div class="mktov">' +
        (ov.cap !== undefined
          ? ovCell(c, c.t('markets.totalCap'), c.L.compactMoney(ov.cap, ov.ccy), ov.capPct) : '') +
        (ov.volume !== undefined
          ? ovCell(c, c.t('markets.volume'), c.L.compact(ov.volume), ov.volPct) : '') +
        (ov.adv !== undefined
          ? '<div class="mktov__cell">' +
              '<span class="mktov__label">' + UI.esc(c.t('markets.advDec')) + '</span>' +
              '<span class="mktov__value"><b class="is-up">↑ ' + c.num(ov.adv) + '</b>' +
                ' <i>/</i> <b class="is-down">↓ ' + c.num(ov.dec) + '</b></span>' +
              '<span class="mktov__sub">' + c.num(ov.unch || 0) + ' ' +
                UI.esc(c.t('markets.unchanged')) + '</span>' +
            '</div>'
          : ov.pairs !== undefined
          ? ovCell2(c, c.t('markets.pairsTracked'), c.num(ov.pairs))
          : ov.contracts !== undefined
          ? ovCell2(c, c.t('markets.contractsTracked'), c.num(ov.contracts)) : '') +
      '</div>' +
      (ov.adv !== undefined
        ? '<div class="mktbreadth">' +
            '<span class="mktbreadth__bar"><i style="width:' +
              Math.round(ov.adv / (ov.adv + ov.dec + (ov.unch || 0)) * 100) + '%"></i>' +
              '<u style="width:' + Math.round((ov.unch || 0) / (ov.adv + ov.dec + (ov.unch || 0)) * 100) +
              '%"></u></span>' +
            '<span class="mktbreadth__label">' + UI.esc(c.t('markets.breadth')) + '</span>' +
          '</div>'
        : '') +
      /* §26.5 — only metrics this market actually publishes. */
      (ov.turnover !== undefined ? UI.metrics([
        { value: c.L.compactMoney(ov.turnover, ov.ccy), label: c.t('markets.turnover') },
        { value: c.num(ov.trades), label: c.t('markets.trades') },
        { value: ov.session ? c.t('markets.session.' + ov.session) : '—', label: c.t('markets.sessionLabel') }
      ], 3) : '')) }) : '';

    var world = cls !== 'indices' ? '' : UI.section({ title: c.t('markets.tab.global'),
      body: UI.rows(D.GLOBAL_INDICES.map(function (ix, i) {
        return UI.richRow({
          logo: ix.sym.slice(0, 3), logoTone: 'var(--tint-neutral)',
          title: ix.name, sub: ix.full,
          spark: UI.sparkline(D.walk(ix.value + i, 20, ix.value, 0.005), { tone: dirOf(ix.pct) }),
          value: c.num(ix.value, { maximumFractionDigits: 2 }),
          delta: { dir: dirOf(ix.pct), text: c.pct(ix.pct) }
        });
      })) });

    return context + classnav + heroSection + controls + assetsSection + overviewSection + world;
  }
};
