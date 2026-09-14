/// The tools that have been converted, by catalogue id.
///
/// `registry.js` imports all 85 modules by name and refuses a mismatch at
/// load. Flutter converts them in archetype waves (`TOOL_INVENTORY.md` §5), so
/// this map names only the tools that are built; every other catalogue id still
/// resolves, through the same gate, to the fixture tool screen.
/// `inventory_tools.mjs` reads this file to report which are built.
library;

import 'package:flutter/widgets.dart';

import '../../calendar/presentation/calendar_tool.dart';
import '../../emergency/presentation/emergency_tool.dart';
import '../../goldrates/presentation/goldrates_tool.dart';
import '../../learning/presentation/learning_tool.dart';
import '../../news/presentation/news_tool.dart';
import '../../recipes/presentation/recipes_tool.dart';
import '../../tax/presentation/tax_tool.dart';
import '../../timer/presentation/timer_tool.dart';
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
    };
