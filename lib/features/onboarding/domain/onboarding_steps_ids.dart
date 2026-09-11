/// The nine steps, by the index the prototype's own `data-step` carries.
///
/// In the domain rather than beside the widgets, because the state machine and
/// the persistence rules need them and neither should have to reach into the
/// presentation layer to find out what step four is.
library;

/// The flow, in order.
abstract final class LumeOnboardingStep {
  static const int welcome = 0;
  static const int plan = 1;
  static const int tools = 2;
  static const int country = 3;
  static const int city = 4;
  static const int interests = 5;
  static const int setUp = 6;
  static const int name = 7;
  static const int done = 8;

  /// Nine, which is why the progress bar has nine segments.
  static const int count = 9;

  static const List<int> all = <int>[
    welcome,
    plan,
    tools,
    country,
    city,
    interests,
    setUp,
    name,
    done,
  ];

  /// The last step has nothing to skip past, so its Skip is disabled — and the
  /// first has nothing to go back to.
  static bool canGoBack(int step) => step > welcome;
  static bool canSkip(int step) => step < done;
}
