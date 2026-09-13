# Khởi động nhanh & kiểm thử — PBI 25

**Mã PBI**: 25
**Liên kết**: `.specify/specs/25/spec.md`, `.specify/specs/25/plan.md`, `.specify/specs/25/contracts/brand-assets.md`

## 1. Sinh lại asset nhận diện

```bash
cd app/sora_thu_chi
dart run tool/gen_brand_assets.dart      # sinh icon/splash cho Android + iOS + asset Flutter
git status --short                        # xem danh sách file asset đã đổi
```

Kiểm tra nhanh phần Android đã sạch icon mặc định:

```bash
ls android/app/src/main/res/mipmap-*      # KHÔNG còn ic_launcher.png; chỉ còn mipmap-anydpi-v26/ic_launcher.xml
```

## 2. Kiểm thử tự động (không cần thiết bị)

```bash
cd app/sora_thu_chi
flutter analyze
flutter test test/splash_screen_test.dart test/brand_assets_test.dart
flutter test                             # toàn bộ (không được đỏ thêm test nào)
```

## 3. Chạy app xem bằng mắt

```bash
cd app/sora_thu_chi
flutter run                              # chọn emulator/thiết bị Android
```

Vòng kiểm **cold start** (đóng hẳn app rồi mở lại — không phải resume):

| # | Thao tác | Kỳ vọng | Truy vết |
|---|---|---|---|
| A | Nhìn màn hình chính của máy | icon = đồng xu hai nửa màu + 2 mũi tên trắng, tên "Sora Thu Chi" | FR-001/003, SC-001 |
| B | Đổi kiểu icon của launcher (tròn / vuông bo góc / mềm) | hình coin + 2 mũi tên vẫn rõ, không bị cắt chi tiết chính, không lộ nền lạ | FR-002, SC-004 |
| C | Chạm icon | logo hiện **gần như tức thì**, **không** có khung trắng/đen kéo dài, **không** nhảy hình giữa tầng hệ thống và tầng app | FR-010, FR-015, SC-002 |
| D | Nhìn splash | chỉ có logo + "Sora Thu Chi" trắng trên nền teal đặc; **không** app bar, **không** bottom nav, **không** nút, **không** chữ chú thích concept | FR-004/007, SC-007 |
| E | Nhìn kỹ logo trên splash | thấy **đủ hai nửa** đồng xu (nửa teal không chìm vào nền) | FR-016, SC-008 |
| F | Chờ app nạp | splash **tự** biến mất (không chạm), tối đa 5 giây | FR-006, SC-003 |
| G | Sau splash | có PIN → màn khóa; không PIN → Tổng quan | FR-012 |
| H | Đổi Cài đặt → giao diện **Tối**, rồi cold start lại | splash **giống hệt** lúc Sáng (nền teal, chữ trắng); màn kế tiếp đã đúng Tối, không nháy đổi | FR-008/013, SC-006 |
| I | Đổi ngôn ngữ sang English, rồi cold start lại | màn kế tiếp đã đúng ngôn ngữ, không nháy đổi | FR-013 |
| J | Bật/Bật lại chế độ máy bay rồi cold start | splash + icon y hệt (không phụ thuộc mạng) | FR-014 |
| K | Xoay ngang, và thử trên màn nhỏ/màn dài/tablet | logo căn giữa, đúng tỉ lệ, không méo, không tràn | — (SC-004) |
| L | Đặt cỡ chữ hệ thống lớn nhất rồi cold start | tên app trên splash không tràn ra mép màn hình | spec §Trường hợp biên |
| M | Đưa app về nền rồi mở lại (không bị OS kill) | **không** thấy splash; về đúng màn đang dùng (hoặc màn khóa nếu đã tự khóa) | FR-005, SC-005 |
| N | Vào Tổng quan / Giao dịch / Báo cáo / Cài đặt | **không** có logo nào trong nội dung app | FR-010 (phạm vi), spec §Ngoài phạm vi |
| O | Cài đè bản cũ (bản có icon mặc định) | icon trên màn hình chính đổi thành logo mới, không giữ icon cũ | spec §Luồng phụ |

**iOS** (nếu có máy/Mac): lặp lại A–G; riêng bước **C** phải xem thêm khung `LaunchScreen.storyboard` — nền teal, coin + "Sora Thu Chi" trắng, không còn nền trắng.

## 4. Nghiệm thu số liệu

- `flutter test`: số test tăng so với mốc **809** ở PBI 24, **không** test cũ nào đỏ thêm (riêng `transactions_dao_test` đã đỏ sẵn từ trước — không tính).
- `flutter analyze`: không cảnh báo mới.
- `flutter build apk --release`: build xanh (đây là bước xác nhận R1 — không vướng cảnh báo `aapt2` vì thiếu mipmap mặc định).
