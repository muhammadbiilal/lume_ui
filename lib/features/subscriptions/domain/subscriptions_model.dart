/// Subscriptions' stored records — one per recurring subscription — and
/// their codec to and from the record envelope
/// (`SUBSCRIPTIONS_PROPOSAL.md` §2).
///
/// **The reference hand-types a display date and a day-count as two
/// independent literals** (`tool-data.js:763-769`) with no recurrence
/// engine behind either. This model stores one real anchor date
/// (`startedOn`) and a cycle, and every renewal date is computed from
/// them, every time (`subscriptions_book.dart`) — never a second
/// hand-typed field that could disagree with the first.
///
/// **One codec, nothing else sees a map.** A record that fails is a
/// [SubscriptionsDefect], shown as damaged, never dropped or repaired
/// silently.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kSubscriptionsSchema = 'lume.subscriptions/1';

/// The record collection Subscriptions keeps. One flat collection — unlike
/// Goals/Installments there is no child record; a subscription is a single
/// row whose renewal is always derived, never scheduled in advance.
abstract final class SubscriptionsCollections {
  static const String subscriptions = 'subscriptions.subscription';
  static const List<String> all = <String>[subscriptions];
}

const int kSubscriptionsNameMax = 80;
const int kSubscriptionsCategoryMax = 40;

/// D-S4: monthly and yearly (the only two the reference shows), plus a
/// typed custom day-count for a cycle that is neither.
enum SubscriptionCycle { monthly, yearly, custom }

enum SubscriptionState { active, cancelled }

/// A small fixed palette a subscription is drawn with, matching the
/// reference's decorative `tone` field (`tool-data.js`: rose, green, sky,
/// amber, indigo) — never a meaningful stored fact.
enum SubscriptionTone { rose, green, sky, amber, indigo }

@immutable
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    this.category,
    required this.amount,
    required this.cycle,
    this.customDays,
    required this.startedOn,
    this.tone = SubscriptionTone.sky,
    this.state = SubscriptionState.active,
    required this.createdAt,
    this.cancelledAt,
    this.version = 1,
  }) : assert(
         cycle == SubscriptionCycle.custom
             ? customDays != null
             : customDays == null,
         'customDays only accompanies SubscriptionCycle.custom',
       );

  final LumeRecordId id;
  final String name;

  /// Free text, matching the reference (`cat`) — never a closed enum, since
  /// the reference never constrains it.
  final String? category;
  final LumeMoney amount;
  final SubscriptionCycle cycle;

  /// Set only when [cycle] is [SubscriptionCycle.custom].
  final int? customDays;

  /// The anchor every renewal date is computed from. The reference has no
  /// equivalent — it hand-types `renews` and `days` independently
  /// (`tool-data.js:763-769`); this is the one real date that replaces both.
  final LumeDate startedOn;
  final SubscriptionTone tone;
  final SubscriptionState state;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final int version;

  LumeCurrency get currency => amount.currency;
  bool get active => state == SubscriptionState.active;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kSubscriptionsSchema,
    'name': name,
    'category': category,
    'amountMinor': amount.minor,
    'currency': currency.code,
    'cycle': cycle.name,
    'customDays': customDays,
    'startedOn': startedOn.toIso(),
    'tone': tone.name,
    'state': state.name,
    'cancelledAt': cancelledAt?.toIso8601String(),
  };

  Subscription copyWith({
    String? name,
    String? category,
    bool clearCategory = false,
    LumeMoney? amount,
    SubscriptionCycle? cycle,
    int? customDays,
    bool clearCustomDays = false,
    LumeDate? startedOn,
    SubscriptionTone? tone,
    SubscriptionState? state,
    DateTime? cancelledAt,
    bool clearCancelledAt = false,
  }) => Subscription(
    id: id,
    name: name ?? this.name,
    category: clearCategory ? null : (category ?? this.category),
    amount: amount ?? this.amount,
    cycle: cycle ?? this.cycle,
    customDays: clearCustomDays ? null : (customDays ?? this.customDays),
    startedOn: startedOn ?? this.startedOn,
    tone: tone ?? this.tone,
    state: state ?? this.state,
    createdAt: createdAt,
    cancelledAt: clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
    version: version,
  );

  static Subscription decode(LumeRecord r) {
    final SubscriptionsCodec c = SubscriptionsCodec(
      SubscriptionsCollections.subscriptions,
      r,
    );
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    final SubscriptionCycle cycle = c.choice('cycle', SubscriptionCycle.values);
    int? customDays;
    if (cycle == SubscriptionCycle.custom) {
      final Object? d = r['customDays'];
      if (d is! int || d < 1 || d > 3660) c.fail('customDays', 'range');
      customDays = d;
    } else if (r['customDays'] != null) {
      c.fail('customDays', 'unexpected');
    }
    final Object? cancelled = r['cancelledAt'];
    if (cancelled != null && cancelled is! String) {
      c.fail('cancelledAt', 'type');
    }
    return Subscription(
      id: c.id,
      name: c.name('name'),
      category: c.optionalName('category', max: kSubscriptionsCategoryMax),
      amount: amount,
      cycle: cycle,
      customDays: customDays,
      startedOn: c.date('startedOn')!,
      tone: c.choice('tone', SubscriptionTone.values),
      state: c.choice('state', SubscriptionState.values),
      createdAt: r.createdAt,
      cancelledAt: cancelled == null ? null : DateTime.tryParse(cancelled as String),
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.id == id &&
      other.name == name &&
      other.category == category &&
      other.amount == amount &&
      other.cycle == cycle &&
      other.customDays == customDays &&
      other.startedOn == startedOn &&
      other.tone == tone &&
      other.state == state &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    amount,
    cycle,
    customDays,
    startedOn,
    tone,
    state,
    version,
  );
}

/// A record that could not be read as what its collection holds.
@immutable
class SubscriptionsDefect {
  const SubscriptionsDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class SubscriptionsDefectException implements Exception {
  const SubscriptionsDefectException(this.defect);
  final SubscriptionsDefect defect;

  @override
  String toString() => 'SubscriptionsDefectException($defect)';
}

/// Strict field readers for one record.
class SubscriptionsCodec {
  SubscriptionsCodec(this.collection, this.record) {
    if (record['schema'] != kSubscriptionsSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) =>
      throw SubscriptionsDefectException(
        SubscriptionsDefect(collection, record.id, field, reason),
      );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  String name(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > kSubscriptionsNameMax) fail(field, 'long');
    return t;
  }

  String? optionalName(String field, {int max = kSubscriptionsNameMax}) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    final String t = v.trim();
    if (t.length > max) fail(field, 'long');
    return t.isEmpty ? null : t;
  }

  T choice<T extends Enum>(String field, List<T> values) {
    final Object? v = record[field];
    for (final T x in values) {
      if (x.name == v) return x;
    }
    fail(field, 'value');
  }

  LumeDate? date(String field, {bool optional = false}) {
    final Object? v = record[field];
    if (v == null && optional) return null;
    if (v is! String) fail(field, 'missing');
    return LumeDate.tryParse(v) ?? fail(field, 'date');
  }

  LumeMoney money(String minorField, String currencyField) {
    final Object? code = record[currencyField];
    if (code is! String) fail(currencyField, 'missing');
    final LumeCurrency? cur = LumeCurrency.tryOf(code);
    if (cur == null) fail(currencyField, 'currency');
    final Object? minor = record[minorField];
    if (minor is! int) fail(minorField, 'type');
    try {
      return LumeMoney.entry(minor, cur);
    } on LumeMoneyException catch (e) {
      fail(minorField, e.failure.name);
    }
  }
}
