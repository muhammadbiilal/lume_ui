// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get a11yBack => 'واپس';

  @override
  String get a11yMainNavigation => 'مرکزی';

  @override
  String get a11ySearch => 'تلاش';

  @override
  String get a11yShare => 'شیئر';

  @override
  String get actionAdd => 'شامل کریں';

  @override
  String get actionAll => 'سب';

  @override
  String get actionBack => 'واپس';

  @override
  String get actionBookmark => 'محفوظ کریں';

  @override
  String get actionCancel => 'منسوخ';

  @override
  String get actionClear => 'صاف کریں';

  @override
  String get actionClose => 'بند کریں';

  @override
  String get actionContinue => 'جاری رکھیں';

  @override
  String get actionDelete => 'حذف کریں';

  @override
  String get actionDone => 'مکمل';

  @override
  String get actionEdit => 'ترمیم';

  @override
  String get actionGetStarted => 'شروع کریں';

  @override
  String get actionLooksGood => 'ٹھیک ہے';

  @override
  String get actionNext => 'اگلا';

  @override
  String get actionNotSet => 'مقرر نہیں';

  @override
  String get actionRefresh => 'تازہ کریں';

  @override
  String get actionRemove => 'ہٹائیں';

  @override
  String get actionSave => 'محفوظ کریں';

  @override
  String get actionSaveImage => 'تصویر محفوظ کریں';

  @override
  String get actionSearch => 'تلاش';

  @override
  String get actionShare => 'شیئر کریں';

  @override
  String get actionSkip => 'چھوڑ دیں';

  @override
  String get actionTryAgain => 'دوبارہ کوشش کریں';

  @override
  String get actionWeek => 'ہفتہ';

  @override
  String get agendaAdhanOn => 'اذان · یاد دہانی آن';

  @override
  String get agendaGroceries => 'سودا سلف لینا';

  @override
  String get agendaGroceriesMeta => 'گھر جاتے ہوئے';

  @override
  String get agendaOutage => 'بندش';

  @override
  String agendaOutageMeta(String area, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours گھنٹے',
      one: '1 گھنٹہ',
    );
    return '$area · $_temp0';
  }

  @override
  String get agendaPrayed => 'ادا ہو گئی';

  @override
  String get agendaReview => 'ڈیزائن جائزہ';

  @override
  String get agendaReviewMeta => '45 منٹ · میٹنگ روم 2';

  @override
  String get agendaStandup => 'ٹیم اسٹینڈ اپ';

  @override
  String get agendaStandupMeta => '15 منٹ · ویڈیو کال';

  @override
  String get anniversaryKind => 'سالگرہ کی تقریب';

  @override
  String get appTagline => 'آپ کا دن، ایک جگہ';

  @override
  String get authAsideText =>
      'نماز، موسم، پیسہ، سفر اور چھوٹی چھوٹی باتیں — آپ جہاں بھی ہوں۔';

  @override
  String get authAsideTitle => 'آنے والے دن کے لیے ایک ایپ۔';

  @override
  String get authBackToSignIn => 'سائن ان پر واپس';

  @override
  String get authContinue => 'جاری رکھیں';

  @override
  String get authContinueAsGuest => 'مہمان کے طور پر جاری رکھیں';

  @override
  String get authCreateAccount => 'اکاؤنٹ بنائیں';

  @override
  String get authCreateOne => 'ایک بنائیں';

  @override
  String get authCreatedText => 'آپ کا Lume اکاؤنٹ تیار ہے۔';

  @override
  String authCreatedTextNamed(String name) {
    return 'آپ کا Lume اکاؤنٹ تیار ہے، $name۔';
  }

  @override
  String get authCreatedTitle => 'سب تیار ہے';

  @override
  String get authCreatingAccount => 'آپ کا اکاؤنٹ بن رہا ہے…';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authEnterCta => 'Lume میں داخل ہوں';

  @override
  String get authErrCodeExpired => 'یہ کوڈ ختم ہو چکا ہے۔ نیا منگوائیں۔';

  @override
  String get authErrCodeIncorrect => 'یہ کوڈ درست نہیں۔';

  @override
  String get authErrCodeRequired => 'وہ کوڈ درج کریں جو ہم نے بھیجا۔';

  @override
  String get authErrConfirmMismatch => 'دونوں پاس ورڈ ایک جیسے نہیں۔';

  @override
  String get authErrConfirmRequired => 'اپنے پاس ورڈ کی تصدیق کریں۔';

  @override
  String get authErrCredentials => 'ای میل یا پاس ورڈ درست نہیں۔';

  @override
  String get authErrEmailInvalid => 'یہ ای میل پتہ درست نہیں لگتا۔';

  @override
  String get authErrEmailRequired => 'اپنا ای میل پتہ درج کریں۔';

  @override
  String get authErrEmailSame => 'یہ پہلے ہی آپ کا ای میل پتہ ہے۔';

  @override
  String get authErrEmailTaken => 'اس ای میل کے لیے اکاؤنٹ پہلے سے موجود ہے۔';

  @override
  String get authErrLinkExpired => 'یہ ری سیٹ لنک ختم ہو چکا ہے۔ نیا منگوائیں۔';

  @override
  String get authErrLinkInvalid => 'یہ ری سیٹ لنک اب کارآمد نہیں۔';

  @override
  String get authErrLocked =>
      'یہ اکاؤنٹ مقفل ہے۔ کھولنے کے لیے پاس ورڈ ری سیٹ کریں۔';

  @override
  String get authErrNetwork =>
      'Lume نیٹ ورک تک نہیں پہنچ سکا۔ کچھ ضائع نہیں ہوا۔';

  @override
  String get authErrNothingPending => 'کوئی ای میل تبدیلی زیرِ التوا نہیں۔';

  @override
  String get authErrPasswordRequired => 'پاس ورڈ درج کریں۔';

  @override
  String get authErrPasswordWeak =>
      'آپ کا پاس ورڈ ابھی تمام شرائط پوری نہیں کرتا۔';

  @override
  String get authErrRateLimited =>
      'بہت زیادہ کوششیں۔ تھوڑا انتظار کر کے دوبارہ کوشش کریں۔';

  @override
  String get authErrSignedOut =>
      'آپ سائن آؤٹ ہیں۔ جاری رکھنے کے لیے سائن ان کریں۔';

  @override
  String get authErrStorage =>
      'Lume اس ڈیوائس پر محفوظ نہیں کر سکا۔ اس کی اسٹوریج ترتیبات دیکھ کر دوبارہ کوشش کریں۔';

  @override
  String get authExpiredCta => 'دوبارہ سائن ان کریں';

  @override
  String get authExpiredText =>
      'دوبارہ سائن ان کریں، Lume آپ کو وہیں واپس لے جائے گا جہاں آپ تھے۔';

  @override
  String get authExpiredTitle => 'آپ کا سیشن ختم ہو گیا';

  @override
  String get authFieldCode => 'تصدیقی کوڈ';

  @override
  String get authFieldConfirm => 'پاس ورڈ کی تصدیق';

  @override
  String get authFieldEmail => 'ای میل';

  @override
  String get authFieldName => 'نام';

  @override
  String get authFieldNewPassword => 'نیا پاس ورڈ';

  @override
  String get authFieldPassword => 'پاس ورڈ';

  @override
  String get authForgotAction => 'پاس ورڈ بھول گئے؟';

  @override
  String get authForgotCta => 'ری سیٹ لنک بھیجیں';

  @override
  String get authForgotText =>
      'وہ ای میل درج کریں جو آپ کے Lume اکاؤنٹ سے منسلک ہے۔';

  @override
  String get authForgotTitle => 'پاس ورڈ بھول گئے؟';

  @override
  String get authHaveAccount => 'پہلے سے اکاؤنٹ ہے؟';

  @override
  String get authHidePassword => 'پاس ورڈ چھپائیں';

  @override
  String get authLegal =>
      'اکاؤنٹ بنانے کا مطلب ہے کہ Lume یہ معلومات آپ کے لیے رکھے گا۔';

  @override
  String get authLegalLink => 'Lume آپ کا ڈیٹا کیسے سنبھالتا ہے';

  @override
  String authLocalCode(String code) {
    return 'اس بلڈ میں میل سرور نہیں۔ آپ کا کوڈ $code ہے۔';
  }

  @override
  String get authNameHint => 'تاکہ Lume جانے کہ آپ کو کیا کہہ کر پکارے۔';

  @override
  String get authNeedAccountText =>
      'Lume کا یہ حصہ آپ کے اکاؤنٹ سے تعلق رکھتا ہے۔';

  @override
  String get authNoAccount => 'اکاؤنٹ نہیں ہے؟';

  @override
  String get authOpenLink => 'ری سیٹ لنک کھولیں';

  @override
  String get authPasswordRuleDigit => 'ایک عدد';

  @override
  String get authPasswordRuleLength => 'کم از کم 8 حروف';

  @override
  String get authPasswordRuleLower => 'ایک چھوٹا حرف';

  @override
  String get authPasswordRuleUpper => 'ایک بڑا حرف';

  @override
  String get authPasswordRulesTitle => 'پاس ورڈ میں ہونا چاہیے';

  @override
  String get authRememberPassword => 'پاس ورڈ یاد آ گیا؟';

  @override
  String get authResend => 'دوبارہ بھیجیں';

  @override
  String authResendIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'آپ $seconds سیکنڈ بعد دوبارہ مانگ سکتے ہیں',
      one: 'آپ $seconds سیکنڈ بعد دوبارہ مانگ سکتے ہیں',
    );
    return '$_temp0';
  }

  @override
  String get authResendNone => 'موصول نہیں ہوا؟';

  @override
  String get authResetCta => 'پاس ورڈ اپ ڈیٹ کریں';

  @override
  String get authResetText =>
      'ایسا پاس ورڈ چنیں جو آپ نے یہاں پہلے استعمال نہ کیا ہو۔';

  @override
  String get authResetTitle => 'نیا پاس ورڈ بنائیں';

  @override
  String get authSentLocal =>
      'اس بلڈ میں میل سرور نہیں، اس لیے لنک یہیں کھلتا ہے۔';

  @override
  String get authSentNote => 'یہ لنک ایک گھنٹے تک کام کرتا ہے۔';

  @override
  String get authSentText =>
      'اگر اس ای میل کے لیے کوئی اکاؤنٹ موجود ہے تو ہم نے پاس ورڈ ری سیٹ کرنے کی ہدایات بھیج دی ہیں۔';

  @override
  String get authSentTitle => 'اپنی ای میل دیکھیں';

  @override
  String get authShowPassword => 'پاس ورڈ دکھائیں';

  @override
  String get authSignIn => 'سائن ان';

  @override
  String get authSignInText => 'اپنے Lume میں جاری رکھیں۔';

  @override
  String get authSignInTitle => 'خوش آمدید';

  @override
  String get authSignUpPasswordText => 'یہی آپ کے Lume کو آپ کا رکھتا ہے۔';

  @override
  String get authSignUpPasswordTitle => 'پاس ورڈ منتخب کریں';

  @override
  String get authSignUpText => 'آپ کا Lume، محفوظ اور ہر جگہ دستیاب۔';

  @override
  String get authSignUpTitle => 'اپنا Lume اکاؤنٹ بنائیں';

  @override
  String get authSigningIn => 'سائن ان ہو رہا ہے…';

  @override
  String authStepOf(int n, int total) {
    return 'مرحلہ $n از $total';
  }

  @override
  String get authStrength0 => 'پاس ورڈ درج کریں';

  @override
  String get authStrength1 => 'کمزور';

  @override
  String get authStrength2 => 'مناسب';

  @override
  String get authStrength3 => 'اچھا';

  @override
  String get authStrength4 => 'مضبوط';

  @override
  String get authTroubleCta => 'نیا لنک منگوائیں';

  @override
  String get authTroubleExpired =>
      'ری کوری لنک ایک گھنٹے بعد کام کرنا بند کر دیتے ہیں، اس لیے یہ ختم ہو چکا ہے۔ نیا مانگیں، وہ اسی طرح پہنچ جائے گا۔';

  @override
  String get authTroubleText =>
      'ری کوری لنک صرف ایک بار، اور صرف اسی پتے سے استعمال ہو سکتا ہے جس پر بھیجا گیا۔ نیا مانگیں، وہ اسی طرح پہنچ جائے گا۔';

  @override
  String get authTroubleTitle => 'یہ لنک کام نہیں کر سکا';

  @override
  String get authUpdatedText =>
      'اب آپ اپنے نئے پاس ورڈ سے سائن ان کر سکتے ہیں۔';

  @override
  String get authUpdatedTitle => 'پاس ورڈ اپ ڈیٹ ہو گیا';

  @override
  String get authVerifyCta => 'ای میل کی تصدیق کریں';

  @override
  String get authVerifyText => 'ہم نے چھ ہندسوں کا کوڈ بھیجا ہے';

  @override
  String get authVerifyTitle => 'اپنا ان باکس دیکھیں';

  @override
  String authWelcomeBack(String name) {
    return 'خوش آمدید، $name';
  }

  @override
  String get authWorking => 'ایک لمحہ…';

  @override
  String billsDueIn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n دن میں واجب',
      one: '1 دن میں واجب',
    );
    return '$_temp0';
  }

  @override
  String get billsDueThisMonth => 'اس مہینے واجب';

  @override
  String billsNeedAttention(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n بلوں پر توجہ درکار',
      one: '1 بل پر توجہ درکار',
    );
    return '$_temp0';
  }

  @override
  String billsOverdueBy(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n دن تاخیر',
      one: '1 دن تاخیر',
    );
    return '$_temp0';
  }

  @override
  String get birthdayKind => 'سالگرہ';

  @override
  String get collectionBudget => 'بجٹ کی بنیادی باتیں';

  @override
  String collectionBudgetMeta(int n) {
    return '$n اسباق';
  }

  @override
  String get collectionFocus => 'توجہ کی آوازیں';

  @override
  String collectionFocusMeta(int n) {
    return '$n ٹریک';
  }

  @override
  String get collectionGratitude => 'شکرگزاری کے اشارے';

  @override
  String collectionGratitudeMeta(int n) {
    return '$n دن';
  }

  @override
  String get collectionNightSurahs => 'رات کی سورتیں';

  @override
  String collectionNightSurahsMeta(int surahs, int minutes) {
    return '$surahs سورتیں · $minutes منٹ';
  }

  @override
  String get commonAll => 'سب';

  @override
  String get commonDays => 'دن';

  @override
  String get commonDone => 'مکمل';

  @override
  String get commonDue => 'واجب';

  @override
  String get commonExport => 'برآمد';

  @override
  String get commonHistory => 'تاریخ';

  @override
  String commonInDays(Object n) {
    return '$n دن میں';
  }

  @override
  String get commonLocked => 'مقفل';

  @override
  String get commonMonth => 'مہینہ';

  @override
  String get commonNo => 'نہیں';

  @override
  String get commonNow => 'ابھی';

  @override
  String get commonOffline => 'آف لائن';

  @override
  String get commonOptional => 'اختیاری';

  @override
  String get commonOverdue => 'تاخیر';

  @override
  String get commonPaid => 'ادا شدہ';

  @override
  String get commonReset => 'دوبارہ ترتیب';

  @override
  String get commonSave => 'محفوظ کریں';

  @override
  String get commonShare => 'شیئر';

  @override
  String get commonSort => 'ترتیب';

  @override
  String get commonStale => 'تازہ نہیں';

  @override
  String get commonStatus => 'حالت';

  @override
  String get commonThisMonth => 'اس ماہ';

  @override
  String get commonToday => 'آج';

  @override
  String get commonTomorrow => 'کل';

  @override
  String get commonTotal => 'کل';

  @override
  String get commonWeek => 'ہفتہ';

  @override
  String get commonYear => 'سال';

  @override
  String get commonYes => 'ہاں';

  @override
  String get commonYesterday => 'گزشتہ کل';

  @override
  String cricketScore(String team, int runs, int wickets) {
    return '$team $runs/$wickets';
  }

  @override
  String cricketSecondTest(int n) {
    return 'دوسرا ٹیسٹ · دن $n';
  }

  @override
  String get discoverDuasMeta => 'عام دنوں کے لیے';

  @override
  String get discoverDuasTitle => 'چالیس دعائیں';

  @override
  String docsRenewSoon(String name) {
    return 'اپنا $name تجدید کریں';
  }

  @override
  String get exploreAround => 'آپ کے آس پاس';

  @override
  String get exploreAroundSub => 'مقامی خدمات، تازہ ترین';

  @override
  String get exploreBackToHome => 'ہوم پر واپس';

  @override
  String get exploreCollections => 'مجموعے';

  @override
  String get exploreCollectionsSub => 'سکون کے لمحے کے لیے';

  @override
  String get exploreCricket => 'کرکٹ';

  @override
  String get exploreCricketSub => 'لائیو · دوسرا ٹیسٹ، دن 2';

  @override
  String get exploreFeatured => 'نمایاں مجموعہ';

  @override
  String get exploreNearby => 'قریب';

  @override
  String get exploreNearbySub => 'پیدل فاصلے پر';

  @override
  String exploreRainLabel(String value) {
    return 'بارش $value';
  }

  @override
  String get exploreReads => 'آج کا مطالعہ';

  @override
  String get exploreReadsSub => 'متوازن، بغیر شور کے';

  @override
  String get exploreScorecard => 'اسکور کارڈ';

  @override
  String get exploreSubGlobal => 'موسم، مطالعہ اور آس پاس کی باتیں';

  @override
  String get exploreSubLocal => 'مقامی خدمات، اسکور اور مطالعہ';

  @override
  String exploreSunsetLabel(String value) {
    return 'غروب $value';
  }

  @override
  String get exploreWeather => 'موسم';

  @override
  String exploreWeatherDesc(String condition, String feels) {
    return '$condition · $feels';
  }

  @override
  String exploreWeatherSub(String city, int n) {
    return '$city · $n منٹ پہلے تازہ کیا گیا';
  }

  @override
  String get exploreWeatherToast => 'موسم تازہ ہو گیا';

  @override
  String exploreWindLabel(String value) {
    return 'ہوا $value';
  }

  @override
  String exploreWindValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get featureAge => 'عمر کیلکولیٹر';

  @override
  String get featureAlarms => 'الارم';

  @override
  String get featureAqi => 'ہوا کا معیار';

  @override
  String get featureAyah => 'آج کی آیت';

  @override
  String get featureBabybudget => 'بچے کا بجٹ';

  @override
  String get featureBills => 'بل';

  @override
  String get featureBirthdays => 'سالگرہ';

  @override
  String get featureBmi => 'BMI کیلکولیٹر';

  @override
  String get featureCalculator => 'کیلکولیٹر';

  @override
  String get featureCalendar => 'کیلنڈر';

  @override
  String get featureCommittee => 'کمیٹی';

  @override
  String get featureCompound => 'مرکب منافع';

  @override
  String get featureConverter => 'یونٹ کنورٹر';

  @override
  String get featureCricket => 'کرکٹ';

  @override
  String get featureCurrency => 'کرنسی';

  @override
  String get featureCycle => 'سائیکل ٹریکر';

  @override
  String get featureDatecalc => 'تاریخ کیلکولیٹر';

  @override
  String get featureDocscan => 'دستاویز اسکینر';

  @override
  String get featureDocuments => 'دستاویزات';

  @override
  String get featureDuas => 'روزانہ دعائیں';

  @override
  String get featureEmergency => 'ایمرجنسی';

  @override
  String get featureEvents => 'مصروفیات';

  @override
  String get featureExpenses => 'اخراجات';

  @override
  String get featureFaraid => 'فرائض';

  @override
  String get featureFasting => 'روزہ ٹریکر';

  @override
  String get featureFlights => 'پروازیں';

  @override
  String get featureFocus => 'فوکس ٹائمر';

  @override
  String get featureFuel => 'پٹرول کی قیمتیں';

  @override
  String get featureFuelcost => 'سفر کا خرچ';

  @override
  String get featureGoals => 'بچت کے اہداف';

  @override
  String get featureGoldrates => 'کرنسی اور سونا';

  @override
  String get featureHabits => 'عادات';

  @override
  String get featureHadith => 'حدیث';

  @override
  String get featureHealth => 'صحت کا ریکارڈ';

  @override
  String get featureHijri => 'اسلامی کیلنڈر';

  @override
  String get featureHolidays => 'سرکاری تعطیلات';

  @override
  String get featureInstallments => 'اقساط';

  @override
  String get featureLearning => 'سیکھنا';

  @override
  String get featureLedger => 'ادھار کھاتہ';

  @override
  String get featureLoadshed => 'لوڈشیڈنگ';

  @override
  String get featureLoan => 'قرض / قسط';

  @override
  String get featureMarkets => 'مارکیٹس';

  @override
  String get featureMealplan => 'کھانے کا منصوبہ';

  @override
  String get featureMediasaver => 'میڈیا سیور';

  @override
  String get featureMeds => 'ادویات';

  @override
  String get featureMosques => 'قریبی مساجد';

  @override
  String get featureNames99 => '99 نام';

  @override
  String get featureNatsavings => 'قومی بچت';

  @override
  String get featureNews => 'خبریں';

  @override
  String get featureNotes => 'نوٹس';

  @override
  String get featurePackages => 'موبائل پیکجز';

  @override
  String get featureParcel => 'پارسل ٹریکر';

  @override
  String get featurePassport => 'پاسپورٹ تصاویر';

  @override
  String get featurePlay => 'کھیل';

  @override
  String get featurePrayer => 'نماز کے اوقات';

  @override
  String get featurePraytrack => 'نماز ٹریکر';

  @override
  String get featurePregnancy => 'حمل';

  @override
  String get featurePrizebonds => 'پرائز بانڈ';

  @override
  String get featureQibla => 'قبلہ کمپاس';

  @override
  String get featureQr => 'QR اسکینر';

  @override
  String get featureQuran => 'القرآن';

  @override
  String get featureQuransearch => 'قرآن میں تلاش';

  @override
  String get featureRamadan => 'رمضان';

  @override
  String get featureRecipes => 'ترکیبیں';

  @override
  String get featureReminders => 'یاد دہانیاں';

  @override
  String get featureShopping => 'خریداری کی فہرست';

  @override
  String get featureSpeedtest => 'اسپیڈ ٹیسٹ';

  @override
  String get featureStopwatch => 'اسٹاپ واچ';

  @override
  String get featureStreak => 'روزانہ تسلسل';

  @override
  String get featureSubs => 'سبسکرپشنز';

  @override
  String get featureSunmoon => 'سورج و چاند';

  @override
  String get featureTaraweeh => 'تراویح';

  @override
  String get featureTasbih => 'تسبیح';

  @override
  String get featureTax => 'ٹیکس کیلکولیٹر';

  @override
  String get featureTimer => 'ٹائمر';

  @override
  String get featureTipsplit => 'بل تقسیم';

  @override
  String get featureTodos => 'کام';

  @override
  String get featureTrains => 'ٹرینیں';

  @override
  String get featureVaccines => 'ویکسینیشن';

  @override
  String get featureVehicle => 'گاڑی اور جرمانے';

  @override
  String get featureWastatus => 'واٹس ایپ اسٹیٹس';

  @override
  String get featureWater => 'پانی';

  @override
  String get featureWeather => 'موسم';

  @override
  String get featureWorldclock => 'عالمی گھڑی';

  @override
  String get featureZakat => 'زکوٰۃ کیلکولیٹر';

  @override
  String featuredCalmDays(int n) {
    return '$n دن';
  }

  @override
  String featuredCalmEach(int n) {
    return 'ہر ایک $n منٹ';
  }

  @override
  String get featuredCalmText =>
      'منصوبہ بندی، خرچ اور سکون کے لیے چھوٹے معمولات — ہر دن کے لیے ایک۔';

  @override
  String get featuredCalmTitle => 'زیادہ پُرسکون ہفتہ، سات قدموں میں';

  @override
  String get featuredDuasAudio => 'آڈیو شامل';

  @override
  String featuredDuasCount(int n) {
    return '$n دعائیں';
  }

  @override
  String get featuredDuasText =>
      'سفر، قطار اور سونے سے پہلے کے پُرسکون لمحے کے لیے مختصر دعائیں۔';

  @override
  String get featuredDuasTitle => 'عام دنوں کے لیے چالیس دعائیں';

  @override
  String get featuredFree => 'مفت';

  @override
  String featuredMinutes(int n) {
    return '$n منٹ';
  }

  @override
  String get fuelPetrol => 'پٹرول';

  @override
  String get fuelSourceOgra => 'اوگرا';

  @override
  String get greetAfternoon => 'سہ پہر بخیر';

  @override
  String get greetEvening => 'شام بخیر';

  @override
  String get greetLate => 'ابھی تک جاگ رہے ہیں';

  @override
  String get greetMorning => 'صبح بخیر';

  @override
  String greetNamed(String greeting, String name) {
    return '$greeting، $name';
  }

  @override
  String get greetWindDown => 'دن کا اختتام';

  @override
  String get habitFajr => 'فجر وقت پر';

  @override
  String get habitQuran => 'روزانہ قرآن';

  @override
  String get habitSteps => '6 ہزار قدم چلنا';

  @override
  String get habitWater => '8 گلاس';

  @override
  String get heroHighlights => 'نمایاں';

  @override
  String homeAyahProgress(int n, int total, int min) {
    return '$total میں سے آیت $n · تقریباً $min منٹ باقی';
  }

  @override
  String homeContinueSurah(String surah) {
    return '$surah جاری رکھیں';
  }

  @override
  String get homeDiscover => 'دریافت کریں';

  @override
  String get homeDiscoverSub => 'کیونکہ آپ اکثر یہ دیکھتے ہیں';

  @override
  String homeEffective(String date, String source) {
    return '$date سے نافذ · $source';
  }

  @override
  String homeFeelsLike(String temp) {
    return 'محسوس $temp';
  }

  @override
  String get homeGlance => 'ایک نظر میں';

  @override
  String get homeGlanceGeneral => 'اگلے چند گھنٹوں کی اہم باتیں';

  @override
  String get homeGlanceMuslim => 'نماز، تلاوت اور آگے کیا ہے';

  @override
  String get homeLiveNow => 'اس وقت';

  @override
  String homeLiveNowSub(String time) {
    return '$time تک';
  }

  @override
  String homeNextOutage(String time) {
    return 'اگلی بندش $time';
  }

  @override
  String get homeNextPrayer => 'اگلی نماز';

  @override
  String get homeNextUp => 'اگلا';

  @override
  String homeOutageArea(String area, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours گھنٹے',
      one: '1 گھنٹہ',
    );
    return '$area · $_temp0';
  }

  @override
  String get homeQuickDefault => 'سب سے زیادہ استعمال ہونے والے آٹھ';

  @override
  String get homeQuickFromInterests => 'آپ کی دلچسپیوں کے مطابق';

  @override
  String get homeQuickTools => 'فوری ٹولز';

  @override
  String get homeRightNow => 'اس وقت';

  @override
  String get homeSearchEverything => 'ہر چیز تلاش کریں';

  @override
  String homeTasksLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'آج $n کام باقی',
      one: 'آج 1 کام باقی',
      zero: 'آج کچھ باقی نہیں',
    );
    return '$_temp0';
  }

  @override
  String homeTasksNext(String task, String time) {
    return 'اگلا: $task · $time';
  }

  @override
  String get homeToGo => 'باقی';

  @override
  String homeTomorrowIn(String city) {
    return 'کل $city میں';
  }

  @override
  String get homeUpcoming => 'آنے والا';

  @override
  String get homeUpcomingSub => 'اگلے چند دن';

  @override
  String homeWeatherAnd(String temp, String condition) {
    return '$temp اور $condition';
  }

  @override
  String get homeYourProfile => 'آپ کا پروفائل';

  @override
  String get igEveryday => 'روزمرہ زندگی';

  @override
  String get igFaith => 'اسلامی خصوصیات';

  @override
  String get igHealth => 'صحت اور تندرستی';

  @override
  String get igMoney => 'پیسہ اور مالیات';

  @override
  String get igNews => 'خبریں اور تفریح';

  @override
  String get igTravel => 'سفر اور آمد و رفت';

  @override
  String get intAlarms => 'الارم اور ٹائمر';

  @override
  String get intBills => 'بل';

  @override
  String get intCalendar => 'کیلنڈر';

  @override
  String get intConvert => 'کنورٹر';

  @override
  String get intCricket => 'کرکٹ';

  @override
  String get intDuas => 'دعائیں اور ذکر';

  @override
  String get intExpenses => 'اخراجات';

  @override
  String get intFitness => 'فٹنس';

  @override
  String get intFlights => 'پروازیں';

  @override
  String get intFuel => 'ایندھن';

  @override
  String get intHabits => 'عادات';

  @override
  String get intHadith => 'حدیث';

  @override
  String get intMarkets => 'مارکیٹ';

  @override
  String get intMaths => 'کیلکولیٹر';

  @override
  String get intMeds => 'ادویات';

  @override
  String get intNearby => 'قریبی مقامات';

  @override
  String get intNews => 'خبریں';

  @override
  String get intNotes => 'نوٹس';

  @override
  String get intPrayer => 'نماز کے اوقات';

  @override
  String get intQuotes => 'روزانہ اقوال';

  @override
  String get intQuran => 'قرآن';

  @override
  String get intRamadan => 'رمضان';

  @override
  String get intRates => 'ریٹ اور سونا';

  @override
  String get intReading => 'مطالعہ';

  @override
  String get intSavings => 'بچت اور اہداف';

  @override
  String get intSleep => 'نیند';

  @override
  String get intTasks => 'کام اور فہرستیں';

  @override
  String get intTrains => 'ٹرینیں';

  @override
  String get intWater => 'پانی';

  @override
  String get intWeather => 'موسم';

  @override
  String get intZakat => 'زکوٰۃ اور صدقہ';

  @override
  String get loadshedOff => 'بجلی بند ہے';

  @override
  String loadshedUntil(String time) {
    return '$time تک';
  }

  @override
  String get marketPk => 'پاکستان';

  @override
  String get marketsClosed => 'مارکیٹ بند';

  @override
  String marketsHoliday(String holiday) {
    return '$holiday کی وجہ سے بند';
  }

  @override
  String get marketsOpen => 'مارکیٹ کھلی';

  @override
  String get marketsWeekend => 'ہفتہ وار تعطیل';

  @override
  String get methodEgyptian => 'مصری';

  @override
  String get methodIsna => 'ISNA';

  @override
  String get methodKarachi => 'جامعہ کراچی';

  @override
  String get methodMwl => 'رابطہ عالم اسلامی';

  @override
  String get methodUmmAlQura => 'ام القریٰ';

  @override
  String get navAccount => 'اکاؤنٹ';

  @override
  String get navExplore => 'دریافت';

  @override
  String get navHome => 'ہوم';

  @override
  String get navNotifications => 'اطلاعات';

  @override
  String get navProfile => 'پروفائل';

  @override
  String get navToday => 'آج';

  @override
  String get navTools => 'ٹولز';

  @override
  String get navTrains => 'ٹرینیں';

  @override
  String get nearbyChaiShai => 'چائے شائے';

  @override
  String nearbyChaiShaiSub(String time) {
    return 'پُرسکون کیفے · $time تک کھلا';
  }

  @override
  String get nearbyHillPark => 'ہل پارک';

  @override
  String get nearbyHillParkSub => 'غروب کی سیر کے لیے اچھا';

  @override
  String nearbyKilometres(String n) {
    return '$n کلومیٹر';
  }

  @override
  String nearbyMetres(int n) {
    return '$n میٹر';
  }

  @override
  String get nearbyTooba => 'مسجدِ طوبیٰ';

  @override
  String nearbyToobaSub(String time) {
    return 'عصر کی جماعت $time';
  }

  @override
  String get newsCatBusiness => 'کاروبار';

  @override
  String get newsCatKarachi => 'کراچی';

  @override
  String get newsCatMoney => 'پیسہ';

  @override
  String get newsCatProductivity => 'پیداواریت';

  @override
  String get newsCatSport => 'کھیل';

  @override
  String get newsCatWellbeing => 'بہبود';

  @override
  String get newsLoadshed =>
      'کے-الیکٹرک کا ستمبر کے لیے نظرِثانی شدہ لوڈشیڈنگ شیڈول کا اعلان';

  @override
  String newsReadTime(int n) {
    return '$n منٹ کا مطالعہ';
  }

  @override
  String get newsReset => 'دو منٹ کا وقفہ جو کافی بریک سے بہتر ہے';

  @override
  String get newsRupee =>
      'ترسیلاتِ زر میں مسلسل تیسرے ماہ اضافے پر روپیہ مستحکم';

  @override
  String get newsSavings => 'آپ کے پہلے بچت ہدف کی آسان رہنمائی';

  @override
  String get newsShortList => 'مختصر فہرست سے کام زیادہ کیوں ہوتے ہیں';

  @override
  String get newsSquad =>
      'پاکستان نے ہوم ٹیسٹ سیریز کے لیے اسکواڈ کا اعلان کر دیا';

  @override
  String get onbAllSet => 'سب تیار';

  @override
  String onbAtCap(String max) {
    return '$max تک — پہلے ایک ہٹائیں';
  }

  @override
  String get onbCityText =>
      'موسم، جہاں متعلقہ ہو نماز کے اوقات، اور مقامی چیزوں کے لیے۔';

  @override
  String get onbCityTitle => 'آپ کس شہر میں ہیں؟';

  @override
  String get onbEnterLume => 'لومے میں داخل ہوں';

  @override
  String get onbHereForText =>
      'پانچ سے دس منتخب کریں۔ آپ کا ہوم اسکرین، ٹولز اور مطالعہ انہی کے گرد بنتا ہے — جب چاہیں بدل لیں۔';

  @override
  String get onbHereForTitle => 'آپ یہاں کس لیے آئے ہیں؟';

  @override
  String get onbLocalKicker => 'مقامی بنائیں';

  @override
  String get onbMethodLabel => 'نماز کے حساب کا طریقہ';

  @override
  String onbMinimum(String count, String min) {
    return '$min میں سے $count کم از کم';
  }

  @override
  String get onbNameKicker => 'ایک آخری بات';

  @override
  String get onbNameLabel => 'ظاہر ہونے والا نام';

  @override
  String get onbNameNote => 'لومے یہ آپ کی ڈیوائس پر رکھتا ہے۔';

  @override
  String get onbNamePlaceholder => 'آپ کا نام';

  @override
  String get onbNameSkip => 'ابھی چھوڑ دیں';

  @override
  String get onbNameText =>
      'صرف سلام کے لیے۔ آپ بعد میں بدل سکتے ہیں یا چھوڑ سکتے ہیں۔';

  @override
  String get onbNameTitle => 'ہم آپ کو کیا کہہ کر پکاریں؟';

  @override
  String get onbOnDevice =>
      'لومے یہ سب آپ کی ڈیوائس پر رکھتا ہے۔ کچھ اپ لوڈ نہیں ہوتا۔';

  @override
  String get onbPermLocation => 'اپنا مقام استعمال کریں';

  @override
  String get onbPermLocationSub => 'موسم، مقامی خدمات اور قریبی مقامات کے لیے';

  @override
  String get onbPermLocationSubFaith =>
      'نماز کے اوقات، قبلہ، موسم اور قریبی مقامات کے لیے';

  @override
  String get onbPermNotify => 'نرم یاد دہانیاں';

  @override
  String get onbPermNotifySub =>
      'جن چیزوں پر نظر رکھنے کو کہا، ان کے لیے ہلکی سی یاد دہانی';

  @override
  String get onbPermNotifySubFaith =>
      'ہر اذان سے پانچ منٹ پہلے ہلکی سی یاد دہانی';

  @override
  String get onbPlanKicker => 'منصوبہ';

  @override
  String get onbPlanText =>
      'کام، یاد دہانیاں اور تقریبات ایک ہی ٹائم لائن پر — اور جو اہم ہے وہ پہلے ہی اپنی جگہ پر۔';

  @override
  String get onbPlanTitle => 'آپ کا دن، شروع ہونے سے پہلے ترتیب میں';

  @override
  String onbReadyFaith(String prayer) {
    return 'آپ کی اگلی نماز $prayer ہے، اور آج کا منصوبہ ہوم اسکرین پر منتظر ہے۔';
  }

  @override
  String get onbReadyGeneral => 'آج کا منصوبہ ہوم اسکرین پر منتظر ہے۔';

  @override
  String onbReadyNamed(String name) {
    return 'آپ تیار ہیں، $name';
  }

  @override
  String get onbReadyTitle => 'سب تیار ہے';

  @override
  String get onbRevisit =>
      'آپ یہ ٹور پروفائل سے کسی بھی وقت دوبارہ دیکھ سکتے ہیں۔';

  @override
  String onbSelected(String count, String max) {
    return '$max میں سے $count منتخب';
  }

  @override
  String get onbSetupText => 'دو اجازتیں، اور دونوں بعد میں بدلی جا سکتی ہیں۔';

  @override
  String get onbSetupTitle => 'ایک بار ترتیب دیں';

  @override
  String get onbSignInAction => 'سائن ان';

  @override
  String get onbSignInPrompt => 'پہلے سے اکاؤنٹ ہے؟';

  @override
  String get onbSkippedDefaults =>
      'ہمارے ڈیفالٹ کے ساتھ ترتیب — پروفائل میں بدلیں';

  @override
  String get onbSkippedTour => 'ٹور چھوڑ دیا — پروفائل میں دوبارہ ملے گا';

  @override
  String get onbToolsKicker => 'ٹولز';

  @override
  String get onbToolsText =>
      'کیلکولیٹر، کنورٹر، موسم، اسکینر، ریٹ، ٹریکر — ترتیب میں، تاکہ ڈھونڈنا نہ پڑے۔';

  @override
  String onbToolsTitle(String count) {
    return 'تقریباً $count ٹولز، ایک دو ٹیپ کی دوری پر';
  }

  @override
  String get onbWelcomeBack => 'لومے میں خوش آمدید';

  @override
  String get onbWelcomeText =>
      'منصوبے، پیسہ، سفر، مطالعہ اور وہ چھوٹے ٹولز جن تک آپ پہنچتے ہیں — بغیر بھرم کے۔';

  @override
  String get onbWelcomeTitle => 'آپ کے دن کی ہر ضرورت، خاموشی سے منظم۔';

  @override
  String get onbWhereText =>
      'یہ مقامی معلومات اور خدمات کو ذاتی بنانے میں مدد دیتا ہے۔ اس کا آپ کی شناخت سے کوئی تعلق نہیں۔';

  @override
  String get onbWhereTitle => 'آپ کہاں رہتے ہیں؟';

  @override
  String get onbYoursKicker => 'اپنی پسند';

  @override
  String parcelArrivesToday(String carrier) {
    return '$carrier · آج پہنچے گا';
  }

  @override
  String get parcelOutForDelivery => 'ترسیل کے لیے روانہ';

  @override
  String get persAllCountries => 'تمام ممالک';

  @override
  String get persIslamic => 'اسلامی خصوصیات';

  @override
  String get persIslamicSub => 'نماز کے اوقات، قرآن، دعائیں، زکوٰۃ اور رمضان';

  @override
  String get persPopular => 'مقبول';

  @override
  String get persRecent => 'حالیہ';

  @override
  String get persSearchCities => 'شہر تلاش کریں';

  @override
  String get persSearchCountries => 'ممالک تلاش کریں';

  @override
  String get persUseLocation => 'میرا موجودہ مقام استعمال کریں';

  @override
  String get prayerAsr => 'عصر';

  @override
  String get prayerDhuhr => 'ظہر';

  @override
  String get prayerFajr => 'فجر';

  @override
  String get prayerIsha => 'عشاء';

  @override
  String get prayerMaghrib => 'مغرب';

  @override
  String get qaDocscan => 'دستاویز اسکین کریں';

  @override
  String get qaExpense => 'خرچ شامل کریں';

  @override
  String get qaNote => 'نیا نوٹ';

  @override
  String get qaParcel => 'پارسل ٹریک کریں';

  @override
  String get qaScan => 'QR اسکین کریں';

  @override
  String get qaShop => 'خریداری';

  @override
  String get qaTasbih => 'تسبیح';

  @override
  String get qaTask => 'کام شامل کریں';

  @override
  String get qaTimer => 'ٹائمر شروع کریں';

  @override
  String get qaWater => 'پانی درج کریں';

  @override
  String get recConflict => 'یہ ریکارڈ کہیں اور بدل گیا';

  @override
  String get recConflictText =>
      'نیا ورژن موجود ہے۔ اپنی تبدیلیاں دیکھیں یا نیا ورژن لوڈ کریں۔';

  @override
  String get recDeleteFailed => 'یہ ریکارڈ حذف نہ ہو سکا';

  @override
  String recLoadError(Object noun) {
    return '$noun لوڈ نہیں ہو سکے';
  }

  @override
  String get recLoadErrorText =>
      'اپنا کنیکشن دیکھیں۔ آپ کا محفوظ ڈیٹا اسی ڈیوائس پر موجود ہے۔';

  @override
  String get recNothingToUndo => 'واپس لانے کو کچھ نہیں';

  @override
  String get recOffline => 'آپ آف لائن ہیں';

  @override
  String get recOfflineQueued =>
      'یہ یہیں محفوظ ہوگا اور واپسی پر ہم آہنگ ہو جائے گا۔';

  @override
  String get recOfflineText => 'اس ڈیوائس پر محفوظ ریکارڈ دکھائے جا رہے ہیں۔';

  @override
  String get recSaveFailed => 'تبدیلیاں محفوظ نہ ہو سکیں';

  @override
  String get recSaveFailedText =>
      'آپ کا لکھا ہوا کچھ ضائع نہیں ہوا۔ دوبارہ کوشش کریں۔';

  @override
  String get recordsNoSelectionText =>
      'یہاں دیکھنے کے لیے کوئی ریکارڈ منتخب کریں۔';

  @override
  String get recordsNoSelectionTitle => 'کچھ منتخب نہیں';

  @override
  String get routeMissingText =>
      'لنک پرانا ہو سکتا ہے، یا صفحہ منتقل ہو گیا ہو۔';

  @override
  String get routeMissingTitle => 'ہمیں وہ نہیں مل رہا';

  @override
  String get scoreAllOut => 'آل آؤٹ';

  @override
  String scoreOvers(String n) {
    return '$n اوور';
  }

  @override
  String scoreTrail(String team, int runs, String player, int score) {
    return '$team $runs رنز سے پیچھے · $player $score*';
  }

  @override
  String get scoreVersus => 'بمقابلہ';

  @override
  String get searchJumpBack => 'واپس جائیں';

  @override
  String get searchNothing => 'کچھ نہیں ملا';

  @override
  String get searchPlaceholder => 'کچھ بھی تلاش کریں — ٹولز، ریٹ، مقامات';

  @override
  String get searchTry => 'یہ تلاش کر کے دیکھیں';

  @override
  String get slideMoneyCta => 'پیسہ دیکھیں';

  @override
  String get slideMoneyKicker => 'پیسہ';

  @override
  String get slideMoneyText => 'ریٹ، بل اور اخراجات ایک جگہ۔';

  @override
  String get slideMoneyTitle => 'اپنے پیسوں پر نظر رکھیں';

  @override
  String slideOf(int n, int total) {
    return 'سلائیڈ $n از $total';
  }

  @override
  String get slidePlanCta => 'آج کھولیں';

  @override
  String get slidePlanKicker => 'آج';

  @override
  String get slidePlanText =>
      'کام، یاد دہانیاں اور مصروفیات ایک ہی ٹائم لائن پر۔';

  @override
  String get slidePlanTitle => 'دن شروع ہونے سے پہلے اس کی منصوبہ بندی';

  @override
  String get slidePrayerCta => 'نماز کے اوقات';

  @override
  String get slidePrayerKicker => 'آپ کی اگلی نماز';

  @override
  String slidePrayerLine(String time, String city) {
    return 'اذان $time · $city';
  }

  @override
  String get slideReadCta => 'جاری رکھیں';

  @override
  String get slideReadKicker => 'مطالعہ';

  @override
  String get slideReadText =>
      'آپ سورۃ الکہف کی 42 آیات تک پہنچ چکے ہیں۔ دو منٹ کافی ہیں۔';

  @override
  String get slideReadTitle => 'کچھ بامعنی پڑھیں';

  @override
  String get slideToolsCta => 'ٹولز دیکھیں';

  @override
  String get slideToolsKicker => 'ٹولز';

  @override
  String get slideToolsText => 'کیلکولیٹر، کنورٹر، اسکینر اور مزید۔';

  @override
  String get slideToolsTitle => 'کارآمد ٹولز، سب ایک جگہ';

  @override
  String get slideTrainsCta => 'ٹرین تلاش کریں';

  @override
  String get slideTrainsKicker => 'سفر';

  @override
  String get slideTrainsText => 'براہِ راست صورتحال، کرایہ اور نشستیں۔';

  @override
  String get slideTrainsTitle => 'ٹرینیں، بغیر اندازوں کے';

  @override
  String get startupLoading => 'Lume شروع ہو رہا ہے';

  @override
  String subsRenews(String date) {
    return '$date کو تجدید';
  }

  @override
  String get surahAlKahf => 'الکہف';

  @override
  String get taskAlKahf => 'سورہ الکہف کے دو صفحے پڑھیں';

  @override
  String get taskCallHome => 'گھر فون کریں';

  @override
  String get taskElectricity => 'بجلی کا بل ادا کریں';

  @override
  String get taskElectricityPk => 'کے-الیکٹرک کا بل ادا کریں';

  @override
  String get taskEmail => 'سارہ کی ای میل کا جواب دیں';

  @override
  String get taskEvening => 'شام';

  @override
  String get taskSummary => 'تیسری سہ ماہی کا خلاصہ مکمل کریں';

  @override
  String get todayAddToast => 'نیا کام شامل ہو گیا';

  @override
  String get todayAgendaGeneral => 'مصروفیات اور یاد دہانیاں، ترتیب سے';

  @override
  String get todayAgendaMuslim => 'نمازیں اور مصروفیات، ترتیب سے';

  @override
  String get todayAyah => 'آج کی آیت';

  @override
  String todayAyahCitation(String surah, String verse) {
    return '$surah $verse';
  }

  @override
  String todayAyahReference(String surah, String verse) {
    return '$surah · $verse';
  }

  @override
  String get todayDailyStreak => 'روزانہ تسلسل';

  @override
  String todayHabitSummary(String name, int done, int streak) {
    return '$name، سات میں سے $done دن، $streak دن کا تسلسل';
  }

  @override
  String get todayHabits => 'عادات';

  @override
  String get todayHabitsSub => 'پچھلے سات دن';

  @override
  String get todayOfDay => 'دن کا';

  @override
  String get todayOnTrack => 'سب ٹھیک چل رہا ہے';

  @override
  String get todayPrayerStreak => 'نماز کا تسلسل';

  @override
  String get todayPrivate => 'نجی';

  @override
  String get todayPrivateSub => 'صرف اسی ڈیوائس پر، صرف آپ کے لیے';

  @override
  String get todayPrivateText =>
      'ریکارڈ، ادویات اور اخراجات اُس وقت تک مقفل رہتے ہیں جب تک آپ خود نہ کھولیں۔';

  @override
  String get todayPrivateTitle => 'صحت، دستاویزات اور پیسہ';

  @override
  String get todayPrivateToast => 'نجی ریکارڈ دیکھنے کے لیے کھولیں';

  @override
  String get todayReadToday => 'آج پڑھا';

  @override
  String todayRingSummary(int done, int total, int meetings) {
    String _temp0 = intl.Intl.pluralLogic(
      meetings,
      locale: localeName,
      other: 'سہ پہر $meetings میٹنگیں باقی ہیں۔',
      one: 'سہ پہر ایک میٹنگ باقی ہے۔',
      zero: 'اور کچھ طے نہیں۔',
    );
    return '$total میں سے $done کام مکمل۔ $_temp0';
  }

  @override
  String get todaySteps => 'آج کے قدم';

  @override
  String get todayTaskDone => 'بہت خوب — ایک کام کم';

  @override
  String get todayTaskUndone => 'دوبارہ فہرست میں';

  @override
  String get todayTasks => 'کام';

  @override
  String get todayTasksDone => 'مکمل کام';

  @override
  String get todayTasksSub => 'مکمل کرنے کے لیے دبائیں';

  @override
  String get todayThought => 'آج کی بات';

  @override
  String get todayThoughtSub => 'ایک لمحے کا غور';

  @override
  String get todayWeekToast => 'ہفتہ وار منظر پر';

  @override
  String get todayYourDay => 'آپ کا دن';

  @override
  String get toolCategoryDaily => 'روزمرہ زندگی';

  @override
  String get toolCategoryEveryday => 'روزمرہ';

  @override
  String get toolCategoryIslamic => 'اسلامی';

  @override
  String get toolCategoryMoney => 'پیسہ';

  @override
  String get toolCategoryPersonal => 'ذاتی';

  @override
  String get toolCategoryPlanning => 'منصوبہ بندی';

  @override
  String get toolCategorySubDaily => 'آس پاس کیا ہو رہا ہے';

  @override
  String get toolCategorySubEveryday => 'جو روز کام آتے ہیں';

  @override
  String get toolCategorySubIslamic => 'نماز، قرآن اور صدقہ';

  @override
  String get toolCategorySubMoney => 'ریٹ، بل اور بجٹ';

  @override
  String get toolCategorySubPersonal => 'صرف آپ کے لیے، اسی ڈیوائس پر';

  @override
  String get toolCategorySubPlanning => 'آپ کا وقت اور فہرستیں';

  @override
  String get toolErrorText =>
      'ہم اسے لوڈ نہیں کر سکے۔ ایک لمحے بعد دوبارہ کوشش کریں۔';

  @override
  String get toolErrorTitle => 'کچھ غلط ہو گیا';

  @override
  String get toolLoading => 'لوڈ ہو رہا ہے';

  @override
  String get toolLocalService => 'مقامی سہولت';

  @override
  String toolNeedsAttention(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n پر توجہ درکار',
      one: '1 پر توجہ درکار',
    );
    return '$_temp0';
  }

  @override
  String get toolPrivate => 'نجی';

  @override
  String get toolPrivateText =>
      'یہ معلومات آپ کے آلے پر رہتی ہیں اور کبھی شیئر نہیں کی جاتیں۔';

  @override
  String get toolPrivateTitle => 'صرف آپ کے لیے';

  @override
  String get toolStatusAge => 'دنوں تک درست';

  @override
  String get toolStatusAlarms => '2 مقرر';

  @override
  String get toolStatusAqi => 'ہوا کا معیار';

  @override
  String get toolStatusAyah => 'الرعد 28';

  @override
  String get toolStatusBabybudget => 'اخراجات کا منصوبہ';

  @override
  String get toolStatusBills => '2 واجب';

  @override
  String get toolStatusBirthdays => 'عائشہ 4 دن میں';

  @override
  String get toolStatusBmi => 'وزن دیکھیں';

  @override
  String get toolStatusCalculator => 'سادہ';

  @override
  String get toolStatusCalendar => '3 مصروفیات';

  @override
  String get toolStatusCommittee => '10 میں سے مہینہ 4';

  @override
  String get toolStatusCompound => 'نمو کا اندازہ';

  @override
  String get toolStatusConverter => '32 اکائیاں';

  @override
  String get toolStatusCricket => 'PAK 214/4';

  @override
  String get toolStatusCurrency => 'براہِ راست ریٹ';

  @override
  String get toolStatusCycle => 'نجی';

  @override
  String get toolStatusDatecalc => 'جمع · فرق';

  @override
  String get toolStatusDocscan => 'PDF تیار';

  @override
  String get toolStatusDocuments => 'مقفل';

  @override
  String get toolStatusDuas => '42 محفوظ';

  @override
  String get toolStatusEmergency => '15 · 1122';

  @override
  String get toolStatusEvents => 'اگلا 14:00';

  @override
  String get toolStatusExpenses => 'اس مہینے';

  @override
  String get toolStatusFaraid => 'وراثت';

  @override
  String get toolStatusFasting => '3 روزے';

  @override
  String get toolStatusFlights => 'براہِ راست دیکھیں';

  @override
  String get toolStatusFocus => '25 منٹ';

  @override
  String get toolStatusFuel => 'پمپ کی قیمتیں';

  @override
  String get toolStatusFuelcost => 'سفر کا خرچ';

  @override
  String get toolStatusGoals => '2 فعال';

  @override
  String get toolStatusGoldrates => 'سونا اور کرنسی';

  @override
  String get toolStatusHabits => '12 دن کا تسلسل';

  @override
  String get toolStatusHadith => 'روزانہ';

  @override
  String get toolStatusHealth => 'نجی';

  @override
  String get toolStatusHijri => '15 ربیع الاول';

  @override
  String get toolStatusHolidays => 'اس سال';

  @override
  String get toolStatusInstallments => '3 جاری';

  @override
  String get toolStatusLearning => '3 کورس';

  @override
  String get toolStatusLedger => '3 افراد';

  @override
  String get toolStatusLoadshed => '14:00–16:00';

  @override
  String get toolStatusLoan => 'اقساط';

  @override
  String get toolStatusMarkets => 'KSE-100 ▲ 0.8%';

  @override
  String get toolStatusMealplan => 'اس ہفتے';

  @override
  String get toolStatusMediasaver => 'پوسٹس محفوظ کریں';

  @override
  String get toolStatusMeds => 'نجی';

  @override
  String get toolStatusMosques => '1 کلومیٹر میں 3';

  @override
  String get toolStatusNames99 => 'اسماء الحسنیٰ';

  @override
  String get toolStatusNatsavings => 'منافع کی شرح';

  @override
  String get toolStatusNews => '12 نئی';

  @override
  String get toolStatusNotes => '12 محفوظ';

  @override
  String get toolStatusPackages => 'Jazz · Zong';

  @override
  String get toolStatusParcel => '1 راستے میں';

  @override
  String get toolStatusPassport => 'نادرا سائز';

  @override
  String get toolStatusPlay => 'پہیلیاں';

  @override
  String get toolStatusPrayer => 'عصر 15:53';

  @override
  String get toolStatusPraytrack => '12 دن کا تسلسل';

  @override
  String get toolStatusPregnancy => 'نجی';

  @override
  String get toolStatusPrizebonds => 'قرعہ 15 ستمبر';

  @override
  String get toolStatusQibla => '267° مغرب';

  @override
  String get toolStatusQr => 'اسکین اور ادائیگی';

  @override
  String get toolStatusQuran => 'الکہف 42';

  @override
  String get toolStatusQuransearch => 'لفظ سے';

  @override
  String get toolStatusRamadan => '172 دن میں';

  @override
  String get toolStatusRecipes => '24 محفوظ';

  @override
  String get toolStatusReminders => 'آج 4';

  @override
  String get toolStatusShopping => '6 اشیاء';

  @override
  String get toolStatusSpeedtest => 'ابھی جانچیں';

  @override
  String get toolStatusStopwatch => 'لیپ';

  @override
  String get toolStatusStreak => '12 دن';

  @override
  String get toolStatusSubs => '6 فعال';

  @override
  String get toolStatusSunmoon => 'طلوع · غروب';

  @override
  String get toolStatusTaraweeh => 'رمضان';

  @override
  String get toolStatusTasbih => 'شمار';

  @override
  String get toolStatusTax => 'FBR 2025-26';

  @override
  String get toolStatusTimer => 'تیار سیٹنگز';

  @override
  String get toolStatusTipsplit => 'بل تقسیم کریں';

  @override
  String get toolStatusTodos => '5 میں سے 2 مکمل';

  @override
  String get toolStatusTrains => 'گرین لائن';

  @override
  String get toolStatusVaccines => 'نجی';

  @override
  String get toolStatusVehicle => 'چالان دیکھیں';

  @override
  String get toolStatusWastatus => 'اینڈرائیڈ';

  @override
  String get toolStatusWater => '5 / 8';

  @override
  String get toolStatusWeather => '34° صاف';

  @override
  String get toolStatusWorldclock => '8 شہر';

  @override
  String get toolStatusZakat => 'نصاب دیکھیں';

  @override
  String toolUnavailableHere(String country) {
    return 'ابھی $country میں دستیاب نہیں';
  }

  @override
  String get toolUnavailableText => 'یہ ٹول آپ کے سیٹ اپ کا حصہ نہیں ہے۔';

  @override
  String get toolUnavailableTitle => 'آپ کے سیٹ اپ کا حصہ نہیں';

  @override
  String get toolsForYou => 'آپ کے لیے';

  @override
  String get toolsNoMatch => 'کوئی ٹول نہیں ملا';

  @override
  String get toolsNoMatchSub =>
      'کوئی اور لفظ آزمائیں — یا اوپر سے کوئی زمرہ دیکھیں۔';

  @override
  String get toolsNothingYet => 'ابھی یہاں کچھ نہیں';

  @override
  String get toolsNothingYetSub =>
      'کچھ اور دلچسپیاں شامل کریں، یا “سب” میں پوری فہرست دیکھیں۔';

  @override
  String get toolsPersonalise => 'ذاتی بنائیں';

  @override
  String get toolsRecent => 'حال ہی میں استعمال شدہ';

  @override
  String get toolsRecentSub => 'جہاں چھوڑا تھا وہیں سے';

  @override
  String toolsResultCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ٹولز',
      one: '1 ٹول',
      zero: 'کوئی ٹول نہیں',
    );
    return '$_temp0';
  }

  @override
  String get toolsSearchExample => 'کرنسی';

  @override
  String get toolsSearchExamplePk => 'پٹرول';

  @override
  String toolsSearchHint(String example) {
    return 'ٹولز تلاش کریں — مثلاً “$example”';
  }

  @override
  String get toolsSearchLabel => 'ٹولز تلاش کریں';

  @override
  String toolsSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n سہولتیں، ترتیب سے',
      one: '1 سہولت، ترتیب سے',
    );
    return '$_temp0';
  }

  @override
  String get toolsTitle => 'ٹولز';

  @override
  String get unitDays => 'دن';

  @override
  String get unitKmh => 'کلومیٹر/گھنٹہ';

  @override
  String get unitMinutes => 'منٹ';

  @override
  String get unitMph => 'میل/گھنٹہ';

  @override
  String unitOfTotal(int total) {
    return '/$total';
  }

  @override
  String get unitThousand => 'ہزار';

  @override
  String get weatherClear => 'صاف';

  @override
  String get weatherClearVeryWarm => 'صاف · بہت گرم';

  @override
  String get weatherCloudBuilding => 'بادل بن رہے ہیں';

  @override
  String get weatherHazy => 'دھندلا';

  @override
  String get weatherHazySun => 'دھندلی دھوپ';

  @override
  String get weatherHazySunHumid => 'دھندلی دھوپ · حبس';

  @override
  String weatherHighLow(String high, String low) {
    return '$high / $low';
  }

  @override
  String get weatherHumidLightHaze => 'حبس · ہلکی دھند';

  @override
  String get weatherLightCloud => 'ہلکے بادل';

  @override
  String get weatherMostlyClear => 'زیادہ تر صاف';

  @override
  String get weatherOvercast => 'ابر آلود';

  @override
  String get weatherRain => 'بارش';
}
