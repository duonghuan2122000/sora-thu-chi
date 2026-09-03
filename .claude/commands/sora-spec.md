---
description: Tạo file spec.md cho một PBI dựa trên quy trình Spec-Driven Development (tương đương /speckit.specify)
argument-hint: <mã-pbi> <mô-tả-bổ-sung>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(mkdir:*), Bash(ls:*)
---

## Đầu vào

```text
$ARGUMENTS
```

Tham số đầu tiên (`$1`) **luôn luôn** là **Mã PBI** — một chuỗi số (ví dụ `1234`). Toàn bộ phần còn lại của `$ARGUMENTS` (sau `$1`) là **Nội dung mô tả bổ sung** cho tính năng cần đặc tả.

## Kiểm tra đầu vào

1. Nếu `$1` rỗng hoặc không phải là một số nguyên → dừng lại và báo lỗi:
   > "Thiếu hoặc sai Mã PBI. Cách dùng: `/sora-spec <mã-pbi> <mô-tả-bổ-sung>`, ví dụ `/sora-spec 1234 Cho phép người dùng đăng nhập bằng Google`."
2. Nếu phần mô tả bổ sung rỗng → vẫn tiếp tục nhưng ghi chú rằng đặc tả sẽ dựa hoàn toàn vào ngữ cảnh đã có trong hội thoại (nếu có). Nếu không có ngữ cảnh nào khác, dừng lại và hỏi người dùng mô tả tính năng.

## Quy trình thực hiện

1. **Xác định thư mục đặc tả**: `.specify/specs/$1/`
   - Nếu `.specify/specs/$1/spec.md` đã tồn tại: đọc nội dung hiện tại, tóm tắt nhanh nội dung cũ, và hỏi người dùng có muốn **cập nhật/ghi đè** hay **giữ nguyên và dừng**. Chỉ tiếp tục sau khi có xác nhận.
   - Nếu chưa tồn tại: tạo thư mục bằng `mkdir -p .specify/specs/$1`.

2. **Nạp khuôn mẫu**: đọc `.specify/templates/spec-template.md` nếu tồn tại trong dự án. Nếu không có, dùng cấu trúc mặc định mô tả trong mục "Cấu trúc spec.md mặc định" bên dưới.

3. **Trích xuất thông tin** từ mô tả bổ sung:
   - Xác định: tác nhân (actor), hành động (action), dữ liệu (data), ràng buộc (constraint).
   - Với các điểm chưa rõ ràng, hãy đưa ra suy đoán hợp lý dựa trên ngữ cảnh và thông lệ ngành. Chỉ đánh dấu `[CẦN LÀM RÕ: câu hỏi cụ thể]` khi:
     - Lựa chọn ảnh hưởng đáng kể đến phạm vi hoặc trải nghiệm người dùng.
     - Có nhiều cách hiểu hợp lý dẫn đến kết quả khác nhau.
     - Không có giá trị mặc định hợp lý nào.
   - **Giới hạn tối đa 3 điểm `[CẦN LÀM RÕ]`**, ưu tiên theo thứ tự: phạm vi > bảo mật/quyền riêng tư > trải nghiệm người dùng > chi tiết kỹ thuật.
   - Ghi lại các giả định hợp lý vào mục "Giả định" thay vì hỏi tràn lan.

4. **Viết `spec.md`** theo cấu trúc khuôn mẫu, gồm các mục bắt buộc:
   - Tiêu đề & mô tả ngắn gọn (2–4 từ đặc trưng cho tính năng)
   - Kịch bản & luồng người dùng (User Scenarios) — nếu không xác định được luồng chính, báo lỗi "Không thể xác định kịch bản người dùng" và dừng lại để hỏi thêm.
   - Yêu cầu chức năng (Functional Requirements) — mỗi yêu cầu phải kiểm thử được.
   - Tiêu chí thành công (Success Criteria) — đo lường được, **không đề cập công nghệ/triển khai**, gồm cả chỉ số định lượng (thời gian, %, số lượng) lẫn định tính.
   - Thực thể chính (Key Entities) — chỉ thêm nếu tính năng có liên quan đến dữ liệu.
   - Giả định (Assumptions)
   - Ngoài phạm vi (Out of Scope) — nếu phù hợp
   - Chỉ giữ lại các mục thực sự áp dụng; bỏ hẳn mục không liên quan thay vì ghi "Không áp dụng".
   - **Không** viết chi tiết kỹ thuật triển khai (ngôn ngữ, framework, API...) — spec.md chỉ mô tả CÁI GÌ và TẠI SAO, dành cho người đọc phi kỹ thuật.

5. **Tạo checklist chất lượng** tại `.specify/specs/$1/checklists/requirements.md`:

   ```markdown
   # Checklist chất lượng đặc tả: [Tên tính năng]

   **Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
   **Ngày tạo**: [ngày]
   **PBI**: $1 — [Liên kết tới spec.md]

   ## Chất lượng nội dung

   - [ ] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
   - [ ] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
   - [ ] Viết dễ hiểu cho người không chuyên kỹ thuật
   - [ ] Đầy đủ các mục bắt buộc

   ## Tính đầy đủ của yêu cầu

   - [ ] Không còn điểm đánh dấu [CẦN LÀM RÕ]
   - [ ] Các yêu cầu rõ ràng, kiểm thử được
   - [ ] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ
   - [ ] Đầy đủ kịch bản chấp nhận (acceptance scenarios)
   - [ ] Đã xác định các trường hợp biên (edge cases)
   - [ ] Phạm vi rõ ràng
   - [ ] Đã ghi nhận giả định và phụ thuộc

   ## Sẵn sàng cho bước tiếp theo

   - [ ] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
   - [ ] Kịch bản người dùng bao phủ luồng chính
   - [ ] Không có chi tiết triển khai rò rỉ vào đặc tả
   ```

6. **Tự kiểm tra (validate)** spec.md vừa viết theo checklist ở bước 5:
   - Nếu tất cả mục đạt: đánh dấu hoàn tất, chuyển sang bước 7.
   - Nếu có mục chưa đạt (trừ `[CẦN LÀM RÕ]`): liệt kê vấn đề cụ thể (trích đoạn liên quan), sửa lại spec.md, lặp lại tối đa 3 lần. Nếu vẫn chưa đạt sau 3 lần, ghi chú lại trong checklist và cảnh báo người dùng.
   - Nếu còn điểm `[CẦN LÀM RÕ]`: trình bày tối đa 3 câu hỏi cho người dùng theo định dạng bảng lựa chọn:

     ```markdown
     ## Câu hỏi [N]: [Chủ đề]

     **Ngữ cảnh**: [trích đoạn liên quan trong spec]

     **Cần làm rõ**: [câu hỏi cụ thể]

     | Lựa chọn | Phương án | Ảnh hưởng |
     |----------|-----------|-----------|
     | A        | ...       | ...       |
     | B        | ...       | ...       |
     | C        | ...       | ...       |
     | Khác     | Tự đề xuất | ...      |

     **Lựa chọn của bạn**: _[chờ phản hồi]_
     ```

     Sau khi có phản hồi, cập nhật spec.md tương ứng và chạy lại bước tự kiểm tra.

7. **Báo cáo kết quả** cho người dùng, gồm:
   - Đường dẫn thư mục: `.specify/specs/$1/`
   - Đường dẫn file: `.specify/specs/$1/spec.md`
   - Tóm tắt kết quả checklist
   - Gợi ý bước tiếp theo: chạy `/sora-plan $1 <mô tả kỹ thuật nếu có>`

## Cấu trúc spec.md mặc định

Dùng cấu trúc sau nếu không tìm thấy `.specify/templates/spec-template.md`:

```markdown
# Đặc tả tính năng: [TÊN TÍNH NĂNG]

**Mã PBI**: $1
**Ngày tạo**: [ngày]
**Trạng thái**: Nháp

## Mô tả tổng quan

[Tóm tắt 2-3 câu về tính năng]

## Kịch bản & luồng người dùng

### Luồng chính
[Mô tả luồng sử dụng chính, theo dạng Given/When/Then nếu phù hợp]

### Kịch bản chấp nhận
1. ...
2. ...

### Trường hợp biên
- ...

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI ...
- **FR-002**: Hệ thống PHẢI ...

## Tiêu chí thành công

- **SC-001**: ...(đo lường được, không kỹ thuật)
- **SC-002**: ...

## Thực thể chính
[Nếu có liên quan đến dữ liệu]

## Giả định

- ...

## Ngoài phạm vi

- ...
```
