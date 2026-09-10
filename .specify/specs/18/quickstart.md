# Kịch bản kiểm thử nhanh — PBI 18 (Giao diện Sáng / Tối / Theo hệ thống)

Ngày: 2026-09-06

## Chạy tự động

Từ `app/sora_thu_chi/`:

```bash
flutter pub get
flutter analyze          # sạch cảnh báo/lỗi
flutter test             # toàn bộ suite (light giữ nguyên kết quả; + test dark mới)
flutter test test/theme_screen_test.dart test/theme_controller_test.dart test/dark_theme_smoke_test.dart
```

Lưu ý: suite cũ **không được vỡ** — bản light token giữ nguyên giá trị; nếu vỡ là refactor đã đổi
màu sáng (sai).

## QA tay emulator (luồng chính + biên)

Mở app ở giao diện **sáng**, vào **Cài đặt → Tiện ích & Cá nhân hóa**:

1. **A — Hàng mở được màn đúng bố cục**: hàng "Giao diện" hiện giá trị "Theo hệ thống" ▸; chạm →
   màn con "Giao diện": app bar teal + nút back + tiêu đề "Giao diện", **không** bottom nav, đủ 3
   lựa chọn Sáng – Tối – Theo hệ thống (icon trong vòng nhạt + tên + dòng phụ + radio), chân màn
   ghi chú "Thay đổi được áp dụng ngay lập tức…".
2. **B — Radio mặc định**: lần đầu (chưa đổi) → radio "Theo hệ thống" chọn sẵn, không có hàng thứ 2
   chọn.
3. **C — Đổi ngay lập tức**: chạm "Tối" → radio Tối chọn (chấm teal), Sáng/System bỏ chọn, **cả app
   nền tối ngay**, màn đang mở lẫn màn sau không cần khởi động lại; kiểm tra vài màn khác (Giao
   dịch, ví, danh mục) không có vùng "chìm" khó đọc, số tiền vẫn `1.234.000 đ`, teal/coral phân
   biệt, ảnh hóa đơn/avatar không đổi màu. Lặp chọn Sáng → app về sáng.
4. **D — Giá trị màn 01 đồng bộ**: chọn "Tối" rồi back → hàng "Giao diện" hiện "Tối"; mở lại màn 02
   thấy radio Tối đang chọn.
5. **E — Nhớ qua restart**: đang "Tối", tắt hẳn app mở lại → app vẫn tối, màn 01 hiện "Tối", màn 02
   radio Tối chọn.
6. **F — Theo hệ thống**: chọn "Theo hệ thống", đổi điện thoại giữa sáng/tối → app tự đổi theo,
   không mở lại màn.
7. **G — Biên/bố cục**: chạm nhanh liên tiếp Sáng/Tối/Theo hệ thống → radio cuối = lần chạm cuối;
   cỡ chữ lớn nhất + màn nhỏ → danh sách cuộn tới hàng cuối, không vỡ/cắt; chọn mới rồi tắt hẳn app
   ngay → mở lại vẫn giữ giao diện vừa chọn.
