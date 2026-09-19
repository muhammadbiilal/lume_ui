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
List<Map<String, Object?>>? lumeRecordSeeds(
  String collection,
  DateTime now,
) => switch (collection) {
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
  // Notes: two pinned, in the reference's order.
  'notes' => <Map<String, Object?>>[
    <String, Object?>{
      'title': '@notesSeedN1',
      'body': '@notesSeedN1x',
      'folder': 'work',
      'pinned': true,
    },
    <String, Object?>{
      'title': '@notesSeedN2',
      'body': '@notesSeedN2x',
      'folder': 'personal',
      'pinned': true,
    },
    <String, Object?>{
      'title': '@notesSeedN3',
      'body': '@notesSeedN3x',
      'folder': 'ideas',
    },
    <String, Object?>{
      'title': '@notesSeedN4',
      'body': '@notesSeedN4x',
      'folder': 'work',
    },
  ],
  // To-dos: two due today (one high), one tomorrow, one done.
  'todos' => <Map<String, Object?>>[
    <String, Object?>{
      'label': '@todosSeedItem1',
      'list': 'work',
      'due': lumeIsoDay(now, 0),
      'priority': 'high',
    },
    <String, Object?>{
      'label': '@todosSeedItem2',
      'list': 'home',
      'due': lumeIsoDay(now, 0),
    },
    <String, Object?>{
      'label': '@todosSeedItem3',
      'list': 'work',
      'due': lumeIsoDay(now, 1),
    },
    <String, Object?>{
      'label': '@todosSeedItem4',
      'list': 'personal',
      'done': true,
    },
  ],
  // Events: lunch in two days, the dentist in five — times on the reader's clock.
  'events' => <Map<String, Object?>>[
    <String, Object?>{
      'title': '@eventsSeedE2',
      'date': lumeIsoDay(now, 2),
      'at': '19:00',
      'where': '@eventsSeedW2',
      'people': 12,
    },
    <String, Object?>{
      'title': '@eventsSeedE3',
      'date': lumeIsoDay(now, 5),
      'at': '11:00',
      'where': '@eventsSeedW3',
      'people': 3,
    },
  ],
  // Shopping: five items, the yoghurt already in the basket.
  'shopping' => <Map<String, Object?>>[
    <String, Object?>{
      'label': '@shopSeedI1',
      'qty': '2 kg',
      'price': 4,
      'group': 'produce',
    },
    <String, Object?>{
      'label': '@shopSeedI2',
      'qty': '1 L',
      'price': 2,
      'group': 'dairy',
    },
    <String, Object?>{
      'label': '@shopSeedI3',
      'qty': '500 g',
      'price': 6,
      'group': 'dairy',
      'done': true,
    },
    <String, Object?>{
      'label': '@shopSeedI4',
      'qty': '1',
      'price': 3,
      'group': 'produce',
    },
    <String, Object?>{
      'label': '@shopSeedI5',
      'qty': '2',
      'price': 8,
      'group': 'household',
    },
  ],
  _ => null,
};
