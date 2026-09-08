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
      tabs: ['PSX', 'Global', 'Crypto'],
      rowsByTab: {
        PSX: [['KSE-100', 78412, '+0.8%'], ['KSE-30', 24180, '+0.6%'],
              ['All Share', 51230, '+0.4%'], ['Volume (shares)', 412000000, '']],
        Global: [['S&P 500', 5642, '+0.4%'], ['NASDAQ', 17930, '+0.7%'],
                 ['FTSE 100', 8298, '−0.2%'], ['Nikkei 225', 38104, '+1.1%']],
        Crypto: [['Bitcoin', 61240, '+2.3%'], ['Ethereum', 2585, '+1.4%'],
                 ['Solana', 143, '−0.8%'], ['XRP', 0.58, '+0.3%']]
      },
      /* An index is points, volume is shares and crypto is dollars — none of
         them are the user's local currency (§47: identify the unit). */
      valueFormat: function (v, row, tab, L) {
        if (tab === 'Crypto') return L.moneyRaw(v, 'USD', v < 10 ? 2 : 0);
        if (/volume/i.test(row[0])) return L.num(v);
        return L.num(v, { maximumFractionDigits: 0 }) + ' pts';
      },
      chartFor: {
        PSX:    { label: 'KSE-100, last 30 days', from: '9 Aug', to: 'Today',
                  series: [74100, 74620, 75180, 74890, 75640, 76210, 75980, 76540, 77120, 77480, 78010, 78412],
                  format: function (v) { return Math.round(v).toLocaleString(); } },
        Global: { label: 'S&P 500, last 30 days', from: '9 Aug', to: 'Today',
                  series: [5480, 5502, 5471, 5533, 5560, 5528, 5581, 5604, 5590, 5622, 5638, 5642],
                  format: function (v) { return Math.round(v).toLocaleString(); } },
        Crypto: { label: 'Bitcoin, last 30 days', from: '9 Aug', to: 'Today',
                  series: [57200, 58100, 56800, 59400, 60100, 58900, 59800, 61050, 60420, 61800, 60900, 61240],
                  format: function (v) { return '$' + Math.round(v).toLocaleString(); } }
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
               related: ['calendar', 'prayer'], reqCity: 1 }
  };

  /* ---- Lists ------------------------------------------------------------- */
  var LIST = {
    todos:    { noun: 'task', groups: ['Today', 'Upcoming', 'Completed'], seed: [['Finish the Q3 summary', 'Today · 15:00'], ['Call home', 'Today · 21:00'], ['Renew the car token', 'Fri']], related: ['calendar', 'reminders'], writesTo: ['calendar'] },
    notes:    { noun: 'note', seed: [['Meeting notes', 'Edited yesterday'], ['Reading list', '6 items'], ['Gift ideas', 'Edited Monday']], related: ['todos', 'docscan'] },
    shopping: { noun: 'item', seed: [['Milk', '2 litres'], ['Rice', '5 kg'], ['Bread', '']], related: ['recipes', 'expenses'] },
    birthdays:{ noun: 'birthday', seed: [['Ayesha', 'In 4 days'], ['Abbu', '14 October'], ['Hamza', '2 January']], related: ['calendar', 'age'], writesTo: ['calendar'] },
    alarms:   { noun: 'alarm', seed: [['Wake up', '06:30 · weekdays'], ['Leave for work', '08:15 · weekdays']], related: ['timer', 'todos'] },
    reminders:{ noun: 'reminder', seed: [['Pay the gas bill', 'Tomorrow · 10:00'], ['Book dentist', 'Thursday']], related: ['todos', 'calendar'], writesTo: ['calendar'] },
    events:   { noun: 'event', seed: [['Design review', 'Today · 14:00'], ['Nikah — Sana', '20 September']], related: ['calendar'], writesTo: ['calendar'] },
    documents:{ noun: 'document', seed: [['CNIC', 'Expires 2031'], ['Passport', 'Expires June 2028'], ['Driving licence', 'Expires March 2027']], sensitive: 1, auth: 'account', related: ['docscan', 'vehicle'], writesTo: ['calendar'] },
    vaccines: { noun: 'record', seed: [['Hepatitis B', '3 of 3 · complete'], ['Influenza', 'Due October']], sensitive: 1, auth: 'account', related: ['health'] },
    health:   { noun: 'record', seed: [['Blood test', '12 August'], ['Blood pressure', '118/76 · Monday']], sensitive: 1, auth: 'account', related: ['vaccines', 'meds'], canExport: 1 },
    meds:     { noun: 'medication', seed: [['Metformin', '500 mg · twice daily'], ['Vitamin D', 'Weekly · Sunday']], sensitive: 1, auth: 'account', related: ['health'], writesTo: ['calendar'] },
    subs:     { noun: 'subscription', seed: [['Netflix', 'Monthly · 12th'], ['Spotify', 'Monthly · 3rd'], ['iCloud', 'Monthly · 28th']], sensitive: 1, related: ['expenses'], writesTo: ['calendar'] },
    goals:    { noun: 'goal', seed: [['Emergency fund', '64% of target'], ['Umrah', '30% of target']], sensitive: 1, related: ['expenses', 'natsavings'] },
    expenses: { noun: 'expense', seed: [['Groceries', 'Today'], ['Fuel', 'Yesterday'], ['Electricity', '2 September']], sensitive: 1, related: ['goals', 'subs'], canExport: 1 },
    ledger:   { noun: 'entry', seed: [['Bilal — lent', 'Since 12 August'], ['Sana — borrowed', 'Since 1 September']], sensitive: 1, related: ['expenses', 'committee'] },
    installments:{ noun: 'plan', seed: [['Bike — 8 of 12', 'Next 15 September'], ['Laptop — 3 of 6', 'Next 20 September']], related: ['loan', 'calendar'], writesTo: ['calendar'] },
    committee:{ noun: 'committee', seed: [['Office committee', 'Month 4 of 10'], ['Family committee', 'Month 2 of 12']], related: ['ledger'], writesTo: ['calendar'] },
    bills:    { noun: 'bill', groups: ['Upcoming', 'Paid'], seed: [['K-Electric', 'Due 12 September'], ['Sui Southern Gas', 'Due 14 September'], ['PTCL', 'Paid 2 September']], auth: 'history', related: ['packages', 'expenses'], writesTo: ['calendar'] },
    recipes:  { noun: 'recipe', seed: [['Chicken karahi', '45 min'], ['Daal chawal', '30 min'], ['Kheer', '1 hr']], related: ['mealplan', 'shopping'] },
    mealplan: { noun: 'meal', seed: [['Monday — Daal chawal', 'Dinner'], ['Tuesday — Karahi', 'Dinner']], related: ['recipes', 'shopping'], writesTo: ['calendar'] },
    learning: { noun: 'course', seed: [['Arabic — beginner', '3 of 20 lessons'], ['Product design', '12 of 30']], related: ['notes'] },
    parcel:   { noun: 'parcel', seed: [['TCS · 4820 9931 22', 'Out for delivery'], ['Leopards · LP7741', 'In transit']], related: ['notes'], custom: 'parcel' },
    babybudget:{ noun: 'item', seed: [['Cot', 'Planned'], ['Pram', 'Bought']], related: ['expenses', 'goals'] }
  };

  /* ---- Trackers ---------------------------------------------------------- */
  var TRACK = {
    habits:   { unitLabel: 'day', target: 7, items: ['Walk 6k steps', '8 glasses', 'Read 10 pages'], related: ['streak', 'water'] },
    water:    { unitLabel: 'glass', target: 8, current: 5, step: 1, related: ['habits'] },
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
    qr:         { why: 'Lume needs the camera to read a QR code. Nothing is uploaded — the code is decoded on your device.', action: 'Scan a code', related: ['docscan'] },
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
