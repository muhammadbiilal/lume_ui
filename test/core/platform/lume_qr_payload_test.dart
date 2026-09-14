/// A decoded QR code is untrusted text: what it is, where it would go, and
/// that nothing is opened that Lume has not checked (C80).
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_link_opener.dart';
import 'package:lume/core/platform/lume_link_opener_platform.dart';
import 'package:lume/core/platform/lume_qr_payload.dart';

final String rlo = String.fromCharCode(0x202E);
final String replacement = String.fromCharCode(0xFFFD);

void main() {
  group('web addresses', () {
    test('https with a plain host opens, and says the host', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'https://lume.app/tools?x=1',
      );
      expect(p.kind, LumeQrKind.web);
      expect(p.destination, 'lume.app');
      expect(p.target, Uri.parse('https://lume.app/tools?x=1'));
      expect(p.insecure, isFalse);
      expect(p.opens, isTrue);
    });

    test('http opens and is marked not secure', () {
      final LumeQrPayload p = LumeQrPayload.classify('http://example.com');
      expect(p.kind, LumeQrKind.web);
      expect(p.insecure, isTrue);
    });

    test('the scheme and host are judged whatever their case', () {
      final LumeQrPayload p = LumeQrPayload.classify('HTTPS://Example.COM/A');
      expect(p.kind, LumeQrKind.web);
      expect(p.destination, 'example.com');
    });

    for (final (String why, String value) in <(String, String)>[
      ('credentials before the host', 'https://bank.example@evil.test/login'),
      ('a host that imitates another', 'https://ex${'а'}mple.com'),
      ('no host', 'https:/example.com'),
      ('whitespace', 'https://example.com/a b'),
      ('a hidden direction override', 'https://exa${rlo}mple.com'),
    ]) {
      test('refused: $why', () {
        final LumeQrPayload p = LumeQrPayload.classify(value);
        expect(p.kind, LumeQrKind.refused);
        expect(p.target, isNull);
      });
    }
  });

  group('schemes Lume never opens', () {
    for (final String value in <String>[
      'javascript:alert(1)',
      'JavaScript:alert(1)',
      'data:text/html,<b>hi</b>',
      'file:///etc/hosts',
      'intent://scan/#Intent;scheme=zxing;end',
      'content://contacts/people/1',
      'market://details?id=x',
      'itms-services://?action=download-manifest',
      'lume://tools/account/delete',
      'otherapp://pay?to=1',
    ]) {
      test(value, () {
        final LumeQrPayload p = LumeQrPayload.classify(value);
        expect(p.kind, LumeQrKind.refused);
        expect(p.opens, isFalse);
        expect(p.shownText, value);
      });
    }
  });

  group('phone, message and email', () {
    test('tel: opens the dialer to exactly that number', () {
      final LumeQrPayload p = LumeQrPayload.classify('tel:+923001234567');
      expect(p.kind, LumeQrKind.phone);
      expect(p.destination, '+923001234567');
      expect(p.target, Uri(scheme: 'tel', path: '+923001234567'));
    });

    test('a USSD code is refused', () {
      expect(LumeQrPayload.classify('tel:*123%23').kind, LumeQrKind.refused);
      expect(LumeQrPayload.classify('tel:*#06#').kind, LumeQrKind.refused);
    });

    test('sms: goes to the number, without the prefilled text', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'sms:+447700900123?body=Reply%20WIN',
      );
      expect(p.kind, LumeQrKind.message);
      expect(p.target, Uri(scheme: 'sms', path: '+447700900123'));
      expect(p.target!.hasQuery, isFalse);
    });

    test('SMSTO: with a message is the same', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'SMSTO:+447700900123:Hello there',
      );
      expect(p.kind, LumeQrKind.message);
      expect(p.destination, '+447700900123');
      expect(p.target, Uri(scheme: 'sms', path: '+447700900123'));
    });

    test('mailto: goes to the address, without subject or body', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'mailto:hello@lume.app?subject=Hi&body=There',
      );
      expect(p.kind, LumeQrKind.email);
      expect(p.destination, 'hello@lume.app');
      expect(p.target, Uri(scheme: 'mailto', path: 'hello@lume.app'));
    });

    test('MATMSG: reads its TO', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'MATMSG:TO:hello@lume.app;SUB:Hi;BODY:There;;',
      );
      expect(p.kind, LumeQrKind.email);
      expect(p.target, Uri(scheme: 'mailto', path: 'hello@lume.app'));
    });

    test('an address that is not one is refused', () {
      expect(
        LumeQrPayload.classify('mailto:not-an-address').kind,
        LumeQrKind.refused,
      );
      expect(
        LumeQrPayload.classify('mailto:a@b.com,c@d.com').kind,
        LumeQrKind.refused,
      );
    });
  });

  group('what Lume shows and never does', () {
    test('Wi-Fi: the network, never the password', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'WIFI:T:WPA;S:Home-WiFi;P:hunter22;;',
      );
      expect(p.kind, LumeQrKind.wifi);
      expect(p.destination, 'Home-WiFi');
      expect(p.opens, isFalse);
      expect(p.shownText, isNot(contains('hunter22')));
      expect(p.raw, contains('hunter22'));
    });

    test('Wi-Fi: escapes are honoured, and the password is still hidden', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        r'WIFI:S:My\;Net;T:WPA;P:pa\;ss\:word;;',
      );
      expect(p.destination, 'My;Net');
      expect(p.shownText, isNot(contains('pa')));
      expect(p.shownText, isNot(contains('word')));
    });

    test('Wi-Fi: a password written first is hidden too', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'WIFI:P:topsecret;S:Cafe;;',
      );
      expect(p.destination, 'Cafe');
      expect(p.shownText, isNot(contains('topsecret')));
    });

    test('a vCard names the contact and adds nothing', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'BEGIN:VCARD\nVERSION:3.0\nFN:Ada Lovelace\nTEL:+441234\nEND:VCARD',
      );
      expect(p.kind, LumeQrKind.contact);
      expect(p.destination, 'Ada Lovelace');
      expect(p.opens, isFalse);
    });

    test('a MeCard names the contact', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'MECARD:N:Lovelace,Ada;TEL:+441234;;',
      );
      expect(p.kind, LumeQrKind.contact);
      expect(p.destination, 'Ada Lovelace');
    });

    test('geo: shows the coordinates and opens no map', () {
      final LumeQrPayload p = LumeQrPayload.classify('geo:33.6844,73.0479');
      expect(p.kind, LumeQrKind.location);
      expect(p.destination, '33.6844, 73.0479');
      expect(p.opens, isFalse);
      expect(LumeQrPayload.classify('geo:95,10').kind, LumeQrKind.refused);
    });

    test('a sentence with a colon is text, not a scheme', () {
      expect(
        LumeQrPayload.classify('Note: bring the tickets').kind,
        LumeQrKind.text,
      );
      expect(LumeQrPayload.classify('Home-WiFi').kind, LumeQrKind.text);
      expect(LumeQrPayload.classify('www.lume.app').kind, LumeQrKind.text);
    });

    test('hidden direction and control characters are shown, not obeyed', () {
      final LumeQrPayload p = LumeQrPayload.classify('abc${rlo}def');
      expect(p.kind, LumeQrKind.text);
      expect(p.raw, 'abc${rlo}def');
      expect(p.shownText, 'abc${replacement}def');
    });

    test('longer than a QR code holds is only text', () {
      final LumeQrPayload p = LumeQrPayload.classify(
        'https://lume.app/${'a' * LumeQrPayload.maxLength}',
      );
      expect(p.kind, LumeQrKind.text);
      expect(p.opens, isFalse);
    });

    test('Arabic and Urdu text stays exactly as written', () {
      const String urdu = 'السلام علیکم — Lume';
      final LumeQrPayload p = LumeQrPayload.classify(urdu);
      expect(p.kind, LumeQrKind.text);
      expect(p.shownText, urdu);
    });
  });

  group('the door checks again', () {
    test('the allowlist', () {
      expect(LumeLinkOpener.allows(Uri.parse('https://lume.app')), isTrue);
      expect(LumeLinkOpener.allows(Uri.parse('http://lume.app')), isTrue);
      expect(LumeLinkOpener.allows(Uri.parse('mailto:a@lume.app')), isTrue);
      expect(LumeLinkOpener.allows(Uri.parse('sms:+447700900123')), isTrue);
      for (final String refused in <String>[
        'javascript:alert(1)',
        'https://user@lume.app',
        'mailto:a@lume.app?body=x',
        'sms:+447700900123?body=x',
        'tel:+447700900123',
        'intent://x',
        'lume://tools',
        'file:///etc/hosts',
      ]) {
        expect(
          LumeLinkOpener.allows(Uri.parse(refused)),
          isFalse,
          reason: refused,
        );
      }
    });

    test('the recording opener refuses what the allowlist refuses', () async {
      final LumeRecordingLinkOpener opener = LumeRecordingLinkOpener();
      expect(
        await opener.open(Uri.parse('javascript:alert(1)')),
        LumeOpenOutcome.refused,
      );
      expect(
        await opener.open(Uri.parse('https://lume.app')),
        LumeOpenOutcome.opened,
      );
      expect(opener.opened, <Uri>[Uri.parse('https://lume.app')]);
      expect(opener.requested, hasLength(2));
    });

    test('the platform opener never asks the platform for a refused '
        'address, and says what the platform said', () async {
      final List<Uri> launched = <Uri>[];
      Future<bool> launch(Uri u) async {
        launched.add(u);
        return u.host != 'nothing.test';
      }

      final LumePlatformLinkOpener opener = LumePlatformLinkOpener(
        launch: launch,
      );
      expect(
        await opener.open(Uri.parse('intent://x')),
        LumeOpenOutcome.refused,
      );
      expect(launched, isEmpty);
      expect(
        await opener.open(Uri.parse('https://lume.app')),
        LumeOpenOutcome.opened,
      );
      expect(
        await opener.open(Uri.parse('https://nothing.test')),
        LumeOpenOutcome.unavailable,
      );
      expect(
        await LumePlatformLinkOpener(
          launch: (Uri u) async => throw PlatformException(code: 'x'),
        ).open(Uri.parse('https://lume.app')),
        LumeOpenOutcome.failed,
      );
      expect(
        await LumePlatformLinkOpener(
          launch: (Uri u) async => throw MissingPluginException(),
        ).open(Uri.parse('https://lume.app')),
        LumeOpenOutcome.unavailable,
      );
    });
  });
}
