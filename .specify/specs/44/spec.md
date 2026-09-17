# Đặc tả tính năng: Nút back thiếu/không nhất quán

**Mã PBI**: 44
**Ngày tạo**: 2026-09-17
**Trạng thái**: Nháp

## Mô tả tổng quan

Một số sub-page trong app tự dựng app bar/nút back riêng thay vì dùng mẫu chuẩn của hệ thống, khiến người dùng gặp trải nghiệm back không nhất quán giữa các màn (thiếu header 2 dòng, sai màu, hoặc thiếu hẳn nút back). Tính năng này chuẩn hoá lại các màn lệch chuẩn để mọi sub-page dùng chung 1 kiểu app bar + back, và làm rõ hành vi back cho màn hiện đang thiếu nút back hoàn toàn.

## Kịch bản & luồng người dùng

### Luồng chính

Given người dùng đang ở màn chính (Tổng quan/Giao dịch/Danh mục/Cài đặt...), When họ điều hướng vào 1 sub-page bất kỳ (danh mục con, chọn danh mục, chọn tag, kết quả sao lưu...), Then màn đó hiển thị app bar cùng kiểu (màu thương hiệu teal, tiêu đề, nút back mũi tên bên trái) như mọi sub-page khác trong app, và chạm nút back đưa người dùng quay lại đúng màn trước đó.

### Kịch bản chấp nhận

1. **Given** người dùng mở màn "Danh mục con" từ màn Danh mục, **When** màn hiển thị, **Then** app bar dùng đúng kiểu chuẩn (không phải app bar tự dựng riêng, không hard-code màu chữ/icon).
2. **Given** người dùng mở màn "Chọn danh mục" hoặc "Chọn Tag" (từ màn thêm/sửa giao dịch), **When** màn hiển thị, **Then** app bar dùng đúng kiểu chuẩn thay vì kiểu app bar trần khác biệt.
3. **Given** người dùng vừa hoàn tất một thao tác sao lưu/khôi phục và đang ở màn kết quả, **When** màn hiển thị, **Then** có nút back rõ ràng (hoặc vuốt back hệ thống hoạt động nhất quán) để quay lại, thay vì màn "kẹt" không có cách thoát tường minh.
4. **Given** người dùng đang ở màn bảo mật (khoá PIN, thiết lập PIN) hoặc màn dạng modal (quét hoá đơn, thêm giao dịch), **When** màn hiển thị, **Then** hành vi back giữ nguyên như hiện tại (không đổi) — các màn này có chủ đích không dùng nút back mũi tên chuẩn.

### Trường hợp biên

- Màn "Chọn danh mục"/"Chọn Tag" có thể được mở từ nhiều nơi (thêm giao dịch, sửa giao dịch, lọc...) — sau khi chuẩn hoá app bar, hành vi chọn xong quay lại (trả kết quả) phải giữ nguyên như trước, chỉ đổi giao diện app bar.
- Màn kết quả sao lưu/khôi phục có thể đạt được cả từ luồng thành công lẫn luồng lỗi — cả hai đều phải có cách thoát rõ ràng.

## Yêu cầu chức năng

- **FR-001**: Màn "Danh mục con" PHẢI dùng chung mẫu app bar + nút back chuẩn của hệ thống, không tự dựng app bar riêng hay hard-code màu.
- **FR-002**: Màn "Chọn danh mục" và màn "Chọn Tag" PHẢI dùng chung mẫu app bar + nút back chuẩn của hệ thống thay vì app bar trần hiện tại.
- **FR-003**: Màn kết quả sao lưu/khôi phục PHẢI có nút back tường minh và hành vi vuốt-back hệ thống rõ ràng (cho phép quay lại), không được để màn không có cách thoát nào.
- **FR-004**: Các màn có chủ đích không dùng nút back chuẩn (màn bảo mật PIN, màn dạng modal dùng icon đóng "X") KHÔNG bị thay đổi bởi tính năng này.
- **FR-005**: Sau khi chuẩn hoá app bar, chức năng nghiệp vụ hiện có của 3 màn bị ảnh hưởng (điều hướng vào/ra, trả kết quả chọn lựa) PHẢI hoạt động y hệt như trước khi thay đổi.

## Tiêu chí thành công

- **SC-001**: 100% sub-page không thuộc nhóm "chủ đích ngoại lệ" (bảo mật, modal) dùng chung 1 kiểu app bar + nút back nhất quán.
- **SC-002**: Không còn màn nào trong app khiến người dùng phải thoát bằng cách tắt app (không có cách quay lại tường minh).
- **SC-003**: Người dùng test thủ công không phân biệt được sự khác biệt về giao diện/hành vi back giữa các sub-page đã chuẩn hoá và các sub-page vốn đã đúng chuẩn.

## Giả định

- "Mẫu app bar chuẩn của hệ thống" là mẫu app bar teal + nút back đang được đa số sub-page dùng (theo mô tả trong tài liệu rà soát), áp dụng lại cho 3 màn lệch chuẩn.
- Màn kết quả sao lưu/khôi phục sẽ cho phép back về màn trước (không chặn), vì đây không phải màn bảo mật cần khoá luồng.
- Phạm vi giới hạn đúng 4 màn nêu trong tài liệu rà soát (`category_child_list_screen`, `category_picker_screen`, `tag_picker_screen`, `backup_result_screen`); không mở rộng sang các vấn đề khác trong tài liệu (màn Tiện ích, điều hướng pop+callback).

## Ngoài phạm vi

- Vấn đề "màn Tiện ích & Cá nhân hoá lộn xộn" (mục 2 trong tài liệu rà soát).
- Vấn đề "điều hướng gượng gạo" pop+callback ở `budget_detail_screen` (mục 3 trong tài liệu rà soát).
- Thêm route đặt tên (named route) hay chuẩn hoá type annotation cho `MaterialPageRoute`.
