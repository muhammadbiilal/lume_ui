/// Installments' stored records — a plan, its schedule, its payments — and
/// their codec to and from the record envelope
/// (`INSTALLMENTS_PROPOSAL.md` §40.3).
///
/// **A plan is what the reader was quoted:** an instalment amount, a count,
/// a currency, a first due date, monthly. Nothing here is a rate: there is
/// no interest, markup, amortisation or conversion anywhere in the tool.
///
/// **The schedule is stored.** It is generated once, when the plan is
/// created, and never recomputed from the calendar again; a payment names
/// the scheduled instalment it pays by id.
///
/// **One codec, nothing else sees a map.** Each type decodes from a
/// [LumeRecord] strictly; a record that fails is an [InstallmentsDefect],
/// shown as damaged, never dropped and never repaired silently.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kInstallmentsSchema = 'lume.installments/1';

/// The record collections Installments keeps.
abstract final class InstallmentsCollections {
  static const String plans = 'installments.plan';
  static const String schedule = 'installments.schedule';
  static const String payments = 'installments.payment';
  static const List<String> all = <String>[plans, schedule, payments];
}

/// Longest item or merchant, and longest note, the reader may type.
const int kInstallmentsNameMax = 80;
const int kInstallmentsNoteMax = 500;

/// The most instalments one plan may have: fifty years of months.
const int kInstallmentsCountMax = 600;

/// How often an instalment falls due. Monthly only in v1 (D-I7); typed, so
/// a later frequency is an addition and a stored record that names one this
/// build does not know is reported rather than read as monthly.
enum InstallmentFrequency { monthly }

enum InstallmentPlanState { active, cancelled }

enum InstallmentPaymentState { active, voided }

/// A purchase paid in fixed instalments — the reader is the payer.
@immutable
class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.item,
    this.merchant,
    this.note,
    required this.amount,
    required this.count,
    this.frequency = InstallmentFrequency.monthly,
    required this.firstDue,
    this.deposit,
    this.depositOn,
    this.cashPrice,
    this.state = InstallmentPlanState.active,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final String item;
  final String? merchant;
  final String? note;

  /// The instalment amount, as quoted: every scheduled instalment is this.
  final LumeMoney amount;
  final int count;
  final InstallmentFrequency frequency;

  /// The first instalment's due date — the schedule's anchor.
  final LumeDate firstDue;

  /// Money already paid before the schedule: counted in the total payable
  /// and in what is paid, never an instalment.
  final LumeMoney? deposit;
  final LumeDate? depositOn;

  /// What the item would have cost outright — informational only.
  final LumeMoney? cashPrice;
  final InstallmentPlanState state;
  final DateTime createdAt;
  final int version;

  LumeCurrency get currency => amount.currency;
  bool get cancelled => state == InstallmentPlanState.cancelled;

  /// amount × count.
  LumeMoney get scheduledTotal => LumeMoney.sum(amount.minor * count, currency);

  /// deposit + scheduled total.
  LumeMoney get totalPayable =>
      scheduledTotal + (deposit ?? LumeMoney.zero(currency));

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kInstallmentsSchema,
    'item': item,
    'merchant': merchant,
    'note': note,
    'amountMinor': amount.minor,
    'currency': currency.code,
    'count': count,
    'frequency': frequency.name,
    'firstDue': firstDue.toIso(),
    'depositMinor': deposit?.minor,
    'depositOn': depositOn?.toIso(),
    'cashPriceMinor': cashPrice?.minor,
    'state': state.name,
  };

  InstallmentPlan copyWith({
    String? item,
    String? merchant,
    String? note,
    bool clearMerchant = false,
    bool clearNote = false,
    InstallmentPlanState? state,
  }) => InstallmentPlan(
    id: id,
    item: item ?? this.item,
    merchant: clearMerchant ? null : (merchant ?? this.merchant),
    note: clearNote ? null : (note ?? this.note),
    amount: amount,
    count: count,
    frequency: frequency,
    firstDue: firstDue,
    deposit: deposit,
    depositOn: depositOn,
    cashPrice: cashPrice,
    state: state ?? this.state,
    createdAt: createdAt,
    version: version,
  );

  static InstallmentPlan decode(LumeRecord r) {
    final InstallmentsCodec c = InstallmentsCodec(
      InstallmentsCollections.plans,
      r,
    );
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    final Object? count = r['count'];
    if (count is! int) c.fail('count', 'type');
    if (count < 1 || count > kInstallmentsCountMax) c.fail('count', 'range');
    if (amount.minor > LumeMoney.maxSumMinor ~/ count) {
      c.fail('amountMinor', 'overflow');
    }
    final Object? freq = r['frequency'];
    InstallmentFrequency? frequency;
    for (final InstallmentFrequency f in InstallmentFrequency.values) {
      if (f.name == freq) frequency = f;
    }
    if (frequency == null) {
      c.fail('frequency', freq is String ? 'unsupported' : 'missing');
    }
    final LumeDate firstDue = c.date('firstDue')!;
    final LumeMoney? deposit = c.optionalMoney('depositMinor', amount.currency);
    final LumeDate? depositOn = c.date('depositOn', optional: true);
    if ((deposit == null) != (depositOn == null)) {
      c.fail(deposit == null ? 'depositMinor' : 'depositOn', 'pair');
    }
    if (deposit != null && deposit.isZero) c.fail('depositMinor', 'zero');
    final LumeMoney? cash = c.optionalMoney('cashPriceMinor', amount.currency);
    if (cash != null && cash.isZero) c.fail('cashPriceMinor', 'zero');
    final InstallmentPlan p = InstallmentPlan(
      id: c.id,
      item: c.name('item'),
      merchant: c.optionalName('merchant'),
      note: c.note('note'),
      amount: amount,
      count: count,
      frequency: frequency,
      firstDue: firstDue,
      deposit: deposit,
      depositOn: depositOn,
      cashPrice: cash,
      state: c.choice('state', InstallmentPlanState.values),
      createdAt: r.createdAt,
      version: r.version,
    );
    if (deposit != null && deposit.compareTo(p.totalPayable) > 0) {
      c.fail('depositMinor', 'exceedsTotal');
    }
    return p;
  }

  @override
  bool operator ==(Object other) =>
      other is InstallmentPlan &&
      other.id == id &&
      other.item == item &&
      other.merchant == merchant &&
      other.note == note &&
      other.amount == amount &&
      other.count == count &&
      other.frequency == frequency &&
      other.firstDue == firstDue &&
      other.deposit == deposit &&
      other.depositOn == depositOn &&
      other.cashPrice == cashPrice &&
      other.state == state &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    item,
    merchant,
    note,
    amount,
    count,
    firstDue,
    deposit,
    depositOn,
    cashPrice,
    state,
    version,
  );
}

/// One instalment of a plan: its place, its due date, its amount — stored
/// once, when the plan is created.
@immutable
class ScheduledInstallment {
  const ScheduledInstallment({
    required this.id,
    required this.planId,
    required this.seq,
    required this.due,
    required this.amount,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId planId;

  /// 1 for the first instalment.
  final int seq;
  final LumeDate due;
  final LumeMoney amount;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kInstallmentsSchema,
    'plan': planId.value,
    'seq': seq,
    'due': due.toIso(),
    'amountMinor': amount.minor,
    'currency': amount.currency.code,
  };

  static ScheduledInstallment decode(LumeRecord r) {
    final InstallmentsCodec c = InstallmentsCodec(
      InstallmentsCollections.schedule,
      r,
    );
    final Object? seq = r['seq'];
    if (seq is! int) c.fail('seq', 'type');
    if (seq < 1 || seq > kInstallmentsCountMax) c.fail('seq', 'range');
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    return ScheduledInstallment(
      id: c.id,
      planId: c.ref('plan'),
      seq: seq,
      due: c.date('due')!,
      amount: amount,
      createdAt: r.createdAt,
      version: r.version,
    );
  }
}

/// A payment of exactly one scheduled instalment, at its amount.
@immutable
class InstallmentPayment {
  const InstallmentPayment({
    required this.id,
    required this.planId,
    required this.installmentId,
    required this.amount,
    required this.paidOn,
    this.state = InstallmentPaymentState.active,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId planId;
  final LumeRecordId installmentId;
  final LumeMoney amount;
  final LumeDate paidOn;
  final InstallmentPaymentState state;
  final DateTime createdAt;
  final int version;

  bool get active => state == InstallmentPaymentState.active;
  bool get voided => !active;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kInstallmentsSchema,
    'plan': planId.value,
    'installment': installmentId.value,
    'amountMinor': amount.minor,
    'currency': amount.currency.code,
    'paidOn': paidOn.toIso(),
    'state': state.name,
  };

  InstallmentPayment withState(InstallmentPaymentState s) => InstallmentPayment(
    id: id,
    planId: planId,
    installmentId: installmentId,
    amount: amount,
    paidOn: paidOn,
    state: s,
    createdAt: createdAt,
    version: version,
  );

  static InstallmentPayment decode(LumeRecord r) {
    final InstallmentsCodec c = InstallmentsCodec(
      InstallmentsCollections.payments,
      r,
    );
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    return InstallmentPayment(
      id: c.id,
      planId: c.ref('plan'),
      installmentId: c.ref('installment'),
      amount: amount,
      paidOn: c.date('paidOn')!,
      state: c.choice('state', InstallmentPaymentState.values),
      createdAt: r.createdAt,
      version: r.version,
    );
  }
}

/// A record that could not be read as what its collection holds.
@immutable
class InstallmentsDefect {
  const InstallmentsDefect(
    this.collection,
    this.recordId,
    this.field,
    this.reason, {
    this.planId,
  });

  final String collection;
  final String recordId;
  final String field;

  /// A stable machine reason: `missing`, `type`, `precision`, `overflow`,
  /// `currency`, `schema`, `zero`, `unsupported`, `pair`, `exceedsTotal` …
  final String reason;

  /// The plan the record says it belongs to, when it says one.
  final String? planId;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

/// Thrown by a decode; caught by whoever reads a collection.
@immutable
class InstallmentsDefectException implements Exception {
  const InstallmentsDefectException(this.defect);
  final InstallmentsDefect defect;

  @override
  String toString() => 'InstallmentsDefectException($defect)';
}

/// Strict field readers for one record.
class InstallmentsCodec {
  InstallmentsCodec(this.collection, this.record) {
    if (record['schema'] != kInstallmentsSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw InstallmentsDefectException(
    InstallmentsDefect(
      collection,
      record.id,
      field,
      reason,
      planId: collection == InstallmentsCollections.plans
          ? record.id
          : (record['plan'] is String ? record['plan']! as String : null),
    ),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeRecordId ref(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    return LumeRecordId.tryParse(v) ?? fail(field, 'uuid');
  }

  String name(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > kInstallmentsNameMax) fail(field, 'long');
    return t;
  }

  String? optionalName(String field) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    final String t = v.trim();
    if (t.length > kInstallmentsNameMax) fail(field, 'long');
    return t.isEmpty ? null : t;
  }

  String? note(String field) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    if (v.length > kInstallmentsNoteMax) fail(field, 'long');
    return v.trim().isEmpty ? null : v;
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
    return _minor(minorField, cur);
  }

  /// An optional amount in the record's own currency.
  LumeMoney? optionalMoney(String minorField, LumeCurrency currency) {
    if (record[minorField] == null) return null;
    return _minor(minorField, currency);
  }

  LumeMoney _minor(String field, LumeCurrency cur) {
    final Object? minor = record[field];
    if (minor is! int) fail(field, 'type');
    try {
      return LumeMoney.entry(minor, cur);
    } on LumeMoneyException catch (e) {
      fail(field, e.failure.name);
    }
  }
}
