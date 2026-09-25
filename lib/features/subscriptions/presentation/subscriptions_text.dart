/// Small string/colour mappings for Subscriptions — no state, no logic
/// beyond a lookup.
library;

import 'package:flutter/widgets.dart';

import '../../../core/theme/lume/lume_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/subscriptions_model.dart';

abstract final class SubscriptionsText {
  static String cycle(AppLocalizations l, SubscriptionCycle c) => switch (c) {
    SubscriptionCycle.monthly => l.subsCycleMonthly,
    SubscriptionCycle.yearly => l.subsCycleYearly,
    SubscriptionCycle.custom => l.subsCycleCustom,
  };

  /// The row's trailing sub-label, cycle-aware — corrects the reference's
  /// unconditional "per month" (D-S5).
  static String perCycle(AppLocalizations l, Subscription s) =>
      switch (s.cycle) {
        SubscriptionCycle.monthly => l.subsPerMonth,
        SubscriptionCycle.yearly => l.subsPerYear,
        SubscriptionCycle.custom => l.subsEveryDays(s.customDays!),
      };

  static Color tone(LumeColors lume, SubscriptionTone t) => switch (t) {
    SubscriptionTone.rose => lume.rose,
    SubscriptionTone.green => lume.toneGreen,
    SubscriptionTone.sky => lume.sky,
    SubscriptionTone.amber => lume.amber,
    SubscriptionTone.indigo => lume.violet,
  };
}
