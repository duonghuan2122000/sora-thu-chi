# Kế hoạch triển khai: Chọn hành động cho bản sao lưu cũ

**Mã PBI**: 43
**Liên kết spec**: .specify/specs/43/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (theo repo hiện có) |
| Framework / Thư viện chính | GetX (`BackupController` đã có), `share_plus` (đã có), `file_picker` (đã có) — **không thêm dependency mới** |
| Lưu trữ dữ liệu | Không thêm bảng/khoá mới; dùng nguyên danh sách `LocalBackupEntry` từ `LocalBackupStore.list()` đã có |
| Kiểm thử | `flutter_test` — mở rộng `test/backup_restore_screen_test.dart`, có thể thêm `test/backup_result_screen_test.dart` nếu tách hàm share dùng chung |
| Nền tảng triển khai | Android/iOS (app hiện có), không đổi cấu hình native |
| Ràng buộc hiệu năng | Không đáng kể — chỉ thêm 1 bottom sheet tĩnh, không truy vấn thêm |
| Ràng buộc khác | Giữ nguyên toàn bộ luật/luồng khôi phục PBI 35 (xác nhận, cảnh báo, checkbox bắt buộc, safety-snapshot, transaction DB); không đổi UI của `RestoreConfirmSheet`/`CreateBackupSheet`/`BackupResultScreen` |

Không có mục `NEEDS CLARIFICATION` — xem `research.md`.

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md` trong repo — bỏ qua bước đối chiếu hiến pháp, áp dụng trực tiếp quy ước đã chốt ở `CLAUDE.md` (thiết kế/luồng nghiệp vụ ở `docs/`, ngôn ngữ tiếng Việt, style code/test theo các PBI backup trước).

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không đổi luật nghiệp vụ đã chốt (khôi phục = Replace-only, xác nhận bắt buộc) | ✅ | Chỉ đổi *lối vào* luồng khôi phục từ danh sách, logic `BackupController.confirmRestore`/`RestoreConfirmSheet` giữ nguyên |
| Design system (bottom sheet, màu teal/coral, bo góc) | ✅ | Tái dùng khuôn sheet đã có trong module backup, không tự chế control mới |
| Không thêm dependency khi thư viện sẵn có đủ dùng | ✅ | `share_plus` đã có; chỉ tái cấu trúc hàm mặc định, không thêm package |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem `research.md`. Tóm tắt các quyết định chính:

- **Quyết định**: Chạm vào 1 hàng trong danh sách mở `showModalBottomSheet` 2 lựa chọn (Chia sẻ file / Khôi phục từ bản này) thay vì khôi phục ngay. **Lý do**: đúng khuôn UI sheet đã dùng khắp module. **Phương án khác**: `showMenu` context-menu, 2 icon riêng cuối hàng — đều lệch khuôn hiện có hoặc tăng rủi ro bấm nhầm.
- **Quyết định**: Gộp hàm mặc định chia sẻ file (`SharePlus.instance.share`) thành 1 hàm dùng chung ở `backup_share.dart`, cả `BackupResultScreen` và `BackupRestoreScreen` cùng dùng. **Lý do**: tránh lặp code, giữ đúng seam test bơm hàm giả. **Phương án khác**: giữ 2 định nghĩa riêng — chấp nhận được nhưng dư thừa.
- **Quyết định**: Lỗi "file không tồn tại" (chia sẻ hoặc khôi phục) tái dùng đúng cơ chế báo lỗi đã có (`_showError`/SnackBar), không thêm state lỗi riêng. **Lý do**: đủ theo FR-006, tránh phình logic.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: không có — tính năng không thêm/đổi entity hay bảng dữ liệu, dùng nguyên `LocalBackupEntry` đã có.
- **Hợp đồng giao diện**: không áp dụng — không có API/CLI công khai, đây là thay đổi UI nội bộ app di động offline.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` (5 nhóm A–E: menu hiện đúng, chia sẻ bản thủ công, chia sẻ bản tự động, khôi phục vẫn đủ bước xác nhận, file bị thiếu).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Giữ nguyên luồng khôi phục đã chốt | ✅ | Thiết kế không đổi `BackupController`/`RestoreConfirmSheet` |
| Không phình phạm vi (chọn nhiều, xoá bản) | ✅ | Đúng "Ngoài phạm vi" trong spec.md |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/lib/
  core/backup/
    backup_share.dart                # thêm hàm dùng chung defaultShareBackupFile(path)
  screens/
    backup_restore_screen.dart       # _BackupList: onTap hàng → mở sheet 2 lựa chọn (mới: _BackupEntryActionSheet/_BackupEntryAction)
                                      #   → chọn "Chia sẻ file" gọi shareFile(path) (bắt lỗi file thiếu)
                                      #   → chọn "Khôi phục từ bản này" gọi đúng _startRestoreFlow(path) hiện có
    backup_result_screen.dart        # dùng lại defaultShareBackupFile thay vì định nghĩa cục bộ
app/sora_thu_chi/test/
  backup_restore_screen_test.dart    # thêm ca: mở sheet, chọn Chia sẻ (gọi đúng path, không đổi dữ liệu),
                                      #   chọn Khôi phục (vẫn ra RestoreConfirmSheet), đóng sheet không chọn gì,
                                      #   lỗi file thiếu ở cả 2 nhánh
  backup_result_screen_test.dart     # cập nhật nếu chữ ký hàm share mặc định đổi vị trí khai báo
```

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: đổi `onTap` của hàng từ "khôi phục ngay" sang "mở menu" là thay đổi hành vi UI — rà lại không có test cũ nào tap trực tiếp vào hàng để kỳ vọng khôi phục ngay lập tức (đã kiểm tra `backup_restore_screen_test.dart`, các test hiện có chỉ `find` để kiểm tra text/key, không `tap` hàng danh sách) ⇒ không phá test cũ.
- **Không có ngoại lệ vi phạm nguyên tắc dự án** — không cần mục "Ngoại lệ có lý do" riêng.
