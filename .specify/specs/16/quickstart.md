# Kịch bản kiểm thử tích hợp — PBI 16 (Sắp xếp danh mục)

**Môi trường**: chạy từ `app/sora_thu_chi/`.
```bash
flutter pub get
flutter analyze
flutter test                       # toàn bộ (không hồi quy 1–15)
flutter test test/category_sort_test.dart
flutter test test/category_sort_screen_test.dart
flutter run                        # QA tay emulator (Android)
```

Dữ liệu mặc định khi cài mới (seed `CategorySource`) gồm cha chi tiêu "Ăn uống" (có con)
và các cha khác → đủ bối cảnh QA mà không cần tạo thêm. Muốn thêm cha/nhóm cho QA tạo bằng
luồng thêm/sửa danh mục (PBI 14) hiện có.

## QA tay — nhóm A–H (đối chiếu acceptance/FR/SC)

### A. Mở màn từ icon "Sắp xếp" (acceptance 1, FR-001/002)
1. Cài đặt → "Danh mục" → tab **Chi tiêu** đang mở → chạm icon ⣿ (Sắp xếp) góc phải app bar.
2. **Kỳ vọng**: mở màn "Sắp xếp danh mục": app bar teal, back (trái), tiêu đề "Sắp xếp danh
   mục", nút **"Xong"** (phải); danh sách là **cha chi tiêu** đúng thứ tự hiện tại; mỗi dòng
   có tay cầm ba gạch (trái) + icon tròn màu + tên; **không** tab, **không** bottom nav,
   **không** số tiền.
3. Đối chiếu trực quan `docs/category/04-sap-xep-danh-muc.svg` (SC-002).

### B. Chỉ đúng loại, chỉ cha cấp 1 (acceptance 3/5, FR-003/004, SC-004)
1. Từ tab **Thu nhập** mở sắp xếp → chỉ thấy cha thu nhập, không lẫn cha chi tiêu.
2. Mở lại từ tab Chi tiêu → chỉ cha chi tiêu; danh mục con (VD con của "Ăn uống") **không**
   xuất hiện dưới cha của chúng trong màn này.

### C. Kéo–thả đổi vị trí + ghi ngay (acceptance 2/6, FR-005/006, SC-003)
1. Ở màn sắp xếp chi tiêu, kéo tay cầm "Di chuyển" lên đầu rồi thả → dòng dạt ra, dòng kéo
   đứng yên vị trí mới, danh sách thành [Di chuyển, Ăn uống, …].
2. Chạm "Xong" → về màn danh sách (đúng tab Chi tiêu) → cha hiển thị thứ tự mới **ngay**,
   không làm mới tay (FR-008/acceptance 7).
3. Vào lại màn sắp xếp → thứ tự giữ nguyên (acceptance 8/SC-003).
4. Kéo một dòng xuống **vượt màn hình** gần mép → danh sách tự cuộn, thả đúng vị trí, không
   bật ngược (acceptance 6/SC-007).
5. Kéo nhanh nhiều dòng liên tục → mỗi lần thả một kết quả nhất quán, không lệch/trùng thứ
   tự (edge list).
6. Chỉ còn 1 cha (tự tạo loại chỉ có 1 cha) → màn mở bình thường, kéo không lỗi (edge).

### D. Danh mục ẩn vẫn hiện & kéo được (acceptance 4, FR-004, SC-005)
1. Ẩn một danh mục cha qua form Sửa (PBI 14) → mở màn sắp xếp → cha đó vẫn ở đúng vị trí,
   nhãn "Đã ẩn"/mờ phân biệt; kéo–thả bình thường như dòng khác.
2. Thao tác kéo chỉ hoán vị **trong danh sách cha**, không làm ẩn/hiện hay đổi cha (FR-005).

### E. Không phá cấu trúc con & nơi khác (acceptance 5, FR-007, SC-004/008)
1. Cha có con (VD "Ăn uống" — Cà phê, Ăn ngoài, Đi chợ): kéo cha đó lên/xuống → con không
   xuất hiện trong màn, thứ tự/liên kết con bên trong không đổi (sang màn danh mục con `03`
   kiểm tra thứ tự con giữ nguyên).
2. Thêm một giao dịch → picker chọn nhanh liệt kê cha theo thứ tự mới; chọn con không đổi.
3. Quay lại màn sắp xếp sắp cha loại kia → không ảnh hưởng thứ tự cha loại này.

### F. Không yêu cầu xác nhận khi rời (FR-006/008, acceptance edge)
1. Mở màn sắp xếp, chưa kéo gì → chạm "Xong" / back hệ thống → về màn danh sách, thứ tự
   không đổi, không cảnh báo.
2. Kéo một dòng thả về đúng vị trí cũ → không ghi đổi thừa, không nhảy.

### G. Bố cục & khả năng tiếp cận (FR-009, SC-007)
1. Bật cỡ chữ lớn nhất + màn hình nhỏ → danh sách cuộn tới dòng cuối, không tràn/cắt tay
   cầm/icon/tên; tên dài hiển thị đủ (ellipsis), kéo–thả không vỡ bố cục.

### H. Khóa app (edge)
1. Màn đang trong shell sau mở khóa (PBI 3), không số tiền → không phát sinh lộ thêm khi
   khóa có hiệu lực (chỉ xác nhận luồng chung).

## Kiểm tra tự động (đã phủ ở test)

- **Unit** `category_sort_test.dart`: `moveCategoryAt` — kéo lên/xuống, qua ranh giới, thả
  cuối danh sách, không đổi khi `oldIndex == newIndex`.
- **Widget** `category_sort_screen_test.dart` (fake repo, seed tùy chọn): bố cục mockup `04`
  (app bar/tiêu đề/"Xong", không tab/bottom nav); chỉ cha đúng loại theo thứ tự seed; dòng
  ẩn hiện + "Đã ẩn"; kéo tay cầm → ghi qua fake (`reorderCategories`) + thứ tự UI đổi; về
  màn danh sách `01` đúng tab + thứ tự mới.
- **Hồi quy**: `category_list_screen_test` (icon sắp xếp no-op → mở màn sắp xếp), toàn bộ
  test cũ chạy lại.
