import 'utilities.dart';

/// Seam đọc/ghi trạng thái màn Tiện ích & Cá nhân hóa — màn chỉ phụ thuộc
/// interface này để test bơm fake (không cần sqlite native). Impl thật:
/// [DriftUtilitiesStore]. PBI sau (màn khác đọc công tắc Ẩn số dư / Máy tính)
/// đọc cùng store qua GetX singleton như pattern repository hiện có.
abstract class UtilitiesStore {
  /// Đọc trạng thái hiện hành — key vắng trong bảng → mặc định domain
  /// (UtilitiesPrefs.fromSettings).
  Future<UtilitiesPrefs> load();

  /// Ghi write-through trạng thái 2 công tắc (upsert row, không xoá row khác).
  Future<void> save(UtilitiesPrefs prefs);
}
