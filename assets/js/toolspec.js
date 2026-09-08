/* ============================================================
   Lume — tool specifications
   The per-tool half of the Tool Detail Contract: what a tool
   asks for, what it computes or shows, where its data comes
   from, and which tools it genuinely relates to.

   Behaviour lives in toolkit.js. This file is only the contract.
   ============================================================ */
window.LUME_TOOLSPEC = (function () {
  'use strict';

  /* Defaults by shape. A tool only overrides what differs. */
  var SHAPE_DEFAULTS = {
    calculator: { auth: 'guest',   offline: 'full',      fresh: 'computed', canShare: 1, canSave: 1 },
    data:       { auth: 'guest',   offline: 'cached',    fresh: 'live',     canShare: 1 },
    list:       { auth: 'local',   offline: 'full',      fresh: 'local',    canCreate: 1, canDelete: 1 },
    tracker:    { auth: 'local',   offline: 'full',      fresh: 'local' },
    reader:     { auth: 'guest',   offline: 'cached',    fresh: 'static',   canShare: 1 },
    scanner:    { auth: 'guest',   offline: 'full',      fresh: 'computed', perms: ['camera'] },
    timer:      { auth: 'guest',   offline: 'full',      fresh: 'computed' },
    custom:     { auth: 'guest',   offline: 'partial',   fresh: 'live' }
  };

  /* ---- Calculators ------------------------------------------------------
     Each field declares its own validation so no calculator can silently
     turn malformed input into zero. */
  var CALC = {
    calculator: null,                                   /* keypad, handled bespoke */
    converter: {
      intro: 'Convert between the units you actually use.',
      fields: [
        { id: 'v', label: 'Value', type: 'number', unit: 'km', min: 0, max: 1e9, def: 10 },
        { id: 'from', label: 'From', type: 'choice', options: ['km', 'mi', 'kg', 'lb', 'L', 'gal', '°C', '°F'], def: 'km' },
        { id: 'to', label: 'To', type: 'choice', options: ['mi', 'km', 'lb', 'kg', 'gal', 'L', '°F', '°C'], def: 'mi' }
      ],
      compute: function (v) {
        var R = { 'km>mi': 0.621371, 'mi>km': 1.60934, 'kg>lb': 2.20462, 'lb>kg': 0.453592,
                  'L>gal': 0.264172, 'gal>L': 3.78541 };
        var key = v.from + '>' + v.to;
        if (v.from === v.to) return { value: v.v, unit: v.to };
        if (key === '°C>°F') return { value: v.v * 9 / 5 + 32, unit: '°F' };
        if (key === '°F>°C') return { value: (v.v - 32) * 5 / 9, unit: '°C' };
        if (!R[key]) return { error: 'Those two units measure different things.' };
        return { value: v.v * R[key], unit: v.to };
      },
      related: ['calculator', 'currency']
    },
    currency: {
      intro: 'Interbank rate, with the open-market rate alongside it.',
      fields: [
        { id: 'amount', label: 'Amount', type: 'number', min: 0, max: 1e9, def: 100 },
        { id: 'from', label: 'From', type: 'currency', def: 'USD' },
        { id: 'to', label: 'To', type: 'currency', def: null }
      ],
      related: ['goldrates', 'markets'],
      source: 'Interbank reference rate'
    },
    age: {
      intro: 'Exact age, and how long until the next birthday.',
      fields: [{ id: 'dob', label: 'Date of birth', type: 'date', def: '1995-04-12' }],
      related: ['birthdays', 'datecalc']
    },
    datecalc: {
      intro: 'Days between two dates, or a date a number of days away.',
      fields: [
        { id: 'from', label: 'From', type: 'date', def: 'today' },
        { id: 'to', label: 'To', type: 'date', def: '+90' }
      ],
      related: ['calendar', 'age']
    },
    bmi: {
      intro: 'Body mass index, with the range it falls in.',
      fields: [
        { id: 'h', label: 'Height', type: 'number', unit: 'cm', min: 60, max: 260, def: 174 },
        { id: 'w', label: 'Weight', type: 'number', unit: 'kg', min: 20, max: 400, def: 72 }
      ],
      compute: function (v) {
        var bmi = v.w / Math.pow(v.h / 100, 2);
        var band = bmi < 18.5 ? 'Underweight' : bmi < 25 ? 'Healthy range'
                 : bmi < 30 ? 'Overweight' : 'Obese';
        return { value: bmi, unit: '', decimals: 1, note: band, band: band };
      },
      note: 'BMI is a rough screen, not a diagnosis.',
      related: ['health', 'habits']
    },
    tax: {
      intro: 'Salaried income tax using the current FBR slabs.',
      fields: [{ id: 'salary', label: 'Monthly salary', type: 'money', min: 0, max: 1e9, def: 350000 }],
      compute: function (v) {
        var annual = v.salary * 12, tax = 0;
        var slabs = [[600000, 0], [1200000, 0.05], [2200000, 0.15], [3200000, 0.25],
                     [4100000, 0.30], [Infinity, 0.35]];
        var prev = 0;
        for (var i = 0; i < slabs.length; i++) {
          if (annual > prev) tax += (Math.min(annual, slabs[i][0]) - prev) * slabs[i][1];
          prev = slabs[i][0];
          if (annual <= prev) break;
        }
        return {
          value: tax / 12, money: 1, note: 'Take home ' + '{take}',
          extra: [['Annual income', annual, 1], ['Annual tax', tax, 1],
                  ['Effective rate', (annual ? tax / annual * 100 : 0).toFixed(1) + '%', 0]],
          take: v.salary - tax / 12
        };
      },
      note: 'An estimate for salaried individuals. Confirm with FBR or your employer.',
      source: 'FBR slabs, tax year 2025-26',
      related: ['expenses', 'natsavings']
    },
    loan: {
      intro: 'Monthly instalment for a loan or car finance.',
      fields: [
        { id: 'p', label: 'Amount', type: 'money', min: 1, max: 1e12, def: 2000000 },
        { id: 'r', label: 'Markup', type: 'number', unit: '% a year', min: 0, max: 100, def: 22 },
        { id: 'n', label: 'Term', type: 'number', unit: 'months', min: 1, max: 480, def: 36 }
      ],
      compute: function (v) {
        var i = v.r / 100 / 12;
        var m = i === 0 ? v.p / v.n : v.p * i / (1 - Math.pow(1 + i, -v.n));
        return { value: m, money: 1,
                 extra: [['Total repaid', m * v.n, 1], ['Total markup', m * v.n - v.p, 1]] };
      },
      related: ['installments', 'expenses']
    },
    tipsplit: {
      intro: 'Split a bill, with or without a tip.',
      fields: [
        { id: 'bill', label: 'Bill', type: 'money', min: 0, max: 1e9, def: 4800 },
        { id: 'tip', label: 'Tip', type: 'number', unit: '%', min: 0, max: 100, def: 10 },
        { id: 'people', label: 'People', type: 'number', min: 1, max: 100, def: 4 }
      ],
      compute: function (v) {
        var total = v.bill * (1 + v.tip / 100);
        return { value: total / v.people, money: 1,
                 extra: [['Total with tip', total, 1], ['Tip', total - v.bill, 1]] };
      },
      related: ['expenses', 'ledger']
    },
    zakat: {
      intro: 'Zakat due on your qualifying assets at 2.5%.',
      fields: [
        { id: 'cash', label: 'Cash & bank', type: 'money', min: 0, max: 1e12, def: 850000 },
        { id: 'gold', label: 'Gold & silver value', type: 'money', min: 0, max: 1e12, def: 400000 },
        { id: 'debts', label: 'Debts owed by you', type: 'money', min: 0, max: 1e12, def: 60000 }
      ],
      compute: function (v) {
        var net = v.cash + v.gold - v.debts;
        var nisabUsd = 912;                          /* ~612g silver, converted at render */
        return { value: net > 0 ? net * 0.025 : 0, money: 1,
                 extra: [['Net qualifying wealth', Math.max(0, net), 1]],
                 nisabUsd: nisabUsd, net: net };
      },
      note: 'Zakat is due once a lunar year has passed on wealth above nisab.',
      source: 'Nisab tracks the current silver rate',
      related: ['goldrates', 'faraid']
    },
    faraid: {
      intro: 'Indicative inheritance shares under the fixed portions.',
      fields: [
        { id: 'estate', label: 'Net estate', type: 'money', min: 0, max: 1e12, def: 10000000 },
        { id: 'sons', label: 'Sons', type: 'number', min: 0, max: 20, def: 2 },
        { id: 'daughters', label: 'Daughters', type: 'number', min: 0, max: 20, def: 1 },
        { id: 'spouse', label: 'Surviving spouse', type: 'choice', options: ['Wife', 'Husband', 'None'], def: 'Wife' }
      ],
      note: 'Indicative only. Inheritance depends on the full set of surviving relatives — consult a qualified scholar.',
      related: ['zakat', 'documents']
    },
    fuelcost: {
      intro: 'What a journey costs at today’s pump price.',
      fields: [
        { id: 'dist', label: 'Distance', type: 'number', unit: 'km', min: 1, max: 20000, def: 165 },
        { id: 'eff', label: 'Mileage', type: 'number', unit: 'km per litre', min: 1, max: 60, def: 12 },
        { id: 'price', label: 'Fuel price', type: 'money', min: 1, max: 100000, def: 264.61, decimals: 2 }
      ],
      compute: function (v) {
        var litres = v.dist / v.eff;
        return { value: litres * v.price, money: 1,
                 extra: [['Fuel needed', litres.toFixed(1) + ' L', 0]] };
      },
      reads: ['fuel'],
      related: ['fuel', 'trains']
    }
  };

  /* ---- Data tools -------------------------------------------------------- */
  var DATA = {
    fuel: {
      source: 'OGRA notification', updated: 'Effective 1 September',
      rows: [['Petrol', 264.61, '+2.14'], ['Hi-Octane', 284.90, '+1.80'],
             ['Diesel', 272.98, '−0.65'], ['Light Diesel', 160.45, '0.00']],
      unit: 'per litre', related: ['fuelcost', 'vehicle'], writesTo: ['fuelcost']
    },
    goldrates: {
      source: 'Karachi Sarafa · open market', updated: '11:20 today',
      tabs: ['Rates', 'Convert', 'Chart'],
      currencies: [['US Dollar', 285.10, '+0.35'], ['UK Pound', 381.50, '+1.20'],
                   ['Saudi Riyal', 76.00, '0.00'], ['UAE Dirham', 77.60, '+0.10']],
      bullion: [['Gold 24k · tola', 258400, '+1,900'], ['Gold 22k · 10g', 203120, '+1,630'],
                ['Silver · tola', 3140, '0.00']],
      chartSeries: { label: 'USD to PKR, last 30 days', from: '9 Aug', to: 'Today',
                     series: [278.4, 279.1, 280.3, 279.8, 281.2, 282.0, 281.4, 283.1, 284.0, 283.6, 284.8, 285.1],
                     format: function (v) { return v.toFixed(2); } },
      related: ['currency', 'markets', 'zakat']
    },
    markets: {
      source: 'Delayed 15 min', updated: 'Close, 8 September',
      /* PSX is removed outside Pakistan rather than shown disabled: a tab the
         user can never use is clutter, not a feature. */
      tabs: ['PSX', 'Global', 'Crypto'],
      tabsFor: marketTabs,
      rowsByTab: {
        PSX: [['KSE-100', 78412, '+0.8%'], ['KSE-30', 24180, '+0.6%'],
              ['All Share', 51230, '+0.4%'], ['KMI-30', null, ''],
              ['Volume (shares)', 412000000, '']],
        Global: [['S&P 500', 5642, '+0.4%'], ['NASDAQ', 17930, '+0.7%'],
                 ['FTSE 100', 8298, '\u22120.2%'], ['Nikkei 225', 38104, '+1.1%']],
        Crypto: [['Bitcoin', 61240, '+2.3%'], ['Ethereum', 2585, '+1.4%'],
                 ['Solana', 143, '\u22120.8%'], ['XRP', 0.58, '+0.3%']]
      },
      /* An index is points, volume is shares and crypto is dollars \u2014 none of
         them are the user's local currency (\u00a747: identify the unit). */
      timeframes: ['1W', '1M', '3M', '1Y'],
      disclaimer: 'Information only, not investment advice. Prices are delayed.',
      valueFormat: function (v, row, tab, L) {
        if (tab === 'Crypto') return L.moneyRaw(v, 'USD', v < 10 ? 2 : 0);
        if (/volume/i.test(row[0])) return L.num(v);
        return L.num(v, { maximumFractionDigits: 0 }) + ' pts';
      },
      /* The lead instrument each tab charts and heroes. */
      leadFor: {
        PSX:    { name: 'KSE-100', value: '78,412 pts', delta: '+0.8%',
                  sub: 'Pakistan Stock Exchange \u00b7 close, 8 September' },
        Global: { name: 'S&P 500', value: '5,642 pts', delta: '+0.4%',
                  sub: 'New York \u00b7 session closed' },
        Crypto: { name: 'Bitcoin', value: '$61,240', delta: '+2.3%',
                  sub: 'Trades around the clock \u00b7 delayed 15 min' }
      },
      /* One short series per timeframe, so the chips actually move the chart
         instead of relabelling the same line. */
      chartFor: {
        PSX: {
          label: 'KSE-100', format: function (v) { return Math.round(v).toLocaleString() + ' pts'; },
          windows: {
            '1W': { from: '1 Sep', to: 'Today', series: [77980, 78120, 77860, 78240, 78390, 78180, 78305, 78412] },
            '1M': { from: '9 Aug', to: 'Today', series: [76210, 76540, 77120, 76890, 77480, 78010, 78180, 78412] },
            '3M': { from: '10 Jun', to: 'Today', series: [71400, 72680, 74100, 73520, 75180, 76240, 77300, 78412] },
            '1Y': { from: 'Sep 2025', to: 'Today', series: [62800, 65400, 68100, 66900, 70300, 73100, 75800, 78412] }
          }
        },
        Global: {
          label: 'S&P 500', format: function (v) { return Math.round(v).toLocaleString() + ' pts'; },
          windows: {
            '1W': { from: '1 Sep', to: 'Today', series: [5604, 5590, 5622, 5611, 5638, 5629, 5647, 5642] },
            '1M': { from: '9 Aug', to: 'Today', series: [5528, 5560, 5581, 5571, 5604, 5622, 5638, 5642] },
            '3M': { from: '10 Jun', to: 'Today', series: [5312, 5388, 5441, 5407, 5502, 5560, 5604, 5642] },
            '1Y': { from: 'Sep 2025', to: 'Today', series: [4480, 4690, 4885, 4820, 5080, 5290, 5470, 5642] }
          }
        },
        Crypto: {
          label: 'Bitcoin', format: function (v) { return '$' + Math.round(v).toLocaleString(); },
          windows: {
            '1W': { from: '1 Sep', to: 'Today', series: [61050, 60420, 61800, 60900, 62100, 61400, 60880, 61240] },
            '1M': { from: '9 Aug', to: 'Today', series: [58900, 59800, 61050, 60420, 61800, 60900, 61980, 61240] },
            '3M': { from: '10 Jun', to: 'Today', series: [52400, 55100, 57200, 56800, 59400, 60100, 61800, 61240] },
            '1Y': { from: 'Sep 2025', to: 'Today', series: [38200, 43600, 48900, 45300, 52700, 57400, 59900, 61240] }
          }
        }
      },
      overview: {
        PSX:    [['Volume', '412M', 'i-bar'], ['Gainers', '218', 'i-trending'], ['Losers', '143', 'i-trending-down']],
        Global: [['Advancing', '312', 'i-trending'], ['Declining', '188', 'i-trending-down'], ['Volume', '4.1B', 'i-bar']],
        Crypto: [['Market cap', '$2.14T', 'i-bar'], ['24h volume', '$78B', 'i-trending'], ['BTC dominance', '56.4%', 'i-pie']]
      },
      sortsFor: {
        PSX: ['Change', 'Price', 'Name'],
        Global: ['Change', 'Price', 'Volume', 'Name'],
        Crypto: ['Rank', 'Change', 'Price', 'Market cap']
      },
      /* Movers carry the per-market fields the brief asks for. Anything that
         will not fit one row is disclosed on tap rather than crammed in. */
      moversFor: {
        PSX: [
          { name: 'OGDC', sub: 'Oil & gas exploration', price: 214.80, change: 3.2, cur: 'PKR', vol: 8.4,
            detail: [['Open', '208.20'], ['Day range', '207.90 \u2013 216.40'], ['Volume', '8.4M shares']] },
          { name: 'Lucky Cement', sub: 'Cement', price: 1024.50, change: 2.4, cur: 'PKR', vol: 1.2,
            detail: [['Open', '1,000.10'], ['Day range', '998.00 \u2013 1,031.75'], ['Volume', '1.2M shares']] },
          { name: 'HBL', sub: 'Commercial banking', price: 178.30, change: 1.1, cur: 'PKR', vol: 5.1,
            detail: [['Open', '176.35'], ['Day range', '175.80 \u2013 179.10'], ['Volume', '5.1M shares']] },
          { name: 'Engro', sub: 'Fertiliser', price: 312.60, change: -1.4, cur: 'PKR', vol: 2.7,
            detail: [['Open', '317.05'], ['Day range', '311.20 \u2013 317.90'], ['Volume', '2.7M shares']] },
          { name: 'PSO', sub: 'Oil marketing', price: 421.15, change: -2.8, cur: 'PKR', vol: 3.9,
            detail: [['Open', '433.30'], ['Day range', '419.60 \u2013 434.10'], ['Volume', '3.9M shares']] }
        ],
        Global: [
          { name: 'Nvidia', sub: 'NVDA \u00b7 semiconductors', price: 118.60, change: 2.1, cur: 'USD', vol: 264.8,
            detail: [['Open', '$116.30'], ['Volume', '264.8M'], ['Session', 'Closed \u00b7 delayed 15 min']] },
          { name: 'Microsoft', sub: 'MSFT \u00b7 software', price: 416.20, change: 0.9, cur: 'USD', vol: 21.4,
            detail: [['Open', '$413.10'], ['Volume', '21.4M'], ['Session', 'Closed \u00b7 delayed 15 min']] },
          { name: 'Apple', sub: 'AAPL \u00b7 consumer tech', price: 228.40, change: 0.6, cur: 'USD', vol: 48.2,
            detail: [['Open', '$226.90'], ['Volume', '48.2M'], ['Session', 'Closed \u00b7 delayed 15 min']] },
          { name: 'Amazon', sub: 'AMZN \u00b7 retail', price: 178.90, change: -0.4, cur: 'USD', vol: 34.1,
            detail: [['Open', '$179.70'], ['Volume', '34.1M'], ['Session', 'Closed \u00b7 delayed 15 min']] },
          { name: 'Tesla', sub: 'TSLA \u00b7 automotive', price: 232.80, change: -1.3, cur: 'USD', vol: 88.6,
            detail: [['Open', '$236.10'], ['Volume', '88.6M'], ['Session', 'Closed \u00b7 delayed 15 min']] }
        ],
        Crypto: [
          { name: 'Bitcoin', sub: 'BTC \u00b7 rank 1', price: 61240, change: 2.3, cur: 'USD', rank: 1, cap: 1210,
            detail: [['Market cap', '$1.21T'], ['24h volume', '$32.4B'], ['Circulating', '19.75M of 21M'],
                     ['All-time high', '$73,738'], ['All-time low', '$67']] },
          { name: 'Ethereum', sub: 'ETH \u00b7 rank 2', price: 2585, change: 1.4, cur: 'USD', rank: 2, cap: 311,
            detail: [['Market cap', '$311B'], ['24h volume', '$14.8B'], ['Circulating', '120.3M'],
                     ['All-time high', '$4,878'], ['All-time low', '$0.43']] },
          { name: 'Solana', sub: 'SOL \u00b7 rank 5', price: 143, change: -0.8, cur: 'USD', rank: 5, cap: 67,
            detail: [['Market cap', '$67B'], ['24h volume', '$2.9B'], ['Circulating', '468M'],
                     ['All-time high', '$260'], ['All-time low', '$0.50']] },
          { name: 'XRP', sub: 'XRP \u00b7 rank 7', price: 0.58, change: 0.3, cur: 'USD', rank: 7, cap: 32,
            detail: [['Market cap', '$32B'], ['24h volume', '$1.1B'], ['Circulating', '56.2B of 100B'],
                     ['All-time high', '$3.84'], ['All-time low', '$0.0028']] },
          { name: 'Cardano', sub: 'ADA \u00b7 rank 11', price: 0.34, change: -1.9, cur: 'USD', rank: 11, cap: 12,
            detail: [['Market cap', '$12B'], ['24h volume', '$310M'], ['Circulating', '35.1B of 45B'],
                     ['All-time high', '$3.09'], ['All-time low', '$0.017']] }
        ]
      },
      related: ['goldrates', 'currency']
    },
    natsavings: {
      source: 'National Savings profit rates', updated: 'Bundled — checked weekly',
      rows: [['Behbood Certificates', 15.36, ''], ['Pensioners Benefit', 15.36, ''],
             ['Defence Savings', 12.84, ''], ['Regular Income', 13.32, '']],
      unit: '% a year', related: ['prizebonds', 'goals']
    },
    prizebonds: {
      source: 'National Savings draw schedule', updated: 'Next draw 15 September',
      rows: [['₨ 750 bond', 0, 'Draw 15 Sep'], ['₨ 1,500 bond', 0, 'Draw 15 Nov'],
             ['₨ 25,000 premium', 0, 'Draw 10 Dec']],
      related: ['natsavings'], searchable: 'Check a bond number'
    },
    packages: {
      source: 'Operator published rates', updated: 'Checked today',
      rows: [['Jazz Super Card', 1350, '30 days'], ['Zong Super Weekly', 480, '7 days'],
             ['Ufone Super Card', 1200, '30 days'], ['Telenor Easycard', 1180, '30 days']],
      related: ['bills']
    },
    loadshed: {
      source: 'K-Electric schedule', updated: 'Checked 20 min ago',
      related: ['bills'], custom: 'schedule'
    },
    news: { source: 'Multiple publishers', updated: 'Refreshed 6 min ago', related: ['cricket'] },
    cricket: { source: 'Live scorecard', updated: 'Ball by ball', related: ['news'] },
    speedtest: { source: 'On-device measurement', fresh: 'computed', related: [] },
    flights: { source: 'Airline schedules', updated: 'Live', related: ['trains'],
               searchable: 'Flight number or route' },
    trains: { source: 'Pakistan Railways', updated: 'Live', related: ['flights', 'fuelcost'] },
    vehicle: { source: 'Excise & Taxation', updated: 'On request', related: ['fuel'],
               searchable: 'Registration number' },
    emergency: { source: 'National helplines', offline: 'full', fresh: 'static', related: ['health'] },
    weather: { source: 'Meteorological service', updated: 'Updated 4 min ago',
               tabs: ['Now', '24 hours', '5 days'],
               related: ['calendar', 'prayer'], reqCity: 1 }
  };

  /* ---- Lists ------------------------------------------------------------- */
  var LIST = {
    todos:    { noun: 'task', completable: 1, groups: ['Today', 'Upcoming', 'Completed'], seed: [['Finish the Q3 summary', 'Today · 15:00'], ['Call home', 'Today · 21:00'], ['Renew the car token', 'Fri']], related: ['calendar', 'reminders'], writesTo: ['calendar'] },
    notes:    { noun: 'note', searchable: 'Search notes', pinnable: 1,
                notes: [
                  { t: 'Reading list', b: 'The Left Hand of Darkness\nPiranesi\nThe Dispossessed\nStation Eleven', pin: 1, ago: 2880 },
                  { t: 'Standup, Monday', b: 'Shipped the rates cache. Next: the offline copy for markets, then the share card sizing on small screens.', ago: 95 },
                  { t: 'Gift ideas', b: 'Ammi \u2014 the shawl from Anarkali\nHamza \u2014 headphones\nAyesha \u2014 the ceramic set she kept mentioning', ago: 4320 }
                ],
                related: ['todos', 'docscan'] },
    shopping: { noun: 'item', completable: 1, searchable: 'Search list', seed: [['Milk', '2 litres'], ['Rice', '5 kg'], ['Bread', '']], related: ['recipes', 'expenses'] },
    birthdays:{ noun: 'birthday', seed: [['Ayesha', 'In 4 days'], ['Abbu', '14 October'], ['Hamza', '2 January']], related: ['calendar', 'age'], writesTo: ['calendar'] },
    alarms:   { noun: 'alarm', seed: [['Wake up', '06:30 · weekdays'], ['Leave for work', '08:15 · weekdays']], related: ['timer', 'todos'] },
    reminders:{ noun: 'reminder', completable: 1, seed: [['Pay the gas bill', 'Tomorrow · 10:00'], ['Book dentist', 'Thursday']], related: ['todos', 'calendar'], writesTo: ['calendar'] },
    events:   { noun: 'event', seed: [['Design review', 'Today · 14:00'], ['Nikah — Sana', '20 September']], related: ['calendar'], writesTo: ['calendar'] },
    documents:{ noun: 'document', searchable: 'Search documents', seed: [['CNIC', 'Expires 2031'], ['Passport', 'Expires June 2028'], ['Driving licence', 'Expires March 2027']], sensitive: 1, auth: 'account', related: ['docscan', 'vehicle'], writesTo: ['calendar'] },
    vaccines: { noun: 'record', seed: [['Hepatitis B', '3 of 3 · complete'], ['Influenza', 'Due October']], sensitive: 1, auth: 'account', related: ['health'] },
    health:   { noun: 'record', searchable: 'Search records', seed: [['Blood test', '12 August'], ['Blood pressure', '118/76 · Monday']], sensitive: 1, auth: 'account', related: ['vaccines', 'meds'], canExport: 1 },
    meds:     { noun: 'medication', completable: 1, seed: [['Metformin', '500 mg · twice daily'], ['Vitamin D', 'Weekly · Sunday']], sensitive: 1, auth: 'account', related: ['health'], writesTo: ['calendar'] },
    subs:     { noun: 'subscription', money: 1, period: 'Every month',
               seed: [['Netflix', 'Monthly · 12th', 6], ['Spotify', 'Monthly · 3rd', 4],
                      ['iCloud', 'Monthly · 28th', 3], ['Gym', 'Monthly · 1st', 12]], sensitive: 1, related: ['expenses'], writesTo: ['calendar'] },
    goals:    { noun: 'goal', money: 1, period: 'Saved so far',
               seed: [['Emergency fund', '64% of target', 640], ['Umrah', '30% of target', 300]], sensitive: 1, related: ['expenses', 'natsavings'] },
    expenses: { noun: 'expense', money: 1, period: 'This month',
               seed: [['Groceries', 'Today', 67], ['Fuel', 'Yesterday', 40], ['Electricity', '2 September', 42],
                      ['Chai Shai', '2 September', 6], ['Phone top-up', '1 September', 9]], sensitive: 1, related: ['goals', 'subs'], canExport: 1 },
    ledger:   { noun: 'entry', money: 1, period: 'Outstanding',
               seed: [['Bilal — lent', 'Since 12 August', 21], ['Sana — borrowed', 'Since 1 September', 9]], sensitive: 1, related: ['expenses', 'committee'] },
    installments:{ noun: 'plan', money: 1, period: 'Due next',
               seed: [['Bike — 8 of 12', 'Next 15 September', 32], ['Laptop — 3 of 6', 'Next 20 September', 55]], related: ['loan', 'calendar'], writesTo: ['calendar'] },
    committee:{ noun: 'committee', seed: [['Office committee', 'Month 4 of 10'], ['Family committee', 'Month 2 of 12']], related: ['ledger'], writesTo: ['calendar'] },
    bills:    { noun: 'bill', groups: ['Upcoming', 'Paid'], money: 1, period: 'Due this month',
               seed: [['K-Electric', 'Due 12 September', 65], ['Sui Southern Gas', 'Due 14 September', 14],
                      ['PTCL', 'Paid 2 September', 12]], auth: 'history', related: ['packages', 'expenses'], writesTo: ['calendar'] },
    recipes:  { noun: 'recipe', searchable: 'Search recipes', seed: [['Chicken karahi', '45 min'], ['Daal chawal', '30 min'], ['Kheer', '1 hr']], related: ['mealplan', 'shopping'] },
    mealplan: { noun: 'meal', seed: [['Monday — Daal chawal', 'Dinner'], ['Tuesday — Karahi', 'Dinner']], related: ['recipes', 'shopping'], writesTo: ['calendar'] },
    learning: { noun: 'course', searchable: 'Search courses', seed: [['Arabic — beginner', '3 of 20 lessons'], ['Product design', '12 of 30']], related: ['notes'] },
    parcel:   { noun: 'parcel', seed: [['TCS · 4820 9931 22', 'Out for delivery'], ['Leopards · LP7741', 'In transit']], related: ['notes'], custom: 'parcel' },
    babybudget:{ noun: 'item', money: 1, period: 'Planned',
               seed: [['Cot', 'Planned', 120], ['Pram', 'Bought', 180], ['Car seat', 'Planned', 90]], related: ['expenses', 'goals'] }
  };

  /* ---- Trackers ---------------------------------------------------------- */
  var TRACK = {
    habits:   { unitLabel: 'day', target: 7, items: ['Walk 6k steps', '8 glasses', 'Read 10 pages'], related: ['streak', 'water'] },
    water:    { unitLabel: 'glass', target: 8, current: 5, step: 1, goalLabel: 'Daily goal', related: ['habits'] },
    streak:   { unitLabel: 'day', target: 30, current: 12, related: ['habits'] },
    praytrack:{ unitLabel: 'prayer', target: 5, current: 3, faithItems: 1, related: ['prayer', 'calendar'], reads: ['prayer'], writesTo: ['calendar'] },
    fasting:  { unitLabel: 'fast', target: 30, current: 3, related: ['ramadan', 'calendar'] },
    taraweeh: { unitLabel: 'night', target: 30, current: 0, related: ['ramadan', 'prayer'] },
    cycle:    { unitLabel: 'day', target: 28, current: 12, sensitive: 1, auth: 'account', related: ['health'] },
    pregnancy:{ unitLabel: 'week', target: 40, current: 18, sensitive: 1, auth: 'account', related: ['health', 'babybudget'] }
  };

  /* ---- Readers ----------------------------------------------------------- */
  var READ = {
    quran: { title: 'Al-Kahf', sub: 'The Cave · ayah 42 of 110', progress: 38,
             arabic: 'وَأُحِيطَ بِثَمَرِهِ فَأَصْبَحَ يُقَلِّبُ كَفَّيْهِ عَلَىٰ مَآ أَنفَقَ فِيهَا',
             text: 'And his fruits were encompassed by ruin, so he began turning his hands over what he had spent on it.',
             ref: 'Al-Kahf 18:42', shareKind: 'ayah',
             related: ['quransearch', 'hadith', 'duas'] },
    quransearch: { title: 'Search the Qur’an', searchable: 'Word, surah or ayah',
                   results: [['Ar-Rahman', 'Chapter 55 · 78 ayahs'], ['Al-Kahf', 'Chapter 18 · 110 ayahs'],
                             ['Yaseen', 'Chapter 36 · 83 ayahs']],
                   related: ['quran'] },
    hadith: { title: 'Hadith of the day', sub: 'Sahih al-Bukhari',
              text: 'The most beloved deeds to God are those done consistently, even if they are few.',
              ref: 'Bukhari 6464 · Narrated by Aisha', shareKind: 'hadith',
              related: ['quran', 'duas'] },
    duas: { title: 'Daily duas', sub: '42 in your library',
            arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
            text: 'Our Lord, give us good in this world.',
            ref: 'Al-Baqarah 2:201', shareKind: 'dua',
            related: ['quran', 'tasbih'] },
    names99: { title: '99 Names', sub: 'Asma ul Husna',
               arabic: 'ٱلرَّحْمَٰنُ', text: 'The Most Compassionate', ref: '1 of 99',
               shareKind: 'dua', related: ['duas', 'tasbih'] },
    ayah: { title: 'Ayah of the day', sub: 'Ar-Ra’d · 13:28',
            arabic: 'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
            text: 'Truly, it is in the remembrance of God that hearts find rest.',
            ref: 'Ar-Ra’d 13:28', shareKind: 'ayah',
            related: ['quran', 'hadith'] }
  };

  /* ---- Scanners ---------------------------------------------------------- */
  var SCAN = {
    qr:         { modes: ['Scan', 'Generate'], why: 'Lume needs the camera to read a QR code. Nothing is uploaded — the code is decoded on your device.', action: 'Scan a code', related: ['docscan'] },
    docscan:    { why: 'Lume needs the camera to photograph a page and turn it into a PDF. Pages stay on your device until you share them.', action: 'Scan a page', related: ['documents', 'notes'] },
    passport:   { why: 'Lume needs the camera to take a compliant passport photo at the right size.', action: 'Take a photo', related: ['documents'] },
    mediasaver: { why: 'Paste a link and Lume saves the media to your device.', action: 'Paste a link', perms: [], related: [] },
    wastatus:   { why: 'Lume needs file access to read statuses your device has already downloaded.', action: 'Open statuses', perms: ['files'], platform: 'android', related: ['mediasaver'] }
  };

  /* ---- Timers ------------------------------------------------------------ */
  var TIMER = {
    timer:     { mode: 'countdown', presets: [1, 3, 5, 10, 20], related: ['stopwatch', 'alarms'] },
    stopwatch: { mode: 'up', related: ['timer'] },
    tasbih:    { mode: 'count', target: 33, related: ['duas', 'praytrack'] }
  };

  /* ---- Custom ------------------------------------------------------------ */
  var CUSTOM = {
    prayer:   { related: ['praytrack', 'qibla', 'mosques'], reqCity: 1, writesTo: ['calendar', 'praytrack'], source: 'Computed for your city' },
    qibla:    { related: ['prayer', 'mosques'], reqCity: 1, perms: ['orientation'], source: 'Great-circle bearing to the Kaaba' },
    calendar: { related: ['todos', 'bills', 'birthdays'], reads: ['todos', 'bills', 'installments', 'committee', 'meds', 'birthdays', 'prayer'] },
    hijri:    { related: ['calendar', 'ramadan'] },
    ramadan:  { related: ['fasting', 'taraweeh', 'prayer'], reads: ['prayer'] },
    mosques:  { related: ['prayer', 'qibla'], reqCity: 1, source: 'Community directory' },
    play:     { related: [] }
  };


  /* ---- Prayer & Islam composition (v2 §9) -------------------------------- */
  var ISLAM = {
    prayer: {
      heroLive: 1,
      hero: function (c) {
        var st = c.prayer();
        var total = Math.max(0, Math.round(st.toNext * 60));
        var h = Math.floor(total / 3600), m = Math.floor(total % 3600 / 60), sec = total % 60;
        var pad = function (n) { return n < 10 ? '0' + n : '' + n; };
        var isFriday = new Date().getDay() === 5;
        var name = st.next.name === 'Dhuhr' && isFriday ? 'Jumma' : st.next.name;
        return {
          label: 'Next prayer · ' + name,
          value: h + ':' + pad(m) + ':' + pad(sec),
          sub: c.hhmm(st.next) + ' in ' + c.profile.city +
               (isFriday && st.next.name === 'Dhuhr' ? ' · Jumma khutbah' : ''),
          progress: Math.round(st.progress * 100),
          foot: 'Counting down to ' + name
        };
      },
      nudge: { when: 'notifications', icon: 'i-bell-ring',
               title: 'Adhan reminders are off',
               text: 'Get a quiet nudge five minutes before each prayer.',
               action: 'Turn on' },
      settings: [
        { label: 'Calculation method',
          value: function (c) { return c.profile.method; },
          options: ['Karachi', 'MWL', 'ISNA', 'UmmAlQura', 'Egyptian', 'Tehran', 'Gulf'],
          apply: function (v, ctx) { ctx.profile.method = v; ctx.setMethod(v); } },
        { label: 'Asr juristic method',
          value: function (c) { return c.profile.hanafi ? 'Hanafi' : 'Standard'; },
          options: ['Standard', 'Hanafi'],
          apply: function (v, ctx) { ctx.profile.hanafi = (v === 'Hanafi'); ctx.setMethod(ctx.profile.method); } },
        { label: 'High latitude rule',
          value: 'Middle of the night',
          options: ['Middle of the night', 'One seventh', 'Angle based'] }
      ],
      disclaimer: 'Times are computed on your device from your city, so they keep working offline.'
    },

    praytrack: {
      hero: function (c) {
        var done = 3;
        return { label: 'Today', value: c.L.num(done) + ' of 5', sub: 'prayers logged',
                 progress: Math.round(done / 5 * 100), tone: 'calm' };
      },
      sections: [{ title: 'This week', secondary: true, icon: 'i-check-circle', rows: [
        ['Monday', 'All five logged', '5/5'],
        ['Sunday', 'Missed Asr', '4/5'],
        ['Saturday', 'All five logged', '5/5']
      ] }],
      disclaimer: 'Logged prayers stay on this device and never appear in a notification preview.'
    },

    ramadan: {
      hero: function (c) {
        return { label: 'Ramadan 1447', value: 'In 172 days',
                 sub: 'Begins around 18 February 2027', progress: 6 };
      },
      metrics: function (c) {
        var st = c.prayer();
        var fajr = st.list.filter(function (p) { return p.name === 'Fajr'; })[0];
        var mag = st.list.filter(function (p) { return p.name === 'Maghrib'; })[0];
        return [['Suhoor ends', c.hhmm(fajr), 'i-moon'],
                ['Iftar', c.hhmm(mag), 'i-sun'],
                ['Fasting hours', '13h 33m', 'i-clock']];
      },
      sections: [{ title: 'Ramadan tools', icon: 'i-moon-star', rows: [
        ['Fasting tracker', 'Log each day', ''],
        ['Taraweeh', 'Track the nights', ''],
        ['Zakat calculator', 'Work out what is due', '']
      ] }]
    },

    fasting: {
      hero: function (c) {
        return { label: 'Today', value: 'Not fasting', sub: 'Tap below to log a fast', tone: 'calm' };
      },
      sections: [{ title: 'Recent', secondary: true, icon: 'i-moon', rows: [
        ['Monday', 'Kept', '✓'], ['Thursday', 'Kept', '✓'], ['Last Monday', 'Missed', '—']
      ] }]
    },

    taraweeh: {
      hero: function (c) {
        var st = c.prayer();
        var isha = st.list.filter(function (p) { return p.name === 'Isha'; })[0];
        return { label: 'Tonight', value: c.hhmm(isha), sub: 'Taraweeh usually begins after Isha in ' + c.profile.city,
                 tone: 'calm' };
      },
      sections: [{ title: 'Nearby congregations', icon: 'i-mosque', rows: [
        ['Masjid-e-Tooba', '20 rak\u2018ah · starts 20:15', '650 m'],
        ['Jamia Masjid Al-Falah', '8 rak\u2018ah · starts 20:30', '1.2 km']
      ] }],
      disclaimer: 'Timings vary by mosque. Confirm locally during Ramadan.'
    },

    mosques: {
      hero: function (c) {
        return { label: 'Nearest', value: 'Masjid-e-Tooba', sub: c.L.distance(0.65) + ' from ' + c.profile.city,
                 tone: 'calm' };
      },
      disclaimer: 'Distances are from your selected city. Lume does not ask for GPS to show this.'
    },

    quran: {
      hero: function (c) {
        return { label: 'Continue reading', value: 'Al-Kahf', sub: 'Ayah 42 of 110 · about 6 minutes left',
                 progress: 38, tone: 'calm' };
      },
      sections: [{ title: 'Jump to', icon: 'i-book', rows: [
        ['Al-Fatihah', 'Chapter 1 · 7 ayahs', ''],
        ['Ya-Sin', 'Chapter 36 · 83 ayahs', ''],
        ['Ar-Rahman', 'Chapter 55 · 78 ayahs', '']
      ] }]
    },

    hijri: {
      hero: function (c) {
        return { label: 'Today', value: '15 Rabi\u2018 al-Awwal', sub: '1448 · ' + c.L.dateLong(new Date()),
                 tone: 'calm' };
      },
      sections: [{ title: 'Coming up', icon: 'i-moon-star', rows: [
        ['Ramadan begins', 'About 18 February 2027', '172 days'],
        ['Eid al-Fitr', 'About 20 March 2027', '202 days'],
        ['Hajj', 'About 26 May 2027', '269 days']
      ] }],
      settings: [{ label: 'Moon sighting adjustment', value: 'None',
                   options: ['None', '−1 day', '+1 day'] }],
      disclaimer: 'Hijri dates depend on local moon sighting and may differ by a day.'
    },

    names99: {
      sections: [{ title: 'Browse', icon: 'i-star', rows: [
        ['Ar-Rahman', 'The Most Compassionate', '1'],
        ['Ar-Rahim', 'The Most Merciful', '2'],
        ['Al-Malik', 'The Sovereign', '3'],
        ['Al-Quddus', 'The Most Holy', '4']
      ] }]
    },

    duas: {
      sections: [{ title: 'Categories', icon: 'i-heart', rows: [
        ['Morning & evening', '12 duas', ''],
        ['Travel', '6 duas', ''],
        ['Before sleep', '5 duas', ''],
        ['Distress & difficulty', '9 duas', '']
      ] }]
    },

    zakat: {
      sections: [{ title: 'How this is worked out', secondary: true, icon: 'i-help', rows: [
        ['Rate', 'Two and a half percent of qualifying wealth', '2.5%'],
        ['Nisab', 'Tracks the current silver rate', ''],
        ['Lunar year', 'Wealth must have been held for a full hijri year', '']
      ] }]
    },

    faraid: {
      sections: [{ title: 'Assumptions', secondary: true, icon: 'i-scales', rows: [
        ['Fixed shares', 'Applied before any residue is distributed', ''],
        ['Residue', 'Passes to the agnatic heirs', ''],
        ['Debts and bequests', 'Settled before distribution', '']
      ] }],
      disclaimer: 'Indicative only. Inheritance depends on the full set of surviving relatives — consult a qualified scholar.'
    }
  };


  /* One rule for which market tabs exist, so the hero, the metrics and the
     screen itself cannot disagree about which market is being shown. */
  function marketTabs(country) {
    return ['PSX', 'Global', 'Crypto'].filter(function (tb) {
      return tb !== 'PSX' || country === 'PK';
    });
  }
  function marketTab(c) {
    var tabs = marketTabs(c.profile.country);
    return c.tab && tabs.indexOf(c.tab) >= 0 ? c.tab : tabs[0];
  }

  /* ---- Money & Rates composition (v2 §9) --------------------------------- */
  var MONEYC = {
    markets: {
      hero: function (c) {
        var lead = SPECS.markets.leadFor[marketTab(c)];
        return { label: lead.name, value: lead.value, delta: lead.delta, sub: lead.sub };
      },
      metrics: function (c) { return SPECS.markets.overview[marketTab(c)]; }
    },

    fuel: {
      hero: function (c) {
        return { label: 'Petrol · effective 1 September', value: c.L.moneyRaw(264.61, 'PKR', 2),
                 sub: 'per litre in ' + c.profile.city, foot: 'Reviewed fortnightly by OGRA' };
      },
      sections: [{ title: 'Recent changes', secondary: true, icon: 'i-trending', rows: [
        ['1 September', 'Petrol raised', '+2.14'],
        ['16 August', 'Petrol lowered', '−1.68'],
        ['1 August', 'Petrol raised', '+3.05']
      ] }]
    },

    natsavings: {
      hero: function (c) {
        return { label: 'Best current rate', value: '15.36%', sub: 'Behbood Savings Certificates',
                 foot: 'Profit paid monthly' };
      },
      sections: [{ title: 'Terms at a glance', secondary: true, icon: 'i-shield', rows: [
        ['Behbood', 'Widows and over-60s only · 10 years', '15.36%'],
        ['Pensioners Benefit', 'Pensioners only · 10 years', '15.36%'],
        ['Defence Savings', 'Open to all · 10 years', '12.84%'],
        ['Regular Income', 'Open to all · 5 years', '13.32%']
      ] }],
      disclaimer: 'Rates are set by the Central Directorate of National Savings and change without notice.'
    },

    prizebonds: {
      hero: function (c) {
        return { label: 'Next draw', value: '15 September', sub: '\u20a8 750 denomination · Multan',
                 foot: 'Results usually published the same evening' };
      },
      sections: [{ title: 'Upcoming draws', icon: 'i-ticket', rows: [
        ['\u20a8 750', 'Multan', '15 Sep'],
        ['\u20a8 1,500', 'Karachi', '15 Nov'],
        ['\u20a8 25,000 premium', 'Lahore', '10 Dec']
      ] }]
    },

    packages: {
      hero: function (c) {
        return { label: 'Cheapest monthly bundle', value: c.L.moneyRaw(480, 'PKR', 0),
                 sub: 'Zong Super Weekly · 7 days', tone: 'calm' };
      },
      sections: [{ title: 'What you get', secondary: true, icon: 'i-signal', rows: [
        ['Jazz Super Card', '10 GB · 1,000 mins · 30 days', '\u20a8 1,350'],
        ['Zong Super Weekly', '5 GB · 500 mins · 7 days', '\u20a8 480'],
        ['Ufone Super Card', '8 GB · 1,500 mins · 30 days', '\u20a8 1,200'],
        ['Telenor Easycard', '7 GB · 800 mins · 30 days', '\u20a8 1,180']
      ] }],
      disclaimer: 'Allowances and taxes vary by region and are set by the operator.'
    },

    loan: {
      sections: [{ title: 'How the instalment is built', secondary: true, icon: 'i-bank', rows: [
        ['Method', 'Reducing balance, monthly rest', ''],
        ['Fees', 'Processing and insurance are not included', ''],
        ['Early settlement', 'May carry a separate charge', '']
      ] }],
      disclaimer: 'An estimate. Your lender\u2019s schedule is the binding one.'
    },

    committee: {
      hero: function (c) {
        return { label: 'Office committee', value: c.L.money(300), sub: 'Monthly pot · round 4 of 10',
                 progress: 40, foot: 'Your turn comes in round 7' };
      },
      metrics: function (c) {
        return [['Members', c.L.num(10), 'i-users'],
                ['Collected', c.L.money(300), 'i-check-circle'],
                ['Next due', '15 Sep', 'i-calendar']];
      },
      sections: [{ title: 'Round order', icon: 'i-list', rows: [
        ['Round 4 · Bilal', 'Paid out 15 August', 'Done'],
        ['Round 5 · Ayesha', 'Due 15 September', 'Next'],
        ['Round 6 · Hamza', 'Due 15 October', ''],
        ['Round 7 · You', 'Due 15 November', 'Yours']
      ] }]
    },

    installments: {
      hero: function (c) {
        return { label: 'Next payment due', value: c.L.money(32), sub: 'Bike \u00b7 15 September \u00b7 8 of 12',
                 progress: 67 };
      }
    },

    ledger: {
      metrics: function (c) {
        return [['Lent out', c.L.money(21), 'i-arrow-ur'],
                ['Borrowed', c.L.money(9), 'i-arrow-r'],
                ['Net', c.L.money(12), 'i-wallet']];
      }
    },

    goals: {
      hero: function (c) {
        return { label: 'Emergency fund', value: c.L.money(640), sub: 'of ' + c.L.money(1000) + ' target',
                 progress: 64, foot: 'On track for December' };
      },
      sections: [{ title: 'Contributions', secondary: true, icon: 'i-target', rows: [
        ['September', 'Monthly transfer', '+' ],
        ['August', 'Monthly transfer', '+'],
        ['July', 'Monthly transfer plus bonus', '+']
      ] }]
    },

    subs: {
      hero: function (c) {
        return { label: 'Committed every month', value: c.L.money(25), sub: '4 active subscriptions',
                 foot: 'Next renewal: Spotify on the 3rd' };
      }
    },

    tax: {
      sections: [{ title: 'Assumptions', secondary: true, icon: 'i-percent', rows: [
        ['Basis', 'Salaried individual, tax year 2025-26', ''],
        ['Excluded', 'Zakat, donations and other credits', ''],
        ['Surcharge', 'Not applied below the threshold', '']
      ] }]
    },

    fuelcost: {
      sections: [{ title: 'Where the number comes from', secondary: true, icon: 'i-route', rows: [
        ['Fuel price', 'Taken from the current pump price', ''],
        ['Mileage', 'Your own figure, not a manufacturer claim', ''],
        ['Return trip', 'Double the distance for a round trip', '']
      ] }]
    },

    tipsplit: {
      sections: [{ title: 'Split modes', secondary: true, icon: 'i-users', rows: [
        ['Even', 'Everyone pays the same share', ''],
        ['By item', 'Coming to the ledger tool', '']
      ] }]
    },

    bills: {
      hero: function (c) {
        return { label: 'Due this month', value: c.L.money(79), sub: '2 bills outstanding',
                 foot: 'K-Electric is next, on the 12th' };
      }
    }
  };


  /* ---- Daily Life composition (v2 §9) ------------------------------------ */
  var DAILYC = {
    loadshed: {
      hero: function (c) {
        return { label: 'Right now', value: 'Power is on', sub: 'Next outage 14:00 \u2013 16:00 in ' + c.profile.city,
                 progress: 68, foot: 'About 2 hours from now' };
      },
      settings: [{ label: 'Area', value: 'Gulshan-e-Iqbal',
                   options: ['Gulshan-e-Iqbal', 'Clifton', 'DHA', 'Nazimabad'] }],
      disclaimer: 'Schedules can change at short notice, and emergency load management is not published in advance.'
    },

    flights: {
      hero: function (c) {
        return { label: 'Track a flight', value: 'PK-304', sub: 'Karachi \u2192 Islamabad \u00b7 on time',
                 foot: 'Departs 14:35, gate B4' };
      },
      metrics: [['Duration', '1h 55m', 'i-clock'], ['Aircraft', 'A320', 'i-plane'], ['Status', 'On time', 'i-check-circle']],
      sections: [{ title: 'Today on this route', icon: 'i-plane', rows: [
        ['PK-300', 'Departs 07:10 \u00b7 on time', '07:10'],
        ['PK-304', 'Departs 14:35 \u00b7 on time', '14:35'],
        ['PK-368', 'Departs 19:20 \u00b7 delayed 25m', '19:45']
      ] }],
      disclaimer: 'Times come from published schedules and can change without notice.'
    },

    cricket: {
      hero: function (c) {
        return { label: 'Live \u00b7 2nd Test, day 2', value: '214/4', sub: 'Pakistan trail South Africa by 87',
                 foot: 'Babar 78* \u00b7 Saud 41* \u00b7 58.2 overs' };
      },
      metrics: [['Run rate', '3.67', 'i-trending'], ['Partnership', '96', 'i-users'], ['Overs left', '31.4', 'i-clock']],
      sections: [{ title: 'Fixtures', secondary: true, icon: 'i-cricket', rows: [
        ['3rd Test', 'Karachi \u00b7 from 16 September', ''],
        ['1st ODI', 'Lahore \u00b7 28 September', ''],
        ['T20 series', 'Rawalpindi \u00b7 October', '']
      ] }]
    },

    emergency: {
      hero: function (c) {
        return { label: 'Most urgent', value: '1122', sub: 'Rescue \u00b7 ambulance and fire in ' + c.profile.city,
                 tone: 'calm', foot: 'Works without credit on most networks' };
      },
      sections: [{ title: 'Other services', icon: 'i-shield', rows: [
        ['Police', 'Madadgar helpline', '15'],
        ['Edhi ambulance', 'Round the clock', '115'],
        ['Fire brigade', 'Municipal', '16'],
        ['K-Electric', 'Power faults', '118']
      ] }],
      disclaimer: 'Numbers are for Pakistan. Change your country in Personalisation if you have travelled.'
    },

    vehicle: {
      hero: function (c) {
        return { label: 'Registration check', value: 'No fines', sub: 'Nothing outstanding on this vehicle',
                 tone: 'calm', foot: 'Last checked today' };
      },
      sections: [{ title: 'Vehicle', secondary: true, icon: 'i-car', rows: [
        ['Token tax', 'Paid to June 2026', 'Paid'],
        ['Registration', 'Valid', 'Valid'],
        ['Last transfer', 'March 2023', '']
      ] }],
      disclaimer: 'Sourced from Excise & Taxation records, which can lag behind recent payments.'
    },

    speedtest: {
      hero: function (c) {
        return { label: 'Last test', value: '48.2 Mbps', sub: 'Download \u00b7 good for streaming and calls',
                 tone: 'calm' };
      },
      metrics: [['Download', '48.2 Mbps', 'i-download'], ['Upload', '12.4 Mbps', 'i-arrow-ur'], ['Ping', '28 ms', 'i-signal']],
      disclaimer: 'Measured on your device against the nearest server. Results vary with signal and time of day.'
    },

    qr: {
      sections: [{ title: 'What Lume can read', secondary: true, icon: 'i-qr', rows: [
        ['Links', 'Opens in your browser after you confirm', ''],
        ['Payment codes', 'Shows the details before anything happens', ''],
        ['Plain text', 'Copy it or share it onward', '']
      ] }],
      disclaimer: 'Codes are decoded on your device. Nothing is uploaded.'
    },

    docscan: {
      sections: [{ title: 'How it works', secondary: true, icon: 'i-scan', rows: [
        ['Capture', 'Edges are detected as you frame the page', ''],
        ['Multi-page', 'Add pages, reorder or remove before finishing', ''],
        ['Export', 'Builds a PDF on your device', '']
      ] }]
    },

    passport: {
      sections: [{ title: 'Sizes', secondary: true, icon: 'i-image', rows: [
        ['Pakistan', '35 \u00d7 45 mm \u00b7 white background', 'NADRA'],
        ['ICAO standard', '35 \u00d7 45 mm', 'Most visas'],
        ['US visa', '51 \u00d7 51 mm', '2 \u00d7 2 in']
      ] }],
      disclaimer: 'Check the exact requirement with the issuing authority before printing.'
    },

    mediasaver: {
      sections: [{ title: 'Supported sources', secondary: true, icon: 'i-download', rows: [
        ['Public video links', 'Saved to your device', ''],
        ['Public image posts', 'Saved to your gallery', ''],
        ['Private or paid content', 'Not supported', 'No']
      ] }],
      disclaimer: 'Only content you are allowed to keep. Lume does not bypass any restriction.'
    },

    wastatus: {
      disclaimer: 'Android only. Lume reads statuses your device has already downloaded — it never accesses WhatsApp data directly.'
    },

    converter: {
      sections: [{ title: 'Categories', secondary: true, icon: 'i-ruler', rows: [
        ['Distance', 'km, miles, metres, feet', ''],
        ['Weight', 'kg, pounds, grams, ounces', ''],
        ['Volume', 'litres, gallons, millilitres', ''],
        ['Temperature', 'Celsius, Fahrenheit', '']
      ] }]
    },

    bmi: {
      sections: [{ title: 'What the ranges mean', secondary: true, icon: 'i-pulse', rows: [
        ['Under 18.5', 'Underweight', ''],
        ['18.5 to 24.9', 'Healthy range', ''],
        ['25 to 29.9', 'Overweight', ''],
        ['30 and above', 'Obese', '']
      ] }],
      disclaimer: 'BMI ignores muscle, build and age. It is a rough screen, not a diagnosis.'
    },

    age: {
      sections: [{ title: 'Also worth knowing', secondary: true, icon: 'i-cake', rows: [
        ['Leap-day birthdays', 'Counted on 28 February in common years', ''],
        ['Total days', 'Shown alongside the years and months', ''],
        ['Next birthday', 'Counted from today in your timezone', '']
      ] }]
    },

    trains: {
      metrics: [['Trains today', '42', 'i-train'], ['Running now', '17', 'i-signal'], ['At a station', '9', 'i-pin']]
    },

    news: {
      sections: [{ title: 'Topics', secondary: true, icon: 'i-news', rows: [
        ['Business', 'Rupee, markets and trade', ''],
        ['Your city', 'Local services and notices', ''],
        ['Sport', 'Cricket and more', '']
      ] }],
      disclaimer: 'Headlines come from several publishers. Lume does not rank by opinion.'
    }
  };


  /* ---- Personal composition (v2 §9) -------------------------------------- */
  var PERSONALC = {
    parcel: {
      hero: function (c) {
        return { label: 'Out for delivery', value: 'Arrives today', sub: 'TCS \u00b7 between 14:00 and 18:00',
                 progress: 82, foot: 'CN 4820 9931 22 \u00b7 Lahore to ' + c.profile.city };
      },
      sections: [{ title: 'Other shipments', secondary: true, icon: 'i-package', rows: [
        ['Leopards \u00b7 LP7741', 'In transit \u00b7 Sukkur hub', '2 days'],
        ['PostEx \u00b7 PX1180', 'Delivered 4 September', 'Done']
      ] }],
      disclaimer: 'Supports TCS, Leopards, PostEx, Trax, CallCourier, BlueEx and Daewoo FastEx.'
    },

    birthdays: {
      hero: function (c) {
        return { label: 'Next up', value: 'Ayesha', sub: 'In 4 days \u00b7 turning 29', tone: 'calm' };
      },
      sections: [{ title: 'Later this year', secondary: true, icon: 'i-cake', rows: [
        ['Abbu', '14 October \u00b7 turning 63', '36 days'],
        ['Hamza', '2 January \u00b7 turning 31', '116 days']
      ] }]
    },

    streak: {
      hero: function (c) {
        return { label: 'Current streak', value: c.L.num(12) + ' days', sub: 'Best ever: 24 days',
                 progress: 40, foot: '18 more days to beat it' };
      },
      canShare: 1,
      sections: [{ title: 'This month', secondary: true, icon: 'i-flame', rows: [
        ['Days kept', 'Out of 8 so far', '8'],
        ['Longest run', 'Since 27 August', '12'],
        ['Missed', 'None this month', '0']
      ] }],
      disclaimer: 'A streak is a nudge, not a scoreboard. Missing a day does not undo the habit.'
    },

    recipes: {
      sections: [{ title: 'Categories', secondary: true, icon: 'i-utensils', rows: [
        ['Everyday dinners', '12 recipes', ''],
        ['Quick, under 30 minutes', '8 recipes', ''],
        ['Sweet', '4 recipes', '']
      ] }]
    },

    mealplan: {
      hero: function (c) {
        return { label: 'Tonight', value: 'Daal chawal', sub: 'Serves 4 \u00b7 about 30 minutes', tone: 'calm' };
      },
      sections: [{ title: 'Rest of the week', secondary: true, icon: 'i-calendar', rows: [
        ['Tuesday', 'Chicken karahi', ''],
        ['Wednesday', 'Vegetable pulao', ''],
        ['Thursday', 'Leftovers', '']
      ] }]
    },

    alarms: {
      hero: function (c) {
        return { label: 'Next alarm', value: '06:30', sub: 'Wake up \u00b7 weekdays', tone: 'calm',
                 foot: 'In 17 hours 40 minutes' };
      },
      nudge: { when: 'notifications', icon: 'i-bell-ring', title: 'Alarms need notifications',
               text: 'Without them Lume cannot wake you.', action: 'Turn on' }
    },

    learning: {
      hero: function (c) {
        return { label: 'In progress', value: 'Arabic', sub: 'Lesson 3 of 20 \u00b7 beginner', progress: 15,
                 foot: 'Next: definite articles' };
      },
      sections: [{ title: 'Also learning', secondary: true, icon: 'i-graduation', rows: [
        ['Product design', '12 of 30 lessons', '40%']
      ] }]
    },

    documents: {
      hero: function (c) {
        return { label: 'Expiring soonest', value: 'Driving licence', sub: 'Expires March 2027 \u00b7 in 18 months',
                 tone: 'calm' };
      },
      disclaimer: 'Documents are encrypted on this device and never appear in a notification preview.'
    },

    vaccines: {
      hero: function (c) {
        return { label: 'Due next', value: 'Influenza', sub: 'Recommended from October', tone: 'calm' };
      },
      sections: [{ title: 'History', secondary: true, icon: 'i-syringe', rows: [
        ['Hepatitis B', '3 of 3 \u00b7 complete', '2019'],
        ['Tetanus', 'Booster', '2021'],
        ['COVID-19', '2 doses plus booster', '2022']
      ] }],
      disclaimer: 'Private to you. Kept on this device and shown to nobody else.'
    },

    health: {
      hero: function (c) {
        return { label: 'Needs attention', value: '1 follow-up', sub: 'Blood test results to review',
                 tone: 'calm', foot: 'Everything else is up to date' };
      },
      metrics: [['Records', '14', 'i-folder'], ['Files', '6', 'i-image'], ['Shared', '0', 'i-share']],
      sections: [{ title: 'Recent', secondary: true, icon: 'i-pulse', rows: [
        ['Blood test', '12 August \u00b7 lab report attached', 'PDF'],
        ['Blood pressure', 'Monday \u00b7 118/76', 'Normal'],
        ['Consultation', '3 July \u00b7 notes', '']
      ] }],
      canExport: 1,
      disclaimer: 'Encrypted on this device. Sharing gives read-only access and can be revoked at any time.'
    },

    play: {
      sections: [{ title: 'Something quick', icon: 'i-play', rows: [
        ['Word of the day', 'Two minutes', ''],
        ['Number puzzle', 'Five minutes', ''],
        ['Memory tiles', 'Three minutes', '']
      ] }]
    },

    babybudget: {
      hero: function (c) {
        return { label: 'Planned so far', value: c.L.money(390), sub: 'Across 3 items',
                 progress: 39, foot: 'Of a ' + c.L.money(1000) + ' budget' };
      }
    },

    habits: {
      hero: function (c) {
        return { label: 'Today', value: '2 of 3', sub: 'habits done', progress: 67, tone: 'calm' };
      },
      sections: [{ title: 'Streaks', secondary: true, icon: 'i-flame', rows: [
        ['Walk 6k steps', 'Longest 14 days', '2'],
        ['8 glasses', 'Longest 9 days', '1'],
        ['Read 10 pages', 'Longest 21 days', '6']
      ] }],
      disclaimer: 'Progress is a nudge, not a score. Nothing here is shared.'
    },

    cycle: {
      hero: function (c) {
        return { label: 'Today', value: 'Day 12', sub: 'Follicular phase', progress: 43,
                 tone: 'calm', foot: 'Next period expected around 24 September' };
      },
      disclaimer: 'Predictions are estimates from your own logged history and can shift. Private to this device.'
    },

    pregnancy: {
      hero: function (c) {
        return { label: 'Week 18', value: 'Second trimester', sub: 'About 22 weeks to go', progress: 45,
                 tone: 'calm', foot: 'Next scan: anomaly scan around week 20' };
      },
      sections: [{ title: 'Coming up', secondary: true, icon: 'i-baby', rows: [
        ['Week 20', 'Anomaly scan', ''],
        ['Week 24', 'Glucose screening', ''],
        ['Week 28', 'Third trimester begins', '']
      ] }],
      disclaimer: 'General guidance only. Your midwife or doctor knows your situation.'
    },

    meds: {
      hero: function (c) {
        return { label: 'Next dose', value: '20:00', sub: 'Metformin 500 mg \u00b7 with food', tone: 'calm',
                 foot: 'Morning dose taken at 08:10' };
      },
      nudge: { when: 'notifications', icon: 'i-bell-ring', title: 'Dose reminders are off',
               text: 'Lume can remind you quietly, without naming the medicine.', action: 'Turn on' },
      disclaimer: 'Reminders never name the medicine on your lock screen.'
    },

    shopping: {
      hero: function (c) {
        return { label: 'To buy', value: c.L.num(3) + ' items', sub: 'Nothing ticked off yet', tone: 'calm' };
      }
    },

    todos: {
      settings: [{ label: 'Default view', value: 'Today', options: ['Today', 'Upcoming', 'Completed'] }]
    },

    /* Pinning is real in the notes view, so the composed screen adds only
       the privacy note the rest of Personal carries. */
    notes: {
      disclaimer: 'Notes stay on this device. Nothing is uploaded and nothing syncs.'
    }
  };


  /* ---- Remaining tools: low-density by design (§4) still get context ----- */
  var RESTC = {
    currency: {
      sections: [{ title: 'Today', secondary: true, icon: 'i-currency', rows: [
        ['Interbank', 'Used for this conversion', '285.10'],
        ['Open market', 'What a dealer would quote', '286.40'],
        ['Spread', 'Difference between the two', '1.30']
      ] }],
      disclaimer: 'Indicative rates. A bank or dealer will quote its own.'
    },
    datecalc: {
      sections: [{ title: 'Handy spans', secondary: true, icon: 'i-calendar', rows: [
        ['30 days', 'Common notice period', ''],
        ['90 days', 'A quarter', ''],
        ['180 days', 'Half a year', '']
      ] }]
    },
    reminders: {
      hero: function (c) {
        return { label: 'Next reminder', value: '10:00', sub: 'Pay the gas bill · tomorrow', tone: 'calm' };
      },
      nudge: { when: 'notifications', icon: 'i-bell-ring', title: 'Reminders need notifications',
               text: 'Otherwise Lume can only show them inside the app.', action: 'Turn on' }
    },
    events: {
      hero: function (c) {
        return { label: 'Next event', value: '14:00', sub: 'Design review · Studio 2', tone: 'calm' };
      }
    },
    ayah: {
      sections: [{ title: 'About this ayah', secondary: true, icon: 'i-book', rows: [
        ['Surah', 'Ar-Ra‘d, the Thunder', 'Chapter 13'],
        ['Revealed', 'Makkah', ''],
        ['Theme', 'Remembrance and the settled heart', '']
      ] }]
    },
    hadith: {
      sections: [{ title: 'Source', secondary: true, icon: 'i-quote', rows: [
        ['Collection', 'Sahih al-Bukhari', '6464'],
        ['Narrator', 'Aisha, may God be pleased with her', ''],
        ['Grade', 'Sahih', '']
      ] }]
    },
    quransearch: {
      sections: [{ title: 'Try searching', secondary: true, icon: 'i-search', rows: [
        ['A surah name', 'Ar-Rahman, Al-Kahf, Yaseen', ''],
        ['A word', 'mercy, patience, light', ''],
        ['A reference', '18:42', '']
      ] }]
    },
    tasbih: {
      sections: [{ title: 'Common counts', secondary: true, icon: 'i-beads', rows: [
        ['Subhan Allah', 'After each prayer', '33'],
        ['Alhamdulillah', 'After each prayer', '33'],
        ['Allahu akbar', 'After each prayer', '34']
      ] }]
    }
  };

  var SPECS = {};
  function merge(map, shape) {
    Object.keys(map).forEach(function (id) {
      var base = {}, k;
      for (k in SHAPE_DEFAULTS[shape]) base[k] = SHAPE_DEFAULTS[shape][k];
      var over = map[id] || {};
      for (k in over) base[k] = over[k];
      base.shape = shape;
      SPECS[id] = base;
    });
  }
  merge(CALC, 'calculator');
  merge(DATA, 'data');
  merge(LIST, 'list');
  merge(TRACK, 'tracker');
  merge(READ, 'reader');
  merge(SCAN, 'scanner');
  merge(TIMER, 'timer');
  merge(CUSTOM, 'custom');

  function applyComposition(map) {
    Object.keys(map).forEach(function (id) {
      if (!SPECS[id]) return;
      var add = map[id];
      Object.keys(add).forEach(function (k) { SPECS[id][k] = add[k]; });
    });
  }
  applyComposition(ISLAM);
  applyComposition(MONEYC);
  applyComposition(DAILYC);
  applyComposition(PERSONALC);
  applyComposition(RESTC);

  /* Anything not named above still gets its shape's contract. */
  function specFor(feature) {
    if (SPECS[feature.id]) return SPECS[feature.id];
    var base = {}, k;
    for (k in SHAPE_DEFAULTS[feature.sh] || SHAPE_DEFAULTS.custom) {
      base[k] = (SHAPE_DEFAULTS[feature.sh] || SHAPE_DEFAULTS.custom)[k];
    }
    base.shape = feature.sh;
    return base;
  }

  return { SPECS: SPECS, SHAPE_DEFAULTS: SHAPE_DEFAULTS, specFor: specFor };
})();
