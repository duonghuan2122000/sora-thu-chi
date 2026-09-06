# Nghiên cứu — PBI 15 (Màn hình danh sách danh mục con)

**Mã PBI**: 15 — **Ngày**: 2026-09-06

Đọc: spec 15, mockup `docs/category/03-danh-muc-con.svg`, wiki [[Danh mục]]/[[Design system]]/[[Stack kỹ thuật]], code hiện tại (`category_list_screen.dart`, `category_form_screen.dart`, `category.dart`, `category_list.dart`, `category_source.dart`, `wallet_repository*.dart`, `fake_wallet_repository.dart`, `sub_page_scaffold.dart`, `app_theme.dart`/`app_colors.dart`), PBI 13/14 spec + research + plan + data-model (màn `01`, màn `02`, seam đọc/ghi, presets).

**Không có** `.specify/memory/constitution.md`. Không còn `NEEDS CLARIFICATION` — spec checklist đã đạt. Bố cục màn khớp mockup `03`; mọi điểm kỹ thuật chốt bên dưới có lý do, không cần hạ tầng mới.

---

## R1 — Điểm vào từ màn danh sách danh mục (PBI 13 → 15) & refresh khi về

- **Quyết định**: trong `CategoryListScreen`, nhánh `onTap` dòng đang là no-op ("có con") được nối: danh mục **có con** → `Navigator.push(CategoryChildListScreen(parent: c, repository: _repository))`; sau khi `await push` trả về → `_reloadSilent()` (helper sẵn có, nạp lại lặng cả 2 loại). Nhánh **không con** giữ nguyên (mở form Sửa — PBI 14). FAB "+" không đổi (thêm danh mục gốc).
- **Lý do**: màn `03` hiển thị dữ liệu con của cha; khi cha/con thay đổi trong màn con (thêm/sửa/đổi cha con) số danh mục con của cha ở màn `01` phải phản ánh khi quay lại (FR-011/acceptance 8/10). `_reloadSilent` đã có, nạp lại 2 loại một lần, giữ tab + không bật spinner — tái dùng đúng helper, không tách luồng mới. Route giữ `_tab` nên back trả về đúng tab đang mở.
- **Phương án khác**: màn con `pop(result: bool đã đổi)` rồi list chỉ reload khi đổi → tiết kiệm 1 đọc nhưng thừa hợp đồng phức tạp (phải biết loại nào đổi); reload lặng luôn đơn giản, bảng nhỏ local, đủ nhanh (SC-001). Chọn reload luôn như PBI 14 R1.

## R2 — Màn mới `CategoryChildListScreen`: nguồn dữ liệu & cấu trúc

- **Quyết định**: StatefulWidget mới `screens/category_child_list_screen.dart` (pattern `CategoryListScreen` PBI 13 — seam `repository` mặc định `ensureWalletRepository`, test bơm fake). Nhận **`Category parent`** (cha đang xem — mang `id`, `type`, `name`, icon/màu/ẩn để dựng app bar) + `repository`. Khi mở:
  - Nạp **1 loại** `categoriesIncludingHidden(type: parent.type)` vào `_list` (cha + con của đúng loại, gồm ẩn) — danh sách con = `childrenOf(_list, parent.id)` (helper thuần `category_list.dart` đã có, sort ổn định theo `sortOrder`, FR-004/005).
  - Cha hiển thị không giữ object tĩnh từ tham số: **derive** `_parent = _list.firstWhere(id == parent.id)` sau mỗi lần load/reload → tiêu đề app bar luôn tươi sau khi đổi tên cha (không state song song dễ lệch).
- **Bố cục** (mockup `03`): app bar teal + back trái; **vùng tiêu đề chạm được** (R3); action "+" (phải); body `ListView`: các dòng con (R4) + hàng **"Thêm danh mục con"** cuối danh sách (R5); empty-state phòng thủ khi không còn con (R9). Không FAB, không bottom nav, không hiển thị số tiền.
- **Lý do**: màn chỉ đọc (không ghi schema), tái dùng `childrenOf` + seam `categoriesIncludingHidden` sẵn có — không thêm method repository, không chạy `build_runner`. Nạp 1 loại đủ (chỉ con của cha đang xem); nạp cả 2 loại thừa. Derive cha từ list loại bỏ 2 nguồn sự thật.
- **Phương án khác**: thêm seam mới `categoriesIncludingHidden` kiểu "chỉ con của cha" → thừa (lọc bằng `childrenOf` thuần ở tầng UI là bất biến đã chốt PBI 13); nạp cả 2 loại như màn `01` → dư dữ liệu không dùng.

## R3 — Vùng tiêu đề = điểm chạm sửa danh mục cha (FR-003, acceptance 9)

- **Quyết định**: app bar tự dựng trong màn con (không qua `SubPageScaffold`): `Scaffold` + `AppBar` chuẩn (hưởng `AppBarTheme` teal/foreground trắng/`centerTitle: false` của `AppTheme`). `leading` để mặc định (BackButton tự hiện vì route đẩy — đúng pattern). `actions`: `IconButton` "+" tooltip "Thêm danh mục con". `title`: **khối 2 dòng chạm được** — `InkWell` (riêng vùng nằm giữa back và "+") bọc `Column` [tên cha (`white`, 16, w600), dòng phụ "Danh mục con" (`white` ~85%, 11)], bọc `FittedBox` scaleDown để cỡ chữ lớn không tràn/overflow (FR-012, pattern tab màn `01`).
  - Nhấn vùng tiêu đề → `CategoryFormScreen(category: _parent)` — cha **có con** nên form tự khóa loại (readonly box) + không mở sheet cha (giữ cây 2 cấp) — PBI 14 đã dựng đủ, màn này chỉ nối. Sau pop → `_reloadSilent()` (derive lại `_parent` → tên mới phản ánh ngay, FR-009).
- **Lý do**: `SubPageScaffold.title` chỉ nhận `String` — không nhúng được tiêu đề 2 dòng + vùng chạm; thêm tham số `titleWidget`/`leading` vào component dùng chung ~10 màn là đổi rộng rủi ro hồi quy cao hơn lợi một lần. Màn con tự dựng `Scaffold`/`AppBar` chuẩn vẫn nhất quán nhờ AppBarTheme tập trung; diff cục bộ, không đụng màn khác.
- **Phương án khác**: sửa `SubPageScaffold` thêm title widget tùy biến → chạm component chung không cần thiết cho 1 màn; nút "+" bên phải không thuộc scope `actions` của mockup? — đúng, `actions` của `SubPageScaffold` đặt được IconButton, nhưng vấn đề nằm ở `title`, chọn tự dựng là tối thiểu.

## R4 — Tái dùng dòng danh mục: trích `CategoryRow` dùng chung (màn `01` + `03`)

- **Quyết định**: trích khối `_row` của `CategoryListScreen` thành widget chia sẻ `core/widgets/category_row.dart` (`CategoryRow`), vì màn `03` dựng dòng gần giống hệt: bubble nền nhạt + icon màu `category.color` (mờ + nhãn "Đã ẩn" nếu ẩn) + tên (ellipsis, không cắt chevron) + chevron phải; **khác duy nhất**: màn `01` có dòng phụ "N danh mục con" (chỉ khi cha có con), màn `03` không có dòng phụ nào (FR-005).
  - API: `CategoryRow({required Category category, String? subtitle, required VoidCallback onTap})` — `subtitle != null` mới hiện; hidden badge/fade nằm trong widget (giống hệt 2 màn).
  - `CategoryListScreen` thay `_row` bằng `CategoryRow(category: c, subtitle: children.isEmpty ? null : '${children.length} danh mục con', onTap: ...)`; vẫn tính `childrenOf` để quyết định `subtitle` + hướng onTap (có con → màn `03`, không con → Sửa) ngay tại list.
  - `CategoryChildListScreen` dùng `CategoryRow(category: con, subtitle: null, onTap: mở Sửa con)`.
- **Lý do**: không nhân bản ~45 dòng bố cục dòng giữa 2 màn quản lý (màn sắp xếp `04` sau cũng dựng dòng tương tự); widget tách file `core/widgets` là nơi chứa component dùng chung (như `category_icon.dart`). Hình thức giữ nguyên 100% → test màn `01` hiện có không vỡ (chạy lại xác nhận). Rủi ro hồi quy thấp vì widget test màn `01` khá đầy đủ (bố cục dòng/ẩn/đếm).
- **Phương án khác**: copy `_row` sang màn `03` — tránh đụng màn `01` nhưng nhân đôi code + lệch dần; không trích → 2 bản bảo trì song song.

## R5 — Điểm "Thêm danh mục con" & preset cha trong form (FR-008, acceptance 6)

- **Quyết định**: hai điểm thêm (action "+" app bar + hàng "Thêm danh mục con" cuối danh sách) cùng mở `CategoryFormScreen` chế độ **Thêm** với cha preset:
  - `CategoryFormScreen` thêm tham số **`int? initialParentId`** (PBI 14 chưa có — để lại cho màn `03`): trong `initState`, `_parentId = widget.category?.parentId ?? widget.initialParentId;` (Sửa vẫn lấy theo category; Thêm dùng preset).
  - Caller truyền `initialType: parent.type` + `initialParentId: parent.id` → form dựng với ô "Danh mục cha" hiển thị tên cha đang xem, loại đúng loại cha, nhóm so trùng tên = con của cha đó; người dùng chỉ nhập tên/chọn icon/màu là lưu được (SC-006, không bắt buộc chọn lại cha).
  - Form **giữ nguyên luật hiện có**: vẫn cho đổi cha (sheet cùng loại) / đổi loại — khi đổi loại `_switchType` đưa `_parentId` về null → trở thành danh mục gốc của loại mới (đúng giả định spec "màn danh sách con chỉ quyết định giá trị khởi tạo"; màn thêm/sửa tự vận hành theo ràng buộc của nó). sortOrder con mới = `endOfGroupSortOrder` → cuối nhóm (acceptance 7).
- **Lý do**: đây là "thêm nhanh danh mục con" đã chốt ở PBI 14 — màn `03` tái dùng màn `02` không sửa lại; param `initialParentId` là mảnh ghép còn thiếu duy nhất ở màn `02`. Không thêm màn/đoạn mới.
- **Phương án khác**: màn `03` tự dựng form thêm con riêng → nhân đôi PBI 14, trái tái dùng; preset cứng trong màn `03` không truyền vào form → không được.

## R6 — Con ẩn vẫn hiện (FR-006, acceptance 4) & dòng con không có dòng phụ đếm

- **Quyết định**: danh sách con lấy từ `categoriesIncludingHidden` (không lọc ẩn) qua `childrenOf` → con đang ẩn xuất hiện đúng vị trí với nhãn "Đã ẩn" + mờ (trong `CategoryRow`); không bị loại khỏi màn quản lý. Vì con cấp 2 không thể có con (cây 2 cấp), `CategoryRow` không nhận `subtitle` ở màn này — không có dòng phụ đếm con (FR-005). Cha đang ẩn nhưng có con vẫn vào được màn con (list `01` hiện cha ẩn) — màn con không nhắc lại trạng thái ẩn của cha ở danh sách.
- **Lý do**: tái dùng đúng quy ước màn quản lý PBI 13/14 (ẩn chỉ rút khỏi picker giao dịch mới, không khỏi màn quản lý); bất biến `childrenOf` gồm ẩn đã test ở PBI 13. Không cần logic mới.

## R7 — Chạm con → sửa danh mục con (FR-007, acceptance 5) & con đổi cha (FR-010)

- **Quyết định**: chạm dòng con → `CategoryFormScreen(category: con)` (prefill 100% — PBI 14 đã dựng). Con là cấp 2 → `canChangeType` trả false (isParent = false) → ô loại readonly, luôn cùng loại cha. Con không có con → `_canPickParent` đúng → vẫn đổi cha (sheet cha cùng loại gồm "Không có — là danh mục gốc"). Sau pop (đã lưu hay back) → `_reloadSilent()` đọc lại `_list` → con vừa đổi tên/icon/màu/ẩn phản ánh ngay (FR-009); con vừa chuyển sang cha khác (hoặc bỏ cha thành gốc) biến mất khỏi danh sách cha cũ (FR-010, acceptance: sau lưu không còn trong danh sách này).
- **Lý do**: màn `02` đã dựng đủ chế độ Sửa con (R7 PBI 14 dành cho entry `03` này) — màn `15` chỉ nối điểm vào + reload. Lọc "con còn thuộc cha" tự nhiên bằng cách đọc lại list (không cần xóa thủ công).
- **Phương án khác**: màn con tự giữ cache và xóa dòng đã đổi cha bằng result trả về → thừa, dễ lệch; reload lặng đúng mô hình màn `01`.

## R8 — Refresh "không cần làm mới tay" xuyên 2 tầng màn (FR-009/011)

- **Quyết định**: sau **mỗi** lần pop từ form (màn `02`) màn con reload lặng 1 loại; sau khi màn con pop về màn `01`, màn `01` reload lặng cả 2 loại (R1). Không có pull-to-refresh, không nút làm mới — phản ánh tự động.
- **Lý do**: bám đúng mô hình PBI 13/14 (reload lặng sau pop); offline 1 user, bảng nhỏ local, đọc lại nhanh (SC-001). Hai tầng reload đảm bảo acceptance 7 (về màn con thấy dữ liệu mới) và acceptance 8/10 (về màn `01` thấy số con/tên cha mới) cùng đúng.
- **Phương án khác**: truyền danh sách con dùng chung qua state chia sẻ (controller/event) → phình tầng, trái kiến trúc "màn StatefulWidget + seam" đang giữ.

## R9 — Empty-state phòng thủ & đa cỡ chữ (edge, FR-012/SC-008)

- **Quyết định**: khi `childrenOf` rỗng (cha đang xem không còn con — chỉ xảy ra khi toàn bộ con chuyển cha/xóa, chưa có xóa đợt này → trạng thái phòng thủ): hiện empty hướng dẫn thêm con **+ vẫn giữ** 2 điểm thêm ("+"/hàng "Thêm danh mục con") — không lỗi (acceptance edge). Cả cha ẩn lẫn con ẩn đều không tạo empty giả (danh sách nguồn gồm ẩn nên không rỗng khi còn con ẩn). Body `ListView` cuộn + SafeArea; tiêu đề chạm được bọc FittedBox; dòng tên ellipsis — cỡ chữ lớn/safe area khác nhau không tràn/cắt (FR-012).
- **Lý do**: quy ước empty của màn `01` (PBI 13) lặp lại; con ẩn không tính là "không có con" vì màn quản lý hiện cả ẩn.

## R10 — Test

- **Quyết định**:
  - Widget mới `test/category_child_list_screen_test.dart` bơm `FakeWalletRepository` (đã biến đổi được): nhóm bố cục mockup `03` (app bar: back + tiêu đề tên cha + "Danh mục con" + nút "+", không bottom nav, chỉ con của cha đang xem — không lẫn con cha khác / loại khác, chevron mỗi dòng, thứ tự sortOrder), nhóm con ẩn (hiện đúng vị trí + "Đã ẩn", không loại), chạm con → form Sửa prefill + loại khóa; thêm qua "+"/hàng → form Thêm preset cha/loại (ông cha hiển thị tên cha, chọn sẵn loại cha) → lưu con cuối nhóm; đổi cha con → hết xuất hiện (FR-010); sửa cha qua vùng tiêu đề (đổi tên → tiêu đề mới, danh sách con giữ nguyên, form cha khóa loại + không mở sheet); empty-state phòng thủ (pump trực tiếp repo không còn con); cỡ chữ lớn không overflow. Test dùng `find.descendant` scope trong màn con (màn `01` đè dưới còn state — như helper `_formText` PBI 14).
  - Sửa `test/category_list_screen_test.dart`: case cũ "dòng có con → no-op" đổi thành "mở màn danh sách con"; thêm case back từ màn con → tab cũ giữ + số danh mục con cập nhật (acceptance 8/10) — qua fake biến đổi.
  - Sửa `test/category_form_screen_test.dart`: thêm case Thêm với `initialParentId` (nhóm so trùng tên theo cha preset, lưu về cuối nhóm con của cha đó).
  - Unit `category_list`/`category_form` không đổi (không logic thuần mới); chạy lại toàn bộ test — không hồi quy PBI 11/12/13/14 (chung fake/theme).
- **Lý do**: bám pattern PBI 14 (widget test qua fake biến đổi, assert store); acceptance phủ entry màn `03` — điểm chưa QA tay được đầy đủ vì chỉ seed "Ăn uống" có con (R11). Không cần sqlite native.
- **Phương án khác**: DAO/drift test cho đọc con — thừa (không seam/schema mới); chấp nhận phủ qua widget+unit như PBI 13/14.

## R11 — Giới hạn QA tay & chuẩn bị dữ liệu

- **Quyết định**: seed mặc định chỉ 1 cha có con ("Ăn uống" — 3 con). QA tay màn con chủ yếu đi qua "Ăn uống"; muốn QA cha thu/nhóm khác → **tự tạo trước**: ở màn `01` FAB → đặt tên + chọn "Danh mục cha" = cha muốn (thêm con trực tiếp bằng form PBI 14) → cha đó có con → từ màn `01` chạm được vào màn con. Không thêm seed mới (không số liệu minh họa giả).
- **Lý do**: quy ước không thêm dữ liệu giả; luồng tạo cha-có-con đã có sẵn qua màn `02` (đặt cha khi Thêm).

---

## Kết luận

Không còn `NEEDS CLARIFICATION`. Không đổi schema (v4), không seam repository mới, không `build_runner`, không package mới. Việc chính: 1 màn `03` mới (đọc + dựng), trích `CategoryRow` dùng chung `01`/`03`, thêm 1 param `initialParentId` vào form `02`, nối điểm vào màn `01`, cập nhật 3 file test.
