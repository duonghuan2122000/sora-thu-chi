# Kế hoạch triển khai: Màn sắp xếp danh mục

**Mã PBI**: 16
**Liên kết spec**: .specify/specs/16/spec.md
**Ngày tạo**: 2026-09-06

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–15) |
| Framework / Thư viện chính | Flutter Material — **`ReorderableListView` built-in** (không thêm package); GetX **chỉ** cho DI repository (`ensureWalletRepository`); màn `StatefulWidget` + seam repository inject (pattern PBI 13/15); tái dùng `SubPageScaffold`, `CategoryRow`, `AppColors`, `categoryIcon`, hàm thuần `topLevelParents` |
| Lưu trữ dữ liệu | **Không đổi schema** (drift schemaVersion giữ **4**, không chạy `build_runner`); tận dụng cột `sort_order` có sẵn; thêm **1 seam ghi** mới `reorderCategories(orderedIds)` (interface + drift + fake) — mọi seam đọc cũ giữ nguyên |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit thuần (`category_sort`: index-math `moveCategoryAt` — kéo lên/xuống, ranh giới, thả cuối), widget (`category_sort_screen`: bố cục mockup `04` + chỉ cha đúng loại + dòng ẩn + drag handle → ghi + về `01` đúng tab/thứ tự mới), sửa `category_list_screen` (icon sắp xếp no-op → mở màn sắp xếp), fake repository (+ method mới); chạy lại toàn bộ — không hồi quy PBI 11–15 |
| Nền tảng triển khai | Android (kiểm chứng chính); widget thuần + không đổi plugin/native — iOS rủi ro thấp |
| Ràng buộc hiệu năng | SC-001: màn hiển thị < 1 s với vài trăm danh mục → nạp 1 loại 1 lần khi mở, lọc cha cấp 1 local bằng `topLevelParents`; kéo–thả `ReorderableListView.builder` lazy; không phân trang |
| Ràng buộc khác | App offline; chỉ sau mở khóa (PBI 3 — không làm thêm). Màn không số tiền. Design system: app bar teal qua theme, token `AppColors`, **không hex cứng** trong widget; màu danh mục là dữ liệu `category.color`. Tài liệu & commit tiếng Việt có dấu |

*Không còn `NEEDS CLARIFICATION` — spec đã chốt; quyết định thiết kế (R1–R10) ở research.*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Danh mục]]/[[Design system]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | Ghi drift local; không gọi mạng; không thêm dependency |
| Đúng stack đã chốt (drift + GetX), không thêm thư viện | ✅ | `ReorderableListView` là Material built-in; GetX chỉ DI; không package mới |
| Số dư ví là đại lượng suy ra / không đụng ví | ✅ | Không chạm `wallets`/`transactions` — chỉ ghi `categories.sort_order` |
| Tái dùng hơn viết mới | ✅ | `ReorderableListView`, `SubPageScaffold`, `CategoryRow` (+2 param optional), `topLevelParents`, `_reloadSilent`, seam pattern; chỉ thêm 1 màn + 1 seam ghi + 1 module thuần nhỏ |
| Danh mục: 2 cấp cha-con, ẩn giữ lịch sử | ✅ | Màn sắp xếp chỉ cha cấp 1 đúng loại (FR-003/004); danh mục ẩn vẫn hiện + kéo được kèm dấu phân biệt (chốt spec); con không xuất hiện/không đổi (acceptance 5) |
| Danh mục hệ thống không xóa được | ✅ | Cha hệ thống hiện & sắp xếp bình thường (FR-004) — không xóa/gộp trong màn này |
| Mỗi PBI một màn; điểm vào no-op kích hoạt khi tới PBI | ✅ | Icon "Sắp xếp" no-op (PBI 13) → mở màn `04`; màn danh mục con `03` chưa có entry sắp xếp (giữ — ngoài phạm vi) |
| Design system (teal, bo, token, không hex cứng) | ✅ | Khung app bar qua theme; nút "Xong"/handle dùng token; màu dòng là `category.color` (dữ liệu) |
| Không số liệu minh họa giả | ✅ | Không seed mới — seed "Ăn uống" + cha chi tiêu/thu nhập sẵn có đủ QA |
| Test không phụ thuộc sqlite native | ✅ | Widget test bơm `FakeWalletRepository` (có method ghi mới); unit thuần cho index-math |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |
| Cập nhật wiki sau implement | ⚠️ | PBI 16 chạm entity [[Danh mục]] (màn `04` từ "PBI sau" → đã triển khai; `sort_order` thành dữ liệu ghi được khi kéo–thả; entry từ màn `01`) + [[Lộ trình]]. Sync qua skill `sora-wiki` + `log.md` sau implement |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **`ReorderableListView` built-in** (không package mới), `buildDefaultDragHandles: false`
  + `ReorderableDragStartListener` bọc **icon tay cầm** → kéo chỉ bằng tay cầm, autoscroll
  gần mép có sẵn (R1/R2).
- **Seam ghi mới `reorderCategories(orderedIds)`** — ghi atomic `sort_order = 0..n−1` cho
  cha cấp 1 của một loại trong một transaction; ghi ngay khi thả (FR-006) (R3).
- **Chỉ đánh lại cha cấp 1 đúng loại** — con cấp 2 & loại kia bất biến; mọi consumer xếp
  theo nhóm con (đã quét xác minh) nên thứ tự hiển thị nhất quán mọi nơi (R4/R6).
- **Tái dùng `CategoryRow`** thêm 2 param optional `leading` + `showChevron` — không nhân
  bản dòng danh mục; màn `01`/`03` không đổi (R5).
- **Helper thuần `moveCategoryAt`** (index-math ReorderableListView) + unit test biên (R7).
- **Khung `SubPageScaffold`** + "Xong" trong `actions`; back/"Xong" đều pop, không xác nhận
  (R8). **Điểm vào** = icon sắp xếp màn `01` → push màn `04` theo `_tab`, sau pop
  `_reloadSilent()` (R9). **Không đổi schema/seam đọc cũ** (R10).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — **không đổi schema** (v4); tận dụng
  `Categories.sort_order`; bất biến "thứ tự theo nhóm con" giữ nguyên; seam ghi mới
  `reorderCategories` chỉ tác động cha cấp 1 của một loại.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI
  (bám PBI 7–15).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–H đối chiếu
  acceptance/FR/SC; drag thật QA tay emulator (widget test drag-handle giới hạn).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 1 màn (`04`) + 1 seam ghi + 1 module thuần nhỏ (`category_sort.dart`) + 2 param optional `CategoryRow` + nối điểm vào màn `01`; không controller/service/event bus; **không đổi schema/repository đọc cũ** |
| Đúng seam cho test | ✅ | `CategorySortScreen` nhận `repository` (mặc định `ensureWalletRepository`) — test bơm fake; fake cài `reorderCategories` + lộ `categoriesStored` → widget test assert thứ tự store sau kéo |
| Không hồi quy PBI 13/14/15 | ✅ | Màn `01` chỉ đổi `onPressed` no-op icon sort → push (không đụng tab/dòng/FAB/reload); `CategoryRow` chỉ **thêm** param optional (default giữ chevron/không leading) → màn `01`/`03` & test cũ không đổi. Chạy lại toàn bộ test |
| Tái dùng > viết mới | ✅ | `ReorderableListView`/`SubPageScaffold`/`CategoryRow`/`topLevelParents`/`_reloadSilent`/seam pattern; không viết lại bubble/ẩn/màn khung |
| Ràng buộc cây 2 cấp / cùng loại / ẩn giữ lịch sử / tên duy nhất | ✅ | Màn `04` không sinh cấp 3, không trộn loại, không kéo cha-con; không đụng validator/khóa tên của màn `02` |
| Không làm hỏng dữ liệu | ✅ | Chỉ ghi `sort_order` các dòng cha trong list (atomic); con & loại kia & tham chiếu giao dịch/ngân sách bất biến; back không ghi thêm (đã ghi khi thả) |
| Khóa app không lộ thông tin | ✅ | Màn route trong shell sau boot-gate (PBI 3), không số tiền — không làm thêm |
| Cập nhật wiki | ⚠️ | Sau implement sync entity [[Danh mục]] + [[Lộ trình]] + `log.md` (qua skill `sora-wiki`) |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── category/
│   │   │   ├── category_sort.dart                # [TẠO] (R7): thuần moveCategoryAt(list, oldIndex, newIndex)
│   │   │   │                                          — điều chỉnh newIndex > oldIndex → −1, removeAt+insert
│   │   │   │                                          (ngữ nghĩa ReorderableListView); không đọc DB
│   │   │   └── (không đổi) category.dart, category_list.dart, category_form.dart, category_source.dart, presets
│   │   └── widgets/
│   │       ├── category_row.dart                  # [SỬA] (R5): + Widget? leading (trước bubble) + bool showChevron=true
│   │       └── (không đổi) sub_page_scaffold.dart, category_icon.dart
│   ├── data/
│   │   ├── wallet_repository.dart                 # [SỬA] (R3): + Future<void> reorderCategories({required List<int> orderedIds})
│   │   ├── wallet_repository_drift.dart           # [SỬA] (R3): db.transaction() — với mỗi id theo thứ tự list,
│   │   │                                               update categories set sort_order = index (0..n−1)
│   │   └── (không đổi) wallet_deps.dart, transaction_deps.dart, db/*
│   └── screens/
│       ├── category_sort_screen.dart              # [TẠO] (R1/2/6/8): CategorySortScreen{required initialType, repository?}
│       │                                               StatefulWidget: initState nạp categoriesIncludingHidden(initialType)
│       │                                               → _rows = topLevelParents(list); loading/error+Thử lại/empty phòng thủ;
│       │                                               SubPageScaffold('Sắp xếp danh mục', actions:[TextButton 'Xong' → pop],
│       │                                               child: SafeArea(top:false, ReorderableListView.builder(
│       │                                               buildDefaultDragHandles:false, itemCount:_rows.length, itemBuilder:
│       │                                               CategoryRow(key: ValueKey('sort-row-${c.id}'), category:c,
│       │                                                 leading: ReorderableDragStartListener(index:i,
│       │                                                   child: Icon(Icons.drag_handle, …)), showChevron:false,
│       │                                                   onTap: (){}), proxyDecorator: …nổi nhẹ,
│       │                                               onReorder: (o,n){ final moved=moveCategoryAt(_rows,o,n);
│       │                                                 setState(_rows=moved); _persist(); })));
│       │                                               _persist(): gọi reorderCategories(orderedIds: _rows.map(id)) —
│       │                                               lỗi → _load() đồng bộ lại (R7)
│       ├── category_list_screen.dart               # [SỬA] (R9): icon sort no-op → push CategorySortScreen(initialType:_tab,
│       │                                               repository:_repository) rồi _reloadSilent(); cập nhật doc comment
│       └── (không đổi) category_child_list_screen.dart, category_form_screen.dart, category_picker_screen.dart, …
└── test/
    ├── fakes/fake_wallet_repository.dart           # [SỬA] (R3): + reorderCategories — với id trong orderedIds đặt
    │                                                   sortOrder = index (đổi trong _categories); giữ nguyên phần tử khác;
    │                                                   categoriesStored có sẵn để assert
    ├── category_sort_test.dart                     # [TẠO] (R7): unit moveCategoryAt — kéo lên/xuống, kéo qua nhiều dòng,
    │                                                   newIndex == length (thả cuối), oldIndex == newIndex không đổi
    ├── category_sort_screen_test.dart              # [TẠO] widget fake (+categoriesSeed): bố cục mockup 04 (app bar back +
    │                                                   tiêu đề 'Sắp xếp danh mục' + 'Xong' phải, không tab/bottom nav);
    │                                                   chỉ cha cấp 1 đúng initialType theo thứ tự seed (không con/loại kia);
    │                                                   dòng ẩn hiện đúng vị trí + 'Đã ẩn'; mỗi dòng có tay cầm; drag tay
    │                                                   cầm → reorderCategories gọi + UI đổi thứ tự (R2); empty phòng thủ;
    │                                                   cỡ chữ lớn không overflow; scope find trong màn con (màn 01 đè dưới)
    ├── category_list_screen_test.dart               # [SỬA] (R9): case 'icon sort no-op' → 'tap icon → mở CategorySortScreen
    │                                                   với đúng tab'; back từ màn sắp xếp → đúng tab + thứ tự mới hiện
    ├── category_row_test.dart                       # [SỬA hoặc TẠO nếu chưa có]: case leading render + showChevron:false
    │                                                   bỏ chevron (nếu hiện có test row — ngược lại phủ qua sort screen test)
    └── (không đổi) category_list_test.dart, category_child_list_screen_test.dart,
        category_form_screen_test.dart, category_form_test.dart, category_presets_test.dart,
        category_picker_screen_test.dart, wallet_*/transaction_*/settings_*/pin tests — chạy lại
```

Không đổi: `core/category/*` (category, category_list, category_form, category_source,
category_presets), `core/widgets/category_icon.dart`, `sub_page_scaffold.dart`, `data/*`
(repository đọc, drift đọc, db/*, deps), `theme/*`, `category_picker_screen.dart`,
`add_transaction_screen.dart`, `category_child_list_screen.dart`, `category_form_screen.dart`,
`transaction_*`, `wallet_*`, màn PIN/boot, `app_shell.dart`, `settings_screen.dart`.

## Rủi ro & ngoại lệ có lý do

- **Widget test kéo–thả có thể flaky** — ReorderableListView + `ReorderableDragStartListener`
  (drag tức thì từ handle) thường driver được bằng gesture, nhưng autoscroll/thả vị trí xa
  khó ổn định trong widget test. Phòng: unit test `moveCategoryAt` phủ hết biên index-math;
  widget test kéo một bước ngắn giữa 2 dòng kề nhau để xác nhận `reorderCategories` gọi +
  UI đổi; các kịch bản kéo xa/tự cuộn QA tay (quickstart C4). Không phải rào cản.
- **`ReorderableListView` chỉ cho phép 1 thứ tự phẳng** — đúng nhu cầu (cha cấp 1, không
  nhóm con, không cây). Kéo chéo loại/cấp nằm ngoài màn (FR-005) — không xử lý đặc biệt.
- **Nút "Xong" = `TextButton` trong `actions`** — hình thức text trắng trên app bar teal
  theo mockup; khác chút nếu mockup dùng nút nhỏ bo — tinh chỉnh lúc QA visual (SC-002).
- **Không lưu bản nháp — ghi mỗi lần thả** — đúng FR-006; mỗi thả 1 transaction ghi toàn bộ
  nhóm cha (n dòng). Bảng nhỏ local nên chi phí không đáng kể; bỏ tối ưu "chỉ ghi đoạn đổi"
  (`ponytail:` — thêm khi nhóm cha phình bất thường, chưa cần).
- **Lỗi ghi khi thả hiếm** (DB local) — xử lý bằng `_load()` đồng bộ lại (danh sách trở về
  thứ tự DB), không hiện dialog phức tạp; test seam ở drift + fake.
- **iOS chưa verify** (máy Windows): widget thuần + không đổi plugin/native — rủi ro thấp,
  giữ trạng thái.
- **Wiki cần sync sau implement** — màn `04` đã triển khai (bố cục, entry màn `01`, kéo–thả
  cha cấp 1, `sort_order` ghi khi thả, danh mục ẩn vẫn sắp được); dùng skill `sora-wiki` +
  `log.md` — chưa làm trong đợt code.

## File đã tạo

- `.specify/specs/16/research.md`
- `.specify/specs/16/data-model.md`
- `.specify/specs/16/quickstart.md`
- `.specify/specs/16/plan.md`

Bước tiếp theo: chạy `/sora-task 16` để phân rã thành tasks.md.
