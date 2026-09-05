# Kịch bản khởi động nhanh — PBI 10: Màn hình chi tiết giao dịch

Ngày: 2026-09-05

## Chuẩn bị dữ liệu mẫu

App tự seed lần đầu (onCreate): 5 ví mẫu + 11 giao dịch mẫu (`TransactionSource`). PBI 10 nâng schema lên **v3** và làm giàu **row 1** (chi `85.000` Tiền mặt) bằng tag `#côngty` + vị trí `123 Láng Hạ, Đống Đa, Hà Nội`; `receipt_image` để trống mọi dòng. Ngày các dòng mẫu **tương đối so với giờ chạy** (cách nay 0/1/2/3/5 ngày).

> Nếu bạn đã từng cài bản PBI 8/9 (schema v2) — app tự `onUpgrade` v2→v3 thêm 3 cột, không mất dữ liệu; **không cần cài lại**. Bản mới (fresh) chạy thẳng onCreate v3.

## Cách chạy (bắt buộc regen `.g.dart` trước)

```bash
cd app/sora_thu_chi
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # schema v3 → tái sinh app_database.g.dart
flutter analyze        # phải sạch
flutter test           # toàn bộ (gồm transaction_detail* / transaction_screen / dao)
flutter run            # chọn Android emulator
```

App khởi động → màn khóa PIN (PBI 3): nhập/lập PIN lần đầu rồi vào.

## Bảng dòng mẫu dùng để mở chi tiết

| # | Loại | Danh mục | Ví | Ghi chú | Tiền (danh sách) | Detail kỳ vọng |
|---|---|---|---|---|---|---|
| 1 | Chi | Ăn uống | Tiền mặt | Ăn trưa văn phòng | `−85.000 đ` coral | Summary bubble teal nhạt + glyph, nhãn **"Ăn uống"**, tiền `−85.000 đ` coral; Ví "Tiền mặt"; Ngày giờ; Ghi chú; **Tag `#côngty`**; **Vị trí "123 Láng Hạ…"**; không hàng Ảnh hóa đơn (data trống) |
| 2 | Chi | Di chuyển | Tiền mặt | — | `−120.000 đ` | Chỉ Ví + Ngày giờ; **không** hàng Ghi chú/Tag/Ảnh/Vị trí (ẩn hết) |
| 3 | Thu | Lương | Vietcombank | Lương tháng 8 | `+12.000.000 đ` teal | Summary tiền `+12.000.000 đ` teal |
| 8 | Chuyển khoản | — | Vietcombank → Momo | Chuyển sang Momo | `700.000 đ` trung tính | Summary trung tính "Chuyển khoản" không dấu; **2 hàng** "Ví nguồn: Vietcombank" / "Ví đích: Momo"; Ngày giờ; Ghi chú "Chuyển sang Momo" |

> Lưu ý: danh mục trên emulator hiện là **tên cha** (`'Ăn uống'`). Đường dẫn "cha · con" (VD `'Ăn uống · Ăn ngoài'`) chưa có trong dữ liệu thật (chưa có bảng categories — quyết định mở #1); logic này được phủ bằng widget test với chuỗi ghép (xem phần test).

## Nhóm QA

### A. Luồng chính — chạm dòng mở chi tiết (acceptance 1–2)
1. Tab **Giao dịch** → chạm dòng chi #1 ("Ăn uống – −85.000 đ – Tiền mặt").
2. Màn **Chi tiết giao dịch** mở ra (sub-page): app bar teal tiêu đề "Chi tiết giao dịch", nút back trái, **icon 3 chấm** phải.
3. Khối tóm tắt: bubble tròn nền teal nhạt + glyph, nhãn "Ăn uống", số tiền **lớn `−85.000 đ` coral**.
4. Vùng chi tiết đúng mockup: **Ví "Tiền mặt"**, **Ngày giờ** dạng `dd/MM/yyyy · HH:mm`, **Ghi chú** gói dòng, **Tag** chip `#côngty`, **Vị trí** text; ngăn cách bởi đường kẻ mảnh.
5. Chạm dòng thu #3 → summary `+12.000.000 đ` **teal**, phân biệt rõ với chi coral (SC-003).

### B. Chuyển khoản — 1 màn, 2 ví nguồn/đích (acceptance 3, SC-005)
Chạm dòng "Chuyển khoản" (nhóm 3 ngày trước) → summary trung tính "Chuyển khoản", tiền `700.000 đ` **không dấu**, không teal/coral; vùng chi tiết có **2 hàng riêng** "Ví nguồn: Vietcombank" / "Ví đích: Momo" — đúng chiều chuyển.

### C. Ẩn hàng không dữ liệu (acceptance 4, SC-006, FR-007)
Chạm dòng chi #2 (không ghi chú/tag/ảnh/vị trí) → màn chỉ còn Ví + Ngày giờ (+ tóm tắt); **không** thấy dòng trống hay phân cách thừa.

### D. Điểm vào Sửa/Nhân bản/3 chấm (acceptance 8, FR-012)
Trên màn chi tiết, chạm lần lượt: nút **"Sửa"**, nút **"Nhân bản"** (dưới cùng), icon **3 chấm** (app bar) → **không** lỗi/treo, không đi hướng (màn thao tác là PBI sau). Màn vẫn ở chi tiết.

### E. Quay lại & giữ vị trí (acceptance 7, SC-008)
Cuộn danh sách xuống một nhóm xa → chạm dòng mở detail → **back** (nút hoặc cử chỉ) → trở về **đúng danh sách ở vị trí đã cuộn**. Mở/đóng nhiều lần mượt, không treo.

### F. Biên & độ bền hiển thị (acceptance 9 + edge)
- **Cỡ chữ lớn nhất / safe area** (bật Cài đặt hệ thống): khối tóm tắt + mọi hàng (kể cả ghi chú dài, vị trí dài) hiển thị đủ, cuộn được, **không vỡ/tràn**, nút dưới cùng không bị cắt.
- **Danh mục/ví ẩn**: giao dịch cũ vẫn hiện đúng tên/màu trên chi tiết (lịch sử giữ nguyên — FR-011).
- **Ngày tương lai**: (nếu có dòng đặt lịch trong seed/test) hiển thị đúng ngày giờ ghi nhận.
- **Khóa app**: chi tiết chỉ thấy sau mở khóa, không lộ số tiền qua màn hình khóa (FR-015).
- **Số tiền lớn**: mở chi tiết khoản lớn → phân tách nghìn chuẩn, không tràn vùng.

### G. Không hồi quy
- Tab Tổng quan / Giao dịch (danh sách vẫn nhóm/đếm như PBI 9) / Báo cáo / Cài đặt, FAB, luồng ví & chuyển tiền, khóa PIN — bình thường.
- `flutter test` xanh toàn bộ (gồm test PBI 6/7/8/9 chạy lại).

## Lưu ý xác minh qua test
Mọi kịch bản trên được phủ tự động:
- **Unit thuần** `transaction_detail_test.dart`: dựng view theo ref (id / transfer group), transfer 2 ví trung tính, adjustment trung tính, nhãn cha·con từ chuỗi ghép `' · '`, parseTags, ẩn hàng khi field rỗng, không tìm thấy → null.
- **Widget** `transaction_detail_screen_test.dart`: seam bơm view — summary màu/dấu theo loại, hàng Ví/Ngày giờ `·`, tag chip `#`, ảnh thumbnail (path giả, `Image.file` + `errorBuilder` placeholder — không crash), vị trí, ẩn hàng rỗng, 3 chấm + 2 nút chạm không crash, cỡ chữ lớn + safe area, số tiền lớn không tràn.
- **Danh sách** `transaction_screen_test.dart`: chạm dòng → mở detail (thay vì no-op PBI 9).
- **DAO** `transactions_dao_test.dart`: `NativeDatabase.memory()` map 3 cột mới (row 1 mang tags/location); skip-guard nếu host thiếu sqlite.

QA emulator chỉ để xác minh trực quan & thao tác thật.
