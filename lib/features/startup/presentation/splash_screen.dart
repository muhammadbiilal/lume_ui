/// What shows while the launch is still deciding.
///
/// **The only honest thing to draw.** Home would be a guess about the session,
/// and Sign In would be a guess the other way — and a guess that turns out
/// wrong is a flash of the wrong screen in front of somebody who has done
/// nothing but open the application.
///
/// So it is the brand, on the ground colour, with nothing that looks like
/// progress: a spinner on a launch that resolves in 40 ms reads as a stall.
/// A screen reader is told what is happening, because "nothing announced" is
/// not the same as "nothing is happening".
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_chrome.dart';

class LumeSplashScreen extends StatelessWidget {
  const LumeSplashScreen({super.key});

  /// Addressed by the startup tests, which assert what is *not* on screen as
  /// much as what is.
  static const Key surface = Key('startup.splash');

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final AppLocalizations l = AppLocalizations.of(context);

    return Semantics(
      container: true,
      label: l.startupLoading,
      child: ColoredBox(
        key: LumeSplashScreen.surface,
        color: lume.bg,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: LumeAuthAmbient()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: lume.accent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: context.lumeShadows.sm,
                    ),
                    child: Center(
                      child: LumeIcon(
                        LumeIcons.lume,
                        size: 30,
                        color: lume.onAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Lume',
                    style: context.lumeType.body.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 20 * -0.035,
                      color: lume.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
