/// Al-Qur'an — the surah library (quran/quransearch/ayah wave).
///
/// `tools/islamic/quran.tool.js`: a search over the surahs, and the library
/// of surahs to browse. The reference's own screen also carries a
/// continue-reading progress card, a juz list and a bookmarks view — all
/// built from fixed demo values with nothing behind them (the progress card
/// names "Al-Kahf 42", an ayah this build does not hold at all), so none of
/// the three is ported: showing a "current place" nobody is actually at
/// would be exactly the kind of unearned freshness claim `KNOWN_DIFFERENCES.md`
/// flags elsewhere in this codebase. What this screen keeps is what is real:
/// the twelve surahs the reference holds, searchable exactly as it searches
/// them, and — for the two surahs this build also holds an ayah for — that
/// ayah, genuinely, revealed on tap rather than merely toasted.
///
/// Faith-gated in the catalogue; the gate decides who reaches this screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/quran_fixtures.dart';
import '../domain/quran_model.dart';
import 'quran_text.dart';

class LumeQuranTool extends ConsumerStatefulWidget {
  const LumeQuranTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeQuranTool(request: request);

  static const String id = 'quran';

  static const Key searchKey = ValueKey<String>('quran.search');
  static const Key browseKey = ValueKey<String>('quran.browse');
  static const Key emptyKey = ValueKey<String>('quran.empty');
  static const Key readerKey = ValueKey<String>('quran.reader');

  @override
  ConsumerState<LumeQuranTool> createState() => _LumeQuranToolState();
}

class _LumeQuranToolState extends ConsumerState<LumeQuranTool> {
  static const String _id = LumeQuranTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(_id, 'q') ?? '',
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String? _read(String k) => _session.read(_id, k);
  void _write(String k, String v) => _session.write(_id, k, v);

  String _place(AppLocalizations l, LumeSurahPlace p) => switch (p) {
    LumeSurahPlace.meccan => l.quranMeccan,
    LumeSurahPlace.medinan => l.quranMedinan,
  };

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final List<LumeSurah> shown = LumeQuranFixtures.surahsMatching(_query.text);

    final int? selectedSurah = int.tryParse(_read('surah') ?? '');
    final LumeAyah? selected = selectedSurah == null
        ? null
        : LumeQuranFixtures.ayahForSurah(selectedSurah);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // Nothing to share until a real ayah is on screen (D7): the header's
      // Share stays disabled until then.
      shareCard: selected == null
          ? null
          : () => LumeShareCard.forFeature(
              sensitive: r.feature.sensitive,
              kind: LumeShareKind.quran,
              text: selected.translation,
              source: l.quranVerseReference(
                selected.surahName,
                selected.surahNumber,
                selected.ayahNumber,
              ),
              arabic: selected.arabic,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeSearchField(
              key: LumeQuranTool.searchKey,
              controller: _query,
              placeholder: l.quranSearchPlaceholder,
              onChanged: (String q) => setState(() => _write('q', q)),
            ),
          ),
          if (selected != null)
            LumeToolSection(
              child: LumeAyahCard(
                key: LumeQuranTool.readerKey,
                reference: l.quranVerseReference(
                  selected.surahName,
                  selected.surahNumber,
                  selected.ayahNumber,
                ),
                arabic: selected.arabic,
                translation: selected.translation,
                transliteration: selected.transliteration,
              ),
            ),
          LumeToolSection(
            title: l.quranSurahsTitle,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeQuranTool.emptyKey,
                    icon: LumeIcons.search,
                    title: l.quranNoMatch,
                    text: l.quranNoMatchText,
                  )
                : LumeRows(
                    key: LumeQuranTool.browseKey,
                    children: <Widget>[
                      for (final LumeSurah s in shown)
                        _surahRow(l, s, selectedSurah == s.number),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _surahRow(AppLocalizations l, LumeSurah s, bool isSelected) {
    final LumeAyah? ayah = LumeQuranFixtures.ayahForSurah(s.number);
    return LumeRichRow(
      logo: '${s.number}',
      title: s.name,
      subtitle: s.meaning,
      meta: <String>[l.quranAyahCount(s.ayahCount), _place(l, s.place)],
      trailing: LumeQuranArabicText(s.arabicName, size: 15),
      selected: isSelected,
      chevron: true,
      onTap: () {
        if (ayah == null) {
          // The reference toasts the surah's bare name, which reads like
          // the start of something opening. Lume holds no text for it, and
          // says that.
          _host.currentState?.say(
            l.quranSurahNotHeld(s.name),
            tone: LumeToastTone.info,
          );
          return;
        }
        setState(() => _write('surah', isSelected ? '' : '${s.number}'));
      },
    );
  }
}
