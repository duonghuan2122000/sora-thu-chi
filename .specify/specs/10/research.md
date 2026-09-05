# Nghiên cứu — PBI 10: Màn hình chi tiết giao dịch

Ngày: 2026-09-05

## Bối cảnh ràng buộc

- App offline (drift SQLite), không thêm dependency; state GetX (nhưng màn detail bám pattern `WalletDetailScreen`: Stateful + seam test — xem R10).
- `transactions` (schema v2, PBI 8) chỉ có subset cột: `id, wallet_id, type, amount, category(text tạm), note, transaction_date, transfer_group_id`. **Chưa** có `tags/receipt_image/location/category_id`; chưa có producer nào tạo 3 trường tùy chọn (màn thêm/sửa giao dịch ở PBI sau).
- Danh mục hiện là **chữ tạm** (cột `category`), chưa có bảng `categories`/phân cấp cha-con (quyết định mở #1 — ghi trong PBI 9 plan).
- Điểm vào: dòng trong danh sách Giao dịch (PBI 9) hiện đang `onTap: () {}` no-op → PBI 10 kích hoạt điều hướng.
- Design system + mockup `docs/transaction/04-chi-tiet-giao-dich.svg` + nhóm Giao dịch §5 màu: thu teal `+`, chi coral `−`, chuyển khoản/điều chỉnh **trung tính không dấu**.

## R1 — Nguồn dữ liệu màn chi tiết: nạp lại mỗi lần mở (không truyền dòng cũ)

**Quyết định**: Màn chi tiết tự nạp lại dữ liệu khi mở: gọi `WalletRepository.allTransactions()` + `loadAll()` (tên ví kể cả ví ẩn — FR-011/edge), rồi **hàm thuần** chọn đúng giao dịch theo `ref` và dựng view-model hiển thị. Không truyền `TxnRow`/object cũ từ danh sách sang.

**Lý do**: FR-010 yêu cầu phản ánh dữ liệu mới nhất sau khi ghi/sửa/xóa ở nơi khác; object của màn danh sách là bản đã gộp/trình bày (mất bút toán gốc của transfer). Đọc lại từ seam duy nhất (`allTransactions` đã có, không cần method repo mới — R9) giữ một nguồn chân lý, deterministic, test bằng fake.

**Phương án khác**: Truyền thẳng object `Transaction`/`TxnRow` sang route → nhanh hơn (không đọc lại DB) nhưng rủi ro hiển thị dữ liệu cũ khi có chỉnh sửa ngoài (vi phạm FR-010), và dòng transfer đã gộp không còn đủ 2 bút toán. Bị bác.

## R2 — Định danh mở detail (ref) & hành vi danh sách

**Quyết định**: Mở rộng `TxnRow` (view-model danh sách, file `transaction_list.dart`) bằng 2 field định danh phụ (additive, chỉ màn danh sách dùng): `int? detailTransactionId` (dòng thường/adjustment/vế lẻ = `t.id`) và `int? detailGroupId` (chỉ dòng **transfer đã gộp** = `transfer_group_id`, khi 2 vế cặp nhau). Đúng một trong hai khác null. Dòng chạm → push `MaterialPageRoute` tới `TransactionDetailScreen(ref)`; màn detail là sub-page (AppBar riêng, không bottom nav) đè lên shell. Quay lại tự trả về vị trí cũ vì màn danh sách nằm dưới route (PageStorageKey của PBI 9 giữ cuộn — SC-008).

**Lý do**: Chỉ danh sách biết mình đang hiển thị gì; ref dạng vô hại, không kéo nghiệp vụ vào view-model. Transfer đã gộp chỉ còn biết nhóm → bắt buộc mang `transfer_group_id` để màn chi tiết tìm đủ 2 vế (FR-006/SC-005). Đọc lại theo ref (R1) đáp ứng FR-010.

**Phương án khác**: (a) Truyền `sortId`/con số may rủi — sai ngữ nghĩa, fragile. (b) Repository thêm `transactionById`/`transferLegs(groupId)` — thêm code không cần thiết vì đã có `allTransactions()` (quy mô local nghìn dòng, SC-001). Bác.

## R3 — Mở rộng schema drift v3 (cột tùy chọn) — QUYẾT ĐỊNH NGƯỜI DÙNG

**Quyết định** (user chốt phương án A): Bump `schemaVersion` 2 → 3, thêm **3 cột text** vào bảng `transactions`: `tags` (text, default `''`), `receipt_image` (text, default `''`), `location` (text, default `''`) — đúng cột đã định trong `docs/wallet/nghiep-vu-vi-tai-khoan.md` §7. Domain `Transaction` thêm `tags`, `receiptImage`, `location` (String, default `''`). Chạy `build_runner` để tái sinh `app_database.g.dart`. Migration `onUpgrade(from<3)` dùng `m.addColumn`. Seed làm giàu **một** dòng mẫu khớp mockup (row 1: chi 85.000 Tiền mặt) bằng `tags` + `location` (text) để QA thấy hàng Tag chip + Vị trí; `receipt_image` **để trống** (chưa có producer/ảnh thật) → dòng Ảnh hóa đơn chỉ verify bằng widget test. `category` vẫn là chữ tạm — không thêm `category_id`.

**Lý do**: Spec FR-007/acceptance 1/SC-002 yêu cầu hiển thị Tag/Ảnh hóa đơn/Vị trí khi dữ liệu có; không cột thì trường không bao giờ tồn tại → không thể đạt. Ba cột này đã nằm trong mô hình chuẩn của docs → đây là triển khai đúng thiết kế, không phải scope creep. Migration có default `''` nên không vỡ dữ liệu cũ. Bỏ `receipt_image` trống vì (i) chưa có luồng chụp/chọn ảnh nào, (ii) không muốn nhét asset demo + cơ chế render file-vs-asset chỉ để QA (ponytail).

**Phương án khác**: (b) Không đổi schema — ít đụng nhưng Tag/Ảnh/Vị trí vĩnh viễn ẩn, acceptance không QA được (bị bác). (c) v3 + seed ảnh demo asset — đụng pubspec + asset + scheme render file-vs-asset, thêm phức tạp không cần thiết cho đợt chỉ-hiển-thị (bị bác).

## R4 — Định dạng lưu `tags` & phân tích hiển thị

**Quyết định**: Lưu `tags` dạng chuỗi text, các tag phân tách bằng dấu phẩy `,`, **không** lưu ký tự `#` (VD `'côngty,ăntrưa'`). Hiển thị thêm tiền tố `#` (VD chip `#côngty`, `#ăntrưa`). Hàm thuần `parseTags(String)` → `List<String>` (split `,`, trim, bỏ rỗng) đặt trong module detail; rỗng → `[]` → ẩn hàng Tag (FR-007). Mỗi tag là một chip pill: nền `softCardBg`, chữ `teal`, bo tròn, đủ nhiều chip không cắt (edge "nhiều tag").

**Lý do**: Text thuần đơn giản, dễ seed, không thêm dependency/thư viện tag; dấu `#` là quy ước hiển thị nên thêm ở tầng UI, không lưu vào dữ liệu.

**Phương án khác**: Lưu JSON array / ký tự phân tách khác → thêm parse phức tạp, không cần; mockup minh họa chuỗi `#côngty` nhưng không quy định lưu.

## R5 — Màu/dấu/khối tóm tắt & nhãn danh mục

**Quyết định**: Khối tóm tắt & tô màu bám đúng PBI 9 + mockup 04:
- **Thu**: bubble nền `tealLightBg` + glyph `categoryGlyph`, nhãn = `category` (rỗng → `typeLabel`), số tiền **lớn** (24px/600) màu `teal`, dấu `+` (`formatSignedMoney`).
- **Chi**: cùng cấu trúc bubble, số tiền màu `coral`, dấu `−`.
- **Chuyển khoản / Điều chỉnh số dư**: bubble nền `softCardBg` trung tính, glyph `swap_horiz` / `tune` màu `listLabel`; nhãn = `typeLabel` (không tên danh mục — FR-004); số tiền `formatMoney(abs)` **không dấu**, màu `textPrimary`; tuyệt đối không dùng teal/coral (FR-004).
- Nhãn danh mục ở tóm tắt hiển thị **đúng chuỗi `category` lưu** trong dữ liệu: seed hiện là tên cha (`'Ăn uống'`); khi module Danh mục (PBI sau) lưu/join chuỗi đường dẫn `'Ăn uống · Ăn ngoài'` thì màn tự hiển thị đúng **không cần đổi logic** — đúng chốt "cha · con" của spec (acceptance 5). Hiện chưa có categories table/producer nên acceptance-5 được verify bằng **dữ liệu ghép** trong unit/widget test (Transaction có `category: 'Ăn uống · Ăn ngoài'`), không phải data thật — ghi ngoại lệ ở plan.

**Lý do**: Thống nhất một quy ước màu/dấu xuyên danh sách (PBI 9) và chi tiết; tránh 2 bộ luật màu song song. Không dựng tạm hệ phân cấp danh mục vì thuộc module Danh mục (quyết định mở #1).

## R6 — Khung màn (SubPageScaffold) & các điểm vào no-op

**Quyết định**: Màn chi tiết dùng `SubPageScaffold` — AppBar teal tự có back + title "Chi tiết giao dịch". Mở rộng `SubPageScaffold` thêm tham số tuỳ chọn `actions` (List<Widget>?, default null) để đặt **icon 3 chấm** bên phải (FR-001/FR-012). Hai nút dưới cùng qua `bottomNavigationBar`: `SafeArea(Row(…))` — **"Nhân bản"** (OutlinedButton, viền `divider`/`#E0E0E0`) và **"Sửa"** (FilledButton teal bo 8 cao 44), nằm cạnh nhau đúng mockup. Cả 3 điểm vào (3 chấm, Nhân bản, Sửa) **no-op không lỗi/treo** vì màn thêm/sửa giao dịch ở PBI sau (FR-012) — `onPressed: () {}`/InkWell rỗng, không pop.

**Lý do**: `SubPageScaffold` là khung sub-page dùng chung (wallet detail đang dùng); thêm param additive, không phá màn cũ. Design "Sửa = nút chính, Nhân bản = nút phụ" bám mockup.

## R7 — Cấu trúc vùng chi tiết & hàng có điều kiện

**Quyết định**: Vùng chi tiết là danh sách hàng, mỗi hàng = icon dẫn đầu teal (nhỏ) + cột (nhãn nhỏ `listLabel`, giá trị `textPrimary`), ngăn cách bằng đường kẻ `listDivider`; cuộn khi tràn (FR-008). Hàng hiển thị **có điều kiện** (FR-007, edge "không có thì ẩn, không dòng trống/thừa phân cách"):
- **Ví**: luôn hiện — income/expense/adjustment 1 hàng "Ví"; transfer **2 hàng** "Ví nguồn" / "Ví đích" (FR-006/SC-005).
- **Ngày giờ**: luôn hiện, định dạng mới `'dd/MM/yyyy · HH:mm'` (R8).
- **Ghi chú**: khi `note` không rỗng; gói dòng, không cắt (edge "ghi chú dài").
- **Tag**: khi `parseTags` không rỗng — dãy chip (R4).
- **Ảnh hóa đơn**: khi `receiptImage` không rỗng — thumbnail 56×56 bo 8, dùng `Image.file`, `errorBuilder` → hộp placeholder icon (không crash khi file thiếu/đường dẫn lỗi).
- **Vị trí**: khi `location` không rỗng — text, gói dòng.

**Lý do**: Đúng mockup (mỗi hàng nhãn + giá trị, đường kẻ mảnh) và nhất quán cách PBI 9 ẩn dòng phụ thừa. Icon dẫn đầu theo từng loại field (Ví → `account_balance_wallet_outlined`, Ngày giờ → `schedule`, Ghi chú → `notes`, Ảnh → `image_outlined`, Vị trí → `location_on_outlined`, Tag dùng chip không cần icon dẫn riêng — mockup bỏ icon cho hàng Tag).

## R8 — Định dạng ngày giờ "·"

**Quyết định**: Thêm hàm thuần `formatDateTimeDetailLabel(DateTime)` vào `core/date_label.dart` trả `'dd/MM/yyyy · HH:mm'` (mỗi số 2 chữ số, dấu `·`). Giữ nguyên `formatDateTimeLabel` (PBI 8 dùng, không đổi hành vi).

**Lý do**: Mockup 04 hiển thị `03/09/2026 · 12:15`; hàm hiện có trả khoảng trắng `dd/MM/yyyy HH:mm` — đổi hàm cũ sẽ làm hồi quy màn chuyển tiền (PBI 8) nên thêm hàm mới, tái dùng `_two`.

## R9 — Không thêm method repository mới

**Quyết định**: Tận dụng `allTransactions()` + `loadAll()` đã có; chọn giao dịch & dựng view-model bằng hàm thuần `buildTransactionDetail(...)` trong file `core/transaction/transaction_detail.dart`. Không thêm method/query vào `WalletRepository`/Drift/Fake.

**Lý do**: SC-001 thoải mái (≤1s/1.000 dòng local); hạn chế bề mặt seam phải giữ giữa 3 impl (interface/drift/fake). Chọn lọc trong bộ nhớ đơn giản và dễ test thuần.

**Phương án khác**: Thêm `transactionById`/`legsByGroup` → sạch SQL hơn nhưng phình seam + fake + test DAO; chưa cần ở quy mô này.

## R10 — Pattern màn & test (không phình GetX cho 1 màn đọc)

**Quyết định**: `TransactionDetailScreen` là `StatefulWidget` bám pattern `WalletDetailScreen`: nhận `ref`; có **seam** `Future<TransactionDetailView?> Function()? loader` (test bơm trực tiếp, không cần sqlite); mặc định `loader` đọc qua `ensureWalletRepository()` (singleton, `wallet_deps.dart`) → `allTransactions` + `loadAll` → `buildTransactionDetail`. State UI: `loading / view | lỗi (thông báo + Thử lại)`. Không thêm controller GetX/deps cho màn đọc này.

**Lý do**: Màn chỉ đọc 1 lần khi mở, không cần Rx/tái nạp theo sự kiện; pattern Stateful + seam đã có sẵn trong codebase (WalletDetailScreen), tái dùng được. Test unit (hàm thuần) + widget (seam bơm view) + DAO (map cột mới, skip-guard) — không cần sqlite native ở test màn.

**Phương án khác**: Tạo `TransactionDetailController` GetX + `transaction_deps.dart` → thêm 2 file + đăng ký/dispose theo ref, quá mức cho 1 lần đọc (bác).

## Tổng kết

Mọi điểm nghiên cứu đã chốt, không còn `NEEDS CLARIFICATION`. Thay đổi schema v3 do người dùng chốt (R3).
