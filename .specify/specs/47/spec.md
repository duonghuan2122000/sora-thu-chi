# Đặc tả tính năng: Nhật ký trích xuất AI

**Mã PBI**: 47
**Ngày tạo**: 2026-09-17
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Luồng quét hóa đơn bằng AI Local đôi khi trích xuất sai (loại giao dịch, số tiền, danh mục...). Tính năng này ghi lại mỗi phiên quét — kết quả AI đề xuất ban đầu, giá trị cuối cùng người dùng lưu, và toàn bộ thao tác sửa/hủy/quay lại của người dùng trong phiên — thành nhật ký lưu local. Người dùng xem lại nhật ký trong app và xuất file để cung cấp cho việc tinh chỉnh prompt/model trích xuất AI sau này.

## Kịch bản & luồng người dùng

### Luồng chính

Người dùng mở luồng quét hóa đơn AI (từ FAB "thêm giao dịch"), chụp/chọn ảnh. Hệ thống chạy trích xuất AI và điền sẵn màn Thêm giao dịch. Trong lúc đó, mọi thao tác của người dùng (sửa trường nào, giá trị trước/sau, bấm back, bấm hủy, hoặc bấm Lưu) được ghi nhận âm thầm. Khi phiên quét kết thúc (dù thành công, bị hủy, hay trích xuất lỗi), một bản ghi nhật ký hoàn chỉnh được lưu local. Người dùng có thể vào màn "Nhật ký trích xuất AI" (trong mục Cài đặt/Tiện ích) để xem danh sách, xem chi tiết từng bản ghi, xóa bớt, hoặc xuất toàn bộ ra file để chia sẻ.

### Kịch bản chấp nhận

1. **Given** người dùng quét ảnh hóa đơn và AI trích xuất, **When** người dùng sửa số tiền AI đề xuất rồi bấm Lưu, **Then** nhật ký ghi nhận: kết quả AI đề xuất ban đầu, giá trị cuối đã lưu, và sự kiện "sửa trường số tiền" kèm giá trị trước/sau.
2. **Given** AI đã trích xuất xong và điền sẵn form, **When** người dùng bấm back thoát khỏi màn hình mà không lưu, **Then** nhật ký ghi nhận phiên này là "hủy/thoát", vẫn giữ kết quả AI đề xuất và ảnh/OCR gốc.
3. **Given** người dùng đã có nhiều bản ghi nhật ký, **When** mở màn "Nhật ký trích xuất AI", **Then** thấy danh sách bản ghi mới nhất trước, chạm vào một bản ghi để xem chi tiết đầy đủ (ảnh, OCR, kết quả AI, giá trị cuối, chuỗi thao tác).
4. **Given** đang xem danh sách nhật ký, **When** bấm "Xuất file", **Then** hệ thống tạo file chứa toàn bộ nhật ký và mở bảng chia sẻ hệ thống để gửi ra ngoài app.
5. **Given** số bản ghi nhật ký đã đạt trần lưu trữ, **When** một phiên quét mới hoàn tất, **Then** bản ghi cũ nhất bị xóa tự động để nhường chỗ (FIFO).

### Trường hợp biên

- Trích xuất AI báo lỗi (không đọc được ảnh, hết bộ nhớ, engine không sẵn sàng) → vẫn ghi nhận bản ghi nhật ký với trạng thái lỗi, kèm ảnh gốc nếu có.
- Người dùng quét rồi sửa đi sửa lại nhiều lần trước khi lưu → ghi đủ toàn bộ chuỗi sự kiện sửa theo thứ tự thời gian, không chỉ lần sửa cuối.
- Người dùng xóa giao dịch vừa tạo từ quét ngay sau đó (ở màn Chi tiết) → không ảnh hưởng bản ghi nhật ký đã lưu (nhật ký độc lập với vòng đời giao dịch).
- Dung lượng máy thấp / không xuất được file → báo lỗi rõ ràng, không làm mất nhật ký đã có.
- Nhật ký rỗng (chưa quét lần nào) → màn hình hiển thị trạng thái rỗng, ẩn nút xuất file.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI tự động tạo một bản ghi nhật ký cho mỗi phiên quét hóa đơn AI, không cần người dùng bật/tắt thủ công.
- **FR-002**: Bản ghi PHẢI lưu kết quả trích xuất thô ban đầu do AI đề xuất (loại giao dịch, số tiền, danh mục, ngày, mô tả, độ tin cậy).
- **FR-003**: Bản ghi PHẢI lưu giá trị cuối cùng người dùng đã lưu thành giao dịch, nếu phiên kết thúc bằng việc tạo giao dịch thành công.
- **FR-004**: Hệ thống PHẢI ghi lại chuỗi hành vi thao tác của người dùng trong phiên: trường nào bị sửa (tên trường, giá trị trước, giá trị sau), có bấm back/thoát không, có hủy không — theo đúng thứ tự thời gian xảy ra.
- **FR-005**: Hệ thống PHẢI ghi nhận cả trường hợp phiên kết thúc bằng: lưu thành công, người dùng hủy/thoát giữa chừng, hoặc trích xuất AI báo lỗi.
- **FR-006**: Bản ghi PHẢI lưu kèm ảnh hóa đơn gốc và văn bản nhận diện (OCR) thô của phiên đó.
- **FR-007**: Người dùng PHẢI có một màn hình riêng để xem danh sách nhật ký trích xuất, sắp xếp mới nhất trước.
- **FR-008**: Người dùng PHẢI xem được chi tiết đầy đủ của một bản ghi: ảnh gốc, văn bản OCR, kết quả AI đề xuất, giá trị cuối đã lưu (nếu có), và toàn bộ chuỗi thao tác.
- **FR-009**: Người dùng PHẢI xóa được từng bản ghi nhật ký, hoặc xóa toàn bộ nhật ký.
- **FR-010**: Người dùng PHẢI xuất được toàn bộ nhật ký ra một file, dùng bảng chia sẻ hệ thống để gửi ra ngoài app.
- **FR-011**: Hệ thống PHẢI tự động xóa bản ghi cũ nhất khi số lượng bản ghi vượt trần lưu trữ quy định (FIFO), để tránh chiếm dụng vô hạn dung lượng máy.
- **FR-012**: Nhật ký PHẢI chỉ lưu và xử lý local trên máy; hệ thống không được tự động gửi nhật ký ra ngoài app nếu người dùng không chủ động bấm xuất file.

*Mỗi yêu cầu phải kiểm thử được (testable) và không mơ hồ.*

## Tiêu chí thành công

- **SC-001**: Sau khi hoàn tất hoặc hủy bất kỳ phiên quét hóa đơn AI nào, một bản ghi nhật ký tương ứng xuất hiện trong màn "Nhật ký trích xuất AI" mà người dùng không cần thao tác gì thêm.
- **SC-002**: Từ một bản ghi nhật ký bất kỳ, người dùng xác định được trong dưới 10 giây: AI đề xuất gì, người dùng đã sửa gì, và kết quả cuối cùng là gì.
- **SC-003**: Người dùng xuất được file nhật ký và chia sẻ ra ngoài app trong không quá 3 thao tác chạm.
- **SC-004**: Số lượng bản ghi nhật ký lưu trên máy không bao giờ vượt trần quy định, kể cả khi quét liên tục nhiều lần.
- **SC-005**: Việc ghi nhật ký không làm chậm cảm nhận được luồng quét hóa đơn hiện có (người dùng không nhận thấy độ trễ tăng thêm).

## Thực thể chính

- **Bản ghi nhật ký trích xuất**: một phiên quét hóa đơn AI. Gồm: thời điểm, ảnh gốc, văn bản OCR thô, kết quả AI đề xuất (từng trường), trạng thái kết thúc (lưu thành công / hủy-thoát / lỗi), giá trị cuối đã lưu (nếu có), chuỗi sự kiện thao tác (loại sự kiện, trường liên quan, giá trị trước/sau, thời điểm).
- **Sự kiện thao tác**: một hành động của người dùng trong phiên (sửa trường, back, hủy, lưu), gắn với bản ghi nhật ký cha, có thứ tự thời gian.

## Giả định

- Trần số lượng bản ghi nhật ký cụ thể (ví dụ 100/200 bản ghi) sẽ chốt số ở bước lập kế hoạch kỹ thuật, dựa theo tiền lệ trần lưu trữ đã có trong app (ví dụ sổ thông báo).
- Định dạng file xuất (JSON) sẽ chốt ở bước lập kế hoạch, theo tiền lệ cơ chế xuất báo cáo/backup JSON đã có.
- Tính năng áp dụng cho toàn bộ luồng quét hóa đơn AI hiện có (gồm cả nhận diện ảnh thông báo ngân hàng), vì dùng chung cơ chế trích xuất AI và cùng mục đích thu thập dữ liệu tinh chỉnh.
- Nhật ký không chứa thông tin định danh người dùng (không tên, không tài khoản) — chỉ dữ liệu ảnh/OCR/kết quả trích xuất/thao tác, vì app không có khái niệm tài khoản.

## Ngoài phạm vi

- Không tự động gửi nhật ký lên server hoặc dịch vụ AI bên ngoài — app vẫn offline hoàn toàn.
- Không tự động dùng nhật ký để huấn luyện lại model ngay trong app — nhật ký chỉ là dữ liệu thô để dev dùng ngoài app.
- Không có màn hình cấu hình bật/tắt việc ghi nhật ký ở giai đoạn này (mặc định luôn ghi).
