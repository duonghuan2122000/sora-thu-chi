# Nghiên cứu kỹ thuật: PBI 43 — Chọn hành động cho bản sao lưu cũ

## Bối cảnh mã nguồn hiện có

- Màn `BackupRestoreScreen` ([backup_restore_screen.dart](../../../app/sora_thu_chi/lib/screens/backup_restore_screen.dart)) render danh sách `_BackupList`, mỗi hàng `InkWell(onTap: () => onTap(entry.path))` gọi thẳng `_startRestoreFlow` (đọc meta → `RestoreConfirmSheet` → khôi phục).
- Chia sẻ file backup đã có sẵn nhưng chỉ ở `BackupResultScreen` ([backup_result_screen.dart](../../../app/sora_thu_chi/lib/screens/backup_result_screen.dart)), nút "Chia sẻ lại file" ngay sau khi vừa tạo backup mới — dùng `ShareBackupFile` typedef ([backup_share.dart](../../../app/sora_thu_chi/lib/core/backup/backup_share.dart)) với implementation mặc định `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`.
- `BackupController.inspectBackupFile`/`confirmRestore` không đổi — luồng khôi phục hiện có (PBI 35) giữ nguyên hoàn toàn.
- Toàn app đã dùng `showModalBottomSheet` cho mọi lựa chọn ngắn (`CreateBackupSheet`, `RestoreConfirmSheet`, sheet lọc báo cáo ở `report_export_screen.dart`) — không có `showMenu`/context menu kiểu popup nào.

## Quyết định

- **Quyết định**: Chạm vào một hàng trong "CÁC BẢN SAO LƯU" mở `showModalBottomSheet` nhỏ gồm 2 `ListTile` ("Chia sẻ file" / "Khôi phục từ bản này"), trả về enum lựa chọn qua `Navigator.pop(context, action)`; đóng không chọn (tap ra ngoài/kéo xuống) trả `null` → không làm gì.
  **Lý do**: Đúng khuôn UI đã dùng khắp module backup và toàn app (không thêm `showMenu`/package mới); tách rõ bước "chọn hành động" khỏi bước "thực hiện", giữ nguyên `_startRestoreFlow` không đổi logic bên trong.
  **Phương án khác đã xem xét**: (a) `showMenu` kiểu context-menu tại vị trí chạm — không khớp pattern hiện có, thêm cách tương tác mới không cần thiết; (b) 2 icon riêng (share/restore) ở cuối mỗi hàng — tăng bề rộng hàng, dễ bấm nhầm trên máy màn hình hẹp, còn bottom sheet đã đủ rõ ràng và nhất quán.

- **Quyết định**: Hàm chia sẻ mặc định (`SharePlus.instance.share(...)`) chuyển thành 1 hàm dùng chung `defaultShareBackupFile` khai báo tại `backup_share.dart`, `BackupResultScreen` và `BackupRestoreScreen` cùng dùng qua tham số `ShareBackupFile shareFile` (mặc định = hàm dùng chung).
  **Lý do**: Tránh lặp lại định nghĩa `_defaultShareBackupFile` ở 2 file (đang chỉ có ở `backup_result_screen.dart`); giữ đúng seam test đã có (bơm hàm giả trong `flutter test`, không đụng share sheet thật).
  **Phương án khác đã xem xét**: giữ nguyên 2 bản định nghĩa riêng — chấp nhận được nhưng trùng lặp không cần thiết khi cùng logic 1 dòng.

- **Quyết định**: Bắt lỗi "file không tồn tại" tại đúng 2 điểm gọi (`shareFile(path)` và `_controller.inspectBackupFile(path)`), bắt `FileSystemException`/lỗi đọc file chung, hiện lại đúng cơ chế báo lỗi đã có (`_showError` + SnackBar) thay vì thêm loại lỗi mới.
  **Lý do**: FR-006 chỉ cần "báo lỗi rõ ràng, không crash" — tái dùng cơ chế lỗi sẵn có (`_restoreError`) là đủ, không cần state lỗi riêng cho nhánh chia sẻ.
  **Phương án khác đã xem xét**: làm mới danh sách (`_controller.load()`) tự động khi phát hiện file thiếu — vượt phạm vi (spec không yêu cầu tự làm mới, "Ngoài phạm vi" đã loại các thao tác hàng loạt/dọn danh sách).

Không còn điểm `NEEDS CLARIFICATION`.
