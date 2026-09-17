# Kế hoạch triển khai: Nhân bản giao dịch

**Mã PBI**: 40
**Liên kết spec**: .specify/specs/40/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter |
| Framework / Thư viện chính | GetX (state/navigation), drift (local DB) — không thêm dependency mới |
| Lưu trữ dữ liệu | drift, schema hiện tại (v10) — không cần migration, không thêm bảng/trường |
| Kiểm thử | `flutter_test` — mở rộng `transaction_detail_screen_test.dart`, `add_transaction_screen_test.dart`, `wallet_transfer_screen_test.dart` |
| Nền tảng triển khai | Android/iOS (app/sora_thu_chi) |
| Ràng buộc hiệu năng | Không phát sinh — thao tác đọc 1 bản ghi + mở màn có sẵn |
| Ràng buộc khác | Tái dùng tối đa pattern PBI 39 (sửa giao dịch) để giảm rủi ro hồi quy |

*Không còn mục `NEEDS CLARIFICATION` — spec.md đã đủ rõ, khảo sát code xác nhận đủ điểm neo triển khai.*

## Kiểm tra theo hiến pháp dự án

Không tìm thấy `.specify/memory/constitution.md` trong repo — bỏ qua bước này.

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt 4 quyết định chính:

- **Quyết định 1**: Thêm 4 tham số optional (`initialNote`, `initialDate`, `initialTags`, `initialReceiptImage`) vào `AddTransactionScreen`, dùng khi `editing == null`. Cờ `editing != null` vẫn là điều kiện DUY NHẤT quyết định `addTransaction` vs `updateTransaction`. **Lý do**: tối thiểu hóa thay đổi, nhất quán với `initialCategory`/`initialWallet` sẵn có. **Phương án khác**: constructor `.duplicate()` riêng — loại vì thừa API.
- **Quyết định 2**: `WalletTransferScreen` không cần sửa — cờ `editingTransferGroupId` đã tách biệt sẵn khỏi các tham số `initial*`. **Lý do**: cấu trúc hiện có khớp thẳng nhu cầu. **Phương án khác**: không có.
- **Quyết định 3**: Thêm `_duplicate(view)` trong `transaction_detail_screen.dart`, bám cấu trúc `_edit(view)` nhưng không truyền cờ update, ép `date = DateTime.now()`. **Lý do**: tái dùng pattern đã kiểm chứng PBI 39. **Phương án khác**: viết luồng tải dữ liệu riêng — loại vì trùng lặp.
- **Quyết định 4**: FR-007 (không gắn chuỗi định kỳ) không cần xử lý riêng — model `Transaction` hiện không có trường liên kết định kỳ.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — không thêm bảng/trường/migration, chỉ liệt kê trường được/không được sao chép.
- **Hợp đồng giao diện**: không áp dụng — app offline, không API/CLI công khai; bỏ qua `contracts/`.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — 4 kịch bản tay (Chi, sửa-trước-khi-lưu, hủy giữa chừng, Chuyển khoản) + lệnh test tự động.

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├─ lib/screens/
│  ├─ transaction_detail_screen.dart   # sửa: thêm _duplicate(view), gán onPressed nút "Nhân bản"
│  └─ add_transaction_screen.dart      # sửa: thêm 4 tham số optional initialNote/initialDate/initialTags/initialReceiptImage
│                                        # (wallet_transfer_screen.dart — không đổi, tái dùng nguyên vẹn)
└─ test/
   ├─ transaction_detail_screen_test.dart   # thêm case: bấm "Nhân bản" → điều hướng đúng màn + đúng dữ liệu điền sẵn (kể cả transfer)
   ├─ add_transaction_screen_test.dart      # thêm case: truyền initial* mà KHÔNG truyền editing → lưu bằng addTransaction (bản ghi mới), không update
   └─ wallet_transfer_screen_test.dart      # thêm case (nếu chưa có coverage tương đương): initial* không kèm editingTransferGroupId → tạo transfer mới
```

## Rủi ro & ngoại lệ có lý do

- Không có ngoại lệ vi phạm nguyên tắc dự án nào cần biện minh.
- Rủi ro nhỏ: nếu `_duplicate` quên loại bỏ `editing`/`editingTransferGroupId` khi copy từ `_edit`, sẽ vô tình rơi vào nhánh update và ghi đè giao dịch gốc — cần test tự động phủ rõ case này (đã đưa vào `add_transaction_screen_test.dart`/`wallet_transfer_screen_test.dart` ở trên) để chặn hồi quy.
