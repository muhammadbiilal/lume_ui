/// The Lume application widget.
///
/// F1 hosted the token gallery directly, because the foundation had to be
/// verifiable before a single screen existed. F3 gives the app a router: the
/// six branches, the destinations that ride on them, and the two flows that
/// cover the shell. The gallery survives as a development surface reached from
/// the profile branch rather than as the application's home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/fixtures/lume_clock.dart';
import '../core/layout/lume_breakpoint.dart';
import '../core/localization/lume_locales.dart';
import '../core/routing/app_router.dart';
import '../core/theme/lume/lume_theme.dart';
import '../l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';

class LumeApp extends ConsumerWidget {
  const LumeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
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

      routerConfig: router,

      builder: (BuildContext context, Widget? child) {
        // Everything below measures the shell rather than the window, and
        // reads the real clock unless a fixture pinned one. The shell installs
        // a second, narrower scope inside its own width cap; this one is the
        // fallback for the flows that cover the shell and have none.
        return LumeClockScope(
          clock: const LumeClock.system(),
          child: LumeBreakpointScope(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
