/// Ayah of the Day — the reference tool for scripture readers, extended to
/// the Qur'an (mirrors Hadith's own C77/C82 wave).
///
/// `tools/islamic/ayah.tool.js` and `c.ayahOfDay()`: today's ayah, drawn from
/// the same three-ayah pool `dayIndex` also picks Hadith's day from — the
/// same formula, applied to a pool of three instead of four. The reference's
/// `tafsir` field is not commentary: it is one fixed sentence
/// (`ayah.tafsirBody`) shown under every one of the three ayat regardless of
/// which is on screen, and it is the wrong commentary for two of them. That
/// is a placeholder standing in for real commentary, not real content, so it
/// is not ported — this screen carries no tafsir section at all rather than
/// present an invented or a mismatched one.
///
/// The tool is faith-gated in the catalogue, so a reader who has not turned
/// the Islamic experience on never reaches it (the gate, not this screen,
/// decides).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../hadith/domain/religious_content.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/quran_fixtures.dart';
import '../domain/quran_model.dart';
import 'quran_text.dart';

class LumeAyahTool extends ConsumerStatefulWidget {
  const LumeAyahTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) => LumeAyahTool(request: request);

  static const String id = 'ayah';

  static const Key cardKey = ValueKey<String>('ayah.card');
  static const Key shareKey = ValueKey<String>('ayah.share');
  static const Key saveKey = ValueKey<String>('ayah.save');
  static const Key moreKey = ValueKey<String>('ayah.more');

  @override
  ConsumerState<LumeAyahTool> createState() => _LumeAyahToolState();
}

class _LumeAyahToolState extends ConsumerState<LumeAyahTool> {
  static const String _id = LumeAyahTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);

  String? _read(String k) => _session.read(_id, k);
  void _write(String k, String v) => _session.write(_id, k, v);

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final DateTime now = LumeClockScope.of(context).now();
    final LumeAyah ayah = LumeQuranFixtures.ayahOfDay(now);
    final String dayId = ayah.id;
    final bool saved = _read('saved') == dayId;

    // The passage the reader's own language resolves to, honestly: the
    // Arabic is always shown regardless (never a fallback), and the
    // reference's English is marked as one only when the reader's interface
    // language is neither Arabic nor English (C82's principle, reused).
    final LumeResolvedPassage resolved = ayah.resolve(
      LumeContentLanguage(Localizations.localeOf(context).languageCode),
    );
    final String reference = l.quranVerseReference(
      ayah.surahName,
      ayah.surahNumber,
      ayah.ayahNumber,
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.quran,
        text: ayah.translation,
        source: reference,
        arabic: ayah.arabic,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeAyahCard(
              key: LumeAyahTool.cardKey,
              reference: reference,
              arabic: ayah.arabic,
              translation: ayah.translation,
              transliteration: ayah.transliteration,
              fallbackNote: resolved.isFallback
                  ? l.readerFallbackEnglish
                  : null,
              actions: <Widget>[
                LumeButton.accent(
                  key: LumeAyahTool.shareKey,
                  label: l.commonShare,
                  icon: LumeIcons.share,
                  onPressed: () => _host.currentState?.share(),
                ),
                LumeButton(
                  key: LumeAyahTool.saveKey,
                  label: saved ? l.commonSaved : l.commonSave,
                  icon: LumeIcons.bookmark,
                  // The reference's bookmark does nothing (`bookmark:ayah`
                  // has no handler). This keeps today's ayah for the session
                  // and says so, exactly as Hadith's own Save does (C77).
                  onPressed: () {
                    setState(() => _write('saved', saved ? '' : dayId));
                    _host.currentState?.say(
                      saved ? l.ayahUnsaved : l.ayahSaved,
                    );
                  },
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.ayahMoreVerses,
            child: LumeRows(
              key: LumeAyahTool.moreKey,
              children: <Widget>[
                for (final LumeAyah a in LumeQuranFixtures.ayat)
                  LumeRichRow(
                    icon: LumeIcons.book,
                    title: l.quranVerseReference(
                      a.surahName,
                      a.surahNumber,
                      a.ayahNumber,
                    ),
                    subtitle: a.translation,
                    chevron: true,
                    onTap: () => r.onOpenRelated?.call('quran'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
