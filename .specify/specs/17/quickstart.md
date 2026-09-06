# Kịch bản khởi động nhanh — PBI 17

## Test tự động (từ `app/sora_thu_chi/`)

```bash
flutter analyze
flutter test test/utilities_test.dart
flutter test test/utilities_store_drift_test.dart
flutter test test/utilities_screen_test.dart
flutter test test/settings_screen_test.dart
```

## Kiểm thử tay trên emulator

1. Chạy app: `flutter run`. Lần đầu cần thiết lập PIN (mật mã gì cũng được), mở khóa.
2. Vào tab **Cài đặt** → cuộn tới nhóm **KHÁC** → chạm **"Tiện ích & Cá nhân hóa"**
   (ngay dưới hàng "Danh mục").
3. **Đối chiếu màn 01**: app bar teal, nút back, tiêu đề "Tiện ích & Cá nhân hóa",
   không bottom nav. Đủ 3 nhóm — HIỂN THỊ (Giao diện / Ngôn ngữ / Định dạng & Tiền
   tệ), TRẢI NGHIỆM (Widget màn hình chính / Ẩn số dư (Privacy mode) / Máy tính khi
   nhập số tiền), DỮ LIỆU & TÌM KIẾM (Tìm kiếm toàn cục / Quản lý Tag). Mỗi hàng có
   vòng nền nhạt + icon teal, tên, dòng phụ (nếu có) và phần cuối.
4. **Kiểm tra giá trị/trailing mặc định**: Giao diện = "Hệ thống" →, Ngôn ngữ =
   "Tiếng Việt" →; công tắc Ẩn số dư = **tắt**, Máy tính = **bật**; Widget màn hình
   chính hiển thị công tắc **bật**.
5. **Widget màn hình chính**: chạm toàn hàng → dialog hướng dẫn ghim widget theo
   nền tảng hiện ra, công tắc **không** đảo. Đóng dialog.
6. **2 công tắc thật**: bật "Ẩn số dư", tắt "Máy tính khi nhập số tiền" → trạng thái
   đảo ngay. Chạm **back hệ thống** về Cài đặt → mở lại màn → trạng thái giữ nguyên.
   **Tắt hẳn app** (swipe khỏi recent) → mở lại, vào màn → vẫn giữ.
7. **5 hàng điều hướng**: lần lượt chạm Giao diện, Ngôn ngữ, Định dạng & Tiền tệ,
   Tìm kiếm toàn cục, Quản lý Tag → không mở màn mới, app không lỗi. Hàng Quản lý
   Tag **không** hiện số "12 tag" hay tag minh họa.
8. **Regression**: sang Tổng quan / Giao dịch / màn thêm giao dịch → giao diện & hành
   vi không đổi sau khi bật/tắt công tắc.
9. **Cỡ chữ lớn + màn hình nhỏ**: tăng cỡ chữ hệ thống lên tối đa, màn nhỏ → cuộn
   tới hàng cuối, không cắt/tràn tên, dòng phụ, phần cuối.

## Tiêu chí đạt

- Cả 8 acceptance của spec đều pass; trạng thái công tắc giữ 100% giữa các lần mở
  màn và sau khi khởi động lại app.
