# Checklist chất lượng đặc tả: Thêm giao dịch bằng quét hóa đơn (AI)

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-12
**PBI**: 24 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API) — spec chỉ nói "đọc chữ ngay trên thiết bị", "mô hình chạy trên máy", "từ điển cửa hàng → danh mục"; tên thư viện/plugin để dành cho plan.md (doc nghiệp vụ §8)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ (giảm thao tác nhập tay, không rời dữ liệu khỏi máy)
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc (mô tả, kịch bản, FR, SC, thực thể, giả định, ngoài phạm vi, quyết định đã chốt)

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 3 điểm phạm vi lớn (engine, nguồn, cài đặt) đã hỏi và chốt trước khi viết spec
- [x] Các yêu cầu rõ ràng, kiểm thử được (41 FR, mỗi FR nêu hành vi quan sát được)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (6 lần chạm, ≥ 90% đúng số tiền/ngày, < 3s / < 10s, 0 giao dịch tự tạo, 0 nhãn tiếng Việt sót khi ở English)
- [x] Đầy đủ kịch bản chấp nhận (27 kịch bản, bao phủ 3 luồng phụ: máy yếu, phải tải model, không đọc được nội dung)
- [x] Đã xác định các trường hợp biên (22 trường hợp: ảnh mờ, nhiều con số, ngày không có, mất quyền camera, thiếu dung lượng, ví mặc định không hợp lệ, bấm lưu 2 lần, app bị đóng giữa chừng…)
- [x] Phạm vi rõ ràng (chỉ hóa đơn giấy; mục "Ngoài phạm vi" liệt kê 12 nhóm bị loại kèm căn cứ doc §7/§10)
- [x] Đã ghi nhận giả định và phụ thuộc (16 giả định, gồm cả các chốt phạm vi 2026-09-12)

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng (FR ↔ kịch bản/SC ánh xạ 1–1 hoặc theo nhóm)
- [x] Kịch bản người dùng bao phủ luồng chính (chụp → xử lý → xác nhận → lưu, cùng các nhánh lỗi/thoát)
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú kiểm tra

- Mockup `scan-02` có nút "Quét nhiều" nhưng đợt này không hiển thị (quét hàng loạt = GĐ2 theo doc §7) — đã ghi thành khác biệt đã chốt ở FR-016/SC-001 để khi QA đối chiếu mockup không báo nhầm là thiếu.
- Doc nghiệp vụ §3.1 nêu 3 lối vào; đợt này chỉ làm lối FAB → bottom sheet (mockup `scan-01`) vì 2 lối còn lại chưa có UI trong app — đã ghi ở "Giả định" và "Ngoài phạm vi".
- Doc §10.5 thêm trường `source_type` cho phiên quét: đợt này chỉ có 1 nguồn nên chưa thêm trường — đã ghi ở "Giả định"/"Ngoài phạm vi" để plan.md không tự thêm.
