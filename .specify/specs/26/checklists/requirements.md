# Checklist chất lượng đặc tả: So sánh kỳ (màn 03 Báo cáo)

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-13
**PBI**: 26 — [Liên kết tới spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 3 điểm đã chốt ngày 2026-09-13, ghi vào mục "Quyết định đã chốt"
- [x] Các yêu cầu rõ ràng, kiểm thử được
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ
- [x] Đầy đủ kịch bản chấp nhận (acceptance scenarios)
- [x] Đã xác định các trường hợp biên (edge cases)
- [x] Phạm vi rõ ràng
- [x] Đã ghi nhận giả định và phụ thuộc

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra

- Lần 1 (2026-09-13): tất cả mục đạt, **trừ** mục "Không còn điểm [CẦN LÀM RÕ]" — 3 điểm mở thuộc nhóm **phạm vi** (lối vào, thẻ xu hướng) và **trải nghiệm** (cách đổi kỳ đối chiếu), đã trình bày cho người dùng kèm phương án.
- Lần 2 (2026-09-13): người dùng chốt cả 3 điểm theo phương án đề xuất — lối vào là biểu tượng trên vùng tiêu đề; thẻ xu hướng nằm trong đợt này; chip kỳ đối chiếu bấm được để luân chuyển "kỳ liền trước" ⇄ "cùng kỳ năm trước". Đã cập nhật FR-001/FR-003/FR-005/FR-006, kịch bản chấp nhận (thêm KB-21), SC-001/SC-016, Thực thể, Giả định và thêm mục "Quyết định đã chốt"; xoá mục "Điểm cần làm rõ". **Tất cả mục đạt.**
- Đã rà lại: spec không nêu tên package/thư viện/thành phần kỹ thuật nào (thẻ số liệu, biểu đồ đường, cặp chip đều mô tả ở mức giao diện).
- Đã đối chiếu mockup `03`: đủ 5 khối (2 chip + nút hoán đổi, thẻ Thu nhập, thẻ Chi tiêu, thẻ xu hướng, thẻ Nhận xét); một khác biệt cố ý — chip kỳ đối chiếu bấm được nên có thêm chỉ báo thị giác.
- Đã đối chiếu doc nghiệp vụ §3.3 (§so sánh kỳ), §8 (edge case kỳ đầu tiên dùng app), §2.2 (loại transfer, đa tiền tệ), §4 (luồng vào màn).
- Đã rà tính nhất quán sau khi chốt: thuật ngữ **kỳ chính = bên trái / kỳ đối chiếu = bên phải** dùng thống nhất ở Luồng chính, KB-1..4, KB-21, FR-003..FR-006, mục Thực thể; quy tắc hoán đổi ("chỉ đổi chỗ, không tính lại kỳ đối chiếu") khớp giữa FR-006, SC-007 và "Quyết định đã chốt".
