# Kịch bản khởi động nhanh: PBI 38 — Cập nhật giao diện màn Thêm giao dịch

Chạy thử tính năng sau khi thi công xong `tasks.md`.

## Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get
flutter run
```

Cần ít nhất 1 ví hoạt động đã tồn tại (nếu máy trống, tạo ví trước ở tab Ví).

## Bước kiểm thử tay

1. Mở tab "Giao dịch" → chạm FAB giữa bottom nav → mở màn "Thêm giao dịch".
2. Chạm ô Số tiền → **kỳ vọng**: bàn phím số của thiết bị (OS) hiện lên, không phải numpad tự vẽ trong app. Gõ `150000` → ô hiển thị `150.000`.
3. Chạm dòng "Tag" → **kỳ vọng**: mở màn chọn tag riêng.
   - Nếu chưa từng có tag nào → gõ tên tag mới (VD "ăn trưa") → tạo → tag xuất hiện trong danh sách đã chọn.
   - Thoát màn, thêm 1 giao dịch nữa gắn cùng tag → mở lại màn chọn tag → **kỳ vọng**: tag "ăn trưa" xuất hiện sẵn trong danh sách gợi ý, chọn lại được không cần gõ lại.
   - Xác nhận → quay về màn Thêm giao dịch, dòng Tag hiển thị tag đã chọn.
4. Chạm dòng "Ảnh hóa đơn" → chọn "Chụp ảnh" (hoặc "Chọn từ thư viện" nếu test trên máy ảo không có camera) → hoàn tất chụp/chọn → **kỳ vọng**: ảnh xem trước (thumbnail) hiện tại dòng đó.
5. Gõ Ghi chú → **kỳ vọng**: ô ghi chú có không gian nhập nhiều dòng hơn trước (do đã bỏ numpad tự vẽ).
6. Chọn Danh mục + Ví + Ngày giờ như luồng cũ → bấm "Lưu giao dịch" → **kỳ vọng**: lưu thành công, không lỗi.
7. Mở màn Chi tiết giao dịch vừa tạo → **kỳ vọng**: tag đã chọn + ảnh hóa đơn hiển thị đúng (màn Chi tiết PBI 10 đã hỗ trợ hiển thị 2 trường này).
8. Lặp lại bước 1–2, lần này **không** nhập Tag/Ảnh hóa đơn, chỉ điền các trường bắt buộc → Lưu → **kỳ vọng**: vẫn lưu thành công (2 trường là tùy chọn).
9. Chạm tab "Chuyển khoản" ở màn Thêm giao dịch → **kỳ vọng**: mở luồng chuyển khoản nội bộ như cũ, không có dòng Tag/Ảnh hóa đơn.
10. Mở màn Thêm giao dịch → chạm dòng Ảnh hóa đơn, chụp ảnh → **không** lưu giao dịch, bấm nút đóng (X) → xác nhận thoát → **kỳ vọng** (kiểm tra bằng file explorer/adb nếu cần): ảnh vừa chụp không còn nằm trong `<appDocuments>/receipts/` (không để rác file).

## Chạy test tự động

```bash
flutter analyze
flutter test
```

Kỳ vọng: `flutter analyze` sạch; toàn bộ test pass (bám baseline hiện có của repo — xem `MEMORY.md`/wiki về số lượng test hiện tại, cộng thêm test mới cho `TagPickerScreen` + phần sửa `AddTransactionScreen`).
