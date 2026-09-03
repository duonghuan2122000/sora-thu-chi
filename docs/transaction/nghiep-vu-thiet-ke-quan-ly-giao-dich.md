# ĐẶC TẢ NGHIỆP VỤ & THIẾT KẾ MÀN HÌNH: QUẢN LÝ GIAO DỊCH

> Chi tiết hóa mục "3. Quản lý Giao dịch (Transactions)" trong tài liệu tính năng nghiệp vụ, kèm đặc tả màn hình bám theo `DESIGN SYSTEM: APP QUẢN LÝ THU CHI`. Các mockup SVG tương ứng nằm trong thư mục đính kèm.

---

## 1. Tổng quan phạm vi

Nhóm nghiệp vụ **Quản lý Giao dịch** là trung tâm thao tác của app (tần suất dùng cao nhất — vì vậy được gắn vào FAB của Bottom Navigation). Phạm vi gồm:

- Ghi nhận giao dịch: Thu / Chi / Chuyển khoản nội bộ giữa các ví
- Xem, sửa, xóa, nhân bản giao dịch
- Tìm kiếm, lọc, sắp xếp
- Giao dịch định kỳ (recurring) và nhắc nhở
- Nhập liệu hàng loạt (CSV/Excel) và quét hóa đơn OCR (nâng cao)
- Undo sau thao tác xóa/sửa

Giai đoạn triển khai (theo roadmap gốc): nhóm **Thêm/sửa/xóa giao dịch + Danh mục** thuộc **MVP**; **Giao dịch định kỳ + Nhắc nhở** thuộc **Giai đoạn 2**; **OCR/Import nâng cao** là tùy chọn mở rộng.

---

## 2. Bản đồ màn hình (Screen Map)

| # | Màn hình | Loại (theo design system) | Vào từ | File SVG |
|---|---|---|---|---|
| 1 | Danh sách giao dịch | Màn hình chính (header teal + bottom nav) | Tab "Giao dịch" | `01-danh-sach-giao-dich.svg` |
| 2 | Thêm/Sửa giao dịch | Full-screen modal (app bar teal, không bottom nav) | FAB, nút "Sửa", "+ Thêm" | `02-them-giao-dich.svg` |
| 3 | Chọn danh mục | Sub-page (app bar teal + back) | Từ màn Thêm/Sửa giao dịch | `03-chon-danh-muc.svg` |
| 4 | Chi tiết giao dịch | Sub-page (app bar teal + back) | Chạm vào 1 dòng giao dịch | `04-chi-tiet-giao-dich.svg` |
| 5 | Tìm kiếm & Lọc | Sub-page (app bar teal, chứa ô search) | Icon lọc/tìm kiếm ở màn Danh sách | `05-tim-kiem-loc.svg` |
| 6 | Giao dịch định kỳ | Sub-page (app bar teal + back) | Từ Cài đặt hoặc menu ở màn Danh sách | `06-giao-dich-dinh-ky.svg` |

---

## 3. Đặc tả nghiệp vụ chi tiết

### 3.1 Thêm giao dịch
- **Loại giao dịch** chọn qua segmented tab: `Chi | Thu | Chuyển khoản` (mặc định mở ở "Chi" vì tần suất cao nhất).
- **Trường dữ liệu bắt buộc:** Số tiền (> 0, dùng bàn phím số tùy chỉnh có dấu phân cách nghìn tự động), Danh mục, Ví áp dụng, Ngày giờ (mặc định = hiện tại).
- **Trường tùy chọn:** Ghi chú, Tag, Ảnh hóa đơn (chụp hoặc chọn từ thư viện), Vị trí GPS (nếu bật quyền).
- **Chuyển khoản (Transfer):** thay Danh mục bằng cặp Ví nguồn → Ví đích; không tính vào tổng Thu/Chi của báo cáo; validate ví nguồn ≠ ví đích và số dư ví nguồn đủ (cảnh báo mềm nếu âm quỹ, không chặn cứng vì tiền mặt có thể âm tạm).
- **Nhập nhanh (Quick Add):** phiên bản rút gọn chỉ hỏi Số tiền + Danh mục + Ví, các trường còn lại dùng mặc định lần nhập gần nhất; có thể gọi từ widget màn hình chính hoặc notification.
- **Lưu & tiếp tục thêm:** sau khi lưu, hiển thị snackbar xác nhận kèm tùy chọn "Thêm giao dịch khác" để nhập liên tiếp nhiều khoản (hữu ích khi nhập hóa đơn chợ nhiều mục).

### 3.2 Sửa / Xóa giao dịch
- Sửa: mở lại đúng màn "Thêm giao dịch" với dữ liệu điền sẵn, app bar đổi tiêu đề thành "Sửa giao dịch".
- Xóa: xác nhận bằng dialog ngắn; sau khi xóa hiển thị snackbar **Undo** trong ~5 giây trước khi xóa vĩnh viễn.
- Sửa/xóa giao dịch thuộc chuỗi định kỳ: hỏi rõ phạm vi áp dụng — "Chỉ giao dịch này" hay "Toàn bộ chuỗi từ đây trở đi".

### 3.3 Nhân bản giao dịch (Duplicate)
- Từ màn Chi tiết giao dịch, nút "Nhân bản" tạo bản sao với ngày giờ = hiện tại, các trường khác giữ nguyên, mở ngay màn Thêm/Sửa để người dùng chỉnh trước khi lưu — phù hợp cho chi tiêu lặp lại không đủ đều đặn để làm giao dịch định kỳ (VD: đổ xăng, đi chợ).

### 3.4 Tìm kiếm, lọc & sắp xếp
- Tìm theo từ khóa (ghi chú, tên danh mục, tag) — tìm kiếm tức thời (debounce) khi gõ.
- Lọc theo: loại giao dịch (Thu/Chi/Chuyển khoản), khoảng thời gian (preset: Hôm nay/Tuần này/Tháng này hoặc tùy chỉnh), danh mục (multi-select), ví, khoảng số tiền (min–max), tag.
- Sắp xếp: Ngày mới nhất/cũ nhất, Số tiền tăng/giảm dần.
- Các bộ lọc có thể kết hợp đồng thời; hiển thị số lượng kết quả và tổng số tiền khớp bộ lọc ngay trên danh sách kết quả.

### 3.5 Giao dịch định kỳ (Recurring Transactions)
- Cấu hình: Loại (Thu/Chi), Số tiền (có thể để trống nếu số tiền thay đổi mỗi kỳ — nhắc nhập tay), Danh mục, Ví, **Chu kỳ** (Hàng ngày/Hàng tuần/Hàng tháng/Hàng năm + mốc lặp, VD "ngày 25 hằng tháng"), Ngày bắt đầu, Ngày kết thúc (hoặc không giới hạn), Số ngày nhắc trước khi đến hạn.
- Hệ thống tự động sinh giao dịch đúng chu kỳ; giao dịch sinh ra đánh dấu nguồn gốc "định kỳ" để hiển thị icon riêng trong danh sách.
- Nhắc nhở qua push notification trước hạn N ngày (cấu hình được), cho phép xác nhận nhanh "Đã thu/chi" ngay từ notification.
- Danh sách các chuỗi định kỳ đã tạo có toggle Bật/Tắt nhanh từng chuỗi mà không cần xóa cấu hình.

### 3.6 Nhập liệu hàng loạt (Import CSV/Excel)
- Luồng: Chọn file → Ánh xạ cột (mapping: cột nào là ngày/số tiền/danh mục/ghi chú) → Xem trước bảng dữ liệu đã ánh xạ → Xác nhận import → Báo cáo kết quả (số dòng thành công/lỗi, cho phép tải file lỗi để sửa và import lại).
- Danh mục không khớp danh mục có sẵn: cho phép tạo mới nhanh hoặc gán tạm vào "Khác".

### 3.7 Quét hóa đơn bằng OCR (nâng cao, tùy chọn)
- Chụp/chọn ảnh hóa đơn → OCR nhận diện số tiền, ngày, tên cửa hàng → điền sẵn vào form Thêm giao dịch để người dùng xác nhận/chỉnh sửa trước khi lưu (không tự lưu thẳng để tránh sai sót OCR).

### 3.8 Đính kèm ảnh hóa đơn & vị trí giao dịch
- Ảnh hóa đơn: chụp mới hoặc chọn từ thư viện, xem trước dạng thumbnail trong form và màn Chi tiết, hỗ trợ xem phóng to.
- Vị trí: chỉ ghi khi người dùng bật quyền GPS; hiển thị dạng text địa chỉ rút gọn ở màn Chi tiết, không bắt buộc.

### 3.9 Undo & an toàn thao tác
- Mọi hành động xóa (giao dịch, hoặc sửa làm mất dữ liệu) đều có Undo tức thời qua snackbar, tránh mất dữ liệu do bấm nhầm — áp dụng nhất quán cho toàn bộ nhóm nghiệp vụ này.

---

## 4. Đặc tả UI theo từng màn hình

### 4.1 Danh sách giao dịch (`01-danh-sach-giao-dich.svg`)
- **App bar teal** (`#0F6E56`): tiêu đề "Giao dịch", icon lọc bên phải mở màn Tìm kiếm & Lọc.
- **Card thống kê nhanh** (nền `#F1EFE8`, bo góc `10px`) 2 khối cạnh nhau: "Thu tháng này" (icon mũi tên lên, số màu chữ chính) và "Chi tháng này" (icon mũi tên xuống màu coral `#D85A30`).
- **Danh sách** nhóm theo ngày, tiêu đề nhóm nhỏ viết hoa màu `#9B9B9B`; mỗi dòng `ListTile`: icon tròn nền theo màu danh mục + tên danh mục/ghi chú (chữ chính `#1A1A1A`) + tên ví (chữ phụ `#5F5E5A`) + số tiền căn phải (thu: chữ chính hoặc teal có dấu `+`; chi: coral có dấu `-`); đường kẻ phân cách `#EFEFEF`.
- **Bottom Navigation**: 4 tab + FAB giữa theo đúng quy tắc mục 2.1 của design system; tab "Giao dịch" đang chọn tô teal.

### 4.2 Thêm giao dịch (`02-them-giao-dich.svg`)
- **App bar teal**: icon đóng (X) bên trái, tiêu đề "Thêm giao dịch", icon check bên phải để lưu — không có bottom nav (đúng nguyên tắc "màn hình tập trung 1 tác vụ chính").
- **Segmented tab** Chi/Thu/Chuyển khoản: tab đang chọn nền teal chữ trắng, tab còn lại nền trắng viền `#E0E0E0` chữ `#5F5E5A` — tuân thủ quy tắc "chỉ 1 màu thương hiệu cho trạng thái đang chọn".
- **Số tiền lớn** căn giữa, cỡ chữ 22–24px/600, đơn vị "đ" theo sau.
- **Bàn phím số tùy chỉnh** tái sử dụng phong cách numpad (lưới tròn, viền mảnh `#E0E0E0`, không nền) của màn khóa PIN, mở rộng thêm dấu thập phân và icon backspace.
- **Danh sách trường** dạng `ListTile` (icon trái + label + giá trị/chevron phải): Danh mục, Ví, Ngày giờ, Ghi chú — mở các sub-page tương ứng khi chạm.
- **Nút chính** "Lưu giao dịch" full-width, nền teal, bo góc `8px`, cao `44px`.

### 4.3 Chọn danh mục (`03-chon-danh-muc.svg`)
- **App bar teal + back**, tiêu đề "Chọn danh mục".
- **Lưới 4 cột**: mỗi ô = icon tròn (nền màu riêng theo danh mục, icon trắng, đường kính ~48–52px) + label bên dưới căn giữa, cỡ chữ 11–12px.
- Ô cuối cùng "Thêm danh mục" viền nét đứt `#B4B2A9`, icon dấu cộng, để tạo danh mục tùy chỉnh ngay tại chỗ.

### 4.4 Chi tiết giao dịch (`04-chi-tiet-giao-dich.svg`)
- **App bar teal + back**, tiêu đề "Chi tiết giao dịch", icon 3 chấm (menu: Sửa/Xóa) bên phải.
- **Khối tóm tắt** ở đầu nội dung: icon danh mục tròn lớn (nền teal nhạt `#E1F5EE`), tên danh mục, số tiền lớn màu ngữ cảnh (coral nếu Chi, chữ chính/teal nếu Thu).
- **Danh sách chi tiết** dạng `ListTile` có đường kẻ phân cách: Ví, Ngày giờ, Ghi chú, Tag, Ảnh hóa đơn (thumbnail), Vị trí.
- **2 nút dưới cùng** cạnh nhau: "Nhân bản" (nút phụ, viền `#E0E0E0`) và "Sửa" (nút chính, teal).

### 4.5 Tìm kiếm & Lọc (`05-tim-kiem-loc.svg`)
- **App bar teal** chứa luôn ô tìm kiếm dạng pill nền trắng, icon kính lúp, placeholder "Tìm kiếm giao dịch...".
- **Hàng chip lọc nhanh** cuộn ngang: Tất cả/Thu/Chi/Chuyển khoản — chip đang chọn nền teal chữ trắng, còn lại viền `#E0E0E0` chữ `#5F5E5A`.
- **Bộ lọc nâng cao** dạng `ListTile`: Khoảng thời gian, Danh mục (multi-select), Ví, Khoảng số tiền, Sắp xếp theo — mỗi dòng có chevron mở picker riêng.
- **2 nút dưới cùng**: "Đặt lại" (phụ) và "Áp dụng" (chính, teal).

### 4.6 Giao dịch định kỳ (`06-giao-dich-dinh-ky.svg`)
- **App bar teal + back**, tiêu đề "Giao dịch định kỳ".
- **Form thiết lập**: tab Thu/Chi, Số tiền, Danh mục, Ví, Chu kỳ (dropdown), Ngày bắt đầu/kết thúc, Nhắc trước (N ngày) — cùng phong cách `ListTile`/input như màn Thêm giao dịch.
- **Danh sách chuỗi đã tạo** bên dưới, mỗi dòng có toggle Bật/Tắt (đúng style Switch của design system: nền teal khi bật).
- **Nút chính** "Lưu" full-width teal ở cuối màn hình.

---

## 5. Nguyên tắc màu sắc áp dụng riêng cho nhóm Giao dịch

| Ngữ cảnh | Màu | Ghi chú |
|---|---|---|
| Số tiền Thu, icon mũi tên lên, trạng thái đang chọn (tab/chip) | Teal `#0F6E56` | Nhất quán làm màu hành động chính/trạng thái chọn |
| Số tiền Chi, icon mũi tên xuống, cảnh báo vượt ngân sách | Coral `#D85A30` | Không dùng coral cho mục đích trang trí khác |
| Chuyển khoản | Trung tính (chữ chính `#1A1A1A` + icon 2 mũi tên xám) | Không thuộc Thu/Chi nên không dùng teal/coral để tránh nhầm lẫn báo cáo |

---

## 6. Danh sách file đính kèm

- `nghiep-vu-thiet-ke-quan-ly-giao-dich.md` — tài liệu này
- `01-danh-sach-giao-dich.svg`
- `02-them-giao-dich.svg`
- `03-chon-danh-muc.svg`
- `04-chi-tiet-giao-dich.svg`
- `05-tim-kiem-loc.svg`
- `06-giao-dich-dinh-ky.svg`
