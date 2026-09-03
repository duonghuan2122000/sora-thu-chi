---
title: "Danh mục"
date: 2026-09-03
tags: [module, category, entity]
sources:
  - ../docs/category/tinh-nang-nghiep-vu-quan-ly-danh-muc.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
---

# Danh mục

Thực thể **phân loại giao dịch thu/chi** — nền tảng cho báo cáo, ngân sách, tìm kiếm. Gán icon + màu để nhận diện trên DS và biểu đồ.

## Mô hình & ràng buộc (drift)
Bảng `categories`: `id(UUID), name(≤30 ký tự), type(enum income|expense), icon, color, parent_id(null=cha), sort_order, is_system, is_hidden, created_at/updated_at`.

Ràng buộc cấu trúc:
- **Tối đa 2 cấp** (cha – con); con không được có con tiếp theo.
- `parent.type` **phải trùng** `child.type` (Cà phê con của Ăn uống, đều `expense`).
- `name` **duy nhất trong cùng** `parent_id` + `type` (cả khi bản trùng đang ẩn).

## Seed data (`is_system = true`, không xóa vĩnh viễn, chỉ ẩn)
- **Chi tiêu:** Ăn uống, Di chuyển, Nhà ở, Hóa đơn, Mua sắm, Giải trí, Sức khỏe, Giáo dục.
- **Thu nhập:** Lương, Thưởng, Đầu tư.
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
9. `is_hidden`: loại khỏi chọn nhanh khi nhập gd, **vẫn hiện** trong báo cáo/lịch sử cũ.

## Sắp xếp & hiển thị
- `sort_order` kéo-thả (drag handle), độc lập theo tab Thu/Chi và theo nhóm cha/con.
- Thứ tự dùng cho: DS danh mục, chọn nhanh khi nhập gd, chú thích biểu đồ.
- DS tách 2 tab **Chi tiêu / Thu nhập**; chạm danh mục có con → vào DS con; không con → sửa trực tiếp.

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
| File | Mô tả |
|---|---|
| `01-danh-sach-danh-muc.svg` | DS, tab Chi tiêu / Thu nhập |
| `02-them-sua-danh-muc.svg` | Chọn loại, icon, màu, cha |
| `03-danh-muc-con.svg` | DS con của 1 cha |
| `04-sap-xep-danh-muc.svg` | Kéo-thả thứ tự |
