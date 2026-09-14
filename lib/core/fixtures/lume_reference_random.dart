/// The reference's seeded generator, and the series it draws with it.
///
/// `tool-data.js` `seedRand(seed)` is Park–Miller; every "plausible" fixture
/// series in the prototype — the weather's five days, a tracker's thirty-five
/// days of consistency — is a deterministic walk from a seed. Porting the
/// generator once is what lets each series be asserted against the running
/// reference instead of being typed in by hand.
library;

/// `seedRand(seed)`.
class LumeSeedRand {
  LumeSeedRand(int seed) : _s = seed % 2147483647 {
    if (_s <= 0) _s += 2147483646;
  }

  int _s;

  /// The next value in [0, 1).
  double next() {
    _s = _s * 16807 % 2147483647;
    return (_s - 1) / 2147483646;
  }
}

/// `heatDays(n, seed, rate)` in `context.js` — a consistency grid's levels.
///
/// Each day's draw above `rate` is kept (level 2, or 3 a quarter above it);
/// below it, a quarter's grace is a 1 and the rest are 0.
List<int> lumeHeatDays(int n, int seed, double rate) {
  final LumeSeedRand r = LumeSeedRand(seed);
  return <int>[
    for (int i = 0; i < n; i++)
      switch (r.next()) {
        final double v when v > rate => v > rate + 0.25 ? 3 : 2,
        final double v when v > rate - 0.25 => 1,
        _ => 0,
      },
  ];
}
