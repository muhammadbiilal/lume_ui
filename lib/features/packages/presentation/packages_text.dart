/// Small text helpers `packages_tool.dart` shares between the compare table,
/// the filter bar and the detail rows, so the same string is built once.
///
/// An operator's name and a bundle's own name are proper nouns (`Jazz`,
/// `Super Duper Card`) — the reference never translates them, and neither
/// does this: there is nothing here for a language to change.
library;

import '../data/packages_fixtures.dart';

abstract final class LumePackagesText {
  /// `p.op + ' · ' + p.name'` — the compare table's first cell and the detail
  /// row's own header, both in the reference's order.
  static String title(LumeMobilePackage p) => '${p.operatorName} · ${p.name}';

  /// `(p.op + ' ' + p.name).toLowerCase()` — what the reference's own search
  /// compares a query against.
  static String searchable(LumeMobilePackage p) =>
      '${p.operatorName} ${p.name}'.toLowerCase();
}
