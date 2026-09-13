import Flutter
import Foundation
import UIKit

/// Kênh native `sora_thu_chi/device_probe` (bản iOS) — chỉ trả dung lượng trống;
/// iOS không có AICore nên `supportsOnDeviceAi`/`supportsGpuDelegate` luôn false
/// ⇒ luôn rơi vào Tier C, luồng quét vẫn chạy đủ (R5/R17).
enum DeviceProbeChannel {
  static let name = "sora_thu_chi/device_probe"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "probe":
        result([
          "freeStorageGb": freeStorageGb(),
          "supportsOnDeviceAi": false,
          "supportsGpuDelegate": false,
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Dung lượng trống của phân vùng dữ liệu, GB (1 GB = 10^9 byte).
  private static func freeStorageGb() -> Double {
    let home = URL(fileURLWithPath: NSHomeDirectory())
    let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    guard let bytes = values?.volumeAvailableCapacityForImportantUsage else { return 0 }
    return Double(bytes) / 1_000_000_000.0
  }
}
