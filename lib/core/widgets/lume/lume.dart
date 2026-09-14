/// The Lume component system.
///
/// One import for every shared widget. Screens take this; they do not reach
/// into the individual files, so moving a widget between them is not a
/// breaking change.
///
/// Every widget here was measured against the rendered prototype rather than
/// transcribed from its stylesheet — see
/// `docs/conversion_archive/COMPONENT_MATRIX.md` for what each one maps to and
/// `test/core/widgets/component_parity_test.dart` for the assertions that keep
/// them honest.
library;

export 'lume_badge.dart';
export 'lume_button.dart';
export 'lume_chip.dart';
export 'lume_crud.dart';
export 'lume_field.dart';
export 'lume_header.dart';
export 'lume_journey.dart';
export 'lume_overlay.dart';
export 'lume_pressable.dart';
export 'lume_progress.dart';
export 'lume_row.dart';
export 'lume_state.dart';
export 'lume_summary.dart';
export 'lume_surface.dart';
export 'lume_table.dart';
