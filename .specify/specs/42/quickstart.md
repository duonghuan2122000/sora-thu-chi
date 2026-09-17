# Kịch bản khởi động nhanh: PBI 42 — Đường dẫn file tự động sao lưu

Kiểm thử thủ công trên emulator/máy thật sau khi cài đặt xong.

## Chuẩn bị

1. Cài bản build mới nhất, mở app.
2. Vào Cài đặt → "Sao lưu & Khôi phục".

## Kịch bản A — Bản gần nhất là tự động

1. Bật "Tự động sao lưu" (bất kỳ tần suất nào).
2. Kích hoạt 1 lần chạy tự động (dùng lại cách QA đã dùng ở PBI 35 để trigger `_runAutoBackup`, ví dụ chạy task WorkManager thủ công qua ADB hoặc code test-only, hoặc đợi lịch thật nếu QA trên máy thật).
3. Mở lại màn "Sao lưu & Khôi phục".
4. **Kỳ vọng**: mục "Sao lưu gần nhất" hiện thêm dòng đường dẫn file (ví dụ `.../app_flutter/backups/auto/backup_....json`), cạnh thời điểm và số liệu tóm tắt đã có.
5. Cuộn xuống "CÁC BẢN SAO LƯU" — bản vừa tạo có nhãn "Tự động" kèm dòng đường dẫn hiện dưới tên file.

## Kịch bản B — Bản gần nhất là thủ công

1. Chạm "Tạo bản sao lưu mới" → xác nhận trong bottom sheet → chia sẻ/đóng bảng chia sẻ.
2. Quay lại màn "Sao lưu & Khôi phục".
3. **Kỳ vọng**: mục "Sao lưu gần nhất" hiện đúng thời điểm + số liệu như cũ, **không** có dòng đường dẫn (hành vi giữ nguyên).
4. Trong danh sách "CÁC BẢN SAO LƯU", bản thủ công vừa tạo **không** có dòng đường dẫn; các bản tự động khác (nếu có) vẫn có.

## Kịch bản C — Chưa từng sao lưu

1. Trên máy/app mới (hoặc sau khi xoá hết backup), mở màn "Sao lưu & Khôi phục".
2. **Kỳ vọng**: mục "Sao lưu gần nhất" hiện "Chưa từng sao lưu" như cũ, danh sách "CÁC BẢN SAO LƯU" trống — không có gì thay đổi so với trước PBI này.

## Kịch bản D — Đường dẫn dài

1. Trên thiết bị màn hình nhỏ (hoặc thu nhỏ cửa sổ giả lập), quan sát dòng đường dẫn ở card và trong danh sách.
2. **Kỳ vọng**: đường dẫn bị cắt bằng `...` ở cuối dòng (1 dòng, không tràn/xuống dòng, không phá bố cục card/list item).
