# Nghiên cứu — PBI 14 (Màn thêm/sửa danh mục)

**Mã PBI**: 14 — **Ngày**: 2026-09-05

Đọc: `docs/category/tinh-nang-nghiep-vu-quan-ly-danh-muc.md` (§2/§4/§5), mockup `02-them-sua-danh-muc.svg`, wiki [[Danh mục]]/[[Design system]]/[[Stack kỹ thuật]], spec 14, code hiện tại (`category.dart`, `category_source.dart`, `category_list.dart`, `category_icon.dart`, `category_list_screen.dart`, `category_picker_screen.dart`, `wallet_repository*.dart`, `fake_wallet_repository.dart`, `wallet_form_screen.dart`, `app_database.dart`), PBI 11/13 plan+data-model.

**Không có** `.specify/memory/constitution.md`. Không còn `NEEDS CLARIFICATION` — spec checklist đã đạt; mọi điểm chưa khóa trong spec (bộ icon cụ thể, bảng màu, hình thức picker) là quyết định thiết kế bậc thấp, chốt bên dưới có lý do.

---

## R1 — Điểm vào & refresh màn danh sách (PBI 13 → 14)

- **Quyết định**: `CategoryListScreen` giữ nguyên khung; thay **no-op** bằng push `CategoryFormScreen` và sau khi `await Navigator.push(...)` trả về thì **nạp lại lặng (không spinner)** cả 2 loại. FAB → chế độ Thêm với `initialType = _tab` (acceptance 1/2). Chạm dòng: danh mục **không con** → chế độ Sửa; danh mục **có con** → **giữ no-op** (đi vào màn danh sách con `03` — PBI sau, chốt PBI 13/spec).
- **Lý do**: màn `01` chỉ liệt kê cấp 1; thao tác sửa đợt này phủ danh mục cấp 1 không con (đủ acceptance cho entry thật). Form đổi dữ liệu xong, list phải phản ánh ngay (FR-009/SC-003/SC-006) → cần refresh sau pop; không bật spinner để khỏi giật màn khi chỉ có 1 loại đổi. Nạp lại cả 2 loại vì FAB có thể đổi loại trước lưu (chuyển tab sau khi về sẽ thấy dữ liệu mới).
- **Phương án khác**: cập nhật cache cục bộ từ `Category` form pop về → tiết kiệm 1 đọc nhưng phức tạp (phải biết chính xác loại/cha bị đổi), dễ lệch; nạp lại lặng đơn giản, bảng nhỏ local, đủ nhanh (SC-001).

## R2 — Số hóa bộ icon & bảng màu danh mục (form chọn)

- **Quyết định**: file mới `core/category/category_presets.dart`, bám pattern `wallet_presets.dart`:
  - `categoryIconChoices`: **đúng 15 khóa** đang có trong map `categoryIcon` (thứ tự ổn định) — mọi ô render được, không crash.
  - `defaultIconFor(CategoryType)` và `defaultColorFor(CategoryType)`: chọn sẵn mặc định (khác null), nằm trong danh sách lựa chọn.
  - `categoryPresetColors`: **hợp của (a) màu dữ liệu các danh mục seed đang dùng** và (b) 8 màu trong mockup `02` → đảm bảo danh mục hiện có luôn giữ được màu của chính nó khi sửa (chọn sẵn + có thể chọn lại), không phát sinh trạng thái "màu đang chọn không có trong bảng".
  - 8 mã mockup mới thêm vào `AppColors` làm token (không hex cứng trong widget — rule design): `categoryOrange #F2994A, categoryBlue #2F80ED, categoryPurple #9B59B6, categoryYellow #F2C94C, categoryRed #EB5757, categoryCyan #56CCF2, categoryGreen #27AE60, categoryViolet #BB6BD9`. Các màu seed vốn đã là token (`teal, avatarBg, listLabel, coral, tabInactive`).
- **Lý do**: docs/seed không khai báo một "kho icon" rời; bộ icon duy nhất app có là map `categoryIcon`. Dùng trùng bộ đó = không mở rộng map, không thêm phụ thuộc, mọi khóa selectable render được, hình ảnh nhất quán với dữ liệu giao dịch đang hiển thị. Màu: mockup là nguồn bố cục (FR/SC-002 đối chiếu mockup), nhưng palette mockup thiếu 5 màu seed — nếu chỉ dùng palette mockup thì khi sửa "Ăn uống" (màu `#3D8C77`) bảng màu không có ô tương ứng → không chọn lại được màu cũ. Hợp hai bộ giải quyết, không cần case đặc biệt.
- **Bất biến test**: mọi `Category` trong `CategorySource.all` có `color ∈ categoryPresetColors` và `icon ∈ categoryIconChoices` — form sửa luôn hiện đúng lựa chọn sẵn.
- **Phương án khác**: chỉ 8 màu mockup (vỡ pre-fill seed); mở rộng icon map 30+ glyph tùy biến (scope phình, chưa cần).

## R3 — Seam đọc cho chế độ Sửa & chốt "sạch/khóa"

- **Quyết định**: thêm 1 method đọc `categoryHasTransactions(int categoryId)` → `bool` (có ≥1 dòng `transactions.category_id == id`). Các yếu tố khóa khác suy từ cache danh mục đã có (`categoriesIncludingHidden({type})`): "có con" = `childrenOf(cache, id)` không rỗng; "đang là gốc" = `isParent`.
- **Lý do**: FR-002/008 khóa đổi loại khi đã gắn giao dịch → cần biết giao dịch tham chiếu tới danh mục. Query đếm theo `category_id` đúng tầng dữ liệu (không tải toàn bộ giao dịch). Con/cha suy từ list danh mục (đã gồm ẩn — con ẩn vẫn tính "có con").
- **Phương án khác**: tải toàn bộ `allTransactions()` rồi lọc trong Dart — đọc thừa bảng lớn hơn cần; `selectOnly`/`.count()` gọn hơn. Không tách repository riêng cho danh mục (seam `WalletRepository` đã chứa nhóm category read — giữ một chỗ, ít file).
- **Giới hạn thừa nhận**: dòng giao dịch cũ của DB nâng cấp `< v4` giữ `category_id = null` (chỉ có text snapshot) → danh mục chỉ được text-snapshot tham chiếu không bị tính là "đã gắn". Mọi đường ghi hiện tại (seed v4 + PBI 11 `addTransaction`) đều set `category_id`; chấp nhận cho dev-DB, ghi quickstart.

## R4 — Seam ghi danh mục (insert/update) & nơi tính sortOrder

- **Quyết định**: thêm 2 method ghi vào `WalletRepository`:
  - `Future<Category> insertCategory(Category category)` — drift bỏ qua `id` (DB tự sinh), ghi nguyên các trường đã chốt (gồm `isHidden` từ công tắc; `isSystem = false` cho danh mục tự tạo), trả `Category` đã lưu.
  - `Future<Category> updateCategory(Category category)` — `update where id`, ghi tất cả trường nghiệp vụ (gồm `isHidden`, `isSystem` giữ giá trị dòng đang sửa — không tự đổi).
  - Cả hai **không tự validate/không tự tính order** — bám nguyên tắc seam hiện có: "validation nghiệp vụ do rules/UI đảm nhận, repository không tự chặn" (xem `performTransfer`/`addTransaction`).
- **Nơi tính sortOrder**: module **thuần** — lúc lưu, form tính `sortOrder` mới: nếu cùng nhóm (type + parentId) → giữ `sortOrder` cũ; nếu đổi nhóm (đổi cha hoặc đổi loại khi được phép) → `endOfGroupSortOrder(group)` = `max(sortOrder nhóm đích) + 1` (0 nếu nhóm rỗng), thêm helper vào module thuần. Repo ghi literal.
- **Lý do**: nhóm định danh = `(type, parentId)`; "thêm vào cuối nhóm" (doc §4.2/FR-009) là luật thuần → đưa về module test được, không nhân đôi logic drift/fake. App offline 1 user, form là route độc quyền (không screen khác ghi danh mục đồng thời — picker "Thêm mới" PBI 11 no-op, list con `03` chưa có) → snapshot đọc lúc mở form là trạng thái hiện tại lúc lưu (FR-011), không cần repo đọc-giữ trong transaction.
- **Phương án khác**: repo tự đọc max trong `db.transaction` khi insert/update — an toàn hơn khi có đa writer nhưng offline không có; logic nhân đôi drift/fake, thêm đường thất bại. Chọn thuần.
- **Bất biến dữ liệu** (chặn ở validator + UI, không ở DB): không trùng tên trong cùng nhóm kể cả ẩn; con cùng loại cha; có con luôn là gốc (2 cấp); loại đổi chỉ khi "sạch" (chưa gd + không con + đang gốc). Không có unique constraint DB cho name/group (schema v4) — chính là lý do validator buộc chặt.

## R5 — Luồng kiểm tra hợp lệ & lưu (module thuần + UI)

- **Quyết định**: file mới `core/category/category_form.dart` (thuần, bám `add_form.dart` PBI 11) chứa:
  - `categoryNameError({raw, siblings})` — trim; rỗng/trắng → "Tên danh mục không được để trống" (acceptance 12); trùng tên trong nhóm (cùng `type` + `parentId` — 2 null bằng nhau; gồm bản ẩn) ngoại trừ `excludeId` (sửa bỏ chính nó — edge) → báo lỗi, chặn lưu.
  - `endOfGroupSortOrder(group)` (R4).
  - `canChangeType({hasTransactions, hasChildren, isParent})` = `!hasTransactions && !hasChildren && isParent` (FR-002/008; sửa con = `isParent=false` → luôn khóa).
  - `parentsOfType(list)` — cấp 1 của list, sort `sortOrder` (wrap `topLevelParents` sẵn có) → nguồn cho ô "Danh mục cha" (FR-006, lọc theo loại đang chọn).
- **Trạng thái UI khi lưu**: `_saving` bool chặn lưu trùng khi chạm nhanh (FR-011); lưu xong `Navigator.pop(saved)`; lỗi bất ngờ → SnackBar coral "Không lưu được danh mục…", giữ dữ liệu đã nhập (bám form ví FR-014).
- **Lý do**: validation tách khỏi widget để unit test nhanh (pattern PBI 11/13); text lỗi dưới ô tên (FR-010) qua validator của `TextFormField`. TextField `maxLength: 30` chặn nhập quá 30 (acceptance "không nhập thêm được"); trim khi so trùng & lưu (FR-003).
- **Phương án khác**: validate rải trong widget — khó test; bỏ qua — vi phạm FR/SC.

## R6 — Hình thức widget (bám mockup `02` + design system)

- **Quyết định**: màn con `CategoryFormScreen` (StatefulWidget, seam `repository` như list/picker) dùng `SubPageScaffold` — đã có `actions` (nút "Lưu" trắng góc phải app bar, mockup) + `bottomNavigationBar` (nút chính teal cao 44 bo 8 "Lưu danh mục", mockup — pattern `wallet_form_screen`); **không** FAB, không bottom nav. Tiêu đề "Thêm danh mục" / "Sửa danh mục" theo chế độ.
- **Loại**: pill bo 20 hai nửa Chi tiêu/Thu nhập — nửa chọn nền teal chữ trắng, nửa kia `softCardBg` chữ xám (mockup `F1EFE8`/teal/`9B9B9B`). Chế độ Thêm bấm đổi được; chế độ Sửa khi khóa → hiện dạng **readonly box** (đúng pattern form ví `_ReadonlyValue` — tỏ rõ không tương tác, tránh giao diện mồi bấm nhưng im lặng).
- **Tên**: `TextFormField` + validator R5, `maxLength 30`.
- **Biểu tượng**: lưới `Wrap` ô tròn 40 (chọn: nền `tealLightBg` + viền teal 2; chưa: `softCardBg`), glyph qua `categoryIcon` — bám `_IconPicker` form ví (thay emoji bằng `Icon`). Một ô luôn chọn sẵn (FR-005).
- **Màu sắc**: lưới `Wrap` ô tròn ~34; chọn: viền đậm + dấu kiểm trắng (mockup: ring `#1A1A1A` + check); một ô luôn chọn sẵn (FR-005).
- **Danh mục cha**: ô bấm hiển thị lựa chọn hiện tại — "Không có — là danh mục gốc" khi null, tên cha khi có; bấm mở **bottom sheet** liệt kê các cha cấp 1 cùng loại đang chọn (gồm cả cha ẩn — FR-006 không loại; nguồn từ cache), mỗi dòng bubble icon + tên; chọn → set, đóng. Có lựa chọn "Không có — là danh mục gốc" ở đầu để bỏ cha. Đổi loại → đưa cha về "Không có" (acceptance 5).
- **Ẩn**: `SwitchListTile` "Ẩn khỏi danh sách nhanh" — nền `softCardBg` bo 10, teal khi bật (pattern `_DefaultSwitch` form ví). Thêm: tắt sẵn; Sửa: theo `category.isHidden` (edge: đang ẩn → bật sẵn).
- **Cuộn/đa cỡ**: thân `ListView` trong `Form`; safe area; cỡ chữ lớn không vỡ (dùng `FittedBox`/Wrap như list `01`; nút chính cố định chân màn không bị che — SC-008).
- **Lý do**: mọi control có sẵn precedent trong code (`wallet_form_screen`); tái dùng hơn viết mới, bám đúng mockup + token. Parent picker dùng bottom sheet chuẩn Flutter thay vì dropdown tùy biến (danh sách cha có icon/màu dài, cuộn được, dễ test).
- **Phương án khác**: `DropdownButton`/`showDialog` cho cha — khó render bubble + tên dài; giữ sheet.

## R7 — Chế độ Sửa: prefill & luật khóa trường

- **Quyết định**: khi `category != null` màn nạp sẵn 100% (name/type/icon/color/parentId/isHidden). Cache nạp **1 lần cả 2 loại** (Future.wait) + `categoryHasTransactions(id)` khi mở (chỉ Sửa). Khóa:
  - Loại: khóa khi `!canChangeType(...)` (R5). Được đổi (gốc sạch không con) → đổi loại đưa cha về "Không có" và khi lưu về cuối nhóm gốc loại đích (acceptance 7).
  - Cha: khóa (không mở sheet) khi **có con** (FR-008 — có con luôn gốc); danh mục con khi được entry từ list con `03` (PBI sau) vẫn cho **đổi cha** (đang gốc? không — con đổi cha sang cha khác cùng loại hoặc bỏ cha → gốc) — form dựng đủ, reuse sau.
  - Con **không** được khóa cha khi là con (chỉ khóa loại)? FR-008: "danh mục là con không cho đổi loại" nhưng đổi cha được (acceptance 10 mô tả sửa con đổi cha/bỏ cha). Cha picker khi sửa con: loại trừ chính nó và (cha hiện tại?) cho phép chọn cha khác cùng loại hoặc "Không có"; loại trừ các cha đang là con của nó — không xảy ra (con không có con). Exclude self.
- **Lý do**: khóa đúng theo điều kiện (spec FR-002/008, chốt "sạch"), form vừa đủ cho entry hiện tại vừa để màn con `03` sau tái dùng không sửa lại.
- **Phương án khác**: khóa cứng mọi thứ ngoài tên/icon/màu — phá acceptance 7/10 (đổi loại/con đổi cha).

## R8 — Đánh giá lại ràng buộc lúc lưu (FR-011)

- **Quyết định**: ngoài validate form, không cần đọc lại DB khi lưu: app offline 1 user, danh mục chỉ bị ghi bởi chính form này (không screen khác); giao dịch mới không thể sinh ra giữa lúc form mở (form là route đè toàn màn, muốn thêm gd phải thoát form → mở lại = snapshot mới). Do đó snapshot nạp lúc mở form + `hasTransactions` đã là "trạng thái hiện tại" tại thời điểm lưu. Khóa double-save bằng cờ.
- **Lý do**: trường hợp biên spec (danh mục vừa phát sinh giao dịch đầu tiên giữa lúc sửa) không thể xảy ra trong luồng thật offline; nếu sau này có đa-writer (màn con `03` thêm con song song) sẽ xử lý bằng re-check lúc đó. Không thêm phức tạp dự phòng hôm nay.
- **Phương án khác**: mỗi lần lưu đọc lại `hasTransactions` + nhóm — vô hại nhưng thừa (không có đường đổi state), trái lười.
