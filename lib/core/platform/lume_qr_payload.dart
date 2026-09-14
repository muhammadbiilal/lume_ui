/// What a decoded QR code is, and where — if anywhere — it may lead.
///
/// A code is untrusted text printed by anyone. F6B's rule (C80): a scan never
/// opens, dials, messages, joins, adds or copies anything by itself. Lume
/// shows what was read, says what kind of thing it is and where it would go,
/// and offers to go there only on a second, explicit press — and only for the
/// few kinds it can check:
///
/// | kind | recognised from | Lume may open |
/// |---|---|---|
/// | [LumeQrKind.web] | `https://` or `http://` with a plain host, no user info | the site, in the reader's browser; `http` is marked not secure |
/// | [LumeQrKind.phone] | `tel:` a number [LumeDialNumber] accepts | the dialer, number filled in — never a USSD code |
/// | [LumeQrKind.message] | `sms:` / `SMSTO:` a plain number | Messages, to that number, **without** the code's prefilled body |
/// | [LumeQrKind.email] | `mailto:` / `MATMSG:` one plain address | a new email to that address, **without** subject or body |
/// | [LumeQrKind.wifi] | `WIFI:` | nothing — Lume does not join networks; the password is never shown |
/// | [LumeQrKind.contact] | `BEGIN:VCARD` / `MECARD:` | nothing — Lume does not add contacts |
/// | [LumeQrKind.location] | `geo:` | nothing — no map tiles in this build |
/// | [LumeQrKind.refused] | any other scheme (`javascript:`, `intent:`, `file:`, an app's own), or an allowed one that fails its check | nothing |
/// | [LumeQrKind.text] | anything else | nothing |
///
/// Everything is shown as plain text, with direction-override and control
/// characters made visible rather than obeyed, so a code cannot disguise the
/// destination it is shown under.
library;

import 'package:flutter/foundation.dart';

import 'lume_dialer.dart';

enum LumeQrKind {
  web,
  phone,
  message,
  email,
  wifi,
  contact,
  location,
  text,
  refused,
}

@immutable
class LumeQrPayload {
  const LumeQrPayload._({
    required this.kind,
    required this.raw,
    required this.shownText,
    this.destination,
    this.target,
    this.insecure = false,
  });

  /// Longer than a QR code can hold. Such text did not come from one, and is
  /// only ever treated as text.
  static const int maxLength = 7089;

  final LumeQrKind kind;

  /// Exactly what was decoded.
  final String raw;

  /// What the reader is shown and what Copy copies: [raw] with invisible
  /// controls made visible, and a Wi-Fi password hidden.
  final String shownText;

  /// Where it would go, as the reader should judge it: a host, a number, an
  /// address, a network name, a contact's name, coordinates.
  final String? destination;

  /// What a second press opens. `null` for every kind Lume does not open.
  final Uri? target;

  /// A web address that is not encrypted.
  final bool insecure;

  bool get opens => target != null;

  /// Bidirectional overrides and isolates, and C0/C1 controls other than tab
  /// and newline.
  static final RegExp _hidden = RegExp(
    '[${_span(0x00, 0x08)}${_span(0x0B, 0x0C)}${_span(0x0E, 0x1F)}'
    '${_span(0x7F, 0x9F)}${_span(0x200E, 0x200F)}${_span(0x202A, 0x202E)}'
    '${_span(0x2066, 0x2069)}]',
  );

  static String _span(int from, int to) =>
      '${String.fromCharCode(from)}-${String.fromCharCode(to)}';

  static final RegExp _scheme = RegExp(r'^([A-Za-z][A-Za-z0-9+.\-]*):');
  static final RegExp _host = RegExp(
    r'^[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)*$',
  );
  static final RegExp _address = RegExp(
    r'^[A-Za-z0-9.!#$%&*+\-/=^_{|}~]+@[A-Za-z0-9](?:[A-Za-z0-9\-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9\-]*[A-Za-z0-9])?)+$',
  );
  static final RegExp _geo = RegExp(
    r'^geo:(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)(?:[,;?].*)?$',
    caseSensitive: false,
  );

  /// Schemes that are never a destination a code should lead to, however they
  /// are written.
  static const Set<String> _alwaysRefused = <String>{
    'javascript',
    'vbscript',
    'data',
    'file',
    'content',
    'intent',
    'blob',
    'about',
    'chrome',
    'market',
    'itms',
    'itms-apps',
    'itms-services',
    'lume',
    'ftp',
    'ws',
    'wss',
  };

  static String _visible(String s) =>
      s.replaceAll(_hidden, String.fromCharCode(0xFFFD));

  static LumeQrPayload _plain(String raw, LumeQrKind kind) =>
      LumeQrPayload._(kind: kind, raw: raw, shownText: _visible(raw));

  static LumeQrPayload classify(String raw) {
    final String t = raw.trim();
    if (t.isEmpty || raw.length > maxLength) {
      return _plain(raw, LumeQrKind.text);
    }
    final String upper = t.toUpperCase();

    if (upper.startsWith('WIFI:')) return _wifi(raw, t);
    if (upper.startsWith('BEGIN:VCARD')) return _vcard(raw, t);
    if (upper.startsWith('MECARD:')) return _mecard(raw, t);
    if (upper.startsWith('MATMSG:')) return _matmsg(raw, t);
    if (upper.startsWith('SMSTO:')) return _sms(raw, t.substring(6));

    final RegExpMatch? m = _scheme.firstMatch(t);
    if (m == null) return _plain(raw, LumeQrKind.text);
    final String scheme = m.group(1)!.toLowerCase();
    final String rest = t.substring(m.end);

    // A value with a hidden character is not a destination anyone can judge.
    final bool hidden = _hidden.hasMatch(t);

    switch (scheme) {
      case 'https':
      case 'http':
        return hidden ? _plain(raw, LumeQrKind.refused) : _web(raw, t, scheme);
      case 'tel':
        return hidden ? _plain(raw, LumeQrKind.refused) : _tel(raw, rest);
      case 'sms':
        return hidden ? _plain(raw, LumeQrKind.refused) : _sms(raw, rest);
      case 'mailto':
        return hidden
            ? _plain(raw, LumeQrKind.refused)
            : _email(raw, _decoded(rest.split('?').first));
      case 'geo':
        return _location(raw, t);
    }
    if (_alwaysRefused.contains(scheme) || rest.startsWith('//')) {
      return _plain(raw, LumeQrKind.refused);
    }
    // "Note: bring the tickets" — a colon in a sentence is not a scheme.
    return _plain(raw, LumeQrKind.text);
  }

  static String _decoded(String s) {
    try {
      return Uri.decodeComponent(s);
    } on ArgumentError {
      return s;
    } on FormatException {
      return s;
    }
  }

  static LumeQrPayload _web(String raw, String t, String scheme) {
    if (RegExp(r'\s').hasMatch(t)) return _plain(raw, LumeQrKind.refused);
    final Uri? uri = Uri.tryParse(t);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !t.substring(scheme.length + 1).startsWith('//') ||
        !_host.hasMatch(uri.host)) {
      // No host, credentials before the host (`https://bank.com@elsewhere`),
      // or a host that is not plain ASCII and could imitate another.
      return _plain(raw, LumeQrKind.refused);
    }
    return LumeQrPayload._(
      kind: LumeQrKind.web,
      raw: raw,
      shownText: raw,
      destination: uri.host,
      target: uri,
      insecure: scheme == 'http',
    );
  }

  static LumeQrPayload _tel(String raw, String rest) {
    final LumeDialNumber? n = LumeDialNumber.parse(_decoded(rest));
    if (n == null) return _plain(raw, LumeQrKind.refused);
    return LumeQrPayload._(
      kind: LumeQrKind.phone,
      raw: raw,
      shownText: raw,
      destination: n.display,
      target: n.uri,
    );
  }

  /// `sms:+44…?body=…` and `SMSTO:+44…:body` — the number only.
  static LumeQrPayload _sms(String raw, String rest) {
    final String number = _decoded(rest.split(RegExp('[?:;]')).first);
    final LumeDialNumber? n = LumeDialNumber.parse(number);
    if (n == null || _hidden.hasMatch(raw)) {
      return _plain(raw, LumeQrKind.refused);
    }
    return LumeQrPayload._(
      kind: LumeQrKind.message,
      raw: raw,
      shownText: _visible(raw),
      destination: n.display,
      target: Uri(scheme: 'sms', path: n.dialable),
    );
  }

  static LumeQrPayload _email(String raw, String address) {
    final String a = address.trim();
    if (!_address.hasMatch(a) || _hidden.hasMatch(raw)) {
      return _plain(raw, LumeQrKind.refused);
    }
    return LumeQrPayload._(
      kind: LumeQrKind.email,
      raw: raw,
      shownText: _visible(raw),
      destination: a,
      target: Uri(scheme: 'mailto', path: a),
    );
  }

  static LumeQrPayload _location(String raw, String t) {
    final RegExpMatch? g = _geo.firstMatch(t);
    if (g == null) return _plain(raw, LumeQrKind.refused);
    final double lat = double.parse(g.group(1)!);
    final double lng = double.parse(g.group(2)!);
    if (lat.abs() > 90 || lng.abs() > 180) {
      return _plain(raw, LumeQrKind.refused);
    }
    return LumeQrPayload._(
      kind: LumeQrKind.location,
      raw: raw,
      shownText: _visible(raw),
      destination: '${g.group(1)}, ${g.group(2)}',
    );
  }

  /// `WIFI:T:WPA;S:name;P:secret;;` — `\` escapes `;`, `,`, `:` and itself.
  static Map<String, String> _fields(String body) {
    final Map<String, String> out = <String, String>{};
    final StringBuffer part = StringBuffer();
    void close() {
      final String p = part.toString();
      part.clear();
      final int colon = p.indexOf(':');
      if (colon <= 0) return;
      out.putIfAbsent(
        p.substring(0, colon).toUpperCase(),
        () => p.substring(colon + 1),
      );
    }

    for (int i = 0; i < body.length; i++) {
      final String c = body[i];
      if (c == r'\' && i + 1 < body.length) {
        part.write(body[++i]);
      } else if (c == ';') {
        close();
      } else {
        part.write(c);
      }
    }
    close();
    return out;
  }

  static LumeQrPayload _wifi(String raw, String t) {
    final Map<String, String> f = _fields(t.substring(5));
    final String? ssid = f['S'];
    if (ssid == null || ssid.isEmpty) return _plain(raw, LumeQrKind.text);
    // The password is hidden wherever it is written, escaped or not.
    final String shown = _visible(
      raw.replaceAllMapped(
        RegExp(r'([;:]P:)((?:\\.|[^;\\])*)', caseSensitive: false),
        (Match m) => '${m.group(1)}••••••••',
      ),
    );
    return LumeQrPayload._(
      kind: LumeQrKind.wifi,
      raw: raw,
      shownText: shown,
      destination: _visible(ssid),
    );
  }

  static LumeQrPayload _vcard(String raw, String t) {
    String? name;
    for (final String line in t.split(RegExp(r'\r?\n'))) {
      final String u = line.toUpperCase();
      if (u.startsWith('FN:') || u.startsWith('FN;')) {
        name = line.substring(line.indexOf(':') + 1).trim();
        break;
      }
    }
    return LumeQrPayload._(
      kind: LumeQrKind.contact,
      raw: raw,
      shownText: _visible(raw),
      destination: name == null || name.isEmpty ? null : _visible(name),
    );
  }

  static LumeQrPayload _mecard(String raw, String t) {
    final String? n = _fields(t.substring(7))['N'];
    final String? name = n?.split(',').reversed.join(' ').trim();
    return LumeQrPayload._(
      kind: LumeQrKind.contact,
      raw: raw,
      shownText: _visible(raw),
      destination: name == null || name.isEmpty ? null : _visible(name),
    );
  }

  static LumeQrPayload _matmsg(String raw, String t) {
    final String? to = _fields(t.substring(7))['TO'];
    return to == null ? _plain(raw, LumeQrKind.refused) : _email(raw, to);
  }

  @override
  bool operator ==(Object other) =>
      other is LumeQrPayload &&
      other.kind == kind &&
      other.raw == raw &&
      other.target == target;

  @override
  int get hashCode => Object.hash(kind, raw, target);

  @override
  String toString() => 'LumeQrPayload(${kind.name}, $destination, $target)';
}
