# Kế hoạch triển khai: Màn hình thêm / sửa danh mục

**Mã PBI**: 14
**Liên kết spec**: .specify/specs/14/spec.md
**Ngày tạo**: 2026-09-05

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–13) |
| Framework / Thư viện chính | Flutter Material; GetX **chỉ** cho DI repository (`ensureWalletRepository`); màn `StatefulWidget` + seam repository inject (pattern PBI 13 `CategoryListScreen`/PBI 11 `CategoryPickerScreen`); module **thuần** `category_form.dart`/`category_presets.dart`; tái dùng `SubPageScaffold` (actions + bottomNavigationBar), `AppColors`, `categoryIcon`, `_IconPicker`/`_ColorPicker`/`_ReadonlyValue`/`_DefaultSwitch`-style từ `wallet_form_screen` |
| Lưu trữ dữ liệu | **Không đổi schema** (drift schemaVersion giữ **4**, không chạy `build_runner`); **ghi** vào bảng `categories` đã có qua 2 seam ghi mới `insertCategory`/`updateCategory` + 1 seam đọc `categoryHasTransactions` (bổ sung interface + `DriftWalletRepository` + fake) |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit thuần (`category_form`, `category_presets`), widget (`category_form_screen` add/edit; `category_list_screen` sửa: FAB/dòng đã nối màn `02` + refresh), fake repository biến đổi được (store list + method mới); chạy lại toàn bộ test cũ — không hồi quy PBI 5/6/8/11/12/13 |
| Nền tảng triển khai | Android (kiểm chứng chính); widget thuần + không đổi plugin/native — iOS rủi ro thấp |
| Ràng buộc hiệu năng | SC-001: màn thêm/sửa hiển thị < 1 s → nạp cache 2 loại 1 lần khi mở, đổi loại/pill/cha lọc local, không đọc DB lại; không cần phân trang (bảng nhỏ local) |
| Ràng buộc khác | App offline; chỉ sau mở khóa (PBI 3 — không làm thêm). Design system: teal `#0F6E56` hành động/chọn-bật, pill & switch; **màu danh mục là dữ liệu** `category.color` → bảng màu form là hằng dữ liệu tập trung + token `AppColors.category*` cho mã mockup mới (không hex cứng trong widget). Màn không số tiền. Tài liệu & commit tiếng Việt có dấu |

*Không còn `NEEDS CLARIFICATION` — spec checklist đạt; bộ icon/màu cụ thể là quyết định thiết kế chốt ở R2 (hợp 2 nguồn, có bất biến test).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Danh mục]]/[[Design system]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | drift SQLite local; không gọi mạng; không thêm dependency |
| Đúng stack đã chốt (drift + GetX), không thêm thư viện | ✅ | Ghi drift thuần trên bảng đã có; GetX chỉ DI; không package mới |
| Số dư ví là đại lượng suy ra | ✅ | Không đụng `wallets.balance`/cột giao dịch — chỉ đếm `category_id` (đọc) |
| Tái dùng hơn viết mới | ✅ | Tái dùng `Category`, `categoryIcon`, `category_list.dart` (topLevelParents/childrenOf), `SubPageScaffold`, `ensureWalletRepository`, pattern widget picker/switch/readonly của `wallet_form_screen`; chỉ thêm 2 module thuần + 1 màn + 3 seam + 8 token màu |
| Danh mục: 2 cấp cha-con, con cùng loại cha, ẩn giữ lịch sử | ✅ | Chặn cấp 3 (cha picker chỉ cấp 1); loại con = loại cha (khóa đổi loại con); ẩn = rút khỏi picker gd mới nhưng giữ trên màn quản lý & gd lịch sử |
| Tên duy nhất trong nhóm (cha/loại) kể cả ẩn | ✅ | Validator `categoryNameError` chặn trùng cùng `(type, parentId)` gồm bản ẩn, sửa bỏ chính nó; không có unique DB — chặn ở nghiệp vụ |
| Khóa đổi loại khi đã gắn giao dịch / có con / là con | ✅ | `canChangeType` (chưa gd + không con + gốc); UI khóa ô loại đúng chốt spec |
| Danh mục hệ thống sửa được tên/icon/màu/ẩn, không xóa | ✅ | Form không có xóa (ngoài phạm vi); `isSystem` giữ nguyên khi update; isSystem=false khi thêm mới |
| Design system (teal, bo, token, không hex cứng) | ✅ | Nút/pill/switch teal token; mã mockup mới thêm `AppColors.category*`; bảng màu form là list hằng dữ liệu tập trung |
| Không số liệu minh họa giả | ✅ | Không seed mới; icon/màu chọn từ bộ có sẵn, data thật từ danh mục |
| Test không phụ thuộc sqlite native | ✅ | Unit/widget bơm `FakeWalletRepository` (giờ biến đổi được); method ghi drift không có DAO test riêng — logic ghi phủ qua widget+unit |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |
| Cập nhật wiki sau implement | ⚠️ | PBI 14 chạm entity [[Danh mục]] (màn `02` chuyển từ "PBI sau" → đã triển khai; thêm seam ghi + presets + màn Sửa luật khóa). Sync qua skill `sora-wiki` + `log.md` sau implement |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Điểm vào & refresh** — FAB "+" → form Thêm `initialType = tab`; chạm dòng **không con** → Sửa; danh mục **có con** giữ no-op (màn con `03` PBI sau); sau pop form list nạp lại lặng cả 2 loại (R1).
- **Bộ icon & bảng màu** — `category_presets.dart`: `categoryIconChoices` = 15 khóa map `categoryIcon`; `categoryPresetColors` = hợp màu seed dữ liệu + 8 màu mockup `02` (thêm 8 token `AppColors.category*`) → sửa danh mục hiện có luôn chọn lại được màu cũ; bất biến test seed ⊆ choices (R2).
- **Seam ghi + đọc** — thêm `insertCategory`/`updateCategory` (ghi literal, không tự validate/không tự tính order — bám seam hiện có) và `categoryHasTransactions(id)`; nhóm = `(type, parentId)`, "cuối nhóm" tính bằng module thuần `endOfGroupSortOrder` (R3/R4).
- **Validation & lưu** — module thuần `category_form.dart`: `categoryNameError` (trống/trùng nhóm gồm ẩn/bỏ self), `endOfGroupSortOrder`, `canChangeType`, `parentsOfType`; UI chặn lưu trùng bằng cờ `_saving`; snapshot lúc mở = trạng thái hiện tại lúc lưu (offline, route độc quyền — R5/R8).
- **Hình thức widget** — form dùng `SubPageScaffold` (actions "Lưu" + bottomNavigationBar nút chính "Lưu danh mục"), pill loại bo 20, lưới icon tròn 40 (chọn viền teal + nền nhạt), lưới màu tròn ~34 (chọn viền đậm + dấu kiểm), ô cha mở bottom sheet cấp 1 cùng loại, switch ẩn; chế độ Sửa prefill 100%, loại khóa → readonly box (R6/R7).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — **không đổi schema** (v4); domain `Category` dùng lại; thêm 3 seam (2 ghi literal + 1 đếm), 2 module thuần (`category_presets`, `category_form`), nhóm/order/khóa/save-plan.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (bám PBI 7–13).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–I đối chiếu acceptance/FR/SC; QA tay cover entry Thêm + Sửa cấp 1 không con; entry con/có-con phủ bằng widget test pump trực tiếp.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 2 module thuần + 1 màn + 3 seam + 8 token + sửa nhẹ `category_list_screen` (nối điểm vào); không service/event bus/controller mới; **không đổi schema/repository đọc cũ** |
| Đúng seam cho test | ✅ | `CategoryFormScreen` nhận `repository` (mặc định `ensureWalletRepository`) — test bơm fake; fake giữ bộ danh mục **biến đổi** + đếm giao dịch → test ghi qua widget assert store (như `addTransaction` PBI 11) |
| Không hồi quy PBI 5/6/8/11/12/13 | ✅ | `categories()`, picker PBI 11, filter PBI 12, màn `01` giữ nguyên (chỉ thay no-op FAB/dòng không con bằng push form + refresh); `CategorySource`/`category_icon` không đổi; `Category` không thêm field. Chạy lại toàn bộ test |
| Tái dùng > viết mới | ✅ | Wrap `category_list.topLevelParents`/`childrenOf` cho danh sách cha & đếm con; tái dùng `categoryIcon`, `SubPageScaffold`, token; pattern icon/màu/switch/readonly/lỗi-bảo-lưu từ `wallet_form_screen` |
| Ràng buộc cây 2 cấp / cùng loại / tên duy nhất / ẩn giữ lịch sử | ✅ | Validator + khóa UI (R5/R7); không sinh cấp 3/mồ côi/lệch loại (SC-004/005) |
| Không làm hỏng dữ liệu khi thêm/sửa | ✅ | Ghi trong phạm vi trường form; `isSystem` bảo toàn khi sửa; không xóa; back/before-save không ghi (SC-007) |
| Khóa app không lộ thông tin | ✅ | Màn route trong shell sau boot-gate (PBI 3), không số tiền — không làm thêm |
| Cập nhật wiki | ⚠️ | Sau implement sync entity [[Danh mục]]: màn `02` đã triển khai (Thêm/Sửa + luật khóa), seam ghi + `categoryHasTransactions`, presets icon/màu; append `log.md` |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── category/
│   │   │   ├── category_form.dart               # [TẠO] thuần (R5): categoryNameError (trim/trống/trùng nhóm
│   │   │   │                                       gồm ẩn, bỏ excludeId), endOfGroupSortOrder, canChangeType,
│   │   │   │                                       parentsOfType (wrap topLevelParents)
│   │   │   └── category_presets.dart            # [TẠO] (R2): categoryIconChoices (15 khóa), defaultIconFor/
│   │   │                                           defaultColorFor theo type, categoryPresetColors (13 màu dữ liệu)
│   │   ├── widgets/sub_page_scaffold.dart       # (không đổi — đã có actions + bottomNavigationBar + FAB)
│   │   └── (không đổi) category.dart, category_source.dart, category_icon.dart, category_list.dart
│   ├── data/
│   │   ├── wallet_repository.dart               # [SỬA] + categoryHasTransactions(int) (R3)
│   │   │                                           + insertCategory(Category) + updateCategory(Category) (R4)
│   │   ├── wallet_repository_drift.dart         # [SỬA] + impl: count transactions.category_id==id;
│   │   │                                           insert CategoriesCompanion (isSystem false, isHidden theo form,
│   │   │                                           bỏ qua id — DB sinh); update where id ghi đủ trường nghiệp vụ;
│   │   │                                           trả dòng đã lưu (như insert/update ví)
│   │   └── (không đổi) app_database*.dart, wallet_deps.dart, transaction_deps.dart
│   ├── screens/
│   │   ├── category_list_screen.dart            # [SỬA] (R1): FAB "+" → push form Thêm (initialType=_tab, cùng repo);
│   │   │                                           onTap dòng: không con → push form Sửa(category); có con → giữ no-op
│   │   │                                           (màn 03 sau); sau await push trả về → _refresh() lặng 2 loại
│   │   │                                           (bỏ màn loading; không đổi bố cục khác)
│   │   └── category_form_screen.dart            # [TẠO] (R5/6/7) StatefulWidget{initialType?, category?, repository?}:
│   │                                               initState nạp cache 2 loại (Future.wait categoriesIncludingHidden) +
│   │                                               hasTransactions (chỉ Sửa); SubPageScaffold(title theo chế độ,
│   │                                               actions: [TextButton "Lưu" trắng]) + bottomNavigationBar nút chính
│   │                                               "Lưu danh mục" teal cao44/bo8; body SafeArea+Form+ListView cuộn:
│   │                                               pill loại (Thêm đổi được / Sửa: loại sạch đổi, khóa → readonly box) →
│   │                                               TextFormField tên (maxLength 30, validator trùng/trống) → lưới
│   │                                               icon (Wrap tròn 40) → lưới màu (Wrap tròn ~34 check) → ô "Danh
│   │                                               mục cha (tùy chọn)" (bấm → bottom sheet cấp 1 cùng loại gồm ẩn,
│   │                                               loại self; đổi loại → về "Không có") → Switch "Ẩn khỏi danh sách
│   │                                               nhanh"; _save(): validate → tính sortOrder (cùng nhóm giữ /
│   │                                               đổi nhóm = endOfGroupSortOrder) → insert/update (cờ _saving chặn
│   │                                               trùng) → pop(saved); lỗi → SnackBar coral giữ dữ liệu
│   └── theme/app_colors.dart                     # [SỬA] + 8 token màu mockup 02: categoryOrange #F2994A, categoryBlue
│                                                    #2F80ED, categoryPurple #9B59B6, categoryYellow #F2C94C,
│                                                    categoryRed #EB5757, categoryCyan #56CCF2, categoryGreen #27AE60,
│                                                    categoryViolet #BB6BD9 (R2)
└── test/
    ├── fakes/fake_wallet_repository.dart        # [SỬA] (R4/data-model): đổi seed danh mục sang List<Category> biến đổi
    │                                               (bản sao) + _nextCategoryId; categories*/insert/update đọc-ghi store;
    │                                               categoryHasTransactions đếm _transactions; read-accessor
    │                                               categoriesStored (additive — test cũ không đổi)
    ├── category_presets_test.dart                # [TẠO] unit: bất biến seed ⊆ choices (icon ∈ categoryIconChoices,
    │                                               color ∈ categoryPresetColors); default per type ≠ null ∈ choices
    ├── category_form_test.dart                   # [TẠO] unit thuần (R5): tên rỗng/trắng; trùng cùng (type,parent) gồm
    │                                               ẩn; cùng tên khác loại/khác cha hợp lệ; sửa bỏ chính nó;
    │                                               endOfGroupSortOrder (rỗng=0, max+1); canChangeType 4 góc (gd/con/
    │                                               không-gốc → false; gốc sạch → true); parentsOfType sort + gồm ẩn
    ├── category_form_screen_test.dart            # [TẠO] widget fake repo:
    │                                               ADD: (a) mở với initialType → pill loại chọn đúng (chi/income),
    │                                               title/appbar Lưu/bottom nav không có; (b) trống tên báo lỗi, trùng
    │                                               "Ăn uống" báo lỗi chặn lưu; (c) icon/màu mặc định + đổi được; (d)
    │                                               chọn cha chi → chuyển Thu nhập → cha về "Không có", list cha chỉ
    │                                               thu; (e) lưu hợp lệ → insert vào store cuối nhóm (verify sortOrder/
    │                                               isHidden theo switch) + pop(saved); chạm lưu 2 lần → 1 lần;
    │                                               back → không insert.
    │                                               EDIT: (f) prefill 100% (tên/icon/màu/cha/ẩn bật); (g) danh mục
    │                                               sạch → đổi loại lưu về cuối nhóm mới; (h) hasTransactions=true →
    │                                               ô loại khóa + readonly (không đổi được), tên/icon/màu vẫn sửa;
    │                                               (i) danh mục có con → loại khóa + ô cha không mở (sheet không
    │                                               hiện); (j) sửa con (pump trực tiếp) → đổi cha/bỏ cha lưu nhóm đích;
    │                                               (k) giữ nguyên tên → lưu không báo trùng; (l) bật ẩn → lưu → store
    │                                               isHidden=true; (m) back → update không xảy ra.
    ├── category_list_screen_test.dart            # [SỬA]: (f) cũ "no-op dòng/FAB" → sửa thành: FAB push form Thêm với
    │                                               initialType=tab; dòng không con push form Sửa(category đó); dòng có
    │                                               con vẫn no-op; sau khi form trả về danh sách phản ánh (fake insert
    │                                               qua form rồi bấm back → list có dòng mới / tên đổi); giữ các case
    │                                               cũ khác (tab/ẩn/đếm/empty/...)
    └── (không đổi) wallet_*/transaction_*/category_picker_*/settings_*/pin/demo tests — chạy lại
```

Không đổi: `core/category/category.dart`, `category_source.dart`, `category_icon.dart`, `category_list.dart`, `data/db/app_database.dart` (+`.g.dart`), `sub_page_scaffold.dart`, `wallet_*` screens/controller, màn PIN/boot, `category_picker_screen.dart`, `add_transaction_screen.dart`, `transaction_*`, `app_shell.dart`, `wallet_deps.dart`/`transaction_deps.dart`, `settings_screen.dart`.

## Rủi ro & ngoại lệ có lý do

- **Bộ icon cố định 15 khóa (không thêm glyph mới)** — cố ý (R2): app chưa định nghĩa "kho icon" lớn hơn map `categoryIcon`; đủ phủ danh mục thường gặp & nhất quán dữ liệu đang hiển thị. Ceiling: khi cần danh mục đặc thù nhiều hơn → mở rộng `categoryIcon` + `categoryIconChoices` cùng lúc (test bất biến seed ⊆ choices không vỡ). Không phải rào cản PBI này.
- **Bảng màu 13 ô (5 seed + 8 mockup)** — hợp 2 nguồn để sửa danh mục hiện có luôn chọn lại được màu cũ; nhiều ô nhưng `Wrap` cuộn ổn, không cần case đặc biệt "màu ngoài palette" (R2).
- **`categoryHasTransactions` theo `category_id`, không theo text snapshot** — dòng giao dịch cũ DB nâng cấp `< v4` có `category_id = null` nên danh mục chỉ được text tham chiếu không bị khóa loại. Chấp nhận cho dev-DB; mọi đường ghi hiện tại (seed v4, PBI 11) set `category_id`. Ghi rõ quickstart (R3).
- **Snapshot lúc mở form = trạng thái lúc lưu (không re-check DB khi lưu)** — hợp lệ vì app offline 1 user + form là route độc quyền (không screen ghi danh mục/giao dịch đồng thời; muốn thêm gd phải thoát form → mở lại = snapshot mới). Nếu sau này màn con `03`/đa-writer mở ra → thêm re-check lúc đó (R8). Trường hợp biên spec về "phát sinh gd đầu tiên giữa lúc sửa" không thể xảy ra trong luồng thật.
- **Fake đổi sang store biến đổi** — mọi test trước chỉ đọc nên hành vi giữ; thêm read-accessor. Chạy lại toàn bộ test xác nhận không hồi quy PBI 11/12/13 (chung fake).
- **`category_list_screen_test` case no-op cũ thay đổi** — chủ đích (FAB/dòng không con giờ có hành động thật — nối màn `02`); cập nhật + bổ sung case refresh. Màn `01` còn lại không đổi.
- **Cập nhật test `settings_screen_test`?** — không: hàng "Danh mục" & điều hướng giữ nguyên từ PBI 13; màn `01` không đổi điểm vào shell.
- **iOS chưa verify** (máy Windows): widget thuần + không đổi plugin/native — rủi ro thấp, giữ trạng thái.
- **QA tay không phủ được sửa danh mục con/có con** — điểm vào ở màn `03` (PBI sau); phủ bằng widget test pump trực tiếp form (R7). Không phải rào cản PBI 14 — màn sửa dựng đủ để `03` tái dùng.

## File đã tạo

- `.specify/specs/14/research.md`
- `.specify/specs/14/data-model.md`
- `.specify/specs/14/quickstart.md`
- `.specify/specs/14/plan.md`

Bước tiếp theo: chạy `/sora-task 14` để phân rã thành tasks.md.
