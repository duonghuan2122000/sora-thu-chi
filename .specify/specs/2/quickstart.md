# Quickstart — PBI 2: Khung điều hướng ứng dụng

Kịch bản kiểm thử nhanh để người khác chạy thử + đối chiếu tiêu chí thành công (SC). Phần tự động chạy host; phần thủ công chạy trên Android emulator/thiết bị.

## Điều kiện tiên quyết

- Flutter 3.44.x / Dart 3.12.x trên máy (theo PBI 1).
- Android emulator (khuyến nghị API 37 như PBI 1) hoặc thiết bị Android đang mở.

## Bước 1 — Chạy test tự động (host)

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze        # kỳ vọng: No issues found
flutter test           # kỳ vọng: shell smoke test pass
```

Test bao phủ: boot vào Tổng quan; đủ 4 tab + FAB; đổi tab đổi màn; FAB mở màn phụ "Thêm giao dịch" (không còn bottom nav); quay lại đúng tab cũ.

## Bước 2 — Chạy app trên thiết bị

```bash
flutter run -d <device-id>
```

## Bước 3 — Đối chiếu thủ công

| # | Thao tác | Kỳ vọng | SC |
|---|---|---|---|
| 1 | Mở app | Vào thẳng màn Tổng quan; thanh đáy đủ 5 vị trí, "Tổng quan" teal đậm = đang chọn | SC-001 |
| 2 | Lần lượt chạm Giao dịch / Báo cáo / Cài đặt rồi quay lại từng màn | Vùng chính đổi đúng; màn được chọn tô teal; các màn khác xám | SC-001, FR-003 |
| 3 | Từ Giao dịch chạm Báo cáo rồi quay lại Giao dịch | Màn Giao dịch không bị đặt lại (khung trống, không nhấp nháy về đầu) | FR-004 |
| 4 | Ở cả 4 màn chính, chạm FAB "Thêm giao dịch" (4/4 lần) | Mở màn phụ khung trống có tiêu đề "Thêm giao dịch" + nút back; **không** thấy thanh đáy | SC-002, FR-005/6 |
| 5 | Ở màn phụ chạm back (app bar + phím hệ thống) | Về đúng màn chính lúc rời đi, đúng vị trí đang chọn | FR-006/8, SC-006 |
| 6 | Chuyển tab liên tục ≥5 lần | Không treo, màn cuối đúng vị trí chọn | SC-003 |
| 7 | Trên thiết bị có tai thỏ/phím hệ thống | Thanh đáy và FAB không bị che khuất, đủ vùng chạm | SC-004, FR-009 |
| 8 | Bật cỡ chữ lớn nhất (Cài đặt hệ thống → cỡ chữ, hoặc font scale emulator) | Nhãn tab và FAB không vỡ, không tràn màn | SC-005 |

Kết quả mong đợi: 8/8 đạt. Ghi nhận bất thường (màn hình/thiết bị) vào plan.md trạng thái sau thi công.

## Ghi chú

- App **offline**, không cần server/đăng nhập để chạy thử.
- Màn chính đợt này là khung trống (đúng spec — chưa gắn số liệu).
- Chưa verify iOS (máy Windows); code thuần widget, rủi ro nền tảng thấp — verify khi có máy macOS.
