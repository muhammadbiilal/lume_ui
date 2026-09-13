// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get a11yBack => 'رجوع';

  @override
  String get a11yMainNavigation => 'الرئيسية';

  @override
  String get a11ySearch => 'بحث';

  @override
  String get a11yShare => 'مشاركة';

  @override
  String get acctAboutText =>
      'تطبيق عالمي للحياة اليومية. مصمم ليعمل في أي مكان، بلغتك، وبالأجزاء التي اخترتها.';

  @override
  String get acctAboutTitle => 'عن Lume';

  @override
  String get acctAppearanceDark => 'داكن';

  @override
  String get acctAppearanceLight => 'فاتح';

  @override
  String get acctAppearanceSystem => 'حسب النظام';

  @override
  String get acctAppearanceTitle => 'المظهر';

  @override
  String get acctBuild => 'الإصدار البرمجي';

  @override
  String acctCatsOn(int n, int total) {
    return '$n من $total مفعّلة';
  }

  @override
  String get acctChangePassword => 'تغيير كلمة المرور';

  @override
  String get acctChangePasswordSub =>
      'لا يُسجَّل تاريخ آخر تغيير على هذا الجهاز';

  @override
  String get acctClock12 => '12 ساعة';

  @override
  String get acctClock24 => '24 ساعة';

  @override
  String get acctClockFormat => 'الساعة';

  @override
  String get acctCompleteCta => 'أضف اسمك';

  @override
  String get acctCompleteText => 'أضف اسمك حتى يتمكن Lume من تحيتك كما ينبغي.';

  @override
  String get acctCompleteTitle => 'أكمل ملفك الشخصي';

  @override
  String get acctCurrencyAuto => 'حسب منطقتي';

  @override
  String get acctCurrencyNote =>
      'بعض الأدوات تعرض السعر بعملة سوقها الخاصة على أي حال.';

  @override
  String get acctCurrencyTitle => 'العملة';

  @override
  String get acctDangerZone => 'منطقة الخطر';

  @override
  String get acctDataAccount => 'حسابك وجلساتك';

  @override
  String get acctDataNotes => 'الملاحظات والمهام والمصاريف والمتتبعات';

  @override
  String get acctDataNotify => 'إعدادات الإشعارات وسجلها';

  @override
  String get acctDataPrefs => 'التفضيلات والمنطقة واللغة';

  @override
  String get acctDataTools => 'الأدوات والمفضلات والشاشات الأخيرة';

  @override
  String get acctDeleteConfirmText => 'أدخل كلمة المرور لحذف الحساب.';

  @override
  String get acctDeleteConfirmTitle => 'أكّد أنك أنت';

  @override
  String get acctDeleteCta => 'احذف حسابي';

  @override
  String get acctDeleteFinalText => 'هذا يزيل الحساب نهائيًا. لا سبيل للرجوع.';

  @override
  String get acctDeleteFinalTitle => 'حذف حسابك؟';

  @override
  String get acctDeleteK1 =>
      'تبقى الملاحظات والمهام والمصاريف والتفضيلات على هذا الجهاز.';

  @override
  String get acctDeleteKeeps => 'ما الذي يبقى';

  @override
  String get acctDeleteRow => 'حذف الحساب';

  @override
  String get acctDeleteRowSub => 'إزالة حساب Lume الخاص بك نهائيًا';

  @override
  String get acctDeleteTitle => 'حذف الحساب';

  @override
  String get acctDeleteW1 => 'يُزال حسابك وبريدك الإلكتروني.';

  @override
  String get acctDeleteW2 => 'يتم تسجيل خروج كل جهاز مسجّل الدخول.';

  @override
  String get acctDeleteW3 => 'لا يمكن التراجع عن هذا.';

  @override
  String get acctDeleteWhat => 'ماذا يفعل هذا';

  @override
  String get acctDeleted => 'تم حذف الحساب';

  @override
  String get acctDeviceAndroid => 'هاتف أندرويد';

  @override
  String get acctDeviceBrowser => 'متصفح ويب';

  @override
  String get acctDeviceIos => 'آيفون';

  @override
  String get acctDeviceMac => 'ماك';

  @override
  String get acctDeviceWindows => 'حاسوب ويندوز';

  @override
  String get acctDiscardCta => 'تجاهل';

  @override
  String get acctDiscardText =>
      'لقد عدّلت هذه الشاشة دون حفظ. المغادرة الآن تفقد تلك التعديلات.';

  @override
  String get acctDiscardTitle => 'تجاهل تغييراتك؟';

  @override
  String get acctEditProfile => 'تعديل الملف الشخصي';

  @override
  String get acctEditSaved => 'تم تحديث الملف الشخصي';

  @override
  String get acctEditTitle => 'تعديل الملف الشخصي';

  @override
  String get acctEmailChanged => 'تم تحديث البريد الإلكتروني';

  @override
  String get acctEmailPending => 'بانتظار التحقق';

  @override
  String acctEmailPendingText(String email) {
    return 'يصبح $email عنوانك بمجرد التحقق منه.';
  }

  @override
  String get acctEmailTitle => 'البريد الإلكتروني';

  @override
  String get acctErrCurrentRequired => 'أدخل كلمة المرور الحالية.';

  @override
  String get acctErrCurrentWrong => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get acctErrNameRequired =>
      'أدخل اسمًا، أو اتركه فارغًا لاستخدام بريدك الإلكتروني.';

  @override
  String get acctErrPasswordSame => 'اختر كلمة مرور لم تستخدمها هنا من قبل.';

  @override
  String get acctErrPhoneInvalid => 'أدخل رقم هاتف يستطيع Lume قراءته.';

  @override
  String get acctErrPhotoTooBig =>
      'هذه الصورة أكبر من أن يحفظها هذا الجهاز. جرّب صورة أصغر.';

  @override
  String get acctErrStorage =>
      'تعذّر على Lume الحفظ على هذا الجهاز. تأكد من وجود مساحة فارغة وحاول مرة أخرى.';

  @override
  String get acctFavourites => 'مفضلاتك';

  @override
  String get acctFieldConfirmNew => 'تأكيد كلمة المرور الجديدة';

  @override
  String get acctFieldCurrent => 'كلمة المرور الحالية';

  @override
  String get acctFieldDisplayName => 'الاسم المعروض';

  @override
  String get acctFieldFirst => 'الاسم الأول';

  @override
  String get acctFieldLast => 'اسم العائلة';

  @override
  String get acctFieldNewEmail => 'البريد الإلكتروني الجديد';

  @override
  String get acctFieldPhone => 'الهاتف';

  @override
  String get acctGuestBadge => 'ضيف';

  @override
  String get acctGuestEditNote =>
      'يُحفظ هذا الاسم على هذا الجهاز. وإنشاء حساب ينقله معك.';

  @override
  String get acctGuestNotifText =>
      'كضيف، تخص التنبيهات هذا الجهاز وحده. وتسجيل الدخول لا يعرض لك أبدًا إشعارات حساب آخر.';

  @override
  String get acctGuestNotifTitle => 'الإشعارات على هذا الجهاز';

  @override
  String get acctGuestText =>
      'أنت تستخدم Lume كضيف. كل ما أعددته محفوظ على هذا الجهاز.';

  @override
  String get acctGuestTitle => 'مرحبًا بك في Lume';

  @override
  String get acctGuestWhy => 'أنشئ حسابًا لكي';

  @override
  String get acctGuestWhy1 => 'تحتفظ بـ Lume على كل أجهزتك';

  @override
  String get acctGuestWhy2 => 'تستعيد إعداداتك إذا فقدت هذا الهاتف';

  @override
  String get acctGuestWhy3 => 'تستخدم ميزات الحساب فور توفرها';

  @override
  String get acctHelpContact => 'أرسل ملاحظاتك';

  @override
  String get acctHelpText =>
      'Lume منتج من شاشة واحدة: كل شيء على بُعد نقرة أو نقرتين من الرئيسية.';

  @override
  String get acctHelpTitle => 'المساعدة';

  @override
  String get acctHelpTour => 'أعد جولة الترحيب';

  @override
  String get acctLanguageNote => 'تغيير اللغة لا يغيّر أي شيء كتبته.';

  @override
  String get acctLanguageTitle => 'اللغة';

  @override
  String acctLastSeen(String when) {
    return 'آخر ظهور $when';
  }

  @override
  String get acctLoggedOut => 'تم تسجيل الخروج';

  @override
  String get acctLogoutText =>
      'ستحتاج إلى تسجيل الدخول مجددًا للوصول إلى حسابك. وكل ما على هذا الجهاز يبقى في مكانه.';

  @override
  String get acctLogoutTitle => 'تسجيل الخروج؟';

  @override
  String acctMemberSince(String date) {
    return 'عضو منذ $date';
  }

  @override
  String get acctNameNote => 'هذا هو الاسم الذي يحييك به Lume.';

  @override
  String get acctNoFavourites => 'لا شيء محفوظ بعد';

  @override
  String get acctNoFavouritesText => 'اضغط النجمة على أي أداة لتظهر هنا.';

  @override
  String get acctNoOtherDevices => 'لا توجد أجهزة أخرى مسجّلة الدخول.';

  @override
  String get acctNothingChanged => 'لا شيء لحفظه بعد';

  @override
  String get acctPersonalTitle => 'المعلومات الشخصية';

  @override
  String get acctPhoneNote => 'اختياري. يُحفظ على هذا الجهاز.';

  @override
  String get acctPhoneSaved => 'تم حفظ رقم الهاتف';

  @override
  String get acctPhoneScope => 'ما الغرض من هذا';

  @override
  String get acctPhoneScopeText =>
      'يُحفظ على هذا الجهاز لتتمكن أداة من عرضه. لا يوجد في Lume تسجيل دخول أو استرداد عبر الهاتف، فهو لا يفعل شيئًا آخر.';

  @override
  String get acctPhoneTitle => 'رقم الهاتف';

  @override
  String get acctPhoto => 'صورة الملف الشخصي';

  @override
  String get acctPhotoAdd => 'أضف صورة';

  @override
  String get acctPhotoNote => 'اختياري. تُحفظ على هذا الجهاز.';

  @override
  String get acctPhotoRemove => 'أزل الصورة';

  @override
  String get acctPhotoReplace => 'استبدل الصورة';

  @override
  String get acctPrefsTitle => 'التفضيلات';

  @override
  String get acctPrivacyAnalytics => 'تحليلات الاستخدام';

  @override
  String get acctPrivacyAnalyticsSub =>
      'لا يجمع Lume أيًا منها. لا شيء لإيقافه.';

  @override
  String get acctPrivacyPersonal => 'التخصيص';

  @override
  String get acctPrivacyPersonalSub =>
      'استخدام ما تفعله في Lume لترتيب ما تراه';

  @override
  String get acctPrivacyPreview => 'معاينة الإشعارات';

  @override
  String get acctPrivacyPreviewSub => 'إظهار محتوى التنبيه على شاشة القفل';

  @override
  String get acctPrivacySensitive => 'المحتوى الحساس في المعاينات';

  @override
  String get acctPrivacySensitiveSub =>
      'تبقى الصحة والمال والمستندات مخفية حتى تُفتح';

  @override
  String get acctPrivacyTitle => 'الخصوصية';

  @override
  String get acctPushAsk => 'لم يُطلب بعد';

  @override
  String get acctPushDenied => 'محظورة في إعدادات جهازك';

  @override
  String get acctPushDeniedHelp =>
      'الإشعارات محظورة. اسمح بها لـ Lume من إعدادات جهازك.';

  @override
  String get acctPushGranted => 'مسموح بها على هذا الجهاز';

  @override
  String get acctPushOff => 'مغلقة';

  @override
  String get acctPushOn => 'مفعّلة';

  @override
  String get acctPushThanks => 'الإشعارات مفعّلة';

  @override
  String get acctPushUnsupported =>
      'لا يستطيع هذا الجهاز عرض الإشعارات الفورية';

  @override
  String get acctPwStrengthLabel => 'القوة';

  @override
  String get acctRegionChange => 'تغيير الدولة أو المدينة';

  @override
  String get acctRegionTitle => 'المنطقة والعملة';

  @override
  String get acctRegionWarn =>
      'قد يؤدي تغيير منطقتك إلى تحديث عملتك وأسواقك وعطلاتك وأرقام الطوارئ والخدمات المحلية.';

  @override
  String get acctRowAbout => 'عن Lume';

  @override
  String get acctRowAboutSub => 'الإصدار والتراخيص وشكر وتقدير';

  @override
  String get acctRowAppearance => 'المظهر';

  @override
  String get acctRowAppearanceSub => 'فاتح أو داكن أو حسب النظام';

  @override
  String get acctRowHelp => 'المساعدة';

  @override
  String get acctRowHelpSub => 'إجابات، وطريقة للتواصل معنا';

  @override
  String get acctRowInterests => 'اهتماماتك';

  @override
  String get acctRowInterestsSub => 'تشكّل صفحتك الرئيسية وأدواتك وقراءاتك';

  @override
  String get acctRowLanguage => 'اللغة';

  @override
  String get acctRowLibrary => 'مكتبتك';

  @override
  String get acctRowLibrarySub => 'القراءات المحفوظة والملاحظات والمفضلات';

  @override
  String get acctRowNotificationsSub =>
      'التنبيهات الفورية والتحديثات داخل التطبيق وساعات الهدوء';

  @override
  String get acctRowPersonal => 'المعلومات الشخصية';

  @override
  String get acctRowPersonalSub => 'الاسم والبريد والهاتف والمنطقة';

  @override
  String get acctRowPreferences => 'التفضيلات';

  @override
  String get acctRowPreferencesSub => 'اللغة والعملة والوحدات والوقت';

  @override
  String get acctRowPrivacy => 'الخصوصية';

  @override
  String get acctRowPrivacySub => 'ما يعرضه Lume ويحتفظ به ويشاركه';

  @override
  String get acctRowRegion => 'المنطقة والعملة';

  @override
  String get acctRowRegionSub => 'الدولة والمدينة والخدمات التابعة لهما';

  @override
  String get acctRowSecurity => 'الأمان';

  @override
  String get acctRowSecuritySub => 'كلمة المرور والجلسات وحماية الحساب';

  @override
  String get acctRowSync => 'البيانات والمزامنة';

  @override
  String get acctRowSyncSub => 'أين يُخزَّن كل جزء من Lume الخاص بك';

  @override
  String get acctRowTour => 'أعد جولة الترحيب';

  @override
  String get acctRowTourSub => 'تذكير سريع بما هو متاح هنا';

  @override
  String get acctSaveChanges => 'حفظ التغييرات';

  @override
  String get acctSecurityScope => 'ما الذي يحميه Lume';

  @override
  String get acctSecurityScopeText =>
      'كلمة مرورك وأجهزتك المسجّلة. لا توجد في هذا الإصدار مصادقة ثنائية ولا فتح بالبصمة، ولا شيء هنا يدّعي غير ذلك.';

  @override
  String get acctSecurityTitle => 'الأمان';

  @override
  String acctSessionsSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n جهازًا مسجّلًا',
      few: '$n أجهزة مسجّلة',
      two: 'جهازان مسجّلان',
      one: 'جهاز واحد مسجّل الدخول',
    );
    return '$_temp0';
  }

  @override
  String get acctSessionsTitle => 'الجلسات النشطة';

  @override
  String get acctSignOut => 'تسجيل الخروج';

  @override
  String get acctSignOutDevice => 'تسجيل الخروج';

  @override
  String get acctSignOutOthers => 'تسجيل الخروج من كل الأجهزة الأخرى';

  @override
  String get acctSignOutOthersText =>
      'سيحتاج كل جهاز آخر مسجّل الدخول إلى تسجيل الدخول من جديد.';

  @override
  String acctSignedInAs(String email) {
    return 'مسجّل الدخول بـ $email';
  }

  @override
  String acctSignedOutOthers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم تسجيل خروج $n جهازًا آخر',
      few: 'تم تسجيل خروج $n أجهزة أخرى',
      two: 'تم تسجيل خروج جهازين آخرين',
      one: 'تم تسجيل خروج جهاز واحد آخر',
    );
    return '$_temp0';
  }

  @override
  String get acctSince => 'عضو منذ';

  @override
  String get acctStatus => 'حالة الحساب';

  @override
  String get acctStatusActive => 'نشط';

  @override
  String get acctStatusLocked => 'مقفل';

  @override
  String get acctSupport => 'الدعم';

  @override
  String get acctSyncDevice => 'مخزَّن على هذا الجهاز';

  @override
  String get acctSyncNone =>
      'لا شيء يُزامَن بعد. لا يوجد خادم لـ Lume في هذا الإصدار، لذا يبقى كل ما في الأعلى على هذا الجهاز — بما في ذلك حسابك.';

  @override
  String get acctSyncSynced => 'مزامَن مع حسابك';

  @override
  String get acctSyncTitle => 'البيانات والمزامنة';

  @override
  String acctThemeSwitched(String mode) {
    return 'المظهر: $mode';
  }

  @override
  String get acctThisDevice => 'هذا الجهاز';

  @override
  String get acctTimeTitle => 'الوقت والمنطقة الزمنية';

  @override
  String get acctTimezoneAuto => 'حسب هذا الجهاز';

  @override
  String get acctTimezoneFollowRegion => 'حسب منطقتي';

  @override
  String get acctTimezoneNote =>
      'تستخدم الأسواق والرحلات والقطارات دائمًا منطقتها الزمنية الخاصة.';

  @override
  String get acctTimezoneTitle => 'الوقت';

  @override
  String get acctUnitsAuto => 'حسب منطقتي';

  @override
  String get acctUnitsImperial => 'إمبراطوري';

  @override
  String get acctUnitsMetric => 'متري';

  @override
  String get acctUnitsTitle => 'الوحدات';

  @override
  String get acctVersion => 'الإصدار';

  @override
  String get acctYourLume => 'حسابك في Lume';

  @override
  String get actionAdd => 'إضافة';

  @override
  String get actionAll => 'الكل';

  @override
  String get actionBack => 'رجوع';

  @override
  String get actionBookmark => 'حفظ';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionChange => 'تغيير';

  @override
  String get actionClear => 'مسح';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionConfirm => 'تأكيد';

  @override
  String get actionContinue => 'متابعة';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionDone => 'تم';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionGetStarted => 'ابدأ';

  @override
  String get actionLooksGood => 'ممتاز';

  @override
  String get actionNext => 'التالي';

  @override
  String get actionNotSet => 'غير محدد';

  @override
  String get actionRefresh => 'تحديث';

  @override
  String get actionRemove => 'إزالة';

  @override
  String get actionResend => 'إعادة الإرسال';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionSaveImage => 'حفظ الصورة';

  @override
  String get actionSearch => 'بحث';

  @override
  String get actionShare => 'مشاركة';

  @override
  String get actionSkip => 'تخطٍ';

  @override
  String get actionTryAgain => 'حاول مرة أخرى';

  @override
  String get actionVerify => 'تحقّق';

  @override
  String get actionWeek => 'أسبوع';

  @override
  String get agendaAdhanOn => 'الأذان · التذكير مفعّل';

  @override
  String get agendaGroceries => 'شراء البقالة';

  @override
  String get agendaGroceriesMeta => 'في الطريق إلى المنزل';

  @override
  String get agendaOutage => 'انقطاع';

  @override
  String agendaOutageMeta(String area, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      few: '$hours ساعات',
      two: 'ساعتان',
      one: 'ساعة',
    );
    return '$area · $_temp0';
  }

  @override
  String get agendaPrayed => 'صُلّيت';

  @override
  String get agendaReview => 'مراجعة التصميم';

  @override
  String get agendaReviewMeta => '45 دقيقة · غرفة الاجتماعات 2';

  @override
  String get agendaStandup => 'اجتماع الفريق';

  @override
  String get agendaStandupMeta => '15 دقيقة · مكالمة فيديو';

  @override
  String get anniversaryKind => 'ذكرى سنوية';

  @override
  String get appTagline => 'يومك في مكان واحد';

  @override
  String get authAsideText =>
      'الصلاة والطقس والمال والسفر والتفاصيل الصغيرة — أينما كنت.';

  @override
  String get authAsideTitle => 'تطبيق واحد ليومك المقبل.';

  @override
  String get authBackToSignIn => 'العودة إلى تسجيل الدخول';

  @override
  String get authContinue => 'متابعة';

  @override
  String get authContinueAsGuest => 'المتابعة كضيف';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authCreateOne => 'أنشئ واحدًا';

  @override
  String get authCreatedText => 'حساب Lume الخاص بك جاهز.';

  @override
  String authCreatedTextNamed(String name) {
    return 'حساب Lume الخاص بك جاهز يا $name.';
  }

  @override
  String get authCreatedTitle => 'كل شيء جاهز';

  @override
  String get authCreatingAccount => 'جارٍ إنشاء حسابك…';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authEnterCta => 'ادخل إلى Lume';

  @override
  String get authErrCodeExpired => 'انتهت صلاحية هذا الرمز. اطلب رمزًا جديدًا.';

  @override
  String get authErrCodeIncorrect => 'هذا الرمز غير صحيح.';

  @override
  String get authErrCodeRequired => 'أدخل الرمز الذي أرسلناه إليك.';

  @override
  String get authErrConfirmMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get authErrConfirmRequired => 'أكّد كلمة المرور.';

  @override
  String get authErrCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authErrEmailInvalid => 'لا يبدو هذا كعنوان بريد إلكتروني.';

  @override
  String get authErrEmailRequired => 'أدخل عنوان بريدك الإلكتروني.';

  @override
  String get authErrEmailSame => 'هذا هو عنوان بريدك الإلكتروني بالفعل.';

  @override
  String get authErrEmailTaken => 'يوجد حساب بالفعل لهذا البريد الإلكتروني.';

  @override
  String get authErrLinkExpired =>
      'انتهت صلاحية رابط إعادة التعيين. اطلب رابطًا جديدًا.';

  @override
  String get authErrLinkInvalid => 'لم يعد رابط إعادة التعيين هذا صالحًا.';

  @override
  String get authErrLocked => 'هذا الحساب مقفل. أعد تعيين كلمة المرور لفتحه.';

  @override
  String get authErrNetwork =>
      'تعذّر على Lume الوصول إلى الشبكة. لم يُفقد شيء.';

  @override
  String get authErrNothingPending =>
      'لا يوجد تغيير بريد إلكتروني قيد الانتظار.';

  @override
  String get authErrPasswordRequired => 'أدخل كلمة مرور.';

  @override
  String get authErrPasswordWeak => 'كلمة المرور لا تستوفي جميع الشروط بعد.';

  @override
  String get authErrRateLimited =>
      'محاولات كثيرة جدًا. انتظر لحظة ثم حاول مرة أخرى.';

  @override
  String get authErrSignedOut => 'أنت خارج الحساب. سجّل الدخول للمتابعة.';

  @override
  String get authErrStorage =>
      'تعذّر على Lume الحفظ على هذا الجهاز. تحقق من إعدادات التخزين وحاول مرة أخرى.';

  @override
  String get authExpiredCta => 'سجّل الدخول مرة أخرى';

  @override
  String get authExpiredText =>
      'سجّل الدخول مرة أخرى وسيعيدك Lume إلى حيث كنت.';

  @override
  String get authExpiredTitle => 'انتهت صلاحية جلستك';

  @override
  String get authFieldCode => 'رمز التحقق';

  @override
  String get authFieldConfirm => 'تأكيد كلمة المرور';

  @override
  String get authFieldEmail => 'البريد الإلكتروني';

  @override
  String get authFieldName => 'الاسم';

  @override
  String get authFieldNewPassword => 'كلمة المرور الجديدة';

  @override
  String get authFieldPassword => 'كلمة المرور';

  @override
  String get authForgotAction => 'نسيت كلمة المرور؟';

  @override
  String get authForgotCta => 'إرسال رابط إعادة التعيين';

  @override
  String get authForgotText =>
      'أدخل البريد الإلكتروني المرتبط بحساب Lume الخاص بك.';

  @override
  String get authForgotTitle => 'نسيت كلمة المرور؟';

  @override
  String get authHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authLegal =>
      'إنشاء حساب يعني أن Lume يحتفظ بهذه المعلومات من أجلك.';

  @override
  String get authLegalLink => 'كيف يتعامل Lume مع بياناتك';

  @override
  String authLocalCode(String code) {
    return 'لا يوجد خادم بريد في هذه النسخة. رمزك هو $code.';
  }

  @override
  String get authNameHint => 'حتى يعرف Lume بماذا يناديك.';

  @override
  String get authNeedAccountText => 'هذا الجزء من Lume يخص حسابك.';

  @override
  String get authNoAccount => 'ليس لديك حساب؟';

  @override
  String get authOpenLink => 'افتح رابط إعادة التعيين';

  @override
  String get authPasswordRuleDigit => 'رقم واحد';

  @override
  String get authPasswordRuleLength => '8 أحرف على الأقل';

  @override
  String get authPasswordRuleLower => 'حرف صغير واحد';

  @override
  String get authPasswordRuleUpper => 'حرف كبير واحد';

  @override
  String get authPasswordRulesTitle => 'يجب أن تحتوي كلمة المرور على';

  @override
  String get authRememberPassword => 'تتذكر كلمة المرور؟';

  @override
  String get authResend => 'أرسله مرة أخرى';

  @override
  String authResendIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'يمكنك الطلب مرة أخرى بعد $seconds ثانية',
      many: 'يمكنك الطلب مرة أخرى بعد $seconds ثانية',
      few: 'يمكنك الطلب مرة أخرى بعد $seconds ثوانٍ',
      two: 'يمكنك الطلب مرة أخرى بعد ثانيتين',
      one: 'يمكنك الطلب مرة أخرى بعد ثانية',
      zero: 'يمكنك الطلب مرة أخرى الآن',
    );
    return '$_temp0';
  }

  @override
  String get authResendNone => 'لم يصلك؟';

  @override
  String get authResetCta => 'تحديث كلمة المرور';

  @override
  String get authResetText => 'اختر كلمة مرور لم تستخدمها هنا من قبل.';

  @override
  String get authResetTitle => 'أنشئ كلمة مرور جديدة';

  @override
  String get authSentLocal =>
      'لا يوجد خادم بريد في هذه النسخة، لذا يُفتح الرابط هنا.';

  @override
  String get authSentNote => 'يظل الرابط صالحًا لمدة ساعة واحدة.';

  @override
  String get authSentText =>
      'إذا كان هناك حساب لهذا البريد الإلكتروني، فقد أرسلنا تعليمات إعادة تعيين كلمة المرور.';

  @override
  String get authSentTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authSignInText => 'تابع إلى Lume الخاص بك.';

  @override
  String get authSignInTitle => 'مرحبًا بعودتك';

  @override
  String get authSignUpPasswordText => 'هذا ما يبقي Lume ملكًا لك.';

  @override
  String get authSignUpPasswordTitle => 'اختر كلمة مرور';

  @override
  String get authSignUpText =>
      'Lume الخاص بك، محفوظ ويمكن الوصول إليه من أي مكان.';

  @override
  String get authSignUpTitle => 'أنشئ حساب Lume الخاص بك';

  @override
  String get authSigningIn => 'جارٍ تسجيل دخولك…';

  @override
  String authStepOf(int n, int total) {
    return 'الخطوة $n من $total';
  }

  @override
  String get authStrength0 => 'أدخل كلمة مرور';

  @override
  String get authStrength1 => 'ضعيفة';

  @override
  String get authStrength2 => 'مقبولة';

  @override
  String get authStrength3 => 'جيدة';

  @override
  String get authStrength4 => 'قوية';

  @override
  String get authTroubleCta => 'اطلب رابطًا جديدًا';

  @override
  String get authTroubleExpired =>
      'تتوقف روابط الاسترداد عن العمل بعد ساعة، لذا انتهت صلاحية هذا الرابط. اطلب رابطًا جديدًا وسيصلك بالطريقة نفسها.';

  @override
  String get authTroubleText =>
      'يمكن استخدام رابط الاسترداد مرة واحدة فقط، ومن العنوان الذي أُرسل إليه فقط. اطلب رابطًا جديدًا وسيصلك بالطريقة نفسها.';

  @override
  String get authTroubleTitle => 'لم يعمل هذا الرابط';

  @override
  String get authUpdatedText => 'يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.';

  @override
  String get authUpdatedTitle => 'تم تحديث كلمة المرور';

  @override
  String get authVerifyCta => 'تأكيد البريد الإلكتروني';

  @override
  String get authVerifyText => 'أرسلنا رمزًا من ستة أرقام إلى';

  @override
  String get authVerifyTitle => 'تحقق من صندوق الوارد';

  @override
  String authWelcomeBack(String name) {
    return 'مرحبًا بعودتك يا $name';
  }

  @override
  String get authWorking => 'لحظة واحدة…';

  @override
  String billsDueIn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'مستحق خلال $n يومًا',
      few: 'مستحق خلال $n أيام',
      two: 'مستحق خلال يومين',
      one: 'مستحق خلال يوم',
    );
    return '$_temp0';
  }

  @override
  String get billsDueThisMonth => 'مستحق هذا الشهر';

  @override
  String billsNeedAttention(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n فاتورة تحتاج انتباهك',
      few: '$n فواتير تحتاج انتباهك',
      two: 'فاتورتان تحتاجان انتباهك',
      one: 'فاتورة واحدة تحتاج انتباهك',
    );
    return '$_temp0';
  }

  @override
  String billsOverdueBy(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'متأخر $n يومًا',
      few: 'متأخر $n أيام',
      two: 'متأخر يومين',
      one: 'متأخر يومًا',
    );
    return '$_temp0';
  }

  @override
  String get birthdayKind => 'عيد ميلاد';

  @override
  String get collectionBudget => 'أساسيات الميزانية';

  @override
  String collectionBudgetMeta(int n) {
    return '$n دروس';
  }

  @override
  String get collectionFocus => 'أصوات التركيز';

  @override
  String collectionFocusMeta(int n) {
    return '$n مقاطع';
  }

  @override
  String get collectionGratitude => 'محفّزات الامتنان';

  @override
  String collectionGratitudeMeta(int n) {
    return '$n يومًا';
  }

  @override
  String get collectionNightSurahs => 'سور الليل';

  @override
  String collectionNightSurahsMeta(int surahs, int minutes) {
    return '$surahs سور · $minutes دقيقة';
  }

  @override
  String get commonAll => 'الكل';

  @override
  String get commonDays => 'أيام';

  @override
  String get commonDone => 'تم';

  @override
  String get commonDue => 'مستحق';

  @override
  String get commonExport => 'تصدير';

  @override
  String get commonHistory => 'السجل';

  @override
  String commonInDays(Object n) {
    return 'خلال $n يومًا';
  }

  @override
  String get commonLocked => 'مقفل';

  @override
  String get commonMonth => 'شهر';

  @override
  String get commonNo => 'لا';

  @override
  String get commonNow => 'الآن';

  @override
  String get commonOffline => 'غير متصل';

  @override
  String get commonOptional => 'اختياري';

  @override
  String get commonOr => 'أو';

  @override
  String get commonOverdue => 'متأخر';

  @override
  String get commonPaid => 'مدفوع';

  @override
  String get commonReset => 'إعادة';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonShare => 'مشاركة';

  @override
  String get commonSort => 'ترتيب';

  @override
  String get commonStale => 'غير محدَّث';

  @override
  String get commonStatus => 'الحالة';

  @override
  String get commonThisMonth => 'هذا الشهر';

  @override
  String get commonToday => 'اليوم';

  @override
  String get commonTomorrow => 'غدًا';

  @override
  String get commonTotal => 'الإجمالي';

  @override
  String get commonWeek => 'أسبوع';

  @override
  String get commonYear => 'سنة';

  @override
  String get commonYes => 'نعم';

  @override
  String get commonYesterday => 'أمس';

  @override
  String cricketScore(String team, int runs, int wickets) {
    return '$team $runs/$wickets';
  }

  @override
  String cricketSecondTest(int n) {
    return 'الاختبار الثاني · اليوم $n';
  }

  @override
  String get discoverDuasMeta => 'لأيامك العادية';

  @override
  String get discoverDuasTitle => 'أربعون دعاءً';

  @override
  String docsRenewSoon(String name) {
    return 'جدّد $name';
  }

  @override
  String get exploreAround => 'حولك';

  @override
  String get exploreAroundSub => 'خدمات محلية محدَّثة';

  @override
  String get exploreBackToHome => 'العودة إلى الرئيسية';

  @override
  String get exploreCollections => 'المجموعات';

  @override
  String get exploreCollectionsSub => 'مختارة للحظة هدوء';

  @override
  String get exploreCricket => 'الكريكيت';

  @override
  String get exploreCricketSub => 'مباشر · الاختبار الثاني، اليوم 2';

  @override
  String get exploreFeatured => 'مجموعة مميزة';

  @override
  String get exploreNearby => 'قريب منك';

  @override
  String get exploreNearbySub => 'على مسافة مشي';

  @override
  String exploreRainLabel(String value) {
    return 'المطر $value';
  }

  @override
  String get exploreReads => 'قراءات اليوم';

  @override
  String get exploreReadsSub => 'متوازنة وبلا ضجيج';

  @override
  String get exploreScorecard => 'بطاقة النتائج';

  @override
  String get exploreSubGlobal => 'الطقس والقراءة وما حولك';

  @override
  String get exploreSubLocal => 'الخدمات المحلية والنتائج والقراءة';

  @override
  String exploreSunsetLabel(String value) {
    return 'الغروب $value';
  }

  @override
  String get exploreWeather => 'الطقس';

  @override
  String exploreWeatherDesc(String condition, String feels) {
    return '$condition · $feels';
  }

  @override
  String exploreWeatherSub(String city, int n) {
    return '$city · حُدِّث قبل $n دقيقة';
  }

  @override
  String get exploreWeatherToast => 'تم تحديث الطقس';

  @override
  String exploreWindLabel(String value) {
    return 'الرياح $value';
  }

  @override
  String exploreWindValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get featureAge => 'حاسبة العمر';

  @override
  String get featureAlarms => 'المنبهات';

  @override
  String get featureAqi => 'جودة الهواء';

  @override
  String get featureAyah => 'آية اليوم';

  @override
  String get featureBabybudget => 'ميزانية الطفل';

  @override
  String get featureBills => 'الفواتير';

  @override
  String get featureBirthdays => 'أعياد الميلاد';

  @override
  String get featureBmi => 'حاسبة كتلة الجسم';

  @override
  String get featureCalculator => 'الآلة الحاسبة';

  @override
  String get featureCalendar => 'التقويم';

  @override
  String get featureCommittee => 'الجمعية';

  @override
  String get featureCompound => 'الفائدة المركّبة';

  @override
  String get featureConverter => 'محوّل الوحدات';

  @override
  String get featureCricket => 'الكريكيت';

  @override
  String get featureCurrency => 'العملات';

  @override
  String get featureCycle => 'متابعة الدورة';

  @override
  String get featureDatecalc => 'حاسبة التواريخ';

  @override
  String get featureDocscan => 'ماسح المستندات';

  @override
  String get featureDocuments => 'المستندات';

  @override
  String get featureDuas => 'الأدعية';

  @override
  String get featureEmergency => 'الطوارئ';

  @override
  String get featureEvents => 'المواعيد';

  @override
  String get featureExpenses => 'المصروفات';

  @override
  String get featureFaraid => 'الفرائض';

  @override
  String get featureFasting => 'متابعة الصيام';

  @override
  String get featureFlights => 'الرحلات';

  @override
  String get featureFocus => 'مؤقّت التركيز';

  @override
  String get featureFuel => 'أسعار الوقود';

  @override
  String get featureFuelcost => 'تكلفة الرحلة';

  @override
  String get featureGoals => 'أهداف الادخار';

  @override
  String get featureGoldrates => 'العملات والذهب';

  @override
  String get featureHabits => 'العادات';

  @override
  String get featureHadith => 'الحديث';

  @override
  String get featureHealth => 'السجلات الصحية';

  @override
  String get featureHijri => 'التقويم الهجري';

  @override
  String get featureHolidays => 'العطل الرسمية';

  @override
  String get featureInstallments => 'الأقساط';

  @override
  String get featureLearning => 'التعلّم';

  @override
  String get featureLedger => 'دفتر الديون';

  @override
  String get featureLoadshed => 'انقطاع الكهرباء';

  @override
  String get featureLoan => 'القرض والأقساط';

  @override
  String get featureMarkets => 'الأسواق';

  @override
  String get featureMealplan => 'خطة الوجبات';

  @override
  String get featureMediasaver => 'حافظ الوسائط';

  @override
  String get featureMeds => 'الأدوية';

  @override
  String get featureMosques => 'المساجد القريبة';

  @override
  String get featureNames99 => 'أسماء الله الحسنى';

  @override
  String get featureNatsavings => 'الادخار الوطني';

  @override
  String get featureNews => 'الأخبار';

  @override
  String get featureNotes => 'الملاحظات';

  @override
  String get featurePackages => 'باقات الجوال';

  @override
  String get featureParcel => 'تتبّع الطرود';

  @override
  String get featurePassport => 'صور جواز السفر';

  @override
  String get featurePlay => 'ألعاب';

  @override
  String get featurePrayer => 'مواقيت الصلاة';

  @override
  String get featurePraytrack => 'متابعة الصلاة';

  @override
  String get featurePregnancy => 'الحمل';

  @override
  String get featurePrizebonds => 'سندات الجوائز';

  @override
  String get featureQibla => 'اتجاه القبلة';

  @override
  String get featureQr => 'ماسح QR';

  @override
  String get featureQuran => 'القرآن الكريم';

  @override
  String get featureQuransearch => 'البحث في القرآن';

  @override
  String get featureRamadan => 'رمضان';

  @override
  String get featureRecipes => 'الوصفات';

  @override
  String get featureReminders => 'التذكيرات';

  @override
  String get featureShopping => 'قائمة التسوق';

  @override
  String get featureSpeedtest => 'اختبار السرعة';

  @override
  String get featureStopwatch => 'ساعة الإيقاف';

  @override
  String get featureStreak => 'التتابع اليومي';

  @override
  String get featureSubs => 'الاشتراكات';

  @override
  String get featureSunmoon => 'الشمس والقمر';

  @override
  String get featureTaraweeh => 'التراويح';

  @override
  String get featureTasbih => 'المسبحة';

  @override
  String get featureTax => 'حاسبة الضريبة';

  @override
  String get featureTimer => 'المؤقّت';

  @override
  String get featureTipsplit => 'تقسيم الفاتورة';

  @override
  String get featureTodos => 'المهام';

  @override
  String get featureTrains => 'القطارات';

  @override
  String get featureVaccines => 'التطعيمات';

  @override
  String get featureVehicle => 'المركبات والمخالفات';

  @override
  String get featureWastatus => 'حالات واتساب';

  @override
  String get featureWater => 'الماء';

  @override
  String get featureWeather => 'الطقس';

  @override
  String get featureWorldclock => 'الساعة العالمية';

  @override
  String get featureZakat => 'حاسبة الزكاة';

  @override
  String featuredCalmDays(int n) {
    return '$n أيام';
  }

  @override
  String featuredCalmEach(int n) {
    return '$n دقائق لكل خطوة';
  }

  @override
  String get featuredCalmText =>
      'روتين صغير للتخطيط والإنفاق والاسترخاء — واحد لكل يوم.';

  @override
  String get featuredCalmTitle => 'أسبوع أهدأ، في سبع خطوات';

  @override
  String get featuredDuasAudio => 'مع تسجيل صوتي';

  @override
  String featuredDuasCount(int n) {
    return '$n دعاء';
  }

  @override
  String get featuredDuasText =>
      'أدعية قصيرة للطريق وللانتظار وللدقيقة الهادئة قبل النوم.';

  @override
  String get featuredDuasTitle => 'أربعون دعاءً لأيامك العادية';

  @override
  String get featuredFree => 'مجانًا';

  @override
  String featuredMinutes(int n) {
    return '$n دقيقة';
  }

  @override
  String get fuelPetrol => 'بنزين';

  @override
  String get fuelSourceOgra => 'أوغرا';

  @override
  String get greetAfternoon => 'مساء الخير';

  @override
  String get greetEvening => 'مساء الخير';

  @override
  String get greetLate => 'ما زلت مستيقظًا';

  @override
  String get greetMorning => 'صباح الخير';

  @override
  String greetNamed(String greeting, String name) {
    return '$greeting، $name';
  }

  @override
  String get greetWindDown => 'نهاية اليوم';

  @override
  String get habitFajr => 'الفجر في وقته';

  @override
  String get habitQuran => 'القرآن يوميًا';

  @override
  String get habitSteps => 'المشي 6 آلاف خطوة';

  @override
  String get habitWater => '8 أكواب';

  @override
  String get heroHighlights => 'أبرز الأمور';

  @override
  String homeAyahProgress(int n, int total, int min) {
    return 'الآية $n من $total · يتبقّى نحو $min دقيقة';
  }

  @override
  String homeContinueSurah(String surah) {
    return 'تابع $surah';
  }

  @override
  String get homeDiscover => 'اكتشف';

  @override
  String get homeDiscoverSub => 'لأنك تتابع هذه كثيرًا';

  @override
  String homeEffective(String date, String source) {
    return 'سارٍ من $date · $source';
  }

  @override
  String homeFeelsLike(String temp) {
    return 'الإحساس $temp';
  }

  @override
  String get homeGlance => 'لمحة سريعة';

  @override
  String get homeGlanceGeneral => 'ما يهمّ في الساعات القليلة القادمة';

  @override
  String get homeGlanceMuslim => 'الصلاة والقراءة وما هو قادم';

  @override
  String get homeLiveNow => 'الآن';

  @override
  String homeLiveNowSub(String time) {
    return 'حتى $time';
  }

  @override
  String homeNextOutage(String time) {
    return 'الانقطاع القادم $time';
  }

  @override
  String get homeNextPrayer => 'الصلاة القادمة';

  @override
  String get homeNextUp => 'التالي';

  @override
  String homeOutageArea(String area, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      few: '$hours ساعات',
      two: 'ساعتان',
      one: 'ساعة',
    );
    return '$area · $_temp0';
  }

  @override
  String get homeQuickDefault => 'الثمانية الأكثر استخدامًا';

  @override
  String get homeQuickFromInterests => 'مختارة حسب اهتماماتك';

  @override
  String get homeQuickTools => 'أدوات سريعة';

  @override
  String get homeRightNow => 'الآن';

  @override
  String get homeSearchEverything => 'ابحث في كل شيء';

  @override
  String homeTasksLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'بقيت $n مهمة اليوم',
      few: 'بقيت $n مهام اليوم',
      two: 'بقيت مهمتان اليوم',
      one: 'بقيت مهمة واحدة اليوم',
      zero: 'لم يتبقّ شيء اليوم',
    );
    return '$_temp0';
  }

  @override
  String homeTasksNext(String task, String time) {
    return 'التالي: $task · $time';
  }

  @override
  String get homeToGo => 'متبقٍ';

  @override
  String homeTomorrowIn(String city) {
    return 'غدًا في $city';
  }

  @override
  String get homeUpcoming => 'قادم';

  @override
  String get homeUpcomingSub => 'الأيام القليلة القادمة';

  @override
  String homeWeatherAnd(String temp, String condition) {
    return '$temp و$condition';
  }

  @override
  String get homeYourProfile => 'حسابك';

  @override
  String get igEveryday => 'الحياة اليومية';

  @override
  String get igFaith => 'الميزات الإسلامية';

  @override
  String get igHealth => 'الصحة والعافية';

  @override
  String get igMoney => 'المال والتمويل';

  @override
  String get igNews => 'الأخبار والترفيه';

  @override
  String get igTravel => 'السفر والتنقل';

  @override
  String get intAlarms => 'المنبهات والمؤقتات';

  @override
  String get intBills => 'الفواتير';

  @override
  String get intCalendar => 'التقويم';

  @override
  String get intConvert => 'المحوّلات';

  @override
  String get intCricket => 'الكريكيت';

  @override
  String get intDuas => 'الأدعية والأذكار';

  @override
  String get intExpenses => 'المصروفات';

  @override
  String get intFitness => 'اللياقة';

  @override
  String get intFlights => 'الرحلات الجوية';

  @override
  String get intFuel => 'الوقود';

  @override
  String get intHabits => 'العادات';

  @override
  String get intHadith => 'الحديث';

  @override
  String get intMarkets => 'الأسواق';

  @override
  String get intMaths => 'الآلات الحاسبة';

  @override
  String get intMeds => 'الأدوية';

  @override
  String get intNearby => 'الأماكن القريبة';

  @override
  String get intNews => 'الأخبار';

  @override
  String get intNotes => 'الملاحظات';

  @override
  String get intPrayer => 'مواقيت الصلاة';

  @override
  String get intQuotes => 'اقتباسات يومية';

  @override
  String get intQuran => 'القرآن';

  @override
  String get intRamadan => 'رمضان';

  @override
  String get intRates => 'الأسعار والذهب';

  @override
  String get intReading => 'القراءة';

  @override
  String get intSavings => 'الادخار والأهداف';

  @override
  String get intSleep => 'النوم';

  @override
  String get intTasks => 'المهام وقوائم العمل';

  @override
  String get intTrains => 'القطارات';

  @override
  String get intWater => 'الماء';

  @override
  String get intWeather => 'الطقس';

  @override
  String get intZakat => 'الزكاة والصدقة';

  @override
  String get loadshedOff => 'الكهرباء مقطوعة';

  @override
  String loadshedUntil(String time) {
    return 'حتى $time';
  }

  @override
  String get marketPk => 'باكستان';

  @override
  String get marketsClosed => 'السوق مغلق';

  @override
  String marketsHoliday(String holiday) {
    return 'مغلق بمناسبة $holiday';
  }

  @override
  String get marketsOpen => 'السوق مفتوح';

  @override
  String get marketsWeekend => 'مغلق لعطلة نهاية الأسبوع';

  @override
  String get methodEgyptian => 'المصرية';

  @override
  String get methodIsna => 'ISNA';

  @override
  String get methodKarachi => 'جامعة كراتشي';

  @override
  String get methodMwl => 'رابطة العالم الإسلامي';

  @override
  String get methodUmmAlQura => 'أم القرى';

  @override
  String get nActComplete => 'وضع علامة تم';

  @override
  String get nActPay => 'ادفع';

  @override
  String get nActTrack => 'تتبّع';

  @override
  String get nActViewDoc => 'عرض المستند';

  @override
  String get nActViewFlight => 'عرض الرحلة';

  @override
  String get nActViewMarket => 'عرض السوق';

  @override
  String get nActViewPrayer => 'عرض مواقيت الصلاة';

  @override
  String get nActViewTrain => 'عرض القطار';

  @override
  String get nActViewWeather => 'عرض التوقعات';

  @override
  String get nActioned => 'تم';

  @override
  String get nAllRead => 'لقد اطّلعت على كل شيء';

  @override
  String get nCategory => 'الفئة';

  @override
  String nDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قبل $n يوم',
      few: 'قبل $n أيام',
      two: 'قبل يومين',
      one: 'قبل يوم',
    );
    return '$_temp0';
  }

  @override
  String get nDismiss => 'إخفاء';

  @override
  String get nEmptyCaughtUp => 'لقد اطّلعت على كل شيء';

  @override
  String get nEmptyText => 'ستظهر التنبيهات والتحديثات الجديدة هنا.';

  @override
  String get nEmptyTitle => 'لا شيء لإخبارك به';

  @override
  String get nErrorText => 'لم يُفقد شيء. حاول مرة أخرى.';

  @override
  String get nErrorTitle => 'تعذّر تحميل الإشعارات';

  @override
  String get nExpired => 'انتهت';

  @override
  String get nFixtureNote =>
      'هذه تنبيهات نموذجية. لا يوجد خادم إشعارات في هذا الإصدار، لذلك لم يُرسل شيء هنا ولن يصل شيء جديد.';

  @override
  String nGroupBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n تحديثًا إضافيًا',
      few: '$n تحديثات إضافية',
      two: 'تحديثان إضافيان',
      one: 'تحديث إضافي',
    );
    return '$_temp0';
  }

  @override
  String nGroupTitle(String name) {
    return 'نشاط $name';
  }

  @override
  String get nHidden => 'المحتوى مخفي';

  @override
  String nHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قبل $n ساعة',
      few: 'قبل $n ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة',
    );
    return '$_temp0';
  }

  @override
  String get nMarkAllRead => 'وضع علامة مقروء على الكل';

  @override
  String nMinsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قبل $n دقيقة',
      few: 'قبل $n دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get nNow => 'الآن';

  @override
  String get nPriCritical => 'حرج';

  @override
  String get nPriHigh => 'مهم';

  @override
  String get nPushAllow => 'تفعيل الإشعارات';

  @override
  String get nPushNotNow => 'ليس الآن';

  @override
  String get nPushOff => 'معطّلة';

  @override
  String get nPushOn => 'مفعّلة';

  @override
  String get nPushText => 'تنبيهات مفيدة لما تتابعه بالفعل — ولا شيء غير ذلك.';

  @override
  String get nPushTitle => 'ابقَ على اطلاع';

  @override
  String get nQuietText => 'لن يقاطعك شيء، لكن كل شيء يصل إلى هنا.';

  @override
  String get nQuietTitle => 'ساعات الهدوء مفعّلة';

  @override
  String get nSettings => 'إعدادات الإشعارات';

  @override
  String get nTabImportant => 'مهم';

  @override
  String get nTabUnread => 'غير مقروءة';

  @override
  String get nUnread => 'غير مقروء';

  @override
  String nUnreadCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n غير مقروء',
      few: '$n غير مقروءة',
      two: 'اثنان غير مقروءين',
      one: 'واحد غير مقروء',
    );
    return '$_temp0';
  }

  @override
  String get navAccount => 'الحساب';

  @override
  String get navExplore => 'استكشاف';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navNotifications => 'الإشعارات';

  @override
  String get navProfile => 'الحساب';

  @override
  String get navToday => 'اليوم';

  @override
  String get navTools => 'الأدوات';

  @override
  String get navTrains => 'القطارات';

  @override
  String get ncatDocuments => 'المستندات';

  @override
  String get ncatFaith => 'الإيمان';

  @override
  String get ncatFinance => 'المال';

  @override
  String get ncatHealth => 'الصحة';

  @override
  String get ncatMarkets => 'الأسواق';

  @override
  String get ncatNews => 'الأخبار';

  @override
  String get ncatPersonal => 'شخصي';

  @override
  String get ncatReminders => 'التذكيرات';

  @override
  String get ncatSystem => 'النظام';

  @override
  String get ncatTravel => 'السفر';

  @override
  String get ncatWeather => 'الطقس';

  @override
  String get nearbyChaiShai => 'تشاي شاي';

  @override
  String nearbyChaiShaiSub(String time) {
    return 'مقهى هادئ · مفتوح حتى $time';
  }

  @override
  String get nearbyHillPark => 'حديقة هيل';

  @override
  String get nearbyHillParkSub => 'مناسبة لنزهة عند الغروب';

  @override
  String nearbyKilometres(String n) {
    return '$n كم';
  }

  @override
  String nearbyMetres(int n) {
    return '$n م';
  }

  @override
  String get nearbyTooba => 'مسجد طوبى';

  @override
  String nearbyToobaSub(String time) {
    return 'جماعة العصر عند $time';
  }

  @override
  String get newsCatBusiness => 'أعمال';

  @override
  String get newsCatKarachi => 'كراتشي';

  @override
  String get newsCatMoney => 'مال';

  @override
  String get newsCatProductivity => 'إنتاجية';

  @override
  String get newsCatSport => 'رياضة';

  @override
  String get newsCatWellbeing => 'صحة ورفاهية';

  @override
  String get newsLoadshed =>
      'كي إلكتريك تعلن جدول انقطاع الكهرباء المعدّل لشهر سبتمبر';

  @override
  String newsReadTime(int n) {
    return 'قراءة $n دقائق';
  }

  @override
  String get newsReset => 'استراحة الدقيقتين التي تتفوّق على فنجان القهوة';

  @override
  String get newsRupee => 'الروبية تستقر مع ارتفاع التحويلات للشهر الثالث';

  @override
  String get newsSavings => 'دليل مبسّط لأول هدف ادخاري لك';

  @override
  String get newsShortList => 'لماذا تُنجز القائمة الأقصر عملًا أكثر';

  @override
  String get newsSquad => 'باكستان تعلن تشكيلتها لسلسلة الاختبار على أرضها';

  @override
  String get notifPrefBadge => 'عدّاد الشارة';

  @override
  String get notifPrefBadgeSub => 'إظهار عدد غير المقروء على الجرس';

  @override
  String get notifPrefCategories => 'الفئات';

  @override
  String get notifPrefCategoriesSub => 'أوقف أي شيء لا تريد سماعه';

  @override
  String get notifPrefGeneral => 'عام';

  @override
  String get notifPrefHaptics => 'الاهتزاز';

  @override
  String get notifPrefInApp => 'الإشعارات داخل التطبيق';

  @override
  String get notifPrefInAppSub => 'اللافتات ومركز الإشعارات';

  @override
  String get notifPrefPerTool => 'حسب الأداة';

  @override
  String get notifPrefPerToolSub => 'تحكّم دقيق في كل نوع من التنبيهات';

  @override
  String get notifPrefPreview => 'إظهار المعاينات';

  @override
  String get notifPrefPreviewSub => 'تضمين التفاصيل، لا العنوان فقط';

  @override
  String get notifPrefPrivacySub => 'ما الذي يُسمح للإشعار بكشفه';

  @override
  String get notifPrefPush => 'الإشعارات الفورية';

  @override
  String get notifPrefQuiet => 'ساعات الهدوء';

  @override
  String get notifPrefQuietOn => 'ساعات الهدوء';

  @override
  String get notifPrefQuietSub => 'لا شيء يقاطعك؛ وكل شيء يصلك رغم ذلك';

  @override
  String get notifPrefRestore => 'استعادة المستبعدة';

  @override
  String get notifPrefSensitive => 'معاينة المحتوى الحساس';

  @override
  String get notifPrefSensitiveSub =>
      'الصحة والمستندات والمال تقول فقط إن شيئًا ما تغيّر';

  @override
  String get notifPrefSound => 'الصوت';

  @override
  String get ntypeBillDue => 'فواتير تستحق قريبًا';

  @override
  String get ntypeBillOverdue => 'فواتير متأخرة';

  @override
  String get ntypeDocExpiry => 'انتهاء صلاحية مستند';

  @override
  String get ntypeFlightChange => 'تغييرات الرحلة';

  @override
  String get ntypeForecast => 'توقعات يومية';

  @override
  String get ntypeHabitReminder => 'تذكيرات العادات';

  @override
  String get ntypeMarketMove => 'حركة السوق';

  @override
  String get ntypeMedication => 'تذكيرات الدواء';

  @override
  String get ntypeOutage => 'انقطاع الكهرباء';

  @override
  String get ntypeParcelUpdate => 'تحديثات الطرد';

  @override
  String get ntypePrayerReminder => 'تذكير الصلاة';

  @override
  String get ntypeSevereWeather => 'طقس قاسٍ';

  @override
  String get ntypeSubRenewal => 'تجديد الاشتراكات';

  @override
  String get ntypeTaskReminder => 'تذكيرات المهام';

  @override
  String get ntypeTrainDelay => 'تأخر القطارات';

  @override
  String get onbAllSet => 'كل شيء جاهز';

  @override
  String onbAtCap(String max) {
    return 'حتى $max — أزل واحدًا أولًا';
  }

  @override
  String get onbCityText =>
      'يُستخدم للطقس، ومواقيت الصلاة حيثما كان ذلك مناسبًا، ولكل ما هو محلي.';

  @override
  String get onbCityTitle => 'في أي مدينة أنت؟';

  @override
  String get onbEnterLume => 'ادخل إلى Lume';

  @override
  String get onbHereForText =>
      'اختر من خمسة إلى عشرة. تُبنى شاشتك الرئيسية وأدواتك وقراءتك حولها — وبإمكانك تغييرها متى شئت.';

  @override
  String get onbHereForTitle => 'ما الذي جاء بك إلى هنا؟';

  @override
  String get onbLocalKicker => 'اجعله محليًا';

  @override
  String get onbMethodLabel => 'طريقة حساب مواقيت الصلاة';

  @override
  String onbMinimum(String count, String min) {
    return '$count من $min كحد أدنى';
  }

  @override
  String get onbNameKicker => 'أمر أخير';

  @override
  String get onbNameLabel => 'الاسم المعروض';

  @override
  String get onbNameNote => 'يحتفظ Lume بهذا على جهازك.';

  @override
  String get onbNamePlaceholder => 'اسمك';

  @override
  String get onbNameSkip => 'تخطي الآن';

  @override
  String get onbNameText => 'للتحية فقط. يمكنك تغييره لاحقًا أو تخطيه.';

  @override
  String get onbNameTitle => 'بماذا نناديك؟';

  @override
  String get onbOnDevice => 'يحتفظ Lume بهذا على جهازك. لا يُرفع شيء.';

  @override
  String get onbPermLocation => 'استخدام موقعك';

  @override
  String get onbPermLocationSub => 'للطقس والخدمات المحلية والأماكن القريبة';

  @override
  String get onbPermLocationSubFaith =>
      'لمواقيت الصلاة والقبلة والطقس والأماكن القريبة';

  @override
  String get onbPermNotify => 'تذكيرات لطيفة';

  @override
  String get onbPermNotifySub => 'تنبيه هادئ للأشياء التي طلبت منا متابعتها';

  @override
  String get onbPermNotifySubFaith => 'تنبيه هادئ قبل كل أذان بخمس دقائق';

  @override
  String get onbPlanKicker => 'خطط';

  @override
  String get onbPlanText =>
      'المهام والتذكيرات والأحداث على خط زمني واحد — وكل ما يهم في مكانه بالفعل.';

  @override
  String get onbPlanTitle => 'يومك، مرتَّب قبل أن يبدأ';

  @override
  String onbReadyFaith(String prayer) {
    return 'صلاتك القادمة هي $prayer، وخطة اليوم في انتظارك على الشاشة الرئيسية.';
  }

  @override
  String get onbReadyGeneral => 'خطة اليوم في انتظارك على الشاشة الرئيسية.';

  @override
  String onbReadyNamed(String name) {
    return 'أنت جاهز، $name';
  }

  @override
  String get onbReadyTitle => 'كل شيء جاهز';

  @override
  String get onbRevisit => 'يمكنك إعادة هذه الجولة في أي وقت من الملف الشخصي.';

  @override
  String onbSelected(String count, String max) {
    return '$count من $max محددة';
  }

  @override
  String get onbSetupText => 'إذنان، ويمكنك تغيير أي منهما لاحقًا.';

  @override
  String get onbSetupTitle => 'اضبطه مرة واحدة';

  @override
  String get onbSignInAction => 'تسجيل الدخول';

  @override
  String get onbSignInPrompt => 'هل لديك حساب بالفعل؟';

  @override
  String get onbSkippedDefaults =>
      'تم الإعداد بالإعدادات الافتراضية — عدّلها من الملف الشخصي';

  @override
  String get onbSkippedTour => 'تم تخطي الجولة — تجدها مجددًا في الملف الشخصي';

  @override
  String get onbToolsKicker => 'أدوات';

  @override
  String get onbToolsText =>
      'حاسبة ومحوّلات وطقس وماسح وأسعار ومتتبعات — مرتّبة، فلا تبحث عنها.';

  @override
  String onbToolsTitle(String count) {
    return 'نحو $count أداة، على بُعد نقرة أو نقرتين';
  }

  @override
  String get onbWelcomeBack => 'مرحبًا بك في Lume';

  @override
  String get onbWelcomeText =>
      'الخطط والمال والسفر والقراءة والأدوات الصغيرة التي تلجأ إليها — دون فوضى.';

  @override
  String get onbWelcomeTitle => 'كل ما يحتاجه يومك، منظَّم بهدوء.';

  @override
  String get onbWhereText =>
      'يساعدنا هذا في تخصيص المعلومات والخدمات المحلية. ولا يقول شيئًا عن هويتك.';

  @override
  String get onbWhereTitle => 'أين تقيم؟';

  @override
  String get onbYoursKicker => 'اجعله لك';

  @override
  String parcelArrivesToday(String carrier) {
    return '$carrier · يصل اليوم';
  }

  @override
  String get parcelOutForDelivery => 'خرج للتسليم';

  @override
  String get persAllCountries => 'كل الدول';

  @override
  String get persAppLanguage => 'لغة التطبيق';

  @override
  String get persCity => 'المدينة';

  @override
  String get persCitySub => 'للطقس والمعلومات المحلية والأماكن القريبة';

  @override
  String get persContent => 'المحتوى';

  @override
  String get persCountry => 'الدولة';

  @override
  String get persCountrySub => 'تفتح الخدمات المحلية فقط — لا شيء آخر';

  @override
  String get persCurrency => 'العملة';

  @override
  String persCurrencyAuto(String code) {
    return 'تلقائي ($code)';
  }

  @override
  String get persDataSafe =>
      'هذه التغييرات تؤثر على ما تراه فقط. ملاحظاتك ومهامك وسجلاتك تبقى كما هي.';

  @override
  String get persFinance => 'المعلومات المالية';

  @override
  String get persFinanceSub => 'الأسعار والذهب والأسواق';

  @override
  String get persFormatting => 'اللغة والتنسيق';

  @override
  String get persInterests => 'اهتماماتك';

  @override
  String persInterestsHint(int min) {
    return 'اختر $min على الأقل. هي التي تحدد ما يملأ شاشتك الرئيسية.';
  }

  @override
  String get persIslamic => 'الميزات الإسلامية';

  @override
  String get persIslamicSub => 'مواقيت الصلاة والقرآن والأدعية والزكاة ورمضان';

  @override
  String get persNews => 'الأخبار';

  @override
  String get persNewsSub => 'العناوين في استكشف واليوم';

  @override
  String get persPopular => 'شائعة';

  @override
  String get persRecent => 'حديثة';

  @override
  String get persRecos => 'التوصيات';

  @override
  String get persRecosSub => 'اقتراح أدوات بناءً على طريقة استخدامك لـ Lume';

  @override
  String get persRegion => 'المنطقة';

  @override
  String get persSavePrefs => 'حفظ التفضيلات';

  @override
  String get persSaved => 'تم تحديث تطبيقك';

  @override
  String get persSearchCities => 'ابحث عن مدينة';

  @override
  String get persSearchCountries => 'ابحث عن دولة';

  @override
  String get persSport => 'الرياضة';

  @override
  String get persSportSub => 'نتائج الكريكيت المباشرة';

  @override
  String get persSub => 'غيّر أيًا من هذا متى شئت';

  @override
  String get persTime12 => '12 ساعة';

  @override
  String get persTime24 => '24 ساعة';

  @override
  String get persTimeFormat => 'الوقت';

  @override
  String get persTitle => 'التخصيص';

  @override
  String get persUnits => 'الوحدات';

  @override
  String get persUnitsAuto => 'تلقائي';

  @override
  String get persUnitsImperial => 'إمبراطوري';

  @override
  String get persUnitsMetric => 'متري';

  @override
  String get persUseLocation => 'استخدم موقعي الحالي';

  @override
  String get persUseLocationSub => 'اختياري — يمكنك دائمًا ضبطه يدويًا';

  @override
  String get persWhereYouAre => 'أين أنت';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get profileSub => 'التفضيلات والعناصر المحفوظة';

  @override
  String get qaDocscan => 'امسح مستندًا';

  @override
  String get qaExpense => 'أضف مصروفًا';

  @override
  String get qaNote => 'ملاحظة جديدة';

  @override
  String get qaParcel => 'تتبّع الطرد';

  @override
  String get qaScan => 'امسح رمز QR';

  @override
  String get qaShop => 'التسوّق';

  @override
  String get qaTasbih => 'تسبيح';

  @override
  String get qaTask => 'أضف مهمة';

  @override
  String get qaTimer => 'ابدأ المؤقّت';

  @override
  String get qaWater => 'سجّل الماء';

  @override
  String get recConflict => 'تغيّر هذا السجل في مكان آخر';

  @override
  String get recConflictText => 'توجد نسخة أحدث. راجع تغييراتك أو حمّل الأحدث.';

  @override
  String get recDeleteFailed => 'تعذّر حذف هذا السجل';

  @override
  String recLoadError(Object noun) {
    return 'تعذّر تحميل $noun';
  }

  @override
  String get recLoadErrorText =>
      'تحقق من اتصالك. بياناتك المحفوظة ما زالت آمنة على هذا الجهاز.';

  @override
  String get recNothingToUndo => 'لا شيء للتراجع عنه';

  @override
  String get recOffline => 'أنت دون اتصال';

  @override
  String get recOfflineQueued => 'سيُحفظ هنا وتتم المزامنة عند عودة الاتصال.';

  @override
  String get recOfflineText => 'تُعرض السجلات المحفوظة على هذا الجهاز.';

  @override
  String get recSaveFailed => 'تعذّر حفظ التغييرات';

  @override
  String get recSaveFailedText => 'لم يضع شيء مما كتبته. حاول مرة أخرى.';

  @override
  String get recordsNoSelectionText => 'اختر سجلاً لعرضه هنا.';

  @override
  String get recordsNoSelectionTitle => 'لم يتم اختيار شيء';

  @override
  String get routeMissingText => 'قد يكون الرابط قديمًا أو أن الصفحة قد نُقلت.';

  @override
  String get routeMissingTitle => 'تعذّر العثور على ذلك';

  @override
  String get scoreAllOut => 'خرجوا جميعًا';

  @override
  String scoreOvers(String n) {
    return '$n أوفر';
  }

  @override
  String scoreTrail(String team, int runs, String player, int score) {
    return '$team متأخرون بـ $runs أشواط · $player $score*';
  }

  @override
  String get scoreVersus => 'ضد';

  @override
  String get searchDarkMode => 'الوضع الداكن';

  @override
  String get searchEverything => 'ابحث في كل شيء';

  @override
  String get searchInSettings => 'الإعدادات';

  @override
  String get searchJumpBack => 'عد إلى';

  @override
  String get searchNothing => 'لا توجد نتائج';

  @override
  String get searchNothingSub =>
      'جرّب کلمة أخرى، أو فعّل اهتمامات أخرى من التخصيص.';

  @override
  String get searchPlaceholder => 'ابحث عن أي شيء — أدوات، أسعار، أماكن';

  @override
  String get searchTry => 'جرّب البحث عن';

  @override
  String get slideMoneyCta => 'عرض المال';

  @override
  String get slideMoneyKicker => 'المال';

  @override
  String get slideMoneyText => 'الأسعار والفواتير والمصروفات في مكان واحد.';

  @override
  String get slideMoneyTitle => 'تابع أموالك أولًا بأول';

  @override
  String slideOf(int n, int total) {
    return 'الشريحة $n من $total';
  }

  @override
  String get slidePlanCta => 'افتح اليوم';

  @override
  String get slidePlanKicker => 'اليوم';

  @override
  String get slidePlanText => 'المهام والتذكيرات والمواعيد على خط زمني واحد.';

  @override
  String get slidePlanTitle => 'خطّط ليومك قبل أن يبدأ';

  @override
  String get slidePrayerCta => 'مواقيت الصلاة';

  @override
  String get slidePrayerKicker => 'صلاتك القادمة';

  @override
  String slidePrayerLine(String time, String city) {
    return 'الأذان $time · $city';
  }

  @override
  String get slideReadCta => 'متابعة';

  @override
  String get slideReadKicker => 'القراءة';

  @override
  String get slideReadText => 'بلغت الآية 42 من سورة الكهف. دقيقتان تكفيان.';

  @override
  String get slideReadTitle => 'اقرأ شيئًا ذا معنى';

  @override
  String get slideToolsCta => 'تصفّح الأدوات';

  @override
  String get slideToolsKicker => 'الأدوات';

  @override
  String get slideToolsText => 'حاسبة ومحوّلات وماسح وغيرها.';

  @override
  String get slideToolsTitle => 'أدوات مفيدة، كلّها في مكان واحد';

  @override
  String get slideTrainsCta => 'ابحث عن قطار';

  @override
  String get slideTrainsKicker => 'السفر';

  @override
  String get slideTrainsText => 'حالة التشغيل المباشرة والأجرة والمقاعد.';

  @override
  String get slideTrainsTitle => 'القطارات، بلا تخمين';

  @override
  String get startupLoading => 'جارٍ بدء Lume';

  @override
  String subsRenews(String date) {
    return 'يتجدّد $date';
  }

  @override
  String get surahAlKahf => 'الكهف';

  @override
  String get taskAlKahf => 'اقرأ صفحتين من سورة الكهف';

  @override
  String get taskCallHome => 'اتصل بالأهل';

  @override
  String get taskElectricity => 'ادفع فاتورة الكهرباء';

  @override
  String get taskElectricityPk => 'ادفع فاتورة كي إلكتريك';

  @override
  String get taskEmail => 'ردّ على بريد سارة';

  @override
  String get taskEvening => 'مساءً';

  @override
  String get taskSummary => 'أنهِ ملخّص الربع الثالث';

  @override
  String get todayAddToast => 'تمت إضافة مهمة جديدة';

  @override
  String get todayAgendaGeneral => 'المواعيد والتذكيرات بالترتيب';

  @override
  String get todayAgendaMuslim => 'الصلوات والمواعيد بالترتيب';

  @override
  String get todayAyah => 'آية اليوم';

  @override
  String todayAyahCitation(String surah, String verse) {
    return '$surah $verse';
  }

  @override
  String todayAyahReference(String surah, String verse) {
    return '$surah · $verse';
  }

  @override
  String get todayDailyStreak => 'التتابع اليومي';

  @override
  String todayHabitSummary(String name, int done, int streak) {
    return '$name، $done من 7 أيام، تتابع $streak أيام';
  }

  @override
  String get todayHabits => 'العادات';

  @override
  String get todayHabitsSub => 'آخر سبعة أيام';

  @override
  String get todayOfDay => 'من اليوم';

  @override
  String get todayOnTrack => 'أنت على المسار الصحيح';

  @override
  String get todayPrayerStreak => 'تتابع الصلاة';

  @override
  String get todayPrivate => 'خاص';

  @override
  String get todayPrivateSub => 'على هذا الجهاز فقط، ولك وحدك';

  @override
  String get todayPrivateText =>
      'تبقى السجلات والأدوية والمصروفات مقفلة حتى تفتحها بنفسك.';

  @override
  String get todayPrivateTitle => 'الصحة والوثائق والمال';

  @override
  String get todayPrivateToast => 'افتح القفل لعرض السجلات الخاصة';

  @override
  String get todayReadToday => 'القراءة اليوم';

  @override
  String todayRingSummary(int done, int total, int meetings) {
    String _temp0 = intl.Intl.pluralLogic(
      meetings,
      locale: localeName,
      other: 'بقيت $meetings اجتماعات بعد الظهر.',
      one: 'بقي اجتماع واحد بعد الظهر.',
      zero: 'لا شيء آخر مجدول.',
    );
    return '$done من $total مهام منجزة. $_temp0';
  }

  @override
  String get todaySteps => 'خطوات اليوم';

  @override
  String get todayTaskDone => 'أحسنت — مهمة أقل';

  @override
  String get todayTaskUndone => 'عادت إلى القائمة';

  @override
  String get todayTasks => 'المهام';

  @override
  String get todayTasksDone => 'المهام المنجزة';

  @override
  String get todayTasksSub => 'اضغط لإنجاز مهمة';

  @override
  String get todayThought => 'فكرة اليوم';

  @override
  String get todayThoughtSub => 'دقيقة للتأمل';

  @override
  String get todayWeekToast => 'تم التبديل إلى عرض الأسبوع';

  @override
  String get todayYourDay => 'يومك';

  @override
  String get toolCategoryDaily => 'الحياة اليومية';

  @override
  String get toolCategoryEveryday => 'يومي';

  @override
  String get toolCategoryIslamic => 'إسلامي';

  @override
  String get toolCategoryMoney => 'المال';

  @override
  String get toolCategoryPersonal => 'شخصي';

  @override
  String get toolCategoryPlanning => 'التخطيط';

  @override
  String get toolCategorySubDaily => 'ما يجري حولك';

  @override
  String get toolCategorySubEveryday => 'ما تستخدمه كل يوم';

  @override
  String get toolCategorySubIslamic => 'الصلاة والقرآن والزكاة';

  @override
  String get toolCategorySubMoney => 'الأسعار والفواتير والميزانية';

  @override
  String get toolCategorySubPersonal => 'خاص بك، على هذا الجهاز';

  @override
  String get toolCategorySubPlanning => 'وقتك وقوائمك';

  @override
  String get toolErrorText => 'تعذّر تحميل هذا. حاول مرة أخرى بعد قليل.';

  @override
  String get toolErrorTitle => 'حدث خطأ ما';

  @override
  String get toolLoading => 'جارٍ التحميل';

  @override
  String get toolLocalService => 'خدمة محلية';

  @override
  String toolNeedsAttention(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يحتاج انتباهك',
      few: '$n تحتاج انتباهك',
      two: 'اثنان يحتاجان انتباهك',
      one: 'واحد يحتاج انتباهك',
    );
    return '$_temp0';
  }

  @override
  String get toolPrivate => 'خاص';

  @override
  String get toolPrivateText =>
      'تبقى هذه المعلومات على جهازك ولا تُشارك أبدًا.';

  @override
  String get toolPrivateTitle => 'خاص بك';

  @override
  String get toolStatusAge => 'بالأيام بدقة';

  @override
  String get toolStatusAlarms => '2 مضبوطة';

  @override
  String get toolStatusAqi => 'مؤشر الهواء';

  @override
  String get toolStatusAyah => 'الرعد 28';

  @override
  String get toolStatusBabybudget => 'خطّط التكاليف';

  @override
  String get toolStatusBills => '2 مستحقة';

  @override
  String get toolStatusBirthdays => 'عائشة خلال 4 أيام';

  @override
  String get toolStatusBmi => 'تتبّع الوزن';

  @override
  String get toolStatusCalculator => 'عادية';

  @override
  String get toolStatusCalendar => '3 أحداث';

  @override
  String get toolStatusCommittee => 'الشهر 4 من 10';

  @override
  String get toolStatusCompound => 'توقّع النمو';

  @override
  String get toolStatusConverter => '32 وحدة';

  @override
  String get toolStatusCricket => 'PAK 214/4';

  @override
  String get toolStatusCurrency => 'أسعار مباشرة';

  @override
  String get toolStatusCycle => 'خاص';

  @override
  String get toolStatusDatecalc => 'إضافة · فرق';

  @override
  String get toolStatusDocscan => 'PDF جاهز';

  @override
  String get toolStatusDocuments => 'مقفلة';

  @override
  String get toolStatusDuas => '42 محفوظًا';

  @override
  String get toolStatusEmergency => '15 · 1122';

  @override
  String get toolStatusEvents => 'التالي 14:00';

  @override
  String get toolStatusExpenses => 'هذا الشهر';

  @override
  String get toolStatusFaraid => 'الميراث';

  @override
  String get toolStatusFasting => '3 صيامات';

  @override
  String get toolStatusFlights => 'تتبّع مباشر';

  @override
  String get toolStatusFocus => '25 دقيقة';

  @override
  String get toolStatusFuel => 'أسعار المحطات';

  @override
  String get toolStatusFuelcost => 'تكلفة الرحلة';

  @override
  String get toolStatusGoals => '2 نشطة';

  @override
  String get toolStatusGoldrates => 'الذهب والعملات';

  @override
  String get toolStatusHabits => 'سلسلة 12 يومًا';

  @override
  String get toolStatusHadith => 'يوميًا';

  @override
  String get toolStatusHealth => 'خاص';

  @override
  String get toolStatusHijri => '15 ربيع الأول';

  @override
  String get toolStatusHolidays => 'هذا العام';

  @override
  String get toolStatusInstallments => '3 جارية';

  @override
  String get toolStatusLearning => '3 دورات';

  @override
  String get toolStatusLedger => '3 أشخاص';

  @override
  String get toolStatusLoadshed => '14:00–16:00';

  @override
  String get toolStatusLoan => 'أقساط';

  @override
  String get toolStatusMarkets => 'KSE-100 ▲ 0.8%';

  @override
  String get toolStatusMealplan => 'هذا الأسبوع';

  @override
  String get toolStatusMediasaver => 'حفظ المنشورات';

  @override
  String get toolStatusMeds => 'خاص';

  @override
  String get toolStatusMosques => '3 ضمن 1 كم';

  @override
  String get toolStatusNames99 => 'أسماء الله الحسنى';

  @override
  String get toolStatusNatsavings => 'معدلات الربح';

  @override
  String get toolStatusNews => '12 جديدًا';

  @override
  String get toolStatusNotes => '12 محفوظة';

  @override
  String get toolStatusPackages => 'Jazz · Zong';

  @override
  String get toolStatusParcel => '1 في الطريق';

  @override
  String get toolStatusPassport => 'مقاسات نادرا';

  @override
  String get toolStatusPlay => 'ألغاز';

  @override
  String get toolStatusPrayer => 'العصر 15:53';

  @override
  String get toolStatusPraytrack => 'سلسلة 12 يومًا';

  @override
  String get toolStatusPregnancy => 'خاص';

  @override
  String get toolStatusPrizebonds => 'السحب 15 سبتمبر';

  @override
  String get toolStatusQibla => '267° غربًا';

  @override
  String get toolStatusQr => 'مسح ودفع';

  @override
  String get toolStatusQuran => 'الكهف 42';

  @override
  String get toolStatusQuransearch => 'بالكلمة';

  @override
  String get toolStatusRamadan => 'خلال 172 يومًا';

  @override
  String get toolStatusRecipes => '24 محفوظة';

  @override
  String get toolStatusReminders => '4 اليوم';

  @override
  String get toolStatusShopping => '6 عناصر';

  @override
  String get toolStatusSpeedtest => 'اختبر الآن';

  @override
  String get toolStatusStopwatch => 'لفّات';

  @override
  String get toolStatusStreak => '12 يومًا';

  @override
  String get toolStatusSubs => '6 نشطة';

  @override
  String get toolStatusSunmoon => 'الشروق · الغروب';

  @override
  String get toolStatusTaraweeh => 'رمضان';

  @override
  String get toolStatusTasbih => 'عدّاد';

  @override
  String get toolStatusTax => 'FBR 2025-26';

  @override
  String get toolStatusTimer => 'إعدادات جاهزة';

  @override
  String get toolStatusTipsplit => 'تقسيم الفاتورة';

  @override
  String get toolStatusTodos => '2 من 5 منجزة';

  @override
  String get toolStatusTrains => 'الخط الأخضر';

  @override
  String get toolStatusVaccines => 'خاص';

  @override
  String get toolStatusVehicle => 'التحقق من المخالفات';

  @override
  String get toolStatusWastatus => 'أندرويد';

  @override
  String get toolStatusWater => '5 / 8';

  @override
  String get toolStatusWeather => '34° صافٍ';

  @override
  String get toolStatusWorldclock => '8 مدن';

  @override
  String get toolStatusZakat => 'حساب النصاب';

  @override
  String toolUnavailableHere(String country) {
    return 'غير متاح في $country بعد';
  }

  @override
  String get toolUnavailableText => 'هذه الأداة ليست ضمن إعداداتك.';

  @override
  String get toolUnavailableTitle => 'ليست ضمن إعداداتك';

  @override
  String get toolsForYou => 'لك';

  @override
  String get toolsNoMatch => 'لا توجد أدوات مطابقة';

  @override
  String get toolsNoMatchSub => 'جرّب كلمة أخرى — أو تصفّح فئة من الأعلى.';

  @override
  String get toolsNothingYet => 'لا شيء هنا بعد';

  @override
  String get toolsNothingYetSub =>
      'أضف بعض الاهتمامات، أو تصفّح القائمة كاملة ضمن “الكل”.';

  @override
  String get toolsPersonalise => 'تخصيص';

  @override
  String get toolsRecent => 'المستخدمة مؤخرًا';

  @override
  String get toolsRecentSub => 'عُد مباشرة إلى حيث كنت';

  @override
  String toolsResultCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n أداة',
      few: '$n أدوات',
      two: 'أداتان',
      one: 'أداة واحدة',
      zero: 'لا أدوات',
    );
    return '$_temp0';
  }

  @override
  String get toolsSearchExample => 'العملات';

  @override
  String get toolsSearchExamplePk => 'بنزين';

  @override
  String toolsSearchHint(String example) {
    return 'ابحث في الأدوات — جرّب “$example”';
  }

  @override
  String get toolsSearchLabel => 'ابحث في الأدوات';

  @override
  String toolsSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n أداة، مرتّبة',
      few: '$n أدوات، مرتّبة',
      two: 'أداتان، مرتّبتان',
      one: 'أداة واحدة، مرتّبة',
    );
    return '$_temp0';
  }

  @override
  String get toolsTitle => 'الأدوات';

  @override
  String get trainsAllDepartures => 'كل المغادرات';

  @override
  String get trainsChooseDestination => 'اختر الوجهة';

  @override
  String get trainsChooseOrigin => 'اختر محطة المغادرة';

  @override
  String trainsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n قطارًا',
      few: '$n قطارات',
      two: 'قطاران',
      one: 'قطار واحد',
    );
    return '$_temp0';
  }

  @override
  String trainsDayOn(String date) {
    return 'مغادرات $date';
  }

  @override
  String get trainsDayToday => 'مغادرات اليوم';

  @override
  String get trainsDayTomorrow => 'مغادرات الغد';

  @override
  String get trainsDepartures => 'المغادرات';

  @override
  String trainsDeparturesSub(String station) {
    return 'من $station';
  }

  @override
  String trainsDuration(String h, String m) {
    return '$h س $m د';
  }

  @override
  String trainsFareFrom(String fare) {
    return 'من $fare';
  }

  @override
  String get trainsFrom => 'من';

  @override
  String trainsHeadSub(String operator) {
    return '$operator · الحالة المباشرة';
  }

  @override
  String get trainsNow => 'الآن';

  @override
  String get trainsPickDate => 'اختر تاريخًا';

  @override
  String get trainsPickedDate => 'اختر تاريخ المغادرة';

  @override
  String get trainsPopular => 'المسارات الشائعة';

  @override
  String get trainsPopularSub => 'اضغط لعرض الأسعار والمقاعد';

  @override
  String get trainsRefreshed => 'تم تحديث الحالة المباشرة';

  @override
  String trainsRoute(String from, String to) {
    return '$from ← $to';
  }

  @override
  String get trainsRouteInvalidText => 'تحتاج الرحلة إلى نقطة مغادرة ووجهة.';

  @override
  String get trainsRouteInvalidTitle => 'اختر محطتين مختلفتين';

  @override
  String trainsRouteToast(String from, String to, String trains, String fare) {
    return '$from ← $to · $trains · $fare';
  }

  @override
  String get trainsSaved => 'الرحلات المحفوظة';

  @override
  String trainsSearchResult(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n قطارًا على هذا المسار اليوم',
      few: '$n قطارات على هذا المسار اليوم',
      two: 'قطاران على هذا المسار اليوم',
      one: 'قطار واحد على هذا المسار اليوم',
    );
    return '$_temp0';
  }

  @override
  String trainsServiceLine(
    String depart,
    String arrive,
    String duration,
    String fare,
  ) {
    return '$depart ← $arrive · $duration · $fare';
  }

  @override
  String get trainsStatusDeparted => 'غادر';

  @override
  String trainsStatusLate(int n) {
    return 'متأخر $n دقيقة';
  }

  @override
  String get trainsStatusOnTime => 'في الموعد';

  @override
  String get trainsSwap => 'تبديل المحطتين';

  @override
  String get trainsSwapped => 'تم تبديل المحطتين';

  @override
  String trainsSwappedTo(String origin, String destination) {
    return 'تم تبديل المحطتين: من $origin إلى $destination';
  }

  @override
  String get trainsTo => 'إلى';

  @override
  String get trainsToday => 'اليوم';

  @override
  String get trainsTomorrow => 'غدًا';

  @override
  String trainsTrackedSummary(
    String name,
    String number,
    String route,
    String status,
    String percent,
  ) {
    return '$name $number، $route، $status، $percent';
  }

  @override
  String get trainsTracking => 'أنت تتابع';

  @override
  String get trainsUnavailableTitle => 'القطارات ليست ضمن إعداداتك';

  @override
  String trainsUpdated(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم التحديث قبل $n دقيقة',
      few: 'تم التحديث قبل $n دقائق',
      two: 'تم التحديث قبل دقيقتين',
      one: 'تم التحديث قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get unitDays => 'يوم';

  @override
  String get unitKmh => 'كم/س';

  @override
  String get unitMinutes => 'دقيقة';

  @override
  String get unitMph => 'ميل/س';

  @override
  String unitOfTotal(int total) {
    return '/$total';
  }

  @override
  String get unitThousand => 'ألف';

  @override
  String get weatherClear => 'صافٍ';

  @override
  String get weatherClearVeryWarm => 'صحو · حار جدًا';

  @override
  String get weatherCloudBuilding => 'تزايد الغيوم';

  @override
  String get weatherHazy => 'مغبرّ';

  @override
  String get weatherHazySun => 'شمس مغبرّة';

  @override
  String get weatherHazySunHumid => 'شمس ضبابية · رطوبة';

  @override
  String weatherHighLow(String high, String low) {
    return '$high / $low';
  }

  @override
  String get weatherHumidLightHaze => 'رطوبة · ضباب خفيف';

  @override
  String get weatherLightCloud => 'غيوم خفيفة';

  @override
  String get weatherMostlyClear => 'صافٍ غالبًا';

  @override
  String get weatherOvercast => 'غائم';

  @override
  String get weatherRain => 'المطر';
}
