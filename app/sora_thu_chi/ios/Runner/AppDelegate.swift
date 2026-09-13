import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Thông báo đẩy (PBI 31): thiếu delegate này thì thông báo KHÔNG hiện khi app
    // đang mở (foreground) — R14.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Kênh đo cấu hình máy — thiếu đăng ký thì màn `scan-10` treo ở "Đang kiểm tra…" (R17).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceProbeChannel") {
      DeviceProbeChannel.register(messenger: registrar.messenger())
    }
  }
}
