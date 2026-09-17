# Quickstart kiểm thử: PBI 46 — Chuẩn hoá điều hướng

Đây là thay đổi thuần nội bộ (kiểu generic), không đổi UX — kiểm thử = xác nhận hành vi y hệt trước khi sửa.

## Kiểm tra tự động

```bash
cd app/sora_thu_chi
flutter analyze
flutter test
```

Đạt: `flutter analyze` sạch (0 lỗi/cảnh báo mới liên quan `MaterialPageRoute`), toàn bộ test cũ pass, không giảm số lượng test.

## Kiểm thử tay (đại diện các nhóm điều hướng đã đổi kiểu)

1. **Ngân sách** (`BudgetOverviewScreen`→`BudgetFormScreen`→sửa→lưu): mở Tổng quan ngân sách → Thêm ngân sách → lưu → xác nhận danh sách nạp lại đúng, không crash.
2. **Ví** (`WalletDetailScreen`→`WalletFormScreen`): sửa tên ví → lưu → xác nhận `WalletDetailScreen` cập nhật tên mới ngay (không cần thoát vào lại).
3. **Danh mục** (`AddTransactionScreen`→`CategoryPickerScreen`): thêm giao dịch → chọn danh mục → xác nhận danh mục hiển thị đúng trên form.
4. **Tag** (`AddTransactionScreen`→`TagPickerScreen`): chọn tag → xác nhận danh sách tag hiển thị đúng trên form.
5. **Chuyển khoản** (`TransactionDetailScreen`→`WalletTransferScreen`): sửa 1 giao dịch chuyển khoản → lưu → xác nhận chi tiết giao dịch nạp lại đúng số liệu mới.
6. **Quét hóa đơn** (`scan_flow.dart`, toàn luồng `DeviceCheckScreen`→`ScanCameraScreen`→`ScanProcessingScreen`→`ScanConfirmScreen`→lưu): chạy hết 1 lượt quét hóa đơn → xác nhận giao dịch được tạo đúng.
7. **Tìm kiếm/lọc** (`TransactionScreen`→`SearchFilterScreen`): áp bộ lọc → xác nhận danh sách giao dịch lọc đúng.
8. **Điều hướng liên-tab** (giữ nguyên, chỉ xác nhận không hồi quy): từ Chi tiết ngân sách bấm "Xem tất cả" → xác nhận về đúng tab Giao dịch với bộ lọc đã áp.

Đạt: cả 8 kịch bản hoạt động y hệt trước khi đổi kiểu generic — không màn nào bị treo, không giá trị trả về bị đọc sai kiểu (ví dụ ép `dynamic` thành `bool` sai gây crash).
