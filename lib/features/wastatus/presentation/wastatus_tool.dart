/// WhatsApp Status — `tools/daily/wastatus.tool.js`, as the reference
/// composes it: an "Android only" note, then "Detected statuses", whose
/// empty state offers "Grant folder access".
///
/// The reference lists nothing — a browser cannot read another app's files —
/// and its Grant button toasts "Requesting access". This is that screen: no
/// status is invented, and the button says the reference's line.
///
/// **Dayroz:** Grant folder access asks for WhatsApp's status folder through
/// Android's folder picker (the Storage Access Framework, read-only, for that
/// one folder) and lists what is there, each status saveable to the
/// reader's gallery. The manifest takes no broad storage permission for it
/// (`android_manifest_test.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart' show LumeToastTone;
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';

class LumeWastatusTool extends ConsumerStatefulWidget {
  const LumeWastatusTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeWastatusTool(request: request);

  static const String id = 'wastatus';

  static const Key noteKey = ValueKey<String>('wastatus.note');
  static const Key detectedKey = ValueKey<String>('wastatus.detected');
  static const Key grantKey = ValueKey<String>('wastatus.grant');

  @override
  ConsumerState<LumeWastatusTool> createState() => _LumeWastatusToolState();
}

class _LumeWastatusToolState extends ConsumerState<LumeWastatusTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeNoteCard(
              key: LumeWastatusTool.noteKey,
              tone: LumeNoteTone.info,
              icon: LumeIcons.message,
              title: l.wastatusAndroidTitle,
              text: l.wastatusAndroidText,
            ),
          ),
          LumeToolSection(
            title: l.wastatusDetected,
            child: LumeToolState(
              key: LumeWastatusTool.detectedKey,
              icon: LumeIcons.message,
              title: l.wastatusEmptyTitle,
              text: l.wastatusEmptyText,
              action: LumeButton(
                key: LumeWastatusTool.grantKey,
                label: l.wastatusGrant,
                icon: LumeIcons.folder,
                // The reference's own toast. **Dayroz:** ask for the status
                // folder through Android's folder picker.
                onPressed: () => _host.currentState?.say(
                  l.wastatusGranting,
                  tone: LumeToastTone.info,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
