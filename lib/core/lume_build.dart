/// What build this is.
///
/// Profile's version line and the About route both print it, and both print
/// **this** build's version rather than the prototype's `4.1.0`. A version
/// number is a claim about which code the reader is running; carrying the web
/// prototype's across would be the one kind of statistic §125 forbids — a
/// figure that looks verified and is not. See D40.
///
/// `build_version_test.dart` reads `pubspec.yaml` and fails if this drifts
/// from it, so the constant cannot quietly go stale.
library;

/// The package version, without the build number.
const String kLumeVersion = '0.1.0';
