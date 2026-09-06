# Mô hình dữ liệu — PBI 15 (Màn hình danh sách danh mục con)

**Mã PBI**: 15 — **Ngày**: 2026-09-06

## Phạm vi

PBI 15 **chỉ đọc & trình bày** danh mục con trên màn `03` — **không thay đổi schema drift** (schemaVersion giữ **4**, không chạy `build_runner`), **không thêm seam repository**, **không thay đổi thực thể**. Mọi thao tác thêm/sửa/ẩn diễn ra qua màn `02` (PBI 14) — màn này chỉ nối điểm vào. Không có thực thể mới; trạng thái chuyển đổi không phát sinh ở màn này.

## Thực thể & nguồn (tái dùng, không đổi)

### `Category` — bảng `categories` (drift v4)
Map 1-1 `CategoryRow` → `Category` (mô tả đầy đủ tại data-model PBI 13/14). Màn `03` chạm tới các trường chỉ để **hiển thị**: `id` (khóa định danh cha/con), `name` (tên cha trên app bar, tên con trên dòng), `type` (lọc nhóm con cùng loại cha), `icon`/`color` (bubble nhận diện), `parentId` (xác định con của cha), `sortOrder` (thứ tự ổn định), `isHidden` (con ẩn vẫn hiện + dấu phân biệt).

Không có ràng buộc `UNIQUE` DB cho (name, type, parent_id) — trùng tên trong nhóm do validator màn `02` chặn (đã chốt PBI 14), màn `03` không ghi nên không liên quan.

## Quan hệ & view dữ liệu của màn `03`

- Cây tối đa **2 cấp** (đã chốt): cha = `parentId == null`, con = `parentId == id-cha`. Con **không** có con → màn `03` không có khái niệm "chạm con để đi sâu tiếp".
- Màn `03` của cha `P` hiển thị = **con trực tiếp** của `P`: `{ c ∈ categoriesIncludingHidden(type của P) : c.parentId == P.id }`, sắp `sortOrder` tăng **ổn định** — chính là hàm thuần `childrenOf(list, P.id)` (`core/category/category_list.dart`, PBI 13).
- Không lẫn: con của cha khác (khác `parentId`) và danh mục loại khác (khác `type`) tự loại bởi bộ lọc trên — bất biến "con cùng loại cha" đảm bảo `type` không cần so thêm.
- Con đang **ẩn** (`isHidden == true`) vẫn nằm trong danh sách (quy ước màn quản lý — ẩn chỉ rút khỏi picker giao dịch mới, PBI 11/13). Cha ẩn có con vẫn truy cập được từ màn `01` (màn đó hiện cả cha ẩn).
- Khi màn con được **ghi** (thêm/sửa/đổi cha/ẩn qua màn `02`), màn `03` **không tự duy trì** list — đọc lại `categoriesIncludingHidden` sau mỗi pop (view tái tính từ DB qua seam có sẵn; không snapshot cache giữa 2 màn).

## Thay đổi nhỏ ở tầng giao diện (không chạm dữ liệu)

| Nơi | Thay đổi | Loại |
|---|---|---|
| `CategoryFormScreen` | thêm param `int? initialParentId` — khi chế độ **Thêm** (`category == null`), `_parentId` khởi tạo theo param này (cha preset "thêm nhanh con"); khi **Sửa**, `category.parentId` vẫn thắng | giao diện (không đổi entity/save-plan) |
| `core/widgets/category_row.dart` (mới) | trích bố cục dòng danh mục từ màn `01` → widget dùng chung `01`/`03`: `{category, subtitle?, onTap}` | giao diện (không đổi dữ liệu) |

Không có luật lưu (save plan) mới; sortOrder/isSystem/khóa/trùng tên đều giữ nguyên từ PBI 14 — màn `03` chỉ quyết định **giá trị khởi tạo** (`initialType` + `initialParentId`), phần còn lại form tự vận hành (đúng giả định spec).

## Bất biến & ngoại lệ

- Không sinh cấp 3: màn `03` không có điểm chạm tạo con của con (dòng con → mở Sửa, không "đi sâu"); form khi sửa con vẫn cho đổi cha/bỏ cha (con không có con → không vi phạm 2 cấp), xử lý trong PBI 14.
- Con đổi sang cha khác cùng loại (hoặc bỏ cha thành gốc) → sau lưu không còn trong `childrenOf(P)` → màn `03` đọc lại sẽ không còn dòng đó (không phải trạng thái rác).
- Toàn bộ con ẩn → danh sách vẫn đầy đủ (nguồn gồm ẩn) — không empty giả; empty chỉ xảy ra khi thực sự không còn con nào (phòng thủ).
- Màn không hiển thị số tiền → không phụ thuộc quy ước tiền tệ/che tiền.

## Fake & test

Không sửa ngữ nghĩa `FakeWalletRepository` (màn `03` đọc qua `categoriesIncludingHidden` đã có + ghi qua `insertCategory`/`updateCategory` đã có). Widget test màn `03` dùng `withCategories` seed cha-con tuỳ ý (case ẩn / con lạ / không còn con) giống test màn `01`; assert thay đổi sau ghi bằng `categoriesStored`.
