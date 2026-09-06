# Mô hình dữ liệu — PBI 16 (Sắp xếp danh mục)

**Không đổi schema** — drift schemaVersion giữ **4**, không chạy `build_runner`. Bảng
`categories` (schema v4, PBI 11) đã có cột `sort_order`; tính năng này chỉ **ghi lại**
giá trị cột đó cho một nhóm danh mục cha, tái dùng mọi seam đọc sẵn có.

## Bảng & cột dùng lại

| Bảng | Cột | Vai trò trong PBI 16 |
|---|---|---|
| `categories` | `sort_order` (`int`, default 0) | **Thứ tự hiển thị**. Nguồn thứ tự duy nhất cho mọi nơi hiển thị danh mục (màn danh mục, danh mục con, picker chọn nhanh nhập giao dịch, chú thích biểu đồ) — xem research R6/FR-007. |
| `categories` | `parent_id`, `type`, `is_hidden`, `is_system` | Chỉ dùng để **chọn tập cha cấp 1 của một loại** (`parent_id IS NULL` + `type`) và để hiển thị (ẩn/hệ thống) — không ghi. |

## Bất biến thứ tự (đã có, PBI 13) — giữ nguyên

- `sortOrder` có nghĩa **theo từng nhóm con** (subset-scoped): trong mỗi tập con đồng nhất
  (cha cấp 1 của một loại; con của một cha), xếp tăng `sortOrder`; trùng giá trị giữ thứ tự
  gốc (stable). Giá trị **không** có nghĩa tuyệt đối xuyên nhóm → hai nhóm/loại có thể dùng
  chung miền số.
- Các hàm thuần `topLevelParents`/`childrenOf` (category_list.dart) & `endOfGroupSortOrder`
  (category_form.dart) dựa bất biến này để "thêm vào cuối nhóm".

## Ghi mới — seam `reorderCategories({required List<int> orderedIds})`

- **Ngữ nghĩa**: `orderedIds` = danh sách **đủ id danh mục cha cấp 1 của đúng một loại**,
  theo thứ tự mới sau kéo–thả. Repository ghi `sort_order = 0..n−1` cho từng id theo thứ tự
  list, trong **một transaction** (atomic, bám `performTransfer`).
- **Tác động biên**:
  - Chỉ chạm các dòng cha trong list — danh mục con (cấp 2) và cha loại kia **không đổi**
    `sort_order` → thứ tự nhóm con & loại kia bất biến (research R4).
  - Sau ghi, bất biến subset vẫn thỏa: cha của loại đang mở xếp `0..n−1` liên tục; chèn mới
    sau này (Thêm danh mục gốc) vẫn về cuối nhóm nhờ `max+1` — không xung đột.
  - Không xóa/ẩn/sửa tên danh mục; tham chiếu giao dịch/ngân sách/báo cáo không bị ảnh
    hưởng (chỉ đổi vị trí hiển thị).

## Domain `Category` — không đổi

`Category.sortOrder` giữ nguyên (bắt buộc, `int`). Màn sắp xếp chỉ cần `id`, `name`, `type`,
`icon`, `color`, `parentId`, `isHidden` để hiển thị dòng và gọi seam ghi — không map thêm
thực thể nào.

## Trạng thái màn (không lưu DB)

- Danh sách cha cấp 1 đang sắp giữ **trong memory** suốt vòng đời màn; mỗi lần thả:
  hoán vị local → ghi DB ngay (FR-006). "Xong"/back chỉ `pop` — thay đổi đã lưu, không có
  bản nháp/hủy.
- Mở lại màn sau → đọc lại từ DB → thứ tự bền vững (acceptance 8).

## Migration

Không có — schema v4 giữ nguyên.
