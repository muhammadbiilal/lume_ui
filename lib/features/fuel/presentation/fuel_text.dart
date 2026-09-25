/// The words Fuel Prices and Fuel Cost draw that their data does not carry —
/// grade names, unit suffixes, generic source labels and effective-date
/// text, shared by both screens over the one fixture ([LumeFuel]).
library;

import '../../../l10n/app_localizations.dart';
import '../data/fuel_fixtures.dart';

abstract final class LumeFuelStrings {
  /// `t(i.nk)` — a grade's own name, wherever it appears (the summary
  /// kicker, the grades table, Fuel Cost's default price hint).
  static String grade(AppLocalizations l, LumeFuelGrade g) => switch (g) {
    LumeFuelGrade.petrol => l.fuelPetrol,
    LumeFuelGrade.hiOctane => l.fuelHiOctane,
    LumeFuelGrade.diesel => l.fuelDiesel,
    LumeFuelGrade.lightDiesel => l.fuelLightDiesel,
    LumeFuelGrade.unleaded => l.fuelUnleaded,
    LumeFuelGrade.superUnleaded => l.fuelSuperUnleaded,
    LumeFuelGrade.regular => l.fuelRegular,
    LumeFuelGrade.midgrade => l.fuelMidgrade,
    LumeFuelGrade.premium => l.fuelPremium,
    LumeFuelGrade.special95 => l.fuelSpecial95,
    LumeFuelGrade.super98 => l.fuelSuper98,
    LumeFuelGrade.ePlus91 => l.fuelEPlus91,
    LumeFuelGrade.petrol91 => l.fuelPetrol91,
    LumeFuelGrade.petrol95 => l.fuelPetrol95,
    LumeFuelGrade.cng => l.fuelCng,
  };

  /// `t('unit.' + f.unit)` — the market's own dispensing unit.
  static String unit(AppLocalizations l, LumeFuelUnit u) => switch (u) {
    LumeFuelUnit.litre => l.unitLitre,
    LumeFuelUnit.gallon => l.unitGallon,
  };

  /// `f.source || t(f.sourceKey)` — the market's own literal institution
  /// name where the reference gives one, or the translated generic label.
  static String source(AppLocalizations l, LumeFuelMarket m) =>
      switch (m.sourceKind) {
        LumeFuelSource.proper => m.properSource!,
        LumeFuelSource.retail => l.fuelSourceRetail,
        LumeFuelSource.state => l.fuelSourceState,
        LumeFuelSource.omc => l.fuelSourceOmc,
        LumeFuelSource.regional => l.fuelSourceRegional,
      };

  /// `f.effective || t(f.effectiveKey)`.
  static String effective(AppLocalizations l, LumeFuelMarket m) =>
      switch (m.effectiveKind) {
        LumeFuelEffective.fixed => m.fixedEffective!,
        LumeFuelEffective.today => l.commonToday,
        LumeFuelEffective.thisWeek => l.commonThisWeek,
      };
}
