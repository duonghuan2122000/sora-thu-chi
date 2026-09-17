import Flutter
import Foundation

/// Kênh native `sora_thu_chi/report_downloads` (bản iOS, PBI 41) — iOS không có
/// khái niệm thư mục Tải xuống công khai giống Android; ghi vào thư mục
/// Documents của app (người dùng mở lại qua app Files/"On My iPhone" nếu bật
/// `UIFileSharingEnabled`) — khớp Giả định #1 trong spec.md PBI 41.
enum ReportDownloadsChannel {
  static let name = "sora_thu_chi/report_downloads"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "saveToDownloads":
        guard
          let args = call.arguments as? [String: Any],
          let fileName = args["name"] as? String,
          let bytes = args["bytes"] as? FlutterStandardTypedData
        else {
          result(FlutterError(code: "invalid_args", message: "Thiếu name hoặc bytes", details: nil))
          return
        }
        do {
          let saved = try save(fileName: fileName, data: bytes.data)
          result(["path": saved.path, "fileName": saved.fileName])
        } catch {
          result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func save(fileName: String, data: Data) throws -> (path: String, fileName: String) {
    let documents = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let finalUrl = uniqueUrl(in: documents, fileName: fileName)
    try data.write(to: finalUrl, options: .atomic)
    return (finalUrl.path, finalUrl.lastPathComponent)
  }

  /// Thêm hậu tố ` (2)`, ` (3)`... nếu tên đã tồn tại — giữ nguyên phần mở rộng (FR-004).
  private static func uniqueUrl(in dir: URL, fileName: String) -> URL {
    var candidate = dir.appendingPathComponent(fileName)
    if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
    let ext = (fileName as NSString).pathExtension
    let base = (fileName as NSString).deletingPathExtension
    var n = 2
    repeat {
      let name = ext.isEmpty ? "\(base) (\(n))" : "\(base) (\(n)).\(ext)"
      candidate = dir.appendingPathComponent(name)
      n += 1
    } while FileManager.default.fileExists(atPath: candidate.path)
    return candidate
  }
}
