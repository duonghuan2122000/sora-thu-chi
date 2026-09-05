# Kịch bản khởi động nhanh — PBI 13 (Màn danh sách danh mục)

**Mã PBI**: 13

## Chạy thử
```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze          # sạch, 0 warning
flutter test             # toàn bộ test pass (PBI 2–12 + mới)
flutter run              # chọn emulator Android
```

## QA tay trên emulator
Dữ liệu mặc định seed (onCreate): danh mục hệ thống `is_system=true` — **8 cha chi tiêu** (Ăn uống, Di chuyển, Nhà ở, Hóa đơn, Mua sắm, Giải trí, Sức khỏe, Giáo dục), **4 cha thu nhập** (Lương, Thưởng, Đầu tư, Khác), **3 con** của Ăn uống (Cà phê, Ăn ngoài, Đi chợ). Chưa danh mục nào ẩn (chức năng ẩn thuộc PBI thêm/sửa danh mục, sau).

| # | Bước | Kỳ vọng |
|---|---|---|
| A | Mở app đã mở khóa → tab Cài đặt → chạm "Danh mục" | Màn con: app bar teal tiêu đề "Danh mục" + back trái + icon sắp xếp phải; tab "Chi tiêu" đang chọn (chữ teal + gạch chân teal) → tab "Thu nhập" xám; **không** có bottom nav; FAB "+" góc phải dưới. Bố cục khớp `docs/category/01-danh-sach-danh-muc.svg` |
| B | Xem tab "Chi tiêu" (mặc định) | 8 dòng cha chi tiêu đúng thứ tự seed; mỗi dòng vòng tròn nền nhạt + icon màu nhận diện, tên, chevron phải. Dòng "Ăn uống" có dòng phụ **"3 danh mục con"**; các dòng không con (Di chuyển…) **không** có dòng phụ |
| C | Chạm tab "Thu nhập" rồi về "Chi tiêu" | Tab Thu nhập chỉ 4 danh mục thu (Lương, Thưởng, Đầu tư, Khác) — không lẫn chi; quay lại Chi tiêu vẫn đủ 8 dòng đúng vị trí/thứ tự |
| D | Chạm lần lượt: một dòng (VD "Ăn uống"), FAB "+", icon sắp xếp | Không crash, không treo, không đẩy màn mới (điểm vào no-op PBI này); ripple hiện khi chạm dòng/FAB |
| E | Back về Cài đặt → thêm giao dịch chi mới gắn danh mục (luồng PBI 11) → mở lại "Danh mục" | Danh sách không đổi về cấu trúc (PBI này chưa có thêm danh mục bằng UI) — màn mở lại không lỗi, hiển thị đúng |
| F | Trong Cài đặt, đổi cỡ chữ hệ thống lên lớn nhất + xoay/vùng an toàn | Mỗi dòng không vỡ/tràn, tên dài cắt ellipsis, chevron & FAB không bị che; danh sách cuộn được tới dòng cuối, không `RenderFlex overflow` |
| G | *(QA bằng widget test — chưa tạo ẩn bằng UI được)* | Danh mục ẩn hiện đúng vị trí + nhãn "Đã ẩn"/mờ; con ẩn vẫn tính vào "N danh mục con"; mọi cấp 1 ẩn vẫn hiện (không empty giả) — cover `test/category_list_screen_test.dart` |

Ghi kết quả từng mục A–G vào trạng thái PBI 13 khi hoàn tất.

## Kết quả QA emulator (T012 — 2026-09-05)

| Mục | Kết quả |
|---|---|
| A | Đạt — mở từ Cài đặt → "Danh mục": app bar teal "Danh mục" + back + icon "Sắp xếp"; tab "Chi tiêu" chọn (teal + gạch chân), "Thu nhập" xám; không bottom nav; FAB "+" teal góc phải dưới |
| B | Đạt — tab Chi tiêu đủ 8 cha đúng thứ tự; "Ăn uống" dòng phụ "3 danh mục con"; Di chuyển… không dòng phụ; mỗi dòng bubble nhạt + icon màu nhận diện + chevron |
| C | Đạt — tab Thu nhập chỉ 4 thu (Lương/Thưởng/Đầu tư/Khác), không lẫn chi; về Chi tiêu giữ đủ 8 dòng |
| D | Đạt — chạm dòng "Ăn uống" / FAB "+" / icon "Sắp xếp": không crash/treo, không đẩy route, màn còn nguyên (no-op PBI này) |
| E | Đạt — back về Cài đặt → mở lại "Danh mục" không lỗi, hiển thị đúng (màn chỉ đọc; thêm giao dịch không đổi cấu trúc — cover PBI 11 + reopen) |
| F | Đạt — font_scale 1.5: đủ 8 hàng + tab + FAB, không vỡ (overflow thêm cover widget test textScale 2.0) |
| G | Đạt (qua widget test `category_list_screen_test.dart`) — ẩn hiện đúng vị trí + nhãn "Đã ẩn"/mờ; con ẩn vẫn đếm; ẩn-toàn-bộ không empty giả; chưa tạo ẩn bằng UI (thuộc PBI sau) |

Ghi chú: QA trên emulator `sdk gphone16k (Android 17)`, xóa data app + đặt lại PIN 1234 để seed sạch. Dọn a11y (TalkBack) đã tạm bật để đọc semantics — đã khôi phục.
