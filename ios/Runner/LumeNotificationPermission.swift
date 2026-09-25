import Flutter
import UserNotifications

/// Checks and requests the iOS notification permission for Lume's Reminders
/// feature. This only reports the raw system facts; classifying them into a
/// UI-facing state happens in Dart, not here.
enum LumeNotificationPermission {
  static let channel = "lume/notification_permission_ios"

  static func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: channel, binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "check":
          UNUserNotificationCenter.current().getNotificationSettings { settings in
            let facts = factMap(for: settings)
            DispatchQueue.main.async {
              result(facts)
            }
          }
        case "request":
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
              let facts = factMap(for: settings)
              DispatchQueue.main.async {
                result(facts)
              }
            }
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private static func factMap(for settings: UNNotificationSettings) -> [String: Any] {
    return [
      "granted": settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional,
      "denied": settings.authorizationStatus == .denied,
      "notDetermined": settings.authorizationStatus == .notDetermined,
      "authorizationStatus": settings.authorizationStatus.rawValue,
    ]
  }
}
