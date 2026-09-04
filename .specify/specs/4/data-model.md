# Mô hình dữ liệu: Hồ sơ thiết bị (Device Profile)

**Mã PBI**: 4

Thực thể duy nhất từ spec: **Hồ sơ thiết bị** — 1 hồ sơ cho 1 bản cài đặt app trên 1 thiết bị, tạo với giá trị mặc định khi người dùng lần đầu vào nội dung app. Độc lập dữ liệu ví/giao dịch/danh mục/ngân sách; về sau mở rộng trường & luồng sửa (spec §Thực thể chính).

## Lưu trữ — ĐỢT NÀY: không bền hoá (model hằng)

Màn Cài đặt hiển thị từ model `DeviceProfile.initial` (toàn bộ giá trị là default). **Chưa đọc/ghi storage nào.** Lý do & điểm bám khi có luồng ghi: xem `research.md` Quyết định 1. Khi PBI sửa hồ sơ/đổi tiền tệ đến, quyết định backend (drift singleton / shared_preferences / secure storage) tại PBI đó.

## Cấu trúc model (không tồn tại độc lập ngoài app)

| Thuộc tính | Kiểu | Mặc định | Ghi chú |
|---|---|---|---|
| `displayName` | `String?` | `null` | `null` = **chưa đặt tên** → hiển thị tên mặc định `'Người dùng'` (`resolvedDisplayName`). Người dùng chưa đặt tên trong đợt này nên luôn hiển thị default (SC-001). |
| `currencyCode` | `String` | `'VND'` | Tiền tệ mặc định (FR-004); hiển thị dạng **mã**, ví dụ "VND". Đổi tiền tệ ngoài phạm vi (không hồi tố — chỉ áp dụng khi có luồng đổi). |

**Giá trị suy dẫn (không lưu):**
- **Avatar / chữ viết tắt**: `initialsOf(resolvedDisplayName)` — chữ cái đầu của tối đa 2 từ, in hoa. Tên default "Người dùng" → "ND". Ảnh thật chưa hỗ trợ (giả định spec).
- **Tên đang hiển thị**: `displayName ?? DeviceProfile.defaultDisplayName` (không bao giờ rỗng — FR-002).

**Hằng mặc định:** `defaultDisplayName = 'Người dùng'`, `defaultCurrencyCode = 'VND'`.

## Luật & ràng buộc

- **Duy nhất**: 1 hồ sơ / bản cài đặt / thiết bị — không có khái niệm nhiều hồ sơ, không ID (docs auth §1: device profile, không phải tài khoản server).
- **Khởi tạo**: giá trị mặc định áp dụng từ lần đầu vào nội dung app. Đợt này không có luồng tạo/tách biệt — model hằng đã mang sẵn default.
- **Chỉ đọc**: không có thao tác nào trong đợt này làm thay đổi hồ sơ (FR-010/SC-006). Các hàng/hồ sơ khi chạm không ghi gì.
- **Không để trống vùng hiển thị**: khi chưa đặt tên → tên mặc định; khi chưa đổi tiền tệ → "VND".
- **Không nằm trong phạm vi đợt này**: múi giờ (chưa có consumer), ảnh thật, tên do người dùng đặt.

## Quan hệ (tương lai, không nối đợt này)

- Cung cấp **tiền tệ mặc định** khi tạo ví mới & hiển thị báo cáo đa ví (module Ví — wiki [[Ví & Tài khoản]]).
- Đổi tiền tệ mặc định **không hồi tố** tiền tệ ví đã tạo (docs auth §3).
- Độc lập hoàn toàn với thực thể tài chính; không phụ thuộc luồng khóa PIN (PBI 3).
