/// Every route in the product, written down once.
///
/// The reference has no URLs: `router.js` activates a screen by id and the
/// address bar never changes. Flutter's router does have locations, and they
/// have to be decided rather than invented at each call site — so the ids
/// become paths here, and nothing else in the app writes a path literal.
///
/// **Shape.** Six destinations are branch roots; everything else is a *nested*
/// destination that lives on top of whichever branch you were on. That is not
/// a Flutter convention imported over the reference — it is what the reference
/// does: *"the centre is a destination rather than a tab, so it remembers where
/// the user was and its back control returns them there."* A branch stack says
/// the same thing and survives a rotation, which a remembered-tab variable
/// cannot.
///
/// So the notification centre opened from Home is `/home/notifications` and the
/// one opened from Today is `/today/notifications`. The two are the same screen
/// on two stacks, and Back lands where the user actually was. The bare
/// `/notifications` still resolves — it is what a push notification or a deep
/// link arrives on — and redirects onto the home branch, which is the same
/// fallback `notifReturnTab` starts at.
library;

import '../navigation/lume_destination.dart';

/// The path segments, and the names a call site uses to navigate.
abstract final class LumeRoutes {
  // ---- Branch roots ------------------------------------------------------
  // Written by [LumeDestinationId.path]; repeated here only as names, so a
  // call site reads `LumeRoutes.home` rather than a string.

  static String get home => LumeDestinationId.home.path;
  static String get tools => LumeDestinationId.tools.path;
  static String get trains => LumeDestinationId.trains.path;
  static String get today => LumeDestinationId.today.path;
  static String get explore => LumeDestinationId.explore.path;
  static String get profile => LumeDestinationId.profile.path;

  /// Where an unrecognised location goes.
  static String get start => home;

  // ---- Nested destinations, relative to whichever branch is current ------

  static const String notificationsSegment = 'notifications';
  static const String searchSegment = 'search';
  static const String accountSegment = 'account';
  static const String unavailableSegment = 'unavailable';
  static const String toolSegment = 'tool';
  static const String recordsSegment = 'records';
  static const String newSegment = 'new';
  static const String editSegment = 'edit';

  /// The parameter names, so a screen reads them by name rather than by
  /// spelling them again.
  static const String toolIdParam = 'toolId';
  static const String recordIdParam = 'recordId';

  // ---- Flows outside the shell ------------------------------------------

  /// Authentication. A flow rather than a tool: it never enters the tool
  /// router, the catalogue or search, and it covers the shell rather than
  /// sitting inside it.
  static const String auth = '/auth';

  /// The first-run flow, which covers the shell until it is finished.
  static const String onboarding = '/onboarding';

  // ---- Builders ----------------------------------------------------------

  /// The notification centre on a branch. `branch` is a branch root path.
  static String notifications(String branch) => '$branch/$notificationsSegment';

  /// Global search on a branch.
  static String search(String branch) => '$branch/$searchSegment';

  /// Account and settings on a branch.
  static String account(String branch) => '$branch/$accountSegment';

  /// The "this is not available here" destination.
  static String unavailable(String branch) => '$branch/$unavailableSegment';

  /// A tool, hosted on a branch. Tools opened on top of each other stack,
  /// because each `push` adds a page rather than replacing one.
  static String tool(String branch, String toolId) =>
      '$branch/$toolSegment/$toolId';

  /// A tool's record collection.
  static String records(String branch, String toolId) =>
      '${tool(branch, toolId)}/$recordsSegment';

  /// One record.
  static String record(String branch, String toolId, String recordId) =>
      '${records(branch, toolId)}/$recordId';

  /// The create form. A fixed segment, so it is matched before `:recordId`.
  static String newRecord(String branch, String toolId) =>
      '${records(branch, toolId)}/$newSegment';

  /// The edit form for one record.
  static String editRecord(String branch, String toolId, String recordId) =>
      '${record(branch, toolId, recordId)}/$editSegment';

  /// The branch root a location belongs to, or [start] when it belongs to
  /// none.
  ///
  /// Used by anything that has to build a nested path from where the user
  /// currently is — the search entry in a header, a notification tap.
  static String branchOf(String location) {
    for (final LumeDestinationId id in LumeDestinations.all) {
      if (location == id.path || location.startsWith('${id.path}/')) {
        return id.path;
      }
    }
    return start;
  }

  /// Whether a location *is* a branch root, which is the only case in which a
  /// destination is selected.
  ///
  /// `router.js` syncs the selection against `data-tab`, and a nested
  /// destination has none — so a tool, the notification centre and the account
  /// surface all select nothing and the pill hides. This is that rule.
  static LumeDestinationId? destinationAt(String location) {
    for (final LumeDestinationId id in LumeDestinations.all) {
      if (location == id.path) return id;
    }
    return null;
  }
}
