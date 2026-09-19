/// The zone of each city the country table lists, for the countries with
/// more than one civil time — "Follow my region"'s city policy.
///
/// A country with one civil time needs no entry: its zone is
/// `kLumeCountryCivilZone`. A country with several cannot be given one
/// (New York and Los Angeles are both "United States"), so the city decides,
/// and a city missing here leaves the reader to choose their zone.
///
/// Reviewed by hand against IANA's `zone.tab` descriptions, and held by a
/// test: every value is a canonical identifier CLDR lists for that country
/// (`kLumeCountryZones`), and every city of every several-zone country in
/// `assets/data/countries.json` has an entry. Keys are `country:city`, the
/// city exactly as the table writes it.
library;

const Map<String, String> kLumeCityZones = <String, String>{
  // Australia
  'AU:Sydney': 'Australia/Sydney',
  'AU:Newcastle': 'Australia/Sydney',
  'AU:Canberra': 'Australia/Sydney',
  'AU:Melbourne': 'Australia/Melbourne',
  'AU:Geelong': 'Australia/Melbourne',
  'AU:Brisbane': 'Australia/Brisbane',
  'AU:Gold Coast': 'Australia/Brisbane',
  'AU:Cairns': 'Australia/Brisbane',
  'AU:Perth': 'Australia/Perth',
  'AU:Adelaide': 'Australia/Adelaide',
  'AU:Hobart': 'Australia/Hobart',
  // Brazil
  'BR:São Paulo': 'America/Sao_Paulo',
  'BR:Rio de Janeiro': 'America/Sao_Paulo',
  'BR:Brasília': 'America/Sao_Paulo',
  'BR:Belo Horizonte': 'America/Sao_Paulo',
  'BR:Curitiba': 'America/Sao_Paulo',
  'BR:Salvador': 'America/Bahia',
  'BR:Fortaleza': 'America/Fortaleza',
  'BR:Recife': 'America/Recife',
  // Canada
  'CA:Toronto': 'America/Toronto',
  'CA:Ottawa': 'America/Toronto',
  'CA:Mississauga': 'America/Toronto',
  'CA:Hamilton': 'America/Toronto',
  'CA:Montreal': 'America/Toronto',
  'CA:Quebec City': 'America/Toronto',
  'CA:Vancouver': 'America/Vancouver',
  'CA:Surrey': 'America/Vancouver',
  'CA:Victoria': 'America/Vancouver',
  'CA:Calgary': 'America/Edmonton',
  'CA:Edmonton': 'America/Edmonton',
  'CA:Winnipeg': 'America/Winnipeg',
  'CA:Halifax': 'America/Halifax',
  // DR Congo — Kinshasa and Lubumbashi are links, since tzdb 2014, to the
  // zones whose rules they share.
  'CD:Kinshasa': 'Africa/Lagos',
  'CD:Lubumbashi': 'Africa/Maputo',
  // Chile
  'CL:Santiago': 'America/Santiago',
  'CL:Valparaíso': 'America/Santiago',
  'CL:Concepción': 'America/Santiago',
  // China — Asia/Urumqi is Xinjiang's
  'CN:Shanghai': 'Asia/Shanghai',
  'CN:Beijing': 'Asia/Shanghai',
  'CN:Guangzhou': 'Asia/Shanghai',
  'CN:Shenzhen': 'Asia/Shanghai',
  'CN:Chengdu': 'Asia/Shanghai',
  'CN:Hangzhou': 'Asia/Shanghai',
  'CN:Wuhan': 'Asia/Shanghai',
  'CN:Xi’an': 'Asia/Shanghai',
  // Ecuador — Pacific/Galapagos is the islands'
  'EC:Quito': 'America/Guayaquil',
  'EC:Guayaquil': 'America/Guayaquil',
  // Spain — Atlantic/Canary is the islands', Africa/Ceuta Ceuta and Melilla
  'ES:Madrid': 'Europe/Madrid',
  'ES:Barcelona': 'Europe/Madrid',
  'ES:Valencia': 'Europe/Madrid',
  'ES:Seville': 'Europe/Madrid',
  'ES:Bilbao': 'Europe/Madrid',
  'ES:Málaga': 'Europe/Madrid',
  // Micronesia — Pohnpei is a link to Guadalcanal
  'FM:Palikir': 'Pacific/Guadalcanal',
  // Indonesia
  'ID:Jakarta': 'Asia/Jakarta',
  'ID:Surabaya': 'Asia/Jakarta',
  'ID:Bandung': 'Asia/Jakarta',
  'ID:Medan': 'Asia/Jakarta',
  'ID:Semarang': 'Asia/Jakarta',
  'ID:Palembang': 'Asia/Jakarta',
  'ID:Yogyakarta': 'Asia/Jakarta',
  'ID:Makassar': 'Asia/Makassar',
  // Kiribati
  'KI:Tarawa': 'Pacific/Tarawa',
  // Mongolia
  'MN:Ulaanbaatar': 'Asia/Ulaanbaatar',
  // Mexico
  'MX:Mexico City': 'America/Mexico_City',
  'MX:Guadalajara': 'America/Mexico_City',
  'MX:Puebla': 'America/Mexico_City',
  'MX:Monterrey': 'America/Monterrey',
  'MX:Tijuana': 'America/Tijuana',
  'MX:Cancún': 'America/Cancun',
  // New Zealand — Pacific/Chatham is the islands'
  'NZ:Auckland': 'Pacific/Auckland',
  'NZ:Wellington': 'Pacific/Auckland',
  'NZ:Christchurch': 'Pacific/Auckland',
  // Papua New Guinea — Pacific/Bougainville is the region's
  'PG:Port Moresby': 'Pacific/Port_Moresby',
  // Portugal — Atlantic/Azores and Atlantic/Madeira are the islands'
  'PT:Lisbon': 'Europe/Lisbon',
  'PT:Porto': 'Europe/Lisbon',
  'PT:Braga': 'Europe/Lisbon',
  'PT:Faro': 'Europe/Lisbon',
  // Russia
  'RU:Moscow': 'Europe/Moscow',
  'RU:Saint Petersburg': 'Europe/Moscow',
  'RU:Kazan': 'Europe/Moscow',
  'RU:Novosibirsk': 'Asia/Novosibirsk',
  'RU:Yekaterinburg': 'Asia/Yekaterinburg',
  // Ukraine
  'UA:Kyiv': 'Europe/Kyiv',
  'UA:Kharkiv': 'Europe/Kyiv',
  'UA:Odesa': 'Europe/Kyiv',
  'UA:Lviv': 'Europe/Kyiv',
  // United States
  'US:Los Angeles': 'America/Los_Angeles',
  'US:San Francisco': 'America/Los_Angeles',
  'US:San Diego': 'America/Los_Angeles',
  'US:San Jose': 'America/Los_Angeles',
  'US:Seattle': 'America/Los_Angeles',
  'US:Las Vegas': 'America/Los_Angeles',
  'US:New York': 'America/New_York',
  'US:Buffalo': 'America/New_York',
  'US:Miami': 'America/New_York',
  'US:Orlando': 'America/New_York',
  'US:Tampa': 'America/New_York',
  'US:Boston': 'America/New_York',
  'US:Atlanta': 'America/New_York',
  'US:Philadelphia': 'America/New_York',
  'US:Newark': 'America/New_York',
  'US:Jersey City': 'America/New_York',
  'US:Arlington': 'America/New_York',
  'US:Richmond': 'America/New_York',
  'US:Houston': 'America/Chicago',
  'US:Dallas': 'America/Chicago',
  'US:Austin': 'America/Chicago',
  'US:San Antonio': 'America/Chicago',
  'US:Chicago': 'America/Chicago',
  'US:Detroit': 'America/Detroit',
  'US:Dearborn': 'America/Detroit',
  'US:Phoenix': 'America/Phoenix',
};
