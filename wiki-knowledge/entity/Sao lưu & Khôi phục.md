---
title: "Sao lưu & Khôi phục"
date: 2026-09-17
tags: [module, backup, restore, entity]
sources:
  - ../docs/backup/giai-phap-dong-bo-sao-luu-du-lieu.md
  - ../../.specify/specs/43/spec.md
  - ../../.specify/specs/43/plan.md
---

# Sao lưu & Khôi phục

App offline hoàn toàn → "đồng bộ" = đồng bộ thủ công qua file export/import, không cloud/API riêng. Sub-page từ Cài đặt, `SubPageScaffold` app bar teal + back, không bottom nav/FAB. Xem [[Hồ sơ & Bảo mật]] cho các sub-page Cài đặt khác cùng khuôn.

## Đã triển khai — PBI 35 (màn `01` + sheet `02`/`03` + màn `04`)

- **Định dạng file**: `.json` thuần (không ảnh đính kèm) hoặc `.zip` (`data.json` + `/images/`) — tuỳ chiến lược mã hoá/mật khẩu áp dụng cho cả 2. `meta` tách riêng (counts, checksum, schema_version) để đọc nhanh không cần parse toàn `data`.
- **US1 — Sao lưu thủ công**: nút "Tạo bản sao lưu mới" → `CreateBackupSheet` (tóm tắt số liệu, tuỳ chọn mật khẩu) → ghi file → khay chia sẻ hệ thống (`share_plus`) → `BackupResultScreen` (mode `backup`).
- **US2 — Khôi phục**: "Chọn file khôi phục" (file picker) hoặc chạm 1 bản trong danh sách "CÁC BẢN SAO LƯU" → đọc `meta` (`BackupController.inspectBackupFile`) → `RestoreConfirmSheet` (banner cảnh báo coral + checkbox "Tôi hiểu và muốn tiếp tục" bắt buộc) → xác nhận: tạo **safety-snapshot** dữ liệu hiện tại trước, ghi đè trong 1 transaction DB (**Replace-only, không merge**) → `BackupResultScreen` (mode `restore`).
- **US3 — Tự động sao lưu**: công tắc + tần suất Ngày/Tuần/Tháng, lưu vào thư mục nội bộ app (`backups/auto/`), giữ tối đa 5 bản gần nhất (FIFO), **không** tự share ra ngoài.
- Kiến trúc code: `BackupController` (GetX) là **một** state nguồn cho cả màn chính, sheet tạo, sheet khôi phục; `LocalBackupStore` seam (`FileSystemLocalBackupStore` thật / fake test); `BackupCrypto`/`BackupReader`/`BackupWriter` xử lý mã hoá-đọc-ghi.

## PBI 42 — hiển thị đường dẫn file tự động sao lưu

Thẻ "Sao lưu gần nhất" và hàng tương ứng trong danh sách hiện thêm **đường dẫn file** khi bản gần nhất là bản **tự động** (`isAuto == true` và còn khớp `prefs.lastBackupPath` với 1 entry hiện có) — tra cứu chéo, không thêm cờ dữ liệu riêng. Bản thủ công hoặc bản đã bị dọn khỏi danh sách thì không hiện.

## PBI 43 — chọn hành động cho bản sao lưu cũ

> Trước PBI 43: chạm 1 hàng trong "CÁC BẢN SAO LƯU" luôn khôi phục ngay (đi thẳng `_startRestoreFlow`) — không có cách nào chia sẻ lại một bản **cũ** (chỉ chia sẻ được file **vừa tạo** qua nút "Chia sẻ lại file" ở `BackupResultScreen`).

- **Hành vi mới**: chạm 1 hàng bất kỳ (thủ công lẫn tự động) mở **bottom sheet 2 lựa chọn** — "Chia sẻ file" / "Khôi phục từ bản này" — khuôn sheet ngắn đã dùng khắp module (`ListTile`), đóng không chọn gì (tap ra ngoài) thì không có hành động nào chạy.
- **"Chia sẻ file"**: gọi `ShareBackupFile` (khay chia sẻ hệ thống) với đúng path đã chạm — áp dụng cho **cả bản tự động** (khác việc *tự động* share khi backup nền, vẫn cấm; đây là người dùng **chủ động** chọn). Không đổi dữ liệu/danh sách.
- **"Khôi phục từ bản này"**: gọi lại đúng `_startRestoreFlow` cũ — **0 thay đổi** luật/luồng khôi phục PBI 35 (đủ bước: đọc meta, `RestoreConfirmSheet`, cảnh báo, checkbox bắt buộc, safety-snapshot, transaction DB).
- **File đã bị xoá khỏi máy** (ví dụ bản tự động vừa bị dọn FIFO) mà danh sách chưa kịp làm mới: cả 2 nhánh bắt lỗi đọc file, hiện thông báo rõ ràng qua đúng cơ chế lỗi có sẵn (`_restoreError`/SnackBar), không crash — không thêm state lỗi riêng.
- **Refactor đi kèm**: hàm mặc định chia sẻ (`SharePlus.instance.share(...)`) gộp thành `defaultShareBackupFile` dùng chung tại `backup_share.dart`, cả `BackupResultScreen` (PBI 35) và `BackupRestoreScreen` (PBI 43) cùng dùng — tránh lặp code, giữ đúng seam test bơm hàm giả.
- **Ngoài phạm vi đợt này**: chọn nhiều bản để xử lý hàng loạt, xoá bản từ danh sách này, thêm kênh chia sẻ ngoài khay hệ thống.

## Bảo mật file backup (chưa đổi bởi PBI 43)

Mật khẩu bảo vệ file (AES-256-GCM, khoá dẫn xuất PBKDF2) **độc lập** với mã PIN mở khoá app ([[Hồ sơ & Bảo mật]]) — quên PIN không mất khả năng khôi phục và ngược lại. File **không** mật khẩu được xác thực checksum ngay ở bước đọc meta; file có mật khẩu hoãn xác thực tới lúc nhập đúng mật khẩu trong `RestoreConfirmSheet`.
