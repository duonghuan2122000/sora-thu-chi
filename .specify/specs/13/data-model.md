# Mô hình dữ liệu — PBI 13 (Màn danh sách danh mục)

**Mã PBI**: 13
**Ngày**: 2026-09-05

## Phạm vi
PBI 13 **chỉ đọc** dữ liệu danh mục để hiển thị — **không thay đổi schema drift** (schemaVersion giữ **4**, không chạy `build_runner`), không thêm bảng/cột, không thêm repository method **ghi**. Domain `Category` (PBI 11) dùng lại nguyên vẹn; tài liệu này mô tả projection màn hình + seam đọc bổ sung.

## Thực thể & nguồn

### `Category` (đã có — `core/category/category.dart`, bảng `categories`)
Map 1-1 từ `CategoryRow`. Trường liên quan PBI 13:

| Trường | Nguồn (bảng drift) | Dùng trong màn |
|---|---|---|
| `id` | `categories.id` (int autoincrement) | nhận diện dòng; `parentId` trỏ cha |
| `name` | `categories.name` (≤ 30 ký tự) | tên dòng |
| `type` | `categories.type` (`CategoryType.income/expense`) | tách tab Chi tiêu/Thu nhập |
| `icon` | `categories.icon` (khóa → `categoryIcon`) | glyph vòng tròn |
| `color` | `categories.color` (ARGB bắt buộc) | màu glyph + nền nhạt phái sinh |
| `parentId` | `categories.parent_id` (nullable) | `null` = cấp 1; ≠ null = con cấp 2 |
| `sortOrder` | `categories.sort_order` | thứ tự dòng (cha) |
| `isSystem` | `categories.is_system` | chưa dùng đợt này (chỉ thể hiện khi xóa — PBI sau) |
| `isHidden` | `categories.is_hidden` | dấu "Đã ẩn" + làm mờ dòng |

`Category.isParent` (= `parentId == null`) xác định danh mục cấp 1.

## Seam đọc bổ sung (research R1)

`WalletRepository` thêm method **đọc**:
- `Future<List<Category>> categoriesIncludingHidden({required CategoryType type})`

Hợp đồng:
- Trả **toàn bộ** danh mục thuộc `type` — **cả đang hoạt động lẫn đang ẩn** (`isHidden` đúng với dòng), gồm cha cấp 1 **và** con cấp 2 (cần để đếm con).
- Sắp tăng theo `sortOrder` (không đảm bảo cha đứng trước con — bộ xử lý màn tự tách).
- Khác `categories({type})` hiện có: method đó **chỉ** trả danh mục đang hoạt động (dùng cho picker giao dịch mới PBI 11) — giữ nguyên, không đổi ngữ nghĩa.

Impl:
- Drift: `select(categories)` không lọc `is_hidden`, lọc `type` trong Dart (cột enum converter, bảng nhỏ — bám `categories()` hiện tại), sort `sortOrder`.
- Fake: đọc bộ seed danh mục của fake (mặc định `CategorySource.all`) không lọc ẩn, sort `sortOrder`.

## Projection màn hình (luật hiển thị)

Với `all` = danh sách 1 loại đã nạp (cha + con, gồm ẩn):

1. **Danh sách cấp 1** (nội dung 1 tab) = `all.where(isParent)`, sắp tăng `sortOrder` → thứ tự đã sắp xếp của loại, **ổn định** giữa các lần xem & khi chuyển tab (FR-004). Danh mục ẩn **không bị loại** — vẫn xuất hiện đúng vị trí (FR-006).
2. **"N danh mục con"** của một cha cấp 1 = `all.where((c) => c.parentId == cha.id).length` — đếm **gồm con đang ẩn** (FR-005, edge). Không có con → không hiển thị dòng phụ (để trống).
3. **Tab rỗng thật sự** (FR-009): `topLevelParents` rỗng → state rỗng hướng dẫn thêm. Trường hợp mọi cấp 1 đều ẩn **không** phải rỗng (các dòng ẩn vẫn hiện) → không nhầm "không có danh mục".
4. Hai danh mục cùng tên khác loại/cha → 2 dòng độc lập (không gộp — duyệt theo danh sách riêng từng loại).

## Bất biến
- Không số tiền trên màn (không đụng quy ước tiền tệ).
- PBI 13 không tạo/sửa/xóa/ẩn danh mục — chỉ đọc. Mọi tổ hợp không làm hỏng dữ liệu (SC-008).
- Module thuần `category_list.dart` không đọc DB/state (chỉ nhận `List<Category>` đầu vào) — test bơm trực tiếp.

## Seed & fake
- Bộ danh mục fake mặc định (`CategorySource.all`) hiện **không có** danh mục ẩn và chỉ "Ăn uống" có 3 con — khớp acceptance 2 (Ăn uống → 3 danh mục con; Di chuyển… không con). Để phủ acceptance 4 (ẩn) và đếm con gồm ẩn, `FakeWalletRepository` nhận thêm seed danh mục tùy chọn (`List<Category>? categoriesSeed`, named, mặc định null → `CategorySource.all`) — **additive**, test cũ không đổi.
- Mặc định mở tab **Chi tiêu** (`expense`); tab Thu nhập chỉ các danh mục thu (Lương/Thưởng/Đầu tư/Khác — acceptance 3).
