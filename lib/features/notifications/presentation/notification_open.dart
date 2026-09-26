/// Opening a notification — `services/notifications.js` `openItem`, shared by
/// the centre's rows and the banner so the two cannot disagree.
///
/// * A grouped row only marks itself read: it stands for several events, and
///   the reference re-renders rather than choosing one to open.
/// * Any other row is marked read and opens its tool — on the item it is
///   about, where it names one (the reference's `toolstate:TOOL:KEY:VALUE`
///   deep link, written into that tool's session before it opens).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/notification_feed.dart';
import '../../../core/routing/lume_routes.dart';
import '../../tools/application/tool_session.dart';
import '../domain/notification_model.dart';

/// Returns whether it navigated, so a caller that re-reads its feed knows
/// whether it is still on screen.
Future<bool> openLumeNotification({
  required WidgetRef ref,
  required BuildContext context,
  required String branch,
  required LumeNotification n,
}) async {
  await ref.read(notificationFeedProvider).markRead(n.id);
  if (n.grouped || !context.mounted) return false;
  final (String, String)? opens = n.opens;
  if (opens != null) {
    ref.read(toolSessionProvider).write(n.tool, opens.$1, opens.$2);
  }
  context.go(LumeRoutes.tool(branch, n.tool));
  return true;
}
