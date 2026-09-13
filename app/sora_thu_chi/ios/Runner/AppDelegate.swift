import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
