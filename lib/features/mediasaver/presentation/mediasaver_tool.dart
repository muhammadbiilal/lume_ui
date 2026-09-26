/// Media Saver — `tools/daily/mediasaver.tool.js`, composed in the
/// reference's own order: a link field and Fetch, three figures (saved,
/// storage used, last save), and the library.
///
/// The library and its figures are the reference's own sample
/// (`mediasaver_fixtures.dart`), and the source line says "Sample data".
/// Fetch says the reference's line, "Fetching media"; a library tile says its
/// own name, as the reference's `toast:<title>` does. The link text is kept
/// for the session under the reference's own key, `ms_link`.
///
/// **Dayroz:** Fetch downloads the linked media and adds it to the library;
/// a tile opens the saved item.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart' show LumeToastTone;
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/mediasaver_fixtures.dart';

class LumeMediaSaverTool extends ConsumerStatefulWidget {
  const LumeMediaSaverTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeMediaSaverTool(request: request);

  static const String id = 'mediasaver';

  static const Key fieldKey = ValueKey<String>('mediasaver.field');
  static const Key fetchKey = ValueKey<String>('mediasaver.fetch');
  static const Key metricsKey = ValueKey<String>('mediasaver.metrics');
  static const Key libraryKey = ValueKey<String>('mediasaver.library');

  static Key tile(LumeSavedMediaKind kind) =>
      ValueKey<String>('mediasaver.tile.${kind.name}');

  static String title(AppLocalizations l, LumeSavedMediaKind kind) =>
      switch (kind) {
        LumeSavedMediaKind.video => l.mediaItem1,
        LumeSavedMediaKind.photo => l.mediaItem2,
        LumeSavedMediaKind.audio => l.mediaItem3,
      };

  @override
  ConsumerState<LumeMediaSaverTool> createState() => _LumeMediaSaverToolState();
}

class _LumeMediaSaverToolState extends ConsumerState<LumeMediaSaverTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _link = TextEditingController(
    text: _session.read(LumeMediaSaverTool.id, 'ms_link') ?? '',
  );

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _say(String message) =>
      _host.currentState?.say(message, tone: LumeToastTone.info);

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    const List<LumeSavedMedia> items = LumeMediaSaverFixtures.library;

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
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LumeToolField(
                    key: LumeMediaSaverTool.fieldKey,
                    label: l.mediaLink,
                    controller: _link,
                    placeholder: l.mediasaverLinkPlaceholder,
                    wide: true,
                    onChanged: (String v) =>
                        _session.write(LumeMediaSaverTool.id, 'ms_link', v),
                  ),
                  const SizedBox(height: 14),
                  LumeButtonRow(
                    children: <Widget>[
                      LumeButton.accent(
                        key: LumeMediaSaverTool.fetchKey,
                        label: l.mediaFetch,
                        icon: LumeIcons.download,
                        block: true,
                        // The reference's own toast. **Dayroz:** fetch the
                        // linked media into the library.
                        onPressed: () => _say(l.mediaFetching),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeMetrics(
              key: LumeMediaSaverTool.metricsKey,
              columns: 3,
              children: <Widget>[
                LumeMetric(value: f.integer(items.length), label: l.mediaSaved),
                LumeMetric(
                  value:
                      '${f.integer(LumeMediaSaverFixtures.storageMegabytes)} '
                      '${l.unitMb}',
                  label: l.mediaStorage,
                ),
                LumeMetric(value: l.commonToday, label: l.mediaLastSave),
              ],
            ),
          ),
          LumeToolSection(
            title: l.mediaLibrary,
            child: items.isEmpty
                ? LumeToolState(
                    key: LumeMediaSaverTool.libraryKey,
                    icon: LumeIcons.download,
                    title: l.mediasaverEmptyTitle,
                    text: l.mediaEmptyText,
                  )
                : LumeCard(
                    key: LumeMediaSaverTool.libraryKey,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints box) {
                        // Three to a row, as the reference's grid; two once
                        // the text is large enough that a third would break
                        // its title mid-word.
                        const double gap = 10;
                        final int columns =
                            MediaQuery.textScalerOf(context).scale(1) > 1.3
                            ? 2
                            : 3;
                        final double w =
                            (box.maxWidth - gap * (columns - 1)) / columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: <Widget>[
                            for (final LumeSavedMedia m in items)
                              LumeImageCard(
                                key: LumeMediaSaverTool.tile(m.kind),
                                width: w,
                                title: LumeMediaSaverTool.title(l, m.kind),
                                seed: LumeMediaSaverTool.title(
                                  l,
                                  m.kind,
                                ).length,
                                tone: m.tone,
                                glyph: m.glyph,
                                meta:
                                    '${f.number(m.megabytes, decimals: m.megabytes == m.megabytes.roundToDouble() ? 0 : 1)} '
                                    '${l.unitMb}',
                                // The reference's own toast. **Dayroz:** open
                                // the saved item.
                                onTap: () =>
                                    _say(LumeMediaSaverTool.title(l, m.kind)),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
