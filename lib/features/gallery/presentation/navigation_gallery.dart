/// The navigation surfaces, in every state, on one page.
///
/// The shell only ever shows one of the three, and only ever in the state the
/// current route puts it in. That makes the other eleven combinations — a rail
/// with a badge, a sidebar with nothing selected, a bar in Urdu with a count on
/// Today — things you would otherwise have to navigate the app into. Here they
/// are side by side, which is how a drift in one of them gets noticed.
///
/// Development-only, like the rest of the gallery. One route reaches it —
/// `/profile/navigation-gallery` — and nothing in the product links to it.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/lume_destination.dart';
import '../../../core/navigation/lume_navigation_surfaces.dart';
import '../../../core/navigation/lume_shell.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../l10n/app_localizations.dart';

/// Every navigation surface, every state.
class NavigationGallery extends StatefulWidget {
  const NavigationGallery({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<NavigationGallery> createState() => _NavigationGalleryState();
}

class _NavigationGalleryState extends State<NavigationGallery> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;

    String label(LumeDestinationId id) => switch (id) {
      LumeDestinationId.home => l.navHome,
      LumeDestinationId.tools => l.navTools,
      LumeDestinationId.trains => l.navTrains,
      LumeDestinationId.today => l.navToday,
      LumeDestinationId.explore => l.navExplore,
      LumeDestinationId.profile => l.navProfile,
    };

    final List<LumeDestination> pk = LumeDestinations.build(
      countryCode: 'PK',
      label: label,
    );
    final List<LumeDestination> global = LumeDestinations.build(
      countryCode: 'GB',
      label: label,
    );
    final List<LumeDestination> decorated = LumeDestinations.build(
      countryCode: 'PK',
      label: label,
      badges: const <LumeDestinationId, int>{LumeDestinationId.today: 3},
      dots: const <LumeDestinationId>{LumeDestinationId.profile},
    );

    return ColoredBox(
      color: lume.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: LumeSpace.x10),
          children: <Widget>[
            LumeToolbar(
              title: l.a11yMainNavigation,
              subtitle: l.navTools,
              onBack: widget.onBack,
              backLabel: l.actionBack,
            ),

            _Case(
              name: 'tabbar · PK · selected $_selected',
              child: LumeBottomBar(
                destinations: pk,
                selectedIndex: _selected,
                onSelected: (int i) => setState(() => _selected = i),
                semanticLabel: l.a11yMainNavigation,
              ),
            ),
            _Case(
              name: 'tabbar · global',
              child: LumeBottomBar(
                destinations: global,
                selectedIndex: 1,
                onSelected: (_) {},
              ),
            ),
            // The state the reference reaches whenever the current destination
            // is not a tab: no selection, and the pill hidden rather than
            // parked somewhere arbitrary.
            _Case(
              name: 'tabbar · no tab selected',
              child: LumeBottomBar(
                destinations: pk,
                selectedIndex: -1,
                onSelected: (_) {},
              ),
            ),
            _Case(
              name: 'tabbar · badge and dot',
              child: LumeBottomBar(
                destinations: decorated,
                selectedIndex: 0,
                onSelected: (_) {},
              ),
            ),

            _Case(
              name: 'navside · rail (84)',
              height: 320,
              child: LumeNavigationRail(
                destinations: pk,
                selectedIndex: 2,
                onSelected: (_) {},
                expanded: false,
                semanticLabel: l.a11yMainNavigation,
              ),
            ),
            _Case(
              name: 'navside · rail · badge and dot',
              height: 320,
              child: LumeNavigationRail(
                destinations: decorated,
                selectedIndex: -1,
                onSelected: (_) {},
                expanded: false,
              ),
            ),
            _Case(
              name: 'navside · sidebar (244)',
              height: 380,
              child: LumeNavigationRail(
                destinations: pk,
                selectedIndex: 0,
                onSelected: (_) {},
                expanded: true,
                brand: 'Lume',
                semanticLabel: l.a11yMainNavigation,
              ),
            ),
            _Case(
              name: 'navside · sidebar · badge and dot',
              height: 380,
              child: LumeNavigationRail(
                destinations: decorated,
                selectedIndex: 3,
                onSelected: (_) {},
                expanded: true,
                brand: 'Lume',
              ),
            ),

            const _Case(
              name: 'statusbar · medium',
              child: LumeStatusStrip(brand: 'Lume', clock: '9:41'),
            ),
            const _Case(
              name: 'statusbar · expanded',
              child: LumeStatusStrip(
                brand: 'Lume',
                clock: '9:41',
                gutter: LumeSpace.pageExpanded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Case extends StatelessWidget {
  const _Case({required this.name, required this.child, this.height});

  final String name;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LumeSpace.pageCompact,
        LumeSpace.x5,
        LumeSpace.pageCompact,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            name,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3),
          ),
          const SizedBox(height: LumeSpace.x2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: lume.bgSunk,
              borderRadius: LumeRadius.brMd,
              border: Border.all(color: lume.border, width: LumeSpace.border),
            ),
            child: height == null
                ? child
                : SizedBox(
                    height: height,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: child,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
