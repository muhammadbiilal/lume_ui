/* ============================================================
   Lume — the screen set

   Every top-level destination, in the order it occupies the
   outlet. The order is part of the design rather than an
   accident of registration: screens are siblings in one <main>,
   and the stylesheet and the reading order both depend on Home
   coming first and the overlay destinations coming last.
   ============================================================ */
import { createHomeScreen } from './home.screen.js';
import { createToolsScreen } from './tools.screen.js';
import { createTrainsScreen } from './trains.screen.js';
import { createTodayScreen } from './today.screen.js';
import { createExploreScreen } from './explore.screen.js';
import { createProfileScreen } from './profile.screen.js';
import { createAccountScreen } from './account.screen.js';
import { createAuthScreen } from './auth.screen.js';
import { createNotificationsScreen } from './notifications.screen.js';
import { createToolHostScreen } from './tool.screen.js';

export function createScreens(deps) {
  return [
    createHomeScreen(deps),
    createToolsScreen(deps),
    createTrainsScreen(deps),
    createTodayScreen(deps),
    createExploreScreen(deps),
    createProfileScreen(deps),
    createAccountScreen(deps),
    createAuthScreen(deps),
    createNotificationsScreen(deps),
    createToolHostScreen(deps)
  ];
}
