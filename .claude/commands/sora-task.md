---
description: Phân rã spec.md/plan.md của một PBI thành tasks.md — danh sách task đủ nhỏ để thi công, tương đương /speckit.tasks
argument-hint: <mã-pbi>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(mkdir:*), Bash(ls:*)
---

## Đầu vào

```text
$ARGUMENTS
```

Tham số đầu tiên (`$1`) là **Mã PBI** (bắt buộc). Không cần thêm mô tả — lệnh này chỉ đọc dữ liệu đã có trong `.specify/specs/$1/`. Nếu người dùng cung cấp thêm văn bản sau `$1`, coi đó là ghi chú ngữ cảnh bổ sung cho việc chia task (ví dụ ưu tiên story nào trước).

> **Lưu ý**: Kết quả của lệnh này là file **`tasks.md`**, không phải `spec.md` — không được ghi đè lên spec.md gốc.

## Kiểm tra đầu vào

1. Nếu `$1` rỗng hoặc không phải số → dừng, báo lỗi cách dùng: `/sora-task <mã-pbi>`.
2. Kiểm tra bắt buộc phải có:
   - `.specify/specs/$1/spec.md`
   - `.specify/specs/$1/plan.md`
   - Nếu thiếu một trong hai → dừng lại và báo rõ file còn thiếu, gợi ý chạy `/sora-spec` hoặc `/sora-plan` tương ứng trước.

## Quy trình thực hiện

1. **Nạp tài liệu thiết kế** từ `.specify/specs/$1/`:
   - **Bắt buộc**: `plan.md` (tech stack, cấu trúc dự án), `spec.md` (user story kèm mức ưu tiên P1/P2/P3...)
   - **Tùy chọn nếu tồn tại**: `data-model.md`, `contracts/`, `research.md`, `quickstart.md`
   - Không phải PBI nào cũng có đủ tài liệu tùy chọn — chỉ dùng những gì có sẵn.

2. **Thực hiện phân rã task**:
   - Trích xuất user story từ spec.md, giữ nguyên mức ưu tiên (P1/P2/P3...).
   - Nếu có `data-model.md`: ánh xạ từng thực thể vào user story cần nó.
   - Nếu có `contracts/`: ánh xạ từng hợp đồng giao diện vào user story tương ứng.
   - Nếu có `research.md`: trích các quyết định kỹ thuật cần cho task Setup.
   - Task kiểm thử (test) chỉ tạo khi spec.md yêu cầu rõ ràng hoặc người dùng yêu cầu TDD.

3. **Cấu trúc các pha (bắt buộc theo đúng thứ tự)**:
   - **Pha 1 — Setup**: khởi tạo dự án/thư mục/phụ thuộc chung.
   - **Pha 2 — Foundational**: các task nền tảng bắt buộc phải xong trước khi làm bất kỳ user story nào.
   - **Pha 3 trở đi — Theo từng User Story** (theo thứ tự ưu tiên P1 → P2 → P3...): mỗi pha là một lát cắt hoàn chỉnh, có thể kiểm thử độc lập. Trong mỗi pha: Test (nếu có) → Model → Service → Endpoint/UI → Tích hợp.
   - **Pha cuối — Polish & Cross-cutting**: dọn dẹp, tối ưu, tài liệu.

4. **Định dạng task — BẮT BUỘC tuân thủ chính xác**:

   ```text
   - [ ] [MãTask] [P?] [Story?] Mô tả hành động kèm đường dẫn file cụ thể
   ```

   - Luôn bắt đầu bằng checkbox `- [ ]`
   - `MãTask`: số thứ tự tuần tự (T001, T002, ...) theo đúng thứ tự thực hiện
   - `[P]`: chỉ thêm khi task có thể chạy song song (khác file, không phụ thuộc task chưa xong)
   - `[Story]`: bắt buộc với task thuộc pha User Story (dạng `[US1]`, `[US2]`...); pha Setup/Foundational/Polish **không** có nhãn story
   - Mô tả phải có đường dẫn file cụ thể, đủ rõ để thực hiện mà không cần hỏi thêm

   Ví dụ đúng:
   - `- [ ] T001 Khởi tạo cấu trúc dự án theo plan.md`
   - `- [ ] T005 [P] Cài đặt middleware xác thực tại src/middleware/auth.py`
   - `- [ ] T012 [P] [US1] Tạo model User tại src/models/user.py`

   Ví dụ sai (không được dùng): thiếu checkbox, thiếu MãTask, thiếu nhãn Story ở pha user story, hoặc thiếu đường dẫn file.

5. **Ghi `tasks.md`** tại `.specify/specs/$1/tasks.md` theo `.specify/templates/tasks-template.md` nếu có, hoặc theo cấu trúc mặc định bên dưới. Bao gồm:
   - Tên tính năng lấy từ plan.md
   - Toàn bộ các pha theo mục 3
   - Sơ đồ phụ thuộc giữa các user story
   - Ví dụ chạy song song cho từng story
   - Đề xuất chiến lược triển khai (MVP trước, tăng dần)

6. **Kiểm tra định dạng**: rà lại toàn bộ task đã sinh, xác nhận 100% tuân thủ định dạng checklist ở mục 4.

7. **Báo cáo kết quả**:
   - Đường dẫn `.specify/specs/$1/tasks.md`
   - Tổng số task, số task theo từng user story
   - Cơ hội chạy song song đã xác định
   - Phạm vi MVP đề xuất (thường là chỉ User Story 1)
   - Gợi ý bước tiếp theo: chạy `/sora-implement $1`

## Cấu trúc tasks.md mặc định

```markdown
# Danh sách Task: [TÊN TÍNH NĂNG]

**Mã PBI**: $1
**Nguồn**: plan.md, spec.md (và data-model.md/contracts/research.md nếu có)

## Pha 1: Setup

- [ ] T001 ...

## Pha 2: Foundational

- [ ] T00x ...

## Pha 3: User Story 1 - [Tên] (Ưu tiên: P1)

**Mục tiêu**: ...
**Tiêu chí kiểm thử độc lập**: ...

- [ ] T0xx [US1] ...

## Pha 4: User Story 2 - [Tên] (Ưu tiên: P2)

...

## Pha cuối: Polish & Cross-cutting

- [ ] T0xx ...

## Sơ đồ phụ thuộc

[Mô tả thứ tự hoàn thành giữa các story]

## Chiến lược triển khai

- MVP đề xuất: User Story 1
- Thứ tự giao hàng tăng dần: ...
```
