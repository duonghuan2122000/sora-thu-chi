---
title: "Danh mục"
date: 2026-09-05
tags: [module, category, entity]
sources:
  - ../docs/category/tinh-nang-nghiep-vu-quan-ly-danh-muc.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../../.specify/specs/11/spec.md
  - ../../.specify/specs/13/spec.md
  - ../../.specify/specs/14/spec.md
---

# Danh mục

Thực thể **phân loại giao dịch thu/chi** — nền tảng cho báo cáo, ngân sách, tìm kiếm. Gán icon + màu để nhận diện trên DS và biểu đồ.

## Mô hình & ràng buộc (drift schema v4 — PBI 11, đã triển khai)
Bảng `categories` (đã có thật trong `app_database.dart`, schemaVersion 4): `id` (int autoincrement), `name` (≤30 ký tự), `type` (textEnum income|expense), `icon` (khóa chuỗi → IconData qua map `categoryIcon`), `color` (ARGB int bắt buộc), `parent_id` (int nullable — null = cha), `sort_order` (int, mặc định 0), `is_system` (bool, mặc định false), `is_hidden` (bool, mặc định false). Không có UUID/created_at — giao dịch tham chiếu qua `transactions.category_id` (nullable int, schema v4) + `category` text **snapshot tên** hiển thị (dòng cũ/transfer null — màn DS/chi tiết không đổi).

Ràng buộc cấu trúc (nghiệp vụ):
- **Tối đa 2 cấp** (cha – con); con không được có con tiếp theo.
- `parent.type` **phải trùng** `child.type` (Cà phê con của Ăn uống, đều `expense`).
- `name` **duy nhất trong cùng** `parent_id` + `type` (cả khi bản trùng đang ẩn).

## Seed data (`is_system = true`, không xóa vĩnh viễn, chỉ ẩn)
Khớp `CategorySource.all` (PBI 11): **8 cha chi** (Ăn uống, Di chuyển, Nhà ở, Hóa đơn, Mua sắm, Giải trí, Sức khỏe, Giáo dục), **4 cha thu** (Lương, Thưởng, Đầu tư, **Khác**), **3 con** của Ăn uống (Cà phê, Ăn ngoài, Đi chợ). Seed chưa có danh mục ẩn — từ PBI 14 màn `02` đã bật/tắt ẩn được (danh mục tự tạo/ẩn giữ trên màn quản lý + gd lịch sử). Bộ icon/màu form chọn là hằng dữ liệu **preset** (dưới), đảm bảo mọi seed chọn lại được icon/màu cũ.
- ⚠ QUYẾT ĐỊNH MỞ: nghiệp vụ phí transfer cần danh mục "Phí giao dịch" ([[Ví & Tài khoản]]) nhưng **không có trong seed** — cần bổ sung hay để người dùng tự tạo?

## Quy tắc nghiệp vụ (tổng hợp)
1. Giao dịch gắn **đúng 1** danh mục, **cùng type** (thu↔income, chi↔expense).
2. Transfer **không gắn** danh mục thu/chi.
3. 2 cấp, không giới hạn số con.
4. Không trùng tên trong cùng nhóm cha/loại.
5. Danh mục hệ thống chỉ ẩn, không xóa.
6. Xóa danh mục **đã có giao dịch** → bắt buộc 1 trong 2: **ẩn** (giữ lịch sử) hoặc **gộp & xóa** (chuyển toàn bộ gd sang danh mục khác rồi xóa). Xóa cha → xử lý con (xóa/ẩn theo hoặc thăng cấp thành gốc).
7. Đổi `type` **bị khóa** khi danh mục đã gắn giao dịch (không làm lệch báo cáo lịch sử).
8. Xóa cứng chỉ khi **chưa có giao dịch**.
9. `is_hidden`: loại khỏi chọn nhanh khi nhập gd, **vẫn hiện** trong báo cáo/lịch sử cũ **và trên màn quản lý danh mục** (PBI 13: nhãn "Đã ẩn"/mờ, đúng vị trí — để còn đường bỏ ẩn/sửa; con ẩn vẫn đếm vào "N danh mục con").

## Sắp xếp & hiển thị
- `sort_order` kéo-thả (drag handle — màn `04`, chưa làm), độc lập theo tab Thu/Chi và theo nhóm cha/con.
- Thứ tự dùng cho: DS danh mục, chọn nhanh khi nhập gd, chú thích biểu đồ.
- DS tách 2 tab **Chi tiêu / Thu nhập**; chạm danh mục **không con** → mở `02` Sửa (PBI 14); **có con** → màn DS con `03` PBI sau (điểm vào giữ no-op tới lúc đó).
- **3 seam đọc** trong `WalletRepository` (phân vai, không đổi nhau): `categories({type})` = danh mục **đang hoạt động** (cha+con, `!isHidden`) cho picker giao dịch mới PBI 11; `categoriesIncludingHidden({type})` (thêm PBI 13) = **toàn bộ** cha+con **gồm cả ẩn**, cho màn quản lý — cần con ẩn để đếm dòng phụ; `categoryHasTransactions(id)` (thêm PBI 14) = có ≥1 dòng `transactions.category_id == id` — nguồn **khóa đổi loại** khi Sửa (dòng cũ nâng cấp `< v4` giữ `category_id` null → không tính, chấp nhận dev-DB). Tách cấp 1/đếm con là module **thuần** `core/category/category_list.dart` (`topLevelParents`/`childrenOf`, sắp sortOrder **ổn định**), tái dùng cho màn con `03` PBI sau.
- **3 seam ghi** (PBI 14, drift v4 giữ nguyên — không `build_runner`): `insertCategory(Category)` (bỏ qua `id` — DB sinh, `isSystem = false`, `isHidden` theo form, trả dòng đã lưu) và `updateCategory(Category)` (`update where id`, ghi **đủ** trường nghiệp vụ gồm `isHidden` + `isSystem` giữ giá trị dòng). Repository **không tự validate** trùng tên/khóa loại/cây 2 cấp/tính `sortOrder` — validation & sort thuộc module thuần + UI (bám seam `addTransaction`).
- **Module thuần** cho màn `02`: `category_form.dart` (`categoryNameError` trim/trống/trùng nhóm gồm ẩn/bỏ `excludeId`, `endOfGroupSortOrder` = max+1 hay 0, `canChangeType` = `!hasTransactions && !hasChildren && isParent`, `parentsOfType` wrap `topLevelParents`) + `category_presets.dart` (`categoryIconChoices` 15 khóa, `defaultIconFor`/`defaultColorFor` theo type, `categoryPresetColors` **13 ARGB** = 5 màu seed + 8 token `AppColors.category*`). Bất biến test: mọi `CategorySource.all` có icon ∈ choices + color ∈ palette — Sửa luôn chọn lại được màu/icon cũ.

## Edge cases
- Xóa cha có con **và** cả hai đều có giao dịch → liệt kê rõ ảnh hưởng (số gd, số con) trước khi xác nhận.
- Danh mục đang là điều kiện lọc báo cáo đã lưu / gắn ngân sách → cảnh báo, yêu cầu chọn thay thế.
- Import CSV tham chiếu danh mục chưa tồn tại → tạo mới nhanh hoặc yêu cầu map ([[Giao dịch]]).

## Liên kết module
| Module | Liên hệ |
|---|---|
| [[Giao dịch]] | Mỗi gd thu/chi chọn 1 danh mục |
| [[Ngân sách]] | Budget `scope=category` tính cả gd thuộc **subcategory**; xóa/gộp category → budget "invalid", nhắc gán lại |
| Báo cáo | Pie/bar nhóm theo category + `color`; "Top danh mục chi tiêu" theo `category_id` |
| Tag | Lớp lọc chéo độc lập, không thay thế cây danh mục |
| Backup/Restore | Cả bảng category trong file JSON; restore đối chiếu ràng buộc cha-con |

## Màn hình (sub-page — [[Design system]])
| File | Mô tả | Trạng thái |
|---|---|---|
| `01-danh-sach-danh-muc.svg` | DS, tab Chi tiêu / Thu nhập | ✅ **Đã triển khai** (PBI 13 — `CategoryListScreen`) |
| `02-them-sua-danh-muc.svg` | Thêm/sửa danh mục (loại, icon, màu, cha, ẩn) | ✅ **Đã triển khai** (PBI 14 — `CategoryFormScreen`) |
| `03-danh-muc-con.svg` | DS con của 1 cha | ⏳ PBI sau (điểm vào dòng CÓ con no-op) |
| `04-sap-xep-danh-muc.svg` | Kéo-thả thứ tự | ⏳ PBI sau (icon "Sắp xếp" app bar no-op) |

### Màn `01` — danh sách danh mục (`CategoryListScreen`, PBI 13 — đã triển khai)
- Điểm vào: hàng **"Danh mục"** nhóm KHÁC trong Cài đặt, ngay dưới "Quản lý ví" (`settings_screen.dart`).
- Bố cục (khớp mockup): app bar teal "Danh mục" + back + icon "Sắp xếp" (điểm vào màn `04`); tab tự dựng **Chi tiêu / Thu nhập** (mặc định Chi tiêu — chọn teal + gạch chân, kia xám); thân liệt kê **danh mục cấp 1** của tab (dòng: bubble nền nhạt phái sinh `color` alpha ~0.14 + icon màu đầy đủ, tên, dòng phụ "N danh mục con" chỉ khi có con, chevron); FAB "+" teal (thêm mới).
- Luật hiển thị: màn quản lý hiện **cả danh mục ẩn** đúng vị trí + nhãn "Đã ẩn"/mờ (không rút khỏi màn quản lý); "N danh mục con" **gồm con đang ẩn**; tab rỗng **thật** → empty hướng dẫn, còn **ẩn-toàn-bộ** → vẫn hiện dòng ẩn (không empty giả); 2 danh mục cùng tên khác loại/cha là dòng độc lập.
- State: StatefulWidget nạp **2 loại 1 lần** khi mở (`Future.wait` 2× `categoriesIncludingHidden`), chuyển tab lọc local không đọc DB lại; mỗi lần vào từ Cài đặt push route mới → reload (dữ liệu mới phản ánh). Không GetX controller. Không số tiền trên màn.
- Điểm vào (PBI 14 đã nối, khác no-op PBI 13): **FAB "+"** → mở `02` chế độ **Thêm** với `initialType = tab đang mở`; **chạm dòng KHÔNG con** → mở `02` chế độ **Sửa** (prefill danh mục đó); **chạm dòng CÓ con** → giữ no-op (vào màn con `03` PBI sau); icon "Sắp xếp" → `04` no-op. Sau `await Navigator.push(form)` trả về (lưu hay back) → **refresh lặng cả 2 loại** (`categoriesIncludingHidden` expense + income, không spinner) — thêm/sửa phản ánh ngay.
- **Không đổi schema** (PBI 13 chỉ đọc, drift v4 giữ nguyên, không `build_runner`); không thêm dependency.

### Màn `02` — thêm/sửa danh mục (`CategoryFormScreen`, PBI 14 — đã triển khai)
- Là màn con: app bar teal tiêu đề theo chế độ ("Thêm danh mục"/"Sửa danh mục") + back + chữ **"Lưu"** góc phải; nút chính **"Lưu danh mục"** teal cao 44 bo 8 cố định chân màn; **không** bottom nav. `StatefulWidget` seam `repository` (mặc định `ensureWalletRepository`); `category == null` → Thêm, khác null → Sửa. Snapshot cache **2 loại nạp 1 lần** khi mở + (Sửa) `categoryHasTransactions` — route độc quyền offline nên snapshot lúc mở = trạng thái lúc lưu (không re-check DB).
- **Pill loại** Chi tiêu/Thu nhập bo 20 (chọn nền teal): Thêm mặc định theo `initialType` (tab lúc chạm FAB), đổi được; Sửa hiển thị loại hiện tại, **đổi chỉ khi** `canChangeType` = chưa gd + không con + đang là gốc — ngoài ra hiện **readonly box** khóa rõ (không mồi bấm). **TextFormField tên** (maxLength 30, validator `categoryNameError`: trống/trùng trong nhóm `(type, parentId)` gồm bản **ẩn**, bỏ chính nó khi Sửa — lỗi dưới ô).
- **Lưới biểu tượng** (15 khóa `categoryIconChoices`, ô tròn 40 — chọn viền teal + nền `tealLightBg`) + **lưới màu** (13 ô `categoryPresetColors`, tròn ~34 — chọn viền đậm + dấu kiểm trắng); luôn có 1 ô chọn sẵn (Sửa = icon/màu hiện tại; Thêm = `defaultIconFor`/`defaultColorFor`).
- **Ô "Danh mục cha (tùy chọn)"** hiển thị "Không có — là danh mục gốc" khi null / tên cha khi có; bấm mở **bottom sheet** liệt kê **cấp 1 cùng loại** (gồm cha **ẩn**, loại trừ chính nó khi Sửa) + mục bỏ cha; **danh mục có con** → ô cha không mở (phải luôn gốc, giữ cây 2 cấp). Đổi loại → cha về "Không có" (cha cũ khác loại mất hợp lệ). **Switch "Ẩn khỏi danh sách nhanh"**: Thêm tắt sẵn; Sửa theo `isHidden` (đang ẩn → bật sẵn).
- **Lưu**: validate (trống/trùng chặn) → tính `sortOrder` — **cùng nhóm** (type+parentId) giữ cũ / **Thêm hoặc đổi nhóm** = `endOfGroupSortOrder` (cuối nhóm đích) → `insertCategory`/`updateCategory` (Sửa giữ `isSystem` cũ) dưới cờ `_saving` chặn lưu trùng → `Navigator.pop(saved)`; lỗi bất ngờ → SnackBar coral giữ dữ liệu. Back trước lưu → không ghi. Form **tái dùng cho entry sửa danh mục con / có con** ở màn con `03` (PBI sau — entry đó chưa mở, phủ bằng widget test pump trực tiếp).
