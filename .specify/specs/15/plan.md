# Kế hoạch triển khai: Màn hình danh sách danh mục con

**Mã PBI**: 15
**Liên kết spec**: .specify/specs/15/spec.md
**Ngày tạo**: 2026-09-06

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–14) |
| Framework / Thư viện chính | Flutter Material; GetX **chỉ** cho DI repository (`ensureWalletRepository`); màn `StatefulWidget` + seam repository inject (pattern PBI 13 `CategoryListScreen`); widget chia sẻ mới `CategoryRow` (`core/widgets`) + tái dùng `Category`, `category_list.childrenOf`, `CategoryFormScreen` (PBI 14), `AppColors`, `categoryIcon`, `AppTheme` |
| Lưu trữ dữ liệu | **Không đổi schema** (drift schemaVersion giữ **4**, không chạy `build_runner`); màn `03` **chỉ đọc** qua seam có sẵn `categoriesIncludingHidden({type})`; ghi qua màn `02` (insert/update đã có). Không thêm seam repository |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: widget mới `category_child_list_screen` (bơm `FakeWalletRepository` biến đổi được); sửa widget `category_list_screen` (case no-op → mở màn con + refresh count) & `category_form_screen` (Thêm với `initialParentId`); chạy lại toàn bộ test — không hồi quy PBI 11/12/13/14 |
| Nền tảng triển khai | Android (kiểm chứng chính); widget thuần + không đổi plugin/native — iOS rủi ro thấp |
| Ràng buộc hiệu năng | SC-001: màn danh sách con hiển thị < 1 s → nạp 1 loại (`parent.type`) một lần khi mở, lọc con local bằng `childrenOf`, không đọc DB lại khi cuộn; không cần phân trang (bảng nhỏ local) |
| Ràng buộc khác | App offline; chỉ sau mở khóa (PBI 3 — không làm thêm). Màn không hiển thị số tiền. Design system: app bar teal qua `AppBarTheme`, token `AppColors`; **không hex cứng trong widget**. Tài liệu & commit tiếng Việt có dấu |

*Không còn `NEEDS CLARIFICATION` — spec checklist đạt; điểm mở duy nhất về hình thức (cách nhúng tiêu đề chạm được) là quyết định thiết kế chốt ở R3.*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Danh mục]]/[[Design system]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | Chỉ đọc drift local qua seam có sẵn; không gọi mạng; không thêm dependency |
| Đúng stack đã chốt (drift + GetX), không thêm thư viện | ✅ | Không seam/schema mới; GetX chỉ DI; màn StatefulWidget + seam (pattern PBI 13) |
| Số dư ví là đại lượng suy ra / không đụng ví | ✅ | Không chạm `wallets`/`transactions`; màn chỉ trình bày danh mục |
| Tái dùng hơn viết mới | ✅ | Tái dùng `childrenOf` (PBI 13), màn `02` nguyên vẹn (chỉ thêm param khởi tạo), seam `categoriesIncludingHidden`, `CategoryRow` trích từ `01` dùng chung `01`/`03` |
| Danh mục: 2 cấp cha-con, con cùng loại cha, ẩn giữ lịch sử | ✅ | Màn `03` liệt kê con trực tiếp cùng loại; con không có con (không đi sâu); con ẩn vẫn hiện + dấu phân biệt |
| Tên duy nhất trong nhóm / khóa loại / có con luôn gốc | ✅ | Giữ nguyên validator + khóa UI của màn `02` (PBI 14); màn `03` chỉ chọn điểm vào, không phá luật |
| Design system (teal, bo, token, không hex cứng) | ✅ | App bar teal qua theme; tiêu đề/nút token; dòng tái dùng `CategoryRow` dùng màu **dữ liệu** `category.color` |
| Không số liệu minh họa giả | ✅ | Không seed mới — seed hiện có "Ăn uống" + 3 con đủ vào màn `03` |
| Test không phụ thuộc sqlite native | ✅ | Widget test bơm `FakeWalletRepository` (giữ biến đổi được — PBI 14) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |
| Cập nhật wiki sau implement | ⚠️ | PBI 15 chạm entity [[Danh mục]] (màn `03` chuyển từ "PBI sau" → đã triển khai; điểm vào sửa cha bằng vùng tiêu đề; preset cha thêm con). Sync qua skill `sora-wiki` + `log.md` sau implement |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Điểm vào màn `03`** — dòng cha **có con** ở màn `01`: bỏ no-op → push `CategoryChildListScreen(parent, repository)`; sau pop reload lặng cả 2 loại (helper có sẵn) → số con/tên cha phản ánh khi về (R1).
- **Màn `03` mới** — nạp 1 loại `categoriesIncludingHidden(parent.type)`, con = `childrenOf(list, parent.id)`; cha hiển thị **derive** từ list (không giữ object tĩnh) → tiêu đề tươi sau đổi tên. Tự dựng `Scaffold`/`AppBar` (theme teal) vì cần tiêu đề 2 dòng chạm được (R2/R3).
- **Vùng tiêu đề = sửa cha** — khối tên cha + "Danh mục con" bọc `InkWell` (giữa back và "+"); nhấn → form Sửa cha; cha có con nên form tự khóa loại + không mở sheet cha (PBI 14 dựng đủ) (R3).
- **Tái dùng dòng** — trích `_row` màn `01` → `CategoryRow{category, subtitle?, onTap}` dùng chung `01`/`03` (màn `03` không truyền subtitle — không dòng phụ đếm con) (R4).
- **Thêm nhanh con** — `CategoryFormScreen` thêm param `initialParentId` (PBI 14 để lại cho màn `03`); hai điểm thêm ("+" + hàng cuối) mở form Thêm với `initialType: parent.type` + `initialParentId: parent.id` (R5).
- **Sửa con / con đổi cha** — chạm con → form Sửa con (loại khóa); sau pop reload lặng → con đổi tên/ẩn phản ánh, con đổi cha biến mất khỏi nhóm cũ (FR-010) (R7).
- **Refresh không refresh tay** — reload lặng sau mỗi pop form (tầng con: 1 loại) và sau pop màn con (tầng `01`: 2 loại) (R8). Con ẩn hiện đủ (R6); empty phòng thủ khi không còn con (R9).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — **không đổi schema** (v4), không seam mới; màn `03` là view đọc con qua `childrenOf`; thay đổi giao diện nhỏ (param `initialParentId` ở màn `02`, trích `CategoryRow`).
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (bám PBI 7–14).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–H đối chiếu acceptance/FR/SC; QA tay đi từ cha-có-con sẵn ("Ăn uống"); cha thu/nhóm khác tự tạo bằng form PBI 14.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 1 màn (`03`) + 1 widget chia sẻ (`CategoryRow`) + 1 param khởi tạo form + nối điểm vào màn `01`; không controller/service/event bus mới; **không đổi schema/repository** |
| Đúng seam cho test | ✅ | `CategoryChildListScreen` nhận `repository` (mặc định `ensureWalletRepository`) — test bơm fake; fake đã biến đổi được (store + `insert/updateCategory`) → test ghi qua widget assert store |
| Không hồi quy PBI 13/14 | ✅ | Màn `01` chỉ thay no-op dòng có con bằng push màn con + giữ reload lặng; màn `02` chỉ thêm param mặc định không đổi hành vi cũ (add `initialParentId == null` → như cũ); `categoriesIncludingHidden`/`childrenOf`/seed/icon không đổi. Chạy lại toàn bộ test |
| Tái dùng > viết mới | ✅ | `childrenOf` tính danh sách con; `CategoryRow` trích từ `_row` `01`; form `02` tái dùng cho Sửa con / Sửa cha (đã dựng đủ luật khóa) / Thêm con (preset); tiêu đề chạm tự dựng 1 lần, không đổi `SubPageScaffold` dùng chung |
| Ràng buộc cây 2 cấp / cùng loại / tên duy nhất / ẩn giữ lịch sử | ✅ | Màn `03` không sinh cấp 3; chỉ hiển thị con của cha đang xem; ghi giữ nguyên validator màn `02` |
| Không làm hỏng dữ liệu | ✅ | Màn `03` thuần đọc; thêm/sửa đều qua màn `02` đã kiểm soát; back không ghi |
| Khóa app không lộ thông tin | ✅ | Màn route trong shell sau boot-gate (PBI 3), không số tiền — không làm thêm |
| Cập nhật wiki | ⚠️ | Sau implement sync entity [[Danh mục]]: màn `03` đã triển khai (nội dung/bố cục, entry từ `01`, vùng tiêu đề = sửa cha, thêm nhanh con preset, con đổi cha); append `log.md` |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── category/
│   │   │   └── (không đổi) category.dart, category_list.dart, category_form.dart,
│   │   │       category_source.dart, category_presets.dart
│   │   └── widgets/
│   │       ├── category_row.dart                  # [TẠO] (R4): CategoryRow{category, subtitle?, onTap} —
│   │       │                                          bubble nền nhạt alpha category.color + icon (mờ khi ẩn),
│   │       │                                          tên (ellipsis), nhãn "Đã ẩn", dòng phụ subtitle (nếu có),
│   │       │                                          chevron phải; ValueKey('category-row-${id}') (pattern màn 01)
│   │       └── (không đổi) sub_page_scaffold.dart, category_icon.dart
│   ├── screens/
│   │   ├── category_list_screen.dart              # [SỬA] (R1/R4): dòng dùng CategoryRow; onTap dòng có con →
│   │   │                                              push CategoryChildListScreen(parent: c, repository) rồi
│   │   │                                              _reloadSilent(); subtitle 'N danh mục con' chỉ khi có con;
│   │   │                                              không con → mở form Sửa (giữ); FAB/khung không đổi
│   │   ├── category_form_screen.dart              # [SỬA] (R5): thêm param int? initialParentId; initState
│   │   │                                              _parentId = category?.parentId ?? initialParentId
│   │   │                                              (Sửa vẫn thắng; add không truyền → như cũ = null)
│   │   └── category_child_list_screen.dart        # [TẠO] (R2/3/5/6/7/8/9): CategoryChildListScreen{parent, repository?}
│   │                                                  StatefulWidget: initState nạp categoriesIncludingHidden
│   │                                                  (parent.type) → _list; derive _parent theo id; Scaffold+AppBar
│   │                                                  (theme teal, centerTitle false): title = FittedBox(InkWell(
│   │                                                  Column[tên cha, 'Danh mục con'])) → chạm mở form Sửa cha;
│   │                                                  actions = IconButton "+"; body ListView: CategoryRow từng con
│   │                                                  (subtitle null; chạm → form Sửa con) + Divider + hàng
│   │                                                  'Thêm danh mục con' (chạm → form Thêm preset cha); empty-state
│   │                                                  khi childrenOf rỗng (vẫn giữ điểm thêm); sau mỗi pop form →
│   │                                                  _reloadSilent() rồi derive lại _parent
│   └── (không đổi) theme/, data/, core/category/category_icon.dart, wallet_*/transaction_* …
└── test/
    ├── fakes/fake_wallet_repository.dart          # (không đổi — đã biến đổi được, có categoriesIncludingHidden/
    │                                                  insert/update/categoriesStored cho PBI 15)
    ├── category_child_list_screen_test.dart        # [TẠO] widget fake repo (R10): bố cục mockup 03 (app bar back +
    │                                                  tiêu đề tên cha + 'Danh mục con' + nút +, không bottom nav);
    │                                                  chỉ con của cha đang xem (không lẫn con cha khác / loại khác);
    │                                                  thứ tự sortOrder ổn định; con ẩn hiện đúng vị trí + 'Đã ẩn',
    │                                                  không loại; chạm con → Sửa prefill + loại khóa (readonly); đổi
    │                                                  cha con qua form → lưu → không còn trong nhóm cũ (FR-010);
    │                                                  '+'/hàng Thêm → form Thêm preset cha + loại (ô cha hiện tên cha)
    │                                                  → lưu con cuối nhóm; chạm vùng tiêu đề → Sửa cha (đổi tên →
    │                                                  tiêu đề mới, con giữ nguyên, loại khóa + không mở sheet cha);
    │                                                  empty-state (pump trực tiếp repo không còn con); cỡ chữ lớn
    │                                                  không overflow. Scope find trong màn con (màn 01 đè dưới giữ
    │                                                  state — như helper _formText PBI 14)
    ├── category_list_screen_test.dart              # [SỬA] (R1/R10): case 'dòng có con → no-op' đổi thành '→ mở
    │                                                  CategoryChildListScreen'; thêm case back từ màn con → đúng tab
    │                                                  + số con cha cập nhật (acceptance 8); giữ các case cũ khác
    ├── category_form_screen_test.dart              # [SỬA] (R10): thêm case Thêm với initialParentId (ô cha hiển thị
    │                                                  tên cha preset, lưu về cuối nhóm con cha đó; không truyền =
    │                                                  hành vi cũ)
    └── (không đổi) category_form_test.dart, category_list_test.dart, category_presets_test.dart,
        category_picker_screen_test.dart, wallet_*/transaction_*/settings_*/pin tests — chạy lại
```

Không đổi: `core/category/*` (category, category_list, category_form, category_source, category_presets), `core/widgets/category_icon.dart`, `sub_page_scaffold.dart`, `data/*` (repository, drift, db, deps), `theme/*`, `category_picker_screen.dart`, `add_transaction_screen.dart`, `transaction_*`, `wallet_*`, màn PIN/boot, `app_shell.dart`, `settings_screen.dart`.

## Rủi ro & ngoại lệ có lý do

- **Trích `CategoryRow` (sửa lại màn `01`)** — màn `01` đã ổn định/test kỹ; đổi sang widget chia sẻ có rủi ro hồi quy nhỏ nhưng test widget màn `01` (bố cục dòng/ẩn/đếm) bảo vệ, chạy lại toàn bộ xác nhận. Cân bằng: tránh nhân bản ~45 dòng dòng danh mục giữa `01`/`03` (màn `04` sắp xếp sau cũng dùng) — chọn trích là tái dùng hơn viết mới.
- **Màn `03` tự dựng `Scaffold`/`AppBar` thay vì dùng `SubPageScaffold`** — cố ý (R3): cần tiêu đề 2 dòng chạm được (nằm giữa back và "+"), `SubPageScaffold.title` chỉ nhận `String`. Đổi component dùng chung ~10 màn rủi ro cao hơn lợi 1 lần; màn mới vẫn nhất quán nhờ `AppBarTheme` teal tập trung. Duplication scaffold 1 lần chấp nhận.
- **`initialParentId` chỉ là giá trị khởi tạo** — khi người dùng đổi loại trong form Thêm, `_switchType` (PBI 14) đưa cha về null → danh mục trở thành gốc loại mới. Đúng giả định spec "màn danh sách con chỉ quyết định giá trị khởi tạo; màn thêm/sửa tự vận hành theo ràng buộc". Không phải lỗi.
- **Entry màn `03` chỉ tới được từ cha có con** — seed mặc định chỉ "Ăn uống" có con; QA tay nhóm khác/loại thu phải tự tạo cha-có-con bằng form (đặt "Danh mục cha" khi Thêm). Không thêm seed giả (rule dự án). Ghi rõ quickstart (R11).
- **Empty-state màn con là phòng thủ** — chưa có xóa danh mục (ngoài phạm vi spec 15) nên "cha không còn con" trong luồng thật chỉ xảy ra khi chuyển toàn bộ con sang cha khác; màn xử lý bằng empty hướng dẫn + vẫn cho thêm, không lỗi.
- **iOS chưa verify** (máy Windows): widget thuần + không đổi plugin/native — rủi ro thấp, giữ trạng thái.
- **QA tay màn `03` phụ thuộc dữ liệu có con** — ngoài "Ăn uống" các bước QA đều tạo được dữ liệu bằng luồng hiện có; không phải rào cản.

## File đã tạo

- `.specify/specs/15/research.md`
- `.specify/specs/15/data-model.md`
- `.specify/specs/15/quickstart.md`
- `.specify/specs/15/plan.md`

Bước tiếp theo: chạy `/sora-task 15` để phân rã thành tasks.md.
