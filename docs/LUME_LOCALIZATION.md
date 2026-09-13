# Localization

Three languages, held to full parity, with the direction and the type scale
that come with them. This describes the Flutter build. The web prototype's
own string tables are in [`conversion_archive/`](conversion_archive/).

---

## 1. What ships

| | English | Urdu | Arabic |
|---|---|---|---|
| code | `en` | `ur` | `ar` |
| direction | left to right | right to left | right to left |
| messages | 1037 | 1037 | 1037 |

`lib/l10n/app_en.arb` is the template and the only file carrying `@key`
metadata. `l10n.yaml` writes `l10n_untranslated.json` on every
`flutter gen-l10n`; an empty object is the contract, and
`arb_parity_test.dart` fails on anything else.

**Why parity is enforced rather than hoped for.** `gen_l10n` falls back to
English for any key a locale is missing. A partial ARB therefore ships
silently: nothing fails to build, nothing throws, and the reader simply sees
an English sentence in the middle of an Urdu screen.

---

## 2. Parity, measured

| dimension | result |
|---|---|
| keys English has and a translation does not | **0** |
| keys a translation has and English does not | **0** |
| messages declaring placeholders | 92 |
| a declared placeholder the English string never uses | **0** |
| a placeholder dropped by a translation | **0** |
| plural messages | 16 |
| select messages | 0 |
| a plural that is not a plural in some language | **0** |
| a plural with no `other` branch | **0** |
| values byte-identical to English | 16 of 1037 (1.5%) |

### Plurals

English and Urdu both count one separately; Arabic has a dual and a paucal as
well. Parity here is **not** branch-for-branch: it is that Arabic covers at
least as much as English, and that Urdu never collapses a singular English
distinguishes.

| message | en | ur | ar |
|---|---|---|---|
| `acctSessionsSub` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `acctSignedOutOthers` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `agendaOutageMeta` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `authResendIn` | `one,other` | `one,other` | `zero,one,two,few,many,other` |
| `billsDueIn` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `billsNeedAttention` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `billsOverdueBy` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `homeOutageArea` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `homeTasksLeft` | `=0,=1,other` | `=0,=1,other` | `=0,=1,=2,few,other` |
| `todayRingSummary` | `=0,=1,other` | `=0,=1,other` | `=0,=1,other` |
| `toolNeedsAttention` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `toolsResultCount` | `=0,=1,other` | `=0,=1,other` | `=0,=1,=2,few,other` |
| `toolsSub` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `trainsCount` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `trainsSearchResult` | `=1,other` | `=1,other` | `=1,=2,few,other` |
| `trainsUpdated` | `=1,other` | `=1,other` | `=1,=2,few,other` |

Three of those Urdu rows read `other` only until F5C. `trainsCount`,
`trainsSearchResult` and `trainsUpdated` had no singular branch, so an Urdu
reader looking at a route with one train was told **"1 ٹرینیں"** — "1 trains".
Every other Urdu plural in the file already handled it; these three were
missed, and nothing failed. `plurals a language that counts one separately
says so everywhere` is the test that would have caught it, and now does.

---

## 3. The untranslated report

Sixteen values are byte-identical across all three languages. Each one is
identical because of what it **is**, and the test decides that rather than a
list deciding it: a value with no letters left after the placeholders and the
punctuation are removed has nothing to translate.

| key | value | why |
|---|---|---|
| `cricketScore` | `{team} {runs}/{wickets}` | placeholders and a slash |
| `exploreWeatherDesc` | `{condition} · {feels}` | placeholders and a separator |
| `exploreWindValue` | `{value} {unit}` | placeholders |
| `todayAyahCitation` | `{surah} {verse}` | placeholders |
| `todayAyahReference` | `{surah} · {verse}` | placeholders and a separator |
| `unitOfTotal` | `/{total}` | a slash and a placeholder |
| `weatherHighLow` | `{high} / {low}` | placeholders and a slash |

And nine named exceptions, each a token rather than a phrase:

| key | value | why |
|---|---|---|
| `authEmailPlaceholder` | `you@example.com` | a sample address |
| `methodIsna` | `ISNA` | an organisation's acronym |
| `toolStatusCricket` | `PAK 214/4` | fixture sample data |
| `toolStatusEmergency` | `15 · 1122` | dialling codes |
| `toolStatusLoadshed` | `14:00–16:00` | a window of hours |
| `toolStatusMarkets` | `KSE-100 ▲ 0.8%` | an index and a move |
| `toolStatusPackages` | `Jazz · Zong` | two operators' names |
| `toolStatusTax` | `FBR 2025-26` | an authority and a tax year |
| `toolStatusWater` | `5 / 8` | a tally |

A second test asserts the list does not rot: a key on it that has since been
translated should come off it rather than sit there excusing nothing.

**Two were not exceptions.** `acctSessionsSub` and `acctSignedOutOthers` were
whole English sentences in both translated files — an Urdu reader on the
Security route was told "3 signed in". The suite's ratio check tolerated them
(two keys in a thousand is well under ten per cent) and its named check only
covered `auth*`. The named check now covers every key that has words in it.

---

## 4. Browser wording

The reference is a web page, and says so. A Flutter build has no browser, so
a sentence pointing a phone user at one is an instruction they cannot follow
(C49).

| key | reference | Flutter |
|---|---|---|
| `acctErrStorage` | "check your browser's storage settings" | names the device |
| `acctPushDenied` | "Blocked in your browser settings" | "Blocked in your device settings" |
| `acctPushDeniedHelp` | "…in your browser's site settings" | "…for Lume in your device settings" |
| `acctPushGranted` | "Allowed by your browser" | "Allowed on this device" |
| `acctDeviceBrowser` | "This browser" | "Web browser" |

`acctDeviceBrowser` is the one that keeps the word, and the only one allowed
to: it is one of five platform labels a session row can carry, beside Android,
iPhone, Mac and Windows. It names a platform, never the reader's own device.
`nothing tells a reader about their browser` enforces exactly that exception
and no other.

---

## 5. Direction

`LumeLocales` resolves the device's preference against the three languages and
supplies the `Directionality`; nothing reads direction from a country, and
`resolution language is never inferred from country` says so (§12, §66).

Three things follow from direction and are tested separately, because the
naive version of each is wrong:

**Only genuinely directional glyphs mirror.** A forward chevron mirrors; a
clock, a play button and a compass do not. The mirroring set is small and
written down.

**Numbers, times and codes do not reorder.** `LumeNumerals` / `LumeLtr` give a
run its own `Directionality` subtree — direction *and* isolation. A price and
a time in one RTL paragraph would otherwise swap places: the digits stay
correct and their sequence does not.

**The script gets a looser line.** Urdu and Arabic need more leading than the
Latin scale gives, and `LumeType.fit()` raises the line height and drops
negative tracking for joined scripts. Nasta'liq descends far below the
baseline; a line box measured for Inter clips it.

---

## 6. Scale and length

Translated strings are longer than English, and dynamic type multiplies the
problem rather than adding to it. `account_locale_test.dart` sweeps all
twenty-one account routes across every combination below, asserting that
nothing overflows:

| | en | ur | ar |
|---|---|---|---|
| 390 pt, 100% | ✓ | ✓ | ✓ |
| 390 pt, **200%** | ✓ | ✓ | ✓ |
| 359 pt, 100% | ✓ | ✓ | ✓ |
| 390 pt, 200%, as a guest | ✓ | ✓ | ✓ |

The guest row matters because the seven protected routes have a second screen
nobody captures by default, and it carries the longest sentence in the
section.

A separate test walks every settings row in Urdu and Arabic looking for Latin
words in a title or subtitle — which is what a missing key looks like after
`gen_l10n`'s silent fallback — allowing only a currency code, a language's own
name and the product's name.

---

## 7. Screenshots

`test/goldens/images/` holds the compared captures. The account section is
shot at four cells for each of its twenty-one routes:

| cell | what it is for |
|---|---|
| `390x844_light_en` | the reference cell, compared against the prototype's measurements |
| `390x844_light_ur` | right to left, Nasta'liq |
| `390x844_light_ar` | right to left, Arabic |
| `390x844_light_en_x2` | 200% type |

Eighty-four account captures, plus the refusal a guest meets on a protected
route — which is a screen in its own right rather than an absence — for
eighty-five; four hundred and sixty-two in the suite. They
are regression evidence, not acceptance evidence: a golden says the pixels
have not moved since the last time somebody looked, and the tests above say
what the pixels are supposed to mean.
