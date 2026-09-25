/// WhatsApp Status Saver — `tools/daily/wastatus.tool.js`.
///
/// The reference is not a working scanner: it is a static composition — a
/// note card saying "Android only", then a permanently empty "Detected
/// statuses" list whose one button (`act: 'toast:' + c.t('wastatus.granting')`)
/// does nothing but show a toast. No build of that reference, on any
/// platform, ever lists a real status: a browser cannot read another app's
/// files, so the "Grant folder access" button had nothing behind it to grant.
///
/// A real status saver would read WhatsApp's own local status cache, which
/// needs broad storage access to a *third-party app's* files — a
/// meaningfully different, more invasive permission than anything else Lume
/// asks for. This app's manifest deliberately carries none of it:
/// `READ_EXTERNAL_STORAGE` is removed (`tools:node="remove"`), and neither
/// `MANAGE_EXTERNAL_STORAGE` nor any `READ_MEDIA_*` scoped-storage permission
/// is declared (`android_manifest_test.dart`). Nothing in this build offers a
/// folder-tree picker either (no SAF package, no native channel), so there is
/// no honest interactive path to "here are your statuses" — reproducing the
/// reference's fake empty state and fake grant button would additionally
/// *imply* access to another app's files that Lume cannot and does not have.
///
/// So this screen keeps the reference's honesty (it is fine with saying
/// "Android only") and drops its theatre: no scan, no fake permission
/// request, no invented count. In its place, real information a reader can
/// actually act on — WhatsApp's own save control, which needs nothing from
/// Lume at all — and a plainly-hedged pointer to Android's own Files app for
/// what WhatsApp still has cached. `LumeToolScreen.bare` is used throughout
/// (§F6B decision 5): with no figures of any kind on this screen, there is
/// nothing for a source bar to truthfully claim, and `LumeDataCapability`'s
/// default fixture classification (`isSample: true`, decided for every tool
/// not otherwise listed in `tool_capability.dart`) would be wrong here — this
/// screen shows no records, feed or fixture, sample or otherwise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/personalisation.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';

class LumeWastatusTool extends ConsumerStatefulWidget {
  const LumeWastatusTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeWastatusTool(request: request);

  static const String id = 'wastatus';

  static const Key whyKey = ValueKey<String>('wastatus.why');
  static const Key saveKey = ValueKey<String>('wastatus.save');
  static const Key folderKey = ValueKey<String>('wastatus.folder');
  static const Key relatedKey = ValueKey<String>('wastatus.related');

  @override
  ConsumerState<LumeWastatusTool> createState() => _LumeWastatusToolState();
}

class _LumeWastatusToolState extends ConsumerState<LumeWastatusTool> {
  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeEligibility eligibility = ref.watch(eligibilityProvider);

    // The same eligibility-filtered rail the frame builds for every other
    // tool (`tool_screen.dart`) — reproduced by hand because `bare: true`
    // turns the frame's own copy off along with the source bar it exists to
    // suppress here.
    final List<LumeRelatedTool> related = <LumeRelatedTool>[
      for (final String relatedId in r.feature.related)
        if (eligibility.visibleById(relatedId, r.user)
            case final LumeFeature rf)
          LumeRelatedTool(
            id: rf.id,
            name: LumeFeatureStrings.name(l, rf.id),
            icon: rf.icon,
          ),
    ];

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // No figures, no records, nothing to source: the frame's source bar,
      // privacy note and related rail are all built from data this screen
      // does not have, so its own body supplies the one part (Related) that
      // still applies.
      bare: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeNotice(
              key: LumeWastatusTool.whyKey,
              kind: LumeNoticeKind.info,
              title: l.wastatusWhyTitle,
              text: l.wastatusWhyText,
            ),
          ),
          LumeToolSection(
            title: l.wastatusSaveTitle,
            subtitle: l.wastatusSaveSubtitle,
            child: Column(
              key: LumeWastatusTool.saveKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _WastatusStep(
                  number: 1,
                  title: l.wastatusStep1Title,
                  text: l.wastatusStep1Text,
                ),
                const SizedBox(height: LumeSpace.x4),
                _WastatusStep(
                  number: 2,
                  title: l.wastatusStep2Title,
                  text: l.wastatusStep2Text,
                ),
                const SizedBox(height: LumeSpace.x4),
                _WastatusStep(
                  number: 3,
                  title: l.wastatusStep3Title,
                  text: l.wastatusStep3Text,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.wastatusFolderTitle,
            child: LumeNotice(
              key: LumeWastatusTool.folderKey,
              kind: LumeNoticeKind.info,
              title: l.wastatusFolderNoteTitle,
              text: l.wastatusFolderNoteText,
            ),
          ),
          if (related.isNotEmpty)
            LumeToolSection(
              title: l.toolRelated,
              child: LumeRelatedTools(
                key: LumeWastatusTool.relatedKey,
                tools: related,
                onOpen: r.onOpenRelated,
              ),
            ),
        ],
      ),
    );
  }
}

/// One numbered step in "Save a status yourself" — a plain row rather than
/// [LumeRichRow]'s single-line subtitle, because real instructions need to
/// wrap at any length and any text scale (§60, §17) rather than ellipsize.
class _WastatusStep extends StatelessWidget {
  const _WastatusStep({
    required this.number,
    required this.title,
    required this.text,
  });

  final int number;
  final String title;
  final String text;

  static const double _badge = 28;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: _badge,
            height: _badge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: lume.tintAccent,
              shape: BoxShape.circle,
            ),
            child: ExcludeSemantics(
              child: Text(
                '$number',
                style: LumeType.fit(
                  context,
                  context.lumeType.metaSmall,
                ).copyWith(color: lume.accent, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: LumeSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: LumeType.fit(
                    context,
                    context.lumeType.cardTitle,
                  ).copyWith(color: lume.text),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: LumeType.fit(
                    context,
                    context.lumeType.body,
                  ).copyWith(color: lume.text2, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
