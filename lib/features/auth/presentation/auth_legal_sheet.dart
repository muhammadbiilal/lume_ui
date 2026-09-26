/// `#sheet-authlegal` — sign-up step two's "How Lume handles your data".
///
/// A sheet rather than a screen, as the reference says why (§126.40):
/// navigating away from step two would take the password the reader has just
/// typed with it; a sheet leaves the form underneath exactly as it was.
///
/// **Dayroz obligation:** this says where Lume keeps things in this build —
/// on the device. Once accounts sync, the copy has to say what the service
/// holds, and link the published privacy policy.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';

Future<void> showLumeAuthLegal(BuildContext context) {
  final AppLocalizations l = AppLocalizations.of(context);
  return showLumeSheet<void>(
    context: context,
    barrierLabel: l.authLegalTitle,
    child: Builder(
      builder: (BuildContext sheetContext) => LumeSheet(
        child: LumeAuthLegalSheet(
          onClose: () => Navigator.of(sheetContext).maybePop(),
        ),
      ),
    ),
  );
}

/// `.dconfirm` with the legal copy and one Close.
class LumeAuthLegalSheet extends StatelessWidget {
  const LumeAuthLegalSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final TextStyle text = LumeType.fit(
      context,
      context.lumeType.body,
    ).copyWith(color: lume.text2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              l.authLegalTitle,
              textAlign: TextAlign.center,
              style: LumeType.fit(
                context,
                context.lumeType.title,
              ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(l.authLegalBody, textAlign: TextAlign.center, style: text),
          const SizedBox(height: 10),
          Text(l.authLegalWhere, textAlign: TextAlign.center, style: text),
          const SizedBox(height: 20),
          LumeButtonRow(
            children: <Widget>[
              LumeButton(label: l.actionClose, block: true, onPressed: onClose),
            ],
          ),
        ],
      ),
    );
  }
}
