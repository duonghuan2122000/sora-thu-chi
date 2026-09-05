# Kịch bản khởi động nhanh — PBI 9: Màn hình danh sách giao dịch

Ngày: 2026-09-05

## Chuẩn bị dữ liệu mẫu

App tự seed lần đầu (onCreate): 5 ví mẫu + 11 giao dịch mẫu (`TransactionSource`). Ngày các dòng mẫu **tương đối so với giờ chạy** (cách nay 0/1/2/3/5 ngày).

> Mẹo QA: chạy vào **ngày ≥ 6 của tháng** để 5 dòng cũ nhất (cách nay 5 ngày) vẫn nằm trong tháng hiện tại → số "Thu/Chi tháng này" tròn trịa. Dòng 0 ngày → nhóm "HÔM NAY", 1 ngày → "HÔM QUA", 2–5 ngày → nhóm `dd/MM/yyyy`.

### Bảng đối chiếu kỳ vọng (chạy khi cả 11 dòng cùng tháng hiện tại)

| # | Loại | Danh mục | Ví | Ghi chú | Tiền | Nhóm ngày |
|---|---|---|---|---|---|---|
| 1 | Chi | Ăn uống | Tiền mặt | Ăn trưa văn phòng | `−85.000 đ` coral | HÔM NAY |
| 2 | Chi | Di chuyển | Tiền mặt | — | `−120.000 đ` coral | HÔM QUA |
| 3 | Thu | Lương | Vietcombank | Lương tháng 8 | `+12.000.000 đ` teal | HÔM QUA |
| 4 | Thu | Bán đồ cũ | Vietcombank | — | `+2.500.000 đ` teal | 5 ngày trước |
| 5 | Thu | Thu nhập khác | Vietcombank | — | `+500.000 đ` teal | 2 ngày trước |
| 6 | Chi | Ăn uống | Vietcombank | Siêu thị Coopmart | `−450.000 đ` coral | HÔM NAY |
| 7 | Chi | Xăng xe | Vietcombank | — | `−250.000 đ` coral | HÔM QUA |
| 8 | **Chuyển khoản** | — | Vietcombank → Momo | (một dòng duy nhất) | `700.000 đ` trung tính, **không dấu** | 3 ngày trước |
| 9 | Chi | Mua sắm | Thẻ tín dụng VIB | Mua sắm online | `−1.200.000 đ` coral | HÔM QUA |
| 10 | Chi | Ăn uống | Thẻ tín dụng VIB | — | `−350.000 đ` coral | HÔM NAY |
| 11 | = vế đích của #8 | — | (gộp vào #8) | — | — | — |

- **Thu tháng này** = 12.000.000 + 2.500.000 + 500.000 = **15.000.000 đ**.
- **Chi tháng này** = 85.000 + 120.000 + 450.000 + 250.000 + 1.200.000 + 350.000 = **2.455.000 đ**.
- Khoản chuyển 700.000 và (nếu có) điều chỉnh số dư **không** làm đổi hai con số trên.

## Cách chạy

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze        # phải sạch
flutter test           # toàn bộ (gồm transaction_screen / transaction_list / dao)
flutter run            # chọn Android emulator
```

App khởi động → màn khóa PIN (PBI 3): nhập/lập PIN lần đầu rồi vào.

## Nhóm QA

### A. Luồng chính — tab "Giao dịch" (acceptance 1–3)
1. Chạm tab **Giao dịch** ở bottom nav → màn hiện: header teal "Giao dịch" (icon lọc bên phải, chạm không lỗi), card thống kê 2 khối, danh sách nhóm theo ngày. Tab đang chọn tô teal.
2. Đối chiếu **bảng trên**: từng dòng đúng tiêu đề/dòng phụ ("Ví · ghi chú")/số tiền màu — chi coral `−`, thu teal `+`, căn phải.
3. Nhóm mới nhất trên cùng; hai dòng hôm nay nằm chung nhóm **HÔM NAY**.

### B. Chuyển khoản 1 dòng (acceptance 4)
Tìm dòng "Chuyển khoản" (nhóm 3 ngày trước): phụ đề "Vietcombank → Momo", số `700.000 đ` trung tính **không dấu**; chỉ **1** dòng (không thấy 2 dòng `+`/`−` 700.000).

### C. Card tháng (acceptance 5, FR-003)
Đối chiếu 2 con số card với bảng (chạy ngày ≥ 6 trong tháng): đúng tổng; chuyển khoản & điều chỉnh không đổi số.

### D. Tự làm mới (acceptance 6, FR-011)
Cài đặt → Quản lý ví → chọn Vietcombank → **Chuyển tiền** 200.000 sang Momo (PBI 8). Quay lại tab **Giao dịch** → xuất hiện 1 dòng "Chuyển khoản … Vietcombank → Momo" `200.000 đ` ở nhóm hôm nay, không cần làm mới tay.

### E. Cuộn & cỡ chữ (acceptance 7–8, FR-012/013, SC-007)
- Cuộn tới cuối danh sách: mượt, không treo/giật; mỗi giao dịch xuất hiện đúng 1 lần.
- Bật cỡ chữ lớn nhất (Cài đặt hệ thống) hoặc xoay vùng an toàn: header, card, nhóm ngày, dòng không vỡ/tràn, vẫn cuộn được.

### F. Biên (edge)
- **Chưa có giao dịch**: cài sạch/backup mới + không seed → tab Giao dịch hiện card `0 đ`/`0 đ`, vùng giữa hiển thị hướng dẫn ghi giao dịch đầu tiên, không lỗi.
- **Ví ẩn**: ẩn một ví (màn ví) → giao dịch của ví đó vẫn hiện ở danh sách, tên ví đủ.
- **Khóa app**: khóa lại → màn Giao dịch chỉ thấy sau mở khóa, không lộ số tiền qua màn hình khóa (FR-015).

### G. Không hồi quy
- Tab Tổng quan / Báo cáo / Cài đặt, FAB thêm giao dịch (mở màn tạm, không lỗi), luồng ví/chuyển tiền, khóa PIN — chạy lại thấy bình thường.
- `flutter test` xanh toàn bộ.

## Lưu ý xác minh qua test
Mọi kịch bản trên được phủ tự động bằng test widget với `FakeWalletRepository` (không cần sqlite native); drift map `transfer_group_id` được kiểm ở DAO test (`NativeDatabase.memory()`, skip-guard nếu host thiếu sqlite). QA emulator chỉ để xác minh trực quan & thao tác thật.
