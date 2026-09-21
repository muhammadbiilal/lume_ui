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
import '../../calendar/presentation/calendar_tool.dart';
import '../../compound/presentation/compound_tool.dart';
import '../../datecalc/presentation/datecalc_tool.dart';
import '../../documents/presentation/documents_tool.dart';
import '../../emergency/presentation/emergency_tool.dart';
import '../../events/presentation/events_tool.dart';
import '../../expenses/presentation/expenses_tool.dart';
import '../../babybudget/presentation/babybudget_tool.dart';
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
import '../../weather/presentation/weather_tool.dart';
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
    };
