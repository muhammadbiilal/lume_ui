/// The application language.
///
/// `null` means "follow the device", which is the first-run state and is
/// resolved by `LumeLocales.resolve` against the three languages Lume ships.
///
/// **Language is not read from country.** A user in Pakistan reading English,
/// a user in the UK reading Urdu and a user in Japan reading Arabic are all
/// ordinary, and nothing anywhere may infer one dimension from the other.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chosen language, or `null` to follow the device.
final StateProvider<Locale?> localeProvider = StateProvider<Locale?>(
  (Ref ref) => null,
);
