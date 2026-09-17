# Quickstart kiểm thử: PBI 47 — Nhật ký trích xuất AI

Chạy từ `app/sora_thu_chi/`: `flutter pub get && flutter test` trước khi thao tác tay.

## Kịch bản 1 — Ghi log khi lưu thành công + sửa trường

1. Mở app → FAB thêm giao dịch → "Quét hóa đơn (AI)" → chọn/chụp ảnh hóa đơn.
2. Ở màn xác nhận (`ScanConfirmScreen`), sửa số tiền AI đề xuất, đổi danh mục, bấm Lưu.
3. Vào Cài đặt → Tiện ích → "Nhật ký trích xuất AI" → bản ghi mới nhất xuất hiện đầu danh sách.
4. Mở chi tiết bản ghi: thấy ảnh gốc, OCR text, giá trị AI đề xuất ban đầu, giá trị cuối đã lưu, và 2 sự kiện `edit` (số tiền, danh mục) đúng thứ tự + 1 sự kiện `save`.

## Kịch bản 2 — Hủy giữa chừng

1. Lặp bước 1-2 ở trên nhưng bấm nút back (hệ thống hoặc app bar) thay vì Lưu.
2. Vào màn Nhật ký → bản ghi mới có `outcome = cancelled`, vẫn có ảnh + OCR text, không có `finalValuesJson`.

## Kịch bản 3 — Trích xuất lỗi

1. Tắt/giả lập lỗi engine (hoặc dùng thiết bị không đạt cấu hình Tier A/B, chỉ còn bộ luật lỗi) — nếu khó tái hiện tay, kiểm bằng unit test mock `ReceiptExtractor` ném exception.
2. Bản ghi log có `outcome = error`, `errorMessage` khác null, `extractionJson` có thể null.

## Kịch bản 4 — Trần FIFO

1. Unit test: insert > `kMaxScanLogs` (200) bản ghi qua store, assert số dòng còn lại = 200, dòng cũ nhất bị xoá, file ảnh tương ứng dòng bị xoá không còn tồn tại trên đĩa (dùng thư mục test tạm).

## Kịch bản 5 — Xuất file

1. Ở màn Nhật ký, bấm "Xuất file" → bảng chia sẻ hệ thống mở ra với 1 file `.json` đính kèm.
2. Mở file (qua "Lưu vào Files"/tương đương) → xác nhận là mảng JSON hợp lệ chứa đủ bản ghi hiện có, mỗi bản ghi có đủ field theo `data-model.md`.

## Kịch bản 6 — Nhật ký rỗng

1. Trên máy/app mới (chưa quét lần nào) → mở màn Nhật ký → hiển thị trạng thái rỗng, nút "Xuất file" bị ẩn/vô hiệu.
