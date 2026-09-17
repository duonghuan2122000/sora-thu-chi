# Nghiên cứu kỹ thuật: Sửa giao dịch (PBI 39)

## R1. Cập nhật số dư ví khi sửa giao dịch Thu/Chi

**Quyết định**: Thêm `WalletRepository.updateTransaction` — trong một `db.transaction()`: hoàn tác tác động số dư của giao dịch **gốc** (trừ đi `original.amount` đã có dấu khỏi ví gốc), rồi áp tác động mới (`amount` có dấu theo `type` mới) vào ví đích (có thể là ví khác nếu người dùng đổi ví), sau đó ghi đè toàn bộ cột nghiệp vụ của đúng dòng `id == transactionId`.

**Lý do**: Số dư ví là đại lượng suy ra (nguyên tắc xuyên module) — không có bảng snapshot riêng, nên sửa giao dịch bắt buộc phải "hoàn tác rồi áp lại" thay vì tính delta, để đúng cả khi người dùng đổi ví lẫn đổi loại (thu ⇄ chi) cùng lúc. Bám đúng mẫu atomic một `db.transaction()` đã dùng ở `addTransaction`/`performTransfer`/`reorderCategories`.

**Phương án khác đã xem xét**: Tính delta trực tiếp trên ví hiện tại (`newAmount - oldAmount`) — chỉ đúng khi ví không đổi; đổi ví thì phải tách 2 thao tác trừ/cộng trên 2 ví khác nhau, tương đương độ phức tạp nhưng dễ sai (quên trường hợp ví không đổi trùng lặp cộng/trừ). Hoàn tác-rồi-áp-lại đơn giản hơn và đúng cho mọi trường hợp, kể cả ví không đổi (trừ rồi cộng lại cùng một ví).

## R2. Cập nhật giao dịch Chuyển khoản (2 vế liên kết)

**Quyết định**: Thêm `WalletRepository.updateTransfer` — nhận `transferGroupId` (= id của dòng vế nguồn, theo đúng quy ước ghi ở `performTransfer`), hoàn tác số dư 2 ví theo vế nguồn/đích **cũ**, áp lại theo `fromWalletId`/`toWalletId`/`amount` **mới**, rồi ghi đè 2 dòng `transactions` hiện có (không xóa/insert lại) — giữ nguyên `id` và `transfer_group_id` của cả 2 vế.

**Lý do**: Giữ nguyên 2 dòng thay vì xóa+tạo mới để không phát sinh id mới (an toàn cho các tham chiếu khác nếu có sau này) và để logic đối xứng với `updateTransaction` (hoàn tác-rồi-áp-lại). Việc 2 ví nguồn/đích mới có thể trùng một phần với ví cũ (ví dụ chỉ đổi ví đích, giữ ví nguồn) xử lý được tự nhiên vì đọc số dư ví ngay trước khi ghi trong cùng transaction.

**Phương án khác đã xem xét**: Xóa 2 dòng cũ rồi gọi lại `performTransfer` — đơn giản hơn về code nhưng đổi `id`/`transfer_group_id` của giao dịch, có thể gây lệch nếu về sau có bảng khác tham chiếu `transaction_id` (ví dụ mẫu `scan_sessions`); không chọn vì rủi ro không cần thiết.

## R3. Tái sử dụng màn hình hiện có thay vì tạo màn "Sửa giao dịch" riêng

**Quyết định**: Không tạo màn mới. Mở rộng `AddTransactionScreen` (Thu/Chi) và `WalletTransferScreen` (Chuyển khoản) với tham số tùy chọn ở chế độ sửa (dữ liệu điền sẵn + gọi `update...` thay vì `add.../perform...` khi lưu). Nút "Sửa" ở `TransactionDetailScreen` tự chọn màn đích theo loại giao dịch — đúng cách màn Thêm giao dịch hiện đang tự chuyển sang `WalletTransferScreen` khi chọn tab "Chuyển khoản".

**Lý do**: Bám đúng mô tả nghiệp vụ gốc ("Sửa: mở lại đúng màn Thêm giao dịch với dữ liệu điền sẵn") và tránh trùng lặp toàn bộ UI/validation đã có (ladder bậc 2 — tái dùng thay vì viết mới).

## R4. Phạm vi đổi loại giao dịch khi sửa

**Quyết định**: Khi sửa một giao dịch Thu/Chi, người dùng đổi qua lại được giữa Thu ⇄ Chi (cùng ở `AddTransactionScreen`), nhưng **không** đổi sang/từ Chuyển khoản trong lúc sửa — segmented tab ẩn/khóa lựa chọn "Chuyển khoản" khi đang ở chế độ sửa. Sửa một giao dịch Chuyển khoản mở thẳng `WalletTransferScreen` ở chế độ sửa, không đi qua `AddTransactionScreen`.

**Lý do**: spec.md chỉ yêu cầu kiểm thử đổi loại trong phạm vi Thu ⇄ Chi (kịch bản chấp nhận #3) và sửa nội bộ trong nhóm Chuyển khoản (kịch bản #4) — không có kịch bản đổi giữa hai *nhóm lưu trữ* khác nhau (1 dòng ↔ 2 dòng liên kết). Cho phép đổi nhóm sẽ kéo theo phải xóa/tạo lại bản ghi khác cấu trúc, tăng độ phức tạp đáng kể cho một luồng nghiệp vụ hiếm gặp và không được yêu cầu — YAGNI.

**Phương án khác đã xem xét**: Cho đổi tự do giữa cả 3 loại (kể cả sang/từ Chuyển khoản) bằng cách xóa bản ghi cũ (hoàn tác số dư) + tạo bản ghi mới đúng cấu trúc loại đích. Khả thi nhưng vượt phạm vi spec đã chốt; để dành nếu có yêu cầu thực tế sau.

## R5. So sánh "đã đổi gì chưa" (dirty check) ở chế độ sửa

**Quyết định**: Mở rộng hàm thuần `isDirty` (đã có trong `add_form.dart`) để nhận thêm baseline tùy chọn (`initialAmount`, `initialCategory`, `initialNote`, `initialDate`, `initialType`, `initialHasTags`, `initialHasReceiptImage`) — mặc định giữ nguyên baseline "form trống" hiện tại (không đổi hành vi màn Thêm). Ở chế độ sửa, `AddTransactionScreen`/`WalletTransferScreen` truyền baseline = dữ liệu gốc đã nạp.

**Lý do**: Tái dùng một hàm thuần đã có test thay vì viết hàm song song — bậc 2 của ladder. Giữ tương thích ngược cho màn Thêm giao dịch hiện tại.
