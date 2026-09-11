/// "What are you here for?" — the picker's rules, as data.
///
/// Every rule here is `makePicker`'s in `ui/pickers.js`, and the count
/// resolution behind the group list is in
/// `docs/conversion_archive/INTERESTS_CATALOGUE.md`.
///
/// * **Five minimum, ten maximum.** `PICK_MIN = 5, PICK_MAX = 10`.
/// * **Six groups**, five ordinary and one faith group that is kept apart on
///   purpose — it is the switch that turns the Islamic experience on, and it is
///   never preselected for anyone.
/// * **An interest that cannot lead anywhere is not offered.** `liveItems`
///   keeps an ordinary interest only when some *visible* feature declares it.
///   The faith group is exempt, because it is what makes its own features
///   exist.
/// * **At the cap, the rest step back rather than disappear** — `.is-muted`,
///   and a tap is refused with a message instead of silently doing nothing.
/// * **Turning the faith group on selects prayer, Qur'an and duas** if there is
///   room; turning it off removes every faith interest.
library;

import 'package:flutter/foundation.dart';

/// One interest.
@immutable
class LumeInterest {
  const LumeInterest({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;

  /// Already localised by whoever built the list.
  final String label;

  final String icon;

  @override
  bool operator ==(Object other) =>
      other is LumeInterest && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

/// One group of interests.
@immutable
class LumeInterestGroup {
  const LumeInterestGroup({
    required this.id,
    required this.label,
    required this.interests,
    this.faith = false,
  });

  final String id;

  /// Rendered as the `.pickgroup__label`, except for the faith group, whose
  /// heading is the switch itself.
  final String label;

  final List<LumeInterest> interests;

  /// The one group that is a switch rather than a heading.
  final bool faith;
}

/// Everything the interests step renders.
@immutable
class LumeInterestsModel {
  const LumeInterestsModel({
    required this.groups,
    required this.selected,
    required this.faithOpen,
  });

  /// Already filtered: a group with nothing left in it is not in this list.
  final List<LumeInterestGroup> groups;

  final Set<String> selected;

  /// Whether the faith group's switch is on. Its interests are only reachable
  /// when it is.
  final bool faithOpen;

  int get count => selected.length;

  bool get atCap => count >= LumeInterests.maximum;
  bool get meetsMinimum => count >= LumeInterests.minimum;
  bool get canContinue => meetsMinimum;

  /// How many more are needed before Continue turns on.
  int get remaining =>
      (LumeInterests.minimum - count).clamp(0, LumeInterests.minimum);

  bool isSelected(String id) => selected.contains(id);

  /// At the cap an unselected chip is muted; a selected one never is.
  bool isMuted(String id) => atCap && !selected.contains(id);
}

/// The rules, and the filter that decides what is offered.
abstract final class LumeInterests {
  /// `PICK_MIN`.
  static const int minimum = 5;

  /// `PICK_MAX`.
  static const int maximum = 10;

  /// Turning the faith switch on selects these, in this order, while there is
  /// room under the cap.
  static const List<String> faithSeed = <String>['prayer', 'quran', 'duas'];

  /// Builds the offered groups.
  ///
  /// [reachable] answers `liveItems`' question — does some feature this user
  /// can see declare this interest? The faith group never asks it.
  static List<LumeInterestGroup> offer({
    required List<LumeInterestGroup> all,
    required bool Function(String interestId) reachable,
  }) {
    final List<LumeInterestGroup> out = <LumeInterestGroup>[];
    for (final LumeInterestGroup g in all) {
      if (g.faith) {
        out.add(g);
        continue;
      }
      final List<LumeInterest> live = g.interests
          .where((LumeInterest i) => reachable(i.id))
          .toList();
      if (live.isEmpty) continue;
      out.add(LumeInterestGroup(id: g.id, label: g.label, interests: live));
    }
    return out;
  }
}

/// The step's mutable state.
///
/// Owns the selection and the faith switch, and enforces the cap — so a screen
/// cannot get past ten by calling the wrong method, and a test can drive every
/// state without a widget.
class LumeInterestsController extends ChangeNotifier {
  LumeInterestsController({
    Set<String>? selected,
    bool? faithOpen,
    required this.faithInterests,
  }) : _selected = <String>{...?selected},
       _faithOpen =
           faithOpen ??
           (selected ?? const <String>{}).any(faithInterests.contains);

  /// The ids in the faith group, so turning the switch off knows what to drop.
  final Set<String> faithInterests;

  Set<String> _selected;
  Set<String> get selected => Set<String>.unmodifiable(_selected);

  bool _faithOpen;
  bool get faithOpen => _faithOpen;

  int get count => _selected.length;
  bool get atCap => count >= LumeInterests.maximum;

  bool isSelected(String id) => _selected.contains(id);

  /// Toggles one interest.
  ///
  /// Returns `false` when the tap was refused because the cap is reached —
  /// the screen says so rather than appearing to do nothing.
  bool toggle(String id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
      notifyListeners();
      return true;
    }
    if (atCap) return false;
    _selected.add(id);
    notifyListeners();
    return true;
  }

  /// The faith switch. On seeds three; off drops every faith interest.
  void setFaithOpen(bool open) {
    if (_faithOpen == open) return;
    _faithOpen = open;
    if (open) {
      for (final String id in LumeInterests.faithSeed) {
        if (_selected.length >= LumeInterests.maximum) break;
        _selected.add(id);
      }
    } else {
      _selected.removeAll(faithInterests);
    }
    notifyListeners();
  }

  void toggleFaith() => setFaithOpen(!_faithOpen);

  /// `.picker__clear` — empties the selection, and leaves the switch alone.
  void clear() {
    if (_selected.isEmpty) return;
    _selected = <String>{};
    notifyListeners();
  }

  /// Restores a selection — coming back to the step, or a fixture state.
  void restore(Set<String> selection, {bool? faithOpen}) {
    _selected = <String>{...selection};
    _faithOpen = faithOpen ?? selection.any(faithInterests.contains);
    notifyListeners();
  }

  LumeInterestsModel model(List<LumeInterestGroup> groups) =>
      LumeInterestsModel(
        groups: groups,
        selected: selected,
        faithOpen: _faithOpen,
      );
}
