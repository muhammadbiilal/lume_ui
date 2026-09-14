/// The schedules and levies the reference ships — `tool-data.js` `TAX`,
/// `LEVIES` and `LEVIES_FALLBACK`, transcribed with their order kept.
///
/// **Fixture-only.** Statutory figures change every budget; these are the ones
/// the prototype carries, labelled with the year it names, and the screen says
/// so through its freshness line ("Current tax year") and its source
/// ("Statutory slabs"). Dayroz replaces this file with a maintained schedule.
library;

import '../domain/tax_rules.dart';

/// `TAX` — the six markets the reference configures.
const Map<String, LumeTaxConfig> kReferenceTaxConfigs = <String, LumeTaxConfig>{
  'PK': LumeTaxConfig(
    currency: 'PKR',
    year: '2025-26',
    authority: LumeTaxAuthority.fbrSalaried,
    bands: <LumeTaxBand>[
      LumeTaxBand(600000, 0),
      LumeTaxBand(1200000, 0.01),
      LumeTaxBand(2200000, 0.11),
      LumeTaxBand(3200000, 0.23),
      LumeTaxBand(4100000, 0.30),
      LumeTaxBand(double.infinity, 0.35),
    ],
  ),
  'GB': LumeTaxConfig(
    currency: 'GBP',
    year: '2025-26',
    authority: LumeTaxAuthority.hmrcEngland,
    bands: <LumeTaxBand>[
      LumeTaxBand(12570, 0),
      LumeTaxBand(50270, 0.20),
      LumeTaxBand(125140, 0.40),
      LumeTaxBand(double.infinity, 0.45),
    ],
  ),
  'US': LumeTaxConfig(
    currency: 'USD',
    year: '2025',
    authority: LumeTaxAuthority.irsSingleFiler,
    bands: <LumeTaxBand>[
      LumeTaxBand(11925, 0.10),
      LumeTaxBand(48475, 0.12),
      LumeTaxBand(103350, 0.22),
      LumeTaxBand(197300, 0.24),
      LumeTaxBand(250525, 0.32),
      LumeTaxBand(626350, 0.35),
      LumeTaxBand(double.infinity, 0.37),
    ],
  ),
  'IN': LumeTaxConfig(
    currency: 'INR',
    year: '2025-26',
    authority: LumeTaxAuthority.indiaNewRegime,
    bands: <LumeTaxBand>[
      LumeTaxBand(400000, 0),
      LumeTaxBand(800000, 0.05),
      LumeTaxBand(1200000, 0.10),
      LumeTaxBand(1600000, 0.15),
      LumeTaxBand(2000000, 0.20),
      LumeTaxBand(2400000, 0.25),
      LumeTaxBand(double.infinity, 0.30),
    ],
  ),
  'AE': LumeTaxConfig(
    currency: 'AED',
    year: '2025',
    authority: LumeTaxAuthority.noPersonalIncomeTax,
    bands: <LumeTaxBand>[LumeTaxBand(double.infinity, 0)],
  ),
  'SA': LumeTaxConfig(
    currency: 'SAR',
    year: '2025',
    authority: LumeTaxAuthority.noPersonalIncomeTax,
    bands: <LumeTaxBand>[LumeTaxBand(double.infinity, 0)],
  ),
};

/// `LEVIES`.
const Map<String, List<LumeLevyRate>> kReferenceLevies =
    <String, List<LumeLevyRate>>{
      'AE': <LumeLevyRate>[
        LumeLevyRate(LumeLevy.vat, 5),
        LumeLevyRate(LumeLevy.pension, 5),
        LumeLevyRate(LumeLevy.corporate, 9),
      ],
      'SA': <LumeLevyRate>[
        LumeLevyRate(LumeLevy.vat, 15),
        LumeLevyRate(LumeLevy.gosi, 9.75),
        LumeLevyRate(LumeLevy.zakatRate, 2.5),
      ],
      'GB': <LumeLevyRate>[
        LumeLevyRate(LumeLevy.vat, 20),
        LumeLevyRate(LumeLevy.ni, 8),
      ],
      'US': <LumeLevyRate>[
        LumeLevyRate(LumeLevy.socialSecurity, 6.2),
        LumeLevyRate(LumeLevy.medicare, 1.45),
      ],
      'PK': <LumeLevyRate>[
        LumeLevyRate(LumeLevy.gst, 18),
        LumeLevyRate(LumeLevy.eobi, 1),
      ],
      'IN': <LumeLevyRate>[
        LumeLevyRate(LumeLevy.gst, 18),
        LumeLevyRate(LumeLevy.pf, 12),
      ],
    };

/// `LEVIES_FALLBACK`.
const List<LumeLevyRate> kReferenceLeviesFallback = <LumeLevyRate>[
  LumeLevyRate(LumeLevy.vat, 20),
];

/// `taxFor(code)` — `null` for a market with no schedule.
LumeTaxConfig? lumeTaxConfigFor(String country) =>
    kReferenceTaxConfigs[country];

/// `leviesFor(code)`.
List<LumeLevyRate> lumeLeviesFor(String country) =>
    kReferenceLevies[country] ?? kReferenceLeviesFallback;
