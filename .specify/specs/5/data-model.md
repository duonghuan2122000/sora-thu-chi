# Mô hình dữ liệu: Ví (cho màn danh sách ví)

**Mã PBI**: 5

Đợt này chỉ **đọc** — chưa có luồng ghi ví. Model thuần Dart + bộ mẫu hằng; chưa wire drift (xem `research.md` Q1).

## Lưu trữ — ĐỢT NÀY: bộ mẫu trong bộ nhớ (`WalletSource`)

`WalletSource.all()` trả danh sách ví mẫu cố định (5 ví, khớp SC-003) để kiểm chứng hiển thị. Khi PBI tạo/sửa ví (form `wallet-add-edit-form.svg`) đến → thay nguồn bằng đọc drift `wallets` (schema tham chiếu: `docs/wallet/nghiep-vu-vi-tai-khoan.md` §7), giữ nguyên interface trả `List<Wallet>`.

## Thực thể `Wallet` (subset cho màn hình này)

| Thuộc tính | Kiểu | Ghi chú |
|---|---|---|
| `id` | `int` | Định danh; mẫu gán 1..5 |
| `name` | `String` | Tên ví |
| `type` | `WalletType` | `cash / bank / credit / eWallet / savings` |
| `icon` | `String` | Emoji (mockup dùng emoji), hiển thị trong tròn teal nhạt |
| `balance` | `int` | Số dư hiện tại (VND). Ở đời thật là **đại lượng suy ra** từ giao dịch — đợt này cấp thẳng, không sửa tay |
| `isDefault` | `bool` | Cờ "ví mặc định" — tối đa **1** ví |
| `isHidden` | `bool` | Cờ "đã ẩn" (giữ lịch sử, không xóa) |
| `sortOrder` | `int` | Thứ tự hiển thị thủ công |
| `creditLimit` | `int?` | Chỉ thẻ tín dụng |
| `creditUsed` | `int?` | Chỉ thẻ tín dụng — số đã dùng |

**Không đưa vào đợt này** (thuộc luồng tạo ví PBI sau): `initial_balance`, màu, `currency` (đợt này toàn ví chung VND — spec giả định), ngày sao kê/đến hạn (thẻ), kỳ hạn/đáo hạn/lãi suất (sổ tiết kiệm), `created_at/updated_at`.

## Giá trị suy dẫn (hàm thuần, không lưu)

- **Thứ tự hiển thị**: ví không ẩn theo `sortOrder`, rồi ví ẩn xếp cuối (`walletsByDisplayOrder`).
- **Tổng số dư** (card đầu màn): Σ `balance` của ví **đang hoạt động, không ẩn, không phải thẻ tín dụng** (`activeTotal`) — xem `research.md` Q3 (⚠ quyết định mở).
- **Số ví đang hoạt động**: đếm mọi ví `!isHidden` — gồm thẻ tín dụng (`activeCount`).
- **% sử dụng thẻ**: `creditUsed * 100 ~/ creditLimit` (chia nguyên — mockup 6.500.000/20.000.000 → 32%); `creditLimit` ≤ 0 → 0%.
- **Chuỗi thẻ tín dụng**: `"Đã dùng {formatAmount(used)} / {formatAmount(limit)} đ"`, hiển thị coral (FR-007).
- **Tên ví ẩn**: `"{name} (đã ẩn)"` + dòng phụ `"Không tính vào tổng"` (FR-008).
- **Dòng phụ loại**: tên loại tiếng Việt; ví mặc định → nhãn "Mặc định" trước tên loại.

## Luật & ràng buộc (đợt này)

- **Chỉ đọc**: không thao tác nào trên màn làm đổi dữ liệu ví (SC-008). Màn đọc lại nguồn mỗi lần build → phản ánh đúng dữ liệu hiện tại khi nguồn đổi (FR-012).
- **Đúng 1 ví mặc định**: invariant nghiệp vụ (docs §2); bộ mẫu tuân thủ; screen không tự kiểm định (không thể sai ở dữ liệu mẫu).
- **Số âm**: `balance` có thể âm (ví tiền mặt chi quá tay) → định dạng kèm dấu trừ, không coi là dữ liệu lỗi (edge spec).
- **Không rỗng tên hiển thị**: ví luôn có tên; ví ẩn thêm hậu tố "(đã ẩn)".

## Quan hệ (tương lai, không nối đợt này)

- Màn này là **trung tâm điều hướng** module Ví: hàng từng ví / nút "+ Thêm ví mới" là điểm vào của PBI chi tiết ví & form ví (không nối đợt này).
- Số dư ví thật liên hệ `transactions` (PBI giao dịch); transfer sinh 2 bút toán. Tiền tệ mặc định cấp từ DeviceProfile (PBI 4). Tổng đa ví khi có đa tiền tệ/tỷ giá — ngoài đợt này (spec giả định).
