# Mô hình dữ liệu — PBI 14 (Màn thêm/sửa danh mục)

**Mã PBI**: 14 — **Ngày**: 2026-09-05

## Phạm vi
PBI 14 **ghi** danh mục (tạo/sửa/ẩn) qua màn `02` — **không thay đổi schema drift** (schemaVersion giữ **4**, không chạy `build_runner`): mọi thao tác nằm trên bảng `categories` đã có. Bổ sung seam **ghi** + seam **đếm giao dịch** + module thuần validation/presets. Domain `Category` (PBI 11) dùng lại nguyên vẹn.

## Thực thể & nguồn (không đổi)
### `Category` — bảng `categories` (drift v4)
Map 1-1 `CategoryRow` → `Category` (mô tả đầy đủ tại data-model PBI 13). Trường form chạm tới: `name` (≤ 30, chuẩn trim), `type` (`CategoryType.income/expense`), `icon` (khóa → `categoryIcon`), `color` (ARGB bắt buộc), `parentId` (null = cấp 1), `sortOrder`, `isHidden`, `isSystem`.

Không có ràng buộc `UNIQUE` DB cho (name, type, parent_id) — **trùng tên trong nhóm do tầng nghiệp vụ chặn** (validator màn).

### `Transactions` (chỉ đọc để khóa loại)
`transactions.category_id` (nullable, v4) tham chiếu `categories.id`. Dòng thu/chi tạo từ seed v4 và PBI 11 `addTransaction` luôn set `category_id`. Transfer & dòng cũ nâng cấp `< v4` → null (không khóa).

## Seam mới trên `WalletRepository`

| Method | Loại | Hợp đồng |
|---|---|---|
| `categories({type})` | đọc | (giữ nguyên, picker PBI 11) |
| `categoriesIncludingHidden({type})` | đọc | (giữ nguyên, PBI 13) |
| `categoryHasTransactions(int categoryId)` | đọc | `bool` — có ≥ 1 dòng `transactions.category_id == categoryId`. Nguồn khóa đổi loại (FR-002/008) |
| `insertCategory(Category c)` | ghi | Bỏ qua `c.id` (DB sinh). Ghi `name/type/icon/color/parentId/sortOrder/isHidden`, `isSystem = false`. Trả `Category` đã lưu (id + toàn bộ trường) |
| `updateCategory(Category c)` | ghi | `update where id == c.id`. Ghi **tất cả** trường nghiệp vụ gồm `isHidden` (công tắc) và `isSystem` (giữ giá trị dòng đang sửa). Trả `Category` đã lưu |

Repository **không** tự validate trùng tên / khóa loại / cây 2 cấp / tính sortOrder — validation & sort thuộc module thuần + UI (bám nguyên tắc seam: "repository không tự chặn nghiệp vụ", xem `performTransfer`/`addTransaction`). Impl drift dùng `CategoriesCompanion.insert`/`WalletsCompanion`-style rồi đọc lại dòng.

## Module thuần mới

### `core/category/category_presets.dart`
- `categoryIconChoices` — 15 khóa icon (== tập khóa map `categoryIcon`) → mọi lựa chọn render được.
- `defaultIconFor(CategoryType)`, `defaultColorFor(CategoryType)` — mặc định sẵn khi Thêm (khác null, thuộc danh sách lựa chọn).
- `categoryPresetColors` — **13 ARGB**: 5 màu seed dữ liệu (teal `#0F6E56`, avatar `#3D8C77`, listLabel `#5F5E5A`, coral `#D85A30`, tabInactive `#9B9B9B`) + 8 palette mockup `02` (token mới `AppColors.category*`). Màu là **dữ liệu** (ARGB int), list hằng tập trung 1 chỗ.

**Bất biến**: mọi `Category` seed hiện tại có `icon ∈ categoryIconChoices` và `color ∈ categoryPresetColors` — form Sửa luôn có ô/ô màu trùng lựa chọn sẵn. (Test chặn hồi quy khi thêm seed.)

### `core/category/category_form.dart`
Hàm thuần, không đọc DB/state:
- `categoryNameError({required String raw, required List<Category> siblings, int? excludeId})`:
  - trim `raw`; rỗng → `'Tên danh mục không được để trống'` (acceptance 12; chuẩn theo FR-003 — tên toàn khoảng trắng = trống).
  - trùng `siblings` cùng `type` + cùng `parentId` (2 null xem là bằng nhau), **gồm bản đang ẩn**, bỏ `excludeId` (chính mình khi sửa — edge "giữ nguyên tên") → báo lỗi trùng. Khác nhóm/khác loại → hợp lệ.
- `endOfGroupSortOrder(List<Category> group)` → `max(sortOrder)+1`, `0` nếu rỗng — "thêm vào cuối nhóm" (doc §4.2/FR-009).
- `canChangeType({required bool hasTransactions, required bool hasChildren, required bool isParent})` = `!hasTransactions && !hasChildren && isParent` — điều kiện đổi loại khi Sửa (chốt spec; con có `isParent=false` → luôn false).
- `parentsOfType(List<Category> list)` → cấp 1 của list, sort tăng (wrap `category_list.topLevelParents`) — nguồn danh sách cha; **gồm cha ẩn** (FR-006 không chặn), màn tự loại chính nó khi Sửa.

## Nhóm danh mục (grouping)
- **Nhóm** = `(type, parentId)`; `parentId` null-literal so bằng nhau (null == null). Tên duy nhất trong nhóm; sortOrder độc lập theo nhóm.
- Cây tối đa 2 cấp: cha = `parentId == null`; con = `parentId != null`. Con **không** có con. Danh mục có con luôn là gốc (chọn cha mới chỉ cho phép là cấp 1).

## Luật lưu (save plan — validator + UI)
Đầu vào form → category mới/đã sửa để ghi:
1. `name = raw.trim()`, đã qua `categoryNameError` (trống/trùng chặn từ trước).
2. `icon`/`color` luôn có giá trị (chọn sẵn — FR-005/edge 13 không thể trống).
3. `sortOrder`:
   - **Thêm**: `endOfGroupSortOrder(nhóm đích)`.
   - **Sửa cùng nhóm** (`type` + `parentId` không đổi): giữ `sortOrder` cũ.
   - **Sửa đổi nhóm** (đổi cha hợp lệ, hoặc đổi loại khi `canChangeType`): `endOfGroupSortOrder(nhóm đích)` → xếp cuối nhóm mới.
4. `isHidden` từ công tắc; `isSystem`: Thêm = false, Sửa = giá trị cũ.
5. Khóa (đánh giá lúc dựng + lúc lưu qua state snapshot, offline không đổi mid-edit — R8):
   - Đổi loại chỉ khi `canChangeType`.
   - Đổi cha không áp dụng cho danh mục **có con** (luôn gốc — FR-008).
   - Con luôn cùng loại cha (loại con = loại cha, không đổi được).

## Bất biến & ngoại lệ
- Không tạo cấp 3 (danh sách cha chỉ liệt kê cấp 1); không danh mục "mồ côi" (đổi cha/bỏ cha xử lý parentId đúng đích).
- Đổi loại danh mục đã gắn giao dịch bị chặn ở UI + validator (khóa ô loại); không có guard DB (bám seam — SC-005 kiểm qua màn).
- Thứ tự hiển thị sau ghi: list/màn `01` đọc lại qua `categoriesIncludingHidden` sort `sortOrder` tăng → phản ánh ngay vị trí cuối nhóm (không cần sắp lại số giữa group khi xóa giữa — chưa có xóa PBI này).
- Danh mục hệ thống sửa được tên/icon/màu/ẩn (spec — không đặc quyền ở đợt này, chỉ khi xóa mới cấm).

## Fake & test
`FakeWalletRepository` giữ **bộ danh mục biến đổi được** (bản sao `List<Category>` từ seed thay vì trả hằng) + bộ đếm id; cài 3 method mới. `categoryHasTransactions` đếm trên `_transactions` (gồm seed tùy chọn truyền vào). Các test cũ chỉ đọc → không đổi hành vi (constructor `withCategories` giữ nguyên ngữ nghĩa; thêm read-accessor `categoriesStored` cho test assert). Test Sửa muốn sạch → seed `transactions: []`; muốn khóa → seed 1 dòng giao dịch `categoryId` = danh mục đích.
