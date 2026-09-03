---
description: Đọc spec.md của một PBI và tạo plan.md (kế hoạch triển khai kỹ thuật), tương đương /speckit.plan
argument-hint: <mã-pbi> <mô-tả-bổ-sung-về-kỹ-thuật>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(mkdir:*), Bash(ls:*)
---

## Đầu vào

```text
$ARGUMENTS
```

Tham số đầu tiên (`$1`) là **Mã PBI**. Phần còn lại của `$ARGUMENTS` là **ngữ cảnh kỹ thuật bổ sung** (ví dụ: ngôn ngữ, framework, ràng buộc hạ tầng, dịch vụ bên thứ ba...).

## Kiểm tra đầu vào

1. Nếu `$1` rỗng hoặc không phải số → dừng và báo lỗi cách dùng: `/sora-plan <mã-pbi> <mô-tả-bổ-sung>`.
2. Kiểm tra `.specify/specs/$1/spec.md` có tồn tại không:
   - Nếu **không tồn tại** → dừng lại, báo cho người dùng: "Chưa có spec.md cho PBI $1. Hãy chạy `/sora-spec $1 <mô tả>` trước." Không tự tạo spec thay thế.
   - Nếu tồn tại → tiếp tục.

## Quy trình thực hiện

1. **Nạp ngữ cảnh**:
   - Đọc toàn bộ `.specify/specs/$1/spec.md`.
   - Đọc `.specify/memory/constitution.md` nếu tồn tại (các nguyên tắc/ràng buộc bắt buộc của dự án — coding convention, kiến trúc, bảo mật...).
   - Đọc `.specify/templates/plan-template.md` nếu tồn tại; nếu không, dùng cấu trúc mặc định bên dưới.
   - Xem xét ngữ cảnh kỹ thuật bổ sung do người dùng cung cấp trong `$ARGUMENTS`.

2. **Điền Ngữ cảnh kỹ thuật (Technical Context)**:
   - Ngôn ngữ/runtime, framework chính, cơ sở dữ liệu, cách triển khai (deploy), ràng buộc hiệu năng...
   - Với thông tin chưa xác định được và không có trong spec/ngữ cảnh bổ sung, đánh dấu `NEEDS CLARIFICATION`.

3. **Kiểm tra theo Hiến pháp dự án (Constitution Check)**:
   - Nếu có `.specify/memory/constitution.md`, đối chiếu kế hoạch dự kiến với từng nguyên tắc.
   - Nếu có vi phạm không thể tránh khỏi, phải nêu rõ lý do (justification) trong plan.md, mục "Ngoại lệ có lý do". Nếu vi phạm không có lý do chính đáng → dừng lại và báo lỗi, không tạo kế hoạch vi phạm nguyên tắc dự án.

4. **Giai đoạn 0 — Research** (`research.md`):
   - Với mỗi điểm `NEEDS CLARIFICATION`, mỗi phụ thuộc (dependency), mỗi tích hợp bên ngoài: xác định quyết định kỹ thuật.
   - Ghi vào `.specify/specs/$1/research.md` theo định dạng:
     - **Quyết định**: [lựa chọn]
     - **Lý do**: [tại sao chọn]
     - **Phương án khác đã xem xét**: [so sánh]
   - Kết thúc giai đoạn này khi mọi `NEEDS CLARIFICATION` đã được giải quyết.

5. **Giai đoạn 1 — Thiết kế & Hợp đồng giao diện** (chỉ tạo các phần phù hợp với loại dự án):
   - `data-model.md`: trích xuất thực thể từ spec.md — tên, thuộc tính, quan hệ, luật hợp lệ, trạng thái chuyển đổi (nếu có).
   - `contracts/`: nếu dự án có giao diện với bên ngoài (API công khai, CLI, endpoint dịch vụ...), mô tả hợp đồng tương ứng (OpenAPI, schema lệnh CLI, v.v.). Bỏ qua nếu dự án hoàn toàn nội bộ.
   - `quickstart.md`: kịch bản kiểm thử tích hợp nhanh, các bước để một người khác chạy thử tính năng.

6. **Ghi `plan.md`** tại `.specify/specs/$1/plan.md` theo cấu trúc mặc định bên dưới (hoặc theo `plan-template.md` nếu có), bao gồm: Ngữ cảnh kỹ thuật, Constitution Check (trước & sau thiết kế), tóm tắt Giai đoạn 0 và Giai đoạn 1, danh sách file đã tạo.

7. **Báo cáo hoàn tất**:
   - Đường dẫn: `.specify/specs/$1/plan.md` và các file liên quan (`research.md`, `data-model.md`, `contracts/`, `quickstart.md`) — chỉ liệt kê file thực sự đã tạo.
   - Gợi ý bước tiếp theo: chạy `/sora-task $1`.

## Cấu trúc plan.md mặc định

```markdown
# Kế hoạch triển khai: [TÊN TÍNH NĂNG]

**Mã PBI**: $1
**Liên kết spec**: .specify/specs/$1/spec.md
**Ngày tạo**: [ngày]

## Ngữ cảnh kỹ thuật

- Ngôn ngữ / Runtime: ...
- Framework / Thư viện chính: ...
- Lưu trữ dữ liệu: ...
- Kiểm thử: ...
- Nền tảng triển khai: ...
- Ràng buộc hiệu năng: ...
- Ràng buộc khác: ...

## Kiểm tra theo hiến pháp dự án

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| ... | ✅/⚠️/❌ | ... |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`.

## Giai đoạn 1 — Thiết kế

- Mô hình dữ liệu: xem `data-model.md` (nếu có)
- Hợp đồng giao diện: xem `contracts/` (nếu có)
- Kịch bản khởi động nhanh: xem `quickstart.md`

## Cấu trúc dự án dự kiến

[Cây thư mục / file chính sẽ tạo hoặc chỉnh sửa]

## Rủi ro & ngoại lệ có lý do

- ...
```
