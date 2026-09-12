# Nghiên cứu kỹ thuật: PBI 20 — Tổng quan Ngân sách (ngân sách theo danh mục)

**Mã PBI**: 20 · **Ngày**: 2026-09-12 · **Liên kết spec**: [spec.md](./spec.md)

Không còn `NEEDS CLARIFICATION`: spec đã "Đã làm rõ", checklist `requirements.md` xác nhận 0 điểm mở. Dưới đây là các quyết định kỹ thuật cho những chỗ spec **cố ý** để trống (chi tiết triển khai).

## R1 — Điểm vào & thanh điều hướng đáy: **đẩy route riêng, tự dựng bottom nav + FAB dùng chung**

- **Quyết định**: Tab Báo cáo (`report_screen.dart`) thêm hàng điểm vào "Ngân sách". Chạm → `Navigator.push(BudgetOverviewScreen)`. Màn 01 là `Scaffold` **không có app bar back** (đúng mockup `01`: tiêu đề trái + nút `+` phải), dùng `ScreenHeader` cho vùng teal, `bottomNavigationBar: AppBottomNavBar(selectedIndex: 2)` — tab "Báo cáo" sáng sẵn. Chạm tab khác → `Navigator.pop()` rồi gọi callback `onSelectTab` do `AppShell` bơm xuống.
- **Lý do**: mockup `01` cho thấy màn này **là màn cấp tab** (bottom nav hiện, tab Báo cáo đang chọn) nhưng lại có nút `+` riêng và không có nút back ⇒ không dùng được `SubPageScaffold`. Bơm callback từ `AppShell` là cách duy nhất để bottom nav ở màn đẩy thật sự chuyển được tab mà không phải nhân bản state của shell.
- **Phương án khác đã xem xét**:
  - *Nhúng thẳng vào tab Báo cáo (đổi state hiển thị trong `ReportScreen`)* — bottom nav "miễn phí" nhưng **mất đường quay lại** khung Báo cáo (mockup không có nút back), phải thêm nút back sai mockup.
  - *Đẩy route không có bottom nav* — vi phạm FR-001/SC-002.

## R2 — Bảng `budgets` schema v6: **chỉ 6 cột có hiệu lực đợt này**

- **Quyết định**: `budgets(id, categoryId, amount, period, isRecurring, startDate)`. **Không** tạo `scope`, `name`, `walletIds`, `currency`, `periodStartRule`, `endDate`, `alertThresholds`, `rolloverUnused`, `status`, `createdAt/updatedAt`. Migration v5→v6 = `createTable(budgets)`, **không seed** (spec đòi trạng thái rỗng ở lần mở đầu — khác ví/giao dịch có seed demo).
- **Lý do**: các cột bỏ đi đều **chưa có hiệu lực** (ngoài phạm vi 2a — hàng "Ví áp dụng"/"Cộng dồn"/"Ngưỡng cảnh báo" chỉ hiển thị theo mockup, FR-014) hoặc **suy ra được** (`status`: kết thúc = không lặp lại + kỳ đã qua; không hợp lệ = danh mục không còn). Repo đã có nếp thêm cột bằng migration khi PBI sau cần (v1→v5) nên hoãn là an toàn.
- **Phương án khác**: dựng đủ 18 cột theo doc nghiệp vụ §3.1 — thêm 10 cột không ai đọc/ghi, và `status` lưu sẵn sẽ phải đồng bộ tay với dữ liệu giao dịch.

## R3 — **Không** bảng `budget_period_snapshots`; tính lại khi mở màn

- **Quyết định**: "đã chi", "% đã dùng", "còn lại", "số ngày còn lại" là **đại lượng tính toán** (đúng mục "Thực thể chính" của spec), tính lại mỗi lần nạp màn từ `transactions` + `budgets` + `categories`.
- **Lý do**: doc nghiệp vụ §9 cho phép ("snapshot có thể tính runtime thay vì lưu bảng riêng nếu khối lượng dữ liệu nhỏ"); DB local một thiết bị, quét O(n) trên vài nghìn dòng là tức thời. Bỏ snapshot ⇒ **SC-010 tự động đúng**: sửa `amount` không thể hồi tố kỳ trước vì không có bản ghi kỳ nào để hồi tố.
- **Phương án khác**: bảng snapshot + recompute khi ghi giao dịch — thêm bảng, thêm đường đồng bộ, thêm chỗ sai lệch (snapshot cũ ≠ dữ liệu thật) mà không đổi hành vi người dùng thấy.

## R4 — "Đã chi" = tổng giao dịch **Chi** khớp `category_id` (bản thân + con), theo `transaction_date`

- **Quyết định**: lọc `type == expense` **và** `categoryId ∈ {categoryId} ∪ con trực tiếp` **và** `transactionDate ∈ [periodStart, periodEnd)`. `amount` trong DB là **số có dấu** (chi = âm) ⇒ đã chi = `-tổng`.
- **Lý do**: FR-006 + kịch bản 10/11. Khớp theo `category_id` (không theo text `category`) vì text là snapshot tên và dòng nâng cấp `< v4` giữ `category_id = null` — chấp nhận các dòng cũ đó không tính (không suy đoán theo tên).
- **Phương án khác**: khớp thêm theo tên khi `category_id` null — dễ cộng nhầm giao dịch của danh mục khác trùng tên, và không kiểm chứng được.

## R5 — Mốc kỳ: tháng dương lịch, năm dương lịch, **tuần bắt đầu Thứ Hai**

- **Quyết định**: `Tuần` = Thứ Hai → Chủ nhật; `Tháng` = ngày 1 → hết tháng; `Năm` = 01/01 → 31/12. Khoảng tính theo `[start, end)`.
- **Lý do**: spec giả định "kỳ Tháng/Tuần/Năm tính theo mốc mặc định"; Thứ Hai đã là quy ước sẵn của app (`transaction_filter.resolveDatePreset.thisWeek`). Dùng lại đúng quy ước, không phát minh mốc mới.
- **Phương án khác**: `periodStartRule` (kỳ lệch ngày) — ngoài phạm vi (màn "Định dạng & Tiền tệ" chưa dựng).

## R6 — Nhãn kỳ tháng: `'Tháng @tháng, @năm'` (VI) / `'@tháng/@năm'` (EN)

- **Quyết định**: một khóa dịch có tham số; bản EN hiển thị dạng `9/2026`.
- **Lý do**: FR-023 chỉ đòi **không sót tiếng Việt** khi ở English. Bản EN dạng số không cần bảng tên 12 tháng — mà chưa màn nào khác của app cần tên tháng (các màn hiện dùng `dd/MM/yyyy`).
- **Phương án khác**: bảng tên tháng Anh (12 khóa) — thêm dữ liệu chỉ để làm đẹp một nhãn; thêm khi có màn thật sự cần (báo cáo theo tháng ở PBI sau).

## R7 — Màu tiến độ 3 dải: teal / **coral alpha 0.6** / coral

- **Quyết định**: `< 80%` → thanh + % màu teal (`AppColors.teal` / `colors.tealOnNeutral`); `80–99%` → thanh `AppColors.coral.withValues(alpha: 0.6)`, % `colors.coralOnNeutral`; `≥ 100%` → thanh `AppColors.coral`, % `colors.coralOnNeutral`.
- **Lý do**: mockup `01` vẽ đúng vậy (dòng 84% và 96% là coral `opacity="0.6"`, dòng 107% coral đặc; cả 3 dòng % đều `#D85A30`). Không thêm màu thứ ba vào Design System.
- **Phương án khác**: token `coralLight` mới trong `SoraColors` — thừa: đây là **cùng một màu** ở độ trong suốt khác, không phải màu mới theo theme.

## R8 — Thứ tự danh sách: **giảm dần theo % đã dùng**, dòng "đã kết thúc"/"không hợp lệ" xuống cuối

- **Quyết định**: sắp giảm dần `usagePercent` (FR-022); dòng không tính được % (kết thúc / không hợp lệ) xếp sau, ổn định theo tên danh mục.
- **Lý do**: spec đã chốt "giảm dần để ngân sách căng nhất lên đầu"; dòng không có % không có chỗ trong thang đó nên tách nhóm dưới.
- **Phương án khác**: giữ nguyên thứ tự tạo — spec ghi rõ cần chốt lại nếu muốn vậy (không chọn).

## R9 — Trạng thái rỗng kích hoạt khi **không có dòng ngân sách nào**

- **Quyết định**: `rows.isEmpty` → trạng thái rỗng (lời nhắc + nút "Thêm ngân sách"), không hiện thẻ tổng.
- **Lý do**: FR-019. Đơn giản, không cần định nghĩa thêm "kỳ này có ngân sách hay không" cho các chu kỳ khác nhau.
- **Hệ quả chấp nhận**: ngân sách chu kỳ Tháng tạo ở tháng 9 vẫn hiện (0%) khi người dùng lùi về tháng 6 — spec không kiểm thử case này; ghi nhận ở mục rủi ro.

## R10 — Chồng lấn: so **khoảng hiệu lực**, không so "kỳ đang xem"

- **Quyết định**: mỗi ngân sách có khoảng hiệu lực = `startDate → ∞` nếu `isRecurring`, hoặc **đúng kỳ chứa `startDate`** nếu không lặp lại. Hai ngân sách chồng lấn khi **cùng `categoryId` + cùng `period`** và khoảng hiệu lực giao nhau (FR-016). Khi lưu, bỏ qua chính nó (theo `id`) khi ở chế độ sửa.
- **Lý do**: khớp doc nghiệp vụ §4.2 và kịch bản 8; "khác chu kỳ thì song song" thoả tự nhiên vì `period` phải trùng mới xét.
- **Phương án khác**: chặn theo "cùng danh mục" bất kể chu kỳ — vi phạm kịch bản "Tháng và Năm song song".

## R11 — Seam dữ liệu: **mở rộng `WalletRepository`**, không thêm repository/controller mới

- **Quyết định**: thêm 3 method `budgets()`, `insertBudget(Budget)`, `updateBudget(Budget)` vào `WalletRepository` + `DriftWalletRepository` + `FakeWalletRepository`. Không tạo `BudgetController`; 2 màn dùng `StatefulWidget` + tham số `repository` như màn Danh mục (PBI 13–16).
- **Lý do**: seam này đã là nơi ở của `categories*`/`allTransactions` — thêm repository thứ hai nghĩa là hai chỗ mở cùng một file sqlite. Với 2 màn đọc-rồi-hiện, GetX controller không mang lại gì (không chia sẻ state giữa 2 màn).
- **Phương án khác**: `BudgetRepository` riêng + `BudgetController` (doc §9 gợi ý) — thêm 4 file và 1 dependency mới vào `ensureWalletRepository` singleton, không đổi hành vi.
- **Kéo theo**: `flutter pub run build_runner build` để sinh lại `app_database.g.dart` (bảng mới).

## R12 — Ô nhập số tiền: `digitsOnly` + formatter phân tách nghìn ngay khi gõ

- **Quyết định**: `TextFormField` + `FilteringTextInputFormatter.digitsOnly` + một `TextInputFormatter` riêng tư (~10 dòng) định dạng lại text thành `3.000.000` sau mỗi lần gõ, con trỏ về cuối; lưu bằng `parseAmount`.
- **Lý do**: FR-011 đòi **hiển thị phân tách nghìn**; các ô tiền hiện có (`wallet_form_screen`) chỉ nhận số thô. Dùng lại `formatAmount`/`parseAmount` sẵn có, không thêm package.
- **Phương án khác**: `AmountKeypad` (bàn phím số toàn màn như màn Thêm giao dịch) — mockup `02` vẽ ô nhập có nút mở bàn phím hệ thống, không phải keypad chiếm chỗ; thêm nữa keypad đó không định dạng nghìn lúc gõ.

## R13 — Không thêm dependency bên thứ ba

- **Quyết định**: chỉ dùng `drift`, `get`, Flutter SDK như hiện có. `fl_chart` **không** dùng (biểu đồ thuộc màn Chi tiết ngân sách — PBI sau).
- **Lý do**: đúng ràng buộc stack của dự án; PBI này chỉ có thanh tiến độ tuyến tính (`Container` bo góc), không cần thư viện vẽ.

## Tổng hợp `NEEDS CLARIFICATION`

Không còn mục nào. Các điểm spec để mở đều đã được người dùng chốt ngày 2026-09-12 (xem spec §"Quyết định đã chốt"); các quyết định trên là chi tiết triển khai, không đổi hành vi nghiệp vụ.
