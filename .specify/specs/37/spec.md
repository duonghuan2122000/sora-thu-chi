# Đặc tả tính năng: Tier A đọc ảnh trực tiếp (Gemini Nano đa phương thức)

**Mã PBI**: 37
**Ngày tạo**: 2026-09-15
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Hiện tại, khi quét hóa đơn/ảnh thông báo ngân hàng ở Chế độ AI trên máy — Tier A, hệ thống nhận diện chữ trong ảnh (OCR) rồi mới đưa **văn bản** đó cho mô hình AI trên máy phân tích. Tính năng này đổi Tier A sang cho mô hình AI **tự đọc trực tiếp ảnh gốc** để suy ra loại giao dịch, số tiền, ngày, người/nơi giao dịch và danh mục — không còn phụ thuộc vào văn bản OCR trích ra làm đầu vào chính, kỳ vọng đọc đúng hơn với ảnh mờ, chữ nhỏ, hoặc bị OCR đọc sai ký tự.

## Kịch bản & luồng người dùng

### Luồng chính

**Given** người dùng đã bật quét hóa đơn và máy đang ở Tier A (AI trên máy, model do hệ điều hành quản lý sẵn),
**When** người dùng chụp hoặc chọn một ảnh hóa đơn/thông báo ngân hàng để quét,
**Then** hệ thống gửi thẳng ảnh đó cho AI trên máy để nó tự đọc nội dung và trả về loại giao dịch/số tiền/ngày/người-nơi giao dịch/danh mục gợi ý, sau đó hiển thị màn xác nhận như hiện tại — người dùng không thấy khác biệt về luồng thao tác, chỉ khác biệt về độ chính xác của kết quả gợi ý.

### Kịch bản chấp nhận

1. **Given** Tier A khả dụng, **When** quét một hóa đơn cửa hàng rõ nét, **Then** kết quả gợi ý (loại/số tiền/ngày/cửa hàng/danh mục) hiển thị ở màn xác nhận giống định dạng hiện tại, không có khoanh vùng vị trí trên ảnh.
2. **Given** Tier A khả dụng, **When** quét một ảnh thông báo chuyển khoản ngân hàng có nhiều số dễ nhầm (số dư, số tài khoản, mã giao dịch), **Then** hệ thống vẫn ưu tiên đối chiếu số tiền giao dịch bằng tín hiệu hình ảnh nổi bật (cỡ chữ) đã có sẵn của bộ luật khi tín hiệu đó đủ mạnh và khác với số AI đọc được — hành vi đối chiếu này không đổi so với hiện tại.
3. **Given** Tier A khả dụng nhưng AI trên máy lỗi, treo quá thời gian chờ, hoặc trả về nội dung không đọc được, **Then** hệ thống tự động rơi về bộ luật xử lý sẵn có (không dùng AI) để vẫn đưa ra được gợi ý và cho người dùng vào màn xác nhận — không bao giờ kẹt lại ở màn xử lý.
4. **Given** Tier B (mô hình tải riêng) hoặc Chế độ cơ bản (không AI), **When** quét ảnh, **Then** hành vi giữ nguyên như hiện tại (vẫn dựa trên văn bản do OCR trích ra) — tính năng này không áp dụng cho hai chế độ đó.

### Trường hợp biên

- Ảnh quá mờ/thiếu sáng đến mức cả AI lẫn bộ luật fallback đều không đọc được gì hữu ích: hệ thống hiển thị thông báo "không đọc được" và cho chụp lại hoặc nhập tay, giống hành vi hiện tại.
- AI trên máy trả về kết quả nhưng sai định dạng (không phải JSON hợp lệ theo cấu trúc mong đợi): coi như lỗi, rơi về bộ luật, không hiển thị dữ liệu sai cho người dùng.
- Ảnh quá lớn khiến việc gửi cho AI chậm: vẫn phải tôn trọng thời gian chờ tối đa hiện có cho một lượt gọi AI mỗi lần quét; quá hạn thì rơi về bộ luật như kịch bản chấp nhận #3.

## Yêu cầu chức năng

- **FR-001**: Ở Tier A, hệ thống PHẢI gửi ảnh hóa đơn/thông báo đã quét cho AI trên máy để AI tự đọc nội dung trực tiếp từ ảnh, thay vì chỉ gửi văn bản do OCR trích ra.
- **FR-002**: Hệ thống PHẢI tiếp tục chạy nhận diện chữ (OCR) song song với việc gọi AI ở Tier A — kết quả OCR này chỉ dùng để: (a) rơi về bộ luật xử lý khi AI lỗi/timeout/kết quả không đọc được, và (b) đối chiếu số tiền cho ảnh thông báo ngân hàng như cơ chế hiện có — không còn dùng để đưa vào nội dung yêu cầu gửi cho AI.
- **FR-003**: Kết quả AI trả về (loại giao dịch, số tiền, ngày, người/nơi giao dịch, danh mục gợi ý) PHẢI được xử lý và hiển thị ở màn xác nhận theo đúng định dạng và mức độ tin cậy như cơ chế hiện tại, không đổi trải nghiệm người dùng ở bước này.
- **FR-004**: Nếu AI trên máy lỗi, treo quá thời gian chờ tối đa cho một lượt quét, hoặc trả về nội dung không đọc được thành kết quả hợp lệ, hệ thống PHẢI tự động rơi về bộ luật xử lý sẵn có, dùng kết quả OCR đã có — người dùng vẫn luôn tới được màn xác nhận hoặc màn "không đọc được ảnh, thử lại/nhập tay".
- **FR-005**: Tier B (mô hình tải riêng) và Chế độ cơ bản (không AI) PHẢI giữ nguyên hành vi hiện tại (dựa trên văn bản OCR) — tính năng này chỉ áp dụng cho Tier A.
- **FR-006**: Việc gửi ảnh cho AI ở Tier A PHẢI tiếp tục xử lý hoàn toàn trên máy, không gửi dữ liệu ảnh hay nội dung trích xuất ra bên ngoài — đúng cam kết "offline hoàn toàn" của ứng dụng.

*Mỗi yêu cầu phải kiểm thử được (testable) và không mơ hồ.*

## Tiêu chí thành công

- **SC-001**: Với ảnh hóa đơn/thông báo ngân hàng rõ nét, tỉ lệ AI đọc đúng số tiền giao dịch ở Tier A không thấp hơn so với cách làm cũ (qua văn bản OCR) trên cùng bộ ảnh thử.
- **SC-002**: 100% lượt quét ở Tier A khi AI lỗi/treo/timeout vẫn đưa người dùng tới được màn xác nhận (dùng kết quả bộ luật) hoặc màn "không đọc được" — không có trường hợp kẹt màn xử lý.
- **SC-003**: Người dùng không nhận thấy thay đổi nào về số bước thao tác hay giao diện trong luồng quét ở Tier A so với trước — chỉ khác về độ chính xác của gợi ý.
- **SC-004**: Hành vi quét ở Tier B và Chế độ cơ bản không thay đổi so với trước khi triển khai tính năng này (kiểm tra qua bộ kiểm thử hồi quy hiện có).

## Giả định

- OCR (ML Kit) tiếp tục chạy trong mọi lượt quét ở Tier A, kể cả khi AI đọc ảnh thành công — chấp nhận chi phí xử lý thêm này để giữ được fallback bộ luật và cơ chế đối chiếu số tiền ảnh ngân hàng hiện có (FR-002), theo quyết định đã chốt với người dùng.
- Tier B (Gemma 3n) không thay đổi trong phạm vi tính năng này, kể cả khi hạ tầng mô hình đó có hỗ trợ đọc ảnh trực tiếp — để giữ phạm vi nhỏ gọn, xử lý riêng nếu có nhu cầu sau.
- "Thời gian chờ tối đa cho một lượt gọi AI" giữ nguyên ngưỡng đã có trong cơ chế fallback hiện tại, không đổi giá trị.
- Ảnh gửi cho AI là ảnh đã qua bước tiền xử lý hiện có của luồng quét (không phải ảnh gốc chưa xử lý), giữ nhất quán với dữ liệu OCR đang dùng.

## Ngoài phạm vi

- Không thay đổi hành vi Tier B, Chế độ cơ bản, hay luồng bật/tắt/chọn chế độ ở màn Cài đặt.
- Không thêm khoanh vùng vị trí (rect) trên ảnh cho kết quả AI đọc trực tiếp — giữ nguyên giới hạn hiện có (AI không trả về vùng chữ).
- Không đổi cơ chế đối chiếu số tiền ảnh ngân hàng hiện có — chỉ đổi nguồn nội dung gửi cho AI.
