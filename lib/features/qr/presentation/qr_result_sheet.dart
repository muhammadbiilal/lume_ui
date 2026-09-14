/// What a QR code said — and the one press that goes where it leads (C80).
///
/// A read code is shown before anything happens: its kind as the title, the
/// destination the reader should judge (a host, a number, an address, a
/// network), a note where Lume holds something back, and the whole decoded
/// text, selectable and never interpreted as markup. **Open** exists only for
/// a destination `LumeQrPayload` has checked, and goes through the dialer or
/// the link opener; **Copy** puts the shown text on the clipboard — for Wi-Fi,
/// the network name, never the password.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/providers/platform_services.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_dialer.dart';
import '../../../core/platform/lume_link_opener.dart';
import '../../../core/platform/lume_qr_payload.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../l10n/app_localizations.dart';

Future<void> showLumeQrResult({
  required BuildContext context,
  required LumeQrPayload payload,
}) => showLumeSheet<void>(
  context: context,
  barrierLabel: AppLocalizations.of(context).actionClose,
  child: LumeQrResultSheet(payload: payload),
);

class LumeQrResultSheet extends ConsumerStatefulWidget {
  const LumeQrResultSheet({super.key, required this.payload});

  final LumeQrPayload payload;

  static const Key destinationKey = ValueKey<String>('qr.result.destination');
  static const Key noteKey = ValueKey<String>('qr.result.note');
  static const Key textKey = ValueKey<String>('qr.result.text');
  static const Key openKey = ValueKey<String>('qr.result.open');
  static const Key copyKey = ValueKey<String>('qr.result.copy');

  static String kindLabel(AppLocalizations l, LumeQrKind kind) =>
      switch (kind) {
        LumeQrKind.web => l.qrKindLink,
        LumeQrKind.phone => l.qrKindPhone,
        LumeQrKind.message => l.qrKindMessage,
        LumeQrKind.email => l.qrKindEmail,
        LumeQrKind.wifi => l.qrKindWifi,
        LumeQrKind.contact => l.qrKindContact,
        LumeQrKind.location => l.qrKindLocation,
        LumeQrKind.text => l.qrKindText,
        LumeQrKind.refused => l.qrKindRefused,
      };

  static String iconOf(LumeQrKind kind) => switch (kind) {
    LumeQrKind.web => LumeIcons.globe,
    LumeQrKind.phone => LumeIcons.phone,
    LumeQrKind.message => LumeIcons.message,
    LumeQrKind.email => LumeIcons.mail,
    LumeQrKind.wifi => LumeIcons.wifi,
    LumeQrKind.contact => LumeIcons.user,
    LumeQrKind.location => LumeIcons.pin,
    LumeQrKind.text => LumeIcons.note,
    LumeQrKind.refused => LumeIcons.alert,
  };

  /// What Lume holds back, or why it will not go there; `null` when nothing.
  static String? noteOf(AppLocalizations l, LumeQrPayload p) {
    final String t = p.raw.trim();
    return switch (p.kind) {
      LumeQrKind.web => p.insecure ? l.qrNoteInsecure : null,
      LumeQrKind.message =>
        RegExp(
              r'^(sms:[^?]*\?.*\S|smsto:[^:]*:.*\S)',
              caseSensitive: false,
              dotAll: true,
            ).hasMatch(t)
            ? l.qrNoteMessage
            : null,
      LumeQrKind.email =>
        RegExp(
              r'^(mailto:[^?]*\?.*\S|matmsg:.*;(sub|body):[^;]*\S)',
              caseSensitive: false,
              dotAll: true,
            ).hasMatch(t)
            ? l.qrNoteEmail
            : null,
      LumeQrKind.wifi => l.qrNoteWifi,
      LumeQrKind.contact => l.qrNoteContact,
      LumeQrKind.location => l.qrNoteLocation,
      LumeQrKind.refused => l.qrNoteRefused,
      LumeQrKind.phone || LumeQrKind.text => null,
    };
  }

  static String? openLabel(AppLocalizations l, LumeQrPayload p) {
    if (!p.opens) return null;
    return switch (p.kind) {
      LumeQrKind.web => l.qrOpenSite,
      LumeQrKind.phone => l.qrOpenPhone,
      LumeQrKind.message => l.qrOpenMessage,
      LumeQrKind.email => l.qrOpenEmail,
      _ => null,
    };
  }

  /// First-strong isolation, so a host or a number keeps its own order inside
  /// an Urdu or Arabic sentence.
  static String isolated(String s) =>
      '${String.fromCharCode(0x2068)}$s${String.fromCharCode(0x2069)}';

  @override
  ConsumerState<LumeQrResultSheet> createState() => _LumeQrResultSheetState();
}

class _LumeQrResultSheetState extends ConsumerState<LumeQrResultSheet> {
  bool _busy = false;

  void _say(String message, LumeToastTone tone) =>
      showLumeToast(context, LumeToastData(message: message, tone: tone));

  Future<void> _copy() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeQrPayload p = widget.payload;
    final String text = p.kind == LumeQrKind.wifi
        ? p.destination ?? ''
        : p.shownText;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _say(l.qrCopied, LumeToastTone.success);
  }

  Future<void> _open() async {
    final LumeQrPayload p = widget.payload;
    final Uri? target = p.target;
    if (_busy || target == null) return;
    final AppLocalizations l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final bool opened;
      final (String, LumeToastTone)? said;
      if (p.kind == LumeQrKind.phone) {
        final LumeDialOutcome o = await ref
            .read(dialerProvider)
            .dial(p.destination!);
        opened = o == LumeDialOutcome.opened;
        said = switch (o) {
          LumeDialOutcome.opened || LumeDialOutcome.cancelled => null,
          LumeDialOutcome.unavailable => (
            l.qrOpenUnavailable,
            LumeToastTone.info,
          ),
          LumeDialOutcome.malformed ||
          LumeDialOutcome.failed => (l.qrOpenFailed, LumeToastTone.error),
        };
      } else {
        final LumeOpenOutcome o = await ref
            .read(linkOpenerProvider)
            .open(target);
        opened = o == LumeOpenOutcome.opened;
        said = switch (o) {
          LumeOpenOutcome.opened => null,
          LumeOpenOutcome.unavailable => (
            l.qrOpenUnavailable,
            LumeToastTone.info,
          ),
          LumeOpenOutcome.refused ||
          LumeOpenOutcome.failed => (l.qrOpenFailed, LumeToastTone.error),
        };
      }
      if (!mounted) return;
      if (said != null) {
        _say(said.$1, said.$2);
      } else if (opened) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeQrPayload p = widget.payload;
    final lume = context.lume;
    final String? note = LumeQrResultSheet.noteOf(l, p);
    final String? open = LumeQrResultSheet.openLabel(l, p);
    final bool rtl = intl.Bidi.detectRtlDirectionality(p.shownText);

    return LumeSheet(
      title: LumeQrResultSheet.kindLabel(l, p.kind),
      subtitle: l.qrResultNote,
      closeLabel: l.actionClose,
      onClose: () => Navigator.of(context).pop(),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (p.destination != null)
              LumeRows(
                children: <Widget>[
                  LumeRichRow(
                    key: LumeQrResultSheet.destinationKey,
                    icon: LumeQrResultSheet.iconOf(p.kind),
                    title: LumeQrResultSheet.isolated(p.destination!),
                    subtitle: note,
                  ),
                ],
              )
            else if (note != null)
              Text(
                note,
                key: LumeQrResultSheet.noteKey,
                style: LumeType.fit(
                  context,
                  context.lumeType.meta,
                ).copyWith(color: lume.text2),
              ),
            const SizedBox(height: LumeSpace.x4),
            Text(
              l.qrFullText,
              style: LumeType.fit(
                context,
                context.lumeType.metaSmall,
              ).copyWith(color: lume.text3),
            ),
            const SizedBox(height: LumeSpace.x2),
            Container(
              key: LumeQrResultSheet.textKey,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(LumeSpace.x3),
              decoration: BoxDecoration(
                color: lume.bgSunk,
                borderRadius: LumeRadius.brMd,
                border: Border.all(color: lume.border, width: LumeSpace.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  p.shownText,
                  textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                  style: LumeType.natural(
                    context,
                    context.lumeType.body,
                  ).copyWith(color: lume.text),
                ),
              ),
            ),
            const SizedBox(height: LumeSpace.x4),
            LumeButtonRow(
              children: <Widget>[
                LumeButton(
                  key: LumeQrResultSheet.copyKey,
                  label: p.kind == LumeQrKind.wifi ? l.qrCopyNetwork : l.qrCopy,
                  onPressed: _copy,
                ),
                if (open != null)
                  LumeButton.accent(
                    key: LumeQrResultSheet.openKey,
                    label: open,
                    icon: LumeIcons.arrowUr,
                    onPressed: _busy ? null : _open,
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
