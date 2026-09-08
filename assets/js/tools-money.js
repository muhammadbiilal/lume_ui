/* ============================================================
   Lume — Money & Rates screens  (Master Spec §25–§38)

   Markets is the reference implementation for §26 and §114: a
   security is never reduced to name + price + percentage when
   the dataset carries exchange, currency, absolute change,
   sparkline, volume, market cap and session status.

   Everything here reads its regional configuration (§105), so
   the same screen shows PSX in Karachi, the LSE in London and
   Tadawul in Riyadh without a single `if country ==` branch.
   ============================================================ */
(function () {
  'use strict';

  var UI = window.LUME_UI;
  var D = window.LUME_DATA;
  var T = window.LUME_TOOLS;

  /* Percentages and signed changes are numbers: `1,25 %` in German, Eastern
     digits in Arabic. They go through the locale engine like every other
     figure (§106) — hence the context, not a module-level helper. */
  function dirOf(n) { return n > 0 ? 'up' : n < 0 ? 'down' : 'flat'; }

  /* ---------------------------------------------------------
     §26 Markets — built to the approved reference composition
     (§26.13, §123), not inferred from the archetype:

       context → classnav → hero → assets → overview

     The market-type control leads the content. The indices list
     is one class within it, not the body of the screen.
     --------------------------------------------------------- */
  T.register('markets', function (c) {
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
  });

  /* §26.4 — one rich row shape, filled from whatever the class carries. */
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

  /* §26.9 — the detail screen. */
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
      [c.t('markets.open'), c.moneyRaw(f.open, a.ccy, dp)],
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

  /* §26.8 — filters follow the class. An index has no market cap and a
     currency pair has no sector, so neither is ever offered one. */
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

  /* §26.5 — the overview a class can actually support. */
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

  /* ---------------------------------------------------------
     §25.1 Currency & Gold — data explorer
     --------------------------------------------------------- */
  T.register('goldrates', function (c) {
    var g = c.metals();
    var query = (c.state('q') || '').trim().toLowerCase();
    var pairs = g.pairs.filter(function (p) {
      return !query || (p.code + ' ' + p.name).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.t('rates.openMarket') }]) }) +
      UI.section({ body: UI.summaryCard({
        tone: 'gold',
        kicker: c.t('rates.gold24'),
        value: c.moneyRaw(g.gold.perTola, g.ccy, 0),
        unit: '/ ' + c.t('unit.tola'),
        caption: UI.delta({ dir: dirOf(g.gold.pct), text: c.signed(g.gold.chg, 0) + '  ' + c.pct(g.gold.pct) }),
        stats: [
          { value: c.moneyRaw(g.gold.perGram, g.ccy, 0), label: c.t('unit.gram') },
          { value: c.moneyRaw(g.gold.perOunce, 'USD', 0), label: c.t('unit.ounce') },
          { value: c.moneyRaw(g.silver.perTola, g.ccy, 0), label: c.t('rates.silverTola') }
        ]
      }) }) +
      UI.section({ title: c.t('rates.metals'), body: UI.table({
        label: c.t('rates.metals'),
        cols: [{ label: c.t('rates.metal') }, { label: c.t('unit.gram'), align: 'right' },
               { label: c.t('unit.tola'), align: 'right' }, { label: c.t('common.change'), align: 'right' }],
        rows: [
          { cells: [c.t('rates.gold24'), c.moneyRaw(g.gold.perGram, g.ccy, 0), c.moneyRaw(g.gold.perTola, g.ccy, 0),
                    UI.delta({ dir: dirOf(g.gold.pct), text: c.pct(g.gold.pct) })] },
          { cells: [c.t('rates.gold22'), c.moneyRaw(g.gold.perGram * 0.916, g.ccy, 0), c.moneyRaw(g.gold.perTola * 0.916, g.ccy, 0),
                    UI.delta({ dir: dirOf(g.gold.pct), text: c.pct(g.gold.pct) })] },
          { cells: [c.t('rates.silver'), c.moneyRaw(g.silver.perGram, g.ccy, 0), c.moneyRaw(g.silver.perTola, g.ccy, 0),
                    UI.delta({ dir: dirOf(g.silver.pct), text: c.pct(g.silver.pct) })] }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('rates.search'), target: 'goldrates', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('rates.currencies'), body: pairs.length ? UI.rows(pairs.map(function (p) {
        return UI.richRow({
          logo: p.flag, logoTone: 'var(--tint-neutral)',
          title: p.code, sub: p.name,
          meta: [c.t('rates.buy') + ' ' + c.num(p.buy, { maximumFractionDigits: 2 }),
                 c.t('rates.sell') + ' ' + c.num(p.sell, { maximumFractionDigits: 2 })],
          spark: UI.sparkline(D.walk(Math.round(p.sell * 10), 18, p.sell, 0.008), { tone: dirOf(p.pct) }),
          value: c.num(p.sell, { maximumFractionDigits: 2 }),
          delta: { dir: dirOf(p.pct), text: c.pct(p.pct) }
        });
      })) : UI.emptyState({ icon: 'i-currency', title: c.t('rates.noMatch'),
        text: c.t('rates.noMatchText') }) }) +
      UI.section({ title: c.t('rates.history'), body: UI.card(
        UI.lineChart({ values: D.walk(9001, 30, g.gold.perTola, 0.01), labels: ['30d', '15d', c.t('common.today')],
          label: c.t('rates.goldHistory'), caption: c.t('rates.goldHistoryCap') })) }) +
      UI.section({ title: c.t('rates.converter'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('rates.weight'), name: 'g_weight', type: 'number', value: 10, suffix: c.t('unit.gram') }),
        UI.field({ label: c.t('rates.worth'), name: 'g_value', value: c.moneyRaw(g.gold.perGram * 10, g.ccy, 0) })
      ])) });
  });

  /* ---------------------------------------------------------
     Currency converter — global, locale-aware
     --------------------------------------------------------- */
  T.register('currency', function (c) {
    var cv = c.currencyBoard();
    var query = (c.state('q') || '').trim().toLowerCase();
    var popular = cv.popular.filter(function (p) {
      return !query || (p.code + ' ' + p.name).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.card(
        '<div class="convert">' +
          '<div class="convert__side">' +
            '<span class="convert__code">' + UI.esc(cv.from) + '</span>' +
            '<input class="convert__input" type="number" inputmode="decimal" value="' + cv.amount + '" data-input="cv_amount">' +
            '<span class="convert__name">' + UI.esc(cv.fromName) + '</span>' +
          '</div>' +
          '<button class="convert__swap pressable" data-act="cvswap" aria-label="' + UI.esc(c.t('convert.swap')) + '">' +
            UI.ico('i-swap') + '</button>' +
          '<div class="convert__side convert__side--to">' +
            '<span class="convert__code">' + UI.esc(cv.to) + '</span>' +
            '<span class="convert__out" data-cv-out>' + c.num(cv.result, { maximumFractionDigits: 2 }) + '</span>' +
            '<span class="convert__name">' + UI.esc(cv.toName) + '</span>' +
          '</div>' +
        '</div>' +
        '<p class="convert__rate">1 ' + UI.esc(cv.from) + ' = ' + c.num(cv.rate, { maximumFractionDigits: 4 }) + ' ' + UI.esc(cv.to) + '</p>') }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('convert.search'), target: 'currency', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('convert.popular'), body: popular.length ? UI.rows(popular.map(function (p) {
        return UI.richRow({
          logo: p.flag, logoTone: 'var(--tint-neutral)',
          title: p.code, sub: p.name,
          spark: UI.sparkline(D.walk(p.code.charCodeAt(0) * 7, 16, p.rate, 0.006), { tone: dirOf(p.pct) }),
          value: c.num(p.rate, { maximumFractionDigits: 3 }),
          delta: { dir: dirOf(p.pct), text: c.pct(p.pct) },
          act: 'toast:1 ' + cv.from + ' = ' + c.num(p.rate, { maximumFractionDigits: 3 }) + ' ' + p.code
        });
      })) : UI.emptyState({ icon: 'i-currency', title: c.t('rates.noMatch'), text: c.t('rates.noMatchText') }) }) +
      UI.section({ title: c.t('convert.chart', { pair: cv.from + '/' + cv.to }), body: UI.card(
        UI.lineChart({ values: D.walk(4242, 30, cv.rate, 0.006), labels: ['30d', '15d', c.t('common.today')],
          label: cv.from + '/' + cv.to })) }) +
      UI.section({ title: c.t('convert.recent'), body: UI.rows(cv.recent.map(function (r) {
        return UI.compactRow({ icon: 'i-clock', label: r.label, value: r.value });
      })) });
  });

  /* ---------------------------------------------------------
     §27 Fuel prices — regional data explorer
     --------------------------------------------------------- */
  T.register('fuel', function (c) {
    var f = D.fuelFor(c.profile.country);
    var main = f.items[0];
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.t('fuel.effective', { date: f.effectiveKey ? c.t(f.effectiveKey) : f.effective }) }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t(main.nk) + ' · ' + main.code,
        value: c.moneyRaw(main.v, f.ccy, 2),
        unit: '/ ' + c.t('unit.' + f.unit),
        caption: UI.delta({ dir: dirOf(main.v - main.prev), text: c.signed(main.v - main.prev) + ' ' + c.t('fuel.sinceLast') }),
        stats: f.items.slice(1, 4).map(function (i) {
          return { value: c.moneyRaw(i.v, f.ccy, 2), label: c.t(i.nk) };
        })
      }) }) +
      UI.section({ title: c.t('fuel.allGrades'), body: UI.table({
        label: c.t('fuel.allGrades'),
        cols: [{ label: c.t('fuel.grade') }, { label: c.t('fuel.previous'), align: 'right' },
               { label: c.t('fuel.current'), align: 'right' }, { label: c.t('common.change'), align: 'right' }],
        rows: f.items.map(function (i) {
          return { cells: [UI.esc(c.t(i.nk)) + ' <i class="cellsub">' + UI.esc(i.code) + '</i>',
                           c.moneyRaw(i.prev, f.ccy, 2), c.moneyRaw(i.v, f.ccy, 2),
                           UI.delta({ dir: dirOf(i.v - i.prev), text: c.signed(i.v - i.prev) })] };
        })
      }) }) +
      UI.section({ title: c.t('fuel.trend'), body: UI.card(
        UI.lineChart({ values: D.walk(731, 24, main.v, 0.01), labels: ['6m', '3m', c.t('common.now')],
          label: c.t('fuel.trend'), caption: c.t('fuel.trendCap') })) }) +
      UI.section({ title: c.t('fuel.related'), body: UI.rows([
        UI.richRow({ icon: 'i-route', title: c.t('f.fuelcost'), sub: c.t('fuel.tripHint'), act: 'tool:fuelcost', chevron: true }),
        UI.richRow({ icon: 'i-car', title: c.t('f.vehicle'), sub: c.t('fuel.vehicleHint'), act: 'tool:vehicle', chevron: true })
      ]) });
  });

  /* ---------------------------------------------------------
     §28 Fuel cost — calculator
     --------------------------------------------------------- */
  T.register('fuelcost', function (c) {
    var fc = c.fuelCost();
    return UI.section({ id: 'inputs', title: c.t('tool.inputs'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('fuelcost.distance'), name: 'fc_dist', type: 'number', value: fc.f.dist,
          suffix: c.L.unitSystem() === 'imperial' ? c.t('unit.mi') : c.t('unit.km') }),
        UI.field({ label: c.t('fuelcost.economy'), name: 'fc_econ', type: 'number', value: fc.f.econ,
          suffix: fc.econUnit }),
        UI.field({ label: c.t('fuelcost.price'), name: 'fc_price', type: 'number', value: fc.f.price,
          prefix: fc.ccy, hint: c.t('fuelcost.priceHint') }),
        UI.field({ label: c.t('fuelcost.people'), name: 'fc_people', type: 'number', value: fc.f.people })
      ])) }) +
      UI.section({ id: 'result', body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('fuelcost.total'),
        value: '<span data-fc-total>' + c.moneyRaw(fc.total, fc.ccy, 0) + '</span>',
        caption: c.t('fuelcost.forTrip', { d: fc.distLabel }),
        stats: [
          { value: '<span data-fc-fuel>' + fc.fuelUsed + '</span>', label: c.t('fuelcost.used') },
          { value: '<span data-fc-per>' + c.moneyRaw(fc.perPerson, fc.ccy, 0) + '</span>', label: c.t('fuelcost.perPerson') },
          { value: c.moneyRaw(fc.perUnit, fc.ccy, 2), label: fc.perUnitLabel }
        ]
      }) }) +
      UI.section({ title: c.t('fuelcost.compare'), body: UI.table({
        label: c.t('fuelcost.compare'),
        cols: [{ label: c.t('fuelcost.scenario') }, { label: c.t('fuelcost.consumption'), align: 'right' },
               { label: c.t('fuelcost.cost'), align: 'right' }],
        rows: fc.scenarios.map(function (s) {
          return { cells: [UI.esc(s.label), s.fuel, c.moneyRaw(s.cost, fc.ccy, 0)] };
        })
      }) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(fc.history.map(function (h) {
        return UI.compactRow({ icon: 'i-route', label: h.label, sub: h.when, value: c.moneyRaw(h.cost, fc.ccy, 0) });
      })) });
  });

  /* ---------------------------------------------------------
     §29 Tax — guided calculator, country-configurable
     --------------------------------------------------------- */
  T.register('tax', function (c) {
    var tx = c.tax();
    var tx0 = tx.config || {};
    if (!tx.config) {
      return UI.section({ body: UI.emptyState({
        icon: 'i-percent',
        title: c.t('tax.unsupported.title', { country: c.L.countryName(c.profile.country) }),
        text: c.t('tax.unsupported.text'),
        action: { label: c.t('settings.changeCountry'), act: 'sheet:personalise', icon: 'i-globe' }
      }) });
    }
    /* No income tax is not "nothing to show": the levies a salary actually
       meets here are what the user came to find out (§91, §112). */
    if (!tx.taxable) {
      var levies = D.leviesFor(c.profile.country);
      var gross = Number(c.field('income') || 3000 * (c.L.RATES[tx0.ccy] || 1));
      return UI.section({ flush: true, body: UI.contextBar([
          { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
          { label: tx0.authority }, { label: tx0.year }]) }) +
        UI.section({ body: UI.summaryCard({
          tone: 'accent',
          kicker: c.t('tax.takeHome'),
          value: c.moneyRaw(gross, tx0.ccy, 0),
          caption: c.t('tax.noneCaption'),
          stats: [
            { value: c.pct(0, 0), label: c.t('tax.incomeTax') },
            { value: c.num(levies[0].rate, { maximumFractionDigits: 2 }) + '%', label: c.t(levies[0].key) },
            { value: tx0.year, label: c.t('tax.year') }
          ]
        }) }) +
        UI.section({ id: 'inputs', body: UI.card(UI.formGrid([
          UI.field({ label: c.t('tax.incomeMonthly'), name: 'tax_income', type: 'number',
            value: gross, prefix: tx0.ccy, wide: true })
        ])) }) +
        UI.section({ body: UI.noteCard({ icon: 'i-info', tone: 'ok',
          title: c.t('tax.none.title'), text: c.t('tax.none.text', { authority: tx0.authority }) }) }) +
        UI.section({ title: c.t('tax.otherLevies'), body: UI.table({
          label: c.t('tax.otherLevies'),
          cols: [{ label: c.t('tax.levy') }, { label: c.t('tax.rate'), align: 'right' }],
          rows: levies.map(function (l) {
            return { cells: [UI.esc(c.t(l.key)),
                             c.num(l.rate, { maximumFractionDigits: 2 }) + '%'] };
          })
        }) }) +
        UI.section({ title: c.t('tax.leviesNote'), body: UI.card(
          '<p class="kard__lead">' + UI.esc(c.t('tax.leviesNoteText')) + '</p>', { tone: 'quiet' }) });
    }

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: tx.config.authority },
        { label: tx.config.year }]) }) +
      UI.section({ body: UI.segmented({ id: 'taxperiod', label: c.t('tax.period'), items: [
        { value: 'month', label: c.t('tax.monthly'), on: tx.period === 'month', act: 'toolstate:tax:period:month' },
        { value: 'year', label: c.t('tax.annual'), on: tx.period === 'year', act: 'toolstate:tax:period:year' }
      ] }) }) +
      UI.section({ id: 'inputs', body: UI.card(UI.formGrid([
        UI.field({ label: tx.period === 'month' ? c.t('tax.incomeMonthly') : c.t('tax.incomeAnnual'),
          name: 'tax_income', type: 'number', value: tx.f.income, prefix: tx.ccy, wide: true }),
        UI.field({ label: c.t('tax.deductions'), name: 'tax_ded', type: 'number', value: tx.f.deductions, prefix: tx.ccy })
      ])) }) +
      UI.section({ id: 'result', body: UI.summaryCard({
        tone: 'accent',
        kicker: tx.period === 'month' ? c.t('tax.dueMonthly') : c.t('tax.dueAnnual'),
        value: '<span data-tax-due>' + c.moneyRaw(tx.dueDisplay, tx.ccy, 0) + '</span>',
        caption: c.t('tax.effective', { rate: c.num(tx.effective * 100, { maximumFractionDigits: 1 }) + '%' }),
        stats: [
          { value: '<span data-tax-net>' + c.moneyRaw(tx.netDisplay, tx.ccy, 0) + '</span>', label: c.t('tax.takeHome') },
          { value: c.moneyRaw(tx.taxableAnnual, tx.ccy, 0), label: c.t('tax.taxable') },
          { value: c.num(tx.marginal * 100, { maximumFractionDigits: 0 }) + '%', label: c.t('tax.marginal') }
        ]
      }) }) +
      UI.section({ id: 'breakdown', title: c.t('tax.slabs'), body: UI.table({
        label: c.t('tax.slabs'),
        cols: [{ label: c.t('tax.band') }, { label: c.t('tax.rate'), align: 'right' },
               { label: c.t('tax.taxedHere'), align: 'right' }],
        rows: tx.bands.map(function (b) {
          return { cells: [UI.esc(b.label), c.num(b.rate * 100, { maximumFractionDigits: 0 }) + '%', c.moneyRaw(b.tax, tx.ccy, 0)] };
        })
      }) }) +
      UI.section({ body: UI.card(UI.donut({
        label: c.t('tax.split'),
        centre: c.moneyRaw(tx.netDisplay, tx.ccy, 0),
        centreSub: c.t('tax.takeHome'),
        slices: [
          { label: c.t('tax.takeHome'), value: tx.netAnnual, color: 'var(--accent)' },
          { label: c.t('tax.tax'), value: tx.dueAnnual, color: 'var(--amber)' }
        ]
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('common.export'), icon: 'i-download', tone: 'accent', act: 'export:tax' },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:tax' }]) });
  });

  /* ---------------------------------------------------------
     §30 National Savings — financial data explorer
     --------------------------------------------------------- */
  T.register('natsavings', function (c) {
    var list = D.NAT_SAVINGS[c.profile.country];
    if (!list) return UI.section({ body: UI.emptyState({
      icon: 'i-shield', title: c.t('savings.unavailable.title'), text: c.t('savings.unavailable.text') }) });
    var ccy = c.L.country().currency;
    var best = list.slice().sort(function (a, b) { return b.rate - a.rate; })[0];

    var query = (c.state('q') || '').trim().toLowerCase();
    var products = list.filter(function (p) {
      return !query || (p.name + ' ' + p.eligible).toLowerCase().indexOf(query) !== -1;
    });

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country) },
        { label: c.t('savings.scheme') }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('savings.bestRate'),
        value: c.num(best.rate, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '<small>%</small>',
        caption: best.name,
        stats: [
          { value: best.term, label: c.t('savings.term') },
          { value: best.payout, label: c.t('savings.payout') },
          { value: c.moneyRaw(best.min, ccy, 0), label: c.t('savings.minimum') }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('savings.search'), target: 'natsavings', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.sortBar({ tool: 'natsavings', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'rate', label: c.t('savings.rate') },
          { value: 'term', label: c.t('savings.term') },
          { value: 'min', label: c.t('savings.minimum') }
        ], 'rate', 'desc') }) }) +
      UI.section({ title: c.t('savings.products'), body: UI.rows(c.sortBy(products, {
        rate: function (p) { return p.rate; },
        term: function (p) { return parseInt(p.term, 10); },
        min: function (p) { return p.min; }
      }, 'rate', 'desc').map(function (p) {
        return UI.richRow({
          icon: 'i-shield', iconTone: 'accent',
          title: p.name,
          sub: p.eligible,
          meta: [p.term, p.payout, c.t('savings.min') + ' ' + c.moneyRaw(p.min, ccy, 0)],
          value: c.num(p.rate, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '%',
          valueSub: c.t('savings.perYear'),
          act: 'toast:' + p.name + ' · ' + c.num(p.rate, { maximumFractionDigits: 2 }) + '%'
        });
      })) }) +
      UI.section({ title: c.t('savings.estimate'), body: UI.card(
        UI.formGrid([
          UI.field({ label: c.t('savings.amount'), name: 'ns_amount', type: 'number', value: 1000000, prefix: ccy }),
          UI.selectField({ label: c.t('savings.product'), name: 'ns_product', value: best.name,
            options: list.map(function (p) { return { value: p.name, label: p.name }; }) })
        ]) +
        UI.metrics([
          { value: c.moneyRaw(1000000 * best.rate / 100 / 12, ccy, 0), label: c.t('savings.monthlyProfit') },
          { value: c.moneyRaw(1000000 * best.rate / 100, ccy, 0), label: c.t('savings.yearlyProfit') }
        ], 2)) });
  });

  /* ---------------------------------------------------------
     §31 Prize Bonds — search + results
     --------------------------------------------------------- */
  T.register('prizebonds', function (c) {
    var list = D.PRIZE_BONDS[c.profile.country];
    if (!list) return UI.section({ body: UI.emptyState({
      icon: 'i-ticket', title: c.t('bonds.unavailable.title'), text: c.t('bonds.unavailable.text') }) });
    var ccy = c.L.country().currency;

    var next = list.slice().sort(function (a, b) { return a.denom - b.denom; })[0];
    var pool = list.reduce(function (a, b) { return a + b.first + b.second * 3 + b.third * b.winners; }, 0);
    var saved = c.state('saved') || [];

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.t('bonds.scheme') }
      ]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('bonds.nextDraw'),
        value: next.date,
        caption: c.t('bonds.nextDrawSub', { denom: c.moneyRaw(next.denom, ccy, 0), draw: next.draw }),
        stats: [
          { value: c.moneyRaw(pool, ccy, 0), label: c.t('bonds.prizePool') },
          { value: c.num(list.reduce(function (a, b) { return a + b.winners; }, 0)), label: c.t('bonds.totalWinners') },
          { value: String(list.length), label: c.t('bonds.denominations') }
        ]
      }) }) +
      UI.section({ body: UI.card(
        '<p class="kard__lead">' + UI.esc(c.t('bonds.checkLead')) + '</p>' +
        UI.formGrid([
          UI.selectField({ label: c.t('bonds.denomination'), name: 'pb_denom', value: '750',
            options: list.map(function (b) { return { value: String(b.denom), label: c.moneyRaw(b.denom, ccy, 0) }; }) }),
          UI.field({ label: c.t('bonds.number'), name: 'pb_num', placeholder: '000000', inputmode: 'numeric' })
        ]) +
        UI.buttonRow([{ label: c.t('bonds.check'), tone: 'accent', icon: 'i-search', block: true,
          act: 'toast:' + c.t('bonds.noWin') }])) }) +
      UI.section({ title: c.t('bonds.draws'), body: UI.rows(list.map(function (b) {
        return UI.richRow({
          logo: String(b.denom), logoTone: 'var(--tint-accent)',
          title: c.moneyRaw(b.denom, ccy, 0) + ' ' + c.t('bonds.bond'),
          sub: b.draw,
          meta: [b.date, c.t('bonds.winners', { n: c.num(b.winners) })],
          value: c.moneyRaw(b.first, ccy, 0),
          valueSub: c.t('bonds.firstPrize'),
          act: 'toast:' + b.draw + ' · ' + b.date, chevron: true
        });
      })) }) +
      UI.section({ title: c.t('bonds.prizeTiers'), body: UI.table({
        label: c.t('bonds.prizeTiers'),
        cols: [{ label: c.t('bonds.bond') }, { label: c.t('bonds.first'), align: 'right' },
               { label: c.t('bonds.second'), align: 'right' }, { label: c.t('bonds.third'), align: 'right' }],
        rows: list.map(function (b) {
          return { cells: [c.moneyRaw(b.denom, ccy, 0), c.moneyRaw(b.first, ccy, 0),
                           c.moneyRaw(b.second, ccy, 0), c.moneyRaw(b.third, ccy, 0)] };
        })
      }) }) +
      UI.section({ title: c.t('bonds.prizeShape'), body: UI.card(
        UI.barChart({
          values: list.map(function (b) { return b.first; }),
          labels: list.map(function (b) { return c.moneyRaw(b.denom, ccy, 0); }),
          label: c.t('bonds.prizeShape'), caption: c.t('bonds.prizeShapeCap') })) }) +
      UI.section({ title: c.t('bonds.yourNumbers'), body: saved.length
        ? UI.rows(saved.map(function (n) {
            return UI.compactRow({ icon: 'i-ticket', label: n, value: c.t('bonds.notDrawn') });
          }))
        : UI.emptyState({ icon: 'i-ticket', title: c.t('bonds.noneSaved'),
            text: c.t('bonds.noneSavedText') }) });
  });

  /* ---------------------------------------------------------
     §32 Bills — financial dashboard
     --------------------------------------------------------- */
  T.register('bills', function (c) {
    var b = c.bills();
    var state = c.filter('state', 'all');
    var shownBills = b.list.filter(function (x) {
      return state === 'all' || x.state === state || (state === 'due' && x.state === 'upcoming');
    });
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('bills.dueThisMonth'),
        value: c.money(b.totalDue),
        caption: b.overdueCount
          ? c.t('bills.overdueCount', { n: b.overdueCount })
          : c.t('bills.allOnTrack'),
        aside: UI.progressRing({ value: b.paidRatio, centre: b.paidCount + '/' + b.list.length, label: c.t('bills.paid') }),
        stats: [
          { value: c.money(b.overdue), label: c.t('bills.overdue') },
          { value: c.money(b.upcoming), label: c.t('bills.upcoming') },
          { value: c.money(b.paid), label: c.t('bills.paidAmount') }
        ]
      }) }) +
      (b.overdueCount ? UI.section({ body: UI.noteCard({ tone: 'warn', icon: 'i-alert',
        title: c.t('bills.overdue.title', { n: b.overdueCount }),
        text: c.t('bills.overdue.text') }) }) : '') +
      UI.section({ body: UI.filterBar([{ id: 'state', label: c.t('common.status'), items: [
        { value: 'all', label: c.t('common.all'), on: state === 'all', count: b.list.length },
        { value: 'overdue', label: c.t('bills.overdue'), on: state === 'overdue', count: b.overdueCount },
        { value: 'due', label: c.t('bills.due'), on: state === 'due', count: b.dueCount },
        { value: 'paid', label: c.t('bills.paidState'), on: state === 'paid', count: b.paidCount }
      ] }], 'bills') }) +
      UI.section({ title: c.t('bills.all'), body: shownBills.length ? UI.rows(shownBills.map(function (x) {
        return UI.richRow({
          icon: x.icon, iconTone: x.state === 'overdue' ? 'warn' : null,
          title: x.name, sub: x.provider,
          meta: [c.t('bills.ref') + ' ' + x.ref, x.dueLabel],
          badge: x.badge,
          value: c.money(x.amount),
          act: x.state === 'paid' ? 'toast:' + x.name + ' — ' + c.t('bills.paidState')
                                  : 'toast:' + c.t('bills.opening', { name: x.provider })
        });
      })) : UI.emptyState({ icon: 'i-receipt', title: c.t('bills.noMatch'), text: c.t('bills.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:bills:state:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('bills.trend'), body: UI.card(
        UI.barChart({ values: b.trend, labels: b.trendLabels, highlight: b.trend.length - 1,
          label: c.t('bills.trend'), caption: c.t('bills.trendCap') })) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(b.history.map(function (h) {
        return UI.compactRow({ icon: 'i-check-circle', label: h.name, sub: h.when, value: c.money(h.amount) });
      })) });
  });

  /* ---------------------------------------------------------
     §33 Mobile packages — comparison explorer
     --------------------------------------------------------- */
  T.register('packages', function (c) {
    var list = D.MOBILE_PACKAGES[c.profile.country];
    if (!list) return UI.section({ body: UI.emptyState({
      icon: 'i-signal', title: c.t('packages.unavailable.title'), text: c.t('packages.unavailable.text') }) });
    var ccy = c.L.country().currency;

    var op = c.filter('op', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = list.filter(function (p) {
      if (op !== 'all' && p.op !== op) return false;
      if (query && (p.op + ' ' + p.name).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    shown = c.sortBy(shown, {
      price: function (p) { return p.price; },
      data: function (p) { return parseFloat(p.data); },
      valid: function (p) { return parseInt(p.valid, 10); }
    }, 'price', 'asc');

    return UI.section({ body: UI.searchBar({ placeholder: c.t('packages.search'), target: 'packages', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([
        { id: 'op', label: c.t('packages.operator'), items: [{ value: 'all', label: c.t('common.all'), on: op === 'all' }]
          .concat(list.map(function (p) { return { value: p.op, label: p.op, on: op === p.op }; })) }
      ], 'packages') }) +
      UI.section({ body: UI.sortBar({ tool: 'packages', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'price', label: c.t('packages.price') },
          { value: 'data', label: c.t('packages.data') },
          { value: 'valid', label: c.t('packages.validity') }
        ], 'price', 'asc') }) }) +
      (shown.length ? UI.section({ title: c.t('packages.compare'), body: UI.table({
        label: c.t('packages.compare'),
        cols: [{ label: c.t('packages.package') }, { label: c.t('packages.data'), align: 'right' },
               { label: c.t('packages.mins'), align: 'right' }, { label: c.t('packages.price'), align: 'right' }],
        rows: shown.map(function (p) {
          return { act: 'toast:' + p.op + ' ' + p.name,
            cells: ['<b>' + UI.esc(p.op) + '</b><i class="cellsub">' + UI.esc(p.name) + '</i>',
                    UI.esc(p.data), UI.esc(p.mins), c.moneyRaw(p.price, ccy, 0)] };
        })
      }) }) : UI.section({ body: UI.emptyState({ icon: 'i-signal',
        title: c.t('packages.noMatch'), text: c.t('packages.noMatchText') }) })) +
      UI.section({ title: c.t('packages.detail'), body: UI.rows(shown.map(function (p) {
        return UI.expandRow({
          head: '<span class="xrow__title">' + UI.esc(p.op) + ' · ' + UI.esc(p.name) + '</span>' +
                '<span class="xrow__value">' + c.moneyRaw(p.price, ccy, 0) + '</span>',
          body: UI.rows([
            UI.compactRow({ label: c.t('packages.data'), value: p.data }),
            UI.compactRow({ label: c.t('packages.mins'), value: p.mins }),
            UI.compactRow({ label: c.t('packages.sms'), value: p.sms }),
            UI.compactRow({ label: c.t('packages.validity'), value: p.valid })
          ], { flat: true })
        });
      })) });
  });

  /* ---------------------------------------------------------
     §34 Loan / EMI — calculator + amortisation
     --------------------------------------------------------- */
  T.register('loan', function (c) {
    var l = c.loan();
    return UI.section({ id: 'inputs', title: c.t('tool.inputs'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('loan.principal'), name: 'ln_principal', type: 'number', value: l.f.principal, prefix: l.ccy, wide: true }),
        UI.field({ label: c.t('loan.rate'), name: 'ln_rate', type: 'number', value: l.f.rate, suffix: '%', step: '0.1' }),
        UI.field({ label: c.t('loan.tenure'), name: 'ln_years', type: 'number', value: l.f.years, suffix: c.t('common.years') })
      ])) }) +
      UI.section({ id: 'result', body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('loan.monthly'),
        value: '<span data-ln-emi>' + c.moneyRaw(l.emi, l.ccy, 0) + '</span>',
        caption: c.t('loan.over', { n: l.f.years * 12 }),
        stats: [
          { value: '<span data-ln-interest>' + c.moneyRaw(l.totalInterest, l.ccy, 0) + '</span>', label: c.t('loan.totalInterest') },
          { value: '<span data-ln-total>' + c.moneyRaw(l.totalPaid, l.ccy, 0) + '</span>', label: c.t('loan.totalPaid') },
          { value: c.num(l.interestShare * 100, { maximumFractionDigits: 0 }) + '%', label: c.t('loan.interestShare') }
        ]
      }) }) +
      UI.section({ body: UI.card(UI.donut({
        label: c.t('loan.split'),
        centre: c.moneyRaw(l.totalPaid, l.ccy, 0), centreSub: c.t('loan.totalPaid'),
        slices: [
          { label: c.t('loan.principalShort'), value: l.f.principal, color: 'var(--accent)' },
          { label: c.t('loan.interest'), value: l.totalInterest, color: 'var(--violet)' }
        ]
      })) }) +
      UI.section({ title: c.t('loan.amortisation'), body: UI.table({
        label: c.t('loan.amortisation'),
        cols: [{ label: c.t('common.year') }, { label: c.t('loan.principalShort'), align: 'right' },
               { label: c.t('loan.interest'), align: 'right' }, { label: c.t('loan.balance'), align: 'right' }],
        rows: l.schedule.map(function (r) {
          return { cells: [String(r.year), c.moneyRaw(r.principal, l.ccy, 0),
                           c.moneyRaw(r.interest, l.ccy, 0), c.moneyRaw(r.balance, l.ccy, 0)] };
        })
      }) }) +
      UI.section({ title: c.t('loan.compare'), body: UI.rows(l.compare.map(function (x) {
        return UI.compactRow({ icon: 'i-bank', label: x.label, sub: x.sub, value: c.moneyRaw(x.emi, l.ccy, 0) });
      })) });
  });

  /* ---------------------------------------------------------
     §35 Tip & split — focused calculator, kept fast
     --------------------------------------------------------- */
  T.register('tipsplit', function (c) {
    var s = c.tipSplit();
    return UI.section({ body: UI.card(UI.formGrid([
        UI.field({ label: c.t('tip.bill'), name: 'tp_bill', type: 'number', value: s.f.bill, prefix: s.ccy, wide: true })
      ]) +
      '<p class="fieldlabel">' + UI.esc(c.t('tip.tip')) + '</p>' +
      '<div class="chips chips--tight">' + [0, 5, 10, 15, 20].map(function (p) {
        return '<button class="chip' + (p === s.f.tip ? ' is-on' : '') + '" data-act="toolstate:tipsplit:tip:' + p + '">' + p + '%</button>';
      }).join('') + '</div>' +
      '<div class="splitrow"><span class="fieldlabel">' + UI.esc(c.t('tip.people')) + '</span>' +
        UI.stepper({ name: 'tp_people', value: s.f.people, label: c.t('tip.people') }) + '</div>') }) +
      UI.section({ body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('tip.perPerson'),
        value: '<span data-tp-each>' + c.moneyRaw(s.each, s.ccy, 2) + '</span>',
        stats: [
          { value: c.moneyRaw(s.tipAmount, s.ccy, 2), label: c.t('tip.tipAmount') },
          { value: c.moneyRaw(s.total, s.ccy, 2), label: c.t('tip.total') },
          { value: String(s.f.people), label: c.t('tip.people') }
        ]
      }) }) +
      UI.section({ title: c.t('tip.custom'), body: UI.rows(s.custom.map(function (x) {
        return UI.compactRow({ icon: 'i-user', label: x.name, value: c.moneyRaw(x.amount, s.ccy, 2) });
      })) });
  });

  /* ---------------------------------------------------------
     §36 Lending ledger — personal financial manager
     --------------------------------------------------------- */
  T.register('ledger', function (c) {
    var g = c.ledger();
    var dir = c.filter('dir', 'all');
    var people = g.people.filter(function (p) {
      if (dir === 'lent') return p.amount > 0;
      if (dir === 'borrowed') return p.amount < 0;
      if (dir === 'overdue') return !!p.overdue;
      return true;
    });
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('ledger.net'),
        value: c.money(g.net),
        caption: g.net >= 0 ? c.t('ledger.owedToYou') : c.t('ledger.youOwe'),
        stats: [
          { value: c.money(g.lent), label: c.t('ledger.lent') },
          { value: c.money(g.borrowed), label: c.t('ledger.borrowed') },
          { value: String(g.people.length), label: c.t('ledger.people') }
        ]
      }) }) +
      UI.section({ body: UI.filterBar([{ id: 'dir', label: c.t('ledger.direction'), items: [
        { value: 'all', label: c.t('common.all'), on: dir === 'all' },
        { value: 'lent', label: c.t('ledger.lent'), on: dir === 'lent' },
        { value: 'borrowed', label: c.t('ledger.borrowed'), on: dir === 'borrowed' },
        { value: 'overdue', label: c.t('common.overdue'), on: dir === 'overdue' }
      ] }], 'ledger') }) +
      UI.section({ title: c.t('ledger.people'), body: people.length ? UI.rows(people.map(function (p) {
        return UI.richRow({
          logo: p.initials, logoTone: 'var(--tone-' + p.tone + ')',
          title: p.name, sub: p.note,
          meta: [p.since, p.due ? c.t('ledger.due', { date: p.due }) : ''],
          badge: p.overdue ? { label: c.t('common.overdue'), tone: 'warn' } : null,
          value: c.money(Math.abs(p.amount)),
          valueSub: p.amount >= 0 ? c.t('ledger.owesYou') : c.t('ledger.youOweShort'),
          act: 'toast:' + p.name, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-users', title: c.t('ledger.noMatch'), text: c.t('ledger.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:ledger:dir:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('common.recent'), body: UI.rows(g.entries.map(function (e) {
        return UI.compactRow({ icon: e.amount >= 0 ? 'i-arrow-r' : 'i-arrow-r', label: e.who, sub: e.when,
          value: (e.amount >= 0 ? '+' : '−') + c.money(Math.abs(e.amount)) });
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('ledger.add'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('ledger.adding') },
        { label: c.t('ledger.remind'), icon: 'i-bell', act: 'toast:' + c.t('ledger.reminded') }]) });
  });

  /* ---------------------------------------------------------
     §37 Installments — financial manager
     --------------------------------------------------------- */
  T.register('installments', function (c) {
    var i = c.installments();
    var state = c.filter('state', 'active');
    var plans = c.sortBy(i.plans.filter(function (p) {
      var done = p.paidCount >= p.total;
      return state === 'all' || (state === 'active' ? !done : done);
    }), {
      next: function (p) { return p.total - p.paidCount; },
      amount: function (p) { return p.monthly; },
      progress: function (p) { return p.paidCount / p.total; }
    }, 'next', 'asc');

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('inst.monthlyTotal'),
        value: c.money(i.monthly),
        caption: c.t('inst.activePlans', { n: i.plans.length }),
        stats: [
          { value: c.money(i.remaining), label: c.t('inst.remaining') },
          { value: c.money(i.paid), label: c.t('inst.paid') },
          { value: i.nextDate, label: c.t('inst.nextPayment') }
        ]
      }) }) +
      UI.section({ body: UI.filterBar([{ id: 'state', label: c.t('common.status'), items: [
        { value: 'active', label: c.t('inst.stActive'), on: state === 'active',
          count: i.plans.filter(function (p) { return p.paidCount < p.total; }).length },
        { value: 'done', label: c.t('inst.stDone'), on: state === 'done',
          count: i.plans.filter(function (p) { return p.paidCount >= p.total; }).length },
        { value: 'all', label: c.t('common.all'), on: state === 'all', count: i.plans.length }
      ] }], 'installments') }) +
      UI.section({ body: UI.sortBar({ tool: 'installments', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'next', label: c.t('inst.remainingShort') },
          { value: 'amount', label: c.t('common.amount') },
          { value: 'progress', label: c.t('inst.progress') }
        ], 'next', 'asc') }) }) +
      UI.section({ title: c.t('inst.plans'), body: plans.length ? UI.rows(plans.map(function (p) {
        return UI.richRow({
          logo: p.logo, logoTone: 'var(--tone-' + p.tone + ')',
          title: p.item, sub: p.merchant,
          meta: [c.t('inst.instalment', { a: p.paidCount, b: p.total }), c.t('inst.next') + ' ' + p.next],
          value: c.money(p.monthly),
          valueSub: c.t('common.perMonth')
        }) + '<div class="rowmeter">' + UI.progressBar({ value: p.paidCount / p.total, label: p.item }) + '</div>';
      })) : UI.emptyState({ icon: 'i-calendar', title: c.t('inst.noneHere'),
        text: c.t('inst.noneHereText'),
        action: { label: c.t('common.all'), act: 'toolstate:installments:state:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('inst.schedule'), body: UI.timeline(i.schedule.map(function (s) {
        return { time: s.date, title: s.item, sub: s.merchant, value: c.money(s.amount), state: s.state };
      })) }) +
      UI.section({ title: c.t('inst.payoff'), body: UI.card(
        UI.barChart({
          values: i.months, labels: i.monthLabels, highlight: 0,
          label: c.t('inst.payoff'), caption: c.t('inst.payoffCap', { amount: c.money(i.monthly) }) })) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(i.history.map(function (h) {
        return UI.compactRow({ icon: 'i-check-circle', label: h.item, sub: h.when, value: c.money(h.amount) });
      })) });
  });

  /* ---------------------------------------------------------
     §38 Committee — group finance manager
     --------------------------------------------------------- */
  T.register('committee', function (c) {
    var k = c.committee();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('committee.pool'),
        value: c.money(k.pool),
        caption: c.t('committee.cycle', { a: k.month, b: k.months }),
        aside: UI.progressRing({ value: k.month / k.months, centre: k.month + '/' + k.months, label: c.t('committee.cycleShort') }),
        stats: [
          { value: c.money(k.contribution), label: c.t('committee.contribution') },
          { value: String(k.members.length), label: c.t('committee.members') },
          { value: c.t('committee.monthN', { n: k.yourTurn }), label: c.t('committee.yourTurn') }
        ]
      }) }) +
      UI.section({ title: c.t('committee.thisMonth'), body: UI.rows(k.members.map(function (m) {
        return UI.richRow({
          logo: m.initials, logoTone: 'var(--tone-' + m.tone + ')',
          title: m.name, sub: m.paid ? c.t('committee.paidOn', { date: m.when }) : c.t('committee.pending'),
          meta: [c.t('committee.turnMonth', { n: m.turn })],
          badge: m.paid ? { label: c.t('common.paid'), tone: 'ok' } : { label: c.t('common.pending'), tone: 'warn' },
          value: c.money(k.contribution)
        });
      })) }) +
      UI.section({ title: c.t('committee.payoutOrder'), body: UI.timeline(k.order.map(function (o) {
        return { time: o.month, title: o.name, sub: o.you ? c.t('committee.you') : '', value: c.money(k.pool), state: o.state };
      })) }) +
      UI.section({ title: c.t('committee.collection'), body: UI.card(
        UI.barChart({ values: k.collected, labels: k.collectedLabels, highlight: k.month - 1,
          label: c.t('committee.collection'), caption: c.t('committee.collectionCap') })) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(k.history.map(function (h) {
        return UI.compactRow({ icon: 'i-users', label: h.name, sub: h.when, value: c.money(h.amount) });
      })) });
  });

  /* ---------------------------------------------------------
     §80 Compound interest — a premium addition with real maths
     --------------------------------------------------------- */
  T.register('compound', function (c) {
    var k = c.compound();
    return UI.section({ id: 'inputs', title: c.t('tool.inputs'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('compound.initial'), name: 'ci_initial', type: 'number', value: k.f.initial, prefix: k.ccy }),
        UI.field({ label: c.t('compound.monthly'), name: 'ci_monthly', type: 'number', value: k.f.monthly, prefix: k.ccy }),
        UI.field({ label: c.t('compound.rate'), name: 'ci_rate', type: 'number', value: k.f.rate, suffix: '%', step: '0.1' }),
        UI.field({ label: c.t('compound.years'), name: 'ci_years', type: 'number', value: k.f.years, suffix: c.t('common.years') })
      ])) }) +
      UI.section({ body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('compound.finalValue'),
        value: '<span data-ci-total>' + c.moneyRaw(k.total, k.ccy, 0) + '</span>',
        caption: c.t('compound.after', { n: k.f.years }),
        stats: [
          { value: c.moneyRaw(k.contributed, k.ccy, 0), label: c.t('compound.contributed') },
          { value: c.moneyRaw(k.growth, k.ccy, 0), label: c.t('compound.growth') },
          { value: c.num(k.growth / Math.max(1, k.contributed) * 100, { maximumFractionDigits: 0 }) + '%', label: c.t('compound.return') }
        ]
      }) }) +
      UI.section({ title: c.t('compound.projection'), body: UI.card(
        UI.lineChart({ values: k.series, labels: ['0', Math.round(k.f.years / 2) + 'y', k.f.years + 'y'],
          label: c.t('compound.projection') })) }) +
      UI.section({ title: c.t('compound.byYear'), body: UI.table({
        label: c.t('compound.byYear'),
        cols: [{ label: c.t('common.year') }, { label: c.t('compound.contributed'), align: 'right' },
               { label: c.t('compound.value'), align: 'right' }],
        rows: k.table.map(function (r) {
          return { cells: [String(r.year), c.moneyRaw(r.contributed, k.ccy, 0), c.moneyRaw(r.value, k.ccy, 0)] };
        })
      }) });
  });
})();
