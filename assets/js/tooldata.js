/* ============================================================
   Lume — domain data & regional configuration
   (Master Spec §20, §21, §105, §106)

   Country-aware tools do not fork into separate products. One
   tool reads its regional configuration and renders local
   exchanges, local pump prices, local emergency numbers and
   local holidays through the same interface.

       Tool → Regional configuration → Country → Data → Format

   Everything here is demonstration data with realistic shape:
   the point is that a screen has enough information to be
   composed honestly, and that swapping the country swaps the
   whole dataset rather than a label.
   ============================================================ */
window.LUME_DATA = (function () {
  'use strict';

  function seedRand(seed) {
    var s = seed % 2147483647;
    if (s <= 0) s += 2147483646;
    return function () { s = s * 16807 % 2147483647; return (s - 1) / 2147483646; };
  }

  /* A plausible price walk, so sparklines and charts move like data. */
  function walk(seed, n, start, vol) {
    var r = seedRand(seed), out = [], v = start;
    for (var i = 0; i < n; i++) {
      v = v * (1 + (r() - 0.5) * vol);
      out.push(Math.round(v * 100) / 100);
    }
    return out;
  }

  /* ---------------------------------------------------------
     §21 — Markets. Never hardcoded to one exchange.
     --------------------------------------------------------- */
  var EXCHANGES = {
    PK: {
      code: 'PSX', name: 'Pakistan Stock Exchange', city: 'Karachi', ccy: 'PKR', tz: 'Asia/Karachi',
      open: '09:32', close: '15:30',
      indices: [
        { sym: 'KSE100', name: 'KSE-100', full: 'Karachi 100 Index', value: 154230.42, chg: 1248.23, pct: 0.82 },
        { sym: 'KSE30', name: 'KSE-30', full: 'Karachi 30 Index', value: 47188.10, chg: 402.55, pct: 0.86 },
        { sym: 'KMI30', name: 'KMI-30', full: 'Meezan Islamic Index', value: 224905.66, chg: -812.40, pct: -0.36 },
        { sym: 'ALLSHR', name: 'All Share', full: 'PSX All Share Index', value: 96114.27, chg: 640.11, pct: 0.67 }
      ],
      stocks: [
        { sym: 'OGDC', name: 'Oil & Gas Development', logo: 'OG', tone: 'green', price: 248.31, chg: 4.12, pct: 1.69, vol: '12.4M', cap: '1.07T', sectorKey: 'sector.energy' },
        { sym: 'ENGRO', name: 'Engro Corporation', logo: 'EN', tone: 'sky', price: 322.90, chg: -2.84, pct: -0.87, vol: '3.1M', cap: '186B', sectorKey: 'sector.fertiliser' },
        { sym: 'HBL', name: 'Habib Bank', logo: 'HB', tone: 'indigo', price: 143.66, chg: 1.98, pct: 1.40, vol: '8.9M', cap: '210B', sectorKey: 'sector.banking' },
        { sym: 'LUCK', name: 'Lucky Cement', logo: 'LC', tone: 'amber', price: 1042.55, chg: 18.40, pct: 1.80, vol: '1.2M', cap: '305B', sectorKey: 'sector.cement' },
        { sym: 'PSO', name: 'Pakistan State Oil', logo: 'PS', tone: 'rose', price: 412.08, chg: -6.22, pct: -1.49, vol: '4.7M', cap: '193B', sectorKey: 'sector.energy' },
        { sym: 'SYS', name: 'Systems Limited', logo: 'SY', tone: 'violet', price: 189.44, chg: 5.61, pct: 3.05, vol: '2.8M', cap: '55B', sectorKey: 'sector.technology' }
      ]
    },
    US: {
      code: 'NASDAQ', name: 'Nasdaq · NYSE', city: 'New York', ccy: 'USD', tz: 'America/New_York',
      open: '09:30', close: '16:00',
      indices: [
        { sym: 'SPX', name: 'S&P 500', full: 'Standard & Poor’s 500', value: 5812.44, chg: 24.18, pct: 0.42 },
        { sym: 'IXIC', name: 'Nasdaq Composite', full: 'Nasdaq Composite Index', value: 18644.20, chg: 132.55, pct: 0.72 },
        { sym: 'DJI', name: 'Dow Jones', full: 'Dow Jones Industrial Average', value: 42330.15, chg: -88.40, pct: -0.21 },
        { sym: 'RUT', name: 'Russell 2000', full: 'Russell 2000 Index', value: 2244.08, chg: 11.62, pct: 0.52 }
      ],
      stocks: [
        { sym: 'AAPL', name: 'Apple Inc.', logo: 'AA', tone: 'slate', price: 238.42, chg: 4.72, pct: 2.02, vol: '54.1M', cap: '3.62T', sectorKey: 'sector.technology' },
        { sym: 'MSFT', name: 'Microsoft Corp.', logo: 'MS', tone: 'sky', price: 428.15, chg: 2.10, pct: 0.49, vol: '18.7M', cap: '3.18T', sectorKey: 'sector.technology' },
        { sym: 'NVDA', name: 'NVIDIA Corp.', logo: 'NV', tone: 'green', price: 138.90, chg: -1.84, pct: -1.31, vol: '212M', cap: '3.41T', sectorKey: 'sector.semiconductors' },
        { sym: 'AMZN', name: 'Amazon.com Inc.', logo: 'AM', tone: 'amber', price: 202.61, chg: 1.44, pct: 0.72, vol: '31.5M', cap: '2.12T', sectorKey: 'sector.retail' },
        { sym: 'JPM', name: 'JPMorgan Chase', logo: 'JP', tone: 'indigo', price: 244.80, chg: 3.02, pct: 1.25, vol: '9.2M', cap: '688B', sectorKey: 'sector.banking' },
        { sym: 'TSLA', name: 'Tesla Inc.', logo: 'TS', tone: 'rose', price: 341.22, chg: -8.61, pct: -2.46, vol: '88.4M', cap: '1.09T', sectorKey: 'sector.automotive' }
      ]
    },
    GB: {
      code: 'LSE', name: 'London Stock Exchange', city: 'London', ccy: 'GBP', tz: 'Europe/London',
      open: '08:00', close: '16:30',
      indices: [
        { sym: 'UKX', name: 'FTSE 100', full: 'Financial Times 100', value: 8288.60, chg: 31.44, pct: 0.38 },
        { sym: 'MCX', name: 'FTSE 250', full: 'Financial Times 250', value: 20914.30, chg: -62.10, pct: -0.30 },
        { sym: 'ASX', name: 'FTSE All-Share', full: 'FTSE All-Share Index', value: 4534.22, chg: 12.88, pct: 0.28 }
      ],
      stocks: [
        { sym: 'SHEL', name: 'Shell plc', logo: 'SH', tone: 'green', price: 2712.50, chg: 18.00, pct: 0.67, vol: '6.1M', cap: '167B', sectorKey: 'sector.energy' },
        { sym: 'AZN', name: 'AstraZeneca plc', logo: 'AZ', tone: 'rose', price: 10422.00, chg: -64.00, pct: -0.61, vol: '1.8M', cap: '161B', sectorKey: 'sector.pharma' },
        { sym: 'HSBA', name: 'HSBC Holdings', logo: 'HS', tone: 'indigo', price: 712.40, chg: 5.20, pct: 0.74, vol: '22.4M', cap: '128B', sectorKey: 'sector.banking' },
        { sym: 'ULVR', name: 'Unilever plc', logo: 'UL', tone: 'sky', price: 4688.00, chg: 22.00, pct: 0.47, vol: '3.4M', cap: '116B', sectorKey: 'sector.consumer' },
        { sym: 'BP', name: 'BP plc', logo: 'BP', tone: 'amber', price: 388.65, chg: -3.15, pct: -0.80, vol: '31.2M', cap: '64B', sectorKey: 'sector.energy' }
      ]
    },
    AE: {
      code: 'DFM', name: 'Dubai Financial Market', city: 'Dubai', ccy: 'AED', tz: 'Asia/Dubai',
      open: '10:00', close: '15:00',
      indices: [
        { sym: 'DFMGI', name: 'DFM General', full: 'DFM General Index', value: 4622.18, chg: 18.44, pct: 0.40 },
        { sym: 'ADI', name: 'ADX General', full: 'Abu Dhabi Securities Index', value: 9384.55, chg: -12.10, pct: -0.13 }
      ],
      stocks: [
        { sym: 'EMAAR', name: 'Emaar Properties', logo: 'EM', tone: 'amber', price: 8.42, chg: 0.12, pct: 1.45, vol: '18.4M', cap: '74B', sectorKey: 'sector.realestate' },
        { sym: 'DIB', name: 'Dubai Islamic Bank', logo: 'DI', tone: 'green', price: 6.88, chg: 0.04, pct: 0.58, vol: '9.1M', cap: '50B', sectorKey: 'sector.banking' },
        { sym: 'ADCB', name: 'Abu Dhabi Commercial', logo: 'AD', tone: 'indigo', price: 10.24, chg: -0.06, pct: -0.58, vol: '5.6M', cap: '72B', sectorKey: 'sector.banking' },
        { sym: 'SALIK', name: 'Salik Company', logo: 'SA', tone: 'sky', price: 5.11, chg: 0.09, pct: 1.79, vol: '12.2M', cap: '38B', sectorKey: 'sector.infrastructure' }
      ]
    },
    SA: {
      code: 'Tadawul', name: 'Saudi Exchange', city: 'Riyadh', ccy: 'SAR', tz: 'Asia/Riyadh',
      open: '10:00', close: '15:00',
      indices: [
        { sym: 'TASI', name: 'TASI', full: 'Tadawul All Share Index', value: 11844.20, chg: 62.10, pct: 0.53 },
        { sym: 'NOMU', name: 'Nomu', full: 'Parallel Market Index', value: 26120.44, chg: -140.20, pct: -0.53 }
      ],
      stocks: [
        { sym: '2222', name: 'Saudi Aramco', logo: 'AR', tone: 'green', price: 27.40, chg: 0.15, pct: 0.55, vol: '14.2M', cap: '6.6T', sectorKey: 'sector.energy' },
        { sym: '1120', name: 'Al Rajhi Bank', logo: 'RJ', tone: 'indigo', price: 96.80, chg: 1.20, pct: 1.26, vol: '4.8M', cap: '387B', sectorKey: 'sector.banking' },
        { sym: '2010', name: 'SABIC', logo: 'SB', tone: 'sky', price: 68.10, chg: -0.90, pct: -1.30, vol: '3.2M', cap: '204B', sectorKey: 'sector.chemicals' },
        { sym: '7010', name: 'STC', logo: 'ST', tone: 'violet', price: 42.55, chg: 0.35, pct: 0.83, vol: '5.1M', cap: '213B', sectorKey: 'sector.telecom' }
      ]
    },
    IN: {
      code: 'NSE', name: 'National Stock Exchange', city: 'Mumbai', ccy: 'INR', tz: 'Asia/Kolkata',
      open: '09:15', close: '15:30',
      indices: [
        { sym: 'NIFTY', name: 'NIFTY 50', full: 'NSE NIFTY 50', value: 24188.65, chg: 118.40, pct: 0.49 },
        { sym: 'SENSEX', name: 'SENSEX', full: 'BSE SENSEX 30', value: 79486.32, chg: 384.20, pct: 0.49 },
        { sym: 'BANKNIFTY', name: 'Bank NIFTY', full: 'NIFTY Bank Index', value: 52104.10, chg: -212.55, pct: -0.41 }
      ],
      stocks: [
        { sym: 'RELIANCE', name: 'Reliance Industries', logo: 'RI', tone: 'indigo', price: 2944.20, chg: 22.10, pct: 0.76, vol: '8.1M', cap: '19.9T', sectorKey: 'sector.conglomerate' },
        { sym: 'TCS', name: 'Tata Consultancy', logo: 'TC', tone: 'sky', price: 4188.55, chg: -18.40, pct: -0.44, vol: '2.2M', cap: '15.2T', sectorKey: 'sector.technology' },
        { sym: 'HDFCBANK', name: 'HDFC Bank', logo: 'HD', tone: 'violet', price: 1688.10, chg: 12.60, pct: 0.75, vol: '11.4M', cap: '12.8T', sectorKey: 'sector.banking' },
        { sym: 'INFY', name: 'Infosys', logo: 'IN', tone: 'green', price: 1902.44, chg: 8.20, pct: 0.43, vol: '6.8M', cap: '7.9T', sectorKey: 'sector.technology' }
      ]
    }
  };

  /* Every market can reach the global board regardless of where the
     user is (§21) — local first, world always available. */
  var GLOBAL_INDICES = [
    { sym: 'SPX', name: 'S&P 500', full: 'United States', value: 5812.44, chg: 24.18, pct: 0.42 },
    { sym: 'UKX', name: 'FTSE 100', full: 'United Kingdom', value: 8288.60, chg: 31.44, pct: 0.38 },
    { sym: 'N225', name: 'Nikkei 225', full: 'Japan', value: 38722.10, chg: -142.80, pct: -0.37 },
    { sym: 'DAX', name: 'DAX', full: 'Germany', value: 19188.44, chg: 88.10, pct: 0.46 },
    { sym: 'HSI', name: 'Hang Seng', full: 'Hong Kong', value: 20144.80, chg: 210.40, pct: 1.06 },
    { sym: 'TASI', name: 'TASI', full: 'Saudi Arabia', value: 11844.20, chg: 62.10, pct: 0.53 }
  ];

  var CRYPTO = [
    { sym: 'BTC', name: 'Bitcoin', logo: '₿', tone: 'amber', price: 96420.00, chg: 1840.00, pct: 1.95, vol: '38.1B', cap: '1.90T' },
    { sym: 'ETH', name: 'Ethereum', logo: 'Ξ', tone: 'violet', price: 3388.40, chg: -42.10, pct: -1.23, vol: '18.4B', cap: '408B' },
    { sym: 'SOL', name: 'Solana', logo: 'S', tone: 'green', price: 214.66, chg: 8.42, pct: 4.08, vol: '4.2B', cap: '101B' },
    { sym: 'XRP', name: 'XRP', logo: 'X', tone: 'slate', price: 2.31, chg: 0.11, pct: 5.00, vol: '6.8B', cap: '132B' }
  ];

  var ETFS = [
    { sym: 'VOO', name: 'Vanguard S&P 500 ETF', logo: 'VO', tone: 'indigo', price: 534.20, chg: 2.18, pct: 0.41, vol: '4.1M', cap: '520B' },
    { sym: 'QQQ', name: 'Invesco QQQ Trust', logo: 'QQ', tone: 'sky', price: 498.66, chg: 3.44, pct: 0.69, vol: '28.4M', cap: '298B' },
    { sym: 'GLD', name: 'SPDR Gold Shares', logo: 'GL', tone: 'amber', price: 244.10, chg: 1.02, pct: 0.42, vol: '6.2M', cap: '73B' }
  ];

  function exchangeFor(code) {
    return EXCHANGES[code] || null;
  }

  /* ---------------------------------------------------------
     Fuel — regulator-published prices per market
     --------------------------------------------------------- */
  var FUEL = {
    PK: { ccy: 'PKR', unit: 'litre', source: 'OGRA notification', effective: '1 September',
      items: [
        { nk: 'fuel.g.petrol', v: 264.61, prev: 262.47, code: 'RON 92' },
        { nk: 'fuel.g.hioctane', v: 284.90, prev: 283.10, code: 'RON 97' },
        { nk: 'fuel.g.diesel', v: 272.98, prev: 273.63, code: 'HSD' },
        { nk: 'fuel.g.lightdiesel', v: 160.45, prev: 160.45, code: 'LDO' }
      ] },
    GB: { ccy: 'GBP', unit: 'litre', sourceKey: 'fuel.src.retail', effectiveKey: 'common.today',
      items: [
        { nk: 'fuel.g.unleaded', v: 1.34, prev: 1.36, code: 'E10' },
        { nk: 'fuel.g.superunleaded', v: 1.46, prev: 1.47, code: 'E5' },
        { nk: 'fuel.g.diesel', v: 1.41, prev: 1.42, code: 'B7' }
      ] },
    US: { ccy: 'USD', unit: 'gallon', sourceKey: 'fuel.src.state', effectiveKey: 'common.today',
      items: [
        { nk: 'fuel.g.regular', v: 3.12, prev: 3.18, code: '87' },
        { nk: 'fuel.g.midgrade', v: 3.58, prev: 3.62, code: '89' },
        { nk: 'fuel.g.premium', v: 3.98, prev: 4.01, code: '93' },
        { nk: 'fuel.g.diesel', v: 3.66, prev: 3.71, code: 'ULSD' }
      ] },
    AE: { ccy: 'AED', unit: 'litre', source: 'Ministry of Energy', effective: '1 September',
      items: [
        { nk: 'fuel.g.special95', v: 2.61, prev: 2.70, code: '95' },
        { nk: 'fuel.g.super98', v: 2.72, prev: 2.81, code: '98' },
        { nk: 'fuel.g.eplus91', v: 2.53, prev: 2.62, code: '91' },
        { nk: 'fuel.g.diesel', v: 2.66, prev: 2.74, code: 'Diesel' }
      ] },
    SA: { ccy: 'SAR', unit: 'litre', source: 'Aramco tariff', effective: '11 September',
      items: [
        { nk: 'fuel.g.petrol91', v: 2.18, prev: 2.18, code: '91' },
        { nk: 'fuel.g.petrol95', v: 2.33, prev: 2.33, code: '95' },
        { nk: 'fuel.g.diesel', v: 1.15, prev: 1.15, code: 'Diesel' }
      ] },
    IN: { ccy: 'INR', unit: 'litre', sourceKey: 'fuel.src.omc', effectiveKey: 'common.today',
      items: [
        { nk: 'fuel.g.petrol', v: 94.72, prev: 94.77, code: 'MS' },
        { nk: 'fuel.g.diesel', v: 87.62, prev: 87.67, code: 'HSD' },
        { nk: 'fuel.g.cng', v: 76.59, prev: 76.59, code: 'CNG' }
      ] }
  };

  /* A neutral global fallback so the tool is never blank (§92). */
  var FUEL_FALLBACK = { ccy: 'USD', unit: 'litre', sourceKey: 'fuel.src.regional', effectiveKey: 'common.thisWeek',
    items: [
      { nk: 'fuel.g.petrol', v: 1.28, prev: 1.30, code: 'Unleaded' },
      { nk: 'fuel.g.diesel', v: 1.34, prev: 1.35, code: 'Diesel' }
    ] };

  function fuelFor(code) { return FUEL[code] || FUEL_FALLBACK; }

  /* ---------------------------------------------------------
     Emergency numbers (§46) — a life-safety dataset, so the
     global fallback is the international standard rather than
     an empty screen.
     --------------------------------------------------------- */
  var EMERGENCY = {
    PK: [{ n: 'Rescue 1122', num: '1122', icon: 'i-pulse', kindKey: 'emerg.ambRescue' },
         { n: 'Police', num: '15', icon: 'i-shield', kindKey: 'emerg.police' },
         { n: 'Fire Brigade', num: '16', icon: 'i-flame', kindKey: 'emerg.fire' },
         { n: 'Edhi Ambulance', num: '115', icon: 'i-pulse', kindKey: 'emerg.ambulance' },
         { n: 'Motorway Police', num: '130', icon: 'i-car', kindKey: 'emerg.highway' }],
    US: [{ n: 'Emergency', num: '911', icon: 'i-shield', kindKey: 'emerg.all3' },
         { n: 'Poison Control', num: '1-800-222-1222', icon: 'i-pill', kindKey: 'emerg.poison' },
         { n: 'Crisis Lifeline', num: '988', icon: 'i-heart', kindKey: 'emerg.mental' },
         { n: 'Roadside', num: '511', icon: 'i-car', kindKey: 'emerg.trafficInfo' }],
    GB: [{ n: 'Emergency', num: '999', icon: 'i-shield', kindKey: 'emerg.all3' },
         { n: 'NHS 111', num: '111', icon: 'i-pulse', kindKey: 'emerg.medAdvice' },
         { n: 'Police non-emergency', num: '101', icon: 'i-shield', kindKey: 'emerg.nonUrgent' },
         { n: 'Gas emergency', num: '0800 111 999', icon: 'i-bolt', kindKey: 'emerg.gas' }],
    AE: [{ n: 'Police', num: '999', icon: 'i-shield', kindKey: 'emerg.police' },
         { n: 'Ambulance', num: '998', icon: 'i-pulse', kindKey: 'emerg.medical' },
         { n: 'Fire (Civil Defence)', num: '997', icon: 'i-flame', kindKey: 'emerg.fire' },
         { n: 'Coast Guard', num: '996', icon: 'i-navigation', kindKey: 'emerg.maritime' }],
    SA: [{ n: 'Unified Emergency', num: '911', icon: 'i-shield', kindKey: 'emerg.allServices' },
         { n: 'Red Crescent', num: '997', icon: 'i-pulse', kindKey: 'emerg.ambulance' },
         { n: 'Civil Defence', num: '998', icon: 'i-flame', kindKey: 'emerg.fireRescue' },
         { n: 'Traffic', num: '993', icon: 'i-car', kindKey: 'emerg.traffic' }],
    IN: [{ n: 'Emergency', num: '112', icon: 'i-shield', kindKey: 'emerg.allServices' },
         { n: 'Ambulance', num: '108', icon: 'i-pulse', kindKey: 'emerg.medical' },
         { n: 'Fire', num: '101', icon: 'i-flame', kindKey: 'emerg.fire' },
         { n: 'Women Helpline', num: '1091', icon: 'i-heart', kindKey: 'emerg.helpline' }]
  };

  var EMERGENCY_FALLBACK = [
    { n: 'International Emergency', num: '112', icon: 'i-shield', kindKey: 'emerg.gsm' },
    { n: 'Local Emergency', num: '911', icon: 'i-shield', kindKey: 'emerg.routed' }
  ];

  function emergencyFor(code) { return EMERGENCY[code] || EMERGENCY_FALLBACK; }

  /* ---------------------------------------------------------
     Public holidays (§80) — country calendars
     --------------------------------------------------------- */
  var HOLIDAYS = {
    PK: [['9 Nov', 'Iqbal Day', 'National'], ['25 Dec', 'Quaid-e-Azam Day', 'National'],
         ['5 Feb', 'Kashmir Day', 'National'], ['23 Mar', 'Pakistan Day', 'National'],
         ['1 May', 'Labour Day', 'National'], ['14 Aug', 'Independence Day', 'National']],
    US: [['28 Nov', 'Thanksgiving', 'Federal'], ['25 Dec', 'Christmas Day', 'Federal'],
         ['1 Jan', 'New Year’s Day', 'Federal'], ['20 Jan', 'MLK Jr. Day', 'Federal'],
         ['4 Jul', 'Independence Day', 'Federal'], ['2 Sep', 'Labor Day', 'Federal']],
    GB: [['25 Dec', 'Christmas Day', 'Bank holiday'], ['26 Dec', 'Boxing Day', 'Bank holiday'],
         ['1 Jan', 'New Year’s Day', 'Bank holiday'], ['18 Apr', 'Good Friday', 'Bank holiday'],
         ['5 May', 'Early May', 'Bank holiday'], ['25 Aug', 'Summer', 'Bank holiday']],
    AE: [['2 Dec', 'National Day', 'Public'], ['1 Jan', 'New Year’s Day', 'Public'],
         ['30 Mar', 'Eid al-Fitr', 'Public'], ['6 Jun', 'Eid al-Adha', 'Public'],
         ['26 Jun', 'Islamic New Year', 'Public'], ['1 Dec', 'Commemoration Day', 'Public']],
    SA: [['23 Sep', 'National Day', 'Public'], ['22 Feb', 'Founding Day', 'Public'],
         ['30 Mar', 'Eid al-Fitr', 'Public'], ['6 Jun', 'Eid al-Adha', 'Public']],
    IN: [['2 Oct', 'Gandhi Jayanti', 'Gazetted'], ['25 Dec', 'Christmas', 'Gazetted'],
         ['26 Jan', 'Republic Day', 'Gazetted'], ['15 Aug', 'Independence Day', 'Gazetted'],
         ['14 Mar', 'Holi', 'Gazetted'], ['20 Oct', 'Diwali', 'Gazetted']]
  };

  var HOLIDAYS_FALLBACK = [['1 Jan', 'New Year’s Day', 'Public'], ['25 Dec', 'Christmas Day', 'Public'],
    ['1 May', 'Labour Day', 'Public']];

  function holidaysFor(code) {
    return (HOLIDAYS[code] || HOLIDAYS_FALLBACK).map(function (h) {
      return { date: h[0], name: h[1], kind: h[2] };
    });
  }

  /* ---------------------------------------------------------
     Weather (§40) — enough to compose a real environmental
     dashboard: hourly, five-day, air quality, sun and moon.
     --------------------------------------------------------- */
  function hourly(base, seed) {
    var r = seedRand(seed), out = [], now = new Date().getHours();
    for (var i = 0; i < 24; i++) {
      var h = (now + i) % 24;
      var solar = Math.cos((h - 15) / 24 * Math.PI * 2);
      out.push({
        h: h,
        temp: Math.round(base + solar * 5 + (r() - 0.5) * 1.6),
        rain: Math.max(0, Math.round((r() * 40 - 12))),
        icon: h >= 6 && h <= 18 ? (r() > 0.7 ? 'i-cloud-sun' : 'i-sun') : 'i-moon'
      });
    }
    return out;
  }

  function daily(base, seed) {
    var r = seedRand(seed + 7), out = [];
    var names = ['Today', 'Tomorrow', '', '', ''];
    for (var i = 0; i < 5; i++) {
      var hi = Math.round(base + 2 + (r() - 0.4) * 5);
      out.push({
        label: names[i], offset: i,
        hi: hi, lo: Math.round(hi - 8 - r() * 4),
        rain: Math.round(r() * 70),
        icon: r() > 0.6 ? 'i-cloud-sun' : 'i-sun',
        desc: r() > 0.6 ? 'Cloud building' : 'Mostly clear'
      });
    }
    return out;
  }

  /* Health guidance must be readable in the reader's own language, so the
     band carries keys and the screen resolves them (§106). */
  var AQI_BANDS = [
    { max: 50, key: 'aqi.good', tone: 'ok' },
    { max: 100, key: 'aqi.moderate', tone: 'info' },
    { max: 150, key: 'aqi.sensitive', tone: 'warn' },
    { max: 200, key: 'aqi.unhealthy', tone: 'warn' },
    { max: 300, key: 'aqi.veryUnhealthy', tone: 'late' },
    { max: 999, key: 'aqi.hazardous', tone: 'late' }
  ];

  function aqiBand(v) {
    for (var i = 0; i < AQI_BANDS.length; i++) if (v <= AQI_BANDS[i].max) return AQI_BANDS[i];
    return AQI_BANDS[AQI_BANDS.length - 1];
  }

  /* Typical urban air quality by market — a Karachi September is not
     a Stockholm September, and pretending otherwise is worse than
     saying nothing. */
  var AQI_BY_COUNTRY = { PK: 164, IN: 178, BD: 186, CN: 112, AE: 96, SA: 104, EG: 128,
    NG: 118, ID: 108, TR: 74, US: 42, GB: 34, DE: 30, FR: 38, CA: 26, AU: 22, JP: 40, SE: 18 };

  /* One national figure is not a city reading. Offset it deterministically
     per city so two cities differ, and let the screen label the derived
     pollutant rows as estimated rather than measured (§108). */
  function aqiFor(code, city) {
    var base = AQI_BY_COUNTRY[code] || 56;
    var seed = 0;
    for (var i = 0; i < (city || '').length; i++) seed = (seed * 31 + (city || '').charCodeAt(i)) % 997;
    var v = Math.max(8, Math.round(base * (0.78 + (seed % 45) / 100)));
    return { value: v, band: aqiBand(v),
      parts: [
        { n: 'PM2.5', v: Math.round(v * 0.62), unit: 'µg/m³' },
        { n: 'PM10', v: Math.round(v * 0.94), unit: 'µg/m³' },
        { n: 'O₃', v: Math.round(v * 0.34), unit: 'ppb' },
        { n: 'NO₂', v: Math.round(v * 0.22), unit: 'ppb' }
      ] };
  }

  /* ---------------------------------------------------------
     Live tracking datasets (§42, §43)
     --------------------------------------------------------- */
  var FLIGHTS = [
    { no: 'EK 624', airline: 'Emirates', logo: 'EK', tone: 'rose', craft: 'Boeing 777-300ER', reg: 'A6-EQK',
      fromCode: 'DXB', from: 'Dubai Intl', toCode: 'ISB', to: 'Islamabad Intl',
      dep: '03:35', arr: '08:05', actual: '03:52', statusKey: 'flights.st.enroute', tone2: 'live', delay: 17,
      alt: 38000, speed: 902, progress: 0.62, gate: 'C12', term: '3', dist: 2038, eta: '08:22' },
    { no: 'PK 309', airline: 'Pakistan Intl', logo: 'PK', tone: 'green', craft: 'Airbus A320', reg: 'AP-BOL',
      fromCode: 'KHI', from: 'Jinnah Intl', toCode: 'LHE', to: 'Allama Iqbal Intl',
      dep: '07:00', arr: '08:45', actual: '07:00', statusKey: 'flights.st.landed', tone2: 'ok', delay: 0,
      alt: 0, speed: 0, progress: 1, gate: 'A4', term: 'M', dist: 1024, eta: '08:41' },
    { no: 'QR 614', airline: 'Qatar Airways', logo: 'QR', tone: 'violet', craft: 'Boeing 787-8', reg: 'A7-BCF',
      fromCode: 'DOH', from: 'Hamad Intl', toCode: 'LHE', to: 'Allama Iqbal Intl',
      dep: '02:10', arr: '08:30', actual: '02:44', statusKey: 'flights.st.delayed', tone2: 'late', delay: 34,
      alt: 36000, speed: 874, progress: 0.41, gate: 'B8', term: '1', dist: 2384, eta: '09:04' },
    { no: 'TK 710', airline: 'Turkish Airlines', logo: 'TK', tone: 'amber', craft: 'Airbus A321neo', reg: 'TC-LSK',
      fromCode: 'IST', from: 'Istanbul', toCode: 'KHI', to: 'Jinnah Intl',
      dep: '20:15', arr: '05:40', actual: '20:15', statusKey: 'flights.st.scheduled', tone2: 'info', delay: 0,
      alt: 0, speed: 0, progress: 0, gate: 'F22', term: 'I', dist: 4102, eta: '05:40' },
    { no: 'BA 262', airline: 'British Airways', logo: 'BA', tone: 'indigo', craft: 'Boeing 787-9', reg: 'G-ZBKA',
      fromCode: 'LHR', from: 'Heathrow', toCode: 'ISB', to: 'Islamabad Intl',
      dep: '21:40', arr: '10:15', actual: '21:58', statusKey: 'flights.st.enroute', tone2: 'live', delay: 18,
      alt: 40000, speed: 918, progress: 0.78, gate: '14', term: '5', dist: 5794, eta: '10:33' }
  ];

  var TRAINS = [
    { no: '5UP', name: 'Green Line Express', from: 'Karachi Cantt', to: 'Islamabad', fromCode: 'KYC', toCode: 'ISL',
      dep: '22:00', arr: '17:30', dur: '19h 30m', statusKey: 'trains.st.onTime', tone: 'ok', delay: 0, fare: 8900,
      platform: '4', speed: 96, next: 'Rohri Junction', progress: 0.48, classes: ['AC Sleeper', 'AC Business'] },
    { no: '7UP', name: 'Tezgam Express', from: 'Karachi Cantt', to: 'Rawalpindi', fromCode: 'KYC', toCode: 'RWP',
      dep: '17:00', arr: '16:15', dur: '23h 15m', statusKey: 'trains.st.late', tone: 'late', delay: 35, fare: 6300,
      platform: '2', speed: 78, next: 'Khanewal Junction', progress: 0.71, classes: ['AC Standard', 'Economy'] },
    { no: '41UP', name: 'Karakoram Express', from: 'Karachi Cantt', to: 'Lahore', fromCode: 'KYC', toCode: 'LHR',
      dep: '15:00', arr: '08:45', dur: '17h 45m', statusKey: 'trains.st.onTime', tone: 'ok', delay: 0, fare: 7100,
      platform: '1', speed: 104, next: 'Multan Cantt', progress: 0.62, classes: ['AC Business', 'Economy'] },
    { no: '27DN', name: 'Shalimar Express', from: 'Lahore', to: 'Karachi City', fromCode: 'LHR', toCode: 'KYC',
      dep: '06:15', arr: '01:30', dur: '19h 15m', statusKey: 'trains.st.departed', tone: 'ok', delay: 0, fare: 5400,
      platform: '6', speed: 88, next: 'Sahiwal', progress: 0.14, classes: ['AC Standard', 'Economy'] },
    { no: '101UP', name: 'Pakistan Express', from: 'Karachi Cantt', to: 'Rawalpindi', fromCode: 'KYC', toCode: 'RWP',
      dep: '11:30', arr: '13:00', dur: '25h 30m', statusKey: 'trains.st.late', tone: 'late', delay: 70, fare: 4850,
      platform: '3', speed: 62, next: 'Bahawalpur', progress: 0.36, classes: ['Economy'] }
  ];

  var TRAIN_STOPS = [
    { st: 'Karachi Cantt', sched: '22:00', act: '22:00', state: 'done', km: 0 },
    { st: 'Hyderabad Junction', sched: '00:05', act: '00:11', state: 'done', km: 165 },
    { st: 'Rohri Junction', sched: '04:20', act: '04:20', state: 'now', km: 480 },
    { st: 'Rahim Yar Khan', sched: '07:05', act: '—', state: 'next', km: 660 },
    { st: 'Multan Cantt', sched: '10:15', act: '—', state: 'next', km: 890 },
    { st: 'Lahore Junction', sched: '14:40', act: '—', state: 'next', km: 1210 },
    { st: 'Rawalpindi', sched: '16:55', act: '—', state: 'next', km: 1480 },
    { st: 'Islamabad', sched: '17:30', act: '—', state: 'next', km: 1505 }
  ];

  /* ---------------------------------------------------------
     Editorial (§44) — news needs categories and imagery
     --------------------------------------------------------- */
  var NEWS_CATEGORIES = ['Top', 'Business', 'World', 'Technology', 'Sport', 'Health', 'Lifestyle'];

  var NEWS = {
    PK: [
      { cat: 'Business', title: 'Rupee holds steady as remittances climb for a third month', src: 'Business Recorder', mins: 4, ago: '18 min', tone: 'accent', lead: 1 },
      { cat: 'Top', title: 'K-Electric announces revised loadshedding schedule for September', src: 'Dawn', mins: 3, ago: '42 min', tone: 'amber' },
      { cat: 'Sport', title: 'Pakistan name a 16-player squad for the home Test series', src: 'Geo Super', mins: 5, ago: '1 hr', tone: 'violet' },
      { cat: 'Technology', title: 'Karachi start-ups raised $84m this quarter, led by fintech', src: 'Profit', mins: 7, ago: '2 hr', tone: 'sky' },
      { cat: 'World', title: 'Regional trade corridor talks resume after a six-month pause', src: 'The News', mins: 6, ago: '3 hr', tone: 'indigo' },
      { cat: 'Health', title: 'Provincial dengue surveillance moves to a weekly reporting cycle', src: 'Express Tribune', mins: 4, ago: '4 hr', tone: 'green' }
    ],
    GLOBAL: [
      { cat: 'Business', title: 'Central banks signal a slower path on rate cuts into the new year', src: 'Reuters', mins: 5, ago: '22 min', tone: 'accent', lead: 1 },
      { cat: 'Technology', title: 'On-device models are quietly reshaping what phones can do offline', src: 'The Verge', mins: 8, ago: '1 hr', tone: 'violet' },
      { cat: 'World', title: 'Coastal cities publish a shared adaptation blueprint', src: 'AP', mins: 6, ago: '2 hr', tone: 'sky' },
      { cat: 'Health', title: 'A short walk after meals does more than a long one before bed', src: 'BBC', mins: 4, ago: '3 hr', tone: 'green' },
      { cat: 'Lifestyle', title: 'Why a shorter to-do list finishes more work', src: 'Lume Editorial', mins: 6, ago: '5 hr', tone: 'amber' },
      { cat: 'Sport', title: 'The tactical shift that decided the weekend’s biggest fixture', src: 'Guardian', mins: 7, ago: '6 hr', tone: 'rose' }
    ]
  };

  function newsFor(code) { return NEWS[code] || NEWS.GLOBAL; }

  /* ---------------------------------------------------------
     Qur'an, hadith, dua, names (§24.8–§24.13)
     --------------------------------------------------------- */
  var SURAHS = [
    { n: 1, name: 'Al-Fatihah', ar: 'الفاتحة', meaning: 'The Opening', ayat: 7, place: 'Meccan' },
    { n: 2, name: 'Al-Baqarah', ar: 'البقرة', meaning: 'The Cow', ayat: 286, place: 'Medinan' },
    { n: 3, name: 'Ali ‘Imran', ar: 'آل عمران', meaning: 'Family of Imran', ayat: 200, place: 'Medinan' },
    { n: 4, name: 'An-Nisa', ar: 'النساء', meaning: 'The Women', ayat: 176, place: 'Medinan' },
    { n: 13, name: 'Ar-Ra‘d', ar: 'الرعد', meaning: 'The Thunder', ayat: 43, place: 'Medinan' },
    { n: 18, name: 'Al-Kahf', ar: 'الكهف', meaning: 'The Cave', ayat: 110, place: 'Meccan' },
    { n: 36, name: 'Ya-Sin', ar: 'يس', meaning: 'Ya Sin', ayat: 83, place: 'Meccan' },
    { n: 55, name: 'Ar-Rahman', ar: 'الرحمن', meaning: 'The Most Merciful', ayat: 78, place: 'Medinan' },
    { n: 56, name: 'Al-Waqi‘ah', ar: 'الواقعة', meaning: 'The Inevitable', ayat: 96, place: 'Meccan' },
    { n: 67, name: 'Al-Mulk', ar: 'الملك', meaning: 'The Sovereignty', ayat: 30, place: 'Meccan' },
    { n: 112, name: 'Al-Ikhlas', ar: 'الإخلاص', meaning: 'The Sincerity', ayat: 4, place: 'Meccan' },
    { n: 114, name: 'An-Nas', ar: 'الناس', meaning: 'Mankind', ayat: 6, place: 'Meccan' }
  ];

  var AYAT = [
    { s: 13, a: 28, surah: 'Ar-Ra‘d', ar: 'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      tr: 'Those who believe, and whose hearts find rest in the remembrance of God — surely in the remembrance of God do hearts find rest.',
      tl: 'Alladhīna āmanū wa taṭma’innu qulūbuhum bi-dhikri-llāh' },
    { s: 94, a: 6, surah: 'Ash-Sharh', ar: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      tr: 'Indeed, with hardship comes ease.', tl: 'Inna ma‘a al-‘usri yusrā' },
    { s: 2, a: 286, surah: 'Al-Baqarah', ar: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
      tr: 'God does not burden a soul beyond what it can bear.', tl: 'Lā yukallifu-llāhu nafsan illā wus‘ahā' }
  ];

  var HADITH = [
    { text: 'The best of people are those who are most beneficial to people.', src: 'Al-Mu‘jam al-Awsat', ref: '5787', grade: 'Hasan', narrator: 'Jabir ibn Abdullah', collection: 'Tabarani' },
    { text: 'None of you truly believes until he loves for his brother what he loves for himself.', src: 'Sahih al-Bukhari', ref: '13', grade: 'Sahih', narrator: 'Anas ibn Malik', collection: 'Bukhari' },
    { text: 'Make things easy and do not make them difficult; give glad tidings and do not repel people.', src: 'Sahih al-Bukhari', ref: '69', grade: 'Sahih', narrator: 'Anas ibn Malik', collection: 'Bukhari' },
    { text: 'The strong is not the one who overcomes people by his strength, but the one who controls himself while in anger.', src: 'Sahih Muslim', ref: '2609', grade: 'Sahih', narrator: 'Abu Hurairah', collection: 'Muslim' }
  ];

  var DUA_CATEGORIES = [
    { id: 'morning', label: 'Morning & evening', icon: 'i-sun', n: 12 },
    { id: 'daily', label: 'Daily life', icon: 'i-home', n: 18 },
    { id: 'travel', label: 'Travel', icon: 'i-plane', n: 6 },
    { id: 'distress', label: 'Distress & worry', icon: 'i-heart', n: 9 },
    { id: 'food', label: 'Food & drink', icon: 'i-utensils', n: 5 },
    { id: 'sleep', label: 'Sleep', icon: 'i-moon', n: 7 }
  ];

  var DUAS = [
    { cat: 'morning', title: 'Morning remembrance', ar: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
      tr: 'We have entered the morning and the dominion belongs to God.', src: 'Sahih Muslim 2723' },
    { cat: 'travel', title: 'Dua for travel', ar: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا',
      tr: 'Glory to Him who has subjected this to us.', src: 'Az-Zukhruf 13' },
    { cat: 'distress', title: 'Relief from anxiety', ar: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
      tr: 'O God, I seek refuge in You from anxiety and sorrow.', src: 'Sahih al-Bukhari 6369' },
    { cat: 'food', title: 'Before eating', ar: 'بِسْمِ اللَّهِ',
      tr: 'In the name of God.', src: 'Sunan Abi Dawud 3767' },
    { cat: 'sleep', title: 'Before sleeping', ar: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      tr: 'In Your name, O God, I die and I live.', src: 'Sahih al-Bukhari 6324' }
  ];

  var NAMES99 = [
    { n: 1, ar: 'الرَّحْمَٰن', tl: 'Ar-Rahman', meaning: 'The Most Compassionate' },
    { n: 2, ar: 'الرَّحِيم', tl: 'Ar-Rahim', meaning: 'The Most Merciful' },
    { n: 3, ar: 'الْمَلِك', tl: 'Al-Malik', meaning: 'The Sovereign' },
    { n: 4, ar: 'الْقُدُّوس', tl: 'Al-Quddus', meaning: 'The Most Holy' },
    { n: 5, ar: 'السَّلَام', tl: 'As-Salam', meaning: 'The Source of Peace' },
    { n: 6, ar: 'الْمُؤْمِن', tl: 'Al-Mu’min', meaning: 'The Giver of Faith' },
    { n: 7, ar: 'الْمُهَيْمِن', tl: 'Al-Muhaymin', meaning: 'The Guardian' },
    { n: 8, ar: 'الْعَزِيز', tl: 'Al-Aziz', meaning: 'The Almighty' },
    { n: 9, ar: 'الْجَبَّار', tl: 'Al-Jabbar', meaning: 'The Compeller' },
    { n: 10, ar: 'الْمُتَكَبِّر', tl: 'Al-Mutakabbir', meaning: 'The Supreme' },
    { n: 11, ar: 'الْخَالِق', tl: 'Al-Khaliq', meaning: 'The Creator' },
    { n: 12, ar: 'الْبَارِئ', tl: 'Al-Bari', meaning: 'The Originator' }
  ];

  var DHIKR = [
    { ar: 'سُبْحَانَ اللَّه', tl: 'SubhanAllah', tr: 'Glory be to God', target: 33 },
    { ar: 'الْحَمْدُ لِلَّه', tl: 'Alhamdulillah', tr: 'All praise is for God', target: 33 },
    { ar: 'اللَّهُ أَكْبَر', tl: 'Allahu Akbar', tr: 'God is the greatest', target: 34 },
    { ar: 'لَا إِلَٰهَ إِلَّا اللَّه', tl: 'La ilaha illallah', tr: 'There is no god but God', target: 100 },
    { ar: 'أَسْتَغْفِرُ اللَّه', tl: 'Astaghfirullah', tr: 'I seek God’s forgiveness', target: 100 }
  ];

  /* Hijri months, for the Islamic calendar and Ramadan tools. */
  var HIJRI_MONTHS = ['Muharram', 'Safar', 'Rabi‘ al-Awwal', 'Rabi‘ al-Thani', 'Jumada al-Ula',
    'Jumada al-Akhirah', 'Rajab', 'Sha‘ban', 'Ramadan', 'Shawwal', 'Dhul-Qa‘dah', 'Dhul-Hijjah'];

  var ISLAMIC_EVENTS = [
    { name: 'Ramadan begins', hijri: '1 Ramadan', greg: '18 Feb', days: 163 },
    { name: 'Laylat al-Qadr (likely)', hijri: '27 Ramadan', greg: '16 Mar', days: 189 },
    { name: 'Eid al-Fitr', hijri: '1 Shawwal', greg: '20 Mar', days: 193 },
    { name: 'Day of Arafah', hijri: '9 Dhul-Hijjah', greg: '26 May', days: 260 },
    { name: 'Eid al-Adha', hijri: '10 Dhul-Hijjah', greg: '27 May', days: 261 }
  ];

  /* ---------------------------------------------------------
     Personal records — shaped like real records so the manager
     archetype has something to manage (§67, §69, §76, §78)
     --------------------------------------------------------- */
  var DOCUMENTS = [
    { name: 'Passport', cat: 'Identity', num: 'AB••••42', expires: '14 Mar 2029', days: 918, holder: 'You', files: 2 },
    { name: 'National ID', cat: 'Identity', num: '61101-•••••••-3', expires: '22 Nov 2026', days: 440, holder: 'You', files: 1 },
    { name: 'Driving Licence', cat: 'Vehicle', num: 'DL-••••-118', expires: '3 Oct 2025', days: 25, holder: 'You', files: 1 },
    { name: 'Car Registration', cat: 'Vehicle', num: 'ABC-••4', expires: '30 Sep 2025', days: 22, holder: 'Household', files: 3 },
    { name: 'Health Insurance', cat: 'Insurance', num: 'POL-••••-7781', expires: '1 Jan 2026', days: 115, holder: 'Family', files: 2 },
    { name: 'Tenancy Agreement', cat: 'Property', num: '—', expires: '31 Aug 2026', days: 357, holder: 'You', files: 4 },
    { name: 'Degree Certificate', cat: 'Education', num: '—', expires: 'No expiry', days: null, holder: 'You', files: 1 }
  ];

  var HEALTH_PEOPLE = [
    { id: 'you', name: 'You', initials: 'ZK', age: 32, blood: 'B+' },
    { id: 'partner', name: 'Sana', initials: 'SK', age: 30, blood: 'O+' },
    { id: 'child', name: 'Musa', initials: 'MK', age: 4, blood: 'B+' }
  ];

  var HEALTH_RECORDS = [
    { person: 'you', kind: 'Appointment', title: 'Annual physical', who: 'Dr Rehman · City Clinic', date: '18 Sep', state: 'upcoming', cost: 45 },
    { person: 'you', kind: 'Report', title: 'Lipid profile', who: 'Aga Khan Lab', date: '2 Aug', state: 'done', cost: 18, flag: 'Cholesterol slightly high' },
    { person: 'child', kind: 'Vaccination', title: 'MMR — dose 2', who: 'Community clinic', date: '11 Oct', state: 'upcoming', cost: 0 },
    { person: 'partner', kind: 'Appointment', title: 'Dental cleaning', who: 'Smile Studio', date: '24 Sep', state: 'upcoming', cost: 30 },
    { person: 'you', kind: 'Prescription', title: 'Vitamin D 50,000 IU', who: 'Weekly · 8 weeks', date: '5 Aug', state: 'active', cost: 12 },
    { person: 'child', kind: 'Report', title: 'Growth chart review', who: 'Community clinic', date: '14 Jul', state: 'done', cost: 0 }
  ];

  var VACCINES = [
    { person: 'child', name: 'MMR', dose: '2 of 2', date: '11 Oct 2025', state: 'due', by: 'Community clinic' },
    { person: 'child', name: 'DTP booster', dose: '4 of 4', date: '3 Mar 2025', state: 'done', by: 'Community clinic' },
    { person: 'child', name: 'Polio (OPV)', dose: '5 of 5', date: '18 Jan 2025', state: 'done', by: 'EPI centre' },
    { person: 'you', name: 'Influenza', dose: 'Annual', date: '2 Nov 2025', state: 'due', by: 'Pharmacy' },
    { person: 'you', name: 'Tetanus', dose: 'Booster', date: '9 Apr 2021', state: 'done', by: 'City clinic' }
  ];

  var MEDS = [
    { name: 'Vitamin D', dose: '50,000 IU', when: 'Weekly · Sunday 09:00', next: 'Sun 09:00', adherence: 0.94, left: 3, of: 8 },
    { name: 'Metformin', dose: '500 mg', when: 'Twice daily · 08:00, 20:00', next: 'Today 20:00', adherence: 0.88, left: 22, of: 60 },
    { name: 'Cetirizine', dose: '10 mg', when: 'As needed', next: '—', adherence: null, left: 9, of: 30 }
  ];

  var EXPENSE_CATEGORIES = [
    { id: 'groceries', label: 'Groceries', icon: 'i-cart', color: '#10998A', share: 0.28 },
    { id: 'transport', label: 'Transport', icon: 'i-car', color: '#6E62E5', share: 0.19 },
    { id: 'bills', label: 'Bills', icon: 'i-receipt', color: '#E0913A', share: 0.22 },
    { id: 'eating', label: 'Eating out', icon: 'i-utensils', color: '#DE6B7A', share: 0.14 },
    { id: 'health', label: 'Health', icon: 'i-pulse', color: '#3E9BD4', share: 0.09 },
    { id: 'other', label: 'Other', icon: 'i-grid', color: '#8B8D95', share: 0.08 }
  ];

  /* Amounts are authored in USD and converted by the locale engine, so a
     Karachi ledger reads in rupees and a London one in pounds. */
  var TRANSACTIONS = [
    { title: 'Metro Cash & Carry', cat: 'groceries', amount: -62, when: 'Today · 11:20', method: 'Card' },
    { title: 'Fuel — Shell', cat: 'transport', amount: -38, when: 'Today · 08:05', method: 'Card' },
    { title: 'Electricity bill', cat: 'bills', amount: -74, when: 'Yesterday', method: 'Auto-debit' },
    { title: 'Salary', cat: 'other', amount: 1850, when: '1 Sep', method: 'Transfer', income: 1 },
    { title: 'Coffee — Chaaye Khana', cat: 'eating', amount: -6, when: 'Yesterday', method: 'Cash' },
    { title: 'Pharmacy', cat: 'health', amount: -21, when: '4 Sep', method: 'Card' },
    { title: 'Internet', cat: 'bills', amount: -28, when: '3 Sep', method: 'Auto-debit' },
    { title: 'Ride to airport', cat: 'transport', amount: -14, when: '2 Sep', method: 'Wallet' }
  ];

  var SUBSCRIPTIONS = [
    { name: 'Netflix', cat: 'Entertainment', price: 9, cycle: 'Monthly', renews: '14 Sep', days: 6, logo: 'N', tone: 'rose' },
    { name: 'Spotify', cat: 'Music', price: 5, cycle: 'Monthly', renews: '21 Sep', days: 13, logo: 'S', tone: 'green' },
    { name: 'iCloud 200GB', cat: 'Storage', price: 3, cycle: 'Monthly', renews: '28 Sep', days: 20, logo: 'i', tone: 'sky' },
    { name: 'Gym membership', cat: 'Health', price: 22, cycle: 'Monthly', renews: '1 Oct', days: 23, logo: 'G', tone: 'amber' },
    { name: 'Domain renewal', cat: 'Work', price: 14, cycle: 'Yearly', renews: '3 Mar', days: 176, logo: 'D', tone: 'indigo' }
  ];

  var BILLS = [
    { name: 'Electricity', provider: 'K-Electric', amount: 74, due: '12 Sep', days: 4, state: 'due', ref: '••••4821' },
    { name: 'Gas', provider: 'SSGC', amount: 21, due: '18 Sep', days: 10, state: 'upcoming', ref: '••••7734' },
    { name: 'Internet', provider: 'Nayatel', amount: 28, due: '3 Sep', days: -5, state: 'overdue', ref: '••••1180' },
    { name: 'Water', provider: 'CDA', amount: 9, due: '25 Sep', days: 17, state: 'upcoming', ref: '••••0042' },
    { name: 'Mobile', provider: 'Jazz', amount: 12, due: '1 Sep', days: -7, state: 'paid', ref: '••••3390' }
  ];

  var GOALS = [
    { name: 'Emergency fund', target: 6000, saved: 3840, by: 'Dec 2026', icon: 'i-shield', tone: 'accent', monthly: 180 },
    { name: 'Umrah trip', target: 2400, saved: 1560, by: 'Mar 2026', icon: 'i-plane', tone: 'violet', monthly: 140 },
    { name: 'New laptop', target: 1400, saved: 420, by: 'Jun 2026', icon: 'i-grid', tone: 'amber', monthly: 110 }
  ];

  var PARCELS = [
    { ref: 'TCS-8842910', carrier: 'TCS', logo: 'TC', tone: 'amber', item: 'Keyboard', status: 'Out for delivery',
      state: 'live', eta: 'Today, by 18:00', place: 'Islamabad hub', progress: 0.85,
      events: [['Booked', 'Karachi', '4 Sep, 14:10', 'done'], ['In transit', 'Lahore hub', '5 Sep, 03:20', 'done'],
              ['Arrived', 'Islamabad hub', '6 Sep, 07:45', 'done'], ['Out for delivery', 'Islamabad', 'Today, 09:12', 'now'],
              ['Delivered', 'Islamabad', 'Expected today', 'next']] },
    { ref: 'LP-5521773', carrier: 'Leopards', logo: 'LP', tone: 'rose', item: 'Books', status: 'In transit',
      state: 'info', eta: 'Wed, 10 Sep', place: 'Multan hub', progress: 0.45,
      events: [['Booked', 'Karachi', '6 Sep, 11:00', 'done'], ['In transit', 'Multan hub', 'Today, 04:30', 'now'],
              ['Arriving', 'Islamabad', 'Expected 10 Sep', 'next']] }
  ];

  var RECIPES = [
    { name: 'Chicken Karahi', cuisine: 'Pakistani', prep: 15, cook: 35, serves: 4, kcal: 520, tone: 'rose', glyph: '🍲',
      tags: ['Dinner', 'Spicy'], ingredients: 12, steps: 8, fav: 1 },
    { name: 'Shakshuka', cuisine: 'Levantine', prep: 10, cook: 20, serves: 2, kcal: 310, tone: 'amber', glyph: '🍳',
      tags: ['Breakfast', 'Vegetarian'], ingredients: 9, steps: 6 },
    { name: 'Daal Chawal', cuisine: 'Pakistani', prep: 10, cook: 40, serves: 4, kcal: 430, tone: 'green', glyph: '🍛',
      tags: ['Lunch', 'Budget'], ingredients: 8, steps: 5, fav: 1 },
    { name: 'Greek Salad', cuisine: 'Mediterranean', prep: 12, cook: 0, serves: 2, kcal: 220, tone: 'sky', glyph: '🥗',
      tags: ['Light', 'No cook'], ingredients: 7, steps: 3 },
    { name: 'Beef Pulao', cuisine: 'Pakistani', prep: 20, cook: 55, serves: 6, kcal: 610, tone: 'violet', glyph: '🍚',
      tags: ['Dinner', 'Family'], ingredients: 14, steps: 9 },
    { name: 'Overnight Oats', cuisine: 'Global', prep: 5, cook: 0, serves: 1, kcal: 290, tone: 'indigo', glyph: '🥣',
      tags: ['Breakfast', 'Make ahead'], ingredients: 6, steps: 3 }
  ];

  var MOBILE_PACKAGES = {
    PK: [
      { op: 'Jazz', name: 'Super Duper Card', data: '15 GB', mins: '3000 On-net', sms: '3000', valid: '30 days', price: 1150, tone: 'rose' },
      { op: 'Zong', name: 'Super Card Max', data: '20 GB', mins: '3000 On-net', sms: '3000', valid: '30 days', price: 1200, tone: 'green' },
      { op: 'Ufone', name: 'Super Card Plus', data: '12 GB', mins: '2000 On-net', sms: '2000', valid: '30 days', price: 1050, tone: 'amber' },
      { op: 'Telenor', name: 'Super Card', data: '10 GB', mins: '2500 On-net', sms: '2500', valid: '30 days', price: 1000, tone: 'sky' }
    ]
  };

  var NAT_SAVINGS = {
    PK: [
      { name: 'Behbood Savings Certificate', rate: 15.36, term: '10 years', payout: 'Monthly', min: 5000, eligible: 'Widows, seniors, disabled' },
      { name: 'Defence Savings Certificate', rate: 13.02, term: '10 years', payout: 'On maturity', min: 500, eligible: 'All' },
      { name: 'Regular Income Certificate', rate: 13.44, term: '5 years', payout: 'Monthly', min: 50000, eligible: 'All' },
      { name: 'Special Savings Certificate', rate: 12.60, term: '3 years', payout: 'Half-yearly', min: 500, eligible: 'All' },
      { name: 'Pensioners’ Benefit Account', rate: 15.36, term: '10 years', payout: 'Monthly', min: 5000, eligible: 'Pensioners' }
    ]
  };

  var PRIZE_BONDS = {
    PK: [
      { denom: 100, draw: 'Draw 47', date: '15 Sep', first: 700000, second: 200000, third: 1000, winners: 2394 },
      { denom: 200, draw: 'Draw 98', date: '15 Sep', first: 750000, second: 250000, third: 1250, winners: 2394 },
      { denom: 750, draw: 'Draw 102', date: '15 Oct', first: 1500000, second: 500000, third: 9300, winners: 1696 },
      { denom: 1500, draw: 'Draw 99', date: '15 Nov', first: 3000000, second: 1000000, third: 18500, winners: 1696 }
    ]
  };

  /* ---------------------------------------------------------
     Tax brackets — country-configurable (§29)
     --------------------------------------------------------- */
  var TAX = {
    PK: { ccy: 'PKR', year: '2025-26', authority: 'FBR salaried slabs', annualise: 12,
      bands: [[600000, 0, 0], [1200000, 0.01, 0], [2200000, 0.11, 6000], [3200000, 0.23, 116000],
              [4100000, 0.30, 346000], [Infinity, 0.35, 616000]] },
    GB: { ccy: 'GBP', year: '2025-26', authority: 'HMRC income tax (England)', annualise: 12,
      bands: [[12570, 0, 0], [50270, 0.20, 0], [125140, 0.40, 7540], [Infinity, 0.45, 37426]] },
    US: { ccy: 'USD', year: '2025', authority: 'IRS single filer', annualise: 12,
      bands: [[11925, 0.10, 0], [48475, 0.12, 1192], [103350, 0.22, 5578], [197300, 0.24, 17651],
              [250525, 0.32, 40199], [626350, 0.35, 57231], [Infinity, 0.37, 188770]] },
    IN: { ccy: 'INR', year: '2025-26', authority: 'New regime slabs', annualise: 12,
      bands: [[400000, 0, 0], [800000, 0.05, 0], [1200000, 0.10, 20000], [1600000, 0.15, 60000],
              [2000000, 0.20, 120000], [2400000, 0.25, 200000], [Infinity, 0.30, 300000]] },
    AE: { ccy: 'AED', year: '2025', authority: 'No personal income tax', annualise: 12, bands: [[Infinity, 0, 0]] },
    SA: { ccy: 'SAR', year: '2025', authority: 'No personal income tax', annualise: 12, bands: [[Infinity, 0, 0]] }
  };

  function taxFor(code) { return TAX[code] || null; }

  /* Where there is no income tax there are still levies a salary meets, so
     the screen has something true to say rather than an apology (§91, §112). */
  var LEVIES = {
    AE: [['levy.vat', 5], ['levy.pension', 5], ['levy.corporate', 9]],
    SA: [['levy.vat', 15], ['levy.gosi', 9.75], ['levy.zakatRate', 2.5]],
    GB: [['levy.vat', 20], ['levy.ni', 8]],
    US: [['levy.socialSecurity', 6.2], ['levy.medicare', 1.45]],
    PK: [['levy.gst', 18], ['levy.eobi', 1]],
    IN: [['levy.gst', 18], ['levy.pf', 12]]
  };
  var LEVIES_FALLBACK = [['levy.vat', 20]];

  function leviesFor(code) {
    return (LEVIES[code] || LEVIES_FALLBACK).map(function (l) {
      return { key: l[0], rate: l[1] };
    });
  }

  /* ---------------------------------------------------------
     Loadshedding, vehicle, learning, play
     --------------------------------------------------------- */
  var LOADSHED = [
    { from: '06:00', to: '07:00', kind: 'Outage', state: 'done' },
    { from: '10:00', to: '11:00', kind: 'Outage', state: 'done' },
    { from: '14:00', to: '16:00', kind: 'Outage', state: 'now' },
    { from: '19:00', to: '20:00', kind: 'Outage', state: 'next' },
    { from: '23:00', to: '00:00', kind: 'Outage', state: 'next' }
  ];

  var VEHICLES = [
    { plate: 'ABC-124', make: 'Toyota Corolla', year: 2019, tone: 'sky', token: '30 Sep', tokenDays: 22,
      insurance: '14 Dec', fines: 1, fineAmount: 12, odo: 84200 },
    { plate: 'LEB-8842', make: 'Honda CD-70', year: 2022, tone: 'amber', token: '11 Nov', tokenDays: 64,
      insurance: '—', fines: 0, fineAmount: 0, odo: 21400 }
  ];

  var COURSES = [
    { name: 'Arabic — Level 2', provider: 'Self-paced', progress: 0.62, mins: 25, streak: 9, tone: 'accent' },
    { name: 'Financial modelling', provider: 'Course library', progress: 0.34, mins: 40, streak: 3, tone: 'violet' },
    { name: 'Photography basics', provider: 'Weekend series', progress: 0.88, mins: 15, streak: 12, tone: 'amber' }
  ];

  var GAMES = [
    { name: 'Number Grid', kind: 'Puzzle', best: '01:42', plays: 38, tone: 'violet', glyph: '🔢' },
    { name: 'Word Chain', kind: 'Word', best: '182 pts', plays: 21, tone: 'accent', glyph: '🔤' },
    { name: 'Memory Match', kind: 'Memory', best: '24 moves', plays: 14, tone: 'amber', glyph: '🧠' },
    { name: 'Quick Maths', kind: 'Arithmetic', best: '96%', plays: 52, tone: 'sky', glyph: '➗' }
  ];

  var CRICKET = {
    live: { t1: 'PAK', t1full: 'Pakistan', t2: 'ENG', t2full: 'England',
      s1: '214/4', o1: '38.2', s2: '—', o2: '—', rr: 5.58, req: null,
      statusKey: 'cricket.choseToBat', venue: 'Gaddafi Stadium, Lahore', format: 'ODI · 2nd of 3',
      batters: [{ n: 'Babar Azam', r: 88, b: 94, f: 7, s: 1, sr: 93.6, out: false },
                { n: 'Salman Agha', r: 42, b: 38, f: 4, s: 0, sr: 110.5, out: false }],
      bowlers: [{ n: 'A. Rashid', o: 8, m: 0, r: 41, w: 2, ec: 5.12 },
                { n: 'J. Archer', o: 7.2, m: 1, r: 38, w: 1, ec: 5.18 }] },
    fixtures: [
      { t1: 'PAK', t2: 'ENG', when: '11 Sep · 15:00', venue: 'Karachi', format: 'ODI 3' },
      { t1: 'IND', t2: 'AUS', when: '12 Sep · 09:30', venue: 'Chennai', format: 'T20 1' },
      { t1: 'SA', t2: 'NZ', when: '14 Sep · 13:00', venue: 'Cape Town', format: 'Test 1' }
    ],
    standings: [
      { team: 'India', p: 8, w: 6, l: 2, pts: 12, nrr: '+0.84' },
      { team: 'Australia', p: 8, w: 5, l: 3, pts: 10, nrr: '+0.42' },
      { team: 'Pakistan', p: 8, w: 5, l: 3, pts: 10, nrr: '+0.18' },
      { team: 'England', p: 8, w: 4, l: 4, pts: 8, nrr: '−0.06' },
      { team: 'South Africa', p: 8, w: 3, l: 5, pts: 6, nrr: '−0.31' }
    ]
  };

  /* World clock — a handful of anchors plus whatever the user's own
     zone is, resolved through the locale engine. */
  var WORLD_CITIES = [
    { city: 'Karachi', tz: 'Asia/Karachi', cc: 'PK' },
    { city: 'Dubai', tz: 'Asia/Dubai', cc: 'AE' },
    { city: 'London', tz: 'Europe/London', cc: 'GB' },
    { city: 'New York', tz: 'America/New_York', cc: 'US' },
    { city: 'Tokyo', tz: 'Asia/Tokyo', cc: 'JP' },
    { city: 'Singapore', tz: 'Asia/Singapore', cc: 'SG' },
    { city: 'Istanbul', tz: 'Europe/Istanbul', cc: 'TR' },
    { city: 'Sydney', tz: 'Australia/Sydney', cc: 'AU' }
  ];

  return {
    walk: walk, seedRand: seedRand,
    EXCHANGES: EXCHANGES, exchangeFor: exchangeFor, GLOBAL_INDICES: GLOBAL_INDICES, CRYPTO: CRYPTO, ETFS: ETFS,
    fuelFor: fuelFor, emergencyFor: emergencyFor, holidaysFor: holidaysFor,
    hourly: hourly, daily: daily, aqiFor: aqiFor, aqiBand: aqiBand,
    FLIGHTS: FLIGHTS, TRAINS: TRAINS, TRAIN_STOPS: TRAIN_STOPS,
    NEWS_CATEGORIES: NEWS_CATEGORIES, newsFor: newsFor,
    SURAHS: SURAHS, AYAT: AYAT, HADITH: HADITH, DUA_CATEGORIES: DUA_CATEGORIES, DUAS: DUAS,
    NAMES99: NAMES99, DHIKR: DHIKR, HIJRI_MONTHS: HIJRI_MONTHS, ISLAMIC_EVENTS: ISLAMIC_EVENTS,
    DOCUMENTS: DOCUMENTS, HEALTH_PEOPLE: HEALTH_PEOPLE, HEALTH_RECORDS: HEALTH_RECORDS,
    VACCINES: VACCINES, MEDS: MEDS,
    EXPENSE_CATEGORIES: EXPENSE_CATEGORIES, TRANSACTIONS: TRANSACTIONS, SUBSCRIPTIONS: SUBSCRIPTIONS,
    BILLS: BILLS, GOALS: GOALS, PARCELS: PARCELS, RECIPES: RECIPES,
    MOBILE_PACKAGES: MOBILE_PACKAGES, NAT_SAVINGS: NAT_SAVINGS, PRIZE_BONDS: PRIZE_BONDS,
    taxFor: taxFor, leviesFor: leviesFor, TAX: TAX,
    LOADSHED: LOADSHED, VEHICLES: VEHICLES, COURSES: COURSES, GAMES: GAMES, CRICKET: CRICKET,
    WORLD_CITIES: WORLD_CITIES
  };
})();
