/// The document vault's dashboard figures — `tool-data.js` `DOCUMENTS`, as
/// `context.js` `documents()` reads them.
///
/// These are not the reader's records: the records are the record layer's
/// `documents` collection, and the dashboard is fixture data beside them, as
/// the reference has it (C75). Each expiry is kept as days from today rather
/// than the reference's written date, which was a year stale on the fixture
/// day ("3 Oct 2025 · in 25 days" on 7 September 2026).
library;

import '../../../core/icons/lume_icons.dart';

/// A document's category, in the order the reference counts them.
enum LumeDocumentCategory {
  identity(LumeIcons.user),
  vehicle(LumeIcons.car),
  insurance(LumeIcons.shield),
  property(LumeIcons.home),
  education(LumeIcons.graduation),
  other(LumeIcons.folder);

  const LumeDocumentCategory(this.icon);

  /// `DOC_ICONS[cat] || 'i-folder'`.
  final String icon;

  static LumeDocumentCategory? byId(String? id) {
    for (final LumeDocumentCategory c in values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

/// A fixture document's name, translated where the reference writes English.
enum LumeDocumentTitle {
  passport,
  nationalId,
  licence,
  registration,
  insurance,
  tenancy,
  degree,
}

/// Who a fixture document belongs to.
enum LumeDocumentHolder { you, household, family }

/// How a document stands on the fixture day.
enum LumeDocumentStanding {
  /// Past its expiry.
  expired,

  /// Within 45 days of it.
  expiring,

  /// Further off.
  valid,

  /// It does not expire.
  permanent,
}

class LumeVaultDocument {
  const LumeVaultDocument({
    required this.title,
    required this.category,
    required this.reference,
    required this.days,
    required this.holder,
    required this.files,
  });

  final LumeDocumentTitle title;
  final LumeDocumentCategory category;

  /// The masked number; `null` for the reference's "—".
  final String? reference;

  /// Days from today to its expiry; `null` for none.
  final int? days;

  final LumeDocumentHolder holder;
  final int files;

  /// `d.days < 45` — the reference's own threshold.
  static const int soon = 45;

  LumeDocumentStanding get standing => switch (days) {
    null => LumeDocumentStanding.permanent,
    final int d when d < 0 => LumeDocumentStanding.expired,
    final int d when d < soon => LumeDocumentStanding.expiring,
    _ => LumeDocumentStanding.valid,
  };

  /// `d.days !== null && d.days < 45` — the "Needs attention" group, which
  /// takes the expired as well.
  bool get needsAttention => days != null && days! < soon;

  /// The day it expires, counted from [now].
  DateTime? expiresOn(DateTime now) =>
      days == null ? null : DateTime(now.year, now.month, now.day + days!);
}

/// `documents()` over `DOCUMENTS`.
class LumeDocumentVault {
  const LumeDocumentVault._();

  static const List<LumeVaultDocument> documents = <LumeVaultDocument>[
    LumeVaultDocument(
      title: LumeDocumentTitle.passport,
      category: LumeDocumentCategory.identity,
      reference: 'AB••••42',
      days: 918,
      holder: LumeDocumentHolder.you,
      files: 2,
    ),
    LumeVaultDocument(
      title: LumeDocumentTitle.nationalId,
      category: LumeDocumentCategory.identity,
      reference: '61101-•••••••-3',
      days: 440,
      holder: LumeDocumentHolder.you,
      files: 1,
    ),
    LumeVaultDocument(
      title: LumeDocumentTitle.licence,
      category: LumeDocumentCategory.vehicle,
      reference: 'DL-••••-118',
      days: 25,
      holder: LumeDocumentHolder.you,
      files: 1,
    ),
    LumeVaultDocument(
      title: LumeDocumentTitle.registration,
      category: LumeDocumentCategory.vehicle,
      reference: 'ABC-••4',
      days: 22,
      holder: LumeDocumentHolder.household,
      files: 3,
    ),
    LumeVaultDocument(
      title: LumeDocumentTitle.insurance,
      category: LumeDocumentCategory.insurance,
      reference: 'POL-••••-7781',
      days: 115,
      holder: LumeDocumentHolder.family,
      files: 2,
    ),
    LumeVaultDocument(
      title: LumeDocumentTitle.tenancy,
      category: LumeDocumentCategory.property,
      reference: null,
      days: 357,
      holder: LumeDocumentHolder.you,
      files: 4,
    ),
    LumeVaultDocument(
      title: LumeDocumentTitle.degree,
      category: LumeDocumentCategory.education,
      reference: null,
      days: null,
      holder: LumeDocumentHolder.you,
      files: 1,
    ),
  ];

  /// `expiring` — within 45 days and not yet past.
  static int get expiring => documents
      .where(
        (LumeVaultDocument d) => d.standing == LumeDocumentStanding.expiring,
      )
      .length;

  /// `expired`.
  static int get expired => documents
      .where(
        (LumeVaultDocument d) => d.standing == LumeDocumentStanding.expired,
      )
      .length;

  /// `files` — every file across the vault.
  static int get files =>
      documents.fold(0, (int a, LumeVaultDocument d) => a + d.files);

  /// `categories` — each category that holds a document, with its count, in
  /// the order the documents first name it.
  static List<(LumeDocumentCategory, int)> get categories {
    final Map<LumeDocumentCategory, int> n = <LumeDocumentCategory, int>{};
    for (final LumeVaultDocument d in documents) {
      n[d.category] = (n[d.category] ?? 0) + 1;
    }
    return <(LumeDocumentCategory, int)>[
      for (final MapEntry<LumeDocumentCategory, int> e in n.entries)
        (e.key, e.value),
    ];
  }
}
