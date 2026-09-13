# Checklist chất lượng đặc tả: Xuất báo cáo (màn 04 Báo cáo)

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-13
**PBI**: 27 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ]
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

## Ghi chú

- **Đã đóng cả 3 điểm cần làm rõ (chốt 2026-09-13)**: Q1 = A (bộ lọc chỉ thuộc màn `04`, không ghi nhớ, không đụng ba màn Báo cáo đã QA) · Q2 = A (cả PDF/Excel/CSV trong một đợt, không chia chặng) · Q3 = A (chỉ có dòng cảnh báo, tệp vẫn chứa số thật, công tắc "Ẩn số dư" giữ nguyên chưa hiệu lực).
- Tự kiểm tra: 25 kịch bản chấp nhận · 28 yêu cầu chức năng · 14 tiêu chí thành công · 23 trường hợp biên — đều kiểm thử được, không nhắc tới công nghệ/thư viện.
- Đã đối chiếu `docs/report/bao-cao-thong-ke-giai-phap.md` §3.7/§4/§6/§7/§8/§9 và mockup `man-hinh-04-xuat-bao-cao.svg`; các ngoại lệ so với doc (§2.2 bảng tổng hợp, §2.2 tỷ giá, §3.8 bộ lọc xuyên suốt) ghi rõ trong "Giả định"/"Ngoài phạm vi"/"Quyết định đã chốt".
- Sai khác **cố ý** so với mockup `04`: **dòng cảnh báo** về việc tệp ra khỏi app không còn được bảo vệ (FR-028 / SC-001).
