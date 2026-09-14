/// Handing a phone number to the phone app — never placing the call.
///
/// The reference writes `<a href="tel:1122">`: the operating system opens its
/// dialer with the number filled in and the reader presses call. Lume does the
/// same through this contract (D6):
///
/// * [LumeDialNumber.parse] accepts exactly what is shown — digits, spaces,
///   hyphens and one leading `+` — and refuses anything else, so the number
///   dialled is the number read, and nothing from a data file can smuggle a
///   scheme or a USSD code (`*`, `#`) into the dialer;
/// * a [LumeDialer] reports what happened as a [LumeDialOutcome], and the
///   screen says so honestly when the dialer could not be opened;
/// * [LumeRecordingDialer] records instead of calling the platform — tests and
///   the fixture build use it, and it never reaches the operating system.
///
/// The platform adapter lives in `lume_dialer_platform.dart`, the only file
/// that knows which plugin opens the dialer.
library;

import 'package:flutter/foundation.dart';

/// A number the dialer may be given: what the reader sees, and the `tel:`
/// form of it.
@immutable
class LumeDialNumber {
  const LumeDialNumber._(this.display, this.dialable);

  /// As written on screen — `0800 111 999`.
  final String display;

  /// Digits and an optional leading `+` — `0800111999`.
  final String dialable;

  /// `tel:0800111999`.
  Uri get uri => Uri(scheme: 'tel', path: dialable);

  static final RegExp _shown = RegExp(r'^\+?[0-9][0-9 \-]*$');

  /// `null` for anything that is not plainly a phone number.
  static LumeDialNumber? parse(String shown) {
    final String display = shown.trim();
    if (!_shown.hasMatch(display)) return null;
    final String dialable = display.replaceAll(RegExp(r'[ \-]'), '');
    final int digits = dialable.replaceFirst('+', '').length;
    if (digits < 2 || digits > 15) return null;
    return LumeDialNumber._(display, dialable);
  }

  @override
  bool operator ==(Object other) =>
      other is LumeDialNumber && other.dialable == dialable;

  @override
  int get hashCode => dialable.hashCode;

  @override
  String toString() => 'LumeDialNumber($display)';
}

/// What became of one request to open the dialer.
enum LumeDialOutcome {
  /// The dialer was opened with the number. Whether the reader then called is
  /// theirs, and the platform does not say.
  opened,

  /// Nothing on this device can dial — a tablet without telephony, a desktop.
  unavailable,

  /// The number was not a phone number; the dialer was not asked.
  malformed,

  /// The platform reports the reader dismissed the hand-off (iOS asks first).
  cancelled,

  /// The platform was asked and refused, or threw.
  failed,
}

/// Opens the phone app with a number filled in. Never places a call.
abstract interface class LumeDialer {
  Future<LumeDialOutcome> dial(String shown);
}

/// Records every request and answers with [outcome]. Never touches the
/// platform.
class LumeRecordingDialer implements LumeDialer {
  LumeRecordingDialer({this.outcome = LumeDialOutcome.opened});

  /// What the next request answers, when the number is well formed.
  LumeDialOutcome outcome;

  /// Every well-formed number the dialer was asked to open, in order.
  final List<LumeDialNumber> dialled = <LumeDialNumber>[];

  /// Every request, as shown, including the refused ones.
  final List<String> requested = <String>[];

  @override
  Future<LumeDialOutcome> dial(String shown) async {
    requested.add(shown);
    final LumeDialNumber? number = LumeDialNumber.parse(shown);
    if (number == null) return LumeDialOutcome.malformed;
    dialled.add(number);
    return outcome;
  }
}
