# Giai đoạn 0 — Nghiên cứu: Màn hình chi tiết ví

**Mã PBI**: 6

Phạm vi đợt này **chỉ hiển thị + điều hướng điểm vào**. Màn chi tiết đọc 1 ví + danh sách giao dịch của ví đấy, không mở luồng nào (chuyển tiền / sửa / ẩn / chi tiết giao dịch = PBI sau). Mọi quyết định giữ diff nhỏ nhất và chừa seam cho PBI Giao dịch (drift) sau.

## Q1. Nguồn dữ liệu giao dịch — đợt này lấy từ đâu?

- **Quyết định**: Mô phỏng đúng pattern PBI 5: model thuần `Transaction` + hằng `TransactionSource.all()`/`forWallet(walletId)` trả bộ giao dịch mẫu gắn các ví mẫu có sẵn (`WalletSource`, PBI 5). Màn nhận `List<Transaction>` qua constructor, default = `TransactionSource.forWallet(wallet.id)`.
- **Lý do**: Chưa có luồng tạo giao dịch, chưa có DB drift wire (kiểm chứng: `lib/` chưa có bảng nào). Spec §Thực thể chính **bắt buộc** "cấp được giao dịch thuộc ví để hiển thị danh sách" và SC-003 cần bộ mẫu một ví có thu/chi/chuyển — ngoại lệ có chủ đích so với nguyên tắc PBI 4 "cấm số liệu minh họa", giống hệt lý do đã chấp nhận ở PBI 5. Interface trả list giữ nguyên để PBI Giao dịch sau thay bằng đọc drift.
- **Phương án khác**: Dựng bảng `transactions` + drift ngay → YAGNI (không có consumer ghi, thêm build_runner/migration); dùng `shared_preferences` → thừa.

## Q2. Hình dạng model `Transaction` & ý nghĩa `amount`

- **Quyết định**: `Transaction { id(int), walletId(int), type(TxnType), category(String — tên danh mục, transfer để rỗng), note(String), amount(int VND, **signed** = tác động ròng lên ví chứa dòng này), date(DateTime) }`. `TxnType { income, expense, transfer, adjustment }` (label 'Thu'/'Chi'/'Chuyển khoản'/'Điều chỉnh số dư'). Transfer = **2 dòng thuộc 2 ví riêng** (dòng trên ví nguồn `amount < 0`, dòng trên ví đích `amount > 0`, cùng type `transfer`) — khớp nghiệp vụ "2 bút toán liên kết", khớp `transactions.wallet_id` + `type transfer` trong `docs/wallet/nghiep-vu-vi-tai-khoan.md` §7. `adjustment` sign tùy hướng tăng/giảm số dư.
- **Lý do**: Mỗi dòng thuộc đúng một ví (FR-008 filter `walletId == ví đang xem`) nên lọc + cộng dồn đơn giản; `amount` signed để SC-003 cộng dồn thủ công được và định dạng ra dấu `+`/`−` không cần nhánh theo type. Đợt này **chưa** lưu `transfer_group_id`/`category_id` — chỉ render, chưa cần liên kết hai vế hay join danh mục (PBI Giao dịch sẽ bổ sung khi có DB).
- **Phương án khác**: Lưu magnitude + suy dấu từ type → chuyển khoản/điều chỉnh không có dấu mặc định, phải thêm cờ hướng; phức tạp hơn. Gộp transfer 1 dòng kiểu `fromWallet/toWallet` → mỗi ví lại phải tự suy dấu theo `walletId`, filter khó.

## Q3. Định dạng số tiền dòng giao dịch

- **Quyết định**: Thêm hàm thuần `formatSignedMoney(int)` vào `core/money_format.dart`: `+` nếu dương, `-` (ASCII, đồng bộ PBI 5) nếu âm, `0` → `'0 đ'`; VD `+18.000.000 đ`, `-450.000 đ`. Màu số tiền & glyph theo **type** (không theo dấu): income teal `+`/↑, expense coral `-`/↓, transfer & adjustment trung tính (`listLabel`) — đúng bảng màu wiki Giao dịch ("Thu teal, Chi coral, Transfer trung tính") và FR-010 (điều chỉnh không lẫn vào thu/chi thường).
- **Lý do**: `formatMoney` hiện tại không có dấu `+`; dòng giao dịch cần dấu theo type (FR-010). `+`/`-` ASCII vì toàn app (PBI 5) dùng `-`; tránh glyph `−` lẫn font.
- **Phương án khác**: Dùng `intl` NumberFormat → thêm dependency cho 1 hàm; viết 10 dòng không cần. Trả cả chuỗi lẫn màu → trộn trách nhiệm, giữ chuỗi thuần + widget chọn màu theo type.

## Q4. Nhãn ngày thân thiện trên dòng giao dịch

- **Quyết định**: Hàm thuần `relativeDayLabel(DateTime date, {DateTime? now})` tại `core/date_label.dart`: cùng ngày lịch với `now` → `'Hôm nay'`; hôm qua → `'Hôm qua'`; khác → `'dd/MM'` (viết tay, không thư viện). `now` truyền vào để test deterministic. Bộ mẫu dùng ngày tương đối `DateTime.now()` (hôm nay / hôm qua / vài ngày trước) để màn trên thiết bị trông thật và có đủ ba dạng nhãn.
- **Lý do**: Mockup dùng "Hôm nay"/"03/09"; chưa có `intl`/helper ngày trong repo (đã grep). Hàm thuần dễ unit test bằng cách bơm `now`.
- **Phương án khác**: `intl` DateFormat + tự so ngày → thêm dependency; cứng nhãn ngày thật → mau "cũ" trên bộ mẫu.

## Q5. Bố cục màn chi tiết

- **Quyết định**: Tái dùng `SubPageScaffold(title: wallet.name)` (app bar teal + back tự động — FR-002). Body = **một ListView/CustomScrollView duy nhất** chứa: vùng teal hero (icon + số dư + dòng loại — FR-003), hàng 3 hành động nhanh (FR-006), `SectionHeader('GIAO DỊCH GẦN ĐÂY')`, rồi các dòng giao dịch (hoặc empty state). Toàn bộ cuộn chung; bọc `SafeArea(top:false)`.
- **Lý do**: Hero teal nối liền app bar cùng màu thành một khối; toàn bộ cuộn giúp **không** vỡ khi cỡ chữ lớn / vùng an toàn / số dòng giao dịch nhiều (FR-014/015, SC-007) mà không phải ép chiều cao cố định vùng teal. App bar (back + tên ví) cố định nhờ Scaffold nên lúc cuộn vẫn về được.
- **Phương án khác**: `Column[ hero cố định, Expanded(list) ]` kiểu PBI 5 → hero nén cứng, cỡ chữ 2.0 dễ overflow; `SliverAppBar` trải dài → thêm phức tạp không cần.

## Q6. Ba hành động nhanh & điểm vào chưa kích hoạt

- **Quyết định**: Hàng nút = 3 cột (tròn teal nhạt `tealLightBg` 48px + icon + nhãn 10–11px `listLabel`): **Chuyển tiền** `Icons.swap_horiz`, **Sửa ví** `Icons.edit_outlined`, **Ẩn ví** `Icons.visibility_off_outlined` (thay glyph text `⇄✎⊘` của SVG). `onPressed: () {}` — chạm không lỗi, không mở luồng (FR-007). Cột bọc tương tác có hiệu ứng mực (pattern `_SettingsRow`).
- **Lý do**: DS "Icon outline (line) mảnh, màu ngữ cảnh" — Material Icons đồng bộ & chắc chắn có glyph, không lo text-glyph hiển thị lỗi font (⇄ ngoài Roboto có thể vỡ). No-op giữ đúng spec.
- **Phương án khác**: Nhúng glyph unicode y hệt SVG → rủi ro font trên một số thiết bị; Material icon sai tinh thần màn "không mở".

## Q7. Vùng số dư hero theo loại ví (FR-003/004/005)

- **Quyết định**: Hero gồm tròn icon (trắng alpha ~0.15 như SVG), dòng **số dư cỡ lớn trắng** `formatMoney(wallet.balance)` + dòng phụ `typeLabel` trắng mờ (`white70`). Ngoại lệ **thẻ tín dụng**: dòng lớn = `creditUsageLabel` (`'Đã dùng 6.500.000 / 20.000.000 đ'`, cỡ vừa) + dòng phụ `'NN% hạn mức đã dùng'` từ `creditUsedPercent` (FR-005), **chữ trắng** thay vì coral.
- **Lý do**: Số dư đọc `wallet.balance` — số dư suy ra, nguồn sự thật PBI 5 (FR-004). `creditUsageLabel`/`creditUsedPercent` đã có trong `Wallet` (PBI 5) → tái dùng, không viết lại. Lệch nhỏ có lý do: coral trên nền teal tương phản thấp; design system quy định "nền teal luôn đi kèm chữ trắng" → giữ trắng, ngữ cảnh chi tiêu được thể hiện ở dòng giao dịch chi. (Xem Rủi ro — cần đối chiếu mắt trên thiết bị.)
- **Phương án khác**: Tô coral phần trăm/chuỗi thẻ trên hero → khó đọc; bỏ dạng "đã dùng" của thẻ → sai FR-005.

## Q8. Trạng thái rỗng "GIAO DỊCH GẦN ĐÂY" (FR-012)

- **Quyết định**: Khi ví không có giao dịch nào, vùng danh sách hiện khối rỗng trung tâm: icon `🧾` + `'Chưa có giao dịch nào.'` + dòng phụ `'Giao dịch của ví sẽ xuất hiện tại đây.'`. Hero + hàng hành động + tiêu đề nhóm vẫn hiện đủ.
- **Lý do**: Spec §Giả định giao cách hiển thị cho kế hoạch, miễn "rõ ràng, không lỗi, không vỡ" (SC-006). Ví ẩn "Sổ tiết kiệm" trong bộ mẫu để trống → mở ra vừa kiểm chứng empty vừa chứng minh ví ẩn xem được (FR-012 + edge "ví ẩn vẫn xem chi tiết").
- **Phương án khác**: Ẩn cả tiêu đề nhóm khi rỗng → màn rỗng loãng; không cần.

## Q9. Nối điều hướng từ danh sách ví & ví ẩn (FR-001)

- **Quyết định**: Hàng ví trong `WalletListScreen` bọc `InkWell`, tap → `Navigator.of(context).push(WalletDetailScreen(wallet: wallet))`. Mở bình thường cả với ví ẩn (spec #7 — không chặn). `WalletDetailScreen({required Wallet wallet, List<Transaction>? transactions})`, default lấy `TransactionSource.forWallet(wallet.id)`; **không** thêm seam callback — test dựng trực tiếp màn detail để bơm wallet + txn, test điều hướng dùng navigator thật (đúng pattern settings→list PBI 5).
- **Lý do**: FR-001 đổi hành vi hàng ví ở PBI 5 (đang "chạm không mở"). Detail nhận qua constructor → unit/widget test không phụ thuộc nguồn dữ liệu toàn cục. Back trả về list — route list còn nằm dưới stack → giữ đúng trạng thái (SC-001, acceptance 9).
- **Phương án khác**: Seam callback `onWalletTap` xuyên constructor như Settings → thừa, vì hành vi đã thật sự điều hướng.

## Q10. Màu & token mới

- **Quyết định**: Thêm đúng 1 token `coralLightBg = Color(0xFFFAECE7)` (nền tròn icon dòng chi — mockup). Các màu khác tái dùng token có sẵn: tròn thu `tealLightBg`, tròn transfer/adjust `softCardBg`, số thu `teal`, số chi `coral`, số transfer/adjust + nhãn `listLabel`, icon arrow thu `teal` / chi `coral` / transfer–adjust `listLabel`. Hero dùng `white` + trắng alpha (không token mới cần — dùng `Colors.white70`).
- **Lý do**: DS "widget không nhúng hex"; `#FAECE7` là nền duy nhất chưa có trong `app_colors.dart`.
- **Phương án khác**: Hex cứng trong widget → vi phạm rule tập trung style.

## Q11. Dependency / kiến trúc — thêm gì?

- **Quyết định**: **Không** thêm dependency, không wire drift/GetX, không tạo controller (màn đọc tĩnh — đúng Q10 PBI 5). Không tạo `contracts/` (app nội bộ offline). Không sửa `pubspec.yaml`.
- **Lý do**: Đợt này chỉ đọc hiển thị; GetX/drift cần khi có luồng ghi trạng thái.
- **Phương án khác**: Dựng controller/repo trước → code chết.

## Quyết định mở / cần người dùng duyệt

1. **Bộ giao dịch mẫu trên thiết bị thật** (Q1): như PBI 5 — dữ liệu demo cố định tới khi có luồng ghi giao dịch. Mọi số liệu phơi bày là mẫu (nối với quyết định mở PBI 5 còn hiệu lực).
2. **Số dư hero là `wallet.balance` (cấp thẳng), không tính lại từ giao dịch** (Q7): ở đời thật số dư = số dư ban đầu + Σ signed(giao dịch); đợt này màn chỉ đọc balance PBI 5 đã cấp. Bộ mẫu giao dịch được **dàn để tự nhất quán**: nếu cộng dồn Σ signed vào một "số dư nền" cố định (ghi trong `quickstart.md`) thì ra đúng `14.800.000 đ` — đủ cho QA SC-003 đối chiếu thủ công. Khi PBI Giao dịch (drift) tới → số dư thành đại lượng suy ra thật. Nếu muốn màn **tự tính** balance từ giao dịch ngay (số dư ban đầu + Σ) → cần thêm trường `initial_balance` vào `Wallet` — báo trước khi implement (nghiêng về KHÔNG thêm đợt này).
3. **Hero thẻ tín dụng để chữ trắng** (Q7): lệch FR-005 chữ "màu chi tiêu" (coral) vì tương phản trên teal kém — chốt bằng mắt trên thiết bị; nếu cần ngữ cảnh coral vẫn có thể đổi phần trăm/thanh nhỏ.
4. **Empty & số âm & ví ẩn chỉ kiểm chứng được bằng widget test + ví ẩn sẵn có** — thiết bị không tạo được trạng thái rỗng tuỳ ý (không có luồng xóa/giao dịch); tận dụng ví "Sổ tiết kiệm" trống.
