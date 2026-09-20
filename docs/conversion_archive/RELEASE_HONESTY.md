# Release honesty

F6B decision 5. Every claim a tool makes about where its figures come from,
how fresh they are and how they are kept, classified for this build and
ruled for a release. The code is `lib/core/config/lume_build_profile.dart`
and `lib/features/tools/domain/tool_capability.dart`; the gate is
`test/release/release_readiness_test.dart`.

## Build flavors

`--dart-define=LUME_BUILD=…` chooses one of three. The widget never infers
durability from the build type: every claim is resolved from capability
metadata, and only the parity flavor reproduces the reference's words.

| flavor | define | source line | About's Data row | fixture harness | may ship |
|---|---|---|---|---|---|
| **parity** | `parity` | the reference's words ("Stored on this device", "Live", "Updated 30 sec ago"), each announced to a screen reader as "… Reference copy, not a claim about this build" | shown | reachable | **never.** A release-mode binary compiled as parity refuses to start (`lumeRefuseUnshippable`) |
| **development** | none | derived from capabilities, exactly as a release: "Kept until you close Lume" for the in-memory store | shown | reachable | no. It is not a production configuration |
| **release** | `release` | derived from capabilities | not shown | refused | yes |

The capability metadata is the same in every flavor: nothing in this build is
durable or encrypted. The test harness selects **parity** explicitly
(`test/helpers/lume_harness.dart`), because the goldens and side-by-sides are
parity captures. That is why no golden changed when an ordinary debug build
stopped drawing the reference's claims. A test about another flavor
overrides it.

### Controls that cannot do what they say

A header control the reference draws with nothing behind it is reproduced
only where it is evidence, and never as though it worked:

| control | parity | development and release |
|---|---|---|
| **Share** on a tool with no typed card, privacy filter or share adapter (Expenses; Goals once converted) | drawn **disabled**: announced "Share", a button, not enabled, with no tap action, no focus and no handler; a tap opens nothing | **left out** |
| **Search** on a tool with no field to focus | drawn **disabled**, like Share: not focusable, announced as unavailable, no handler — the reference's live-but-inert control is not reproduced | **left out** |
| **Share** on a tool with a real card (Age, Loan, Hadith …) | live | live |

`share_visibility_test.dart` holds the table, including two sweeps over
every tool in the catalogue: one for Share and one for Search, which is
live, absent, or — in parity only — genuinely disabled. Installments draws no notification control in any flavor
(`INSTALLMENTS_PROPOSAL.md` §14).

### The privacy note, by flavor

| outbound | parity | development and release |
|---|---|---|
| `none` | the reference's `toolPrivateText`. Its Urdu and Arabic say only "never shared" and leave Home out; the parity captures keep them | `toolPrivateFullText` in every language: stays on the device, never on Home or its suggestions, never in shared content |
| `reviewedShare` | Lume's own sentence (there is no reference one): private by default; only what the reader reviews and chooses leaves; notes, record ids and anything not reviewed never do | the same |

The sentence is chosen from the catalogue's typed `outbound` and the build
profile, never from a tool id (`privacy_note.dart`), and a screen reader
hears the same sentence as the page shows (`privacy_note_test.dart`).

## Classifications

| class | meaning |
|---|---|
| **static reference copy** | a fixed description of fixed content; true in any build |
| **true under adapter** | true when a real adapter supplies the capability it names; in this build no adapter does |
| **fixture-only reproduction** | drawn exactly as the reference draws it, over fixture data, in the parity flavor only; About says its data is sample data |
| **false — release-blocking** | untrue of anything this build can do; a release must not draw it without the capability |

## The matrix

Counts are of the 85 catalogue tools (`feature_catalogue.dart`).

| claim | where it is drawn | tools | this build | a release draws it only when |
|---|---|---|---|---|
| "Stored on this device" | freshness label, `local` | 40 — every calculator and record tool | fixture-only reproduction. Calculators keep their inputs in the tool session; records live in `LumeMemoryRecordRepository` (`durable == false`). Nothing survives closing the app. **False for a release.** | `isDurable`. Otherwise "Kept until you close Lume" |
| "Encrypted on device" | source line | 6 — documents, vaccines, health, cycle, pregnancy, meds | **false — release-blocking.** Nothing is encrypted. | `isEncrypted`. Otherwise "On device" |
| "Live" | freshness label, `live` | 11 | *stopwatch, timer, focus, worldclock*: true under adapter — the on-device clock is running. *trains, flights, news, cricket, speedtest*: **false — release-blocking**, the rows are fixtures. *qr, docscan*: **false** until a scan has happened (C78) | `isLive` |
| "Updated 30 sec ago" | updated line, `live` | the same 11 | **false — release-blocking.** A constant string, whatever happened | `observedAt` is set; the seconds are worked out from it |
| "Delayed 15 min", "Updated 15 min ago" | `delayed` | 7 — currency, zakat, goldrates, markets, aqi, weather, parcel | **false — release-blocking**; fixture rates and readings | `isLive` and `observedAt` |
| "Updated at 6:00", "Updated today", "Latest draw" | `daily`, `draw` | 7 — ayah, fuel, fuelcost, bills, loadshed, vehicle, prizebonds | **false — release-blocking**; the hour and the day are today's whatever the data | `observedAt` |
| "Updated {today's date}", "Updated this week" | `weekly`, `annual` | 4 — natsavings, packages, tax, holidays | natsavings, packages: **false**. tax, holidays: *static reference copy* for the stated year — but "Updated {today}" is **false** | `observedAt` |
| "Current tax year" | `annual` label | tax, holidays | static reference copy for the schedule's year | always |
| Reader's own records, nothing seeded | `readerRecords` | 3 — ledger, installments, committee | all three are converted (C90, C94, C96): each shows only what the reader wrote, so none is sample; the storage claim is still the store's — "Kept until you close Lume" in development and release builds, because the in-memory store is not durable (C74) | `isSample` false |
| "… is never included in shared content" | a sensitive tool's privacy note | 12 sensitive tools | true for the eleven whose `outbound` is `none`. Expenses and Goals keep the reference's Share action in their supports, drawn disabled with no card behind it. **False for Ledger**, whose reminder is shared after review, so Ledger says "Private by default … Only what you review and choose to share leaves Lume" (`LumePrivacyNote`, from `LumeOutbound`) | the tool's `outbound` is `none` |
| "Calculated for your location", "For {city}" | `computed` | 5 — prayer, qibla, ramadan, hijri, sunmoon | true under adapter. **sunmoon** is converted (rollout wave 2, C86) and says it: `LumeDataCapability.computed` marks it `computedHere` and not sample, because every figure is worked out on the device for the reader's city; the other four are not converted | `computedHere` |
| "Cached" | `cached` | mosques, taraweeh | **false**; fixture places | `observedAt` |
| "Reference text" | `reference` | 9 | static reference copy. Scripture carries its own content rules (C77, C82) | always |
| feed names — "Operator live feed", "Publisher feeds", "Match feed", "Exchange feed", "Interbank composite", "Bullion + open market", "Current pump price", "Regulator notification", "Official draw results", "Nisab from live metal rates" | source line | 10 | fixture-only reproduction; **false for a release** | the capability's own `source` names the adapter |
| "On device", "Statutory slabs", "Great-circle bearing", "Astronomical calculation", … | source line | the rest | static reference copy — they say how a figure is worked out, not that anything is live | always |

## How the rule is enforced

- **Capabilities are data.** `LumeDataCapability` carries `isDurable`,
  `isEncrypted`, `isLive`, `computedHere`, `observedAt`, `source` and
  `freshness`. Widgets never infer one: the tool frame asks
  `LumeSourceClaims.resolve` for what to draw.
- **The parity build** resolves every claim exactly as the reference
  draws it, so every golden is unchanged, and About's "Data" row says "Sample
  data — nothing is saved, synced or encrypted in this build". A screen
  reader hears each reproduced claim as reference copy.
  The row makes About's list 72 points taller than the reference's
  (`ACCOUNT_PARITY.md`, `list` height 186 → 258, under the existing C43
  entry); the four About goldens were re-captured for it.
- **A development or release build** resolves each claim against the
  capability and drops or replaces any it does not support. A tool whose
  capability is `isSample` reads "Sample data" as its freshness and draws
  no other claim. A release refuses the fixture harness ids.
- **Sample data is said where the figures are (C85).** In the parity build
  a sample-backed tool's source line leads with "Sample data", read to a
  screen reader in full; in development and release builds it is the
  freshness label itself. About's row stays, but it counts
  for nothing in the gate.
- **The gate.** `release_readiness_test.dart` resolves every catalogue tool
  under the release profile with this build's capabilities and fails if any
  draws "Stored on this device" without durability, "Encrypted" without
  encryption, "Live" without a live source, or any "Updated …" without an
  observation; if a sample-backed tool does not disclose it; or if a
  freshness kind is added without a rule. It holds a development build to
  the same rule, and holds that only a release ships. It then opens every
  converted tool through its route in all three flavors and reads its own
  source bar. It also shows that a claim hiding sample data, and a
  durability claim with nothing durable, would be caught.

## Dayroz obligations

- A durable store behind every tool that claims one (records, preferences,
  the notification ledger, the tool session where a reader expects inputs to
  return).
- Encryption at rest for the six sensitive tools, with a capability that says
  so.
- Real feeds with observation times for every live, delayed, daily, weekly,
  draw and cached tool, and the source line naming the provider.
- The same `LumeDataCapability` supplied by each adapter, so the release
  profile draws exactly what is true.
