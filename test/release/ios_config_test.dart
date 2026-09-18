/// iOS permission text, as configuration (C80, C81, F6B closure).
///
/// This reads files; it builds nothing and runs nothing on iOS. It holds the
/// configuration to what was approved: the camera and add-only Photos, and
/// nothing broader; each explained in English, Urdu and Arabic through
/// `InfoPlist.strings` the Xcode project actually bundles.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A strict reader for the `.strings` format: comments, and
/// `"key" = "value";` entries with `\"`, `\\` and `\n` escapes. Anything else
/// is a syntax error, reported with its line.
Map<String, String> parseStrings(String text) {
  final Map<String, String> out = <String, String>{};
  int i = 0;
  int line = 1;
  Never fail(String what) =>
      throw FormatException('line $line: $what', text, i);

  void skip() {
    while (i < text.length) {
      final String c = text[i];
      if (c == '\n') {
        line++;
        i++;
      } else if (c == ' ' || c == '\t' || c == '\r' || c == '\uFEFF') {
        i++;
      } else if (text.startsWith('/*', i)) {
        final int end = text.indexOf('*/', i + 2);
        if (end < 0) fail('an unclosed comment');
        line += '\n'.allMatches(text.substring(i, end)).length;
        i = end + 2;
      } else if (text.startsWith('//', i)) {
        while (i < text.length && text[i] != '\n') {
          i++;
        }
      } else {
        return;
      }
    }
  }

  String quoted() {
    if (i >= text.length || text[i] != '"') fail('expected a quoted string');
    i++;
    final StringBuffer b = StringBuffer();
    while (true) {
      if (i >= text.length) fail('an unclosed string');
      final String c = text[i];
      if (c == '"') {
        i++;
        return b.toString();
      }
      if (c == '\n') fail('a line break inside a string');
      if (c == r'\') {
        i++;
        if (i >= text.length) fail('a trailing escape');
        final String e = text[i];
        b.write(switch (e) {
          '"' => '"',
          r'\' => r'\',
          'n' => '\n',
          _ => fail('an unknown escape \\$e'),
        });
        i++;
        continue;
      }
      b.write(c);
      i++;
    }
  }

  skip();
  while (i < text.length) {
    final String key = quoted();
    skip();
    if (i >= text.length || text[i] != '=') fail('expected "=" after "$key"');
    i++;
    skip();
    final String value = quoted();
    skip();
    if (i >= text.length || text[i] != ';') fail('expected ";" after "$key"');
    i++;
    if (out.containsKey(key)) fail('"$key" twice');
    out[key] = value;
    skip();
  }
  return out;
}

/// `<key>…</key><string>…</string>` pairs, and the one array this checks.
Map<String, String> plistStrings(String xml) => <String, String>{
  for (final RegExpMatch m in RegExp(
    r'<key>([^<]+)</key>\s*<string>([^<]*)</string>',
  ).allMatches(xml))
    m.group(1)!: m.group(2)!,
};

void main() {
  const String root = 'ios/Runner';
  const Set<String> usage = <String>{
    'NSCameraUsageDescription',
    'NSPhotoLibraryAddUsageDescription',
  };
  final String plist = File('$root/Info.plist').readAsStringSync();
  final Map<String, String> info = plistStrings(plist);

  test('Info.plist asks for the camera and add-only Photos, nothing more', () {
    expect(
      info.keys.where((String k) => k.endsWith('UsageDescription')).toSet(),
      usage,
    );
    expect(plist, isNot(contains('NSPhotoLibraryUsageDescription')));
    expect(plist, isNot(contains('NSMicrophoneUsageDescription')));
    expect(plist, isNot(contains('NSLocation')));
    expect(
      RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>\s*'
        r'<string>en</string>\s*<string>ur</string>\s*<string>ar</string>\s*'
        r'</array>',
      ).hasMatch(plist),
      isTrue,
      reason: 'the bundle declares the languages it has strings for',
    );
  });

  final Map<String, Map<String, String>> strings =
      <String, Map<String, String>>{
        for (final String l in <String>['en', 'ur', 'ar'])
          l: parseStrings(
            utf8.decode(
              File('$root/$l.lproj/InfoPlist.strings').readAsBytesSync(),
            ),
          ),
      };

  test('the .strings reader refuses what is not the format', () {
    for (final String bad in <String>[
      '"a" = "b"',
      '"a" "b";',
      '"a" = "b;',
      '/* open',
      '"a" = "\\q";',
      '"a" = "b"; "a" = "c";',
      'a = "b";',
    ]) {
      expect(() => parseStrings(bad), throwsFormatException, reason: bad);
    }
    expect(parseStrings('// x\n"a" = "b \\"c\\"";'), <String, String>{
      'a': 'b "c"',
    });
  });

  for (final String l in <String>['en', 'ur', 'ar']) {
    test('$l.lproj/InfoPlist.strings is valid, complete and says only what '
        'is true', () {
      final Map<String, String> s = strings[l]!;
      expect(s.keys.toSet(), usage);
      for (final MapEntry<String, String> e in s.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
        expect(e.value, isNot(contains(r'$(')), reason: 'a placeholder');
        expect(e.value, isNot(contains('%@')), reason: 'a format argument');
        expect(e.value.toUpperCase(), isNot(contains('TODO')));
        expect(e.value, contains('Lume'), reason: 'it names the app');
      }
      if (l == 'en') {
        // The English is Info.plist's own, word for word.
        for (final String k in usage) {
          expect(s[k], info[k], reason: k);
        }
        final String add = s['NSPhotoLibraryAddUsageDescription']!;
        expect(add, contains('cannot see your other photos'));
        for (final String broad in <String>[
          'all your photos',
          'your photo library',
          'access your photos',
          'read your photos',
        ]) {
          expect(add.toLowerCase(), isNot(contains(broad)));
        }
        expect(s['NSCameraUsageDescription'], contains('only while you scan'));
      } else {
        // Translated, not English left in place.
        for (final String k in usage) {
          expect(s[k], isNot(strings['en']![k]), reason: '$k in $l');
          expect(
            RegExp('[\u0600-\u06FF]').hasMatch(s[k]!),
            isTrue,
            reason: '$k in $l is in its script',
          );
        }
      }
    });
  }

  test('the Xcode project bundles all three', () {
    final String pbx = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final RegExpMatch? group = RegExp(
      r'(\w{24}) /\* InfoPlist\.strings \*/ = \{\s*isa = PBXVariantGroup;'
      r'\s*children = \(([^)]*)\);\s*name = InfoPlist\.strings;',
    ).firstMatch(pbx);
    expect(group, isNotNull, reason: 'no InfoPlist.strings variant group');
    for (final String l in <String>['en', 'ur', 'ar']) {
      expect(group!.group(2), contains('/* $l */'));
      expect(
        pbx,
        contains(
          'name = $l; path = $l.lproj/InfoPlist.strings; '
          'sourceTree = "<group>";',
        ),
      );
    }
    final String id = group!.group(1)!;
    final RegExpMatch? build = RegExp(
      '(\\w{24}) /\\* InfoPlist\\.strings in Resources \\*/ = '
      '\\{isa = PBXBuildFile; fileRef = $id ',
    ).firstMatch(pbx);
    expect(build, isNotNull);
    final String resources = RegExp(
      r'97C146EC1CF9000F007C117D /\* Resources \*/ = \{.*?files = \(([^)]*)\);',
      dotAll: true,
    ).firstMatch(pbx)!.group(1)!;
    expect(resources, contains(build!.group(1)));
    final String regions = RegExp(
      r'knownRegions = \(([^)]*)\);',
    ).firstMatch(pbx)!.group(1)!;
    for (final String l in <String>['en', 'ur', 'ar']) {
      expect(RegExp('\\b$l,').hasMatch(regions), isTrue, reason: l);
    }
  });
}
