# Kế hoạch triển khai: Chế độ riêng tư trên Tổng quan (Privacy Mode Dashboard)

**Mã PBI**: 48
**Liên kết spec**: [.specify/specs/48/spec.md](.specify/specs/48/spec.md)
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (đúng stack hiện có của repo) |
| Framework / Thư viện chính | GetX (state management) — thêm `PrivacyController extends GetxController` theo đúng pattern `ThemeController`/`LocaleController` đã có |
| Lưu trữ dữ liệu | `drift` — tái dùng bảng `AppSettings` + key `hideBalance` đã có từ PBI 17 (`UtilitiesStore`/`DriftUtilitiesStore`); **không** đổi schema (giữ v11) |
| Kiểm thử | `flutter_test` — widget test cho `DashboardScreen` (mask/reveal/icon), unit test cho `PrivacyController` và `maskMoney`, bơm fake `UtilitiesStore` qua seam có sẵn (không cần sqlite native) |
| Nền tảng triển khai | Android/iOS (app offline hiện có), không có phần backend/API |
| Ràng buộc hiệu năng | Không có yêu cầu riêng — thao tác chỉ đổi state UI cục bộ, không truy vấn DB thêm ngoài 1 lần `load()` đã có |
| Ràng buộc khác | Không thêm dependency mới; tái dùng tối đa widget/pattern sẵn có (`ScreenHeader.trailing` nhiều icon, `MonthStatRow`/`TxnRowTile` tham số tuỳ chọn, cơ chế reset theo tab của `AppShell._syncReportPresence`) |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md` trong repo — không có nguyên tắc bắt buộc riêng để đối chiếu. Áp dụng quy ước chung ở `CLAUDE.md` (design system, offline-first, GetX, drift) — kế hoạch dưới đây tuân thủ đầy đủ, không có ngoại lệ cần biện minh.

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết [research.md](.specify/specs/48/research.md). Tóm tắt:

- **R1**: Tái dùng key `hideBalance` có sẵn trong `AppSettings` — không thêm schema.
- **R2**: `PrivacyController` (singleton GetX) là nguồn chân lý duy nhất cho cả `hideBalance` lẫn `amountCalculatorEnabled`; `UtilitiesScreen` bỏ state cục bộ, chuyển sang đọc/ghi qua controller này để tránh 2 cache lệch nhau.
- **R3**: Trạng thái "xem tạm thời" (`revealed`) không lưu bền, reset khi rời tab Tổng quan qua `AppShell._onTabSelected` (bám cơ chế `_syncReportPresence` đã có).
- **R4**: Hàm `maskMoney(int value)` mới trong `money_format.dart` — che bằng số dấu chấm xấp xỉ theo số chữ số gốc.
- **R5**: `MonthStatRow`/`TxnRowTile` (dùng chung với màn Giao dịch) nhận thêm tham số tuỳ chọn `masked` mặc định `false` — chỉ Dashboard bật, không ảnh hưởng màn Giao dịch.
- **R6**: Icon con mắt đặt cạnh `_BellButton` trong `Row` truyền vào `ScreenHeader.trailing` (đã hỗ trợ nhiều icon từ PBI 27).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](.specify/specs/48/data-model.md) — không thêm thực thể/schema, chỉ thêm state phiên (`PrivacyController.revealed`).
- **Hợp đồng giao diện**: không áp dụng — app offline, không có API/CLI công khai.
- **Kịch bản khởi động nhanh**: xem [quickstart.md](.specify/specs/48/quickstart.md).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

Không có vi phạm — thiết kế chỉ tái dùng state/pattern/widget sẵn có, không thêm bảng, không thêm dependency, không tạo API mới.

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/lib/
├── core/
│   ├── money_format.dart              # + maskMoney(int)
│   ├── privacy/                       # MỚI
│   │   └── privacy_controller.dart    # PrivacyController (hideBalance/amountCalculatorEnabled/revealed)
│   ├── widgets/
│   │   ├── month_stat_row.dart        # + tham số masked (mặc định false)
│   │   └── txn_row_tile.dart          # + tham số masked (mặc định false)
│   └── app_shell.dart                 # _onTabSelected: reset revealed khi rời tab Tổng quan
├── data/
│   └── privacy_deps.dart              # MỚI — ensurePrivacyController() (singleton GetX)
└── screens/
    ├── dashboard_screen.dart          # icon con mắt (trailing), truyền masked xuống MonthStatRow/TxnRowTile/số dư tổng
    └── utilities_screen.dart          # bỏ state cục bộ _prefs, đọc/ghi qua PrivacyController (Obx)

app/sora_thu_chi/test/
├── core/
│   ├── money_format_test.dart         # + case maskMoney
│   └── privacy/
│       └── privacy_controller_test.dart   # MỚI
└── screens/
    ├── dashboard_screen_test.dart     # + case mask/reveal/icon mắt/reset khi đổi tab
    └── utilities_screen_test.dart     # cập nhật theo seam PrivacyController
```

## Rủi ro & ngoại lệ có lý do

- **Di trú `UtilitiesScreen` sang `PrivacyController`**: đổi nguồn state của 2 công tắc đã có (PBI 17) — cần cập nhật `utilities_screen_test.dart` theo seam mới; không đổi hành vi quan sát được từ người dùng (UI/mockup `01` giữ nguyên).
- **`amountCalculatorEnabled` "đi ké" vào `PrivacyController`**: chọn vậy để tránh 2 nguồn cache của cùng bảng ghi đè nhau (R2); không mở rộng phạm vi nghiệp vụ, cờ này không đổi hành vi ở PBI 48.
- Không có ngoại lệ hiến pháp cần biện minh (không có `constitution.md`).
