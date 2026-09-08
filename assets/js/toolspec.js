/* ============================================================
   Lume — tool metadata contract  (Master Spec §81, §82, §111)

   Every tool declares what it is before anything draws it:
   its archetype, its density, what it is aware of, what it
   supports, where its data comes from, how fresh that data is,
   whether it belongs on Home, and which tools it connects to.

   Screens are composed from this contract, so a tool can never
   quietly become "the same generic screen" (§113): the contract
   is what says Markets is a financial data explorer and Tasbih
   is a focused interaction.

   Flags are space-separated words so the table stays readable:
     aware     country region currency language units timezone
     needs     location city account permission
     supports  offline search filters sorting history sharing
               export favorites notifications
   ============================================================ */
window.LUME_SPEC = (function () {
  'use strict';

  /* Screen archetypes (§22 + the focused kinds §113 names). */
  var ARCHETYPES = {
    dashboard:  { label: 'Dashboard',        sections: ['summary', 'metrics', 'primary', 'chart', 'activity', 'related'] },
    explorer:   { label: 'Data explorer',    sections: ['context', 'summary', 'search', 'filters', 'tabs', 'rows', 'chart', 'source'] },
    tracking:   { label: 'Live tracking',    sections: ['status', 'map', 'filters', 'list', 'selected', 'timeline', 'source'] },
    reader:     { label: 'Reader',           sections: ['context', 'content', 'controls', 'progress', 'bookmarks', 'actions'] },
    calculator: { label: 'Calculator',       sections: ['inputs', 'result', 'breakdown', 'history', 'actions'] },
    manager:    { label: 'Records manager',  sections: ['summary', 'search', 'filters', 'groups', 'detail', 'actions', 'history'] },
    tracker:    { label: 'Habit tracker',    sections: ['summary', 'today', 'ring', 'heatmap', 'stats', 'insights'] },
    library:    { label: 'Visual library',   sections: ['search', 'categories', 'featured', 'grid', 'detail'] },
    planner:    { label: 'Planner',          sections: ['nav', 'calendar', 'agenda', 'quickadd'] },
    instrument: { label: 'Instrument',       sections: ['readout', 'primary', 'calibration', 'context'] },
    action:     { label: 'Action interface', sections: ['context', 'actions', 'nearby', 'info'] }
  };

  var DENSITY = ['low', 'medium', 'high', 'veryhigh'];

  /* ---------------------------------------------------------
     Approved reference compositions (§123)

     An archetype is an abstraction, and an abstraction invites
     reinterpretation: read only "Markets is a data explorer"
     and you get the right components in the wrong order with
     the wrong element leading. Where a composition has been
     designed and approved, its section order is binding, and
     the verification suite asserts it.

     Sections listed here must appear, in this order, at the top
     of the screen. A screen may add supporting sections after
     the last binding one.
     --------------------------------------------------------- */
  var COMPOSITIONS = {
    markets: [
      'context',    /* market context / selected region        */
      'classnav',   /* Stocks | Indices | Forex | Commodities  */
      'hero',       /* primary market or index summary + chart */
      'assets',     /* Top Stocks / Top Assets · See all       */
      'overview'    /* Market Overview metrics                 */
    ]
  };

  /* ---------------------------------------------------------
     The contract table.
     a = archetype · d = density · aware · needs · supports
     src = data source · fresh = freshness model
     home = Home-eligible (§117) · quick = quick action (§118)
     rel = related tools (§97)
     --------------------------------------------------------- */
  var SPECS = {
    /* ---- Everyday & calculators ---- */
    calculator: { a: 'calculator', d: 'low', supports: 'history offline', quick: 1,
      src: 'On device', fresh: 'local', rel: ['converter', 'currency', 'tipsplit'] },
    converter: { a: 'calculator', d: 'low', aware: 'units locale', supports: 'history favorites offline', quick: 1,
      src: 'On device', fresh: 'local', rel: ['calculator', 'currency', 'fuelcost'] },
    currency: { a: 'explorer', d: 'high', aware: 'country currency locale', supports: 'search history favorites sharing',
      src: 'Interbank composite', fresh: 'delayed', home: 1, quick: 1, rel: ['goldrates', 'markets', 'expenses'] },
    stopwatch: { a: 'instrument', d: 'low', supports: 'history offline',
      src: 'On device', fresh: 'live', rel: ['timer', 'focus', 'alarms'] },
    timer: { a: 'instrument', d: 'low', supports: 'history notifications offline', quick: 1,
      src: 'On device', fresh: 'live', rel: ['stopwatch', 'focus', 'alarms'] },
    age: { a: 'calculator', d: 'low', aware: 'locale', supports: 'history sharing offline',
      src: 'On device', fresh: 'local', rel: ['datecalc', 'birthdays', 'calendar'] },
    datecalc: { a: 'calculator', d: 'low', aware: 'locale timezone', supports: 'history offline',
      src: 'On device', fresh: 'local', rel: ['age', 'calendar', 'holidays'] },
    focus: { a: 'instrument', d: 'low', supports: 'history notifications offline', quick: 1,
      src: 'On device', fresh: 'live', rel: ['timer', 'habits', 'todos'] },

    /* ---- Planning ---- */
    calendar: { a: 'planner', d: 'high', aware: 'country locale timezone language', supports: 'search notifications offline export',
      src: 'On device', fresh: 'local', home: 1, quick: 1, rel: ['todos', 'reminders', 'birthdays', 'holidays'] },
    reminders: { a: 'manager', d: 'medium', aware: 'timezone locale', supports: 'search notifications offline', quick: 1,
      src: 'On device', fresh: 'local', home: 1, rel: ['todos', 'calendar', 'meds'] },
    notes: { a: 'manager', d: 'medium', supports: 'search sorting offline export favorites', quick: 1,
      src: 'On device', fresh: 'local', home: 1, rel: ['todos', 'docscan', 'documents'] },
    todos: { a: 'manager', d: 'high', aware: 'locale timezone', supports: 'search filters sorting notifications offline', quick: 1,
      src: 'On device', fresh: 'local', home: 1, rel: ['calendar', 'reminders', 'habits'] },
    events: { a: 'manager', d: 'medium', aware: 'city locale timezone', supports: 'search filters notifications',
      src: 'On device', fresh: 'local', rel: ['calendar', 'todos', 'birthdays'] },

    /* ---- Prayer & Islam (§24) ---- */
    prayer: { a: 'dashboard', d: 'high', aware: 'city country timezone locale language', needs: 'city',
      supports: 'notifications offline sharing export', src: 'Astronomical calculation', fresh: 'computed',
      home: 1, quick: 1, rel: ['qibla', 'mosques', 'praytrack', 'hijri'] },
    qibla: { a: 'instrument', d: 'medium', aware: 'city country', needs: 'city location', supports: 'offline',
      src: 'Great-circle bearing', fresh: 'computed', quick: 1, rel: ['prayer', 'mosques', 'quran'] },
    mosques: { a: 'tracking', d: 'high', aware: 'city country units', needs: 'city location',
      supports: 'search filters sorting', src: 'Places directory', fresh: 'cached', rel: ['prayer', 'qibla', 'taraweeh'] },
    praytrack: { a: 'tracker', d: 'high', aware: 'timezone', supports: 'history offline notifications export',
      src: 'On device', fresh: 'local', home: 1, rel: ['prayer', 'habits', 'fasting'] },
    ramadan: { a: 'dashboard', d: 'high', aware: 'city country timezone locale', needs: 'city',
      supports: 'notifications offline sharing', src: 'Hijri calendar + solar times', fresh: 'computed',
      rel: ['fasting', 'prayer', 'taraweeh', 'quran'] },
    fasting: { a: 'tracker', d: 'high', aware: 'timezone', supports: 'history offline export',
      src: 'On device', fresh: 'local', rel: ['ramadan', 'praytrack', 'habits'] },
    taraweeh: { a: 'tracking', d: 'medium', aware: 'city units', needs: 'city',
      supports: 'search filters notifications', src: 'Places directory', fresh: 'cached', rel: ['mosques', 'ramadan', 'prayer'] },
    ayah: { a: 'reader', d: 'medium', aware: 'language', supports: 'sharing favorites offline',
      src: 'Qur’an text', fresh: 'daily', home: 1, rel: ['quran', 'quransearch', 'duas'] },
    quran: { a: 'reader', d: 'high', aware: 'language', supports: 'search history favorites offline sharing',
      src: 'Qur’an text', fresh: 'static', home: 1, quick: 1, rel: ['quransearch', 'ayah', 'prayer', 'ramadan'] },
    quransearch: { a: 'explorer', d: 'high', aware: 'language', supports: 'search filters history favorites offline',
      src: 'Qur’an text', fresh: 'static', rel: ['quran', 'hadith', 'ayah'] },
    hadith: { a: 'reader', d: 'high', aware: 'language', supports: 'search filters favorites offline sharing',
      src: 'Hadith collections', fresh: 'static', rel: ['quran', 'duas', 'names99'] },
    duas: { a: 'library', d: 'high', aware: 'language', supports: 'search filters favorites offline sharing',
      src: 'Dua collection', fresh: 'static', rel: ['names99', 'tasbih', 'hadith'] },
    names99: { a: 'library', d: 'medium', aware: 'language', supports: 'search favorites offline sharing history',
      src: 'Asma ul Husna', fresh: 'static', rel: ['duas', 'tasbih', 'quran'] },
    hijri: { a: 'planner', d: 'medium', aware: 'country locale timezone', supports: 'notifications offline export',
      src: 'Umm al-Qura calculation', fresh: 'computed', rel: ['calendar', 'ramadan', 'holidays'] },
    tasbih: { a: 'instrument', d: 'low', supports: 'history offline', quick: 1,
      src: 'On device', fresh: 'local', rel: ['duas', 'names99', 'praytrack'] },
    zakat: { a: 'calculator', d: 'high', aware: 'currency country locale', supports: 'history sharing export offline',
      src: 'Nisab from live metal rates', fresh: 'delayed', rel: ['goldrates', 'expenses', 'faraid'] },
    faraid: { a: 'calculator', d: 'high', aware: 'currency locale', supports: 'history export sharing offline',
      src: 'Classical faraid rules', fresh: 'static', rel: ['zakat', 'documents', 'ledger'] },

    /* ---- Money & rates (§25–§38) ---- */
    goldrates: { a: 'explorer', d: 'high', aware: 'country currency units locale', supports: 'search history sharing favorites',
      src: 'Bullion + open market', fresh: 'delayed', home: 1, rel: ['currency', 'markets', 'zakat'] },
    markets: { a: 'explorer', d: 'veryhigh', aware: 'country currency locale',
      supports: 'search filters sorting favorites sharing notifications export',
      src: 'Exchange feed', fresh: 'delayed', home: 1, rel: ['currency', 'goldrates', 'news'] },
    fuel: { a: 'explorer', d: 'high', aware: 'country region currency units locale', supports: 'history notifications sharing',
      src: 'Regulator notification', fresh: 'daily', home: 1, rel: ['fuelcost', 'vehicle', 'expenses'] },
    fuelcost: { a: 'calculator', d: 'medium', aware: 'country currency units', supports: 'history sharing offline',
      src: 'Current pump price', fresh: 'daily', rel: ['fuel', 'vehicle', 'expenses'] },
    tax: { a: 'calculator', d: 'high', aware: 'country currency locale', supports: 'history export sharing offline',
      src: 'Statutory slabs', fresh: 'annual', rel: ['expenses', 'natsavings', 'goals'] },
    natsavings: { a: 'explorer', d: 'high', aware: 'country currency locale', supports: 'search sorting history',
      src: 'National Savings schedule', fresh: 'weekly', rel: ['goals', 'markets', 'tax'] },
    prizebonds: { a: 'explorer', d: 'high', aware: 'country currency locale', supports: 'search history notifications',
      src: 'Official draw results', fresh: 'draw', rel: ['natsavings', 'goals', 'ledger'] },
    bills: { a: 'dashboard', d: 'high', aware: 'country currency locale timezone', supports: 'search filters sorting notifications history export',
      src: 'On device + provider', fresh: 'daily', home: 1, quick: 1, rel: ['expenses', 'subs', 'loadshed'] },
    packages: { a: 'explorer', d: 'high', aware: 'country currency locale', supports: 'search filters sorting',
      src: 'Operator tariffs', fresh: 'weekly', rel: ['bills', 'expenses', 'speedtest'] },
    loan: { a: 'calculator', d: 'high', aware: 'currency locale', supports: 'history export sharing offline',
      src: 'On device', fresh: 'local', rel: ['installments', 'expenses', 'goals'] },
    tipsplit: { a: 'calculator', d: 'low', aware: 'currency locale', supports: 'history sharing offline', quick: 1,
      src: 'On device', fresh: 'local', rel: ['expenses', 'ledger', 'calculator'] },
    ledger: { a: 'manager', d: 'high', aware: 'currency locale', supports: 'search filters sorting notifications history export',
      src: 'On device', fresh: 'local', rel: ['expenses', 'installments', 'committee'] },
    installments: { a: 'manager', d: 'high', aware: 'currency locale', supports: 'filters sorting notifications history',
      src: 'On device', fresh: 'local', rel: ['loan', 'expenses', 'subs'] },
    committee: { a: 'manager', d: 'high', aware: 'currency locale', supports: 'notifications history export',
      src: 'On device', fresh: 'local', rel: ['ledger', 'goals', 'expenses'] },
    compound: { a: 'calculator', d: 'medium', aware: 'currency locale', supports: 'history sharing offline',
      src: 'On device', fresh: 'local', rel: ['goals', 'natsavings', 'loan'] },

    /* ---- Daily life (§39–§56) ---- */
    weather: { a: 'dashboard', d: 'high', aware: 'city country units locale timezone', needs: 'city',
      supports: 'notifications offline sharing favorites', src: 'Forecast model', fresh: 'delayed',
      home: 1, quick: 1, rel: ['aqi', 'sunmoon', 'calendar', 'flights'] },
    aqi: { a: 'dashboard', d: 'high', aware: 'city country locale', needs: 'city', supports: 'notifications history sharing',
      src: 'Monitoring stations', fresh: 'delayed', rel: ['weather', 'health', 'sunmoon'] },
    sunmoon: { a: 'dashboard', d: 'medium', aware: 'city country timezone locale', needs: 'city', supports: 'offline sharing',
      src: 'Astronomical calculation', fresh: 'computed', rel: ['weather', 'prayer', 'calendar'] },
    loadshed: { a: 'dashboard', d: 'high', aware: 'city country region timezone', needs: 'city',
      supports: 'notifications history offline', src: 'Distribution company', fresh: 'daily',
      home: 1, rel: ['bills', 'weather', 'emergency'] },
    trains: { a: 'tracking', d: 'veryhigh', aware: 'country city currency locale timezone', needs: 'city',
      supports: 'search filters sorting notifications history sharing', src: 'Operator live feed', fresh: 'live',
      home: 1, rel: ['flights', 'weather', 'holidays'] },
    flights: { a: 'tracking', d: 'veryhigh', aware: 'country city locale timezone units',
      supports: 'search filters sorting notifications history sharing', src: 'ADS-B network', fresh: 'live',
      home: 1, rel: ['weather', 'trains', 'holidays'] },
    news: { a: 'reader', d: 'high', aware: 'country city language locale', supports: 'search filters favorites offline sharing history',
      src: 'Publisher feeds', fresh: 'live', home: 1, rel: ['markets', 'cricket', 'weather'] },
    cricket: { a: 'dashboard', d: 'high', aware: 'country language locale', supports: 'notifications filters sharing history',
      src: 'Match feed', fresh: 'live', home: 1, rel: ['news', 'calendar', 'play'] },
    emergency: { a: 'action', d: 'low', aware: 'country region city locale language', needs: 'city',
      supports: 'offline', src: 'National directory', fresh: 'static', quick: 1, rel: ['health', 'documents', 'meds'] },
    qr: { a: 'instrument', d: 'low', needs: 'permission', supports: 'history offline', quick: 1,
      src: 'Camera', fresh: 'live', rel: ['docscan', 'parcel', 'mediasaver'] },
    docscan: { a: 'instrument', d: 'medium', needs: 'permission', supports: 'history export offline', quick: 1,
      src: 'Camera', fresh: 'live', rel: ['documents', 'notes', 'passport'] },
    passport: { a: 'instrument', d: 'medium', aware: 'country locale', needs: 'permission', supports: 'export offline history',
      src: 'ICAO + national specs', fresh: 'static', rel: ['docscan', 'documents', 'vehicle'] },
    vehicle: { a: 'manager', d: 'high', aware: 'country region currency locale', supports: 'search filters notifications history',
      src: 'Excise records', fresh: 'daily', rel: ['fuel', 'fuelcost', 'documents', 'emergency'] },
    mediasaver: { a: 'manager', d: 'medium', supports: 'history offline', src: 'On device', fresh: 'local',
      rel: ['wastatus', 'docscan', 'notes'] },
    wastatus: { a: 'library', d: 'medium', needs: 'permission', supports: 'history offline',
      src: 'On device', fresh: 'local', rel: ['mediasaver', 'docscan'] },
    speedtest: { a: 'instrument', d: 'medium', aware: 'country locale', supports: 'history offline',
      src: 'Nearest test server', fresh: 'live', rel: ['packages', 'bills'] },
    worldclock: { a: 'explorer', d: 'medium', aware: 'timezone locale language', supports: 'search favorites offline',
      src: 'IANA time zones', fresh: 'live', rel: ['calendar', 'flights', 'holidays'] },
    holidays: { a: 'planner', d: 'medium', aware: 'country region locale language', supports: 'search filters offline export',
      src: 'National calendars', fresh: 'annual', rel: ['calendar', 'hijri', 'worldclock'] },

    /* ---- Personal (§57–§79) ---- */
    parcel: { a: 'tracking', d: 'high', aware: 'country locale timezone', supports: 'search notifications history sharing',
      src: 'Carrier tracking', fresh: 'delayed', home: 1, quick: 1, rel: ['shopping', 'expenses', 'notes'] },
    shopping: { a: 'manager', d: 'medium', aware: 'currency locale', supports: 'search filters offline sharing', quick: 1,
      src: 'On device', fresh: 'local', home: 1, rel: ['mealplan', 'recipes', 'expenses'] },
    birthdays: { a: 'planner', d: 'medium', aware: 'locale timezone', supports: 'search notifications offline',
      src: 'On device', fresh: 'local', home: 1, rel: ['calendar', 'shopping', 'reminders'] },
    streak: { a: 'tracker', d: 'medium', supports: 'history offline notifications',
      src: 'On device', fresh: 'local', home: 1, rel: ['habits', 'praytrack', 'water'] },
    recipes: { a: 'library', d: 'high', aware: 'units locale language', supports: 'search filters favorites offline sharing',
      src: 'Recipe library', fresh: 'static', rel: ['mealplan', 'shopping', 'water'] },
    mealplan: { a: 'planner', d: 'high', aware: 'units locale', supports: 'search offline export',
      src: 'On device', fresh: 'local', rel: ['recipes', 'shopping', 'expenses'] },
    alarms: { a: 'manager', d: 'medium', aware: 'timezone locale', supports: 'notifications offline',
      src: 'On device', fresh: 'local', rel: ['timer', 'focus', 'prayer'] },
    learning: { a: 'tracker', d: 'high', supports: 'search history offline favorites',
      src: 'On device', fresh: 'local', rel: ['habits', 'notes', 'focus'] },
    documents: { a: 'manager', d: 'veryhigh', aware: 'country locale', sensitive: 1,
      supports: 'search filters sorting notifications offline export', src: 'Encrypted on device', fresh: 'local',
      rel: ['vehicle', 'health', 'passport', 'docscan'] },
    vaccines: { a: 'manager', d: 'high', aware: 'country locale', sensitive: 1, supports: 'filters notifications offline export',
      src: 'Encrypted on device', fresh: 'local', rel: ['health', 'meds', 'documents'] },
    health: { a: 'manager', d: 'veryhigh', aware: 'country currency locale', sensitive: 1,
      supports: 'search filters sorting offline export notifications', src: 'Encrypted on device', fresh: 'local',
      rel: ['vaccines', 'meds', 'documents', 'expenses'] },
    play: { a: 'library', d: 'medium', supports: 'history favorites offline',
      src: 'On device', fresh: 'local', rel: ['streak', 'focus', 'learning'] },
    babybudget: { a: 'dashboard', d: 'high', aware: 'currency locale', supports: 'history export offline',
      src: 'On device', fresh: 'local', rel: ['expenses', 'goals', 'pregnancy'] },
    habits: { a: 'tracker', d: 'high', aware: 'timezone locale', supports: 'history notifications offline export',
      src: 'On device', fresh: 'local', home: 1, quick: 1, rel: ['streak', 'water', 'focus', 'praytrack'] },
    water: { a: 'tracker', d: 'medium', aware: 'units locale', supports: 'history notifications offline', quick: 1,
      src: 'On device', fresh: 'local', home: 1, rel: ['habits', 'health', 'recipes'] },
    bmi: { a: 'calculator', d: 'medium', aware: 'units locale', supports: 'history offline',
      src: 'On device', fresh: 'local', rel: ['health', 'water', 'habits'] },
    cycle: { a: 'planner', d: 'high', sensitive: 1, aware: 'locale timezone', supports: 'history notifications offline',
      src: 'Encrypted on device', fresh: 'local', rel: ['health', 'pregnancy', 'meds'] },
    pregnancy: { a: 'dashboard', d: 'high', sensitive: 1, aware: 'locale timezone units', supports: 'history notifications offline',
      src: 'Encrypted on device', fresh: 'local', rel: ['health', 'cycle', 'babybudget'] },
    expenses: { a: 'dashboard', d: 'veryhigh', aware: 'currency country locale timezone', sensitive: 1,
      supports: 'search filters sorting history export offline sharing', src: 'On device', fresh: 'local',
      home: 1, quick: 1, rel: ['goals', 'subs', 'bills', 'ledger'] },
    goals: { a: 'dashboard', d: 'high', aware: 'currency locale', sensitive: 1,
      supports: 'history notifications offline export sharing', src: 'On device', fresh: 'local',
      home: 1, rel: ['expenses', 'natsavings', 'compound'] },
    subs: { a: 'manager', d: 'high', aware: 'currency locale timezone', sensitive: 1,
      supports: 'search filters sorting notifications history export', src: 'On device', fresh: 'local',
      home: 1, rel: ['expenses', 'bills', 'installments'] },
    meds: { a: 'manager', d: 'high', sensitive: 1, aware: 'timezone locale', supports: 'notifications history offline export',
      src: 'Encrypted on device', fresh: 'local', rel: ['health', 'vaccines', 'reminders'] }
  };

  /* Sensible contract for anything added to the catalogue before its
     specification is written — never a silent crash, and never a screen
     that pretends to be richer than its data. */
  var FALLBACK = { a: 'manager', d: 'medium', supports: 'offline', src: 'On device', fresh: 'local', rel: [] };

  function flags(str) {
    var set = {};
    (str || '').split(/\s+/).forEach(function (w) { if (w) set[w] = true; });
    return set;
  }

  var CACHE = {};

  function get(id) {
    if (CACHE[id]) return CACHE[id];
    var raw = SPECS[id] || FALLBACK;
    var spec = {
      id: id,
      archetype: raw.a,
      density: raw.d,
      aware: flags(raw.aware),
      needs: flags(raw.needs),
      supports: flags(raw.supports),
      sensitive: !!raw.sensitive,
      source: raw.src,
      freshness: raw.fresh,
      homeEligible: !!raw.home,
      quickEligible: !!raw.quick,
      related: raw.rel || [],
      sections: (ARCHETYPES[raw.a] || ARCHETYPES.manager).sections,
      /* Present only for a tool with an approved composition (§123). */
      composition: COMPOSITIONS[id] || null
    };
    CACHE[id] = spec;
    return spec;
  }

  function has(id) { return !!SPECS[id]; }

  return {
    ARCHETYPES: ARCHETYPES, DENSITY: DENSITY, SPECS: SPECS, COMPOSITIONS: COMPOSITIONS,
    get: get, has: has
  };
})();
