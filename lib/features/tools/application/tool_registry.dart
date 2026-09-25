/// The tools that have been converted, by catalogue id.
///
/// `registry.js` imports all 85 modules by name and refuses a mismatch at
/// load. Flutter converts them in archetype waves (`TOOL_INVENTORY.md` §5), so
/// this map names only the tools that are built; every other catalogue id still
/// resolves, through the same gate, to the fixture tool screen.
/// `inventory_tools.mjs` reads this file to report which are built.
library;

import 'package:flutter/widgets.dart';

import '../../age/presentation/age_tool.dart';
import '../../alarms/presentation/alarms_tool.dart';
import '../../aqi/presentation/aqi_tool.dart';
import '../../bills/presentation/bills_tool.dart';
import '../../birthdays/presentation/birthdays_tool.dart';
import '../../bmi/presentation/bmi_tool.dart';
import '../../converter/presentation/converter_tool.dart';
import '../../calendar/presentation/calendar_tool.dart';
import '../../compound/presentation/compound_tool.dart';
import '../../cricket/presentation/cricket_tool.dart';
import '../../currency/presentation/currency_tool.dart';
import '../../cycle/presentation/cycle_tool.dart';
import '../../datecalc/presentation/datecalc_tool.dart';
import '../../docscan/presentation/docscan_tool.dart';
import '../../documents/presentation/documents_tool.dart';
import '../../duas/presentation/duas_tool.dart';
import '../../emergency/presentation/emergency_tool.dart';
import '../../events/presentation/events_tool.dart';
import '../../expenses/presentation/expenses_tool.dart';
import '../../faraid/presentation/faraid_tool.dart';
import '../../fasting/presentation/fasting_tool.dart';
import '../../fuel/presentation/fuel_tool.dart';
import '../../fuel/presentation/fuelcost_tool.dart';
import '../../hijri/presentation/hijri_tool.dart';
import '../../holidays/presentation/holidays_tool.dart';
import '../../loadshed/presentation/loadshed_tool.dart';
import '../../markets/presentation/markets_tool.dart';
import '../../mediasaver/presentation/mediasaver_tool.dart';
import '../../mosques/presentation/mosques_tool.dart';
import '../../names99/presentation/names99_tool.dart';
import '../../natsavings/presentation/natsavings_tool.dart';
import '../../packages/presentation/packages_tool.dart';
import '../../parcel/presentation/parcel_tool.dart';
import '../../passport/presentation/passport_tool.dart';
import '../../prayer/presentation/prayer_tool.dart';
import '../../praytrack/presentation/praytrack_tool.dart';
import '../../prizebonds/presentation/prizebonds_tool.dart';
import '../../quran/presentation/ayah_tool.dart';
import '../../quran/presentation/quran_tool.dart';
import '../../quran/presentation/quransearch_tool.dart';
import '../../ramadan/presentation/ramadan_tool.dart';
import '../../speedtest/presentation/speedtest_tool.dart';
import '../../taraweeh/presentation/taraweeh_tool.dart';
import '../../trains/presentation/trains_tool.dart';
import '../../vehicle/presentation/vehicle_tool.dart';
import '../../wastatus/presentation/wastatus_tool.dart';
import '../../babybudget/presentation/babybudget_tool.dart';
import '../../calculator/presentation/calculator_tool.dart';
import '../../focus/presentation/focus_tool.dart';
import '../../goals/presentation/goals_tool.dart';
import '../../habits/presentation/habits_tool.dart';
import '../../health/presentation/health_tool.dart';
import '../../meds/presentation/meds_tool.dart';
import '../../mealplan/presentation/mealplan_tool.dart';
import '../../pregnancy/presentation/pregnancy_tool.dart';
import '../../qibla/presentation/qibla_tool.dart';
import '../../reminders/presentation/reminder_tool.dart';
import '../../streak/presentation/streak_tool.dart';
import '../../subscriptions/presentation/subscriptions_tool.dart';
import '../../tasbih/presentation/tasbih_tool.dart';
import '../../vaccines/presentation/vaccines_tool.dart';
import '../../worldclock/presentation/worldclock_tool.dart';
import '../../play/presentation/play_tool.dart';
import '../../committee/presentation/committee_tool.dart';
import '../../flights/presentation/flights_tool.dart';
import '../../goldrates/presentation/goldrates_tool.dart';
import '../../hadith/presentation/hadith_tool.dart';
import '../../learning/presentation/learning_tool.dart';
import '../../installments/presentation/installments_tool.dart';
import '../../ledger/presentation/ledger_tool.dart';
import '../../loan/presentation/loan_tool.dart';
import '../../news/presentation/news_tool.dart';
import '../../notes/presentation/notes_tool.dart';
import '../../qr/presentation/qr_tool.dart';
import '../../recipes/presentation/recipes_tool.dart';
import '../../shopping/presentation/shopping_tool.dart';
import '../../stopwatch/presentation/stopwatch_tool.dart';
import '../../sunmoon/presentation/sunmoon_tool.dart';
import '../../tax/presentation/tax_tool.dart';
import '../../timer/presentation/timer_tool.dart';
import '../../tipsplit/presentation/tipsplit_tool.dart';
import '../../todos/presentation/todos_tool.dart';
import '../../water/presentation/water_tool.dart';
import '../../weather/presentation/weather_tool.dart';
import '../../zakat/presentation/zakat_tool.dart';
import 'tool_request.dart';

/// Builds one converted tool for an opening the gate has allowed.
typedef LumeToolBuilder = Widget Function(LumeToolRequest request);

const Map<String, LumeToolBuilder> kLumeToolRegistry =
    <String, LumeToolBuilder>{
      'tax': LumeTaxTool.build,
      'learning': LumeLearningTool.open,
      'timer': LumeTimerTool.open,
      'emergency': LumeEmergencyTool.open,
      'recipes': LumeRecipesTool.open,
      'news': LumeNewsTool.open,
      'calendar': LumeCalendarTool.open,
      'goldrates': LumeGoldratesTool.open,
      'flights': LumeFlightsTool.open,
      'expenses': LumeExpensesTool.open,
      'documents': LumeDocumentsTool.open,
      'weather': LumeWeatherTool.open,
      'hadith': LumeHadithTool.open,
      'qr': LumeQrTool.open,
      // F6B rollout wave 1 (`ROLLOUT_WAVE_1.md`).
      'age': LumeAgeTool.open,
      'datecalc': LumeDatecalcTool.open,
      'tipsplit': LumeTipsplitTool.open,
      'loan': LumeLoanTool.open,
      'compound': LumeCompoundTool.open,
      'stopwatch': LumeStopwatchTool.open,
      // Rollout wave 2 (`ROLLOUT_WAVE_2.md`).
      'notes': LumeNotesTool.open,
      'todos': LumeTodosTool.open,
      'events': LumeEventsTool.open,
      'shopping': LumeShoppingTool.open,
      'sunmoon': LumeSunmoonTool.open,
      // Lending Ledger, on its own host (`LEDGER_PROPOSAL.md`, D10).
      'ledger': LumeLedgerTool.open,
      // Installments, on its own host (`INSTALLMENTS_PROPOSAL.md` §40).
      'installments': LumeInstallmentsTool.open,
      // Committee, on its own host (`COMMITTEE_PROPOSAL.md` D-C13).
      'committee': LumeCommitteeTool.open,
      // Baby Budget, on its own host (`BABY_BUDGET_PROPOSAL.md` D-B13).
      'babybudget': LumeBabyBudgetTool.open,
      // Wave 3 (`ROLLOUT_WAVE_3.md`).
      'focus': LumeFocusTool.open,
      'play': LumePlayTool.open,
      'calculator': LumeCalculatorTool.open,
      'tasbih': LumeTasbihTool.open,
      'worldclock': LumeWorldClockTool.open,
      // Wave 4 (`ROLLOUT_WAVE_4.md`).
      'converter': LumeConverterTool.open,
      'birthdays': LumeBirthdaysTool.open,
      'water': LumeWaterTool.open,
      // Wave 5 (`ROLLOUT_WAVE_5.md`).
      'goals': LumeGoalsTool.open,
      'subs': LumeSubscriptionsTool.open,
      // Wave 6 (`ROLLOUT_WAVE_6.md`).
      'mealplan': LumeMealPlanTool.open,
      // Wave 7 (`ROLLOUT_WAVE_7.md`).
      'reminders': LumeReminderTool.open,
      // Wave 8: ten tools built in parallel, without a per-tool discovery
      // gate (the owner's own explicit choice after Wave 7's discovery
      // found nothing left that clears alone).
      'bmi': LumeBmiTool.open,
      'habits': LumeHabitsTool.open,
      'streak': LumeStreakTool.open,
      'meds': LumeMedsTool.open,
      'vaccines': LumeVaccinesTool.open,
      'health': LumeHealthTool.open,
      'cycle': LumeCycleTool.open,
      'pregnancy': LumePregnancyTool.open,
      'qibla': LumeQiblaTool.open,
      'zakat': LumeZakatTool.open,
      // Wave 9: sixteen tools built in parallel, "do the same as web" —
      // porting the reference's own real (fixture) data faithfully, no
      // live network calls anywhere (`ROLLOUT_WAVE_9.md`).
      'quran': LumeQuranTool.open,
      'quransearch': LumeQuranSearchTool.open,
      'ayah': LumeAyahTool.open,
      'duas': LumeDuasTool.open,
      'names99': LumeNames99Tool.open,
      'currency': LumeCurrencyTool.open,
      'fuel': LumeFuelTool.open,
      'fuelcost': LumeFuelcostTool.open,
      'markets': LumeMarketsTool.open,
      'natsavings': LumeNatSavingsTool.open,
      'prizebonds': LumePrizebondsTool.open,
      'bills': LumeBillsTool.open,
      'packages': LumePackagesTool.open,
      'cricket': LumeCricketTool.open,
      'aqi': LumeAqiTool.open,
      'loadshed': LumeLoadshedTool.open,
      'trains': LumeTrainsTool.open,
      'holidays': LumeHolidaysTool.open,
      'parcel': LumeParcelTool.open,
      // Wave 10: fifteen tools built in parallel — Islamic worship
      // features (real astronomical/calendar math, or real reader-record
      // trackers where the reference itself had no schema) plus a batch
      // of device-capability tools (`ROLLOUT_WAVE_10.md`).
      'prayer': LumePrayerTool.open,
      'praytrack': LumePrayTrackTool.open,
      'fasting': LumeFastingTool.open,
      'ramadan': LumeRamadanTool.open,
      'taraweeh': LumeTaraweehTool.open,
      'faraid': LumeFaraidTool.open,
      'hijri': LumeHijriTool.open,
      'mosques': LumeMosquesTool.open,
      'docscan': LumeDocScanTool.open,
      'mediasaver': LumeMediaSaverTool.open,
      'speedtest': LumeSpeedtestTool.open,
      'vehicle': LumeVehicleTool.open,
      'wastatus': LumeWastatusTool.open,
      'passport': LumePassportTool.open,
      'alarms': LumeAlarmsTool.open,
    };
