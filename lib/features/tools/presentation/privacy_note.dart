/// A sensitive tool's privacy note (§61, §62), chosen from what the tool can
/// send out of Lume — never worded per tool id.
///
/// | [LumeOutbound] | title | says |
/// |---|---|---|
/// | `none` | "Private to you" | never shown on Home or its suggestions, never part of shared content |
/// | `reviewedShare` | "Private by default" | never shown on Home; only what the reader reviews and chooses to share leaves, and notes, record ids and what they did not review never do |
///
/// **By flavor.** The parity flavor shows the reference's `none` sentence,
/// whose Urdu and Arabic say only "never shared" and leave Home out, so its
/// captures stay the reference's. Development and release say the whole
/// contract in every language (`toolPrivateFullText`).
///
/// A universal "never included in shared content" would be false beside
/// Ledger's reminder, which the reader previews and then hands to the share
/// sheet. So the sentence follows the capability: a tool that can share
/// reviewed content never says it shares nothing.
library;

import '../../../core/config/lume_build_profile.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/lume_feature.dart';

abstract final class LumePrivacyNote {
  /// The note [feature] shows, or `null` for a tool that is not sensitive.
  static LumePrivateState? of(
    AppLocalizations l,
    LumeFeature feature, {
    required LumeBuildProfile profile,
  }) {
    if (!feature.sensitive) return null;
    return switch (feature.outbound) {
      LumeOutbound.none => LumePrivateState(
        title: l.toolPrivateTitle,
        text: profile.reproducesReference
            ? l.toolPrivateText
            : l.toolPrivateFullText,
      ),
      LumeOutbound.reviewedShare => LumePrivateState(
        title: l.toolPrivateReviewedTitle,
        text: l.toolPrivateReviewedText,
      ),
    };
  }
}
