/* ============================================================
   Lume — catalogue & content
   The single source of truth for every feature in the product.

   Religion and country are SEPARATE dimensions:
     faith : 'islamic'  → visible only when Islamic content is on
     loc   : 'PK'       → visible only when the user's country matches
     adapts: true       → global feature whose *content* localises
   Nothing else in the app is allowed to invent its own rule.
   ============================================================ */
window.LUME = (function () {
  'use strict';

  /* ---------------------------------------------------------
     Interests — the taxonomy behind "What are you here for?"
     --------------------------------------------------------- */
  var INTEREST_GROUPS = [
    { id: 'everyday', label: 'Everyday life', items: [
      { id: 'weather',  label: 'Weather',        icon: 'i-cloud-sun' },
      { id: 'calendar', label: 'Calendar',       icon: 'i-calendar' },
      { id: 'tasks',    label: 'Tasks & to-dos', icon: 'i-check-square' },
      { id: 'notes',    label: 'Notes',          icon: 'i-note' },
      { id: 'convert',  label: 'Converters',     icon: 'i-ruler' },
      { id: 'maths',    label: 'Calculators',    icon: 'i-calculator' },
      { id: 'alarms',   label: 'Alarms & timers',icon: 'i-alarm' }
    ] },
    { id: 'money', label: 'Money & finance', items: [
      { id: 'expenses', label: 'Expenses',       icon: 'i-wallet' },
      { id: 'rates',    label: 'Rates & gold',   icon: 'i-coins' },
      { id: 'bills',    label: 'Bills',          icon: 'i-receipt' },
      { id: 'savings',  label: 'Saving & goals', icon: 'i-target' },
      { id: 'markets',  label: 'Markets',        icon: 'i-trending' }
    ] },
    { id: 'health', label: 'Health & wellness', items: [
      { id: 'habits',   label: 'Habits',         icon: 'i-flame' },
      { id: 'water',    label: 'Water',          icon: 'i-droplet' },
      { id: 'fitness',  label: 'Fitness',        icon: 'i-pulse' },
      { id: 'meds',     label: 'Medication',     icon: 'i-pill' },
      { id: 'sleep',    label: 'Sleep',          icon: 'i-moon' }
    ] },
    { id: 'travel', label: 'Travel & getting around', items: [
      { id: 'trains',   label: 'Trains',         icon: 'i-train' },
      { id: 'flights',  label: 'Flights',        icon: 'i-plane' },
      { id: 'nearby',   label: 'Nearby places',  icon: 'i-pin' },
      { id: 'fuel',     label: 'Fuel',           icon: 'i-fuel' }
    ] },
    { id: 'news', label: 'News & entertainment', items: [
      { id: 'news',     label: 'News',           icon: 'i-news' },
      { id: 'cricket',  label: 'Cricket',        icon: 'i-cricket' },
      { id: 'reading',  label: 'Reading',        icon: 'i-book' },
      { id: 'quotes',   label: 'Daily quotes',   icon: 'i-quote' }
    ] },
    /* Kept apart on purpose: this group is what switches the faith
       dimension on. It is never pre-selected for anyone. */
    { id: 'faith', label: 'Islamic features', faith: true, items: [
      { id: 'prayer',   label: 'Prayer times',   icon: 'i-prayer' },
      { id: 'quran',    label: 'Qur’an',         icon: 'i-book' },
      { id: 'hadith',   label: 'Hadith',         icon: 'i-quote' },
      { id: 'duas',     label: 'Duas & dhikr',   icon: 'i-beads' },
      { id: 'zakat',    label: 'Zakat & giving', icon: 'i-wallet' },
      { id: 'ramadan',  label: 'Ramadan',        icon: 'i-moon-star' }
    ] }
  ];

  var FAITH_INTERESTS = ['prayer', 'quran', 'hadith', 'duas', 'zakat', 'ramadan'];

  /* Someone who skips the picker still gets a personal app. */
  var DEFAULT_INTERESTS = ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses', 'news'];

  /* ---------------------------------------------------------
     Feature catalogue
       id     unique key
       n      display name
       i      icon symbol
       c      Tools-screen category
       g      product group (Prayer & Islam / Money & Rates / …)
       ints   interests that make it "for you"
       m      small status line shown on the card
       act    what tapping it does
       kw     extra search keywords (what people actually type)
       faith  Islamic — hidden unless Islamic content is on
       countries  markets this feature has actually launched in; absent means
                  global. A PK entry says "localised for Pakistan so far",
                  not "this category is Pakistan-only"
       adapts global feature whose *content* localises (visibility is global)
       shareable  supports the visual share-card flow
       reqCity    needs a city to mean anything
       sens   sensitive — never promoted on Home
       staple a tool almost everyone wants, so it survives the For-you filter
     --------------------------------------------------------- */
  var F = [
    /* ---- Everyday ---- */
    { id: 'calculator', staple: 1, n: 'Calculator',       i: 'i-calculator', c: 'everyday', g: 'daily',    ints: ['maths'],              m: 'Standard',      act: 'tool:calculator', kw: 'maths sum arithmetic percent' },
    { id: 'converter', staple: 1,  n: 'Unit Converter',   i: 'i-ruler',      c: 'everyday', g: 'daily',    ints: ['convert'],            m: '32 units',      act: '', kw: 'length weight metric imperial litres kg' },
    { id: 'currency', staple: 1,   n: 'Currency',         i: 'i-currency',   c: 'everyday', g: 'money',    ints: ['convert', 'rates'],   m: 'Live rates',    act: 'tool:currency', kw: 'exchange forex dollar usd pkr riyal pound convert money' },
    { id: 'stopwatch',  n: 'Stopwatch',        i: 'i-stopwatch',  c: 'everyday', g: 'daily',    ints: ['alarms'],             m: 'Laps',          act: '' },
    { id: 'timer', staple: 1,      n: 'Timer',            i: 'i-timer',      c: 'everyday', g: 'daily',    ints: ['alarms'],             m: 'Presets',       act: '' },
    { id: 'age',        n: 'Age Calculator',   i: 'i-cake',       c: 'everyday', g: 'daily',    ints: ['maths'],              m: 'Exact days',    act: '', kw: 'birthday how old years' },
    { id: 'focus',      n: 'Focus Timer',      i: 'i-timer',      c: 'everyday', g: 'daily',    ints: ['alarms', 'habits'],   m: '25 min',        act: 'tool:focus', kw: 'pomodoro concentrate deep work session' },
    { id: 'datecalc',   n: 'Date Calculator',  i: 'i-calendar',   c: 'everyday', g: 'daily',    ints: ['maths', 'calendar'],  m: 'Add · diff',    act: '', kw: 'days between duration' },

    /* ---- Planning ---- */
    { id: 'calendar', staple: 1,   n: 'Calendar',         i: 'i-calendar',   c: 'planning', g: 'daily',    ints: ['calendar'],           m: '3 events',      act: '', kw: 'schedule agenda month' },
    { id: 'reminders', staple: 1,  n: 'Reminders',        i: 'i-bell-ring',  c: 'planning', g: 'personal', ints: ['tasks'],              m: '4 today',       act: '' },
    { id: 'notes', staple: 1,      n: 'Notes',            i: 'i-note',       c: 'planning', g: 'personal', ints: ['notes'],              m: '12 saved',      act: '', kw: 'write memo journal' },
    { id: 'todos', staple: 1,      n: 'To-dos',           i: 'i-check-square',c: 'planning',g: 'personal', ints: ['tasks'],              m: '2 of 5 done',   act: '', kw: 'task checklist' },
    { id: 'events',     n: 'Events',           i: 'i-list',       c: 'planning', g: 'daily',    ints: ['calendar'],           m: 'Next 14:00',    act: '' },

    /* ---- Prayer & Islam (17) ---- */
    { id: 'prayer', staple: 1, reqCity: 1,     n: 'Prayer Times',     i: 'i-prayer',     c: 'islamic', g: 'islam', faith: 1, ints: ['prayer'],       m: 'Asr 15:53',     act: 'tool:prayer', kw: 'salah namaz adhan azan jamaat' },
    { id: 'qibla', staple: 1, reqCity: 1,      n: 'Qibla Compass',    i: 'i-navigation', c: 'islamic', g: 'islam', faith: 1, ints: ['prayer'],       m: '267° W',        act: 'tool:qibla', kw: 'direction kaaba mecca makkah compass' },
    { id: 'mosques', reqCity: 1,    n: 'Nearby Mosques',   i: 'i-mosque',     c: 'islamic', g: 'islam', faith: 1, ints: ['prayer', 'nearby'], m: '3 within 1 km', act: '' },
    { id: 'praytrack',  n: 'Prayer Tracker',   i: 'i-check-circle',c: 'islamic',g: 'islam', faith: 1, ints: ['prayer', 'habits'], m: '12-day streak', act: 'tool:prayer' },
    { id: 'ramadan',    n: 'Ramadan',          i: 'i-moon-star',  c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan'],      m: 'In 172 days',   act: '', kw: 'sehri iftar' },
    { id: 'fasting',    n: 'Fasting Tracker',  i: 'i-moon',       c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan'],      m: '3 kept',        act: '', kw: 'roza sawm' },
    { id: 'taraweeh',   n: 'Taraweeh',         i: 'i-prayer',     c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan', 'prayer'], m: 'Ramadan',  act: '' },
    { id: 'ayah', shareable: 1,       n: 'Ayah of the Day',  i: 'i-sparkles',   c: 'islamic', g: 'islam', faith: 1, ints: ['quran'],        m: 'Ar-Ra’d 28',    act: '', kw: 'verse daily' },
    { id: 'quran', staple: 1, shareable: 1,      n: 'Al-Qur’an',        i: 'i-book',       c: 'islamic', g: 'islam', faith: 1, ints: ['quran', 'reading'], m: 'Al-Kahf 42', act: 'tool:quran', kw: 'surah para juz recite mushaf' },
    { id: 'quransearch',n: 'Search the Qur’an',i: 'i-search',     c: 'islamic', g: 'islam', faith: 1, ints: ['quran'],        m: 'By word',       act: 'sheet:search', kw: 'surah rahman yaseen ayah verse find' },
    { id: 'hadith', shareable: 1,     n: 'Hadith',           i: 'i-quote',      c: 'islamic', g: 'islam', faith: 1, ints: ['hadith', 'reading'], m: 'Daily',    act: '', kw: 'bukhari muslim sunnah' },
    { id: 'duas', shareable: 1,       n: 'Daily Duas',       i: 'i-heart',      c: 'islamic', g: 'islam', faith: 1, ints: ['duas'],         m: '42 saved',      act: '', kw: 'supplication dua azkar' },
    { id: 'names99', shareable: 1,    n: '99 Names',         i: 'i-star',       c: 'islamic', g: 'islam', faith: 1, ints: ['duas', 'quran'], m: 'Asma ul Husna', act: '' },
    { id: 'hijri',      n: 'Islamic Calendar', i: 'i-moon',       c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan', 'calendar'], m: '15 Rabi’ I', act: '', kw: 'hijri date lunar' },
    { id: 'tasbih', staple: 1,     n: 'Tasbih',           i: 'i-beads',      c: 'islamic', g: 'islam', faith: 1, ints: ['duas'],         m: 'Counter',       act: 'tool:tasbih', kw: 'dhikr zikr counter beads tasbeeh' },
    { id: 'zakat',      n: 'Zakat Calculator', i: 'i-wallet',     c: 'islamic', g: 'islam', faith: 1, ints: ['zakat'],        m: 'Nisab check',   act: '', kw: 'charity sadaqah nisab giving' },
    { id: 'faraid',     n: 'Faraid',           i: 'i-scales',     c: 'islamic', g: 'islam', faith: 1, ints: ['zakat'],        m: 'Inheritance',   act: '', kw: 'inheritance mirath wirasat will' },

    /* ---- Money & Rates (14) ---- */
    { id: 'compound',   n: 'Compound Interest',i: 'i-trending',   c: 'money', g: 'money',            ints: ['savings'],       m: 'Project growth', act: 'tool:compound', kw: 'interest growth invest projection returns' },
    { id: 'goldrates',  n: 'Currency & Gold',  i: 'i-coins',      c: 'money', g: 'money', adapts: 1, ints: ['rates'],         m: 'Gold & FX', act: 'tool:goldrates', kw: 'sona gold silver dollar rate open market' },
    { id: 'markets',    n: 'Markets',          i: 'i-trending',   c: 'money', g: 'money',            ints: ['markets'],       m: 'KSE-100 ▲ 0.8%', act: '', kw: 'stocks shares psx index' },
    { id: 'fuel',       n: 'Fuel Prices',      i: 'i-fuel',       c: 'money', g: 'money', adapts: 1, ints: ['fuel'],          m: 'Pump prices',      act: 'tool:fuel', kw: 'petrol diesel price ogra pump' },
    { id: 'fuelcost',   n: 'Fuel Cost',        i: 'i-route',      c: 'money', g: 'money', adapts: 1, ints: ['fuel'],          m: 'Trip cost',     act: '', kw: 'petrol trip mileage average' },
    { id: 'tax',        n: 'Tax Calculator',   i: 'i-percent',    c: 'money', g: 'money', countries: ['PK', 'GB', 'US', 'IN', 'AE', 'SA'], ints: ['expenses'],      m: 'FBR 2025-26',   act: 'tool:tax', kw: 'salary income fbr slab withholding' },
    { id: 'natsavings', n: 'National Savings', i: 'i-shield',     c: 'money', g: 'money', countries: ['PK'], ints: ['savings'],       m: 'Profit rates',  act: '', kw: 'behbood pensioners defence certificate' },
    { id: 'prizebonds', n: 'Prize Bonds',      i: 'i-ticket',     c: 'money', g: 'money', countries: ['PK'], ints: ['savings'],       m: 'Draw 15 Sep',   act: '', kw: 'bond draw result winner' },
    { id: 'bills',      n: 'Bills',            i: 'i-receipt',    c: 'money', g: 'money', adapts: 1, ints: ['bills'],         m: '2 due',         act: 'tool:bills', kw: 'k-electric sui gas wapda ptcl electricity due' },
    { id: 'packages',   n: 'Mobile Packages',  i: 'i-signal',     c: 'money', g: 'money', countries: ['PK'], ints: ['bills'],         m: 'Jazz · Zong',   act: '', kw: 'jazz zong ufone telenor balance load mbs' },
    { id: 'loan',       n: 'Loan / EMI',       i: 'i-bank',       c: 'money', g: 'money',            ints: ['expenses'],      m: 'Instalments',   act: '', kw: 'emi mortgage interest markup car finance' },
    { id: 'tipsplit',   n: 'Tip & Split',      i: 'i-divide',     c: 'money', g: 'money',            ints: ['expenses'],      m: 'Split a bill',  act: '', kw: 'bill share restaurant' },
    { id: 'ledger',     n: 'Lending Ledger',   i: 'i-list',       c: 'money', g: 'money',            ints: ['expenses'],      m: '3 people',   act: '', kw: 'udhaar borrow lend owe khata' },
    { id: 'installments',n:'Installments',     i: 'i-calendar',   c: 'money', g: 'money',            ints: ['expenses'],      m: '3 running',     act: '' },
    { id: 'committee',  n: 'Committee',        i: 'i-users',      c: 'money', g: 'money',            ints: ['savings'],       m: 'Month 4 of 10', act: '', kw: 'bisi rosca kameti pool circle' },

    /* ---- Daily Life (18) ---- */
    { id: 'aqi', reqCity: 1,        n: 'Air Quality',      i: 'i-wind',       c: 'daily', g: 'daily', adapts: 1, ints: ['weather', 'fitness'], m: 'AQI',        act: 'tool:aqi', kw: 'pollution smog pm2.5 air quality index' },
    { id: 'sunmoon', reqCity: 1,    n: 'Sun & Moon',       i: 'i-sun',        c: 'daily', g: 'daily', adapts: 1, ints: ['weather'],       m: 'Sunrise · sunset', act: 'tool:sunmoon', kw: 'sunrise sunset daylight moon phase golden hour' },
    { id: 'worldclock', n: 'World Clock',      i: 'i-clock',      c: 'daily', g: 'daily', adapts: 1, ints: ['calendar', 'flights'], m: '8 cities', act: 'tool:worldclock', kw: 'time zone timezone abroad convert clock' },
    { id: 'holidays',   n: 'Public Holidays',  i: 'i-calendar',   c: 'daily', g: 'daily', adapts: 1, ints: ['calendar'],      m: 'This year',     act: 'tool:holidays', kw: 'bank holiday public national days off' },
    { id: 'weather', staple: 1, reqCity: 1,    n: 'Weather',          i: 'i-cloud-sun',  c: 'daily', g: 'daily', adapts: 1, ints: ['weather'],       m: '34° Clear',     act: '', kw: 'forecast rain temperature humid' },
    { id: 'loadshed', reqCity: 1,   n: 'Loadshedding',     i: 'i-bolt',       c: 'daily', g: 'daily', countries: ['PK'], ints: ['bills'],         m: '14:00–16:00',   act: 'tool:loadshed', kw: 'bijli power outage schedule ke lesco' },
    { id: 'trains', reqCity: 1,     n: 'Trains',           i: 'i-train',      c: 'daily', g: 'daily', countries: ['PK'], ints: ['trains'],        m: 'Green Line',    act: '', kw: 'railway pr green line tezgam bogie seat pnr' },
    { id: 'flights',    n: 'Flights',          i: 'i-plane',      c: 'daily', g: 'daily',            ints: ['flights'],       m: 'Track live',    act: '', kw: 'plane airport arrival departure pia' },
    { id: 'news', staple: 1,       n: 'News',             i: 'i-news',       c: 'daily', g: 'daily', adapts: 1, ints: ['news'],          m: '12 new',        act: '', kw: 'headlines stories today' },
    { id: 'cricket',    n: 'Cricket',          i: 'i-cricket',    c: 'daily', g: 'daily', adapts: 1, ints: ['cricket'],       m: 'PAK 214/4',     act: 'tool:cricket', kw: 'score match psl live wickets' },
    { id: 'emergency', staple: 1, reqCity: 1, n: 'Emergency',     i: 'i-shield',     c: 'daily', g: 'daily', adapts: 1,                          m: '15 · 1122',     act: 'tool:emergency', kw: 'police ambulance rescue fire helpline' },
    { id: 'qr',         n: 'QR Scanner',       i: 'i-qr',         c: 'daily', g: 'daily',                                     m: 'Scan & pay',    act: '', kw: 'scan barcode raast pay' },
    { id: 'docscan',    n: 'Document Scanner', i: 'i-scan',       c: 'daily', g: 'daily',            ints: ['notes'],         m: 'PDF ready',     act: '', kw: 'pdf copy paper photo' },
    { id: 'passport',   n: 'Passport Photos',  i: 'i-image',      c: 'daily', g: 'daily', adapts: 1,                          m: 'NADRA sizes',   act: '', kw: 'photo size id nadra visa' },
    { id: 'vehicle',    n: 'Vehicle & Fines',  i: 'i-car',        c: 'daily', g: 'daily', countries: ['PK'],                          m: 'Check challan', act: '', kw: 'excise token challan car bike registration' },
    { id: 'mediasaver', n: 'Media Saver',      i: 'i-download',   c: 'daily', g: 'daily',                                     m: 'Save posts',    act: '' },
    { id: 'wastatus',   n: 'WhatsApp Status',  i: 'i-message',    c: 'daily', g: 'daily', android: 1,                         m: 'Android',       act: '', kw: 'status save whatsapp' },
    { id: 'speedtest',  n: 'Speed Test',       i: 'i-wifi',       c: 'daily', g: 'daily',                                     m: 'Test now',      act: '', kw: 'internet mbps ping wifi' },

    /* ---- Personal (23) ---- */
    { id: 'parcel',     n: 'Parcel Tracker',   i: 'i-package',    c: 'personal', g: 'personal', adapts: 1, ints: ['news'],    m: '1 in transit',  act: 'tool:parcel', kw: 'tcs leopards courier delivery order cn' },
    { id: 'shopping',   n: 'Shopping List',    i: 'i-cart',       c: 'personal', g: 'personal',            ints: ['tasks'],   m: '6 items',       act: '', kw: 'groceries buy market' },
    { id: 'birthdays',  n: 'Birthdays',        i: 'i-cake',       c: 'personal', g: 'personal',            ints: ['calendar'],m: 'Ayesha in 4d',  act: '', kw: 'anniversary remember' },
    { id: 'streak',     n: 'Daily Streak',     i: 'i-flame',      c: 'personal', g: 'personal',            ints: ['habits'],  m: '12 days',       act: '' },
    { id: 'recipes',    n: 'Recipes',          i: 'i-utensils',   c: 'personal', g: 'personal',                               m: '24 saved',      act: '', kw: 'cook food meal biryani' },
    { id: 'mealplan',   n: 'Meal Planner',     i: 'i-calendar',   c: 'personal', g: 'personal',                               m: 'This week',     act: '', kw: 'food menu week' },
    { id: 'alarms',     n: 'Alarms',           i: 'i-alarm',      c: 'personal', g: 'personal',            ints: ['alarms'],  m: '2 set',         act: '', kw: 'wake up clock' },
    { id: 'learning',   n: 'Learning & Growth',i: 'i-graduation', c: 'personal', g: 'personal',            ints: ['reading'], m: '3 courses',     act: '', kw: 'study course skill' },
    { id: 'documents',  n: 'Documents',        i: 'i-folder',     c: 'personal', g: 'personal', sens: 1,                      m: 'Locked',        act: '', kw: 'id cnic passport licence file' },
    { id: 'vaccines',   n: 'Vaccinations',     i: 'i-syringe',    c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: '', kw: 'immunisation shots epi' },
    { id: 'health',     n: 'Health Records',   i: 'i-pulse',      c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: '', kw: 'medical reports blood test doctor' },
    { id: 'play',       n: 'Play',             i: 'i-play',       c: 'personal', g: 'personal',                               m: 'Puzzles',       act: '', kw: 'game puzzle break' },
    { id: 'babybudget', n: 'Baby Budget',      i: 'i-baby',       c: 'personal', g: 'personal',            ints: ['expenses'],m: 'Plan costs',    act: '' },
    { id: 'habits',     n: 'Habits',           i: 'i-flame',      c: 'personal', g: 'personal',            ints: ['habits'],  m: '12-day streak', act: '', kw: 'routine daily track' },
    { id: 'water',      n: 'Water',            i: 'i-droplet',    c: 'personal', g: 'personal',            ints: ['water'],   m: '5 / 8',         act: '', kw: 'hydration drink glasses' },
    { id: 'bmi',        n: 'BMI Calculator',   i: 'i-pulse',      c: 'personal', g: 'daily',               ints: ['fitness'], m: 'Track weight',  act: '', kw: 'weight height body mass' },
    { id: 'cycle',      n: 'Cycle Tracker',    i: 'i-cycle',      c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: '', kw: 'period menstrual women' },
    { id: 'pregnancy',  n: 'Pregnancy',        i: 'i-baby',       c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: '', kw: 'week due date women' },
    { id: 'expenses',   n: 'Expenses',         i: 'i-wallet',     c: 'personal', g: 'personal', sens: 1,  ints: ['expenses'], m: 'This month',    act: 'tool:expenses', kw: 'spending budget money track' },
    { id: 'goals',      n: 'Savings Goals',    i: 'i-target',     c: 'personal', g: 'personal', sens: 1,  ints: ['savings'],  m: '2 active',      act: '', kw: 'save target money' },
    { id: 'subs',       n: 'Subscriptions',    i: 'i-refresh',    c: 'personal', g: 'personal', sens: 1,  ints: ['expenses'], m: '6 active',    act: '', kw: 'netflix spotify recurring monthly' },
    { id: 'meds',       n: 'Medication',       i: 'i-pill',       c: 'personal', g: 'personal', sens: 1,  ints: ['meds'],     m: 'Private',       act: '', kw: 'medicine dose pills reminder tablet' }
  ];

  /* Tools-screen category headers */
  var CATEGORIES = [
    { id: 'everyday', label: 'Everyday',   icon: 'i-grid',         sub: 'The ones you reach for daily' },
    { id: 'planning', label: 'Planning',   icon: 'i-check-square', sub: 'Your time and your lists' },
    { id: 'islamic',  label: 'Islamic',    icon: 'i-moon-star',    sub: 'Prayer, Qur’an and giving', faith: 1 },
    { id: 'money',    label: 'Money',      icon: 'i-wallet',       sub: 'Rates, bills and budgets' },
    { id: 'daily',    label: 'Daily Life', icon: 'i-cloud-sun',    sub: 'What’s happening around you' },
    { id: 'personal', label: 'Personal',   icon: 'i-heart',        sub: 'Private to you, on this device' }
  ];

  /* ---------------------------------------------------------
     Content
     --------------------------------------------------------- */
  /* Weather for any of ~190 countries: a per-country override where it
     matters, otherwise a climate baseline read off the IANA zone. Demo data,
     but it must never be blank for a country we happen not to have listed. */
  var WEATHER_BY_COUNTRY = {
    PK: [34, 38, 'Hazy sun · humid', 8, 14, 'i-sun'],
    IN: [33, 37, 'Humid · light haze', 25, 12, 'i-sun'],
    GB: [21, 19, 'Mostly clear', 12, 8, 'i-cloud-sun'],
    US: [24, 24, 'Light cloud', 20, 10, 'i-cloud-sun'],
    CA: [17, 15, 'Cloudy', 35, 13, 'i-cloud-sun'],
    AE: [39, 44, 'Clear · very warm', 0, 11, 'i-sun'],
    SA: [40, 42, 'Clear', 0, 9, 'i-sun'],
    AU: [26, 26, 'Bright and breezy', 10, 18, 'i-sun'],
    DE: [18, 17, 'Overcast', 40, 11, 'i-cloud-sun'],
    FR: [21, 20, 'Sunny spells', 15, 9, 'i-cloud-sun'],
    TR: [27, 27, 'Clear', 5, 12, 'i-sun'],
    ID: [31, 35, 'Humid · showers later', 60, 7, 'i-cloud-sun'],
    MY: [32, 36, 'Humid · afternoon storms', 65, 6, 'i-cloud-sun'],
    BD: [32, 37, 'Humid', 45, 10, 'i-cloud-sun'],
    EG: [35, 36, 'Clear and dry', 0, 14, 'i-sun'],
    NG: [30, 34, 'Humid · cloud building', 55, 9, 'i-cloud-sun'],
    ZA: [22, 21, 'Clear', 10, 16, 'i-sun'],
    SG: [31, 36, 'Humid · passing showers', 60, 8, 'i-cloud-sun'],
    JP: [26, 27, 'Mild and clear', 20, 10, 'i-cloud-sun'],
    CN: [25, 26, 'Hazy sun', 25, 11, 'i-cloud-sun']
  };

  /* Fallback climate by IANA zone prefix. */
  var WEATHER_BY_ZONE = {
    Africa:   [31, 34, 'Warm and dry', 10, 11, 'i-sun'],
    Asia:     [29, 32, 'Warm', 20, 10, 'i-sun'],
    Europe:   [18, 17, 'Changeable', 35, 12, 'i-cloud-sun'],
    America:  [23, 23, 'Light cloud', 25, 11, 'i-cloud-sun'],
    Pacific:  [25, 26, 'Breezy', 30, 17, 'i-cloud-sun'],
    Indian:   [28, 30, 'Warm and humid', 35, 13, 'i-cloud-sun'],
    Atlantic: [20, 19, 'Fresh', 30, 20, 'i-cloud-sun']
  };

  function weatherFor(code, tz) {
    var w = WEATHER_BY_COUNTRY[code] ||
            WEATHER_BY_ZONE[(tz || '').split('/')[0]] ||
            WEATHER_BY_ZONE.Europe;
    return { temp: w[0], feels: w[1], desc: w[2], rain: w[3], wind: w[4], icon: w[5] };
  }

  /* A typical monthly household budget in local currency, for the markets we
     know well. Everywhere else falls back to a converted USD figure — a rate
     conversion of a Karachi budget would be nonsense in Tokyo, so the demo
     figures are anchored per market instead. */
  var BUDGET = {
    PK: 80000, IN: 45000, BD: 30000, LK: 90000, NP: 40000,
    US: 1500, CA: 1950, GB: 1200, IE: 1400, AU: 2100, NZ: 2200,
    DE: 1400, FR: 1400, ES: 1100, IT: 1200, NL: 1500, SE: 15000, NO: 17000,
    AE: 6000, SA: 5500, QA: 5500, KW: 450, OM: 550, BH: 550, JO: 700,
    TR: 25000, EG: 15000, MA: 6000, NG: 400000, KE: 60000, ZA: 15000,
    ID: 6000000, MY: 3500, PH: 30000, TH: 25000, VN: 12000000,
    JP: 180000, CN: 6000, KR: 1800000, SG: 2200, HK: 12000,
    MX: 18000, BR: 4000, AR: 500000, CL: 700000, CO: 3000000
  };

  var FUEL = [
    { n: 'Petrol',       v: '264.61', d: '+2.14' },
    { n: 'Hi-Octane',    v: '284.90', d: '+1.80' },
    { n: 'Diesel',       v: '272.98', d: '−0.65' },
    { n: 'Light Diesel', v: '160.45', d: '0.00' }
  ];

  var TRAINS = [
    { no: '5UP',  name: 'Green Line Express', from: 'Karachi Cantt', to: 'Islamabad',   dep: '22:00', arr: '17:30', dur: '19h 30m', status: 'On time',    cls: 'ok',   fare: '8,900' },
    { no: '7UP',  name: 'Tezgam Express',     from: 'Karachi Cantt', to: 'Rawalpindi',  dep: '17:00', arr: '16:15', dur: '23h 15m', status: '35m late',   cls: 'late', fare: '6,300' },
    { no: '41UP', name: 'Karakoram Express',  from: 'Karachi Cantt', to: 'Lahore',      dep: '15:00', arr: '08:45', dur: '17h 45m', status: 'On time',    cls: 'ok',   fare: '7,100' },
    { no: '27DN', name: 'Shalimar Express',   from: 'Lahore',        to: 'Karachi City',dep: '06:15', arr: '01:30', dur: '19h 15m', status: 'Departed',   cls: 'ok',   fare: '5,400' },
    { no: '101UP',name: 'Pakistan Express',   from: 'Karachi Cantt', to: 'Rawalpindi',  dep: '11:30', arr: '13:00', dur: '25h 30m', status: '1h 10m late',cls: 'late', fare: '4,850' }
  ];

  var NEWS = {
    PK: [
      { cat: 'Business', title: 'Rupee holds steady as remittances climb for a third month', meta: '4 min read', tone: 'accent' },
      { cat: 'Karachi',  title: 'K-Electric announces revised loadshedding schedule for September', meta: '3 min read', tone: 'amber' },
      { cat: 'Sport',    title: 'Pakistan name squad for the home Test series', meta: '5 min read', tone: 'violet' }
    ],
    GLOBAL: [
      { cat: 'Wellbeing',    title: 'The two-minute reset that beats a coffee break', meta: '4 min read', tone: 'accent' },
      { cat: 'Productivity', title: 'Why a shorter to-do list finishes more work', meta: '6 min read', tone: 'violet' },
      { cat: 'Money',        title: 'A plain-English guide to your first savings goal', meta: '8 min read', tone: 'amber' }
    ]
  };

  /* Urdu and Arabic ship an `f.<id>` name for every feature; English never
     did, because the catalogue already holds it. Any screen calling
     t('f.bills') directly therefore rendered the raw key in English. The
     catalogue is the source of truth (§19), so it seeds the dictionary from
     itself rather than repeating 85 names in a second file. */
  (function seedFeatureNames() {
    var I = window.LUME_I18N;
    if (!I || !I.DICTS || !I.DICTS.en) return;
    F.forEach(function (f) {
      var key = 'f.' + f.id;
      if (I.DICTS.en[key] === undefined) I.DICTS.en[key] = f.n;
    });
  })();

  return {
    INTEREST_GROUPS: INTEREST_GROUPS,
    FAITH_INTERESTS: FAITH_INTERESTS,
    DEFAULT_INTERESTS: DEFAULT_INTERESTS,
    FEATURES: F,
    CATEGORIES: CATEGORIES,
    weatherFor: weatherFor,
    BUDGET: BUDGET,
    FUEL: FUEL,
    TRAINS: TRAINS,
    NEWS: NEWS
  };
})();
