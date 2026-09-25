/// Media Saver — the reference tool for the "download from a link" archetype,
/// honestly narrowed to what a build with no network access can actually do.
///
/// `tools/daily/mediasaver.tool.js` draws a link field and a "Fetch" button
/// whose own action is `toast: c.t('media.fetching')` — a fixed line that
/// answers whatever was pasted, or nothing, and never resolves into a
/// download, a failure, or anything else. Underneath it, `c.savedMedia()`
/// invents three items (a clip, a photo, a track) with fabricated sizes, a
/// fabricated "182 MB" storage total, and "today" as the last save — none of
/// it read from anywhere; `tool-data.js` has no media store behind Media
/// Saver at all.
///
/// **Why this cannot be ported as a real downloader.** Saving a link's media
/// needs a network request to fetch it — this app makes none, project-wide,
/// by design (no HTTP client, no permission to reach an arbitrary URL). The
/// reference's own "Fetch" already does not do this either: it is a toast,
/// not a request. So the one thing Media Saver is *for* — pulling a photo or
/// a video off a link — has no honest version here, in the reference or in
/// Lume.
///
/// **What is honestly built instead.** The link field is kept, exactly as
/// unread as the reference's own (a reader can paste and edit it; nothing
/// downstream looks at the text) — the same treatment Parcel's tracking field
/// and Trains' from/to fields already get for the same reason (parcel_tool.dart,
/// trains_tool.dart). "Save" answers a press with the same fixed, honest line
/// every time, and the line says what is actually true — that Lume does not
/// reach the network — rather than the reference's ambiguous "Fetching…",
/// which would read here as a claim of progress toward nothing. A permanent
/// [LumeNotice] repeats that explanation next to the field, so a reader who
/// never presses Save still learns why nothing happens, and the library
/// section is a genuine empty state rather than the reference's three
/// invented files: this build has saved nothing, so it says nothing was
/// saved, instead of fabricating a size and a "today" for files that do not
/// exist. No fixture, no fabricated storage figure, no counted "items" the
/// reader never put there.
///
/// **Capability note for whoever wires `tool_capability.dart` (out of this
/// tool's scope):** this screen shows no sample data, no computed figure, and
/// no durable record — its one stateful value is the reader's own,
/// unvalidated link text, kept for the session only, exactly the way
/// `LumeDataCapability.inputOnly`'s other members ("every figure comes from
/// the fields on the screen … no fixture stands behind them") are described.
/// Left out of every set, the default `LumeDataCapability.fixture` marks it
/// `isSample`, which would print "Sample data" over a screen that has none —
/// an inaccurate claim this tool does not make anywhere else. Adding
/// `'mediasaver'` to `LumeDataCapability.inputOnly` is the fit that avoids
/// that false claim.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart' show LumeToastTone;
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';

class LumeMediaSaverTool extends ConsumerStatefulWidget {
  const LumeMediaSaverTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeMediaSaverTool(request: request);

  static const String id = 'mediasaver';

  static const Key fieldKey = ValueKey<String>('mediasaver.field');
  static const Key noticeKey = ValueKey<String>('mediasaver.notice');
  static const Key saveKey = ValueKey<String>('mediasaver.save');
  static const Key libraryKey = ValueKey<String>('mediasaver.library');

  @override
  ConsumerState<LumeMediaSaverTool> createState() =>
      _LumeMediaSaverToolState();
}

class _LumeMediaSaverToolState extends ConsumerState<LumeMediaSaverTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _link = TextEditingController(
    text: _session.read(LumeMediaSaverTool.id, 'ms_link') ?? '',
  );
  final FocusNode _linkFocus = FocusNode();

  @override
  void dispose() {
    _link.dispose();
    _linkFocus.dispose();
    super.dispose();
  }

  // `pc_ref` in Parcel, `ms_link` here — the reference's own key, read by
  // nothing downstream. Kept in the tool session only so the text survives a
  // reopen within the same run, never durable, never validated.
  void _setLink(String v) =>
      _session.write(LumeMediaSaverTool.id, 'ms_link', v);

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
      actions: LumeToolActions(onSearch: _linkFocus.requestFocus),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LumeToolField(
                    key: LumeMediaSaverTool.fieldKey,
                    label: l.mediasaverLinkLabel,
                    controller: _link,
                    placeholder: l.mediasaverLinkPlaceholder,
                    wide: true,
                    onChanged: _setLink,
                  ),
                  const SizedBox(height: 12),
                  LumeNotice(
                    key: LumeMediaSaverTool.noticeKey,
                    kind: LumeNoticeKind.info,
                    title: l.mediasaverNoNetworkTitle,
                    text: l.mediasaverNoNetworkText,
                  ),
                  const SizedBox(height: 12),
                  LumeButtonRow(
                    key: LumeMediaSaverTool.saveKey,
                    children: <Widget>[
                      LumeButton.accent(
                        label: l.mediasaverSave,
                        icon: LumeIcons.download,
                        block: true,
                        // The reference's own "Fetch": a fixed line that
                        // answers any input, or none, the same way, and never
                        // resolves into a result (parcel_tool.dart,
                        // trains_tool.dart carry the same shape). This one
                        // says what is actually true rather than the
                        // reference's ambiguous "Fetching…".
                        onPressed: () => _host.currentState?.say(
                          l.mediasaverNoNetworkToast,
                          tone: LumeToastTone.info,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.mediasaverLibrary,
            child: LumeToolState(
              key: LumeMediaSaverTool.libraryKey,
              icon: LumeIcons.download,
              title: l.mediasaverEmptyTitle,
              text: l.mediasaverEmptyText,
            ),
          ),
        ],
      ),
    );
  }
}
