---
title: "Danh mục"
date: 2026-09-05
tags: [module, category, entity]
sources:
  - ../docs/category/tinh-nang-nghiep-vu-quan-ly-danh-muc.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../../.specify/specs/11/spec.md
  - ../../.specify/specs/13/spec.md
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
Khớp `CategorySource.all` (PBI 11): **8 cha chi** (Ăn uống, Di chuyển, Nhà ở, Hóa đơn, Mua sắm, Giải trí, Sức khỏe, Giáo dục), **4 cha thu** (Lương, Thưởng, Đầu tư, **Khác**), **3 con** của Ăn uống (Cà phê, Ăn ngoài, Đi chợ). Chưa danh mục nào ẩn (chức năng ẩn thuộc PBI thêm/sửa, sau).
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
- DS tách 2 tab **Chi tiêu / Thu nhập**; chạm danh mục có con → vào DS con; không con → sửa trực tiếp.
- **2 seam đọc** trong `WalletRepository` (phân vai, không đổi nhau): `categories({type})` = danh mục **đang hoạt động** (cha+con, `!isHidden`) cho picker giao dịch mới PBI 11; `categoriesIncludingHidden({type})` (thêm PBI 13) = **toàn bộ** cha+con **gồm cả ẩn**, cho màn quản lý — cần con ẩn để đếm dòng phụ. Tách cấp 1/đếm con là module **thuần** `core/category/category_list.dart` (`topLevelParents`/`childrenOf`, sắp sortOrder **ổn định**), tái dùng cho màn con `03` PBI sau.

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
| `02-them-sua-danh-muc.svg` | Chọn loại, icon, màu, cha | ⏳ PBI sau (điểm vào FAB/dòng no-op) |
| `03-danh-muc-con.svg` | DS con của 1 cha | ⏳ PBI sau (điểm vào dòng no-op) |
| `04-sap-xep-danh-muc.svg` | Kéo-thả thứ tự | ⏳ PBI sau (icon "Sắp xếp" app bar no-op) |

### Màn `01` — danh sách danh mục (`CategoryListScreen`, PBI 13 — đã triển khai)
- Điểm vào: hàng **"Danh mục"** nhóm KHÁC trong Cài đặt, ngay dưới "Quản lý ví" (`settings_screen.dart`).
- Bố cục (khớp mockup): app bar teal "Danh mục" + back + icon "Sắp xếp" (điểm vào màn `04`); tab tự dựng **Chi tiêu / Thu nhập** (mặc định Chi tiêu — chọn teal + gạch chân, kia xám); thân liệt kê **danh mục cấp 1** của tab (dòng: bubble nền nhạt phái sinh `color` alpha ~0.14 + icon màu đầy đủ, tên, dòng phụ "N danh mục con" chỉ khi có con, chevron); FAB "+" teal (thêm mới).
- Luật hiển thị: màn quản lý hiện **cả danh mục ẩn** đúng vị trí + nhãn "Đã ẩn"/mờ (không rút khỏi màn quản lý); "N danh mục con" **gồm con đang ẩn**; tab rỗng **thật** → empty hướng dẫn, còn **ẩn-toàn-bộ** → vẫn hiện dòng ẩn (không empty giả); 2 danh mục cùng tên khác loại/cha là dòng độc lập.
- State: StatefulWidget nạp **2 loại 1 lần** khi mở (`Future.wait` 2× `categoriesIncludingHidden`), chuyển tab lọc local không đọc DB lại; mỗi lần vào từ Cài đặt push route mới → reload (dữ liệu mới phản ánh). Không GetX controller. Không số tiền trên màn.
- Điểm vào no-op có ripple (PBI này): chạm dòng → màn con `03`/sửa `02`; FAB → thêm `02`; icon "Sắp xếp" → `04` — màn đích PBI sau; chạm không lỗi/treo.
- **Không đổi schema** (PBI 13 chỉ đọc, drift v4 giữ nguyên, không `build_runner`); không thêm dependency.
