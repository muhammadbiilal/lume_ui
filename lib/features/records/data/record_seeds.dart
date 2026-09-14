/// The demonstration records a collection opens with the first time —
/// `record-schemas.js` `seeds()`.
///
/// Kept with the record layer, where the reference keeps them, rather than in
/// the tools. A seeded string that begins with `@` is a translation key, so a
/// sample record speaks the reader's language and keeps speaking it after
/// they change it; what a reader types is stored as typed. Dates are ISO days
/// counted back from the day the collection is first read.
library;

/// `daysFromNow(n)` — an ISO calendar day.
String lumeIsoDay(DateTime now, int days) {
  final DateTime d = DateTime(now.year, now.month, now.day + days);
  String two(int v) => v < 10 ? '0$v' : '$v';
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// Every family's seeds, by collection. A collection this build has not
/// converted yet opens empty.
List<Map<String, Object?>>? lumeRecordSeeds(String collection, DateTime now) =>
    switch (collection) {
      'expenses' => <Map<String, Object?>>[
        <String, Object?>{
          'title': '@groceries',
          'amount': 34,
          'cat': 'groceries',
          'date': lumeIsoDay(now, 0),
          'method': 'card',
          'notes': '@groceriesNote',
        },
        <String, Object?>{
          'title': '@taxi',
          'amount': 9,
          'cat': 'transport',
          'date': lumeIsoDay(now, -1),
          'method': 'cash',
        },
        <String, Object?>{
          'title': '@internet',
          'amount': 28,
          'cat': 'bills',
          'date': lumeIsoDay(now, -3),
          'method': 'transfer',
        },
        <String, Object?>{
          'title': '@coffee',
          'amount': 7,
          'cat': 'eating',
          'date': lumeIsoDay(now, -4),
          'method': 'cash',
        },
        <String, Object?>{
          'title': '@pharmacy',
          'amount': 17,
          'cat': 'health',
          'date': lumeIsoDay(now, -6),
          'method': 'card',
        },
      ],
      'documents' => <Map<String, Object?>>[
        <String, Object?>{
          'name': '@passport',
          'cat': 'identity',
          'num': 'AB••••42',
          'expires': lumeIsoDay(now, 918),
          'holder': '@you',
        },
        <String, Object?>{
          'name': '@nid',
          'cat': 'identity',
          'num': '61101-•••••••-3',
          'expires': lumeIsoDay(now, 440),
          'holder': '@you',
        },
        <String, Object?>{
          'name': '@licence',
          'cat': 'vehicle',
          'num': 'DL-••••-118',
          'expires': lumeIsoDay(now, 25),
          'holder': '@you',
        },
        <String, Object?>{
          'name': '@insurance',
          'cat': 'insurance',
          'num': 'POL-••••-7781',
          'expires': lumeIsoDay(now, 115),
          'holder': '@family',
        },
      ],
      _ => null,
    };
