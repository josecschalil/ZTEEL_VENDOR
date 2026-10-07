import Flutter
import UIKit
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationChannel: FlutterMethodChannel?
  private var pendingNotificationPayload: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "zteel/vendor_notifications",
        binaryMessenger: controller.binaryMessenger
      )
      notificationChannel = channel
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "showNewOrder":
          guard let arguments = call.arguments as? [String: Any],
                let identifier = arguments["id"] as? Int else {
            result(FlutterError(code: "missing_id", message: "A notification id is required.", details: nil))
            return
          }
          let content = UNMutableNotificationContent()
          content.title = arguments["title"] as? String ?? "New order"
          content.body = arguments["message"] as? String ?? "A new order is ready to review."
          content.sound = .default
          content.userInfo = ["payload": arguments["payload"] as? String ?? ""]
          let request = UNNotificationRequest(
            identifier: String(identifier), content: content, trigger: nil
          )
          UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
              if let error = error {
                result(FlutterError(code: "notification_failed", message: error.localizedDescription, details: nil))
              } else {
                result(nil)
              }
            }
          }
        case "getLaunchOrder":
          result(self.pendingNotificationPayload)
          self.pendingNotificationPayload = nil
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let payload = response.notification.request.content.userInfo["payload"] as? String {
      pendingNotificationPayload = payload
      notificationChannel?.invokeMethod("openOrder", arguments: payload)
    }
    completionHandler()
  }
}
