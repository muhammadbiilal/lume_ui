# Release honesty

F6B decision 5. Every claim a tool makes about where its figures come from,
how fresh they are and how they are kept, classified for this build and
ruled for a release. The code is `lib/core/config/lume_build_profile.dart`
and `lib/features/tools/domain/tool_capability.dart`; the gate is
`test/release/release_readiness_test.dart`.

## Classifications

| class | meaning |
|---|---|
| **static reference copy** | a fixed description of fixed content; true in any build |
| **true under adapter** | true when a real adapter supplies the capability it names; in this build no adapter does |
| **fixture-only reproduction** | drawn exactly as the reference draws it, over fixture data; the reference build says in About that its data is sample data |
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
| "Calculated for your location", "For {city}" | `computed` | 5 — prayer, qibla, ramadan, hijri, sunmoon | true under adapter; none of the five is converted yet | `computedHere` |
| "Cached" | `cached` | mosques, taraweeh | **false**; fixture places | `observedAt` |
| "Reference text" | `reference` | 9 | static reference copy. Scripture carries its own content rules (C77, C82) | always |
| feed names — "Operator live feed", "Publisher feeds", "Match feed", "Exchange feed", "Interbank composite", "Bullion + open market", "Current pump price", "Regulator notification", "Official draw results", "Nisab from live metal rates" | source line | 10 | fixture-only reproduction; **false for a release** | the capability's own `source` names the adapter |
| "On device", "Statutory slabs", "Great-circle bearing", "Astronomical calculation", … | source line | the rest | static reference copy — they say how a figure is worked out, not that anything is live | always |

## How the rule is enforced

- **Capabilities are data.** `LumeDataCapability` carries `isDurable`,
  `isEncrypted`, `isLive`, `computedHere`, `observedAt`, `source` and
  `freshness`. Widgets never infer one: the tool frame asks
  `LumeSourceClaims.resolve` for what to draw.
- **The reference build** resolves every claim exactly as the reference
  draws it, so every golden is unchanged, and About's "Data" row says "Sample
  data — nothing is saved, synced or encrypted in this build".
  The row makes About's list 72 points taller than the reference's
  (`ACCOUNT_PARITY.md`, `list` height 186 → 258, under the existing C43
  entry); the four About goldens were re-captured for it.
- **A release build** (`--dart-define=LUME_BUILD=release`) resolves each
  claim against the capability and drops or replaces any it does not
  support.
- **The gate.** `release_readiness_test.dart` resolves every catalogue tool
  under the release profile with this build's capabilities and fails if any
  draws "Stored on this device" without durability, "Encrypted" without
  encryption, "Live" without a live source, or any "Updated …" without an
  observation. It also fails if a freshness kind is added without a rule.

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
