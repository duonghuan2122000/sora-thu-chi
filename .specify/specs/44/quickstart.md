# Quickstart QA thủ công: PBI 44 — Nút back thiếu/không nhất quán

Chạy `flutter run` (emulator/thiết bị), test tuần tự:

1. **Danh mục con**: Danh mục → chạm 1 danh mục cha có con → màn "Danh mục con" hiện app bar teal, tiêu đề 2 dòng (tên cha + "Danh mục con") vẫn chạm mở form sửa cha, nút "+" vẫn thêm con, back mũi tên trái quay về màn Danh mục.
2. **Chọn danh mục**: Thêm giao dịch → chạm ô Danh mục → màn "Chọn danh mục" hiện app bar teal chuẩn (không còn app bar trần), chọn 1 danh mục vẫn trả kết quả đúng về màn Thêm giao dịch.
3. **Chọn Tag**: Thêm giao dịch → chạm ô Tag → màn "Chọn Tag" hiện app bar teal chuẩn, nút "Xác nhận" đáy màn vẫn hoạt động, back mũi tên trái quay về không mất lựa chọn cũ khi mở lại.
4. **Kết quả sao lưu**: Cài đặt → Sao lưu → tạo bản sao lưu → màn kết quả có nút back nhìn thấy được góc trên-trái, chạm vào quay lại đúng màn Sao lưu (không nhảy thẳng về Tổng quan); nút "Xong" vẫn giữ hành vi cũ (về Tổng quan/route gốc).
5. **Khôi phục**: Cài đặt → Sao lưu → khôi phục từ file → màn kết quả tương tự bước 4, nút back hoạt động, nút "Về Tổng quan" giữ hành vi cũ.
6. **Không đổi (kiểm tra hồi quy)**: màn khoá PIN, thiết lập PIN, quét hoá đơn, Thêm giao dịch (icon "X") — hành vi/app bar giữ nguyên như trước, không xuất hiện nút back mũi tên mới.
7. `flutter analyze` sạch, `flutter test` toàn bộ pass (không có test nào đỏ do thay đổi này — trừ 1 test đỏ có sẵn từ trước nếu còn tồn tại, không liên quan PBI 44).
