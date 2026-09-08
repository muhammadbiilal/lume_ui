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
     §26 Markets — financial data explorer, very high density
     --------------------------------------------------------- */
  T.register('markets', function (c) {
    var ex = c.exchange();
    var session = c.marketSession(ex);
    var tab = c.state('tab') || 'overview';

    var header = UI.section({ flush: true, body: UI.contextBar([
      { icon: 'i-globe', label: ex ? ex.code : c.t('markets.global'), act: 'toolstate:markets:exchange' },
      { label: ex ? ex.name : c.t('markets.worldBoard') },
      { label: c.L.currencyCode() }
    ]) });

    /* Market status strip — session, breadth and turnover, which is what
       a trader reads before any individual row. */
    var status = UI.section({ body: UI.card(
      '<div class="mstat">' +
        '<div class="mstat__lead">' +
          UI.freshness({ quality: session.open ? 'live' : 'cached', label: session.label }) +
          '<p class="mstat__hours">' + UI.esc(session.hours) + '</p>' +
        '</div>' +
        '<div class="mstat__breadth">' +
          '<span class="mstat__bar"><i style="width:' + session.advPct + '%"></i></span>' +
          '<span class="mstat__legend">' +
            '<b class="is-up">' + session.adv + ' ' + UI.esc(c.t('markets.advancing')) + '</b>' +
            '<b class="is-down">' + session.dec + ' ' + UI.esc(c.t('markets.declining')) + '</b>' +
          '</span>' +
        '</div>' +
      '</div>' +
      UI.metrics([
        { value: session.turnover, label: c.t('markets.turnover') },
        { value: session.volume, label: c.t('markets.volume') },
        { value: session.trades, label: c.t('markets.trades') }
      ], 3)) });

    /* §26 index rows: logo, index, market, value, absolute change,
       percentage change and a sparkline — all of it, because it exists. */
    var indices = ex ? ex.indices : D.GLOBAL_INDICES;
    var indexRows = UI.section({ title: c.t('markets.indices'),
      body: UI.rows(indices.map(function (ix, i) {
        var series = D.walk(ix.value + i, 24, ix.value, 0.006);
        return UI.richRow({
          logo: ix.sym.slice(0, 3), logoTone: 'var(--tint-accent)',
          title: ix.name,
          sub: ix.full,
          meta: [ex ? ex.name : c.t('markets.worldBoard')],
          spark: UI.sparkline(series, { tone: dirOf(ix.pct) }),
          value: c.num(ix.value, { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
          delta: { dir: dirOf(ix.pct), text: c.signed(ix.chg) + '  ' + c.pct(ix.pct) },
          act: 'toast:' + ix.name + ' ' + c.pct(ix.pct), chevron: false
        });
      })) });

    var TABS = [
      { value: 'overview', label: c.t('markets.tab.overview') },
      { value: 'movers', label: c.t('markets.tab.movers') },
      { value: 'watchlist', label: c.t('markets.tab.watchlist'), count: 4 },
      { value: 'stocks', label: c.t('markets.tab.stocks') },
      { value: 'etfs', label: c.t('markets.tab.etfs') },
      { value: 'crypto', label: c.t('markets.tab.crypto') },
      { value: 'global', label: c.t('markets.tab.global') }
    ].map(function (x) { x.on = x.value === tab; x.act = 'toolstate:markets:tab:' + x.value; return x; });

    /* One rich row shape, filled from whatever the dataset carries. */
    function securityRow(s, i, ccy) {
      var series = D.walk(Math.round(s.price * 100) + i, 20, s.price, 0.02);
      return UI.richRow({
        logo: s.logo, logoTone: 'var(--tone-' + (s.tone || 'slate') + ')',
        title: s.sym,
        sub: s.name,
        meta: [ex ? ex.code : c.t('markets.global'), s.sectorKey ? c.t(s.sectorKey) : '', s.vol ? c.t('markets.vol') + ' ' + s.vol : '',
               s.cap ? c.t('markets.cap') + ' ' + s.cap : ''],
        spark: UI.sparkline(series, { tone: dirOf(s.pct) }),
        value: c.moneyRaw(s.price, ccy, s.price < 10 ? 2 : 2),
        valueSub: ccy,
        delta: { dir: dirOf(s.pct), text: c.signed(s.chg) + '  ' + c.pct(s.pct) },
        act: 'toast:' + s.name + ' · ' + c.moneyRaw(s.price, ccy, 2) + ' ' + c.pct(s.pct)
      });
    }

    var stocks = ex ? ex.stocks : D.ETFS;
    var ccy = ex ? ex.ccy : 'USD';
    var listBody, listTitle;

    /* Search, then sort — both read from the tool's own state, so the
       controls above the list are the ones driving it (§87, §89). */
    var query = (c.state('q') || '').trim().toLowerCase();
    function searched(list) {
      if (!query) return list;
      return list.filter(function (x) {
        return (x.sym + ' ' + x.name + ' ' + (x.sector || '')).toLowerCase().indexOf(query) !== -1;
      });
    }
    var SORTS = {
      pct: function (x) { return x.pct; },
      price: function (x) { return x.price; },
      vol: function (x) { return parseFloat(x.vol) * (/B/.test(x.vol || '') ? 1000 : 1); },
      cap: function (x) { return parseFloat(x.cap) * (/T/.test(x.cap || '') ? 1e6 : /B/.test(x.cap || '') ? 1000 : 1); }
    };
    function ordered(list) { return c.sortBy(searched(list), SORTS, 'pct', 'desc'); }

    if (tab === 'movers') {
      var sorted = searched(stocks).slice().sort(function (a, b) { return b.pct - a.pct; });
      listTitle = c.t('markets.tab.movers');
      listBody = UI.sectionHead({ title: c.t('markets.gainers') }) +
        UI.rows(sorted.slice(0, 3).map(function (s, i) { return securityRow(s, i, ccy); })) +
        UI.sectionHead({ title: c.t('markets.losers') }) +
        UI.rows(sorted.slice(-3).reverse().map(function (s, i) { return securityRow(s, i + 90, ccy); }));
    } else if (tab === 'crypto') {
      listTitle = c.t('markets.tab.crypto');
      listBody = UI.rows(ordered(D.CRYPTO).map(function (s, i) { return securityRow(s, i, 'USD'); }));
    } else if (tab === 'etfs') {
      listTitle = c.t('markets.tab.etfs');
      listBody = UI.rows(ordered(D.ETFS).map(function (s, i) { return securityRow(s, i, 'USD'); }));
    } else if (tab === 'global') {
      listTitle = c.t('markets.tab.global');
      listBody = UI.rows(D.GLOBAL_INDICES.map(function (ix, i) {
        return UI.richRow({
          logo: ix.sym.slice(0, 3), logoTone: 'var(--tint-neutral)',
          title: ix.name, sub: ix.full,
          spark: UI.sparkline(D.walk(ix.value + i, 20, ix.value, 0.005), { tone: dirOf(ix.pct) }),
          value: c.num(ix.value, { maximumFractionDigits: 2 }),
          delta: { dir: dirOf(ix.pct), text: c.pct(ix.pct) }
        });
      }));
    } else if (tab === 'watchlist') {
      listTitle = c.t('markets.tab.watchlist');
      var watch = ordered(stocks.slice(0, 4));
      listBody = watch.length
        ? UI.rows(watch.map(function (s, i) { return securityRow(s, i, ccy); }))
        : UI.emptyState({ icon: 'i-star', title: c.t('markets.watch.empty'), text: c.t('markets.watch.emptyText'),
            action: { label: c.t('markets.watch.add'), act: 'toolstate:markets:tab:stocks' } });
    } else {
      listTitle = c.t('markets.mostActive');
      var rows = ordered(stocks);
      listBody = rows.length
        ? UI.rows(rows.map(function (s, i) { return securityRow(s, i, ccy); }))
        : UI.emptyState({ icon: 'i-search', title: c.t('markets.noMatch', { q: query }),
            text: c.t('markets.noMatchText') });
    }

    var chartIndex = indices[0];
    var range = c.state('range') || '1d';
    var RANGE_POINTS = { '1d': 40, '1w': 56, '1m': 60, '1y': 72 };
    var RANGE_VOL = { '1d': 0.004, '1w': 0.009, '1m': 0.016, '1y': 0.03 };
    var chart = UI.section({ title: c.t('markets.chart', { name: chartIndex.name }), body: UI.card(
      UI.segmented({ id: 'range', label: c.t('markets.range'), tool: 'markets',
        items: [
          { value: '1d', label: c.t('range.1d') }, { value: '1w', label: c.t('range.1w') },
          { value: '1m', label: c.t('range.1m') }, { value: '1y', label: c.t('range.1y') }
        ].map(function (r) { r.on = r.value === range; return r; }) }) +
      UI.lineChart({
        values: D.walk(chartIndex.value, RANGE_POINTS[range], chartIndex.value, RANGE_VOL[range]),
        labels: range === '1d'
          ? [session.openLabel, c.time(12, 0), session.closeLabel]
          : [c.t('range.' + range), '', c.t('common.now')],
        tone: dirOf(chartIndex.pct),
        label: chartIndex.name,
        caption: '<b>' + c.num(chartIndex.value, { maximumFractionDigits: 2 }) + '</b> ' +
          UI.delta({ dir: dirOf(chartIndex.pct), text: c.signed(chartIndex.chg) + ' ' + c.pct(chartIndex.pct) })
      })) });

    return header + status + indexRows +
      UI.section({ body: UI.searchBar({ placeholder: c.t('markets.search'), target: 'markets', value: c.state('q') || '' }) }) +
      UI.section({ flush: true, body: UI.tabs({ id: 'markets', items: TABS }) }) +
      UI.section({ body: UI.sortBar({ label: c.t('common.sort'), tool: 'markets',
        items: c.sortItems([
          { value: 'pct', label: c.t('markets.sort.change') },
          { value: 'price', label: c.t('markets.sort.price') },
          { value: 'vol', label: c.t('markets.sort.volume') },
          { value: 'cap', label: c.t('markets.sort.cap') }
        ], 'pct', 'desc') }) }) +
      UI.section({ title: listTitle, body: listBody }) +
      chart;
  });

  /* ---------------------------------------------------------
     §25.1 Currency & Gold — data explorer
     --------------------------------------------------------- */
  T.register('goldrates', function (c) {
    var g = c.metals();
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
      UI.section({ title: c.t('rates.currencies'), body: UI.rows(g.pairs.map(function (p) {
        return UI.richRow({
          logo: p.flag, logoTone: 'var(--tint-neutral)',
          title: p.code, sub: p.name,
          meta: [c.t('rates.buy') + ' ' + c.num(p.buy, { maximumFractionDigits: 2 }),
                 c.t('rates.sell') + ' ' + c.num(p.sell, { maximumFractionDigits: 2 })],
          spark: UI.sparkline(D.walk(Math.round(p.sell * 10), 18, p.sell, 0.008), { tone: dirOf(p.pct) }),
          value: c.num(p.sell, { maximumFractionDigits: 2 }),
          delta: { dir: dirOf(p.pct), text: c.pct(p.pct) }
        });
      })) }) +
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
      UI.section({ body: UI.searchBar({ placeholder: c.t('convert.search'), target: 'currency' }) }) +
      UI.section({ title: c.t('convert.popular'), body: UI.rows(cv.popular.map(function (p) {
        return UI.richRow({
          logo: p.flag, logoTone: 'var(--tint-neutral)',
          title: p.code, sub: p.name,
          spark: UI.sparkline(D.walk(p.code.charCodeAt(0) * 7, 16, p.rate, 0.006), { tone: dirOf(p.pct) }),
          value: c.num(p.rate, { maximumFractionDigits: 3 }),
          delta: { dir: dirOf(p.pct), text: c.pct(p.pct) },
          act: 'toast:1 ' + cv.from + ' = ' + c.num(p.rate, { maximumFractionDigits: 3 }) + ' ' + p.code
        });
      })) }) +
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
    if (!tx.config) {
      return UI.section({ body: UI.emptyState({
        icon: 'i-percent',
        title: c.t('tax.unsupported.title', { country: c.L.countryName(c.profile.country) }),
        text: c.t('tax.unsupported.text'),
        action: { label: c.t('settings.changeCountry'), act: 'sheet:personalise', icon: 'i-globe' }
      }) });
    }
    if (!tx.taxable) {
      return UI.section({ flush: true, body: UI.contextBar([
          { icon: 'i-globe', label: c.L.countryName(c.profile.country) },
          { label: tx.config.authority }]) }) +
        UI.section({ body: UI.noteCard({ icon: 'i-info', tone: 'ok',
          title: c.t('tax.none.title'), text: c.t('tax.none.text', { authority: tx.config.authority }) }) });
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
      UI.section({ body: UI.sortBar({ tool: 'natsavings', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'rate', label: c.t('savings.rate') },
          { value: 'term', label: c.t('savings.term') },
          { value: 'min', label: c.t('savings.minimum') }
        ], 'rate', 'desc') }) }) +
      UI.section({ title: c.t('savings.products'), body: UI.rows(c.sortBy(list, {
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

    return UI.section({ body: UI.card(
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
      }) });
  });

  /* ---------------------------------------------------------
     §32 Bills — financial dashboard
     --------------------------------------------------------- */
  T.register('bills', function (c) {
    var b = c.bills();
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
        { value: 'all', label: c.t('common.all'), on: true, count: b.list.length },
        { value: 'overdue', label: c.t('bills.overdue'), count: b.overdueCount },
        { value: 'due', label: c.t('bills.due'), count: b.dueCount },
        { value: 'paid', label: c.t('bills.paidState'), count: b.paidCount }
      ] }]) }) +
      UI.section({ title: c.t('bills.all'), body: UI.rows(b.list.map(function (x) {
        return UI.richRow({
          icon: x.icon, iconTone: x.state === 'overdue' ? 'warn' : null,
          title: x.name, sub: x.provider,
          meta: [c.t('bills.ref') + ' ' + x.ref, x.dueLabel],
          badge: x.badge,
          value: c.money(x.amount),
          act: x.state === 'paid' ? 'toast:' + x.name + ' — ' + c.t('bills.paidState')
                                  : 'toast:' + c.t('bills.opening', { name: x.provider })
        });
      })) }) +
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
        { value: 'all', label: c.t('common.all'), on: true },
        { value: 'lent', label: c.t('ledger.lent') },
        { value: 'borrowed', label: c.t('ledger.borrowed') },
        { value: 'overdue', label: c.t('common.overdue') }
      ] }]) }) +
      UI.section({ title: c.t('ledger.people'), body: UI.rows(g.people.map(function (p) {
        return UI.richRow({
          logo: p.initials, logoTone: 'var(--tone-' + p.tone + ')',
          title: p.name, sub: p.note,
          meta: [p.since, p.due ? c.t('ledger.due', { date: p.due }) : ''],
          badge: p.overdue ? { label: c.t('common.overdue'), tone: 'warn' } : null,
          value: c.money(Math.abs(p.amount)),
          valueSub: p.amount >= 0 ? c.t('ledger.owesYou') : c.t('ledger.youOweShort'),
          act: 'toast:' + p.name, chevron: true
        });
      })) }) +
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
      UI.section({ title: c.t('inst.plans'), body: UI.rows(i.plans.map(function (p) {
        return UI.richRow({
          logo: p.logo, logoTone: 'var(--tone-' + p.tone + ')',
          title: p.item, sub: p.merchant,
          meta: [c.t('inst.instalment', { a: p.paidCount, b: p.total }), c.t('inst.next') + ' ' + p.next],
          value: c.money(p.monthly),
          valueSub: c.t('common.perMonth')
        }) + '<div class="rowmeter">' + UI.progressBar({ value: p.paidCount / p.total, label: p.item }) + '</div>';
      })) }) +
      UI.section({ title: c.t('inst.schedule'), body: UI.timeline(i.schedule.map(function (s) {
        return { time: s.date, title: s.item, sub: s.merchant, value: c.money(s.amount), state: s.state };
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
