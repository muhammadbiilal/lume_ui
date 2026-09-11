# Authentication bounds, measured against the design source

Written by `test/features/auth/auth_bounds_test.dart`. Every row is `getBoundingClientRect` from the running prototype beside `tester.getRect` from the Flutter screen in the same state, at 390 × 844, light, English.

`y` is measured from the panel's own origin on both sides: the prototype draws a 28-point simulated status bar and sits its screen below it (P1), and the Flutter flow covers the shell and has no such bar (D18). Comparing page coordinates would compare two origins.

**467 values compared**, tolerance 1.0 px.

| element | axis | prototype | Flutter | Δ | note |
|---|---|---|---|---|---|
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 60.00 | 60.00 | = |  |
| `auth.back` | y | 16.00 | 16.00 | = |  |
| `auth.back` | x | 14.00 | 14.00 | = |  |
| `auth.back` | width | 44.00 | 44.00 | = |  |
| `auth.back` | height | 44.00 | 44.00 | = |  |
| `auth.brand` | y | 84.00 | 84.00 | = |  |
| `auth.brand` | x | 24.00 | 24.00 | = |  |
| `auth.brand` | width | 342.00 | 342.00 | = |  |
| `auth.brand` | height | 34.00 | 34.00 | = |  |
| `auth.mark` | y | 84.00 | 84.00 | = |  |
| `auth.mark` | x | 24.00 | 24.00 | = |  |
| `auth.mark` | width | 34.00 | 34.00 | = |  |
| `auth.mark` | height | 34.00 | 34.00 | = |  |
| `auth.hero` | y | 142.00 | 142.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 70.14 | 70.00 | -0.14 |  |
| `auth.title` | y | 142.00 | 142.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 36.89 | 37.00 | 0.11 |  |
| `auth.word` | y | 90.00 | 90.00 | = |  |
| `auth.word` | x | 68.00 | 68.00 | = |  |
| `auth.word` | width | 43.30 | 43.28 | -0.02 |  |
| `auth.word` | height | 22.00 | 22.00 | = |  |
| `auth.text` | y | 188.89 | 189.00 | 0.11 |  |
| `auth.text` | x | 24.00 | 24.00 | = |  |
| `auth.text` | width | 342.00 | 342.00 | = |  |
| `auth.text` | height | 23.25 | 23.00 | -0.25 |  |
| `auth.form` | y | 236.14 | 236.00 | -0.14 |  |
| `auth.form` | x | 24.00 | 24.00 | = |  |
| `auth.form` | width | 342.00 | 342.00 | = |  |
| `auth.form` | height | 267.78 | 268.00 | 0.22 |  |
| `auth.field.first` | y | 236.14 | 236.00 | -0.14 |  |
| `auth.field.first` | x | 24.00 | 24.00 | = |  |
| `auth.field.first` | width | 342.00 | 342.00 | = |  |
| `auth.field.first` | height | 101.89 | 102.00 | 0.11 |  |
| `auth.field.second` | y | 350.03 | 350.00 | -0.03 |  |
| `auth.field.second` | x | 24.00 | 24.00 | = |  |
| `auth.field.second` | width | 342.00 | 342.00 | = |  |
| `auth.field.second` | height | 101.89 | 102.00 | 0.11 |  |
| `auth.inline` | y | 459.92 | 460.00 | 0.08 |  |
| `auth.inline` | x | 237.27 | 237.27 | = |  |
| `auth.inline` | width | 128.73 | 128.73 | = |  |
| `auth.inline` | height | 44.00 | 44.00 | = |  |
| `auth.actions` | y | 527.92 | 528.00 | 0.08 |  |
| `auth.actions` | x | 24.00 | 24.00 | = |  |
| `auth.actions` | width | 342.00 | 342.00 | = |  |
| `auth.actions` | height | 54.00 | 54.00 | = |  |
| `auth.submit` | y | 527.92 | 528.00 | 0.08 |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.foot` | y | 597.92 | 598.00 | 0.08 |  |
| `auth.foot` | x | 24.00 | 24.00 | = |  |
| `auth.foot` | width | 342.00 | 342.00 | = |  |
| `auth.foot` | height | 46.00 | 46.00 | = |  |
| `auth.link.first` | y | 597.92 | 598.00 | 0.08 |  |
| `auth.link.first` | x | 24.00 | 24.00 | = |  |
| `auth.link.first` | width | 342.00 | 342.00 | = |  |
| `auth.link.first` | height | 46.00 | 46.00 | = |  |
| `auth.formerr` | y | 236.14 | 236.00 | -0.14 |  |
| `auth.formerr` | x | 24.00 | 24.00 | = |  |
| `auth.formerr` | width | 342.00 | 342.00 | = |  |
| `auth.formerr` | height | 46.13 | 46.00 | -0.13 |  |
| `auth.form` | y | 236.14 | 236.00 | -0.14 |  |
| `auth.form` | x | 24.00 | 24.00 | = |  |
| `auth.form` | width | 342.00 | 342.00 | = |  |
| `auth.form` | height | 325.91 | 326.00 | 0.09 |  |
| `auth.field.first` | y | 294.27 | 294.00 | -0.27 |  |
| `auth.field.first` | x | 24.00 | 24.00 | = |  |
| `auth.field.first` | width | 342.00 | 342.00 | = |  |
| `auth.field.first` | height | 101.89 | 102.00 | 0.11 |  |
| `auth.submit` | y | 586.05 | 586.00 | -0.05 |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.close` | y | 16.00 | 16.00 | = |  |
| `auth.close` | x | 332.00 | 332.00 | = |  |
| `auth.close` | width | 44.00 | 44.00 | = |  |
| `auth.close` | height | 44.00 | 44.00 | = |  |
| `auth.notice` | y | 230.14 | 230.00 | -0.14 |  |
| `auth.notice` | x | 24.00 | 24.00 | = |  |
| `auth.notice` | width | 342.00 | 342.00 | = |  |
| `auth.notice` | height | 46.13 | 46.00 | -0.13 |  |
| `auth.form` | y | 300.27 | 300.00 | -0.27 |  |
| `auth.form` | x | 24.00 | 24.00 | = |  |
| `auth.form` | width | 342.00 | 342.00 | = |  |
| `auth.form` | height | 267.78 | 268.00 | 0.22 |  |
| `auth.foot.secondary` | y | 662.05 | 662.00 | -0.05 |  |
| `auth.foot.secondary` | x | 24.00 | 24.00 | = |  |
| `auth.foot.secondary` | width | 342.00 | 342.00 | = |  |
| `auth.foot.secondary` | height | 50.00 | 50.00 | = |  |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 60.00 | 60.00 | = |  |
| `auth.back` | y | 16.00 | 16.00 | = |  |
| `auth.back` | x | 14.00 | 14.00 | = |  |
| `auth.back` | width | 44.00 | 44.00 | = |  |
| `auth.back` | height | 44.00 | 44.00 | = |  |
| `auth.brand` | y | 84.00 | 84.00 | = |  |
| `auth.brand` | x | 24.00 | 24.00 | = |  |
| `auth.brand` | width | 342.00 | 342.00 | = |  |
| `auth.brand` | height | 34.00 | 34.00 | = |  |
| `auth.mark` | y | 84.00 | 84.00 | = |  |
| `auth.mark` | x | 24.00 | 24.00 | = |  |
| `auth.mark` | width | 34.00 | 34.00 | = |  |
| `auth.mark` | height | 34.00 | 34.00 | = |  |
| `auth.hero` | y | 142.00 | 142.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 130.28 | 130.00 | -0.28 |  |
| `auth.title` | y | 142.00 | 142.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 73.78 | 74.00 | 0.22 |  |
| `auth.stepOf` | y | 28.94 | 29.00 | 0.06 |  |
| `auth.stepOf` | x | 304.08 | 304.07 | -0.01 |  |
| `auth.stepOf` | width | 61.92 | 61.93 | 0.01 |  |
| `auth.stepOf` | height | 18.13 | 18.00 | -0.13 |  |
| `auth.steps` | y | 288.28 | 288.00 | -0.28 |  |
| `auth.steps` | x | 24.00 | 24.00 | = |  |
| `auth.steps` | width | 150.00 | 150.00 | = |  |
| `auth.steps` | height | 4.00 | 4.00 | = |  |
| `auth.form` | y | 316.28 | 316.00 | -0.28 |  |
| `auth.form` | x | 24.00 | 24.00 | = |  |
| `auth.form` | width | 342.00 | 342.00 | = |  |
| `auth.form` | height | 216.17 | 216.00 | -0.17 |  |
| `auth.field.first` | y | 316.28 | 316.00 | -0.28 |  |
| `auth.field.first` | x | 24.00 | 24.00 | = |  |
| `auth.field.first` | width | 342.00 | 342.00 | = |  |
| `auth.field.first` | height | 102.28 | 102.00 | -0.28 |  |
| `auth.field.second` | y | 430.56 | 430.00 | -0.56 |  |
| `auth.field.second` | x | 24.00 | 24.00 | = |  |
| `auth.field.second` | width | 342.00 | 342.00 | = |  |
| `auth.field.second` | height | 101.89 | 102.00 | 0.11 |  |
| `auth.submit` | y | 556.45 | 556.00 | -0.45 |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 60.00 | 60.00 | = |  |
| `auth.back` | y | 16.00 | 16.00 | = |  |
| `auth.back` | x | 14.00 | 14.00 | = |  |
| `auth.back` | width | 44.00 | 44.00 | = |  |
| `auth.back` | height | 44.00 | 44.00 | = |  |
| `auth.brand` | y | 84.00 | 84.00 | = |  |
| `auth.brand` | x | 24.00 | 24.00 | = |  |
| `auth.brand` | width | 342.00 | 342.00 | = |  |
| `auth.brand` | height | 34.00 | 34.00 | = |  |
| `auth.mark` | y | 84.00 | 84.00 | = |  |
| `auth.mark` | x | 24.00 | 24.00 | = |  |
| `auth.mark` | width | 34.00 | 34.00 | = |  |
| `auth.mark` | height | 34.00 | 34.00 | = |  |
| `auth.hero` | y | 142.00 | 142.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 70.14 | 70.00 | -0.14 |  |
| `auth.title` | y | 142.00 | 142.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 36.89 | 37.00 | 0.11 |  |
| `auth.steps` | y | 228.14 | 228.00 | -0.14 |  |
| `auth.steps` | x | 24.00 | 24.00 | = |  |
| `auth.steps` | width | 150.00 | 150.00 | = |  |
| `auth.steps` | height | 4.00 | 4.00 | = |  |
| `auth.form` | y | 256.14 | 256.00 | -0.14 |  |
| `auth.form` | x | 24.00 | 24.00 | = |  |
| `auth.form` | width | 342.00 | 342.00 | = |  |
| `auth.form` | height | 377.78 | 378.00 | 0.22 |  |
| `auth.field.first` | y | 256.14 | 256.00 | -0.14 |  |
| `auth.field.first` | x | 24.00 | 24.00 | = |  |
| `auth.field.first` | width | 342.00 | 342.00 | = |  |
| `auth.field.first` | height | 101.89 | 102.00 | 0.11 |  |
| `auth.pwmeter` | y | 372.03 | 372.00 | -0.03 |  |
| `auth.pwmeter` | x | 24.00 | 24.00 | = |  |
| `auth.pwmeter` | width | 342.00 | 342.00 | = |  |
| `auth.pwmeter` | height | 13.00 | 13.00 | = |  |
| `auth.pwrules` | y | 399.03 | 399.00 | -0.03 |  |
| `auth.pwrules` | x | 24.00 | 24.00 | = |  |
| `auth.pwrules` | width | 342.00 | 342.00 | = |  |
| `auth.pwrules` | height | 121.00 | 121.00 | = |  |
| `auth.field.second` | y | 532.03 | 532.00 | -0.03 |  |
| `auth.field.second` | x | 24.00 | 24.00 | = |  |
| `auth.field.second` | width | 342.00 | 342.00 | = |  |
| `auth.field.second` | height | 101.89 | 102.00 | 0.11 |  |
| `auth.submit` | y | 657.92 | 658.00 | 0.08 |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.legal` | y | 735.92 | 736.00 | 0.08 | the inline link has no padded box in Flutter (D20) |
| `auth.legal` | x | 24.00 | 24.00 | = | the inline link has no padded box in Flutter (D20) |
| `auth.legal` | width | 342.00 | 342.00 | = | the inline link has no padded box in Flutter (D20) |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 60.00 | 60.00 | = |  |
| `auth.back` | y | 16.00 | 16.00 | = |  |
| `auth.back` | x | 14.00 | 14.00 | = |  |
| `auth.back` | width | 44.00 | 44.00 | = |  |
| `auth.back` | height | 44.00 | 44.00 | = |  |
| `auth.brand` | y | 84.00 | 84.00 | = |  |
| `auth.brand` | x | 24.00 | 24.00 | = |  |
| `auth.brand` | width | 342.00 | 342.00 | = |  |
| `auth.brand` | height | 34.00 | 34.00 | = |  |
| `auth.mark` | y | 84.00 | 84.00 | = |  |
| `auth.mark` | x | 24.00 | 24.00 | = |  |
| `auth.mark` | width | 34.00 | 34.00 | = |  |
| `auth.mark` | height | 34.00 | 34.00 | = |  |
| `auth.hero` | y | 294.00 | 294.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 93.39 | 93.00 | -0.39 |  |
| `auth.title` | y | 294.00 | 294.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 36.89 | 37.00 | 0.11 |  |
| `auth.visual` | y | 142.00 | 142.00 | = |  |
| `auth.visual` | x | 24.00 | 24.00 | = |  |
| `auth.visual` | width | 342.00 | 342.00 | = |  |
| `auth.visual` | height | 128.00 | 128.00 | = |  |
| `auth.seal` | y | 142.00 | 142.00 | = |  |
| `auth.seal` | x | 131.00 | 131.00 | = |  |
| `auth.seal` | width | 128.00 | 128.00 | = |  |
| `auth.seal` | height | 128.00 | 128.00 | = |  |
| `auth.form` | y | 411.39 | 411.00 | -0.39 |  |
| `auth.form` | x | 24.00 | 24.00 | = |  |
| `auth.form` | width | 342.00 | 342.00 | = |  |
| `auth.form` | height | 101.89 | 102.00 | 0.11 |  |
| `auth.submit` | y | 537.28 | 537.00 | -0.28 |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.foot` | y | 607.28 | 607.00 | -0.28 |  |
| `auth.foot` | x | 24.00 | 24.00 | = |  |
| `auth.foot` | width | 342.00 | 342.00 | = |  |
| `auth.foot` | height | 46.00 | 46.00 | = |  |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 60.00 | 60.00 | = |  |
| `auth.back` | y | 16.00 | 16.00 | = |  |
| `auth.back` | x | 14.00 | 14.00 | = |  |
| `auth.back` | width | 44.00 | 44.00 | = |  |
| `auth.back` | height | 44.00 | 44.00 | = |  |
| `auth.hero` | y | 236.00 | 236.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 123.52 | 123.00 | -0.52 |  |
| `auth.title` | y | 236.00 | 236.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 36.89 | 37.00 | 0.11 |  |
| `auth.visual` | y | 84.00 | 84.00 | = |  |
| `auth.visual` | x | 24.00 | 24.00 | = |  |
| `auth.visual` | width | 342.00 | 342.00 | = |  |
| `auth.visual` | height | 128.00 | 128.00 | = |  |
| `auth.text` | y | 282.89 | 283.00 | 0.11 |  |
| `auth.text` | x | 24.00 | 24.00 | = |  |
| `auth.text` | width | 342.00 | 342.00 | = |  |
| `auth.text` | height | 46.50 | 46.00 | -0.50 |  |
| `auth.note` | y | 341.39 | 341.00 | -0.39 |  |
| `auth.note` | x | 24.00 | 24.00 | = |  |
| `auth.note` | width | 342.00 | 342.00 | = |  |
| `auth.note` | height | 18.13 | 18.00 | -0.13 |  |
| `auth.submit` | bottom | 128.12 | 128.00 | -0.12 |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.foot` | bottom | 23.99 | 24.00 | 0.01 |  |
| `auth.foot` | x | 24.00 | 24.00 | = |  |
| `auth.foot` | width | 342.00 | 342.00 | = |  |
| `auth.foot` | height | 88.13 | 88.00 | -0.13 |  |
| `auth.top` | y | 0.00 | 0.00 | = | the reference compresses this header (D19) |
| `auth.top` | x | 24.00 | 24.00 | = | the reference compresses this header (D19) |
| `auth.top` | width | 342.00 | 342.00 | = | the reference compresses this header (D19) |
| `auth.top` | height | 48.00 | 60.00 | 12.00 | the reference compresses this header (D19) |
| `auth.back` | y | 10.00 | 16.00 | 6.00 | the reference compresses this header (D19) |
| `auth.back` | x | 14.00 | 14.00 | = | the reference compresses this header (D19) |
| `auth.back` | width | 44.00 | 44.00 | = | the reference compresses this header (D19) |
| `auth.back` | height | 44.00 | 44.00 | = | the reference compresses this header (D19) |
| `auth.brand` | y | 72.00 | 84.00 | 12.00 | the reference compresses this header (D19) |
| `auth.brand` | x | 24.00 | 24.00 | = | the reference compresses this header (D19) |
| `auth.brand` | width | 342.00 | 342.00 | = | the reference compresses this header (D19) |
| `auth.brand` | height | 34.00 | 34.00 | = | the reference compresses this header (D19) |
| `auth.hero` | y | 282.00 | 294.00 | 12.00 | the reference compresses this header (D19) |
| `auth.hero` | x | 24.00 | 24.00 | = | the reference compresses this header (D19) |
| `auth.hero` | width | 342.00 | 342.00 | = | the reference compresses this header (D19) |
| `auth.hero` | height | 130.28 | 130.00 | -0.28 | the reference compresses this header (D19) |
| `auth.title` | y | 282.00 | 294.00 | 12.00 | the reference compresses this header (D19) |
| `auth.title` | x | 24.00 | 24.00 | = | the reference compresses this header (D19) |
| `auth.title` | width | 342.00 | 342.00 | = | the reference compresses this header (D19) |
| `auth.title` | height | 73.78 | 74.00 | 0.22 | the reference compresses this header (D19) |
| `auth.visual` | y | 130.00 | 142.00 | 12.00 | shifted 12 by the compressed header above it (D19) |
| `auth.visual` | x | 24.00 | 24.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.visual` | width | 342.00 | 342.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.visual` | height | 128.00 | 128.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.form` | y | 436.28 | 448.00 | 11.72 | shifted 12 by the compressed header above it (D19) |
| `auth.form` | x | 24.00 | 24.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.form` | width | 342.00 | 342.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.form` | height | 377.78 | 378.00 | 0.22 | shifted 12 by the compressed header above it (D19) |
| `auth.pwmeter` | y | 552.17 | 564.00 | 11.83 | shifted 12 by the compressed header above it (D19) |
| `auth.pwmeter` | x | 24.00 | 24.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.pwmeter` | width | 342.00 | 342.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.pwmeter` | height | 13.00 | 13.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.pwrules` | y | 579.17 | 591.00 | 11.83 | shifted 12 by the compressed header above it (D19) |
| `auth.pwrules` | x | 24.00 | 24.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.pwrules` | width | 342.00 | 342.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.pwrules` | height | 121.00 | 121.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.submit` | y | 838.06 | 850.00 | 11.94 | shifted 12 by the compressed header above it (D19) |
| `auth.submit` | x | 24.00 | 24.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.submit` | width | 342.00 | 342.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.submit` | height | 54.00 | 54.00 | = | shifted 12 by the compressed header above it (D19) |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 48.00 | 48.00 | = |  |
| `auth.hero` | y | 224.00 | 224.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 70.14 | 70.00 | -0.14 |  |
| `auth.title` | y | 224.00 | 224.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 36.89 | 37.00 | 0.11 |  |
| `auth.visual` | y | 72.00 | 72.00 | = |  |
| `auth.visual` | x | 24.00 | 24.00 | = |  |
| `auth.visual` | width | 342.00 | 342.00 | = |  |
| `auth.visual` | height | 128.00 | 128.00 | = |  |
| `auth.seal` | y | 72.00 | 72.00 | = |  |
| `auth.seal` | x | 131.00 | 131.00 | = |  |
| `auth.seal` | width | 128.00 | 128.00 | = |  |
| `auth.seal` | height | 128.00 | 128.00 | = |  |
| `auth.actions` | bottom | 24.00 | 24.00 | = |  |
| `auth.actions` | x | 24.00 | 24.00 | = |  |
| `auth.actions` | width | 342.00 | 342.00 | = |  |
| `auth.actions` | height | 54.00 | 54.00 | = |  |
| `auth.submit` | bottom | 24.00 | 24.00 | = |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 48.00 | 48.00 | = |  |
| `auth.hero` | y | 224.00 | 224.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 70.14 | 70.00 | -0.14 |  |
| `auth.title` | y | 224.00 | 224.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 36.89 | 37.00 | 0.11 |  |
| `auth.visual` | y | 72.00 | 72.00 | = |  |
| `auth.visual` | x | 24.00 | 24.00 | = |  |
| `auth.visual` | width | 342.00 | 342.00 | = |  |
| `auth.visual` | height | 128.00 | 128.00 | = |  |
| `auth.seal` | y | 72.00 | 72.00 | = |  |
| `auth.seal` | x | 131.00 | 131.00 | = |  |
| `auth.seal` | width | 128.00 | 128.00 | = |  |
| `auth.seal` | height | 128.00 | 128.00 | = |  |
| `auth.actions` | bottom | 24.00 | 24.00 | = |  |
| `auth.actions` | x | 24.00 | 24.00 | = |  |
| `auth.actions` | width | 342.00 | 342.00 | = |  |
| `auth.actions` | height | 54.00 | 54.00 | = |  |
| `auth.submit` | bottom | 24.00 | 24.00 | = |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 48.00 | 48.00 | = |  |
| `auth.hero` | y | 224.00 | 224.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 130.28 | 130.00 | -0.28 |  |
| `auth.title` | y | 224.00 | 224.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 73.78 | 74.00 | 0.22 |  |
| `auth.visual` | y | 72.00 | 72.00 | = |  |
| `auth.visual` | x | 24.00 | 24.00 | = |  |
| `auth.visual` | width | 342.00 | 342.00 | = |  |
| `auth.visual` | height | 128.00 | 128.00 | = |  |
| `auth.seal` | y | 72.00 | 72.00 | = |  |
| `auth.seal` | x | 131.00 | 131.00 | = |  |
| `auth.seal` | width | 128.00 | 128.00 | = |  |
| `auth.seal` | height | 128.00 | 128.00 | = |  |
| `auth.actions` | bottom | 86.00 | 86.00 | = |  |
| `auth.actions` | x | 24.00 | 24.00 | = |  |
| `auth.actions` | width | 342.00 | 342.00 | = |  |
| `auth.actions` | height | 54.00 | 54.00 | = |  |
| `auth.submit` | bottom | 86.00 | 86.00 | = |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 60.00 | 60.00 | = |  |
| `auth.back` | y | 16.00 | 16.00 | = |  |
| `auth.back` | x | 14.00 | 14.00 | = |  |
| `auth.back` | width | 44.00 | 44.00 | = |  |
| `auth.back` | height | 44.00 | 44.00 | = |  |
| `auth.hero` | y | 236.00 | 236.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 116.64 | 116.00 | -0.64 |  |
| `auth.title` | y | 236.00 | 236.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 36.89 | 37.00 | 0.11 |  |
| `auth.visual` | y | 84.00 | 84.00 | = |  |
| `auth.visual` | x | 24.00 | 24.00 | = |  |
| `auth.visual` | width | 342.00 | 342.00 | = |  |
| `auth.visual` | height | 128.00 | 128.00 | = |  |
| `auth.seal` | y | 84.00 | 84.00 | = |  |
| `auth.seal` | x | 131.00 | 131.00 | = |  |
| `auth.seal` | width | 128.00 | 128.00 | = |  |
| `auth.seal` | height | 128.00 | 128.00 | = |  |
| `auth.actions` | bottom | 86.00 | 86.00 | = |  |
| `auth.actions` | x | 24.00 | 24.00 | = |  |
| `auth.actions` | width | 342.00 | 342.00 | = |  |
| `auth.actions` | height | 54.00 | 54.00 | = |  |
| `auth.submit` | bottom | 86.00 | 86.00 | = |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
| `auth.top` | y | 0.00 | 0.00 | = |  |
| `auth.top` | x | 24.00 | 24.00 | = |  |
| `auth.top` | width | 342.00 | 342.00 | = |  |
| `auth.top` | height | 60.00 | 60.00 | = |  |
| `auth.back` | y | 16.00 | 16.00 | = |  |
| `auth.back` | x | 14.00 | 14.00 | = |  |
| `auth.back` | width | 44.00 | 44.00 | = |  |
| `auth.back` | height | 44.00 | 44.00 | = |  |
| `auth.hero` | y | 236.00 | 236.00 | = |  |
| `auth.hero` | x | 24.00 | 24.00 | = |  |
| `auth.hero` | width | 342.00 | 342.00 | = |  |
| `auth.hero` | height | 93.39 | 93.00 | -0.39 |  |
| `auth.title` | y | 236.00 | 236.00 | = |  |
| `auth.title` | x | 24.00 | 24.00 | = |  |
| `auth.title` | width | 342.00 | 342.00 | = |  |
| `auth.title` | height | 36.89 | 37.00 | 0.11 |  |
| `auth.visual` | y | 84.00 | 84.00 | = |  |
| `auth.visual` | x | 24.00 | 24.00 | = |  |
| `auth.visual` | width | 342.00 | 342.00 | = |  |
| `auth.visual` | height | 128.00 | 128.00 | = |  |
| `auth.form` | y | 353.39 | 353.00 | -0.39 |  |
| `auth.form` | x | 24.00 | 24.00 | = |  |
| `auth.form` | width | 342.00 | 342.00 | = |  |
| `auth.form` | height | 144.02 | 144.00 | -0.02 |  |
| `auth.field.first` | y | 353.39 | 353.00 | -0.39 |  |
| `auth.field.first` | x | 24.00 | 24.00 | = |  |
| `auth.field.first` | width | 342.00 | 342.00 | = |  |
| `auth.field.first` | height | 101.89 | 102.00 | 0.11 |  |
| `auth.submit` | y | 521.41 | 521.00 | -0.41 |  |
| `auth.submit` | x | 24.00 | 24.00 | = |  |
| `auth.submit` | width | 342.00 | 342.00 | = |  |
| `auth.submit` | height | 54.00 | 54.00 | = |  |
