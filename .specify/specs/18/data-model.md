# Mô hình dữ liệu — PBI 18 (Giao diện Sáng / Tối / Theo hệ thống)

Ngày: 2026-09-06

## Không có bảng mới, không migration

Bảng key-value `AppSettings` (schema **v5**, PBI 17) đã sẵn. PBI này chỉ **thêm 1 row** khi người
dùng chọn giao diện — đúng mục tiêu thiết kế "thêm cài đặt = thêm row, không thêm migration".

## Row mới trong `AppSettings`

| `key` | `value` | Ghi chú |
|---|---|---|
| `'themeMode'` | `'light'` \| `'dark'` \| `'system'` | Chuỗi khớp tên enum Flutter `ThemeMode`; viết thường |

- Key **vắng mặt** = chưa từng đổi giao diện → mặc định **`system`** (FR-004/SC-003).
- Row **không seed** lúc tạo DB; chỉ ghi **write-through** khi người dùng chạm chọn (giống pattern
  2 công tắc PBI 17).
- Giá trị ngoài 3 chuỗi hợp lệ, hoặc thiếu → **mặc định `system`** (parse an toàn, không ném — bám
  `UtilitiesPrefs.fromSettings`).
- Hằng khóa đặt theo convention PBI 17: `const kKeyThemeMode = 'themeMode'`.

## Thực thể domain

Không tạo enum riêng — tái dùng **`ThemeMode` của Flutter** (`ThemeMode.light/dark/system`) làm giá
trị nguồn duy nhất xuyên suốt (màn 01 hiển thị, radio màn 02, `MaterialApp.themeMode`).

| Đối tượng | Mô tả |
|---|---|
| `ThemeMode` (Flutter) | 1 trong 3: `light` / `dark` / `system`; mặc định `system` |
| `ThemeMode → chuỗi lưu` | `light`→`'light'`, `dark`→`'dark'`, `system`→`'system'` |
| `Chuỗi đọc → ThemeMode` | khớp tên enum; ngoài 3 chuỗi / thiếu → `system` |
| `ThemeMode → nhãn UI` | `light`→"Sáng", `dark`→"Tối", `system`→"Theo hệ thống" |

Các hàm parse/label **thuần** (không I/O), test trực tiếp.

## Trạng thái runtime (không lưu thêm)

`ThemeController` (GetxController) giữ `Rx<ThemeMode>`:

- Là **nguồn chân lý trong phiên** cho: `MaterialApp.themeMode`, radio màn 02, giá trị hàng
  "Giao diện" màn 01.
- `load()` (đọc store) được gọi ở `initState` `SoraApp`; trước khi load xong → `system`.
- `setMode(mode)` → đổi Rx (toàn app đổi ngay) + ghi row qua store (nối đuôi các lần ghi — chọn
  nhanh liên tiếp không để lần ghi cũ đè lần mới; trạng thái cuối = lần chạm cuối).

## Không nằm trong mô hình

- Nội dung người dùng nhập, ảnh hóa đơn/avatar — **không** đổi theo theme (FR-009).
- Bảng màu danh mục/ví (màu nhận diện người dùng chọn) — không đổi theo theme.
- Giá trị màn 01 các hàng no-op khác (Ngôn ngữ = "Tiếng Việt"…) — vẫn hằng UI tĩnh (PBI sau).
