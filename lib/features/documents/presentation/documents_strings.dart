/// The words Documents and its records draw that their data does not carry.
library;

import '../../../l10n/app_localizations.dart';
import '../data/documents_fixtures.dart';

abstract final class LumeDocumentsStrings {
  /// `rec.doc.<cat>` — the reference labels the dashboard's chips with the
  /// data's own English id ("Identity"); both lists use these (C75).
  static String category(AppLocalizations l, LumeDocumentCategory c) =>
      switch (c) {
        LumeDocumentCategory.identity => l.recDocIdentity,
        LumeDocumentCategory.vehicle => l.recDocVehicle,
        LumeDocumentCategory.insurance => l.recDocInsurance,
        LumeDocumentCategory.property => l.recDocProperty,
        LumeDocumentCategory.education => l.recDocEducation,
        LumeDocumentCategory.other => l.recDocOther,
      };

  static String title(AppLocalizations l, LumeDocumentTitle t) => switch (t) {
    LumeDocumentTitle.passport => l.docsFxPassport,
    LumeDocumentTitle.nationalId => l.docsFxNid,
    LumeDocumentTitle.licence => l.docsFxLicence,
    LumeDocumentTitle.registration => l.docsFxRegistration,
    LumeDocumentTitle.insurance => l.docsFxInsurance,
    LumeDocumentTitle.tenancy => l.docsFxTenancy,
    LumeDocumentTitle.degree => l.docsFxDegree,
  };

  static String holder(AppLocalizations l, LumeDocumentHolder h) => switch (h) {
    LumeDocumentHolder.you => l.recSeedYou,
    LumeDocumentHolder.household => l.docsHolderHousehold,
    LumeDocumentHolder.family => l.recSeedFamily,
  };

  /// The badge a standing carries: the dashboard's `documents()` badge, which
  /// names a document that does not expire.
  static String standing(AppLocalizations l, LumeDocumentStanding s) =>
      switch (s) {
        LumeDocumentStanding.expired => l.docsExpired,
        LumeDocumentStanding.expiring => l.docsExpiringSoonShort,
        LumeDocumentStanding.valid => l.docsValid,
        LumeDocumentStanding.permanent => l.docsNoExpiry,
      };

  /// A seeded record's `@key`, in the reader's language; anything else is the
  /// reader's own words and is returned as written.
  static String seeded(AppLocalizations l, Object? v) => switch (v) {
    '@passport' => l.recSeedPassport,
    '@nid' => l.recSeedNid,
    '@licence' => l.recSeedLicence,
    '@insurance' => l.recSeedInsurance,
    '@you' => l.recSeedYou,
    '@family' => l.recSeedFamily,
    null => '',
    _ => '$v',
  };
}
