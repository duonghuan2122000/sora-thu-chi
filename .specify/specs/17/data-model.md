# Mô hình dữ liệu — PBI 17 (Tiện ích & Cá nhân hóa)

Ngày: 2026-09-06

Đợt này chỉ có **1 thực thể lưu trữ** (2 lựa chọn công tắc). Các hàng còn lại của màn
01 là UI tĩnh / điểm vào no-op → không phát sinh dữ liệu (xem research R2–R4).

## Bảng drift mới: `AppSettings` (schema v5)

Bảng key-value dùng chung cho mọi cài đặt tiện ích về sau (thêm row, không thêm
migration).

| Cột | Kiểu | Ràng buộc | Ghi chú |
|---|---|---|---|
| `key` | TEXT | PK | Tên khóa cài đặt |
| `value` | TEXT | — | Giá trị dạng chuỗi (bool lưu `'true'`/`'false'`) |

- Khóa trong module này:
  - `'hideBalance'` — "Ẩn số dư (Privacy mode)".
  - `'amountCalculatorEnabled'` — "Máy tính khi nhập số tiền".
- Key **vắng mặt** = chưa từng đổi → lấy mặc định từ domain (không seed row lúc tạo
  DB). Row được ghi **khi người dùng bật/tắt** (write-through).

## Domain: `UtilitiesPrefs`

Giá trị bất biến nạp từ store, đại diện trạng thái hiện hành của 2 công tắc.

| Trường | Mặc định | Ghi chú |
|---|---|---|
| `hideBalance` (bool) | `false` | Ẩn số dư — mockup mặc định TẮT |
| `amountCalculatorEnabled` (bool) | `true` | Máy tính nhập tiền — mockup mặc định BẬT |

Luật chuyển đổi `UtilitiesPrefs ↔ AppSettings`:
- `toSettings()` → 2 row `('hideBalance', …)`, `('amountCalculatorEnabled', …)`.
- `fromSettings(rows)` → key vắng mặt giữ mặc định; chuỗi không parse được → mặc định
  (an toàn, không ném).

## Không nằm trong mô hình (đợt này)

- Giá trị "Hệ thống" / "Tiếng Việt" (hàng Giao diện/Ngôn ngữ) — hằng UI tĩnh (R2).
- Trạng thái hiển thị "bật" của hàng Widget màn hình chính — không lưu (R5).
- Số lượng tag, tag thật — module tag chưa tồn tại (PBI sau).
