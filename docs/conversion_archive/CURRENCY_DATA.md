# Currency data — what is a currency, and which one a country uses now

Two tables decide money in Lume. Neither ever changes a stored amount.

## 1. ISO 4217 — `lib/core/values/lume_currency.dart`

`LumeCurrency` is an ISO 4217 code and ISO's minor-unit exponent. The active
list is ISO 4217 List One through its 2025 amendments. Codes ISO has since
withdrawn are kept in a separate list so that stored data never becomes
unreadable:

| code | withdrawn for | since |
|---|---|---|
| ANG | XCG (Caribbean guilder) | 2025 |
| BGN | EUR (Bulgaria's adoption of the euro) | 1 January 2026 |
| HRK | EUR (Croatia's adoption of the euro) | 1 January 2023 |
| SLL | SLE (Sierra Leone's redenomination) | 2022 |
| ZWL | ZWG (Zimbabwe Gold) | 2024 |

A withdrawn code:

- **decodes** from a stored record and from an import;
- is **displayed and exported** with its own code (`BGN`), never relabelled;
- is **summed apart** from every other currency, including its successor;
- is **never offered** for a new entry, and never a country's default.

## 2. A country's current currency — `lib/core/values/lume_country_currency.dart`

A country's currency is only a **default**: the one "Automatic" names in
Account › Currency, and the one a new Ledger entry starts in.

- **Base:** the web reference's own table (`assets/js/data/geo.js`, bundled
  as `assets/data/countries.json` by `tool/gen_countries.mjs`), unedited.
  `LumeCountryCurrency.reference` is a copy of that table, and
  `lume_country_currency_test.dart` fails if the copy and the bundled table
  differ.
- **Corrections:** `LumeCountryCurrency.changes`, oldest first. Each change
  records the country, the old and new codes, the date it took effect, the
  legally fixed rate where there is one, and its legal source.
- **Version:** `LumeCountryCurrency.asOf` is the date of the newest change
  it includes. A future change is a new entry with its own date, never an
  edit to an old one.
- **Readers:** the country fixture (`LumeCountryFixture.currencyOf`) and the
  formatter (`LumeFormatting.currency`) both read through the corrections.
  Before this, the formatter named only 17 markets and fell back to USD for
  the other 177 countries. It now uses the whole table, as the reference does
  (`L.currencyCode()` reads `country().currency`).

### Changes

| effective | country | from → to | fixed rate | source |
|---|---|---|---|---|
| 2026-01-01 | BG Bulgaria | BGN → EUR | 1.95583 BGN = 1 EUR | Council of the European Union, 8 July 2025: the decision that Bulgaria adopts the euro on 1 January 2026, and Council Regulation (EU) 2025/1409 amending Regulation (EC) No 2866/98 to fix the conversion rate |

## 3. No implicit conversion

The fixed rate is recorded for reference only, and nothing applies it. A lev
amount stays a lev amount: the same code and the same minor units, in every
sum, export and import.

If conversion is introduced later, it must be one of two things:

- an explicit migration; or
- an explicit reader action.

Either way it must use the legally fixed rate and keep the original record.

Changing a profile's country or currency changes only what a **new** amount
defaults to (`ledger_currency_test.dart`: *changing country or currency
changes no stored entry*).
