/// The master-detail shell: one selection, two layouts, nothing rebuilt.
///
/// The CRUD guide's rule is that selecting a record at expanded width updates a
/// pane and *does not push a route*, so the list keeps its scroll, its filter
/// and its sort — it is never rebuilt. [LumeMasterDetail] already lays that
/// out. What this adds is the part that makes it hold together on a device:
///
/// **One piece of state, read by both layouts.** The selected id lives here,
/// not in the route, so a rotation is a re-layout and nothing else. A phone
/// turned sideways mid-record does not lose the record, and a tablet folded to
/// a phone does not have to unwind a pushed page it never pushed.
///
/// **The list never leaves the tree.** At compact the detail *replaces* it
/// visually, but the list stays behind it, offstage — same position in the
/// tree, so the same element and the same `State`, and therefore the same
/// scroll offset, filter chips and controllers when the record closes. An `if`
/// would drop that element and take all of it with it, which is the whole
/// reason this is a widget.
///
/// **Back clears the selection before it pops.** At compact, the record is
/// showing over the list, so the first Back should return to the list. A
/// [BackButtonListener] takes that press; the second one leaves the screen.
/// At expanded there is nothing to clear — the list is still on screen — so
/// Back is left alone.
///
/// **The URL carries a selection in, not out.** A deep link to a record lands
/// here through [initialSelectedId]; selecting afterwards does not rewrite the
/// location. The reference has no locations at all, so nothing is lost, and the
/// alternative — a route per selection — is exactly the rebuild the CRUD guide
/// says not to do. Recorded in KNOWN_DIFFERENCES.
library;

import 'package:flutter/material.dart';

import '../layout/lume_breakpoint.dart';
import 'lume_back_intercept.dart';
import '../widgets/lume/lume_crud.dart';

/// A collection screen drawn as a list, a detail, or both.
class LumeMasterDetailShell extends StatefulWidget {
  const LumeMasterDetailShell({
    super.key,
    required this.listBuilder,
    required this.detailBuilder,
    required this.emptyDetail,
    this.initialSelectedId,
    this.onSelectionChanged,
    this.controller,
  });

  /// The list. Kept at one position in the tree, so its scroll and its filters
  /// survive every selection change and every rotation. `select` is how a row
  /// reports a tap; `selectedId` is what a row uses to draw itself as current.
  final Widget Function(
    BuildContext context,
    String? selectedId,
    ValueChanged<String?> select,
  )
  listBuilder;

  /// One record. Called with the selected id.
  final Widget Function(BuildContext context, String id) detailBuilder;

  /// What the detail pane shows when nothing is selected. Never blank —
  /// `.cstate--pane` exists for this.
  final Widget emptyDetail;

  /// A selection arriving from the route. Applied once, on first build.
  final String? initialSelectedId;

  /// Reported so a screen can mirror the selection somewhere it matters —
  /// a title, an action bar. Not used to navigate.
  final ValueChanged<String?>? onSelectionChanged;

  /// Drives the selection from outside: a search result, a notification tap,
  /// an "open the one I just created". Owned by the caller when supplied.
  final LumeSelectionController? controller;

  @override
  State<LumeMasterDetailShell> createState() => _LumeMasterDetailShellState();
}

/// The selected record id, as something a screen can hold and change.
class LumeSelectionController extends ChangeNotifier {
  LumeSelectionController([this._id]);

  String? _id;
  String? get id => _id;

  set id(String? next) {
    if (_id == next) return;
    _id = next;
    notifyListeners();
  }

  void clear() => id = null;
}

class _LumeMasterDetailShellState extends State<LumeMasterDetailShell> {
  /// The two layouts put the list and the detail at different depths — a row
  /// at expanded, a stack at compact — so a rotation would otherwise drop both
  /// elements and every scroll offset, filter and half-typed field with them.
  /// A [GlobalKey] reparents an element instead of replacing it, which is the
  /// one thing that makes turning the device a re-layout rather than a reset.
  final GlobalKey _listKey = GlobalKey(debugLabel: 'master-detail list');
  final GlobalKey _detailKey = GlobalKey(debugLabel: 'master-detail detail');

  LumeSelectionController? _own;
  LumeSelectionController get _selection => widget.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _own = LumeSelectionController(widget.initialSelectedId);
    } else if (widget.initialSelectedId != null) {
      widget.controller!.id = widget.initialSelectedId;
    }
    _selection.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(LumeMasterDetailShell old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onSelectionChanged);
      _own?.removeListener(_onSelectionChanged);
      if (widget.controller == null) {
        _own ??= LumeSelectionController(old.controller?.id);
      }
      _selection.addListener(_onSelectionChanged);
    }
    // A *new* deep link — the same screen asked to show a different record —
    // moves the selection. A rebuild with the same link does not, or the
    // screen could never be navigated away from its own initial record.
    if (widget.initialSelectedId != old.initialSelectedId &&
        widget.initialSelectedId != null) {
      _selection.id = widget.initialSelectedId;
    }
  }

  @override
  void dispose() {
    _selection.removeListener(_onSelectionChanged);
    _own?.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    setState(() {});
    widget.onSelectionChanged?.call(_selection.id);
  }

  void _select(String? id) => _selection.id = id;

  /// Compact Back: the record is over the list, so the first press returns to
  /// the list rather than leaving the screen.
  Future<bool> _onBack() async {
    if (_selection.id == null) return false;
    if (context.hasDetailPane) return false;
    _select(null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final String? id = _selection.id;
    final bool twoPanes = context.hasDetailPane;

    final Widget list = KeyedSubtree(
      key: _listKey,
      child: widget.listBuilder(context, id, _select),
    );

    // Two keys, doing different jobs: the outer one carries the element across
    // a rotation, the inner one replaces the subtree when the record changes,
    // so a detail never shows one record's scroll position under another's
    // content.
    final Widget detail = KeyedSubtree(
      key: _detailKey,
      child: KeyedSubtree(
        key: ValueKey<String?>(id),
        child: id == null
            ? widget.emptyDetail
            : widget.detailBuilder(context, id),
      ),
    );

    if (twoPanes) return LumeMasterDetail(list: list, detail: detail);

    final Widget stack = Stack(
      // The list is offstage while a record shows, so it contributes no size —
      // the stack has to take the outlet's instead.
      fit: StackFit.expand,
      children: <Widget>[
        // Offstage rather than removed: the list keeps its scroll offset, its
        // filter state and its controllers while a record is showing.
        Offstage(
          offstage: id != null,
          child: TickerMode(enabled: id == null, child: list),
        ),
        if (id != null) Positioned.fill(child: detail),
      ],
    );

    return LumeBackIntercept(onBack: _onBack, child: stack);
  }
}
