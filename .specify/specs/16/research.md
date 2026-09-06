# Nghiên cứu & quyết định thiết kế — PBI 16 (Sắp xếp danh mục)

Bối cảnh: `Categories.sort_order` đã tồn tại (schema v4, dùng ở mọi màn danh mục qua
`sortOrder`). Màn này **không đổi schema**, chỉ thêm một seam **ghi** thứ tự + một màn
kéo–thả mới. Không còn điểm `NEEDS CLARIFICATION` sau các quyết định dưới đây.

## Quyết định chính

### R1 — Widget kéo–thả: `ReorderableListView` (Flutter built-in)
- **Quyết định**: dùng `ReorderableListView.builder` (Material, không thêm dependency).
- **Lý do**: tự động cuộn khi kéo gần mép (FR-006/acceptance 6, SC-007), tự quản proxy
  của dòng đang kéo, lazy qua builder cho danh sách dài (FR-009). Đúng nguyên tắc dự án
  "không thêm thư viện".
- **Phương án khác**: package `reorderables` (thêm dependency — vi phạm rule); tự dựng
  DnD trên `ListView` (tốn code, rủi ro autoscroll) — bỏ.

### R2 — Kéo chỉ bằng tay cầm: `buildDefaultDragHandles: false` + `ReorderableDragStartListener`
- **Quyết định**: vô hiệu hóa drag-handle mặc định (long-press cả dòng) của
  `ReorderableListView`; bọc **icon tay cầm** (`Icons.drag_handle`) trong
  `ReorderableDragStartListener(index: i, child: …)` cho từng dòng → chỉ kéo được từ tay cầm.
- **Lý do**: FR-005 nói rõ thao tác qua tay cầm kéo–thả; tránh vô tình kéo khi chạm dòng;
  mockup `04` đặt tay cầm bên trái mỗi dòng.
- **Phương án khác**: để drag-handle mặc định (kéo cả dòng bằng long-press — sai mockup,
  dễ nhầm với chạm) — bỏ.

### R3 — Ghi ngay khi thả bằng seam atomic `reorderCategories(orderedIds)`
- **Quyết định**: thêm seam repository `Future<void> reorderCategories({required List<int> orderedIds})`.
  Drift ghi trong một `db.transaction()`: với mỗi id (theo thứ tự danh sách) đặt
  `sort_order = index` (0..n−1). Caller đảm bảo `orderedIds` = **đủ danh mục cha cấp 1 của
  đúng một loại** theo thứ tự mới.
- **Lý do**: spec FR-006 ghi nhận **ngay khi thả** (không bản nháp); một seam ghi chuyên
  biệt cho đúng chủ đích (bám mẫu `performTransfer` — nhiều ghi atomic một chỗ), tránh
  n vòng ghi full-row qua `updateCategory` không atomic, tránh ghi nhầm `isHidden/isSystem`
  từ object cũ.
- **Phương án khác**: vòng lặp `updateCategory` (n round-trip, mỗi lần ghi full row, không
  atomic → dễ lệch giữa chừng); đợi chạm "Xong" mới ghi (sai FR-006) — bỏ.

### R4 — Số hóa thứ tự: đánh lại `sort_order` liên tục **chỉ cho cha cấp 1 của một loại**
- **Quyết định**: mỗi lần thả, cha cấp 1 của loại đang mở được đánh `sort_order = 0..n−1`
  theo thứ tự sau kéo. Danh mục con (cấp 2) và cha loại kia **không đụng tới**.
- **Lý do**: mọi consumer xếp thứ tự **theo từng nhóm con** (subset-scoped), không phụ thuộc
  giá trị tuyệt đối:
  - màn danh sách `01` / con `03`: `topLevelParents` / `childrenOf` lọc nhóm rồi sort
    `sortOrder` (category_list.dart) — thứ tự cha chỉ phụ thuộc tương đối giữa cha;
  - picker chọn nhanh (PBI 11) & picker thêm giao dịch (`categories(type)`): lọc `isParent`
    từ list phẳng đã sort → thứ tự lưới cha = thứ tự cha tương đối;
  - đánh lại cha về 0..n **không** đổi thứ tự tương đối của cha loại kia (lọc `type` trước)
    và **không** đổi thứ tự trong nhóm con (con giữ giá trị cũ, sort nội nhóm không đổi);
  - chèn sau này vẫn an toàn: form Thêm dùng `endOfGroupSortOrder` theo nhóm đích
    (`category_form.dart`) → cha gốc mới thêm vẫn về cuối (max+1), con mới về cuối nhóm con.
- **Phương án khác**: lưu "position" float/thập phân, hoặc dịch chỉ một đoạn (đúng nhưng
  thừa — bảng nhỏ local, đánh lại toàn nhóm đơn giản, không mất dữ liệu) — bỏ.

### R5 — Tái dùng `CategoryRow`: thêm 2 param tùy chọn `leading` + `showChevron`
- **Quyết định**: mở rộng `CategoryRow` (dùng chung màn `01`/`03`) với `Widget? leading`
  (render trước bubble) và `bool showChevron = true`. Màn sắp xếp truyền
  `leading: ReorderableDragStartListener(…Icon(drag_handle))`, `showChevron: false`,
  `onTap: () {}` (dòng không điều hướng).
- **Lý do**: bubble nền nhạt + icon màu `category.color` + nhãn "Đã ẩn"/mờ đã được xử lý
  đúng trong `CategoryRow` (PBI 15) — màn `04` cần **đúng y** phần đó (FR-004: dòng hiển thị
  icon theo màu + phân biệt ẩn); tránh nhân bản ~40 dòng dòng danh mục lần thứ ba. Default
  giữ nguyên → màn `01`/`03` cùng test cũ không đổi.
- **Phương án khác**: dựng widget dòng riêng trong màn sắp xếp (nhân bản bubble/ẩn — vi
  phạm "tái dùng hơn viết mới"); bọc handle ngoài `CategoryRow` (vì chevron cố định nên
  không bỏ được → xấu) — bỏ.

### R6 — Thứ tự dòng sau kéo & nhóm chỉ-trong-loại
- **Quyết định**: màn sắp xếp nạp **một loại** (`categoriesIncludingHidden(type)`) lúc mở,
  giữ danh sách cha cấp 1 (`topLevelParents`) làm nguồn hiển thị; kéo–thả chỉ hoán vị trong
  danh sách cha này (không tạo cha-con, không trộn loại — FR-003/005). Con không xuất hiện
  (FR-004).
- **Lý do**: đúng giả định spec "vào từ tab nào sắp nhóm đó, không tab riêng"; dùng hàm
  thuần đã có + test.
- **Phương án khác**: nạp cả 2 loại rồi lọc (thừa — màn chỉ sắp 1 nhóm, không có tab để
  chuyển) — bỏ.

### R7 — Xử lý `onReorder` (index-math) bằng helper thuần + tối ưu local trước khi ghi
- **Quyết định**: tách logic dịch chuyển thành hàm thuần
  `moveCategoryAt(List<Category> list, int oldIndex, int newIndex)` trong module mới
  `core/category/category_sort.dart` (đúng ngữ nghĩa điều chỉnh của `ReorderableListView`:
  `newIndex > oldIndex → newIndex -= 1`). Màn dùng helper → `setState` → gọi
  `reorderCategories` với id theo thứ tự mới (await; nếu lỗi → `_load()` lại để đồng bộ về
  DB).
- **Lý do**: index-math của ReorderableListView dễ sai (đặc biệt kéo xuống qua ranh giới,
  thả cuối danh sách) — tách thuần để unit test các biên, nhất quán pattern "module thuần +
  unit test" của dự án.
- **Phương án khác**: viết trực tiếp trong widget + chỉ test qua widget drag (drag-handle
  test bằng gesture trong widget test dễ flaky — không cover đủ biên) — bỏ, helper thuần là
  tầng chắc chắn.

### R8 — Khung màn: `SubPageScaffold` + `actions` chứa nút "Xong"
- **Quyết định**: dùng `SubPageScaffold(title: 'Sắp xếp danh mục', actions: [TextButton
  'Xong'])`; app bar teal + back tự động (do push route); "Xong" và back hệ thống đều `pop`
  về màn danh sách (FR-008) — mọi thay đổi đã ghi khi thả nên không cần xác nhận.
- **Lý do**: SubPageScaffold đã đủ (title String + actions + không bottom nav); mockup `04`
  đúng dạng này. Nút "Xong" = hành động text trắng trên app bar teal (bám pattern icon action
  trắng màn `01`).
- **Phương án khác**: tự dựng `Scaffold`/`AppBar` như màn `03` (không cần tiêu đề đa dòng
  hay hành động đặc biệt — `SubPageScaffold` cover đủ) — bỏ.

### R9 — Điểm vào: kích hoạt icon "Sắp xếp" no-op ở màn danh sách `01`
- **Quyết định**: ở `CategoryListScreen`, icon `Icons.sort` (đang `onPressed: () {}` từ PBI
  13) đổi thành `push CategorySortScreen(initialType: _tab, repository: _repository)`, sau
  pop gọi `_reloadSilent()` (có sẵn từ PBI 15).
- **Lý do**: spec giả định điểm vào = icon trên app bar màn `01`; nạp theo **đúng tab đang
  mở** (`_tab`) nên khi về màn danh sách giữ nguyên tab (acceptance 7) và thứ tự mới hiện
  ngay (FR-007) — không cần làm mới tay.
- **Phương án khác**: thêm tab riêng trong màn sắp xếp (sai mockup/giả định — không có tab);
  đổi `SubPageScaffold` thêm kiểu leading text (không cần) — bỏ.

### R10 — Không đổi schema / không đổi các seam đọc cũ
- **Quyết định**: schema giữ v4 (không `build_runner`); `categoriesIncludingHidden`,
  `categories`, `childrenOf`, `topLevelParents`, form `02`, màn `03` giữ nguyên. Chỉ thêm
  seam **ghi** mới `reorderCategories` + màn sắp xếp mới.
- **Lý do**: thứ tự hiển thị ở mọi nơi (danh sách, picker nhanh, chú thích biểu đồ sau) đều
  đọc cùng `sortOrder` — một nguồn thứ tự duy nhất, không cần seam đọc mới (FR-007).
- **Phương án khác**: thêm cột `sort_index`/bảng `category_order` riêng (thừa — đã có
  `sort_order`, đổi schema tốn migration) — bỏ.

## Xác minh consumer thứ tự (FR-007)

Quét code xác nhận mọi nơi "tiêu thụ" thứ tự danh mục xếp **theo nhóm con** (không có chỗ
nào dựa giá trị `sortOrder` tuyệt đối xuyên nhóm):
- `category_list.dart`: `topLevelParents` / `childrenOf` — sort nội subset.
- `category_picker_screen.dart`, `transaction_controller` / `search_filter_screen.dart`:
  nhận `categories(type)` phẳng rồi lọc `isParent` / `parentId` — thứ tự cha & con độc lập.
- `category_child_list_screen.dart`, `category_form_screen.dart`: dùng `childrenOf` (con).
→ Đánh lại `sortOrder` của cha cấp 1 (R4) là đủ; con & loại kia bất biến.

## Kết luận

Toàn bộ tính năng = **1 màn mới** + **1 seam ghi mới** + **helper thuần index-math** +
**2 param tùy chọn `CategoryRow`** + nối điểm vào. Không dependency, không đổi schema, không
controller mới.
