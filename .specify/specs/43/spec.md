# Đặc tả tính năng: Chọn hành động cho bản sao lưu cũ

**Mã PBI**: 43
**Ngày tạo**: 2026-09-17
**Trạng thái**: Nháp

## Mô tả tổng quan

Ở màn "Sao lưu & Khôi phục", danh sách "CÁC BẢN SAO LƯU" hiện chỉ cho chạm vào một bản để khôi phục ngay. Tính năng này bổ sung cho mỗi bản sao lưu trong danh sách một lựa chọn hành động: **Chia sẻ file** (gửi file backup ra ngoài qua chia sẻ hệ thống) hoặc **Khôi phục** (giữ nguyên luồng khôi phục đã có). Mục tiêu: người dùng lấy lại/gửi đi một bản sao lưu cũ (kể cả bản tự động lưu nội bộ máy) mà không phải tạo bản mới chỉ để chia sẻ.

## Kịch bản & luồng người dùng

### Luồng chính

1. Người dùng mở màn "Sao lưu & Khôi phục", cuộn tới danh sách "CÁC BẢN SAO LƯU".
2. Chạm vào một bản sao lưu bất kỳ trong danh sách → hệ thống hiện **menu chọn hành động** với 2 lựa chọn: "Chia sẻ file" và "Khôi phục từ bản này" (kèm tuỳ chọn Hủy/đóng menu).
3. Nếu chọn **"Chia sẻ file"**: hệ thống mở khay chia sẻ hệ thống với đúng file backup đã chọn, không đổi gì trên máy.
4. Nếu chọn **"Khôi phục từ bản này"**: hệ thống chạy đúng luồng khôi phục hiện có (đọc `meta`, hiện bottom sheet xác nhận + cảnh báo ghi đè + checkbox xác nhận bắt buộc, tạo bản an toàn tạm thời, ghi đè dữ liệu, hiện màn thành công).

### Kịch bản chấp nhận

1. **Given** danh sách có ít nhất 1 bản sao lưu, **When** người dùng chạm vào một bản, **Then** menu hiện đúng 2 lựa chọn hành động (Chia sẻ file, Khôi phục), không tự động thực hiện hành động nào.
2. **Given** menu hành động đang mở, **When** người dùng chọn "Chia sẻ file", **Then** khay chia sẻ hệ thống mở với file backup tương ứng, dữ liệu trên máy không đổi.
3. **Given** menu hành động đang mở, **When** người dùng chọn "Khôi phục từ bản này", **Then** hệ thống chuyển sang đúng luồng xác nhận khôi phục đã có (không tự khôi phục ngay khi vừa chọn).
4. **Given** menu hành động đang mở, **When** người dùng chọn Hủy hoặc chạm ra ngoài, **Then** menu đóng lại, không có hành động nào xảy ra, dữ liệu và danh sách không đổi.
5. **Given** một bản sao lưu là bản tự động (lưu nội bộ máy, chưa từng được chia sẻ ra ngoài), **When** người dùng chọn "Chia sẻ file" cho bản đó, **Then** khay chia sẻ hệ thống vẫn mở bình thường với đúng file đó.

### Trường hợp biên

- File backup đã bị xoá/di chuyển khỏi vị trí lưu (ví dụ bản tự động vừa bị dọn theo cơ chế xoay vòng FIFO) nhưng danh sách chưa kịp làm mới → chọn "Chia sẻ file" hoặc "Khôi phục" báo lỗi rõ ràng "Không tìm thấy file", không crash.
- Danh sách rỗng ("Chưa có bản sao lưu nào") → không có hàng nào để chạm, hành vi giữ nguyên như hiện tại.
- Người dùng mở menu hành động rồi thoát/chuyển màn giữa chừng (ví dụ khoá app) → không có hành động nào được thực hiện khi quay lại.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI hiện menu chọn hành động khi người dùng chạm vào một bản sao lưu trong danh sách "CÁC BẢN SAO LƯU", thay vì khôi phục ngay lập tức.
- **FR-002**: Menu hành động PHẢI có đúng 2 lựa chọn: "Chia sẻ file" và "Khôi phục từ bản này", cùng cách đóng menu không chọn gì.
- **FR-003**: Khi chọn "Chia sẻ file", hệ thống PHẢI mở khay chia sẻ hệ thống với đúng file của bản sao lưu đã chạm, áp dụng cho cả bản thủ công và bản tự động.
- **FR-004**: Chọn "Chia sẻ file" KHÔNG được làm thay đổi dữ liệu trên máy hay danh sách bản sao lưu.
- **FR-005**: Khi chọn "Khôi phục từ bản này", hệ thống PHẢI chạy đúng luồng khôi phục hiện có (đọc meta, xác nhận, cảnh báo ghi đè, bản an toàn tạm thời, ghi transaction DB, màn thành công) không rút gọn bất kỳ bước bảo vệ nào.
- **FR-006**: Nếu file của bản đã chọn không còn tồn tại tại thời điểm thao tác (dù là chia sẻ hay khôi phục), hệ thống PHẢI báo lỗi rõ ràng và không crash.

## Tiêu chí thành công

- **SC-001**: Từ màn "Sao lưu & Khôi phục", người dùng chia sẻ được một bản sao lưu cũ bất kỳ (kể cả bản tự động) trong tối đa 2 lần chạm.
- **SC-002**: 100% luồng khôi phục từ danh sách vẫn giữ đủ các bước bảo vệ đã có (xác nhận, cảnh báo, checkbox bắt buộc) — không có trường hợp khôi phục bị thực hiện ngay mà không qua xác nhận.
- **SC-003**: Không phát sinh thay đổi dữ liệu tài chính nào khi người dùng chỉ dùng chức năng chia sẻ.

## Giả định

- Cơ chế kích hoạt lựa chọn hành động: chạm vào hàng mở **menu 2 lựa chọn** (khuôn theo mẫu menu/bottom sheet ngắn đã dùng ở các màn khác của app), thay cho việc chạm-để-khôi-phục-ngay hiện tại. Đây là thay đổi hành vi tối thiểu, không cần thêm biểu tượng/vùng chạm riêng trên mỗi hàng.
- Áp dụng cho **mọi bản trong danh sách**, không phân biệt bản thủ công hay tự động — vì tài liệu gốc chỉ cấm *tự động* chia sẻ bản tự động ra ngoài mà không hỏi, không cấm người dùng *chủ động* chọn chia sẻ.
- Không đổi giao diện, luật, hay bảo mật của luồng khôi phục đã có (PBI 35) — chỉ đổi cách vào luồng đó từ danh sách.
- Không thêm định dạng chia sẻ mới hay kênh chia sẻ mới — dùng đúng cơ chế "khay chia sẻ hệ thống" đã có sẵn cho nút "Chia sẻ lại file" ở màn kết quả tạo backup.

## Ngoài phạm vi

- Chọn nhiều bản sao lưu cùng lúc để chia sẻ/xoá hàng loạt.
- Xoá bản sao lưu từ danh sách này.
- Đổi cơ chế/luật của luồng khôi phục đã có (xác nhận, bản an toàn tạm thời, mã hoá...).
- Thêm kênh chia sẻ riêng ngoài khay chia sẻ hệ thống (ví dụ tích hợp API cloud).
