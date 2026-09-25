/// The words Prize Bonds draws that its data does not carry.
library;

import '../data/prizebonds_fixtures.dart';

abstract final class LumePrizebondsText {
  /// `act: 'toast:' + b.draw + ' · ' + b.date` — what tapping a draws row
  /// toasts.
  static String drawToast(LumePrizeBond b) => '${b.draw} · ${b.date}';
}
