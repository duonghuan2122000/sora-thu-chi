# Kế hoạch triển khai: Sửa giao dịch

**Mã PBI**: 39
**Liên kết spec**: .specify/specs/39/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

- Ngôn ngữ / Runtime: Dart / Flutter (app hiện có tại `app/sora_thu_chi`).
- Framework / Thư viện chính: Flutter Material, GetX (chỉ dùng i18n `.tr`, không dùng cho state màn này — bám R11 PBI 38), `drift` (local DB), `image_picker` (đã có, tái dùng seam `ReceiptImagePicker`).
- Lưu trữ dữ liệu: SQLite qua `drift`, bảng `transactions`/`wallets` hiện có — **không đổi schema** (giữ v10), chỉ thêm 2 method ghi (`UPDATE`) trên `WalletRepository`.
- Kiểm thử: `flutter test` — unit cho hàm thuần (`add_form.dart` mở rộng `isDirty`), test cho 2 method mới trên `FakeWalletRepository` + `DriftWalletRepository`, widget test cho `AddTransactionScreen`/`WalletTransferScreen` ở chế độ sửa, nối `TransactionDetailScreen`.
- Nền tảng triển khai: Android/iOS hiện có, không đổi.
- Ràng buộc hiệu năng: thao tác cục bộ tức thời, không có ràng buộc riêng.
- Ràng buộc khác: giữ nguyên seam test hiện có (`WalletRepository` interface + `FakeWalletRepository`), không thêm dependency mới, không đổi cấu trúc bảng.

## Kiểm tra theo hiến pháp dự án

Không có `.specify/memory/constitution.md` trong repo — bỏ qua bước đối chiếu chính thức. Đối chiếu theo quy ước đã chốt trong `CLAUDE.md`/`wiki-knowledge/`:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | `updateTransaction`/`updateTransfer` chỉ sửa qua hoàn tác-rồi-áp-lại đúng công thức cũ (R1/R2). |
| Chuyển khoản nội bộ không tính thu/chi | ✅ | Không đổi cách tính; `updateTransfer` chỉ sửa 2 dòng `type=transfer` sẵn có. |
| Không đổi schema khi không cần | ✅ | Không thêm/đổi cột hay bảng nào. |
| Tái dùng seam/màn hình sẵn có thay vì tạo mới | ✅ | Mở rộng `AddTransactionScreen`/`WalletTransferScreen` thay vì màn "Sửa giao dịch" riêng (R3). |
| Tiếng Việt có dấu cho UI/doc/commit | ✅ | Toàn bộ nhãn/tiêu đề mới đều tiếng Việt. |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`: cơ chế cập nhật số dư khi sửa Thu/Chi (R1) và Chuyển khoản (R2), quyết định tái dùng màn hình có sẵn (R3), giới hạn phạm vi đổi loại khi sửa — chỉ Thu ⇄ Chi, không đổi nhóm sang/từ Chuyển khoản (R4), mở rộng `isDirty` nhận baseline tùy chọn cho chế độ sửa (R5).

## Giai đoạn 1 — Thiết kế

- Mô hình dữ liệu: xem `data-model.md` — 2 method mới `updateTransaction`/`updateTransfer` trên `WalletRepository`, tham số tùy chọn chế độ sửa ở `AddTransactionScreen`/`WalletTransferScreen`.
- Hợp đồng giao diện: không áp dụng — app offline, không có API/CLI công khai ra ngoài.
- Kịch bản khởi động nhanh: xem `quickstart.md` — 7 nhóm kiểm thử tay (A–G) bao phủ sửa Thu/Chi, đổi ví, đổi loại, hủy, validate, sửa Chuyển khoản, và giới hạn không đổi nhóm loại khi sửa.

## Cấu trúc dự án dự kiến

Toàn bộ trong `app/sora_thu_chi/`:

```
lib/
  data/
    wallet_repository.dart          # + updateTransaction, updateTransfer (khai báo interface)
    wallet_repository_drift.dart    # + impl 2 method trên (atomic db.transaction())
  core/
    transaction/
      add_form.dart                 # isDirty nhận thêm baseline tùy chọn (R5)
    wallet/
      wallet_controller.dart        # + updateTransfer (wrap repository, mirror transfer())
  screens/
    add_transaction_screen.dart     # + chế độ sửa: editing/initialCategory/initialWallet,
                                     #   tiêu đề "Sửa giao dịch", khóa tab Chuyển khoản, gọi
                                     #   updateTransaction khi lưu
    wallet_transfer_screen.dart     # + chế độ sửa: editingTransferGroupId/destinationWallet/
                                     #   initialAmount/initialDate/initialNote, gọi
                                     #   updateTransfer khi xác nhận
    transaction_detail_screen.dart  # nút "Sửa" tải lại dữ liệu gốc rồi điều hướng đúng màn

test/
  fakes/fake_wallet_repository.dart          # + updateTransaction, updateTransfer
  data/wallet_repository_drift_test.dart     # (hoặc file tương ứng) + case cho 2 method mới
  core/transaction/add_form_test.dart        # + case isDirty với baseline khác mặc định
  screens/add_transaction_screen_test.dart   # + case chế độ sửa (điền sẵn, lưu gọi update, khóa tab transfer)
  screens/wallet_transfer_screen_test.dart   # + case chế độ sửa
  screens/transaction_detail_screen_test.dart# + case chạm "Sửa" điều hướng đúng màn theo loại
```

Không có file/thư mục mới ngoài test tương ứng — bám đúng vị trí các PBI trước (PBI 10/11/38).

## Rủi ro & ngoại lệ có lý do

- **Giới hạn phạm vi đổi loại khi sửa** (R4): không cho đổi giữa nhóm Thu/Chi và nhóm Chuyển khoản trong lúc sửa (segmented tab khóa mục "Chuyển khoản" ở chế độ sửa). Lý do: spec.md chỉ yêu cầu kiểm thử Thu ⇄ Chi và sửa nội bộ Chuyển khoản, không có kịch bản đổi nhóm lưu trữ (1 dòng ↔ 2 dòng liên kết) — thêm hỗ trợ này sẽ tăng độ phức tạp repository đáng kể (phải xóa+tạo lại bản ghi khác cấu trúc) cho một nhu cầu không được yêu cầu. Nâng cấp sau nếu có yêu cầu thực tế.
- **Không hỗ trợ Undo sau khi sửa** — đúng như "Ngoài phạm vi" của spec.md; nếu người dùng lưu nhầm, phải sửa lại thủ công lần nữa (không mất dữ liệu vì repository vẫn ghi đúng lịch sử `date`, chỉ không có nút hoàn tác nhanh).
- **`updateTransfer` không có tham số tags/receiptImage** — giao dịch Chuyển khoản hiện tại (kể cả lúc tạo mới) không có 2 trường này ở `WalletTransferScreen`, giữ nguyên nhất quán, không mở rộng ngoài yêu cầu.
