# TÍNH NĂNG NGHIỆP VỤ: QUẢN LÝ DANH MỤC (CATEGORIES)

> Tài liệu chi tiết hóa mục "4. Quản lý Danh mục" trong bộ tính năng nghiệp vụ tổng của App Quản lý Thu Chi (Flutter Mobile). Dùng làm căn cứ triển khai UI (đối chiếu với `design-system-app-thu-chi.md`) và logic nghiệp vụ.

---

## 1. Mục tiêu & phạm vi

Danh mục (Category) là thực thể dùng để **phân loại giao dịch Thu/Chi**, làm nền tảng cho báo cáo, ngân sách và tìm kiếm. Tính năng cho phép người dùng:

- Xem, tạo, sửa, ẩn/xóa danh mục.
- Tổ chức danh mục theo **2 cấp (cha – con)**.
- Gán icon và màu để nhận diện nhanh trên danh sách và biểu đồ.
- Sắp xếp lại thứ tự hiển thị danh mục theo ý muốn.

Phạm vi **không bao gồm**: đồng bộ danh mục giữa nhiều thiết bị/tài khoản (app hoạt động offline, không có tài khoản đám mây).

---

## 2. Mô hình dữ liệu (Category)

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `id` | UUID | ✔ | Định danh duy nhất |
| `name` | String (≤ 30 ký tự) | ✔ | Tên danh mục, hiển thị trong danh sách/báo cáo |
| `type` | Enum: `income` \| `expense` | ✔ | Loại danh mục — chỉ áp dụng cho giao dịch cùng loại |
| `icon` | String (mã icon trong bộ icon outline) | ✔ | Biểu tượng nhận diện |
| `color` | Hex color | ✔ | Màu nhận diện (dùng cho icon, biểu đồ pie/bar) |
| `parent_id` | UUID? | ✘ | `null` = danh mục gốc (cấp 1); có giá trị = danh mục con (cấp 2) |
| `sort_order` | Integer | ✔ | Thứ tự hiển thị trong danh sách, do người dùng sắp xếp |
| `is_system` | Boolean | ✔ | `true` với danh mục mặc định được tạo sẵn khi cài app |
| `is_hidden` | Boolean | ✔ (mặc định `false`) | Ẩn khỏi danh sách chọn nhanh khi nhập giao dịch, vẫn giữ lịch sử |
| `created_at` / `updated_at` | Datetime | ✔ | Phục vụ đồng bộ backup/restore |

**Ràng buộc mô hình:**
- Chỉ hỗ trợ **tối đa 2 cấp** (cha – con). Danh mục con không được có danh mục con tiếp theo (`parent_id` của một danh mục con luôn trỏ tới danh mục cấp 1).
- `parent.type` phải trùng `child.type` (danh mục con "Cà phê" thuộc cha "Ăn uống" đều là `expense`).
- `name` là duy nhất trong cùng một `parent_id` + `type` (không cho trùng tên hai danh mục con cùng cha).

---

## 3. Danh mục mặc định (seed data)

Khi cài đặt lần đầu, hệ thống tạo sẵn danh mục hệ thống (`is_system = true`), người dùng có thể **ẩn** nhưng không **xóa vĩnh viễn**:

**Chi tiêu:** Ăn uống, Di chuyển, Nhà ở, Hóa đơn, Mua sắm, Giải trí, Sức khỏe, Giáo dục.
**Thu nhập:** Lương, Thưởng, Đầu tư.

Ví dụ cấu trúc cha–con mặc định:
```
Ăn uống (expense)
 ├─ Cà phê
 ├─ Ăn ngoài
 └─ Đi chợ
```

---

## 4. Luồng nghiệp vụ (Use cases)

### 4.1. Xem danh sách danh mục
- Danh sách tách theo 2 tab **Chi tiêu / Thu nhập**.
- Mỗi dòng hiển thị: icon + màu, tên, số danh mục con (nếu có) hoặc để trống, chevron điều hướng.
- Chạm vào danh mục có con → mở màn hình danh sách danh mục con.
- Chạm vào danh mục không có con → mở màn hình sửa trực tiếp.

### 4.2. Tạo danh mục mới
- Chọn loại (Thu/Chi) — không đổi được sau khi đã có giao dịch gắn với danh mục.
- Nhập tên (bắt buộc, validate trùng tên trong cùng nhóm cha/loại).
- Chọn icon từ bộ icon có sẵn.
- Chọn màu từ bảng màu gợi ý hoặc tùy chỉnh.
- (Tùy chọn) Chọn danh mục cha → biến danh mục mới thành danh mục con.
- Lưu → thêm vào cuối danh sách (`sort_order` = max + 1).

### 4.3. Sửa danh mục
- Cho sửa: tên, icon, màu, danh mục cha (di chuyển giữa các nhóm), trạng thái ẩn/hiện.
- **Không cho sửa** `type` nếu danh mục đã gắn với ít nhất 1 giao dịch (tránh sai lệch báo cáo lịch sử).

### 4.4. Ẩn / Hiện danh mục
- Danh mục ẩn: không xuất hiện trong danh sách chọn nhanh khi nhập giao dịch, nhưng **vẫn hiển thị đầy đủ trong báo cáo/lịch sử** của các giao dịch cũ.
- Áp dụng cho cả danh mục hệ thống lẫn danh mục tự tạo.

### 4.5. Xóa danh mục
- **Nếu chưa từng gắn giao dịch:** xóa cứng (hard delete) ngay lập tức.
- **Nếu đã có giao dịch gắn với danh mục:** không cho xóa trực tiếp — hệ thống đề nghị 2 lựa chọn:
  1. **Ẩn danh mục** (giữ nguyên dữ liệu lịch sử).
  2. **Gộp & xóa**: chuyển toàn bộ giao dịch sang một danh mục khác do người dùng chọn, sau đó xóa danh mục gốc.
- Xóa danh mục cha có danh mục con: cảnh báo rõ — các danh mục con sẽ bị xóa/ẩn theo, hoặc cho phép "thăng cấp" danh mục con thành danh mục gốc.
- Danh mục hệ thống (`is_system = true`): chỉ cho **ẩn**, không cho xóa vĩnh viễn (đảm bảo tính toàn vẹn dữ liệu mẫu và tránh lỗi khi khôi phục backup).

### 4.6. Quản lý danh mục cha – con
- Từ màn hình danh mục cha → xem danh sách con, thêm nhanh danh mục con mới.
- Cho phép "thăng cấp" danh mục con thành danh mục gốc và ngược lại (kéo một danh mục gốc vào làm con của danh mục khác), miễn tuân thủ ràng buộc 2 cấp.

### 4.7. Sắp xếp lại thứ tự
- Màn hình riêng, dùng thao tác kéo–thả (drag handle) để đổi `sort_order`.
- Thứ tự này quyết định vị trí hiển thị trong: danh sách danh mục, danh sách chọn nhanh lúc nhập giao dịch, chú thích biểu đồ.
- Sắp xếp độc lập theo từng tab Thu/Chi và theo từng nhóm cha/con.

---

## 5. Quy tắc nghiệp vụ (Business rules) — tổng hợp

1. Một giao dịch chỉ được gắn với **đúng một danh mục**, và danh mục đó phải cùng `type` với giao dịch (Thu ↔ danh mục Thu, Chi ↔ danh mục Chi).
2. Giao dịch loại **Chuyển khoản (Transfer)** không gắn với danh mục Thu/Chi (theo đúng nghiệp vụ ở mục 2 — chuyển khoản nội bộ không tính là thu/chi).
3. Tối đa 2 cấp danh mục (cha–con); không giới hạn số lượng danh mục con trong một cha.
4. Không cho trùng tên danh mục trong cùng một nhóm (cùng `parent_id` + `type`).
5. Danh mục hệ thống mặc định không xóa được, chỉ ẩn.
6. Xóa danh mục đã phát sinh giao dịch bắt buộc phải xử lý dữ liệu liên quan (ẩn hoặc gộp) trước khi xóa.
7. Đổi `type` của danh mục bị khóa khi danh mục đã có giao dịch lịch sử.

---

## 6. Liên hệ với các module khác

| Module | Liên hệ |
|---|---|
| **Giao dịch** | Mỗi giao dịch Thu/Chi bắt buộc chọn 1 danh mục; danh sách chọn nhanh ưu tiên hiển thị theo `sort_order` và loại trừ danh mục bị ẩn |
| **Ngân sách** | Ngân sách được thiết lập theo từng danh mục (hoặc nhóm cha); xóa/gộp danh mục cần cập nhật lại ngân sách liên quan |
| **Báo cáo & Thống kê** | Biểu đồ tròn/cột nhóm theo danh mục, dùng `color` để tô; "Top danh mục chi tiêu" dựa trên tổng hợp theo `category_id` |
| **Tag** | Tag là lớp lọc chéo, độc lập với danh mục — không thay thế cây phân loại danh mục |
| **Backup/Restore JSON** | Toàn bộ bảng danh mục (kể cả danh mục tùy chỉnh, thứ tự, trạng thái ẩn) nằm trong file backup; khi restore cần đối chiếu để không phá vỡ ràng buộc cha–con |

---

## 7. Màn hình liên quan (UI screens)

Tuân thủ `design-system-app-thu-chi.md` — dạng **sub-page** truy cập từ Cài đặt: app bar teal có nút back, **không hiển thị bottom navigation**.

| # | Màn hình | File mockup |
|---|---|---|
| 1 | Danh sách danh mục (tab Chi tiêu / Thu nhập) | `01-danh-sach-danh-muc.svg` |
| 2 | Thêm / Sửa danh mục (chọn loại, icon, màu, danh mục cha) | `02-them-sua-danh-muc.svg` |
| 3 | Danh sách danh mục con của một danh mục cha | `03-danh-muc-con.svg` |
| 4 | Sắp xếp lại thứ tự danh mục (kéo–thả) | `04-sap-xep-danh-muc.svg` |

---

## 8. Trường hợp biên (Edge cases)

- Người dùng cố xóa danh mục cha đang có danh mục con **và** cả hai đều có giao dịch → hệ thống phải liệt kê rõ ảnh hưởng (số giao dịch, số danh mục con) trước khi cho xác nhận.
- Nhập tên danh mục trùng với danh mục đã ẩn trong cùng nhóm → cảnh báo trùng tên (kể cả khi bản trùng đang ở trạng thái ẩn).
- Xóa danh mục đang được dùng làm điều kiện lọc trong một báo cáo đã lưu / ngân sách đang áp dụng → cảnh báo và yêu cầu chọn danh mục thay thế.
- Import giao dịch hàng loạt (CSV/Excel) tham chiếu tên danh mục chưa tồn tại → tự động tạo danh mục mới hoặc yêu cầu người dùng ánh xạ (mapping) sang danh mục có sẵn.
