# Quickstart: PBI 41 — Thông báo đường dẫn file xuất báo cáo

Kịch bản kiểm thử tích hợp nhanh, chạy trên emulator/thiết bị Android thật sau khi thi công.

## Chuẩn bị

1. `flutter pub get` (đã thêm `permission_handler` vào `pubspec.yaml`).
2. Cài lại app (gỡ cài đặt cũ trước `flutter run`) — thêm kênh native mới (`ReportDownloadsChannel`) + plugin `permission_handler`, hot reload/restart không nạp được (bẫy đã gặp ở PBI 27 với `share_plus`).
3. Có ít nhất vài giao dịch mẫu để bộ lọc xuất báo cáo không rỗng.

## Kịch bản A — Xuất PDF lần đầu

1. Mở app → Báo cáo → icon Xuất báo cáo (màn `04`).
2. Chọn bộ lọc bất kỳ có giao dịch, định dạng PDF.
3. Chạm "Xuất báo cáo".
4. **Kỳ vọng**: SnackBar hiện thông báo chứa tên tệp + có nhắc tới thư mục Tải xuống/Downloads, **trước khi** bảng chia sẻ hệ thống mở ra.
5. Đóng bảng chia sẻ hệ thống mà **không** chọn ứng dụng nào.
6. Mở app Quản lý tệp (Files) của thiết bị → thư mục Downloads → xác nhận thấy đúng tệp PDF vừa xuất, mở được, nội dung khớp bộ lọc.

## Kịch bản B — Xuất trùng tên (chạy lại đúng bộ lọc cũ)

1. Lặp lại đúng bước 2–3 ở Kịch bản A với **cùng** bộ lọc + định dạng (không đổi khoảng ngày/ví/danh mục/tag).
2. **Kỳ vọng**: SnackBar báo tên tệp có hậu tố phân biệt (ví dụ `... (2).pdf`), không ghi đè tệp ở Kịch bản A.
3. Kiểm tra Downloads: cả 2 tệp cùng tồn tại, tệp cũ mở lại vẫn đúng nội dung ban đầu.

## Kịch bản C — Xuất Excel và CSV

1. Lặp Kịch bản A với định dạng Excel, rồi với CSV.
2. **Kỳ vọng**: mỗi định dạng đều có SnackBar path riêng đúng phần mở rộng (`.xlsx`, `.csv`), file mở được bằng ứng dụng tương ứng trên máy.

## Kịch bản D — Lỗi dựng tệp (giữ hành vi cũ)

1. Với seam test hoặc dữ liệu ép lỗi dựng nội dung (theo cách PBI 27 đã test), chạm "Xuất báo cáo".
2. **Kỳ vọng**: SnackBar "Không tạo được tệp báo cáo" như cũ; **không** có thông báo đường dẫn; không có tệp mới xuất hiện trong Downloads.

## Kịch bản E — Từ chối quyền lưu trữ (nếu thiết bị Android cũ yêu cầu quyền)

1. Trên thiết bị/emulator Android 8–9 (hoặc giả lập từ chối quyền), chạm "Xuất báo cáo" lần đầu → hộp thoại xin quyền lưu trữ hiện ra → chọn Từ chối.
2. **Kỳ vọng**: app hiện thông báo lỗi phù hợp (không phải thông báo path), không mở bảng chia sẻ, không có tệp mới trong Downloads.
3. Bỏ qua kịch bản này nếu máy QA chỉ có Android 10+ (không cần xin quyền — ghi chú rõ trong báo cáo QA).

## Kịch bản F — Privacy mode đang bật

1. Bật "Ẩn số dư" trong Cài đặt.
2. Lặp Kịch bản A.
3. **Kỳ vọng**: cảnh báo "Tệp xuất ra không còn được app bảo vệ..." vẫn hiện như cũ trên màn Xuất báo cáo; thêm SnackBar path sau khi xuất — cả hai cùng tồn tại, không cái nào thay thế cái nào.
