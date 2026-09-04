# Giai đoạn 0 — Nghiên cứu: Màn hình danh sách ví

**Mã PBI**: 5

Phạm vi đợt này chỉ là **hiển thị + điều hướng điểm vào**. Không luồng tạo/sửa/ẩn/xóa ví, không giao dịch, không DB mới. Mọi quyết định dưới đây giữ diff nhỏ nhất, chừa seam để PBI sau (form ví, chi tiết ví) thay nguồn dữ liệu thật.

## Q1. Nguồn dữ liệu ví — đợt này lấy từ đâu?

- **Quyết định**: Model thuần `Wallet` + hằng `WalletSource.all()` trả 5 ví mẫu (tiền mặt mặc định, ngân hàng, thẻ tín dụng, ví điện tử, sổ tiết kiệm ẩn) — khớp bộ mẫu spec SC-003. Screen nhận `List<Wallet>` qua constructor (default = `WalletSource.all()`).
- **Lý do**: Chưa có luồng tạo ví, chưa có DB drift nào wire (kiểm chứng: pubspec đã khai `drift` nhưng `lib/` chưa có bảng/`@DriftDatabase` nào). Spec §Giả định & §Thực thể chính **bắt buộc** "nguồn dữ liệu phải cấp được ví mẫu để kiểm chứng hiển thị" — nên đây là ngoại lệ có chủ đích so với nguyên tắc PBI 4 "cấm số liệu minh họa" (xem plan — Ngoại lệ).
- **Phương án khác**: Dựng `wallets` table + drift ngay → quá sớm (YAGNI): không có luồng ghi nào để sinh dữ liệu thật, thêm build_runner + migration trong khi màn chỉ đọc. Dùng `shared_preferences`/JSON → cũng thừa, chưa có consumer ghi.

## Q2. Hình dạng model Wallet — cần đủ gì để vẽ danh sách?

- **Quyết định**: `Wallet { id, name, type(WalletType enum), icon(emoji String), balance(int, VND), isDefault, isHidden, sortOrder, creditLimit?, creditUsed? }`. Chỉ kê trường màn cần; số dư hiện tại là một giá trị int (đại lượng suy ra ở đời thật, đợt này cấp thẳng). `WalletType`: `cash, bank, credit, eWallet, savings`.
- **Lý do**: Màn chỉ đọc các trường trên. Trường nghiệp vụ khác (initial_balance, màu, ngày sao kê, kỳ hạn...) thuộc luồng tạo ví PBI sau — không mang vào sớm.
- **Phương án khác**: Copy toàn bộ schema drift `wallets` từ `docs/wallet/nghiep-vu...` → thừa trường chết, model to hơn cần.

## Q3. Thẻ tín dụng & "tổng số dư" — thẻ có góp vào tổng không?

- **Quyết định**: **Thẻ tín dụng KHÔNG góp vào tổng số dư** (giá trị hiển thị của thẻ là "đã dùng / hạn mức" — khoản phải trả, không phải số dư tài sản sẵn sàng). Tổng = Σ `balance` của ví đang hoạt động **không ẩn, không phải thẻ tín dụng**. Nhãn "N ví đang hoạt động" đếm mọi ví không ẩn (gồm thẻ).
- **Lý do**: Màn không hiển thị một con số "số dư" nào của thẻ để người dùng đối chiếu; nếu góp balance âm (nợ) thì tổng ≠ tổng các số đang hiển thị, QA SC-003 "tổng thủ công" không khớp được. SC-003 "3 ví thường + 1 thẻ + 1 ẩn, ví ẩn không làm lệch" ngầm chỉ tổng theo các ví hiển thị số dư.
- **Phương án khác**: Góp nợ âm của thẻ vào tổng (kiểu "net worth") → cần định nghĩa nghiệp vụ số dư nợ thẻ + quan hệ với giao dịch thẻ (PBI giao dịch chưa tới); tránh đặt tiền lệ từ số liệu mẫu. **⚠ Đánh dấu quyết định mở cho module tổng hợp** khi có nghiệp vụ thẻ tín dụng thật (cập nhật wiki khi PBI tương ứng chốt).

## Q4. Bố cục màn & component dùng chung

- **Quyết định**: Là sub-page dùng `SubPageScaffold(title: 'Quản lý ví')` sẵn có (app bar teal + back tự động, không bottom nav — FR-002). Body: `Column[ _TotalCard, Expanded(ListView các hàng / empty state), nút "+ Thêm ví mới" cố định chân màn ]`, bọc `SafeArea(top:false)` để nút không bị che bởi vùng an toàn đáy (FR-013).
- **Lý do**: Tái dùng thay vì tạo scaffold mới; nút thêm ngoài ListView nên luôn hiện, không phụ thuộc cuộn. Row ví đặt trong widget con `_WalletRow` (không dùng `ListTile` vì layout hai cột số phải linh hoạt cho %/số dư và giữ màu ngữ cảnh).
- **Phương án khác**: `ListTile` thuần → trailing cố định phải, khó xếp "số dư" và "%" riêng; mockup cần dòng phụ dài 2 dòng ở thẻ → row tự dựng chính xác hơn.

## Q5. Định dạng tiền & % sử dụng

- **Quyết định**: Tạo hàm thuần `formatAmount(int)` (phân tách nghìn dấu chấm, không kèm `đ`) và `formatMoney(int)` (= `formatAmount` + `' đ'`); số âm in dấu trừ trước. Đặt tại `lib/core/money_format.dart` (dùng chung toàn app sau này — Tổng quan/Báo cáo). % thẻ = `creditUsed * 100 ~/ creditLimit` (chia nguyên, truncation) để khớp mockup 6.500.000/20.000.000 → "32%"; guard limit ≤ 0 → 0%.
- **Lý do**: Chưa có formatter tiền nào trong repo (đã grep, không match). `đ` nằm sau số, số âm có dấu trừ (FR-011). Chia nguyên vì mockup vẽ 32% cho 32.5%; làm tròn 33% sẽ lệch mockup.
- **Phương án khác**: `intl` NumberFormat → thêm dependency chỉ để 1 hàm; tự viết 10 dòng không cần.

## Q6. Màu & token

- **Quyết định**: Thêm 2 token vào `app_colors.dart`: `tealLightBg = 0xFFE1F5EE` (nền tròn icon), `softCardBg = 0xFFF1EFE8` (nền card tổng). Các màu chữ tái dùng token có sẵn: `textPrimary`/`listLabel`(loại ví)/`tabInactive`+`dotEmpty` (ví ẩn)/`coral` (thẻ — ngữ cảnh chi tiêu)/`white`.
- **Lý do**: Design system "widget không nhúng hex". Chỉ thêm màu thật sự dùng.
- **Phương án khác**: Viết hex cứng trong widget → vi phạm rule tập trung style.

## Q7. Nối điều hướng từ Cài đặt (FR-001)

- **Quyết định**: `SettingsScreen` thêm tham số `onManageWalletTap` (`VoidCallback?`); hàng "Quản lý ví" trở thành hàng chạm được: nếu `onManageWalletTap == null` → default `Navigator.of(context).push(WalletListScreen())`, ngược lại gọi callback. `_SettingsRow` thêm `onTap` optional. Shell giữ nguyên (dùng default).
- **Lý do**: Khớp seam-test PBI 4/3 (bơm callback qua constructor để widget test không cần navigator thật khi cần); hành vi default đúng FR-001. Wallet list là route đẩy nguyên màn → không bottom nav (FR-002), IndexedStack shell giữ trạng thái tab.
- **Phương án khác**: Đặt navigation trong `AppShell._open...` rồi truyền callback xuống → nhiều sửa hơn; gắn `onTap` trực tiếp nhúng route vào Settings → khó test cô lập. Test PBI 4 hiện có loop "tap 'Quản lý ví' → không mở màn" → **phải sửa** (xem plan — file đổi).

## Q8. Dòng phụ từng hàng & lệch mockup

- **Quyết định**: Dòng phụ = tên loại ví (bình thường); ví mặc định → thêm nhãn "Mặc định" (chữ teal, đậm, size nhỏ) **trước** tên loại, cùng dòng cách " • ". Thẻ tín dụng → dòng phụ coral `"Đã dùng X / Hạn mức Y đ"` (thay tên loại, khớp mockup FR-007). Ví ẩn → toàn hàng xám, tên + " (đã ẩn)", dòng phụ "Không tính vào tổng".
- **Lý do**: Spec FR-006 đòi hiển thị **cả** loại **lẫn** nhãn mặc định; mockup chỉ vẽ "Mặc định" cho ví mặc định (vì trong mock tên trùng loại "Tiền mặt") — không tổng quát. FR thắng mockup (đúng triết lý PBI 4).
- **Phương án khác**: Theo đúng mockup (thay loại bằng "Mặc định") → mất thông tin loại, lệch FR-006 khi ví mặc định là ngân hàng/ví điện tử.

## Q9. Trạng thái rỗng — không có ví nào (SC-006)

- **Quyết định**: Card tổng vẫn hiển thị "0 đ / 0 ví đang hoạt động" (không phá FR-003). Vùng danh sách hiện trạng thái rỗng trung tâm: icon ngăn xếp + "Chưa có ví nào." + dòng phụ "Chạm '+ Thêm ví mới' để tạo ví đầu tiên." Nút thêm luôn hiện.
- **Lý do**: Spec §Giả định giao cách hiển thị cho kế hoạch, miễn "rõ ràng, không lỗi, không vỡ" (SC-006). Giữ card giúp bố cục ổn định giữa hai trạng thái.
- **Phương án khác**: Ẩn card khi rỗng → màn thay đổi chiều cao đột ngột; không cần.

## Q10. Dependency / kiến trúc — có thêm gì không?

- **Quyết định**: **Không** thêm dependency, không wire drift, không tạo controller GetX (màn đọc tĩnh). Không tạo `contracts/` (app nội bộ offline — khớp PBI 4). Icon ví = emoji trong field `icon` (mockup dùng emoji), không import thư viện icon.
- **Lý do**: Đúng stack đã chốt, đợt này chỉ hiển thị. GetX controller chỉ cần khi có trạng thái/luồng ghi.
- **Phương án khác**: Dựng GetX controller + repo drift trước → code chết.

## Q11. Cờ mặc định & thứ tự hiển thị

- **Quyết định**: Danh sách xếp: ví **đang hoạt động theo `sortOrder`**, rồi **ví ẩn** ở cuối (mờ). Bộ mẫu đảm bảo đúng 1 ví `isDefault`. Screen **không** tự kiểm định "chỉ 1 ví mặc định" (invariant đảm bảo bởi luồng tạo ví PBI sau; model mẫu tuân thủ).
- **Lý do**: FR-006/SC-004 yêu cầu đúng 1 nhãn "Mặc định"; FR-008 đẩy ví ẩn cuối. Không thêm validation code chết cho dữ liệu không thể sai ở đợt mẫu.
- **Phương án khác**: Tự xác thực/bọc fallback khi nhiều ví default → over-engineering.

## Quyết định mở / cần người dùng duyệt

1. **Thẻ tín dụng không góp tổng** (Q3) — lệch đọc literal "tổng các ví đang hoạt động" trong docs §5. Nếu muốn tổng theo hướng net (trừ nợ thẻ) → sửa predicate 1 chỗ + chỉnh bộ mẫu, báo trước khi implement.
2. **Hiển thị ví mẫu trên thiết bị thật** (Q1) — chấp nhận có dữ liệu demo cố định tới khi PBI tạo ví có DB thật; nếu không muốn thấy số mẫu trên máy thật → chỉ nên chạy màn khi có dữ liệu thật, tức bỏ sample, màn sẽ luôn rỗng (chưa kiểm chứng được SC-003/SC-004 bằng mắt).
3. **Empty state chỉ kiểm chứng bằng widget test** — trên thiết bị không có luồng tạo/xóa ví nên không tạo được trạng thái 0 ví bằng tay (nêu ở quickstart).
