# Kịch bản khởi động nhanh — PBI 11: Màn hình thêm giao dịch & chọn danh mục

Ngày: 2026-09-05

## Chuẩn bị dữ liệu mẫu

App tự seed lần đầu (onCreate): 5 ví mẫu + **bảng danh mục mặc định** (mới, schema v4) + 11 giao dịch mẫu (`TransactionSource`). Ngày dòng mẫu **tương đối so với giờ chạy** (cách nay 0/1/2/3/5 ngày).

**Bảng danh mục mặc định** (từ `data-model.md`, QA đối chiếu màn chọn):

| Loại | Cha | Con | Icon | Màu |
|---|---|---|---|---|
| Chi | Ăn uống | Cà phê, Ăn ngoài, Đi chợ | restaurant… | `#3D8C77` |
| Chi | Di chuyển | — | directions_car | `#0F6E56` |
| Chi | Nhà ở | — | home | `#5F5E5A` |
| Chi | Hóa đơn | — | receipt | `#D85A30` |
| Chi | Mua sắm | — | shopping_bag | `#3D8C77` |
| Chi | Giải trí | — | sports_esports | `#0F6E56` |
| Chi | Sức khỏe | — | medical_services | `#5F5E5A` |
| Chi | Giáo dục | — | school | `#D85A30` |
| Thu | Lương | — | payments | `#0F6E56` |
| Thu | Thưởng | — | redeem | `#3D8C77` |
| Thu | Đầu tư | — | show_chart | `#5F5E5A` |
| Thu | Khác | — | category | `#9B9B9B` |

Giao dịch seed cũ khớp tên danh mục mặc định → được gán `category_id` (VD dòng "Ăn uống"); tên lạ (`'Xăng xe'`, `'Thu nhập khác'`, `'Bán đồ cũ'`) giữ `category_id` null — **danh sách/chi tiết không đổi** (vẫn hiển thị đúng tên).

> Nếu đã cài bản PBI 10 (schema v3) — app tự `onUpgrade` v3→v4: tạo bảng `categories`, thêm cột `category_id`, seed danh mục; **không mất dữ liệu, không cần cài lại**. Bản fresh chạy thẳng onCreate v4.

## Cách chạy (bắt buộc regen `.g.dart` trước)

```bash
cd app/sora_thu_chi
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # schema v4 → tái sinh app_database.g.dart
flutter analyze        # phải sạch
flutter test           # toàn bộ (gồm add_form / add_transaction_screen / category_picker / dao)
flutter run            # chọn Android emulator
```

App khởi động → màn khóa PIN (PBI 3): nhập/lập PIN lần đầu rồi vào. Tab **Giao dịch** → chạm **FAB "+"** để mở màn Thêm giao dịch.

## Nhóm QA

### A. Luồng chính — ghi khoản chi (acceptance 1–3, SC-001/002/003/007)
1. Tab **Giao dịch** → FAB "+" → màn **Thêm giao dịch**: toàn màn hình (không bottom nav), app bar teal tiêu đề "Thêm giao dịch", **X** trái, **check** phải; segmented **Chi** mặc định; số tiền `0 đ`; 4 trường Danh mục / Ví / Ngày giờ / Ghi chú; numpad; nút **"Lưu giao dịch"**.
2. Gõ phím `1`,`2`,`5`,`0`,`0`,`0`,`0` → vùng số tiền hiển thị **`1.250.000 đ`** (phân tách nghìn, đơn vị `đ`, accent coral vì đang Chi). Phím xóa lùi xoá từng số; phím `,` chạm không có tác dụng.
3. Chạm trường **Danh mục** → màn "Chọn danh mục": lưới chỉ danh mục **chi** (Ăn uống…Giáo dục) — không thấy Lương/Thưởng. Chạm **Ăn uống** → hiện vùng **"DANH MỤC CON: ĂN UỐNG"** (Cà phê, Ăn ngoài, Đi chợ); chạm **Ăn ngoài** → quay về, trường Danh mục = "Ăn ngoài".
4. Chạm trường **Ví** → sheet chọn ví hoạt động (mặc định nạp sẵn ví mặc định, VD Tiền mặt); trường Ngày giờ mặc định hiện tại (đổi được — Material date rồi time picker); Ghi chú nhập "Ăn trưa" (tùy chọn).
5. Chạm **"Lưu giao dịch"** → về danh sách; dòng mới "Ăn ngoài – −1.250.000 đ – Tiền mặt" xuất hiện nhóm đúng ngày, card "Thu/Chi tháng này" **Chi tăng 1.250.000**; ví Tiền mặt giảm tương ứng (mở Quản lý ví kiểm).

### B. Ghi khoản thu (acceptance 4, SC-004)
FAB "+" → chuyển segmented sang **Thu** (accent số tiền chuyển **teal**) → Danh mục hiện danh mục **thu** (Lương, Thưởng, Đầu tư, Khác) — không thấy danh mục chi → chọn Lương → nhập số → Lưu → dòng `+… đ` teal, Thu tháng này tăng.

### C. Danh mục cha không con & ô "Thêm mới" (FR-006/007)
- Ở Chi, chạm danh mục **không con** (VD **Nhà ở**) → chọn ngay (không hiện vùng DANH MỤC CON), trường = "Nhà ở".
- Mở lại màn chọn → ô **"Thêm mới"** cuối lưới chạm → **không lỗi/không treo** (chưa kích hoạt — module Danh mục sau).

### D. Chuyển khoản (acceptance 7, FR-003)
FAB "+" → chạm tab **"Chuyển khoản"** → mở luồng chuyển tiền (PBI 8). Ghi xong một khoản chuyển → quay về danh sách: xuất hiện 1 dòng "Chuyển khoản" trung tính; không thấy form chuyển khoản nào trong màn thêm thu/chi.

### E. Validation & chống trùng (acceptance 6, SC-005/009; FR-011/012)
- Mở màn thêm, chưa nhập gì → bấm **"Lưu giao dịch"** (và **icon check**) → báo rõ tại trường: "Vui lòng nhập số tiền lớn hơn 0", "Chưa chọn danh mục", "Chưa chọn ví", "Chưa chọn ngày giờ"; không tạo giao dịch.
- Nhập hợp lệ → bấm **Lưu 2 lần liên tiếp nhanh** → chỉ tạo **đúng 1** giao dịch.

### F. Xác nhận rời màn khi có dữ liệu (acceptance 8, FR-014)
Nhập số tiền/danh mục rồi chạm **X** (hoặc back) → dialog xác nhận "Thoát sẽ mất dữ liệu đã nhập"; chọn **Thoát** → về danh sách, không có giao dịch; chọn **Hủy** → ở lại, dữ liệu không mất. Màn chưa nhập gì → X thoát thẳng (không hỏi).

### G. Biên & độ bền (edge + FR-015/016, SC-008)
- **Ví rỗng**: ẩn/tạo mới không còn ví hoạt động → mở màn thêm hiện thông báo "Chưa có ví hoạt động — hãy tạo ví trong Quản lý ví", chặn Lưu, X thoát được (không kẹt).
- **Một ví hoạt động** → trường Ví nạp sẵn, không cần mở danh sách.
- **Ví ẩn** → không xuất hiện trong sheet chọn ví.
- **Số tiền rất lớn** → hiển thị đủ phân tách nghìn, không tràn/cắt.
- **Ngày giờ tương lai** → lưu được, hiện đúng nhóm ngày theo ngày chọn.
- **Ghi chú dài/nhiều dòng** → lưu & hiển thị trọn.
- **Không danh mục loại đang chọn** → màn chọn hiện trạng thái rỗng + hướng dẫn, không lỗi.
- **Cỡ chữ lớn nhất / safe area**: màn thêm (segmented, số tiền, numpad, 4 trường, nút Lưu) và màn chọn danh mục hiển thị đủ, cuộn được, **không vỡ/tràn**, nút "Lưu giao dịch" không bị cắt.
- **Khóa app**: màn thêm/chọn chỉ thấy sau mở khóa, không lộ số tiền qua màn khóa.

### H. Không hồi quy
- Tab Tổng quan / Giao dịch (danh sách nhóm/đếm/chi tiết như PBI 9/10 — tên danh mục cũ vẫn hiển thị đúng) / Báo cáo / Cài đặt, luồng ví & chuyển tiền, khóa PIN — bình thường.
- `flutter test` xanh toàn bộ (gồm test PBI 6/7/8/9/10 chạy lại).

## Lưu ý xác minh qua test
Mọi kịch bản trên được phủ tự động:
- **Unit thuần** `add_form_test.dart`: gõ số (0 đầu, giới hạn 12 chữ số), backspace, thiếu trường, dirty.
- **Unit `addTransaction`** (qua fake/DAO): income +balance/dòng `+`, expense −balance/dòng `−`, đúng ví/ngày/`category_id` + tên, transfer không gắn danh mục.
- **Widget** `add_transaction_screen_test.dart` + `category_picker_screen_test.dart`: bơm `FakeWalletRepository` — bố cục mockup, numpad `1.250.000 đ`, lọc thu/chi, drill con, ô "Thêm mới" no-op, báo lỗi tại trường, dialog xác nhận, 2 lần Lưu → 1 dòng, empty ví, cỡ chữ lớn + safe area.
- **DAO** `transactions_dao_test.dart`: `NativeDatabase.memory()` — seed categories (bảng rỗng → đủ 12 cha + 3 con), `category_id` khớp tên, `addTransaction` drift; skip-guard nếu host thiếu sqlite.

QA emulator chỉ để xác minh trực quan & thao tác thật.
