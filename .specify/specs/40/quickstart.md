# Kịch bản khởi động nhanh: Nhân bản giao dịch (PBI 40)

Chạy thử tính năng trên emulator/thiết bị sau khi thi công xong.

## Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get
flutter run
```

Đảm bảo đã có ít nhất 1 giao dịch Chi, 1 giao dịch Thu và 1 giao dịch Chuyển khoản trong dữ liệu hiện có (từ seed thủ công hoặc nhập tay).

## Kịch bản A — Nhân bản giao dịch Chi

1. Vào màn Giao dịch → chạm 1 giao dịch Chi bất kỳ (VD "Đổ xăng") → mở màn Chi tiết.
2. Bấm nút "Nhân bản" (nút phụ, viền, cạnh nút "Sửa").
3. **Kỳ vọng**: mở màn "Thêm giao dịch" ở tab Chi, số tiền/ví/danh mục/ghi chú/tag/ảnh hóa đơn (nếu có) đã điền sẵn đúng như giao dịch gốc, ngày giờ = thời điểm hiện tại (không phải ngày giao dịch gốc).
4. Bấm Lưu không sửa gì.
5. **Kỳ vọng**: quay lại, danh sách/chi tiết xuất hiện giao dịch MỚI với dữ liệu vừa lưu; giao dịch gốc vẫn còn nguyên, không đổi ngày/số tiền; số dư ví trừ thêm đúng 1 lần theo giao dịch mới.

## Kịch bản B — Nhân bản rồi sửa trước khi lưu

1. Lặp bước 1-3 ở trên với 1 giao dịch Thu.
2. Sửa số tiền và danh mục trên màn vừa mở.
3. Lưu.
4. **Kỳ vọng**: bản ghi mới lưu đúng giá trị đã sửa, giao dịch gốc không đổi.

## Kịch bản C — Hủy giữa chừng

1. Bấm "Nhân bản" từ 1 giao dịch bất kỳ.
2. Bấm back (không Lưu).
3. **Kỳ vọng**: không có giao dịch mới nào xuất hiện trong danh sách; số dư ví không đổi.

## Kịch bản D — Nhân bản giao dịch Chuyển khoản

1. Mở Chi tiết 1 giao dịch Chuyển khoản (ví A → ví B).
2. Bấm "Nhân bản".
3. **Kỳ vọng**: mở màn "Chuyển tiền", ví nguồn A, ví đích B, số tiền, ghi chú điền sẵn; ngày giờ = hiện tại.
4. Lưu.
5. **Kỳ vọng**: tạo giao dịch chuyển khoản mới độc lập (group id mới), giao dịch gốc không đổi, số dư 2 ví cập nhật đúng theo lần chuyển mới.

## Kiểm thử tự động

```bash
flutter test test/transaction_detail_screen_test.dart
flutter test test/add_transaction_screen_test.dart
flutter test test/wallet_transfer_screen_test.dart
flutter test
```
