/* ============================================================
   Lume — global location database
   Every country on earth, with currency, primary language,
   timezone and a seed of cities. Region/state is modelled only
   where a country actually uses it.

   Country and city NAMES are not stored: Intl.DisplayNames
   renders them in the user's language, so switching to Urdu or
   Arabic localises the whole picker for free.

   Row format: CC|CUR|LANG|TZ|City,City,City|lat,lon
   ============================================================ */
window.LUME_GEO = (function () {
  'use strict';

  /* International dialling codes. Deliberately partial: a country that is
     not here shows no prefix at all, which is honest -- far better than
     assuming +92 for the world (§124.16). */
  var DIAL = {
    PK: 92, IN: 91, BD: 880, LK: 94, NP: 977, AF: 93, IR: 98,
    US: 1, CA: 1, MX: 52, BR: 55, AR: 54, CL: 56, CO: 57, PE: 51,
    GB: 44, IE: 353, FR: 33, DE: 49, IT: 39, ES: 34, PT: 351, NL: 31,
    BE: 32, CH: 41, AT: 43, SE: 46, NO: 47, DK: 45, FI: 358, PL: 48,
    GR: 30, RU: 7, UA: 380, TR: 90,
    AE: 971, SA: 966, QA: 974, KW: 965, OM: 968, BH: 973, JO: 962,
    LB: 961, IQ: 964, EG: 20, MA: 212, DZ: 213, TN: 216,
    NG: 234, GH: 233, KE: 254, TZ: 255, UG: 256, ET: 251, ZA: 27,
    CN: 86, JP: 81, KR: 82, ID: 62, MY: 60, SG: 65, TH: 66, VN: 84,
    PH: 63, AU: 61, NZ: 64
  };

  function dial(cc) {
    return DIAL[cc] ? '+' + DIAL[cc] : null;
  }

  var ROWS = [
'AD|EUR|ca|Europe/Andorra|Andorra la Vella|42.51,1.52',
'AE|AED|ar|Asia/Dubai|Dubai,Abu Dhabi,Sharjah,Ajman,Al Ain,Ras Al Khaimah,Fujairah|25.20,55.27',
'AF|AFN|fa|Asia/Kabul|Kabul,Kandahar,Herat,Mazar-i-Sharif|34.53,69.17',
'AG|XCD|en|America/Antigua|St John’s|17.12,-61.85',
'AL|ALL|sq|Europe/Tirane|Tirana,Durrës|41.33,19.82',
'AM|AMD|hy|Asia/Yerevan|Yerevan,Gyumri|40.18,44.51',
'AO|AOA|pt|Africa/Luanda|Luanda,Huambo|-8.84,13.23',
'AR|ARS|es|America/Argentina/Buenos_Aires|Buenos Aires,Córdoba,Rosario,Mendoza|-34.60,-58.38',
'AT|EUR|de|Europe/Vienna|Vienna,Graz,Linz,Salzburg|48.21,16.37',
'AU|AUD|en|Australia/Sydney||-33.87,151.21',
'AZ|AZN|az|Asia/Baku|Baku,Ganja|40.41,49.87',
'BA|BAM|bs|Europe/Sarajevo|Sarajevo,Banja Luka,Mostar|43.86,18.41',
'BB|BBD|en|America/Barbados|Bridgetown|13.10,-59.62',
'BD|BDT|bn|Asia/Dhaka|Dhaka,Chattogram,Khulna,Sylhet,Rajshahi|23.81,90.41',
'BE|EUR|nl|Europe/Brussels|Brussels,Antwerp,Ghent,Bruges|50.85,4.35',
'BF|XOF|fr|Africa/Ouagadougou|Ouagadougou,Bobo-Dioulasso|12.37,-1.52',
'BG|BGN|bg|Europe/Sofia|Sofia,Plovdiv,Varna|42.70,23.32',
'BH|BHD|ar|Asia/Bahrain|Manama,Riffa,Muharraq|26.23,50.59',
'BI|BIF|fr|Africa/Bujumbura|Gitega,Bujumbura|-3.43,29.93',
'BJ|XOF|fr|Africa/Porto-Novo|Cotonou,Porto-Novo|6.37,2.39',
'BN|BND|ms|Asia/Brunei|Bandar Seri Begawan|4.90,114.94',
'BO|BOB|es|America/La_Paz|La Paz,Santa Cruz,Cochabamba|-16.49,-68.13',
'BR|BRL|pt|America/Sao_Paulo|São Paulo,Rio de Janeiro,Brasília,Salvador,Fortaleza,Belo Horizonte,Curitiba,Recife|-23.55,-46.63',
'BS|BSD|en|America/Nassau|Nassau|25.05,-77.35',
'BT|BTN|dz|Asia/Thimphu|Thimphu|27.47,89.64',
'BW|BWP|en|Africa/Gaborone|Gaborone|-24.63,25.91',
'BY|BYN|be|Europe/Minsk|Minsk,Gomel|53.90,27.57',
'BZ|BZD|en|America/Belize|Belize City,Belmopan|17.50,-88.20',
'CA|CAD|en|America/Toronto||43.65,-79.38',
'CD|CDF|fr|Africa/Kinshasa|Kinshasa,Lubumbashi|-4.44,15.27',
'CF|XAF|fr|Africa/Bangui|Bangui|4.39,18.56',
'CG|XAF|fr|Africa/Brazzaville|Brazzaville,Pointe-Noire|-4.26,15.24',
'CH|CHF|de|Europe/Zurich|Zurich,Geneva,Basel,Bern,Lausanne|47.38,8.54',
'CI|XOF|fr|Africa/Abidjan|Abidjan,Yamoussoukro|5.36,-4.01',
'CL|CLP|es|America/Santiago|Santiago,Valparaíso,Concepción|-33.45,-70.67',
'CM|XAF|fr|Africa/Douala|Douala,Yaoundé|4.05,9.77',
'CN|CNY|zh|Asia/Shanghai|Shanghai,Beijing,Guangzhou,Shenzhen,Chengdu,Hangzhou,Wuhan,Xi’an|31.23,121.47',
'CO|COP|es|America/Bogota|Bogotá,Medellín,Cali,Barranquilla|4.71,-74.07',
'CR|CRC|es|America/Costa_Rica|San José|9.93,-84.09',
'CU|CUP|es|America/Havana|Havana,Santiago de Cuba|23.11,-82.37',
'CV|CVE|pt|Atlantic/Cape_Verde|Praia|14.93,-23.51',
'CY|EUR|el|Asia/Nicosia|Nicosia,Limassol|35.19,33.38',
'CZ|CZK|cs|Europe/Prague|Prague,Brno,Ostrava|50.08,14.44',
'DE|EUR|de|Europe/Berlin|Berlin,Munich,Hamburg,Frankfurt,Cologne,Stuttgart,Düsseldorf,Leipzig|52.52,13.40',
'DJ|DJF|fr|Africa/Djibouti|Djibouti|11.59,43.15',
'DK|DKK|da|Europe/Copenhagen|Copenhagen,Aarhus,Odense|55.68,12.57',
'DM|XCD|en|America/Dominica|Roseau|15.30,-61.39',
'DO|DOP|es|America/Santo_Domingo|Santo Domingo,Santiago|18.49,-69.93',
'DZ|DZD|ar|Africa/Algiers|Algiers,Oran,Constantine|36.75,3.06',
'EC|USD|es|America/Guayaquil|Quito,Guayaquil|-0.18,-78.47',
'EE|EUR|et|Europe/Tallinn|Tallinn,Tartu|59.44,24.75',
'EG|EGP|ar|Africa/Cairo|Cairo,Alexandria,Giza,Luxor,Aswan|30.04,31.24',
'ER|ERN|ti|Africa/Asmara|Asmara|15.34,38.93',
'ES|EUR|es|Europe/Madrid|Madrid,Barcelona,Valencia,Seville,Bilbao,Málaga|40.42,-3.70',
'ET|ETB|am|Africa/Addis_Ababa|Addis Ababa,Dire Dawa|9.03,38.74',
'FI|EUR|fi|Europe/Helsinki|Helsinki,Espoo,Tampere|60.17,24.94',
'FJ|FJD|en|Pacific/Fiji|Suva|-18.14,178.44',
'FM|USD|en|Pacific/Pohnpei|Palikir|6.92,158.16',
'FR|EUR|fr|Europe/Paris|Paris,Marseille,Lyon,Toulouse,Nice,Nantes,Bordeaux,Lille|48.86,2.35',
'GA|XAF|fr|Africa/Libreville|Libreville|0.42,9.47',
'GB|GBP|en|Europe/London||51.51,-0.13',
'GD|XCD|en|America/Grenada|St George’s|12.06,-61.75',
'GE|GEL|ka|Asia/Tbilisi|Tbilisi,Batumi|41.72,44.83',
'GH|GHS|en|Africa/Accra|Accra,Kumasi,Tamale|5.60,-0.19',
'GM|GMD|en|Africa/Banjul|Banjul|13.45,-16.58',
'GN|GNF|fr|Africa/Conakry|Conakry|9.64,-13.58',
'GQ|XAF|es|Africa/Malabo|Malabo|3.75,8.78',
'GR|EUR|el|Europe/Athens|Athens,Thessaloniki,Patras|37.98,23.73',
'GT|GTQ|es|America/Guatemala|Guatemala City|14.63,-90.51',
'GW|XOF|pt|Africa/Bissau|Bissau|11.86,-15.60',
'GY|GYD|en|America/Guyana|Georgetown|6.80,-58.16',
'HN|HNL|es|America/Tegucigalpa|Tegucigalpa,San Pedro Sula|14.07,-87.19',
'HR|EUR|hr|Europe/Zagreb|Zagreb,Split,Rijeka|45.81,15.98',
'HT|HTG|fr|America/Port-au-Prince|Port-au-Prince|18.59,-72.31',
'HU|HUF|hu|Europe/Budapest|Budapest,Debrecen|47.50,19.04',
'ID|IDR|id|Asia/Jakarta|Jakarta,Surabaya,Bandung,Medan,Semarang,Makassar,Palembang,Yogyakarta|-6.21,106.85',
'IE|EUR|en|Europe/Dublin|Dublin,Cork,Galway,Limerick|53.35,-6.26',
'IL|ILS|he|Asia/Jerusalem|Jerusalem,Tel Aviv,Haifa|31.77,35.21',
'IN|INR|hi|Asia/Kolkata||28.61,77.21',
'IQ|IQD|ar|Asia/Baghdad|Baghdad,Basra,Mosul,Erbil,Najaf,Karbala|33.31,44.36',
'IR|IRR|fa|Asia/Tehran|Tehran,Mashhad,Isfahan,Shiraz,Tabriz|35.69,51.39',
'IS|ISK|is|Atlantic/Reykjavik|Reykjavík|64.15,-21.94',
'IT|EUR|it|Europe/Rome|Rome,Milan,Naples,Turin,Florence,Bologna,Venice|41.90,12.50',
'JM|JMD|en|America/Jamaica|Kingston,Montego Bay|17.97,-76.79',
'JO|JOD|ar|Asia/Amman|Amman,Zarqa,Irbid|31.95,35.93',
'JP|JPY|ja|Asia/Tokyo|Tokyo,Osaka,Yokohama,Nagoya,Sapporo,Fukuoka,Kyoto,Kobe|35.68,139.69',
'KE|KES|sw|Africa/Nairobi|Nairobi,Mombasa,Kisumu,Nakuru|-1.29,36.82',
'KG|KGS|ky|Asia/Bishkek|Bishkek,Osh|42.87,74.59',
'KH|KHR|km|Asia/Phnom_Penh|Phnom Penh,Siem Reap|11.56,104.92',
'KI|AUD|en|Pacific/Tarawa|Tarawa|1.33,172.98',
'KM|KMF|ar|Indian/Comoro|Moroni|-11.70,43.26',
'KN|XCD|en|America/St_Kitts|Basseterre|17.30,-62.72',
'KR|KRW|ko|Asia/Seoul|Seoul,Busan,Incheon,Daegu|37.57,126.98',
'KW|KWD|ar|Asia/Kuwait|Kuwait City,Hawalli,Salmiya|29.38,47.99',
'KZ|KZT|kk|Asia/Almaty|Almaty,Astana,Shymkent|43.24,76.89',
'LA|LAK|lo|Asia/Vientiane|Vientiane|17.97,102.63',
'LB|LBP|ar|Asia/Beirut|Beirut,Tripoli,Sidon|33.89,35.50',
'LC|XCD|en|America/St_Lucia|Castries|14.01,-60.99',
'LI|CHF|de|Europe/Vaduz|Vaduz|47.14,9.52',
'LK|LKR|si|Asia/Colombo|Colombo,Kandy,Galle,Jaffna|6.93,79.86',
'LR|LRD|en|Africa/Monrovia|Monrovia|6.30,-10.80',
'LS|LSL|en|Africa/Maseru|Maseru|-29.31,27.48',
'LT|EUR|lt|Europe/Vilnius|Vilnius,Kaunas|54.69,25.28',
'LU|EUR|fr|Europe/Luxembourg|Luxembourg|49.61,6.13',
'LV|EUR|lv|Europe/Riga|Riga,Daugavpils|56.95,24.11',
'LY|LYD|ar|Africa/Tripoli|Tripoli,Benghazi|32.89,13.19',
'MA|MAD|ar|Africa/Casablanca|Casablanca,Rabat,Marrakesh,Fez,Tangier,Agadir|33.57,-7.59',
'MC|EUR|fr|Europe/Monaco|Monaco|43.74,7.42',
'MD|MDL|ro|Europe/Chisinau|Chișinău|47.01,28.86',
'ME|EUR|sr|Europe/Podgorica|Podgorica|42.44,19.26',
'MG|MGA|fr|Indian/Antananarivo|Antananarivo|-18.88,47.51',
'MH|USD|en|Pacific/Majuro|Majuro|7.09,171.38',
'MK|MKD|mk|Europe/Skopje|Skopje|41.99,21.43',
'ML|XOF|fr|Africa/Bamako|Bamako|12.64,-8.00',
'MM|MMK|my|Asia/Yangon|Yangon,Mandalay,Naypyidaw|16.87,96.20',
'MN|MNT|mn|Asia/Ulaanbaatar|Ulaanbaatar|47.89,106.91',
'MR|MRU|ar|Africa/Nouakchott|Nouakchott|18.08,-15.98',
'MT|EUR|mt|Europe/Malta|Valletta|35.90,14.51',
'MU|MUR|en|Indian/Mauritius|Port Louis|-20.16,57.50',
'MV|MVR|dv|Indian/Maldives|Malé|4.18,73.51',
'MW|MWK|en|Africa/Blantyre|Lilongwe,Blantyre|-13.98,33.79',
'MX|MXN|es|America/Mexico_City|Mexico City,Guadalajara,Monterrey,Puebla,Tijuana,Cancún|19.43,-99.13',
'MY|MYR|ms|Asia/Kuala_Lumpur|Kuala Lumpur,George Town,Johor Bahru,Ipoh,Kuching,Shah Alam|3.14,101.69',
'MZ|MZN|pt|Africa/Maputo|Maputo,Beira|-25.97,32.57',
'NA|NAD|en|Africa/Windhoek|Windhoek|-22.56,17.08',
'NE|XOF|fr|Africa/Niamey|Niamey|13.51,2.11',
'NG|NGN|en|Africa/Lagos|Lagos,Abuja,Kano,Ibadan,Port Harcourt,Benin City,Kaduna|6.52,3.38',
'NI|NIO|es|America/Managua|Managua|12.11,-86.24',
'NL|EUR|nl|Europe/Amsterdam|Amsterdam,Rotterdam,The Hague,Utrecht,Eindhoven|52.37,4.90',
'NO|NOK|no|Europe/Oslo|Oslo,Bergen,Trondheim|59.91,10.75',
'NP|NPR|ne|Asia/Kathmandu|Kathmandu,Pokhara|27.72,85.32',
'NR|AUD|en|Pacific/Nauru|Yaren|-0.55,166.92',
'NZ|NZD|en|Pacific/Auckland|Auckland,Wellington,Christchurch|-36.85,174.76',
'OM|OMR|ar|Asia/Muscat|Muscat,Salalah,Sohar|23.59,58.41',
'PA|PAB|es|America/Panama|Panama City|8.98,-79.52',
'PE|PEN|es|America/Lima|Lima,Arequipa,Trujillo|-12.05,-77.04',
'PG|PGK|en|Pacific/Port_Moresby|Port Moresby|-9.44,147.18',
'PH|PHP|fil|Asia/Manila|Manila,Quezon City,Cebu,Davao,Makati|14.60,120.98',
'PK|PKR|en|Asia/Karachi||33.69,73.05',
'PL|PLN|pl|Europe/Warsaw|Warsaw,Kraków,Łódź,Wrocław,Poznań,Gdańsk|52.23,21.01',
'PS|ILS|ar|Asia/Hebron|Gaza,Ramallah,Hebron,Nablus|31.50,34.47',
'PT|EUR|pt|Europe/Lisbon|Lisbon,Porto,Braga,Faro|38.72,-9.14',
'PW|USD|en|Pacific/Palau|Ngerulmud|7.50,134.62',
'PY|PYG|es|America/Asuncion|Asunción|-25.26,-57.58',
'QA|QAR|ar|Asia/Qatar|Doha,Al Rayyan,Al Wakrah|25.28,51.52',
'RO|RON|ro|Europe/Bucharest|Bucharest,Cluj-Napoca,Timișoara|44.43,26.10',
'RS|RSD|sr|Europe/Belgrade|Belgrade,Novi Sad|44.79,20.45',
'RU|RUB|ru|Europe/Moscow|Moscow,Saint Petersburg,Novosibirsk,Kazan,Yekaterinburg|55.76,37.62',
'RW|RWF|rw|Africa/Kigali|Kigali|-1.94,30.06',
'SA|SAR|ar|Asia/Riyadh|Riyadh,Jeddah,Makkah,Madinah,Dammam,Khobar,Taif,Abha|24.71,46.68',
'SB|SBD|en|Pacific/Guadalcanal|Honiara|-9.43,159.95',
'SC|SCR|en|Indian/Mahe|Victoria|-4.62,55.45',
'SD|SDG|ar|Africa/Khartoum|Khartoum,Omdurman|15.50,32.56',
'SE|SEK|sv|Europe/Stockholm|Stockholm,Gothenburg,Malmö,Uppsala|59.33,18.07',
'SG|SGD|en|Asia/Singapore|Singapore|1.35,103.82',
'SI|EUR|sl|Europe/Ljubljana|Ljubljana,Maribor|46.06,14.51',
'SK|EUR|sk|Europe/Bratislava|Bratislava,Košice|48.15,17.11',
'SL|SLE|en|Africa/Freetown|Freetown|8.48,-13.23',
'SM|EUR|it|Europe/San_Marino|San Marino|43.94,12.45',
'SN|XOF|fr|Africa/Dakar|Dakar,Touba,Thiès|14.72,-17.47',
'SO|SOS|so|Africa/Mogadishu|Mogadishu,Hargeisa|2.05,45.32',
'SR|SRD|nl|America/Paramaribo|Paramaribo|5.85,-55.20',
'SS|SSP|en|Africa/Juba|Juba|4.85,31.58',
'ST|STN|pt|Africa/Sao_Tome|São Tomé|0.34,6.73',
'SV|USD|es|America/El_Salvador|San Salvador|13.69,-89.19',
'SY|SYP|ar|Asia/Damascus|Damascus,Aleppo,Homs|33.51,36.29',
'SZ|SZL|en|Africa/Mbabane|Mbabane|-26.31,31.14',
'TD|XAF|fr|Africa/Ndjamena|N’Djamena|12.11,15.04',
'TG|XOF|fr|Africa/Lome|Lomé|6.17,1.23',
'TH|THB|th|Asia/Bangkok|Bangkok,Chiang Mai,Phuket,Pattaya|13.76,100.50',
'TJ|TJS|tg|Asia/Dushanbe|Dushanbe|38.56,68.79',
'TL|USD|pt|Asia/Dili|Dili|-8.56,125.56',
'TM|TMT|tk|Asia/Ashgabat|Ashgabat|37.95,58.38',
'TN|TND|ar|Africa/Tunis|Tunis,Sfax,Sousse|36.81,10.18',
'TO|TOP|en|Pacific/Tongatapu|Nukuʻalofa|-21.14,-175.20',
'TR|TRY|tr|Europe/Istanbul|Istanbul,Ankara,Izmir,Bursa,Antalya,Adana,Konya|41.01,28.98',
'TT|TTD|en|America/Port_of_Spain|Port of Spain|10.65,-61.51',
'TV|AUD|en|Pacific/Funafuti|Funafuti|-8.52,179.20',
'TW|TWD|zh|Asia/Taipei|Taipei,Kaohsiung,Taichung|25.03,121.57',
'TZ|TZS|sw|Africa/Dar_es_Salaam|Dar es Salaam,Dodoma,Arusha,Zanzibar City|-6.79,39.21',
'UA|UAH|uk|Europe/Kyiv|Kyiv,Kharkiv,Odesa,Lviv|50.45,30.52',
'UG|UGX|en|Africa/Kampala|Kampala,Gulu|0.35,32.58',
'US|USD|en|America/New_York||40.71,-74.01',
'UY|UYU|es|America/Montevideo|Montevideo|-34.90,-56.16',
'UZ|UZS|uz|Asia/Tashkent|Tashkent,Samarkand,Bukhara|41.30,69.24',
'VC|XCD|en|America/St_Vincent|Kingstown|13.16,-61.22',
'VE|VES|es|America/Caracas|Caracas,Maracaibo|10.48,-66.90',
'VN|VND|vi|Asia/Ho_Chi_Minh|Ho Chi Minh City,Hanoi,Da Nang,Hai Phong|10.82,106.63',
'VU|VUV|fr|Pacific/Efate|Port Vila|-17.73,168.32',
'WS|WST|en|Pacific/Apia|Apia|-13.83,-171.77',
'YE|YER|ar|Asia/Aden|Sanaa,Aden,Taiz|15.37,44.19',
'ZA|ZAR|en|Africa/Johannesburg|Johannesburg,Cape Town,Durban,Pretoria,Gqeberha|-26.20,28.05',
'ZM|ZMW|en|Africa/Lusaka|Lusaka,Kitwe|-15.39,28.32',
'ZW|ZWG|en|Africa/Harare|Harare,Bulawayo|-17.83,31.05'
  ];

  /* Region / state / province, only where a country actually uses one.
     Everywhere else the hierarchy is country → city. */
  var REGIONS = {
    PK: {
      'Islamabad Capital Territory': ['Islamabad'],
      'Punjab': ['Lahore', 'Faisalabad', 'Rawalpindi', 'Multan', 'Gujranwala', 'Sialkot', 'Bahawalpur'],
      'Sindh': ['Karachi', 'Hyderabad', 'Sukkur', 'Larkana'],
      'Khyber Pakhtunkhwa': ['Peshawar', 'Mardan', 'Abbottabad', 'Swat'],
      'Balochistan': ['Quetta', 'Gwadar'],
      'Gilgit-Baltistan': ['Gilgit', 'Skardu'],
      'Azad Kashmir': ['Muzaffarabad']
    },
    US: {
      'California': ['Los Angeles', 'San Francisco', 'San Diego', 'San Jose'],
      'New York': ['New York', 'Buffalo'],
      'Texas': ['Houston', 'Dallas', 'Austin', 'San Antonio'],
      'Florida': ['Miami', 'Orlando', 'Tampa'],
      'Illinois': ['Chicago'],
      'Washington': ['Seattle'],
      'Massachusetts': ['Boston'],
      'Georgia': ['Atlanta'],
      'Michigan': ['Detroit', 'Dearborn'],
      'Pennsylvania': ['Philadelphia'],
      'Arizona': ['Phoenix'],
      'Nevada': ['Las Vegas'],
      'New Jersey': ['Newark', 'Jersey City'],
      'Virginia': ['Arlington', 'Richmond']
    },
    CA: {
      'Ontario': ['Toronto', 'Ottawa', 'Mississauga', 'Hamilton'],
      'Quebec': ['Montreal', 'Quebec City'],
      'British Columbia': ['Vancouver', 'Surrey', 'Victoria'],
      'Alberta': ['Calgary', 'Edmonton'],
      'Manitoba': ['Winnipeg'],
      'Nova Scotia': ['Halifax']
    },
    GB: {
      'England': ['London', 'Manchester', 'Birmingham', 'Leeds', 'Liverpool', 'Bristol', 'Sheffield', 'Newcastle'],
      'Scotland': ['Glasgow', 'Edinburgh', 'Aberdeen'],
      'Wales': ['Cardiff', 'Swansea'],
      'Northern Ireland': ['Belfast']
    },
    AU: {
      'New South Wales': ['Sydney', 'Newcastle'],
      'Victoria': ['Melbourne', 'Geelong'],
      'Queensland': ['Brisbane', 'Gold Coast', 'Cairns'],
      'Western Australia': ['Perth'],
      'South Australia': ['Adelaide'],
      'Australian Capital Territory': ['Canberra'],
      'Tasmania': ['Hobart']
    },
    IN: {
      'Maharashtra': ['Mumbai', 'Pune', 'Nagpur'],
      'Delhi': ['New Delhi', 'Delhi'],
      'Karnataka': ['Bengaluru', 'Mysuru'],
      'Tamil Nadu': ['Chennai', 'Coimbatore'],
      'Telangana': ['Hyderabad'],
      'West Bengal': ['Kolkata'],
      'Gujarat': ['Ahmedabad', 'Surat'],
      'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Varanasi'],
      'Rajasthan': ['Jaipur'],
      'Kerala': ['Kochi', 'Thiruvananthapuram'],
      'Punjab': ['Amritsar', 'Ludhiana']
    }
  };

  /* Shown first in the picker before anyone types. */
  var POPULAR = ['PK', 'IN', 'US', 'GB', 'AE', 'SA', 'CA', 'AU', 'DE', 'FR', 'TR', 'ID', 'MY', 'BD', 'EG', 'NG', 'ZA', 'SG', 'QA', 'KW'];

  /* Countries that habitually use imperial units. */
  var IMPERIAL = ['US', 'LR', 'MM'];
  /* Countries that read a 12-hour clock by default. */
  var TWELVE_HOUR = ['US', 'GB', 'AU', 'NZ', 'CA', 'IN', 'PK', 'BD', 'PH', 'EG', 'SA', 'AE', 'MY', 'MX', 'CO', 'NG', 'ZA'];

  var COUNTRIES = ROWS.map(function (row) {
    var p = row.split('|');
    var code = p[0];
    return {
      code: code,
      currency: p[1],
      lang: p[2],
      tz: p[3],
      cities: p[4] ? p[4].split(',') : [],
      lat: parseFloat((p[5] || '0,0').split(',')[0]),
      lon: parseFloat((p[5] || '0,0').split(',')[1]),
      regions: REGIONS[code] || null,
      popular: POPULAR.indexOf(code) !== -1,
      units: IMPERIAL.indexOf(code) !== -1 ? 'imperial' : 'metric',
      clock: TWELVE_HOUR.indexOf(code) !== -1 ? 12 : 24
    };
  });

  var BY_CODE = {};
  COUNTRIES.forEach(function (c) { BY_CODE[c.code] = c; });

  /* Countries with a region layer keep their cities in REGIONS, so flatten
     on demand rather than duplicating the list. */
  function citiesOf(code) {
    var c = BY_CODE[code];
    if (!c) return [];
    if (!c.regions) return c.cities;
    var out = [];
    Object.keys(c.regions).forEach(function (r) {
      c.regions[r].forEach(function (city) { if (out.indexOf(city) === -1) out.push(city); });
    });
    return out;
  }

  function regionOf(code, city) {
    var c = BY_CODE[code];
    if (!c || !c.regions) return null;
    var keys = Object.keys(c.regions);
    for (var i = 0; i < keys.length; i++) {
      if (c.regions[keys[i]].indexOf(city) !== -1) return keys[i];
    }
    return null;
  }

  return {
    COUNTRIES: COUNTRIES,
    BY_CODE: BY_CODE,
    POPULAR: POPULAR,
    citiesOf: citiesOf,
    regionOf: regionOf,
    dial: dial,
    get: function (code) { return BY_CODE[code] || null; }
  };
})();
