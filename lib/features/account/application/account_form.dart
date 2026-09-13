/// The account section's form state.
///
/// One controller for every form in the section, because `ui/account-ui.js`
/// has one: the edit form, the address change, the phone, the password and the
/// deletion confirmation all read and write the same `form` object, and the
/// host resets it whenever a route opens. Keeping that shape means the
/// unsaved-changes guard has one thing to ask.
///
/// **No secret leaves this object.** A password is held while it is being
/// typed, handed to the repository, and cleared when the route closes; nothing
/// here is logged, announced, or written anywhere that survives the screen.
library;

import 'package:flutter/foundation.dart';

/// Which field a message belongs to, and what it says.
///
/// The message is a *key* rather than a sentence: the controller has no
/// localisations, and resolving one here would put English inside the state.
@immutable
class LumeFormIssue {
  const LumeFormIssue(this.key);

  /// An `AppLocalizations` getter name in spirit — the screen maps it.
  final String key;

  @override
  bool operator ==(Object other) => other is LumeFormIssue && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// What a form is doing, and what it holds.
class LumeAccountForm extends ChangeNotifier {
  Map<String, String> _initial = <String, String>{};
  Map<String, String> _values = <String, String>{};

  final Map<String, LumeFormIssue> _errors = <String, LumeFormIssue>{};
  final Set<String> _valid = <String>{};
  final Set<String> _touched = <String>{};
  final Set<String> _revealed = <String>{};

  bool _busy = false;

  /// A refusal that belongs to the form rather than to one field.
  LumeFormIssue? _message;

  /// Start a form, with the values it opens on.
  ///
  /// Everything else is cleared: an error from the last route is not an error
  /// on this one, and a revealed password must never stay revealed across a
  /// screen the reader did not ask to see it on.
  void reset(Map<String, String> initial) {
    _initial = Map<String, String>.unmodifiable(initial);
    _values = Map<String, String>.of(initial);
    _errors.clear();
    _valid.clear();
    _touched.clear();
    _revealed.clear();
    _message = null;
    _busy = false;
    notifyListeners();
  }

  String read(String name) => _values[name] ?? '';

  LumeFormIssue? errorOn(String name) => _errors[name];

  bool isValid(String name) => _valid.contains(name);

  bool isTouched(String name) => _touched.contains(name);

  bool isRevealed(String name) => _revealed.contains(name);

  LumeFormIssue? get message => _message;

  bool get busy => _busy;

  /// Whether anything has actually changed.
  ///
  /// Compared against the values the form opened on rather than tracked as a
  /// flag, so typing a character and deleting it again leaves the form clean —
  /// and the guard does not stop somebody who has changed nothing.
  bool get dirty {
    for (final MapEntry<String, String> e in _values.entries) {
      if ((_initial[e.key] ?? '') != e.value) return true;
    }
    return false;
  }

  /// A keystroke. Clears the field's own error — a message about what was
  /// there is not about what is being typed now.
  void edit(String name, String value) {
    if (_values[name] == value) return;
    _values[name] = value;
    _errors.remove(name);
    _valid.remove(name);
    _message = null;
    notifyListeners();
  }

  /// Blur. Only the checks a field can be judged on alone happen here.
  void leave(String name, {LumeFormIssue? issue, bool valid = false}) {
    _touched.add(name);
    if (issue != null) {
      _errors[name] = issue;
      _valid.remove(name);
    } else {
      _errors.remove(name);
      if (valid) {
        _valid.add(name);
      } else {
        _valid.remove(name);
      }
    }
    notifyListeners();
  }

  void toggleReveal(String name) {
    if (!_revealed.remove(name)) _revealed.add(name);
    notifyListeners();
  }

  /// A submission is in flight. Every control that would start another one
  /// reads this and goes inert.
  void beginSubmit() {
    _errors.clear();
    _message = null;
    _busy = true;
    notifyListeners();
  }

  void endSubmit() {
    _busy = false;
    notifyListeners();
  }

  /// A refusal came back. `field` puts it under a field; `null` puts it over
  /// the form.
  void refuse(LumeFormIssue issue, {String? field}) {
    _busy = false;
    if (field == null) {
      _message = issue;
    } else {
      _errors[field] = issue;
    }
    notifyListeners();
  }

  /// A write succeeded: what is on screen is now what is stored, so the form
  /// is clean without being emptied.
  void settle() {
    _initial = Map<String, String>.unmodifiable(_values);
    _errors.clear();
    _message = null;
    _busy = false;
    notifyListeners();
  }

  /// Throw away the edit. Used by the discard path, after the reader has said
  /// they are willing to lose it.
  void discard() {
    _values = Map<String, String>.of(_initial);
    _errors.clear();
    _message = null;
    notifyListeners();
  }
}
