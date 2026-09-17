# Kịch bản khởi động nhanh: Dọn màn Tiện ích & Cá nhân hóa (PBI 45)

## Chạy test

```bash
cd app/sora_thu_chi
flutter test test/screens/utilities_screen_test.dart
flutter analyze
```

## QA tay trên emulator

1. Mở app → Cài đặt → "Tiện ích & Cá nhân hóa".
2. **Kỳ vọng**: nhóm HIỂN THỊ chỉ còn 2 hàng (Giao diện, Ngôn ngữ) — không còn "Định dạng & Tiền tệ".
3. **Kỳ vọng**: nhóm TRẢI NGHIỆM còn nguyên 3 hàng (Widget màn hình chính, Ẩn số dư, Máy tính khi nhập số tiền).
4. **Kỳ vọng**: không còn nhóm/nhãn "DỮ LIỆU & TÌM KIẾM" trên màn — cuộn hết màn để chắc chắn không có khoảng trống hoặc divider mồ côi ở cuối.
5. Chạm "Giao diện" → mở đúng `ThemeScreen`; back về đúng màn Tiện ích.
6. Chạm "Ngôn ngữ" → mở đúng `LanguageScreen`; back về đúng màn Tiện ích.
7. Chạm "Widget màn hình chính" → dialog hướng dẫn ghim widget vẫn mở như cũ.
8. Bật/tắt "Ẩn số dư" và "Máy tính khi nhập số tiền" → trạng thái đổi ngay, thoát vào lại màn vẫn giữ đúng trạng thái đã chọn (ghi-through store không đổi).
9. Kiểm tra giao diện tối (dark mode) — màn không có khoảng trắng/divider lệch màu ở vị trí nhóm đã xoá.
