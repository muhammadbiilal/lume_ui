/// What the route hands a converted tool.
library;

import 'package:flutter/foundation.dart';

import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';

/// One opening of one tool: which feature, for whom, from which branch, and
/// the two ways out of it.
///
/// The route builds this only after the catalogue's gate has said yes, so a
/// tool never has to ask whether it may draw itself.
@immutable
class LumeToolRequest {
  const LumeToolRequest({
    required this.feature,
    required this.user,
    required this.branch,
    this.onBack,
    this.onOpenRelated,
    this.query = const <String, String>{},
  });

  final LumeFeature feature;
  final LumeUserContext user;

  /// The branch root the tool sits on, so Back returns there.
  final String branch;

  final VoidCallback? onBack;

  /// A related tool replaces this one rather than stacking on it.
  final ValueChanged<String>? onOpenRelated;

  /// The location's query — a tool's own deep link (Ledger's `person`).
  /// Untrusted: a tool validates what it reads here.
  final Map<String, String> query;
}
