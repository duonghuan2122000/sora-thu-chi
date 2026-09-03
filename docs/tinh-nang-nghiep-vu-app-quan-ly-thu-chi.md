# TÍNH NĂNG NGHIỆP VỤ APP QUẢN LÝ THU CHI (Flutter Mobile)

## 1. Quản lý tài khoản người dùng (Authentication & Profile)
- App hoạt động hoàn toàn offline, không cần đăng ký/đăng nhập tài khoản, dữ liệu lưu trữ local trên thiết bị
- Bảo mật ứng dụng: khóa app bằng Mã PIN, vân tay (Fingerprint) hoặc Face ID
- Quản lý hồ sơ cá nhân: avatar, tên hiển thị, tiền tệ mặc định (VND, USD...), múi giờ
- Đặt lại/thay đổi mã PIN bảo mật

## 2. Quản lý Ví/Tài khoản (Wallets & Accounts)
- Tạo nhiều ví: tiền mặt, tài khoản ngân hàng, thẻ tín dụng, ví điện tử (Momo, ZaloPay...), sổ tiết kiệm
- Đặt số dư ban đầu cho từng ví
- Chỉnh sửa, xóa, ẩn/hiện ví
- Chuyển tiền giữa các ví (Transfer) — không tính là thu/chi mà là chuyển khoản nội bộ
- Xem số dư từng ví và tổng số dư tất cả ví
- Đặt ví mặc định khi nhập giao dịch nhanh
- Hỗ trợ đa tiền tệ cho từng ví, quy đổi tỷ giá khi tổng hợp báo cáo

## 3. Quản lý Giao dịch (Transactions)
- Thêm giao dịch Thu (Income) / Chi (Expense) / Chuyển khoản (Transfer)
- Nhập nhanh (Quick Add) từ màn hình chính hoặc widget/notification
- Trường dữ liệu giao dịch:
  - Số tiền
  - Loại (thu/chi/chuyển khoản)
  - Danh mục (category)
  - Ví/tài khoản áp dụng
  - Ngày giờ giao dịch
  - Ghi chú, tag
  - Ảnh hóa đơn/chứng từ đính kèm
  - Vị trí giao dịch (địa điểm, nếu bật GPS)
- Sửa, xóa giao dịch
- Nhân bản giao dịch (duplicate) cho các khoản chi lặp lại
- Tìm kiếm giao dịch theo từ khóa, khoảng thời gian, danh mục, số tiền
- Lọc & sắp xếp giao dịch (theo ngày, số tiền tăng/giảm, danh mục)
- Giao dịch định kỳ (Recurring Transactions): tiền lương, tiền thuê nhà, hóa đơn điện nước — tự động tạo theo chu kỳ (ngày/tuần/tháng/năm)
- Nhắc nhở giao dịch định kỳ sắp đến hạn (hóa đơn, trả nợ...)
- Nhập liệu hàng loạt (import từ file CSV/Excel)
- Quét hóa đơn bằng OCR để tự động nhận diện số tiền, ngày, cửa hàng (tùy chọn nâng cao)
- Undo sau khi xóa/sửa (tránh mất dữ liệu do thao tác nhầm)

## 4. Quản lý Danh mục (Categories)
- Danh mục mặc định: Ăn uống, Di chuyển, Nhà ở, Hóa đơn, Mua sắm, Giải trí, Sức khỏe, Giáo dục, Lương, Thưởng, Đầu tư...
- Tạo danh mục tùy chỉnh (tên, icon, màu sắc)
- Danh mục cha - con (Subcategory), ví dụ: Ăn uống > Cà phê, Ăn ngoài, Đi chợ
- Sắp xếp lại thứ tự hiển thị danh mục
- Ẩn/xóa danh mục không dùng
- Gán icon/màu để nhận diện nhanh trên biểu đồ

## 5. Ngân sách (Budgeting)
- Thiết lập ngân sách theo danh mục (VD: Ăn uống tối đa 3 triệu/tháng)
- Thiết lập ngân sách tổng theo tháng/tuần/năm
- Theo dõi tiến độ sử dụng ngân sách (thanh progress bar: đã dùng bao nhiêu %)
- Cảnh báo khi chi tiêu gần/vượt ngân sách (push notification)
- So sánh ngân sách dự kiến vs thực tế
- Sao chép ngân sách tháng trước sang tháng mới
- Ngân sách theo từng ví riêng biệt (tùy chọn)

## 6. Mục tiêu tiết kiệm (Savings Goals)
- Tạo mục tiêu tiết kiệm (VD: Mua xe, Du lịch, Quỹ dự phòng) với số tiền mục tiêu và hạn chót
- Nạp tiền định kỳ hoặc thủ công vào mục tiêu
- Theo dõi tiến độ đạt mục tiêu (%)
- Nhắc nhở đóng góp định kỳ cho mục tiêu
- Thông báo khi hoàn thành mục tiêu

## 7. Quản lý Nợ & Cho vay (Debt & Lending)
- Ghi nhận khoản vay (mình nợ người khác) và khoản cho vay (người khác nợ mình)
- Theo dõi lịch trả nợ, số tiền còn lại
- Nhắc nhở ngày đến hạn trả/thu nợ
- Đánh dấu đã tất toán khoản nợ

## 8. Báo cáo & Thống kê (Reports & Analytics)
- Biểu đồ tổng quan thu/chi theo ngày/tuần/tháng/năm (line chart, bar chart)
- Biểu đồ tròn (pie chart) phân bổ chi tiêu theo danh mục
- So sánh thu chi giữa các kỳ (tháng này vs tháng trước, năm nay vs năm trước)
- Xu hướng chi tiêu theo thời gian (trend analysis)
- Top danh mục chi tiêu nhiều nhất
- Báo cáo dòng tiền (cash flow) theo từng ví
- Xuất báo cáo ra PDF/Excel/CSV để chia sẻ hoặc lưu trữ
- Lọc báo cáo theo khoảng thời gian tùy chỉnh, theo ví, theo danh mục, theo tag

## 9. Thông báo & Nhắc nhở (Notifications & Reminders)
- Nhắc nhập giao dịch hàng ngày (tránh quên ghi chép)
- Cảnh báo vượt ngân sách
- Nhắc hóa đơn/khoản định kỳ sắp đến hạn
- Nhắc mục tiêu tiết kiệm
- Thông báo tổng kết cuối tuần/cuối tháng (insight tự động, VD: "Bạn chi nhiều hơn tháng trước 15%")

## 10. Đồng bộ & Sao lưu dữ liệu (Sync & Backup)
- Xuất dữ liệu ra file JSON để sao lưu (backup) thủ công, lưu trữ local trên thiết bị hoặc chia sẻ sang nơi khác
- Khôi phục dữ liệu bằng cách nhập (import) lại file JSON backup
- Xem thông tin bản backup (thời gian tạo, số lượng giao dịch/ví/danh mục) trước khi khôi phục
- Cảnh báo xác nhận trước khi ghi đè dữ liệu hiện tại khi khôi phục từ file backup

## 11. Chia sẻ & Cộng tác (Sharing/Family mode)
> *Tạm thời bỏ qua — chưa triển khai trong giai đoạn hiện tại.*

## 12. Tiện ích & Cá nhân hóa (Utilities & Personalization)
- Giao diện Light/Dark mode
- Đa ngôn ngữ (Việt/Anh...)
- Widget màn hình chính hiển thị số dư/chi tiêu nhanh
- Tùy chỉnh định dạng ngày, đơn vị tiền tệ, đầu tuần/đầu tháng tài chính (VD: kỳ tài chính bắt đầu từ ngày 25)
- Máy tính bỏ túi tích hợp khi nhập số tiền
- Tìm kiếm toàn cục (giao dịch, danh mục, ví)
- Tag/nhãn tùy chỉnh cho giao dịch (VD: #dulich, #congty) để lọc chéo danh mục

## 13. Bảo mật & Quyền riêng tư (Security & Privacy)
- Mã hóa dữ liệu local (SQLite/Hive được mã hóa)
- Không lưu thông tin thẻ/tài khoản ngân hàng thật (chỉ là nhãn tham chiếu) trừ khi tích hợp Open Banking chính thức
- Tùy chọn ẩn số dư trên màn hình chính (Privacy mode/che số tiền)
- Xác thực sinh trắc học trước khi xem/sửa dữ liệu nhạy cảm

## 14. Tích hợp nâng cao (tùy chọn mở rộng)
> *Tạm thời bỏ qua — chưa triển khai trong giai đoạn hiện tại.*

---

## Gợi ý nhóm tính năng theo giai đoạn phát triển (MVP → Nâng cao)

| Giai đoạn | Tính năng trọng tâm |
|---|---|
| **MVP** | Khóa app bằng PIN/vân tay/FaceID, Quản lý ví, Thêm/sửa/xóa giao dịch, Danh mục, Báo cáo cơ bản (pie/bar chart) |
| **Giai đoạn 2** | Ngân sách, Giao dịch định kỳ, Nhắc nhở, Xuất báo cáo Excel/PDF |
| **Giai đoạn 3** | Mục tiêu tiết kiệm, Quản lý nợ, Backup/Restore bằng file JSON |

> Các tính năng "Chia sẻ & Cộng tác" và "Tích hợp nâng cao" tạm thời chưa nằm trong lộ trình.

## Stack kỹ thuật Flutter
- **Nền tảng**: Flutter Mobile (Android/iOS), ứng dụng offline hoàn toàn
- **Local DB**: `drift`
- **State management**: `GetX`
- **Biểu đồ**: `fl_chart`
- **Thông báo local**: `flutter_local_notifications`
- **Xuất/nhập dữ liệu**: JSON backup/restore (đọc-ghi file JSON local)
- **Bảo mật**: `flutter_secure_storage` (lưu mã PIN/khóa mã hóa), kết hợp sinh trắc học (vân tay/FaceID) qua `local_auth`
