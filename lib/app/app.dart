/// The Lume application widget.
///
/// At Phase F1 this hosts the token gallery, which is what makes the
/// foundation verifiable before a single screen exists. The router, the shell
/// and the five destinations arrive in F3; the gallery route survives as a
/// development surface.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fixtures/lume_clock.dart';
import '../core/layout/lume_breakpoint.dart';
import '../core/localization/lume_locales.dart';
import '../core/theme/lume/lume_theme.dart';
import '../features/gallery/presentation/gallery_screen.dart';
import '../l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';

class LumeApp extends ConsumerWidget {
  const LumeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Lume',
      debugShowCheckedModeBanner: false,

      theme: LumeTheme.light(),
      darkTheme: LumeTheme.dark(),
      themeMode: themeMode,

      locale: locale,
      supportedLocales: LumeLocales.supported,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: LumeLocales.resolve,

      builder: (BuildContext context, Widget? child) {
        // Everything below measures the shell rather than the window, and
        // reads the real clock unless a fixture pinned one.
        return LumeClockScope(
          clock: const LumeClock.system(),
          child: LumeBreakpointScope(child: child ?? const SizedBox.shrink()),
        );
      },

      home: const GalleryScreen(),
    );
  }
}
