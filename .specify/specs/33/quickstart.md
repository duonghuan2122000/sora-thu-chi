# Quickstart kiểm thử — PBI 33 (Nội dung màn Tổng quan)

Chạy sau khi thi công xong `tasks.md`, từ `app/sora_thu_chi/`:

```bash
flutter pub get
flutter analyze
flutter test
```

## Kịch bản tay trên emulator/thiết bị

1. Mở app (đã qua khóa PIN nếu có) → tab **Tổng quan** phải hiện ngay: tổng số dư, 2 thẻ "Thu tháng này"/"Chi tháng này", tối đa 5 giao dịch gần nhất.
2. Chạm 1 dòng giao dịch gần đây → mở đúng màn chi tiết giao dịch đó; back → quay lại Tổng quan, vị trí không đổi.
3. Chạm "Xem tất cả" → chuyển sang tab Giao dịch (danh sách đầy đủ, không bị lọc riêng).
4. Bấm FAB thêm 1 giao dịch thu hoặc chi mới, lưu thành công → quay lại Tổng quan: số dư/thẻ thu-chi/danh sách gần đây phản ánh giao dịch vừa thêm ngay lập tức (không cần thoát app).
5. Chuyển sang tab Giao dịch/Báo cáo rồi quay lại tab Tổng quan → số liệu vẫn đúng, không cần thao tác làm mới thủ công.
6. Cài đặt lại app (hoặc test trên profile chưa có giao dịch nào): tổng số dư = tổng `initial_balance` các ví đang hoạt động, 2 thẻ hiện `0 đ`, khu vực giao dịch gần đây hiện trạng thái rỗng (không phải danh sách trống trơn).
7. Ẩn hết ví đang hoạt động (Cài đặt → Quản lý ví) → quay lại Tổng quan: tổng số dư hiển thị `0 đ`.
8. Có giao dịch chuyển khoản nội bộ gần đây → dòng "Chuyển khoản" hiện màu trung tính, không dấu `+`/`-`, không tính vào 2 thẻ thu/chi tháng này.
