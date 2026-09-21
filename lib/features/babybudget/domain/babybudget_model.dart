/// A baby budget, as records: what is stored and how it is read back
/// (`BABY_BUDGET_PROPOSAL.md` §5).
///
/// Three collections under one schema: the budget, the categories the
/// reader names, and the spends. A spend is either money that went or
/// money they mean to spend, never half of each — `planned` decides, and
/// `spentOn` is null for exactly as long as `planned` is true
/// (correction 1). That is what keeps an intention out of a month's
/// spending, whatever query asks for it.
///
/// Nothing derived is stored: no month total, no ratio, no share, no
/// trend. Those are worked out in `babybudget_book.dart` and checked
/// before any write is published.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The schema every baby-budget record carries.
const String kBabyBudgetSchema = 'lume.babybudget/1';

/// Where each kind of record lives.
abstract final class BabyBudgetCollections {
  static const String budgets = 'babybudget.budget';
  static const String categories = 'babybudget.category';
  static const String spends = 'babybudget.spend';

  static const List<String> all = <String>[budgets, categories, spends];
}

/// A budget's or a category's name.
const int kBabyNameMax = 80;

/// A note on a budget.
const int kBabyNoteMax = 500;

/// A spend's own label.
const int kBabyLabelMax = 80;

/// The most categories one budget may have.
const int kBabyCategoryMax = 50;

/// How many tones a category may be given. The tone is chosen, never
/// derived from the name, so renaming a category does not recolour it.
const int kBabyColourCount = 5;

/// Whether a spend still counts.
enum BabySpendState { active, voided }

/// The budget itself: its plan, where it starts, and whether it has been
/// put away.
@immutable
class BabyBudget {
  const BabyBudget({
    required this.id,
    required this.name,
    this.note,
    required this.currency,
    this.monthlyPlan,
    required this.startedOn,
    this.archivedOn,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;

  /// The reader's own label: "Ayaan", "The baby".
  final String name;
  final String? note;

  /// One currency for the whole budget.
  final LumeCurrency currency;

  /// What they mean to spend a month.
  ///
  /// Absent means no plan, and then there is no ratio and no ring. It is
  /// never zero: a plan of nothing is no plan (correction 2).
  final LumeMoney? monthlyPlan;

  /// The first day this budget covers. Nothing may predate it, and
  /// before it there are no figures at all (correction 3).
  final LumeDate startedOn;

  /// The day the reader put it away, or `null` while it is in use.
  final LumeDate? archivedOn;

  final DateTime createdAt;
  final int version;

  bool get archived => archivedOn != null;
  bool get hasPlan => monthlyPlan != null;

  /// Whether the budget has begun by [today]. Without a day, nothing is
  /// claimed either way.
  bool? startedBy(LumeDate? today) =>
      today == null ? null : !startedOn.isAfter(today);

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kBabyBudgetSchema,
    'name': name,
    'note': note,
    'currency': currency.code,
    'planMinor': monthlyPlan?.minor,
    'startedOn': startedOn.toIso(),
    'archivedOn': archivedOn?.toIso(),
  };

  BabyBudget copyWith({
    String? name,
    String? note,
    bool clearNote = false,
    LumeMoney? monthlyPlan,
    bool clearPlan = false,
    LumeDate? startedOn,
    LumeDate? archivedOn,
    bool clearArchived = false,
  }) => BabyBudget(
    id: id,
    name: name ?? this.name,
    note: clearNote ? null : (note ?? this.note),
    currency: currency,
    monthlyPlan: clearPlan ? null : (monthlyPlan ?? this.monthlyPlan),
    startedOn: startedOn ?? this.startedOn,
    archivedOn: clearArchived ? null : (archivedOn ?? this.archivedOn),
    createdAt: createdAt,
    version: version,
  );

  static BabyBudget decode(LumeRecord r) {
    final BabyBudgetCodec c = BabyBudgetCodec(BabyBudgetCollections.budgets, r);
    final LumeCurrency currency = c.currency('currency');
    final LumeMoney? plan = c.optionalMoney('planMinor', currency);
    // A plan of nothing is no plan, and is never stored (correction 2).
    if (plan != null && !plan.isPositive) c.fail('planMinor', 'zero');
    return BabyBudget(
      id: c.id,
      name: c.name('name'),
      note: c.note('note'),
      currency: currency,
      monthlyPlan: plan,
      startedOn: c.date('startedOn')!,
      archivedOn: c.date('archivedOn', optional: true),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BabyBudget &&
      other.id == id &&
      other.name == name &&
      other.note == note &&
      other.currency == currency &&
      other.monthlyPlan == monthlyPlan &&
      other.startedOn == startedOn &&
      other.archivedOn == archivedOn &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    note,
    currency,
    monthlyPlan,
    startedOn,
    archivedOn,
    version,
  );
}

/// One of the reader's own categories.
@immutable
class BabyCategory {
  const BabyCategory({
    required this.id,
    required this.budgetId,
    required this.name,
    this.monthlyPlan,
    required this.order,
    this.colour = 0,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId budgetId;
  final String name;

  /// Its share of the budget's plan.
  ///
  /// Allowed only while the budget has a plan, and always greater than
  /// zero (correction 2).
  final LumeMoney? monthlyPlan;

  /// Where the reader put it, 0-based and unique within the budget.
  final int order;

  /// A slice tone, 0..[kBabyColourCount] − 1.
  final int colour;

  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kBabyBudgetSchema,
    'budget': budgetId.value,
    'name': name,
    'planMinor': monthlyPlan?.minor,
    'order': order,
    'colour': colour,
  };

  BabyCategory copyWith({
    String? name,
    LumeMoney? monthlyPlan,
    bool clearPlan = false,
    int? order,
    int? colour,
  }) => BabyCategory(
    id: id,
    budgetId: budgetId,
    name: name ?? this.name,
    monthlyPlan: clearPlan ? null : (monthlyPlan ?? this.monthlyPlan),
    order: order ?? this.order,
    colour: colour ?? this.colour,
    createdAt: createdAt,
    version: version,
  );

  static BabyCategory decode(LumeRecord r, {required LumeCurrency currency}) {
    final BabyBudgetCodec c = BabyBudgetCodec(
      BabyBudgetCollections.categories,
      r,
    );
    final Object? order = r['order'];
    if (order is! int) c.fail('order', 'type');
    if (order < 0 || order >= kBabyCategoryMax) c.fail('order', 'range');
    final Object? colour = r['colour'];
    if (colour is! int) c.fail('colour', 'type');
    if (colour < 0 || colour >= kBabyColourCount) c.fail('colour', 'range');
    final LumeMoney? plan = c.optionalMoney('planMinor', currency);
    if (plan != null && !plan.isPositive) c.fail('planMinor', 'zero');
    return BabyCategory(
      id: c.id,
      budgetId: c.ref('budget'),
      name: c.name('name'),
      monthlyPlan: plan,
      order: order,
      colour: colour,
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BabyCategory &&
      other.id == id &&
      other.budgetId == budgetId &&
      other.name == name &&
      other.monthlyPlan == monthlyPlan &&
      other.order == order &&
      other.colour == colour &&
      other.version == version;

  @override
  int get hashCode =>
      Object.hash(id, budgetId, name, monthlyPlan, order, colour, version);
}

/// Money that went, or money the reader means to spend.
///
/// The two are exclusive (correction 1): while [planned] is true there is
/// no [spentOn], and once it is false there is no [expectedOn]. Nothing
/// is ever both, and no figure has to guess which it is looking at.
@immutable
class BabySpend {
  const BabySpend({
    required this.id,
    required this.budgetId,
    this.categoryId,
    this.label,
    required this.amount,
    required this.planned,
    this.spentOn,
    this.expectedOn,
    this.state = BabySpendState.active,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId budgetId;

  /// Absent means uncategorised, which is a real slice of its own.
  final LumeRecordId? categoryId;
  final String? label;
  final LumeMoney amount;

  /// True while this is an intention; false once the money went.
  final bool planned;

  /// The day the money went. Null for exactly as long as [planned].
  final LumeDate? spentOn;

  /// The day it is expected. Only ever set while [planned].
  final LumeDate? expectedOn;

  final BabySpendState state;
  final DateTime createdAt;
  final int version;

  bool get active => state == BabySpendState.active;
  bool get voided => state == BabySpendState.voided;
  LumeCurrency get currency => amount.currency;

  /// Money that went and still counts.
  bool get counts => active && !planned;

  /// The day this record is about, whichever kind it is.
  LumeDate? get day => planned ? expectedOn : spentOn;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kBabyBudgetSchema,
    'budget': budgetId.value,
    'category': categoryId?.value,
    'label': label,
    'amountMinor': amount.minor,
    'currency': currency.code,
    'planned': planned,
    'spentOn': spentOn?.toIso(),
    'expectedOn': expectedOn?.toIso(),
    'state': state.name,
  };

  /// What the reader may change without changing what kind of record it
  /// is. Turning a spend back into a plan, or a plan into a spend, is not
  /// here on purpose: each is its own action (D-B18).
  BabySpend copyWith({
    LumeRecordId? categoryId,
    bool clearCategory = false,
    String? label,
    bool clearLabel = false,
    LumeMoney? amount,
    LumeDate? spentOn,
    LumeDate? expectedOn,
    bool clearExpected = false,
  }) => BabySpend(
    id: id,
    budgetId: budgetId,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    label: clearLabel ? null : (label ?? this.label),
    amount: amount ?? this.amount,
    planned: planned,
    spentOn: planned ? null : (spentOn ?? this.spentOn),
    expectedOn: planned
        ? (clearExpected ? null : (expectedOn ?? this.expectedOn))
        : null,
    state: state,
    createdAt: createdAt,
    version: version,
  );

  /// Mark a planned purchase bought, in one move: it stops being
  /// planned, takes the day the money went, loses the day it was
  /// expected, and takes what was actually paid where that is given
  /// (correction 1).
  BabySpend bought(LumeDate on, {LumeMoney? actually}) => BabySpend(
    id: id,
    budgetId: budgetId,
    categoryId: categoryId,
    label: label,
    amount: actually ?? amount,
    planned: false,
    spentOn: on,
    state: state,
    createdAt: createdAt,
    version: version,
  );

  /// Turn a spend back into a plan — the deliberate way back (D-B18).
  BabySpend replanned({LumeDate? expected}) => BabySpend(
    id: id,
    budgetId: budgetId,
    categoryId: categoryId,
    label: label,
    amount: amount,
    planned: true,
    expectedOn: expected,
    state: state,
    createdAt: createdAt,
    version: version,
  );

  BabySpend withState(BabySpendState s) => BabySpend(
    id: id,
    budgetId: budgetId,
    categoryId: categoryId,
    label: label,
    amount: amount,
    planned: planned,
    spentOn: spentOn,
    expectedOn: expectedOn,
    state: s,
    createdAt: createdAt,
    version: version,
  );

  static BabySpend decode(LumeRecord r) {
    final BabyBudgetCodec c = BabyBudgetCodec(BabyBudgetCollections.spends, r);
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (!amount.isPositive) c.fail('amountMinor', 'zero');
    final bool planned = c.flag('planned');
    final LumeDate? spentOn = c.date('spentOn', optional: true);
    final LumeDate? expectedOn = c.date('expectedOn', optional: true);
    // Spent or planned, never between (correction 1).
    if (planned) {
      if (spentOn != null) c.fail('spentOn', 'planned');
    } else {
      if (spentOn == null) c.fail('spentOn', 'missing');
      if (expectedOn != null) c.fail('expectedOn', 'spent');
    }
    return BabySpend(
      id: c.id,
      budgetId: c.ref('budget'),
      categoryId: c.optionalRef('category'),
      label: c.optionalName('label', kBabyLabelMax),
      amount: amount,
      planned: planned,
      spentOn: spentOn,
      expectedOn: expectedOn,
      state: c.choice('state', BabySpendState.values),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BabySpend &&
      other.id == id &&
      other.budgetId == budgetId &&
      other.categoryId == categoryId &&
      other.label == label &&
      other.amount == amount &&
      other.planned == planned &&
      other.spentOn == spentOn &&
      other.expectedOn == expectedOn &&
      other.state == state &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    budgetId,
    categoryId,
    label,
    amount,
    planned,
    spentOn,
    expectedOn,
    state,
    version,
  );
}

/// A stored record that cannot be read, and why.
@immutable
class BabyBudgetDefect {
  const BabyBudgetDefect(
    this.collection,
    this.recordId,
    this.field,
    this.reason, {
    this.budgetId,
  });

  final String collection;
  final String recordId;
  final String field;

  /// A stable machine word: missing, type, range, zero, currency, schema,
  /// uuid, empty, long, value, date, planned, spent, precision, overflow.
  final String reason;

  /// The budget the record belongs to, when it names one.
  final String? budgetId;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

/// Thrown by a decoder. Callers list the defect; nothing is repaired.
@immutable
class BabyBudgetDefectException implements Exception {
  const BabyBudgetDefectException(this.defect);

  final BabyBudgetDefect defect;

  @override
  String toString() => 'BabyBudgetDefectException($defect)';
}

/// Reads one stored record strictly. Anything unexpected is a defect.
class BabyBudgetCodec {
  BabyBudgetCodec(this.collection, this.record) {
    if (record['schema'] != kBabyBudgetSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw BabyBudgetDefectException(
    BabyBudgetDefect(
      collection,
      record.id,
      field,
      reason,
      budgetId: collection == BabyBudgetCollections.budgets
          ? record.id
          : (record['budget'] is String ? record['budget']! as String : null),
    ),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeRecordId ref(String field) {
    final Object? raw = record[field];
    if (raw is! String) fail(field, 'missing');
    return LumeRecordId.tryParse(raw) ?? fail(field, 'uuid');
  }

  LumeRecordId? optionalRef(String field) {
    final Object? raw = record[field];
    if (raw == null) return null;
    if (raw is! String) fail(field, 'type');
    return LumeRecordId.tryParse(raw) ?? fail(field, 'uuid');
  }

  String name(String field) {
    final Object? raw = record[field];
    if (raw is! String) fail(field, 'missing');
    final String text = raw.trim();
    if (text.isEmpty) fail(field, 'empty');
    if (text.length > kBabyNameMax) fail(field, 'long');
    return text;
  }

  String? optionalName(String field, int max) {
    final Object? raw = record[field];
    if (raw == null) return null;
    if (raw is! String) fail(field, 'type');
    if (raw.length > max) fail(field, 'long');
    return raw.trim().isEmpty ? null : raw.trim();
  }

  String? note(String field) {
    final Object? raw = record[field];
    if (raw == null) return null;
    if (raw is! String) fail(field, 'type');
    if (raw.length > kBabyNoteMax) fail(field, 'long');
    return raw.trim().isEmpty ? null : raw;
  }

  bool flag(String field) {
    final Object? raw = record[field];
    if (raw == null) return false;
    if (raw is! bool) fail(field, 'type');
    return raw;
  }

  T choice<T extends Enum>(String field, List<T> values) {
    final Object? raw = record[field];
    if (raw is! String) fail(field, 'missing');
    for (final T v in values) {
      if (v.name == raw) return v;
    }
    fail(field, 'value');
  }

  LumeDate? date(String field, {bool optional = false}) {
    final Object? raw = record[field];
    if (raw == null) {
      if (optional) return null;
      fail(field, 'missing');
    }
    if (raw is! String) fail(field, 'missing');
    return LumeDate.tryParse(raw) ?? fail(field, 'date');
  }

  LumeCurrency currency(String field) {
    final Object? code = record[field];
    if (code is! String) fail(field, 'missing');
    return LumeCurrency.tryOf(code) ?? fail(field, 'currency');
  }

  LumeMoney money(String minorField, String currencyField) {
    final LumeCurrency cur = currency(currencyField);
    final Object? minor = record[minorField];
    if (minor is! int) fail(minorField, 'missing');
    return _entry(minorField, minor, cur);
  }

  LumeMoney? optionalMoney(String minorField, LumeCurrency cur) {
    final Object? minor = record[minorField];
    if (minor == null) return null;
    if (minor is! int) fail(minorField, 'type');
    return _entry(minorField, minor, cur);
  }

  LumeMoney _entry(String field, int minor, LumeCurrency cur) {
    try {
      return LumeMoney.entry(minor, cur);
    } on LumeMoneyException catch (e) {
      fail(field, e.failure.name);
    }
  }
}
