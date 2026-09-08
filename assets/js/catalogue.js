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
       sh         tool shape — decides which journey shell it uses
       sens   sensitive — never promoted on Home
       staple a tool almost everyone wants, so it survives the For-you filter
     --------------------------------------------------------- */
  var F = [
    /* ---- Everyday ---- */
    { id: 'calculator', sh: 'calculator', staple: 1, n: 'Calculator',       i: 'i-calculator', c: 'everyday', g: 'daily',    ints: ['maths'],              m: 'Standard',      act: 'tool:calculator', kw: 'maths sum arithmetic percent' },
    { id: 'converter', sh: 'calculator', staple: 1,  n: 'Unit Converter',   i: 'i-ruler',      c: 'everyday', g: 'daily',    ints: ['convert'],            m: '32 units',      act: 'tool:converter', kw: 'length weight metric imperial litres kg' },
    { id: 'currency', sh: 'calculator', staple: 1,   n: 'Currency',         i: 'i-currency',   c: 'everyday', g: 'money',    ints: ['convert', 'rates'],   m: 'Live rates',    act: 'tool:currency', kw: 'exchange forex dollar usd pkr riyal pound convert money' },
    { id: 'stopwatch', sh: 'timer',  n: 'Stopwatch',        i: 'i-stopwatch',  c: 'everyday', g: 'daily',    ints: ['alarms'],             m: 'Laps',          act: 'tool:stopwatch' },
    { id: 'timer', sh: 'timer', staple: 1,      n: 'Timer',            i: 'i-timer',      c: 'everyday', g: 'daily',    ints: ['alarms'],             m: 'Presets',       act: 'tool:timer' },
    { id: 'age', sh: 'calculator',        n: 'Age Calculator',   i: 'i-cake',       c: 'everyday', g: 'daily',    ints: ['maths'],              m: 'Exact days',    act: 'tool:age', kw: 'birthday how old years' },
    { id: 'datecalc', sh: 'calculator',   n: 'Date Calculator',  i: 'i-calendar',   c: 'everyday', g: 'daily',    ints: ['maths', 'calendar'],  m: 'Add · diff',    act: 'tool:datecalc', kw: 'days between duration' },

    /* ---- Planning ---- */
    { id: 'calendar', sh: 'custom', staple: 1,   n: 'Calendar',         i: 'i-calendar',   c: 'planning', g: 'daily',    ints: ['calendar'],           m: '3 events',      act: 'tool:calendar', kw: 'schedule agenda month' },
    { id: 'reminders', sh: 'list', staple: 1,  n: 'Reminders',        i: 'i-bell-ring',  c: 'planning', g: 'personal', ints: ['tasks'],              m: '4 today',       act: 'tool:reminders' },
    { id: 'notes', sh: 'list', staple: 1,      n: 'Notes',            i: 'i-note',       c: 'planning', g: 'personal', ints: ['notes'],              m: '12 saved',      act: 'tool:notes', kw: 'write memo journal' },
    { id: 'todos', sh: 'list', staple: 1,      n: 'To-dos',           i: 'i-check-square',c: 'planning',g: 'personal', ints: ['tasks'],              m: '2 of 5 done',   act: 'tool:todos', kw: 'task checklist' },
    { id: 'events', sh: 'list',     n: 'Events',           i: 'i-list',       c: 'planning', g: 'daily',    ints: ['calendar'],           m: 'Next 14:00',    act: 'tool:events' },

    /* ---- Prayer & Islam (17) ---- */
    { id: 'prayer', sh: 'custom', staple: 1, reqCity: 1,     n: 'Prayer Times',     i: 'i-prayer',     c: 'islamic', g: 'islam', faith: 1, ints: ['prayer'],       m: 'Asr 15:53',     act: 'tool:prayer', kw: 'salah namaz adhan azan jamaat' },
    { id: 'qibla', sh: 'custom', staple: 1, reqCity: 1,      n: 'Qibla Compass',    i: 'i-navigation', c: 'islamic', g: 'islam', faith: 1, ints: ['prayer'],       m: '267° W',        act: 'tool:qibla', kw: 'direction kaaba mecca makkah compass' },
    { id: 'mosques', sh: 'custom', reqCity: 1,    n: 'Nearby Mosques',   i: 'i-mosque',     c: 'islamic', g: 'islam', faith: 1, ints: ['prayer', 'nearby'], m: '3 within 1 km', act: 'tool:mosques' },
    { id: 'praytrack', sh: 'tracker',  n: 'Prayer Tracker',   i: 'i-check-circle',c: 'islamic',g: 'islam', faith: 1, ints: ['prayer', 'habits'], m: '12-day streak', act: 'tool:praytrack' },
    { id: 'ramadan', sh: 'custom',    n: 'Ramadan',          i: 'i-moon-star',  c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan'],      m: 'In 172 days',   act: 'tool:ramadan', kw: 'sehri iftar' },
    { id: 'fasting', sh: 'tracker',    n: 'Fasting Tracker',  i: 'i-moon',       c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan'],      m: '3 kept',        act: 'tool:fasting', kw: 'roza sawm' },
    { id: 'taraweeh', sh: 'tracker',   n: 'Taraweeh',         i: 'i-prayer',     c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan', 'prayer'], m: 'Ramadan',  act: 'tool:taraweeh' },
    { id: 'ayah', sh: 'reader', shareable: 1,       n: 'Ayah of the Day',  i: 'i-sparkles',   c: 'islamic', g: 'islam', faith: 1, ints: ['quran'],        m: 'Ar-Ra’d 28',    act: 'tool:ayah', kw: 'verse daily' },
    { id: 'quran', sh: 'reader', staple: 1, shareable: 1,      n: 'Al-Qur’an',        i: 'i-book',       c: 'islamic', g: 'islam', faith: 1, ints: ['quran', 'reading'], m: 'Al-Kahf 42', act: 'tool:quran', kw: 'surah para juz recite mushaf' },
    { id: 'quransearch', sh: 'reader', n: 'Search the Qur’an',i: 'i-search',     c: 'islamic', g: 'islam', faith: 1, ints: ['quran'],        m: 'By word',       act: 'tool:quransearch', kw: 'surah rahman yaseen ayah verse find' },
    { id: 'hadith', sh: 'reader', shareable: 1,     n: 'Hadith',           i: 'i-quote',      c: 'islamic', g: 'islam', faith: 1, ints: ['hadith', 'reading'], m: 'Daily',    act: 'tool:hadith', kw: 'bukhari muslim sunnah' },
    { id: 'duas', sh: 'reader', shareable: 1,       n: 'Daily Duas',       i: 'i-heart',      c: 'islamic', g: 'islam', faith: 1, ints: ['duas'],         m: '42 saved',      act: 'tool:duas', kw: 'supplication dua azkar' },
    { id: 'names99', sh: 'reader', shareable: 1,    n: '99 Names',         i: 'i-star',       c: 'islamic', g: 'islam', faith: 1, ints: ['duas', 'quran'], m: 'Asma ul Husna', act: 'tool:names99' },
    { id: 'hijri', sh: 'custom',      n: 'Islamic Calendar', i: 'i-moon',       c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan', 'calendar'], m: '15 Rabi’ I', act: 'tool:hijri', kw: 'hijri date lunar' },
    { id: 'tasbih', sh: 'timer', staple: 1,     n: 'Tasbih',           i: 'i-beads',      c: 'islamic', g: 'islam', faith: 1, ints: ['duas'],         m: 'Counter',       act: 'tool:tasbih', kw: 'dhikr zikr counter beads tasbeeh' },
    { id: 'zakat', sh: 'calculator',      n: 'Zakat Calculator', i: 'i-wallet',     c: 'islamic', g: 'islam', faith: 1, ints: ['zakat'],        m: 'Nisab check',   act: 'tool:zakat', kw: 'charity sadaqah nisab giving' },
    { id: 'faraid', sh: 'calculator',     n: 'Faraid',           i: 'i-scales',     c: 'islamic', g: 'islam', faith: 1, ints: ['zakat'],        m: 'Inheritance',   act: 'tool:faraid', kw: 'inheritance mirath wirasat will' },

    /* ---- Money & Rates (14) ---- */
    { id: 'goldrates', sh: 'data',  n: 'Currency & Gold',  i: 'i-coins',      c: 'money', g: 'money', countries: ['PK'], ints: ['rates'],         m: 'Tola ₨ 258,400', act: 'tool:goldrates', kw: 'sona gold silver dollar rate open market' },
    { id: 'markets', sh: 'data',    n: 'Markets',          i: 'i-trending',   c: 'money', g: 'money',            ints: ['markets'],       m: 'KSE-100 ▲ 0.8%', act: 'tool:markets', kw: 'stocks shares psx index' },
    { id: 'fuel', sh: 'data',       n: 'Fuel Prices',      i: 'i-fuel',       c: 'money', g: 'money', countries: ['PK'], ints: ['fuel'],          m: '₨ 264.61',      act: 'tool:fuel', kw: 'petrol diesel price ogra pump' },
    { id: 'fuelcost', sh: 'calculator',   n: 'Fuel Cost',        i: 'i-route',      c: 'money', g: 'money', countries: ['PK'], ints: ['fuel'],          m: 'Trip cost',     act: 'tool:fuelcost', kw: 'petrol trip mileage average' },
    { id: 'tax', sh: 'calculator',        n: 'Tax Calculator',   i: 'i-percent',    c: 'money', g: 'money', countries: ['PK'], ints: ['expenses'],      m: 'FBR 2025-26',   act: 'tool:tax', kw: 'salary income fbr slab withholding' },
    { id: 'natsavings', sh: 'data', n: 'National Savings', i: 'i-shield',     c: 'money', g: 'money', countries: ['PK'], ints: ['savings'],       m: 'Profit rates',  act: 'tool:natsavings', kw: 'behbood pensioners defence certificate' },
    { id: 'prizebonds', sh: 'data', n: 'Prize Bonds',      i: 'i-ticket',     c: 'money', g: 'money', countries: ['PK'], ints: ['savings'],       m: 'Draw 15 Sep',   act: 'tool:prizebonds', kw: 'bond draw result winner' },
    { id: 'bills', sh: 'list',      n: 'Bills',            i: 'i-receipt',    c: 'money', g: 'money', countries: ['PK'], ints: ['bills'],         m: '2 due',         act: 'tool:bills', kw: 'k-electric sui gas wapda ptcl electricity due' },
    { id: 'packages', sh: 'data',   n: 'Mobile Packages',  i: 'i-signal',     c: 'money', g: 'money', countries: ['PK'], ints: ['bills'],         m: 'Jazz · Zong',   act: 'tool:packages', kw: 'jazz zong ufone telenor balance load mbs' },
    { id: 'loan', sh: 'calculator',       n: 'Loan / EMI',       i: 'i-bank',       c: 'money', g: 'money',            ints: ['expenses'],      m: 'Instalments',   act: 'tool:loan', kw: 'emi mortgage interest markup car finance' },
    { id: 'tipsplit', sh: 'calculator',   n: 'Tip & Split',      i: 'i-divide',     c: 'money', g: 'money',            ints: ['expenses'],      m: 'Split a bill',  act: 'tool:tipsplit', kw: 'bill share restaurant' },
    { id: 'ledger', sh: 'list',     n: 'Lending Ledger',   i: 'i-list',       c: 'money', g: 'money',            ints: ['expenses'],      m: '₨ 8,500 out',   act: 'tool:ledger', kw: 'udhaar borrow lend owe khata' },
    { id: 'installments', sh: 'list', n:'Installments',     i: 'i-calendar',   c: 'money', g: 'money',            ints: ['expenses'],      m: '3 running',     act: 'tool:installments' },
    { id: 'committee', sh: 'list',  n: 'Committee',        i: 'i-users',      c: 'money', g: 'money',            ints: ['savings'],       m: 'Month 4 of 10', act: 'tool:committee', kw: 'bisi rosca kameti pool circle' },

    /* ---- Daily Life (18) ---- */
    { id: 'weather', sh: 'data', staple: 1, reqCity: 1,    n: 'Weather',          i: 'i-cloud-sun',  c: 'daily', g: 'daily', adapts: 1, ints: ['weather'],       m: '34° Clear',     act: 'tool:weather', kw: 'forecast rain temperature humid' },
    { id: 'loadshed', sh: 'data', reqCity: 1,   n: 'Loadshedding',     i: 'i-bolt',       c: 'daily', g: 'daily', countries: ['PK'], ints: ['bills'],         m: '14:00–16:00',   act: 'tool:loadshed', kw: 'bijli power outage schedule ke lesco' },
    { id: 'trains', sh: 'data', reqCity: 1,     n: 'Trains',           i: 'i-train',      c: 'daily', g: 'daily', countries: ['PK'], ints: ['trains'],        m: 'Green Line',    act: 'tab:trains', kw: 'railway pr green line tezgam bogie seat pnr' },
    { id: 'flights', sh: 'data',    n: 'Flights',          i: 'i-plane',      c: 'daily', g: 'daily',            ints: ['flights'],       m: 'Track live',    act: 'tool:flights', kw: 'plane airport arrival departure pia' },
    { id: 'news', sh: 'data', staple: 1,       n: 'News',             i: 'i-news',       c: 'daily', g: 'daily', adapts: 1, ints: ['news'],          m: '12 new',        act: 'tool:news', kw: 'headlines stories today' },
    { id: 'cricket', sh: 'data',    n: 'Cricket',          i: 'i-cricket',    c: 'daily', g: 'daily', adapts: 1, ints: ['cricket'],       m: 'PAK 214/4',     act: 'tool:cricket', kw: 'score match psl live wickets' },
    { id: 'emergency', sh: 'data',  n: 'Emergency',        i: 'i-shield',     c: 'daily', g: 'daily', countries: ['PK'],                          m: '15 · 1122',     act: 'tool:emergency', kw: 'police ambulance rescue fire helpline' },
    { id: 'qr', sh: 'scanner',         n: 'QR Scanner',       i: 'i-qr',         c: 'daily', g: 'daily',                                     m: 'Scan & pay',    act: 'tool:qr', kw: 'scan barcode raast pay' },
    { id: 'docscan', sh: 'scanner',    n: 'Document Scanner', i: 'i-scan',       c: 'daily', g: 'daily',            ints: ['notes'],         m: 'PDF ready',     act: 'tool:docscan', kw: 'pdf copy paper photo' },
    { id: 'passport', sh: 'scanner',   n: 'Passport Photos',  i: 'i-image',      c: 'daily', g: 'daily', adapts: 1,                          m: 'NADRA sizes',   act: 'tool:passport', kw: 'photo size id nadra visa' },
    { id: 'vehicle', sh: 'data',    n: 'Vehicle & Fines',  i: 'i-car',        c: 'daily', g: 'daily', countries: ['PK'],                          m: 'Check challan', act: 'tool:vehicle', kw: 'excise token challan car bike registration' },
    { id: 'mediasaver', sh: 'scanner', n: 'Media Saver',      i: 'i-download',   c: 'daily', g: 'daily',                                     m: 'Save posts',    act: 'tool:mediasaver' },
    { id: 'wastatus', sh: 'scanner',   n: 'WhatsApp Status',  i: 'i-message',    c: 'daily', g: 'daily', android: 1,                         m: 'Android',       act: 'tool:wastatus', kw: 'status save whatsapp' },
    { id: 'speedtest', sh: 'data',  n: 'Speed Test',       i: 'i-wifi',       c: 'daily', g: 'daily',                                     m: 'Test now',      act: 'tool:speedtest', kw: 'internet mbps ping wifi' },

    /* ---- Personal (23) ---- */
    { id: 'parcel', sh: 'list',     n: 'Parcel Tracker',   i: 'i-package',    c: 'personal', g: 'personal', countries: ['PK'], ints: ['news'],    m: '1 in transit',  act: 'tool:parcel', kw: 'tcs leopards courier delivery order cn' },
    { id: 'shopping', sh: 'list',   n: 'Shopping List',    i: 'i-cart',       c: 'personal', g: 'personal',            ints: ['tasks'],   m: '6 items',       act: 'tool:shopping', kw: 'groceries buy market' },
    { id: 'birthdays', sh: 'list',  n: 'Birthdays',        i: 'i-cake',       c: 'personal', g: 'personal',            ints: ['calendar'],m: 'Ayesha in 4d',  act: 'tool:birthdays', kw: 'anniversary remember' },
    { id: 'streak', sh: 'tracker',     n: 'Daily Streak',     i: 'i-flame',      c: 'personal', g: 'personal',            ints: ['habits'],  m: '12 days',       act: 'tool:streak' },
    { id: 'recipes', sh: 'list',    n: 'Recipes',          i: 'i-utensils',   c: 'personal', g: 'personal',                               m: '24 saved',      act: 'tool:recipes', kw: 'cook food meal biryani' },
    { id: 'mealplan', sh: 'list',   n: 'Meal Planner',     i: 'i-calendar',   c: 'personal', g: 'personal',                               m: 'This week',     act: 'tool:mealplan', kw: 'food menu week' },
    { id: 'alarms', sh: 'list',     n: 'Alarms',           i: 'i-alarm',      c: 'personal', g: 'personal',            ints: ['alarms'],  m: '2 set',         act: 'tool:alarms', kw: 'wake up clock' },
    { id: 'learning', sh: 'list',   n: 'Learning & Growth',i: 'i-graduation', c: 'personal', g: 'personal',            ints: ['reading'], m: '3 courses',     act: 'tool:learning', kw: 'study course skill' },
    { id: 'documents', sh: 'list',  n: 'Documents',        i: 'i-folder',     c: 'personal', g: 'personal', sens: 1,                      m: 'Locked',        act: 'tool:documents', kw: 'id cnic passport licence file' },
    { id: 'vaccines', sh: 'list',   n: 'Vaccinations',     i: 'i-syringe',    c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: 'tool:vaccines', kw: 'immunisation shots epi' },
    { id: 'health', sh: 'list',     n: 'Health Records',   i: 'i-pulse',      c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: 'tool:health', kw: 'medical reports blood test doctor' },
    { id: 'play', sh: 'custom',       n: 'Play',             i: 'i-play',       c: 'personal', g: 'personal',                               m: 'Puzzles',       act: 'tool:play', kw: 'game puzzle break' },
    { id: 'babybudget', sh: 'list', n: 'Baby Budget',      i: 'i-baby',       c: 'personal', g: 'personal',            ints: ['expenses'],m: 'Plan costs',    act: 'tool:babybudget' },
    { id: 'habits', sh: 'tracker',     n: 'Habits',           i: 'i-flame',      c: 'personal', g: 'personal',            ints: ['habits'],  m: '12-day streak', act: 'tool:habits', kw: 'routine daily track' },
    { id: 'water', sh: 'tracker',      n: 'Water',            i: 'i-droplet',    c: 'personal', g: 'personal',            ints: ['water'],   m: '5 / 8',         act: 'tool:water', kw: 'hydration drink glasses' },
    { id: 'bmi', sh: 'calculator',        n: 'BMI Calculator',   i: 'i-pulse',      c: 'personal', g: 'daily',               ints: ['fitness'], m: 'Track weight',  act: 'tool:bmi', kw: 'weight height body mass' },
    { id: 'cycle', sh: 'tracker',      n: 'Cycle Tracker',    i: 'i-cycle',      c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: 'tool:cycle', kw: 'period menstrual women' },
    { id: 'pregnancy', sh: 'tracker',  n: 'Pregnancy',        i: 'i-baby',       c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: 'tool:pregnancy', kw: 'week due date women' },
    { id: 'expenses', sh: 'list',   n: 'Expenses',         i: 'i-wallet',     c: 'personal', g: 'personal', sens: 1,  ints: ['expenses'], m: 'This month',    act: 'tool:expenses', kw: 'spending budget money track' },
    { id: 'goals', sh: 'list',      n: 'Savings Goals',    i: 'i-target',     c: 'personal', g: 'personal', sens: 1,  ints: ['savings'],  m: '2 active',      act: 'tool:goals', kw: 'save target money' },
    { id: 'subs', sh: 'list',       n: 'Subscriptions',    i: 'i-refresh',    c: 'personal', g: 'personal', sens: 1,  ints: ['expenses'], m: '₨ 4,200/mo',    act: 'tool:subs', kw: 'netflix spotify recurring monthly' },
    { id: 'meds', sh: 'list',       n: 'Medication',       i: 'i-pill',       c: 'personal', g: 'personal', sens: 1,  ints: ['meds'],     m: 'Private',       act: 'tool:meds', kw: 'medicine dose pills reminder tablet' }
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
