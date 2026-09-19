/// A sensitive tool's privacy note (§61, §62), chosen from what the tool can
/// send out of Lume — never worded per tool id.
///
/// | [LumeOutbound] | title | says |
/// |---|---|---|
/// | `none` | "Private to you" | never shown on Home, never part of shared content |
/// | `reviewedShare` | "Private by default" | never shown on Home; only what the reader reviews and chooses to share leaves |
///
/// A universal "never included in shared content" would be false beside
/// Ledger's reminder, which the reader previews and then hands to the share
/// sheet. So the sentence follows the capability: a tool that can share
/// reviewed content never says it shares nothing.
library;

import '../../../core/widgets/lume/lume_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/lume_feature.dart';

abstract final class LumePrivacyNote {
  /// The note [feature] shows, or `null` for a tool that is not sensitive.
  static LumePrivateState? of(AppLocalizations l, LumeFeature feature) {
    if (!feature.sensitive) return null;
    return switch (feature.outbound) {
      LumeOutbound.none => LumePrivateState(
        title: l.toolPrivateTitle,
        text: l.toolPrivateText,
      ),
      LumeOutbound.reviewedShare => LumePrivateState(
        title: l.toolPrivateReviewedTitle,
        text: l.toolPrivateReviewedText,
      ),
    };
  }
}
