/* ============================================================
   Lume — the tool registry

   Every one of the 85 tools, imported by name. The list being
   explicit is the point: a tool that is not here does not
   exist, and a tool that is here is checked against the
   catalogue before the app finishes booting.

   install() refuses four things rather than letting any of them
   become a mystery later:

     · a catalogue feature with no module — the tool would be
       listed, be searchable, and open to nothing;
     · a module with no catalogue entry — unreachable code that
       still claims an id;
     · the same id twice;
     · a module that does not declare an id at all.

   The check runs as this module evaluates, not when someone
   remembers to call it. That is deliberate: main.js imports this
   above the shell, so the registry is complete and verified
   before anything can open a tool. A registry that is quietly
   wrong would otherwise fail at the moment a user taps
   something.
   ============================================================ */
import { LUME_TOOLS } from './engine.js';
import { LUME } from '../data/catalogue.js';
/* everyday — 8 */
import ageTool from './everyday/age.tool.js';
import calculatorTool from './everyday/calculator.tool.js';
import converterTool from './everyday/converter.tool.js';
import currencyTool from './everyday/currency.tool.js';
import datecalcTool from './everyday/datecalc.tool.js';
import focusTool from './everyday/focus.tool.js';
import stopwatchTool from './everyday/stopwatch.tool.js';
import timerTool from './everyday/timer.tool.js';

/* planning — 5 */
import calendarTool from './planning/calendar.tool.js';
import eventsTool from './planning/events.tool.js';
import notesTool from './planning/notes.tool.js';
import remindersTool from './planning/reminders.tool.js';
import todosTool from './planning/todos.tool.js';

/* islamic — 17 */
import ayahTool from './islamic/ayah.tool.js';
import duasTool from './islamic/duas.tool.js';
import faraidTool from './islamic/faraid.tool.js';
import fastingTool from './islamic/fasting.tool.js';
import hadithTool from './islamic/hadith.tool.js';
import hijriTool from './islamic/hijri.tool.js';
import mosquesTool from './islamic/mosques.tool.js';
import names99Tool from './islamic/names99.tool.js';
import prayerTool from './islamic/prayer.tool.js';
import praytrackTool from './islamic/praytrack.tool.js';
import qiblaTool from './islamic/qibla.tool.js';
import quranTool from './islamic/quran.tool.js';
import quransearchTool from './islamic/quransearch.tool.js';
import ramadanTool from './islamic/ramadan.tool.js';
import taraweehTool from './islamic/taraweeh.tool.js';
import tasbihTool from './islamic/tasbih.tool.js';
import zakatTool from './islamic/zakat.tool.js';

/* money — 15 */
import billsTool from './money/bills.tool.js';
import committeeTool from './money/committee.tool.js';
import compoundTool from './money/compound.tool.js';
import fuelTool from './money/fuel.tool.js';
import fuelcostTool from './money/fuelcost.tool.js';
import goldratesTool from './money/goldrates.tool.js';
import installmentsTool from './money/installments.tool.js';
import ledgerTool from './money/ledger.tool.js';
import loanTool from './money/loan.tool.js';
import marketsTool from './money/markets.tool.js';
import natsavingsTool from './money/natsavings.tool.js';
import packagesTool from './money/packages.tool.js';
import prizebondsTool from './money/prizebonds.tool.js';
import taxTool from './money/tax.tool.js';
import tipsplitTool from './money/tipsplit.tool.js';

/* daily — 18 */
import aqiTool from './daily/aqi.tool.js';

import cricketTool from './daily/cricket.tool.js';
import docscanTool from './daily/docscan.tool.js';
import emergencyTool from './daily/emergency.tool.js';
import flightsTool from './daily/flights.tool.js';
import holidaysTool from './daily/holidays.tool.js';
import loadshedTool from './daily/loadshed.tool.js';
import mediasaverTool from './daily/mediasaver.tool.js';
import newsTool from './daily/news.tool.js';
import passportTool from './daily/passport.tool.js';
import qrTool from './daily/qr.tool.js';
import speedtestTool from './daily/speedtest.tool.js';
import sunmoonTool from './daily/sunmoon.tool.js';
import trainsTool from './daily/trains.tool.js';
import vehicleTool from './daily/vehicle.tool.js';
import wastatusTool from './daily/wastatus.tool.js';
import weatherTool from './daily/weather.tool.js';
import worldclockTool from './daily/worldclock.tool.js';

/* personal — 22 */
import alarmsTool from './personal/alarms.tool.js';
import babybudgetTool from './personal/babybudget.tool.js';
import birthdaysTool from './personal/birthdays.tool.js';
import bmiTool from './personal/bmi.tool.js';
import cycleTool from './personal/cycle.tool.js';
import documentsTool from './personal/documents.tool.js';
import expensesTool from './personal/expenses.tool.js';
import goalsTool from './personal/goals.tool.js';
import habitsTool from './personal/habits.tool.js';
import healthTool from './personal/health.tool.js';
import learningTool from './personal/learning.tool.js';
import mealplanTool from './personal/mealplan.tool.js';
import medsTool from './personal/meds.tool.js';
import parcelTool from './personal/parcel.tool.js';
import playTool from './personal/play.tool.js';
import pregnancyTool from './personal/pregnancy.tool.js';
import recipesTool from './personal/recipes.tool.js';
import shoppingTool from './personal/shopping.tool.js';
import streakTool from './personal/streak.tool.js';
import subsTool from './personal/subs.tool.js';
import vaccinesTool from './personal/vaccines.tool.js';
import waterTool from './personal/water.tool.js';

const MODULES = [
  ageTool,
  calculatorTool,
  converterTool,
  currencyTool,
  datecalcTool,
  focusTool,
  stopwatchTool,
  timerTool,
  calendarTool,
  eventsTool,
  notesTool,
  remindersTool,
  todosTool,
  ayahTool,
  duasTool,
  faraidTool,
  fastingTool,
  hadithTool,
  hijriTool,
  mosquesTool,
  names99Tool,
  prayerTool,
  praytrackTool,
  qiblaTool,
  quranTool,
  quransearchTool,
  ramadanTool,
  taraweehTool,
  tasbihTool,
  zakatTool,
  billsTool,
  committeeTool,
  compoundTool,
  fuelTool,
  fuelcostTool,
  goldratesTool,
  installmentsTool,
  ledgerTool,
  loanTool,
  marketsTool,
  natsavingsTool,
  packagesTool,
  prizebondsTool,
  taxTool,
  tipsplitTool,
  aqiTool,
  bmiTool,
  cricketTool,
  docscanTool,
  emergencyTool,
  flightsTool,
  holidaysTool,
  loadshedTool,
  mediasaverTool,
  newsTool,
  passportTool,
  qrTool,
  speedtestTool,
  sunmoonTool,
  trainsTool,
  vehicleTool,
  wastatusTool,
  weatherTool,
  worldclockTool,
  alarmsTool,
  babybudgetTool,
  birthdaysTool,
  cycleTool,
  documentsTool,
  expensesTool,
  goalsTool,
  habitsTool,
  healthTool,
  learningTool,
  mealplanTool,
  medsTool,
  parcelTool,
  playTool,
  pregnancyTool,
  recipesTool,
  shoppingTool,
  streakTool,
  subsTool,
  vaccinesTool,
  waterTool
];

function install(registry, catalogue) {
  const seen = new Set();

  MODULES.forEach(function (mod) {
    if (!mod || !mod.id) throw new Error('a tool module declares no id');
    if (typeof mod.build !== 'function') {
      throw new Error('tool module ' + mod.id + ' declares no build()');
    }
    if (seen.has(mod.id)) throw new Error('duplicate tool module: ' + mod.id);
    seen.add(mod.id);
    registry.register(mod.id, mod.build);
  });

  const known = new Set(catalogue.FEATURES.map(function (f) { return f.id; }));

  const orphans = MODULES.map(function (m) { return m.id; })
    .filter(function (id) { return !known.has(id); });
  if (orphans.length) {
    throw new Error('tool modules with no catalogue entry: ' + orphans.join(', '));
  }

  const missing = [...known].filter(function (id) { return !seen.has(id); });
  if (missing.length) {
    throw new Error('catalogue features with no tool module: ' + missing.join(', '));
  }

  return [...seen];
}

/* Installed and checked as this module evaluates. */
export const INSTALLED = install(LUME_TOOLS, LUME);
