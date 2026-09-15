# Kịch bản khởi động nhanh: PBI 36 — Quét ảnh thông báo giao dịch ngân hàng

Chạy tay trên emulator (Chế độ cơ bản/Tier C — đủ để kiểm hết PBI này, không cần Tier A/B thật). Dùng ảnh chụp màn hình các loại thông báo ngân hàng thật (SMS, app, email) để quét thử qua nút **Thư viện** ở màn chụp.

## Nhóm A — Nhận diện đúng loại ảnh

1. Quét ảnh hóa đơn cửa hàng bình thường (VD Circle K) → vẫn ra kết quả hóa đơn như cũ (loại **Chi**, không có cờ "Kiểm tra lại" ở Loại giao dịch). Không có hồi quy so với PBI 24.
2. Quét ảnh SMS biến động số dư (kiểu "ACB: TK ... + 29,896,000 lúc ... Số dư 38,677,245. GD: ...") → nhận đúng là ảnh ngân hàng, loại **Thu**, số tiền = **29.896.000 đ** (không phải 38.677.245 đ).

## Nhóm B — Ghi nợ/ghi có ⇒ đúng chi/thu

3. Ảnh kiểu "... phát sinh giao dịch số tiền 44.100,00VND (Debit) ... Số dư khả dụng: 12.540.601 VND" → loại **Chi**, số tiền = **44.100 đ**.
4. Ảnh email "Giao dịch mới nhất: Ghi nợ -40.000,00 VND" kèm "Số dư mới ... 30.691.405,00 VND" → loại **Chi**, số tiền = **40.000 đ** (không nhầm số dư).
5. Ảnh "Chuyển tiền thành công! 55.000 VND — Từ: ... Đến: CÔNG TY ..." (không có chữ "ghi nợ/ghi có") → loại **Chi** (mặc định theo R4.3), độ tin cậy trung bình, **không** bị gán "Chuyển khoản" (app vẫn chỉ có Thu/Chi ở màn quét).

## Nhóm C — Ghi chú tự điền

6. Với ảnh mục 4 (nội dung "DUONG BANG HUAN CHUYEN KHOAN-010926-14:23:33 ...") → ô "Cửa hàng / Ghi chú" được điền sẵn nội dung/người liên quan, sửa được, xóa được, không bắt buộc.

## Nhóm D — Không đủ căn cứ ⇒ cần xem lại

7. Dựng 1 ảnh test có đủ ≥ 2 từ khóa ngân hàng nhưng **không** có ghi nợ/ghi có/dấu +-/chuyển tiền rõ ràng → loại vẫn mặc định **Chi**, nhưng hiện dòng "Kiểm tra lại" màu coral dưới ô Loại giao dịch; người dùng đổi được sang Thu bằng segmented control như bình thường.

## Nhóm E — Màn xác nhận không đổi hành vi cũ

8. Với mọi kết quả ở nhóm A–D: màn xác nhận vẫn hiển thị đủ 6 trường sửa được, nút "Lưu giao dịch" hoạt động bình thường, giao dịch được lưu đúng loại/số tiền đã sửa (không phải giá trị gốc nếu người dùng đã đổi) — không có trường hợp tự động lưu mà không qua màn xác nhận (SC-003).
9. Đổi ngôn ngữ sang `en` → không còn nhãn tiếng Việt cứng nào ở dòng "Kiểm tra lại" mới thêm (dùng lại khóa dịch `.tr` sẵn có).

## Nhóm F — Nhánh AI (nếu bật Tier A/B thật trên máy có hỗ trợ)

10. Lặp lại nhóm A–C với AI bật — kết quả `type`/`amount`/ghi chú tương đương hoặc tốt hơn bộ luật; AI lỗi/timeout vẫn rơi về bộ luật đúng như PBI 24 (không hồi quy R7/FR-011).

## Tiêu chí đạt

Toàn bộ nhóm A–E đạt trên emulator là đủ điều kiện coi PBI 36 hoàn thành QA tay (SC-001…SC-004); nhóm F chỉ chạy khi có thiết bị hỗ trợ Tier A/B, không chặn hoàn thành PBI.
