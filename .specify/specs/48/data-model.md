# Mô hình dữ liệu: PBI 48 — Privacy Mode Dashboard

Không thêm bảng, không thêm cột, không đổi schema drift (giữ nguyên **v11**). Tái dùng nguyên trạng dữ liệu đã có từ PBI 17.

## Dữ liệu bền vững (đã có, không đổi)

Bảng `AppSettings`, row key `hideBalance` (`'true'`/`'false'`, mặc định `false`) — đọc/ghi qua `UtilitiesStore.load()`/`save()` (impl `DriftUtilitiesStore`), gói trong `UtilitiesPrefs.hideBalance`.

## Trạng thái trong phiên (mới, không lưu bền)

`PrivacyController` (GetxController, singleton qua `ensurePrivacyController()`):

| Trường | Kiểu | Ý nghĩa | Lưu bền? |
|---|---|---|---|
| `hideBalance` | `Rx<bool>` | Cache phản chiếu `UtilitiesPrefs.hideBalance`; đổi qua `setHideBalance(bool)` → ghi `UtilitiesStore` (giữ nguyên `amountCalculatorEnabled` hiện có). | Có (qua `UtilitiesStore`) |
| `amountCalculatorEnabled` | `Rx<bool>` | Cache phản chiếu `UtilitiesPrefs.amountCalculatorEnabled` — chuyển từ state cục bộ của `UtilitiesScreen` sang đây để tránh 2 nguồn cache (R2). | Có (qua `UtilitiesStore`) |
| `revealed` | `Rx<bool>` | "Đang xem tạm thời" trên Tổng quan — chỉ có ý nghĩa khi `hideBalance == true`. Reset về `false` khi rời tab Tổng quan hoặc app khởi động lại. | Không |

## Không có thực thể nghiệp vụ mới

Tính năng không tạo/sửa/xoá thực thể domain (Ví, Giao dịch, Danh mục...) — chỉ thay đổi cách **hiển thị** số tiền đã có trên Tổng quan.
