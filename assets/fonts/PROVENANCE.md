# Font provenance and licensing

Lume is set in **Plus Jakarta Sans** for Latin text and numerals, and
**Noto Naskh Arabic** for Arabic-script reading content. Both are bundled, not
fetched: the application renders offline and on the first frame, and there is no
network font dependency.

Every weight the type system names has a real file here. A missing weight makes
Flutter synthesise a faux bold, and a faux-bold Plus Jakarta is visibly not
Plus Jakarta.

## Files, checksums and verified metadata

SHA-256, and the family / style / weight read from each binary's `name` and
`OS/2` tables rather than from its filename. Asserted by
`test/core/theme/font_assets_test.dart`.

| File | SHA-256 |
|---|---|
| `PlusJakartaSans-Regular.ttf` | `076831b98043f50f829b6c91db3be4a844641f1c95bccff5c886ed87c661a852` |
| `PlusJakartaSans-Medium.ttf` | `b4fc14ec283d54236fd302cdb92546f98ae0ff061ca5ee23453a02bdf4628791` |
| `PlusJakartaSans-SemiBold.ttf` | `50357df108c5d297ec4ece76aeddf49561f3794f67af077cfc2c711b7a75b439` |
| `PlusJakartaSans-Bold.ttf` | `32971ad7976930539a11c79ce91ce84092df7f25c5be716b594601842f10a7ae` |
| `PlusJakartaSans-ExtraBold.ttf` | `d9e0ddb4a15a0054ad84b4ded3b4b9f354a0b7df426e21a1363d6933728da9d5` |
| `NotoNaskhArabic-Regular.ttf` | `67b5a525a661b607971fbd3f96a81b89d3a768e74534fca84f18ac97e6fab72f` |
| `PlusJakartaSans-OFL.txt` | `995c7199cab65954f545996326755daee7b63cc6b42b06c13da1f9502ab08a99` |
| `NotoNaskhArabic-OFL.txt` | `a7a5a25eb188bf1cd96982030d53e23c33485c69b1044a562254226857ee13af` |

### Plus Jakarta Sans — five static weights

Version 2.071 (`gftools[0.9.30]`), 1000 units/em, no `fvar` table, no italic.

| File | `name[1]` family | `name[2]` style | Typographic (16/17) | `usWeightClass` | pubspec weight |
|---|---|---|---|---|---|
| `PlusJakartaSans-Regular.ttf` | Plus Jakarta Sans | Regular | — | **400** | 400 |
| `PlusJakartaSans-Medium.ttf` | Plus Jakarta Sans Medium | Regular | Plus Jakarta Sans / Medium | **500** | 500 |
| `PlusJakartaSans-SemiBold.ttf` | Plus Jakarta Sans SemiBold | Regular | Plus Jakarta Sans / SemiBold | **600** | 600 |
| `PlusJakartaSans-Bold.ttf` | Plus Jakarta Sans | Bold | — | **700** | 700 |
| `PlusJakartaSans-ExtraBold.ttf` | Plus Jakarta Sans ExtraBold | Regular | Plus Jakarta Sans / ExtraBold | **800** | 800 |

Every declared weight points at the binary whose `usWeightClass` is that number.
Nothing is synthesised: `LumeType` uses only w400, w500, w600, w700 and w800, and
all five are present.

The split family names on Medium, SemiBold and ExtraBold are how Google Fonts
ships static instances for compatibility with applications that only read
`name[1]`. Flutter takes the family from `pubspec.yaml`, not from the binary, so
all five load under the single family `PlusJakartaSans`.

### Noto Naskh Arabic — one variable font

Version 2.021, 1000 units/em, **variable** — `fvar` with one axis:

| Axis | Min | Default | Max | Named instances |
|---|---|---|---|---|
| `wght` | 400 | 400 | 700 | 4 |

The web prototype loads this face at 400, 600 and 700. The single binary covers
that whole range, so it is declared once at weight 400 and heavier Arabic is
reached with `FontVariation('wght', n)` rather than by bundling more files or
letting Flutter synthesise a bold. `LumeType.arabic()` is the only place that
sets it.

## Licensing

Both families are licensed under the **SIL Open Font License, Version 1.1**.
The copyright line in each `-OFL.txt` is the one embedded in that font's own
`name[0]` record, read from the binary:

| Family | Copyright | Licence URL (`name[14]`) |
|---|---|---|
| Plus Jakarta Sans | Copyright 2020 The Plus Jakarta Sans Project Authors (https://github.com/tokotype/PlusJakartaSans) | https://scripts.sil.org/OFL |
| Noto Naskh Arabic | Copyright 2022 The Noto Project Authors (https://github.com/notofonts/arabic) | https://openfontlicense.org |

`NotoNaskhArabic-OFL.txt` carries the identical OFL 1.1 body as
`PlusJakartaSans-OFL.txt` — verified byte-identical from the licence heading
onward — under the Noto copyright line and licence URL above.

## Provenance

The binaries were copied read-only from `D:\dayroz\assets\fonts\` on
2026-09-11, with the copy approved for this phase. Each was verified by SHA-256
against its source before and after copying; all eight matched. `D:\dayroz\` was
not modified — `git status --porcelain` there reports only a pre-existing
untracked directory.

Nothing else was taken. Dayroz also carries Inter, Sora and Noto Nastaliq Urdu;
Inter and Sora are its pre-Lume faces and Lume does not use them, and Nastaliq
is not part of the Lume type specification. None of the three was copied.
