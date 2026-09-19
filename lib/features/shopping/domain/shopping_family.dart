/// The shopping list on the record layer — `record-schemas.js` `shopping`.
///
/// An item is its words, a quantity as the reader writes it ("2 kg",
/// "1 pack" — kept as text, never parsed into a unit), an aisle, an
/// estimated price in the reader's currency, and whether it is in the
/// basket. Guide: "checked state and quantity" · "confirmed bulk clear".
library;

import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_schema.dart';
import '../../records/presentation/record_family.dart';

/// `options.groups`.
enum LumeShopAisle {
  produce('@shop.gProduce'),
  dairy('@shop.gDairy'),
  household('@shop.gHousehold');

  const LumeShopAisle(this.legacy);

  final String legacy;

  static LumeShopAisle? byId(Object? v) {
    for (final LumeShopAisle a in values) {
      if (v == a.name || v == a.legacy) return a;
    }
    return null;
  }

  String label(AppLocalizations l) => switch (this) {
    produce => l.shopAisleProduce,
    dairy => l.shopAisleDairy,
    household => l.shopAisleHousehold,
  };
}

class LumeShopItem extends LumeFamilyRecord {
  const LumeShopItem(
    super.record, {
    required this.label,
    required this.qty,
    required this.aisle,
    required this.price,
    required this.done,
  });

  final String label;

  /// As written; empty when not given.
  final String qty;

  final LumeShopAisle? aisle;

  /// In the reader's currency, or `null` when not given. `Number(r.price)`
  /// — a price the store cannot read as a number is no price.
  final num? price;

  /// In the basket.
  final bool done;
}

class LumeShoppingFamily extends LumeRecordFamily<LumeShopItem> {
  const LumeShoppingFamily();

  static const LumeRecordSchema kSchema = LumeRecordSchema(
    collection: 'shopping',
    fields: <LumeRecordField>[
      LumeRecordField(
        name: 'label',
        kind: LumeRecordFieldKind.text,
        required: true,
      ),
      LumeRecordField(
        name: 'qty',
        kind: LumeRecordFieldKind.text,
        optional: true,
      ),
      LumeRecordField(name: 'group', kind: LumeRecordFieldKind.select),
      LumeRecordField(
        name: 'price',
        kind: LumeRecordFieldKind.money,
        optional: true,
      ),
      LumeRecordField(name: 'done', kind: LumeRecordFieldKind.check),
    ],
  );

  @override
  LumeRecordSchema get schema => kSchema;

  @override
  String get icon => LumeIcons.cart;

  @override
  String noun(AppLocalizations l) => l.recShoppingNoun;
  @override
  String nounPlural(AppLocalizations l) => l.recShoppingNounPlural;
  @override
  String emptyTitle(AppLocalizations l) => l.recShoppingEmptyTitle;
  @override
  String emptyText(AppLocalizations l) => l.recShoppingEmptyText;

  static String seeded(AppLocalizations l, String key) => switch (key) {
    'shopSeedI1' => l.shopSeedI1,
    'shopSeedI2' => l.shopSeedI2,
    'shopSeedI3' => l.shopSeedI3,
    'shopSeedI4' => l.shopSeedI4,
    'shopSeedI5' => l.shopSeedI5,
    _ => '@$key',
  };

  static num? _price(Object? v) {
    if (v is num) return v.isFinite ? v : null;
    final String s = '${v ?? ''}'.trim();
    return s.isEmpty ? null : num.tryParse(s);
  }

  @override
  LumeShopItem read(LumeRecord r, LumeRecordContext c) => LumeShopItem(
    r,
    label: LumeFamilyText.resolve(r, 'label', (String k) => seeded(c.l, k)),
    qty: LumeFamilyText.resolve(r, 'qty', (String k) => seeded(c.l, k)),
    aisle: LumeShopAisle.byId(r['group']),
    price: _price(r['price']),
    done: r['done'] == true,
  );

  @override
  Map<String, Object?> defaults(LumeRecordContext c) => <String, Object?>{
    'group': LumeShopAisle.values.first.name,
    'done': false,
  };

  @override
  Map<String, Object?> editValues(LumeShopItem x) => <String, Object?>{
    'label': x.label,
    'qty': x.qty,
    'group': x.aisle?.name ?? '',
    'price': x.price ?? '',
    'done': x.done,
  };

  /// `c.moneyRaw(Number(r.price), null, 0)` — only for a price that is
  /// there (`r.price ?`).
  String? price(LumeShopItem x, LumeRecordContext c) =>
      x.price == null || x.price == 0 ? null : c.f.money(x.price!);

  @override
  LumeFamilyRow row(LumeShopItem x, LumeRecordContext c) => LumeFamilyRow(
    title: x.label,
    subtitle: <String>[
      if (x.qty.isNotEmpty) x.qty,
      if (x.aisle != null) x.aisle!.label(c.l),
    ].join(' · '),
    value: price(x, c),
  );

  @override
  LumeFamilyHero hero(LumeShopItem x, LumeRecordContext c) => LumeFamilyHero(
    kicker: x.aisle?.label(c.l) ?? c.l.recShoppingNoun,
    value: x.label,
    caption: x.qty.isEmpty ? null : x.qty,
    gradient: (g) => x.done ? g.sport : g.accent,
  );

  @override
  List<LumeFact> facts(LumeShopItem x, LumeRecordContext c) => <LumeFact>[
    LumeFact(label: c.l.recFieldQuantity, value: x.qty.isEmpty ? '—' : x.qty),
    LumeFact(label: c.l.recFieldAisle, value: x.aisle?.label(c.l) ?? '—'),
    LumeFact(label: c.l.recFieldEstimate, value: price(x, c) ?? '—'),
    LumeFact(
      label: c.l.commonStatus,
      value: x.done ? c.l.recFieldInBasket : c.l.recToBuy,
    ),
  ];

  @override
  List<LumeFamilyField> fields(LumeRecordContext c) => <LumeFamilyField>[
    LumeFamilyField(
      name: 'label',
      label: c.l.recFieldItem,
      placeholder: c.l.recShoppingPh,
    ),
    LumeFamilyField(
      name: 'qty',
      label: c.l.recFieldQuantity,
      placeholder: c.l.recShoppingQtyPh,
    ),
    LumeFamilyField(
      name: 'group',
      label: c.l.recFieldAisle,
      options: <LumeFamilyOption>[
        for (final LumeShopAisle a in LumeShopAisle.values)
          LumeFamilyOption(a.name, a.label(c.l)),
      ],
    ),
    LumeFamilyField(name: 'price', label: c.l.recFieldEstimate),
    LumeFamilyField(name: 'done', label: c.l.recFieldInBasket),
  ];

  @override
  List<LumeFamilyFilter<LumeShopItem>> filters(LumeRecordContext c) =>
      <LumeFamilyFilter<LumeShopItem>>[
        LumeFamilyFilter<LumeShopItem>(
          'todo',
          c.l.recToBuy,
          (LumeShopItem x) => !x.done,
        ),
        LumeFamilyFilter<LumeShopItem>(
          'done',
          c.l.recFieldInBasket,
          (LumeShopItem x) => x.done,
        ),
      ];

  @override
  String? checkLabel(AppLocalizations l) => l.recFieldInBasket;

  @override
  bool checked(LumeShopItem x) => x.done;

  @override
  Map<String, Object?> toggled(LumeShopItem x, LumeRecordContext c) =>
      <String, Object?>{'done': !x.done};

  @override
  LumeFamilyBulk<LumeShopItem> bulk(AppLocalizations l) =>
      LumeFamilyBulk<LumeShopItem>(
        test: (LumeShopItem x) => x.done,
        label: l.recShoppingClear,
        confirm: l.recShoppingClearConfirm,
      );
}

/// `c.shopping()` — the list's figures, from the records.
class LumeShoppingBoard {
  LumeShoppingBoard(this.items);

  final List<LumeShopItem> items;

  int get checked => items.where((LumeShopItem x) => x.done).length;
  int get remaining => items.length - checked;

  /// Every item's price, in the basket or not — `reduce(a + i.price)`.
  num get estimate =>
      items.fold<num>(0, (num a, LumeShopItem x) => a + (x.price ?? 0));

  /// The ring's share. The reference divides by the count even when it is
  /// zero; an empty list is an empty ring here.
  double get share => items.isEmpty ? 0 : checked / items.length;

  /// Aisles in their order, each with its items; empty aisles left out.
  List<(LumeShopAisle?, List<LumeShopItem>)> groups(
    bool Function(LumeShopItem x) keep,
  ) => <(LumeShopAisle?, List<LumeShopItem>)>[
    for (final LumeShopAisle? a in <LumeShopAisle?>[
      ...LumeShopAisle.values,
      null,
    ])
      (
        a,
        <LumeShopItem>[
          for (final LumeShopItem x in items)
            if (x.aisle == a && keep(x)) x,
        ],
      ),
  ].where(((LumeShopAisle?, List<LumeShopItem>) g) => g.$2.isNotEmpty).toList();
}
