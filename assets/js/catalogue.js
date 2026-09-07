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
     Countries
     --------------------------------------------------------- */
  var COUNTRIES = [
    { code: 'PK', name: 'Pakistan',       cities: ['Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad', 'Peshawar', 'Multan', 'Quetta'], cur: '₨', curCode: 'PKR' },
    { code: 'GB', name: 'United Kingdom', cities: ['London', 'Manchester', 'Birmingham', 'Glasgow'], cur: '£', curCode: 'GBP' },
    { code: 'AE', name: 'UAE',            cities: ['Dubai', 'Abu Dhabi', 'Sharjah'], cur: 'AED ', curCode: 'AED' },
    { code: 'US', name: 'United States',  cities: ['New York', 'Chicago', 'Houston', 'Los Angeles'], cur: '$', curCode: 'USD' },
    { code: 'CA', name: 'Canada',         cities: ['Toronto', 'Vancouver', 'Calgary'], cur: 'C$', curCode: 'CAD' },
    { code: 'SA', name: 'Saudi Arabia',   cities: ['Riyadh', 'Jeddah', 'Makkah', 'Madinah'], cur: 'SAR ', curCode: 'SAR' }
  ];

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
       loc    country code — hidden unless the user is there
       adapts global feature whose content localises
       sens   sensitive — never promoted on Home
     --------------------------------------------------------- */
  var F = [
    /* ---- Everyday ---- */
    { id: 'calculator', n: 'Calculator',       i: 'i-calculator', c: 'everyday', g: 'daily',    ints: ['maths'],              m: 'Standard',      act: 'sheet:calculator', kw: 'maths sum arithmetic percent' },
    { id: 'converter',  n: 'Unit Converter',   i: 'i-ruler',      c: 'everyday', g: 'daily',    ints: ['convert'],            m: '32 units',      act: 'toast:Unit converter · 32 units', kw: 'length weight metric imperial litres kg' },
    { id: 'currency',   n: 'Currency',         i: 'i-currency',   c: 'everyday', g: 'money',    ints: ['convert', 'rates'],   m: 'Live rates',    act: 'sheet:currency', kw: 'exchange forex dollar usd pkr riyal pound convert money' },
    { id: 'stopwatch',  n: 'Stopwatch',        i: 'i-stopwatch',  c: 'everyday', g: 'daily',    ints: ['alarms'],             m: 'Laps',          act: 'toast:Stopwatch ready' },
    { id: 'timer',      n: 'Timer',            i: 'i-timer',      c: 'everyday', g: 'daily',    ints: ['alarms'],             m: 'Presets',       act: 'toast:Timer ready — 00:00' },
    { id: 'age',        n: 'Age Calculator',   i: 'i-cake',       c: 'everyday', g: 'daily',    ints: ['maths'],              m: 'Exact days',    act: 'toast:Age calculator', kw: 'birthday how old years' },
    { id: 'datecalc',   n: 'Date Calculator',  i: 'i-calendar',   c: 'everyday', g: 'daily',    ints: ['maths', 'calendar'],  m: 'Add · diff',    act: 'toast:Date calculator', kw: 'days between duration' },

    /* ---- Planning ---- */
    { id: 'calendar',   n: 'Calendar',         i: 'i-calendar',   c: 'planning', g: 'daily',    ints: ['calendar'],           m: '3 events',      act: 'tab:today', kw: 'schedule agenda month' },
    { id: 'reminders',  n: 'Reminders',        i: 'i-bell-ring',  c: 'planning', g: 'personal', ints: ['tasks'],              m: '4 today',       act: 'toast:4 reminders today' },
    { id: 'notes',      n: 'Notes',            i: 'i-note',       c: 'planning', g: 'personal', ints: ['notes'],              m: '12 saved',      act: 'toast:Notes — 12 saved', kw: 'write memo journal' },
    { id: 'todos',      n: 'To-dos',           i: 'i-check-square',c: 'planning',g: 'personal', ints: ['tasks'],              m: '2 of 5 done',   act: 'tab:today', kw: 'task checklist' },
    { id: 'events',     n: 'Events',           i: 'i-list',       c: 'planning', g: 'daily',    ints: ['calendar'],           m: 'Next 14:00',    act: 'toast:Next: Design review, 14:00' },

    /* ---- Prayer & Islam (17) ---- */
    { id: 'prayer',     n: 'Prayer Times',     i: 'i-prayer',     c: 'islamic', g: 'islam', faith: 1, ints: ['prayer'],       m: 'Asr 15:53',     act: 'sheet:prayer', kw: 'salah namaz adhan azan jamaat' },
    { id: 'qibla',      n: 'Qibla Compass',    i: 'i-navigation', c: 'islamic', g: 'islam', faith: 1, ints: ['prayer'],       m: '267° W',        act: 'sheet:qibla', kw: 'direction kaaba mecca makkah compass' },
    { id: 'mosques',    n: 'Nearby Mosques',   i: 'i-mosque',     c: 'islamic', g: 'islam', faith: 1, ints: ['prayer', 'nearby'], m: '3 within 1 km', act: 'toast:3 mosques within 1 km' },
    { id: 'praytrack',  n: 'Prayer Tracker',   i: 'i-check-circle',c: 'islamic',g: 'islam', faith: 1, ints: ['prayer', 'habits'], m: '12-day streak', act: 'sheet:prayer' },
    { id: 'ramadan',    n: 'Ramadan',          i: 'i-moon-star',  c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan'],      m: 'In 172 days',   act: 'toast:Ramadan begins in 172 days', kw: 'sehri iftar' },
    { id: 'fasting',    n: 'Fasting Tracker',  i: 'i-moon',       c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan'],      m: '3 kept',        act: 'toast:Fasting tracker — 3 kept this month', kw: 'roza sawm' },
    { id: 'taraweeh',   n: 'Taraweeh',         i: 'i-prayer',     c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan', 'prayer'], m: 'Ramadan',  act: 'toast:Taraweeh tracker' },
    { id: 'ayah',       n: 'Ayah of the Day',  i: 'i-sparkles',   c: 'islamic', g: 'islam', faith: 1, ints: ['quran'],        m: 'Ar-Ra’d 28',    act: 'tab:today', kw: 'verse daily' },
    { id: 'quran',      n: 'Al-Qur’an',        i: 'i-book',       c: 'islamic', g: 'islam', faith: 1, ints: ['quran', 'reading'], m: 'Al-Kahf 42', act: 'sheet:reading', kw: 'surah para juz recite mushaf' },
    { id: 'quransearch',n: 'Search the Qur’an',i: 'i-search',     c: 'islamic', g: 'islam', faith: 1, ints: ['quran'],        m: 'By word',       act: 'sheet:search', kw: 'surah rahman yaseen ayah verse find' },
    { id: 'hadith',     n: 'Hadith',           i: 'i-quote',      c: 'islamic', g: 'islam', faith: 1, ints: ['hadith', 'reading'], m: 'Daily',    act: 'tab:today', kw: 'bukhari muslim sunnah' },
    { id: 'duas',       n: 'Daily Duas',       i: 'i-heart',      c: 'islamic', g: 'islam', faith: 1, ints: ['duas'],         m: '42 saved',      act: 'toast:42 duas in your library', kw: 'supplication dua azkar' },
    { id: 'names99',    n: '99 Names',         i: 'i-star',       c: 'islamic', g: 'islam', faith: 1, ints: ['duas', 'quran'], m: 'Asma ul Husna', act: 'toast:99 Names of Allah' },
    { id: 'hijri',      n: 'Islamic Calendar', i: 'i-moon',       c: 'islamic', g: 'islam', faith: 1, ints: ['ramadan', 'calendar'], m: '15 Rabi’ I', act: 'toast:15 Rabi’ al-Awwal 1448', kw: 'hijri date lunar' },
    { id: 'tasbih',     n: 'Tasbih',           i: 'i-beads',      c: 'islamic', g: 'islam', faith: 1, ints: ['duas'],         m: 'Counter',       act: 'sheet:tasbeeh', kw: 'dhikr zikr counter beads tasbeeh' },
    { id: 'zakat',      n: 'Zakat Calculator', i: 'i-wallet',     c: 'islamic', g: 'islam', faith: 1, ints: ['zakat'],        m: 'Nisab check',   act: 'toast:Zakat calculator — nisab ₨ 258,400', kw: 'charity sadaqah nisab giving' },
    { id: 'faraid',     n: 'Faraid',           i: 'i-scales',     c: 'islamic', g: 'islam', faith: 1, ints: ['zakat'],        m: 'Inheritance',   act: 'toast:Faraid — inheritance shares', kw: 'inheritance mirath wirasat will' },

    /* ---- Money & Rates (14) ---- */
    { id: 'goldrates',  n: 'Currency & Gold',  i: 'i-coins',      c: 'money', g: 'money', loc: 'PK', ints: ['rates'],         m: 'Tola ₨ 258,400', act: 'sheet:rates', kw: 'sona gold silver dollar rate open market' },
    { id: 'markets',    n: 'Markets',          i: 'i-trending',   c: 'money', g: 'money',            ints: ['markets'],       m: 'KSE-100 ▲ 0.8%', act: 'toast:KSE-100 · 78,412 ▲ 0.8%', kw: 'stocks shares psx index' },
    { id: 'fuel',       n: 'Fuel Prices',      i: 'i-fuel',       c: 'money', g: 'money', loc: 'PK', ints: ['fuel'],          m: '₨ 264.61',      act: 'sheet:fuel', kw: 'petrol diesel price ogra pump' },
    { id: 'fuelcost',   n: 'Fuel Cost',        i: 'i-route',      c: 'money', g: 'money', loc: 'PK', ints: ['fuel'],          m: 'Trip cost',     act: 'toast:Karachi → Hyderabad · ₨ 2,380', kw: 'petrol trip mileage average' },
    { id: 'tax',        n: 'Tax Calculator',   i: 'i-percent',    c: 'money', g: 'money', loc: 'PK', ints: ['expenses'],      m: 'FBR 2025-26',   act: 'sheet:tax', kw: 'salary income fbr slab withholding' },
    { id: 'natsavings', n: 'National Savings', i: 'i-shield',     c: 'money', g: 'money', loc: 'PK', ints: ['savings'],       m: 'Profit rates',  act: 'toast:Behbood · 15.36% · profit ₨ 1,280/mo', kw: 'behbood pensioners defence certificate' },
    { id: 'prizebonds', n: 'Prize Bonds',      i: 'i-ticket',     c: 'money', g: 'money', loc: 'PK', ints: ['savings'],       m: 'Draw 15 Sep',   act: 'toast:Next ₨ 750 draw — 15 September', kw: 'bond draw result winner' },
    { id: 'bills',      n: 'Bills',            i: 'i-receipt',    c: 'money', g: 'money', loc: 'PK', ints: ['bills'],         m: '2 due',         act: 'sheet:bills', kw: 'k-electric sui gas wapda ptcl electricity due' },
    { id: 'packages',   n: 'Mobile Packages',  i: 'i-signal',     c: 'money', g: 'money', loc: 'PK', ints: ['bills'],         m: 'Jazz · Zong',   act: 'toast:Compare Jazz, Zong, Ufone & Telenor', kw: 'jazz zong ufone telenor balance load mbs' },
    { id: 'loan',       n: 'Loan / EMI',       i: 'i-bank',       c: 'money', g: 'money',            ints: ['expenses'],      m: 'Instalments',   act: 'toast:Loan & EMI calculator', kw: 'emi mortgage interest markup car finance' },
    { id: 'tipsplit',   n: 'Tip & Split',      i: 'i-divide',     c: 'money', g: 'money',            ints: ['expenses'],      m: 'Split a bill',  act: 'toast:Split a bill between friends', kw: 'bill share restaurant' },
    { id: 'ledger',     n: 'Lending Ledger',   i: 'i-list',       c: 'money', g: 'money',            ints: ['expenses'],      m: '₨ 8,500 out',   act: 'toast:₨ 8,500 lent · 3 people', kw: 'udhaar borrow lend owe khata' },
    { id: 'installments',n:'Installments',     i: 'i-calendar',   c: 'money', g: 'money',            ints: ['expenses'],      m: '3 running',     act: 'toast:3 instalment plans running' },
    { id: 'committee',  n: 'Committee',        i: 'i-users',      c: 'money', g: 'money',            ints: ['savings'],       m: 'Month 4 of 10', act: 'toast:Committee — your turn in month 7', kw: 'bisi rosca kameti pool circle' },

    /* ---- Daily Life (18) ---- */
    { id: 'weather',    n: 'Weather',          i: 'i-cloud-sun',  c: 'daily', g: 'daily', adapts: 1, ints: ['weather'],       m: '34° Clear',     act: 'tab:explore', kw: 'forecast rain temperature humid' },
    { id: 'loadshed',   n: 'Loadshedding',     i: 'i-bolt',       c: 'daily', g: 'daily', loc: 'PK', ints: ['bills'],         m: '14:00–16:00',   act: 'sheet:loadshed', kw: 'bijli power outage schedule ke lesco' },
    { id: 'trains',     n: 'Trains',           i: 'i-train',      c: 'daily', g: 'daily', loc: 'PK', ints: ['trains'],        m: 'Green Line',    act: 'tab:trains', kw: 'railway pr green line tezgam bogie seat pnr' },
    { id: 'flights',    n: 'Flights',          i: 'i-plane',      c: 'daily', g: 'daily',            ints: ['flights'],       m: 'Track live',    act: 'toast:Track a flight by number or route', kw: 'plane airport arrival departure pia' },
    { id: 'news',       n: 'News',             i: 'i-news',       c: 'daily', g: 'daily', adapts: 1, ints: ['news'],          m: '12 new',        act: 'tab:explore', kw: 'headlines stories today' },
    { id: 'cricket',    n: 'Cricket',          i: 'i-cricket',    c: 'daily', g: 'daily', adapts: 1, ints: ['cricket'],       m: 'PAK 214/4',     act: 'sheet:cricket', kw: 'score match psl live wickets' },
    { id: 'emergency',  n: 'Emergency',        i: 'i-shield',     c: 'daily', g: 'daily', loc: 'PK',                          m: '15 · 1122',     act: 'sheet:emergency', kw: 'police ambulance rescue fire helpline' },
    { id: 'qr',         n: 'QR Scanner',       i: 'i-qr',         c: 'daily', g: 'daily',                                     m: 'Scan & pay',    act: 'toast:Point the camera at a QR code', kw: 'scan barcode raast pay' },
    { id: 'docscan',    n: 'Document Scanner', i: 'i-scan',       c: 'daily', g: 'daily',            ints: ['notes'],         m: 'PDF ready',     act: 'toast:Scan to PDF', kw: 'pdf copy paper photo' },
    { id: 'passport',   n: 'Passport Photos',  i: 'i-image',      c: 'daily', g: 'daily', adapts: 1,                          m: 'NADRA sizes',   act: 'toast:Passport photo — NADRA & ICAO sizes', kw: 'photo size id nadra visa' },
    { id: 'vehicle',    n: 'Vehicle & Fines',  i: 'i-car',        c: 'daily', g: 'daily', loc: 'PK',                          m: 'Check challan', act: 'toast:Enter a registration number', kw: 'excise token challan car bike registration' },
    { id: 'mediasaver', n: 'Media Saver',      i: 'i-download',   c: 'daily', g: 'daily',                                     m: 'Save posts',    act: 'toast:Paste a link to save it' },
    { id: 'wastatus',   n: 'WhatsApp Status',  i: 'i-message',    c: 'daily', g: 'daily', android: 1,                         m: 'Android',       act: 'toast:Status saver — Android only', kw: 'status save whatsapp' },
    { id: 'speedtest',  n: 'Speed Test',       i: 'i-wifi',       c: 'daily', g: 'daily',                                     m: 'Test now',      act: 'toast:Testing — 48.2 Mbps down', kw: 'internet mbps ping wifi' },

    /* ---- Personal (23) ---- */
    { id: 'parcel',     n: 'Parcel Tracker',   i: 'i-package',    c: 'personal', g: 'personal', loc: 'PK', ints: ['news'],    m: '1 in transit',  act: 'sheet:parcel', kw: 'tcs leopards courier delivery order cn' },
    { id: 'shopping',   n: 'Shopping List',    i: 'i-cart',       c: 'personal', g: 'personal',            ints: ['tasks'],   m: '6 items',       act: 'toast:Shopping list — 6 items', kw: 'groceries buy market' },
    { id: 'birthdays',  n: 'Birthdays',        i: 'i-cake',       c: 'personal', g: 'personal',            ints: ['calendar'],m: 'Ayesha in 4d',  act: 'toast:Ayesha’s birthday in 4 days', kw: 'anniversary remember' },
    { id: 'streak',     n: 'Daily Streak',     i: 'i-flame',      c: 'personal', g: 'personal',            ints: ['habits'],  m: '12 days',       act: 'tab:today' },
    { id: 'recipes',    n: 'Recipes',          i: 'i-utensils',   c: 'personal', g: 'personal',                               m: '24 saved',      act: 'toast:24 recipes saved', kw: 'cook food meal biryani' },
    { id: 'mealplan',   n: 'Meal Planner',     i: 'i-calendar',   c: 'personal', g: 'personal',                               m: 'This week',     act: 'toast:Meal plan for this week', kw: 'food menu week' },
    { id: 'alarms',     n: 'Alarms',           i: 'i-alarm',      c: 'personal', g: 'personal',            ints: ['alarms'],  m: '2 set',         act: 'toast:2 alarms set', kw: 'wake up clock' },
    { id: 'learning',   n: 'Learning & Growth',i: 'i-graduation', c: 'personal', g: 'personal',            ints: ['reading'], m: '3 courses',     act: 'toast:3 courses in progress', kw: 'study course skill' },
    { id: 'documents',  n: 'Documents',        i: 'i-folder',     c: 'personal', g: 'personal', sens: 1,                      m: 'Locked',        act: 'toast:Documents are locked', kw: 'id cnic passport licence file' },
    { id: 'vaccines',   n: 'Vaccinations',     i: 'i-syringe',    c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: 'toast:Vaccination records are private', kw: 'immunisation shots epi' },
    { id: 'health',     n: 'Health Records',   i: 'i-pulse',      c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: 'toast:Health records are private', kw: 'medical reports blood test doctor' },
    { id: 'play',       n: 'Play',             i: 'i-play',       c: 'personal', g: 'personal',                               m: 'Puzzles',       act: 'toast:A quick puzzle break', kw: 'game puzzle break' },
    { id: 'babybudget', n: 'Baby Budget',      i: 'i-baby',       c: 'personal', g: 'personal',            ints: ['expenses'],m: 'Plan costs',    act: 'toast:Baby budget planner' },
    { id: 'habits',     n: 'Habits',           i: 'i-flame',      c: 'personal', g: 'personal',            ints: ['habits'],  m: '12-day streak', act: 'tab:today', kw: 'routine daily track' },
    { id: 'water',      n: 'Water',            i: 'i-droplet',    c: 'personal', g: 'personal',            ints: ['water'],   m: '5 / 8',         act: 'toast:Water — 5 of 8 glasses', kw: 'hydration drink glasses' },
    { id: 'bmi',        n: 'BMI Calculator',   i: 'i-pulse',      c: 'personal', g: 'daily',               ints: ['fitness'], m: 'Track weight',  act: 'toast:BMI calculator', kw: 'weight height body mass' },
    { id: 'cycle',      n: 'Cycle Tracker',    i: 'i-cycle',      c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: 'toast:Cycle tracker is private', kw: 'period menstrual women' },
    { id: 'pregnancy',  n: 'Pregnancy',        i: 'i-baby',       c: 'personal', g: 'personal', sens: 1,  ints: ['fitness'],  m: 'Private',       act: 'toast:Pregnancy tracker is private', kw: 'week due date women' },
    { id: 'expenses',   n: 'Expenses',         i: 'i-wallet',     c: 'personal', g: 'personal', sens: 1,  ints: ['expenses'], m: 'This month',    act: 'sheet:expenses', kw: 'spending budget money track' },
    { id: 'goals',      n: 'Savings Goals',    i: 'i-target',     c: 'personal', g: 'personal', sens: 1,  ints: ['savings'],  m: '2 active',      act: 'toast:2 savings goals · 64% of target', kw: 'save target money' },
    { id: 'subs',       n: 'Subscriptions',    i: 'i-refresh',    c: 'personal', g: 'personal', sens: 1,  ints: ['expenses'], m: '₨ 4,200/mo',    act: 'toast:6 subscriptions · ₨ 4,200 a month', kw: 'netflix spotify recurring monthly' },
    { id: 'meds',       n: 'Medication',       i: 'i-pill',       c: 'personal', g: 'personal', sens: 1,  ints: ['meds'],     m: 'Private',       act: 'toast:Medication reminders are private', kw: 'medicine dose pills reminder tablet' }
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
     Hero carousel — slides are personalised, never hard-coded
     --------------------------------------------------------- */
  var SLIDES = [
    { id: 'prayer',  faith: 1, art: 'night',  kicker: 'Next prayer', cta: 'Prayer times', act: 'sheet:prayer',
      live: true },
    { id: 'plan',    art: 'plan',   kicker: 'Today', title: 'Plan your day before it starts',
      text: 'Tasks, reminders and events on one clean timeline.', cta: 'Open today', act: 'tab:today' },
    { id: 'read',    faith: 1, art: 'read',  kicker: 'Read', title: 'Read something meaningful',
      text: 'You’re 42 ayahs into Al-Kahf. Two minutes is enough.', cta: 'Continue', act: 'sheet:reading' },
    { id: 'money',   art: 'money',  kicker: 'Money', title: 'Stay on top of your money',
      text: 'Rates, bills and expenses — all in one place.', cta: 'See money', act: 'sheet:rates', ints: ['rates', 'expenses', 'bills'] },
    { id: 'trains',  loc: 'PK', art: 'train', kicker: 'Travel', title: 'Trains, without the guesswork',
      text: 'Live running status, fares and seat availability.', cta: 'Find a train', act: 'tab:trains' },
    { id: 'tools',   art: 'tools',  kicker: 'Tools', title: 'Useful tools, all in one place',
      text: 'Calculator, converters, weather, scanner and more.', cta: 'Browse tools', act: 'tab:tools' }
  ];

  /* ---------------------------------------------------------
     Content
     --------------------------------------------------------- */
  var PRAYERS_BY_COUNTRY = {
    PK: [ { name: 'Fajr', h: 5, m: 3 }, { name: 'Sunrise', h: 6, m: 22, minor: true },
          { name: 'Dhuhr', h: 12, m: 29 }, { name: 'Asr', h: 15, m: 53 },
          { name: 'Maghrib', h: 18, m: 36 }, { name: 'Isha', h: 19, m: 50 } ],
    GB: [ { name: 'Fajr', h: 4, m: 52 }, { name: 'Sunrise', h: 6, m: 21, minor: true },
          { name: 'Dhuhr', h: 12, m: 38 }, { name: 'Asr', h: 16, m: 12 },
          { name: 'Maghrib', h: 19, m: 24 }, { name: 'Isha', h: 20, m: 46 } ]
  };

  var QIBLA_BY_COUNTRY = { PK: 267, GB: 119, AE: 258, US: 58, CA: 56, SA: 180 };

  var WEATHER = {
    PK: { temp: 34, feels: 38, desc: 'Hazy sun · humid', rain: 8,  wind: '14 km/h', icon: 'i-sun' },
    GB: { temp: 21, feels: 19, desc: 'Mostly clear',     rain: 12, wind: '8 km/h',  icon: 'i-cloud-sun' },
    AE: { temp: 39, feels: 44, desc: 'Clear · very warm',rain: 0,  wind: '11 km/h', icon: 'i-sun' },
    US: { temp: 24, feels: 24, desc: 'Light cloud',      rain: 20, wind: '10 km/h', icon: 'i-cloud-sun' },
    CA: { temp: 17, feels: 15, desc: 'Cloudy',           rain: 35, wind: '13 km/h', icon: 'i-cloud-sun' },
    SA: { temp: 40, feels: 42, desc: 'Clear',            rain: 0,  wind: '9 km/h',  icon: 'i-sun' }
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
    COUNTRIES: COUNTRIES,
    FEATURES: F,
    CATEGORIES: CATEGORIES,
    SLIDES: SLIDES,
    PRAYERS_BY_COUNTRY: PRAYERS_BY_COUNTRY,
    QIBLA_BY_COUNTRY: QIBLA_BY_COUNTRY,
    WEATHER: WEATHER,
    FUEL: FUEL,
    TRAINS: TRAINS,
    NEWS: NEWS
  };
})();
