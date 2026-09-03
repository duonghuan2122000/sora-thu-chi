---
description: Thi công toàn bộ task trong tasks.md của một PBI, tương đương /speckit.implement
argument-hint: <mã-pbi>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

## Đầu vào

```text
$ARGUMENTS
```

Tham số đầu tiên (`$1`) là **Mã PBI** (bắt buộc).

## Kiểm tra đầu vào

1. Nếu `$1` rỗng hoặc không phải số → dừng, báo lỗi cách dùng: `/sora-implement <mã-pbi>`.
2. Kiểm tra `.specify/specs/$1/tasks.md` tồn tại:
   - Nếu **không** → dừng lại, báo: "Chưa có tasks.md cho PBI $1. Hãy chạy `/sora-task $1` trước." Không tự bịa task để thi công.

## Quy trình thực hiện

1. **Kiểm tra checklist (nếu có)**: nếu tồn tại `.specify/specs/$1/checklists/`, quét toàn bộ file trong đó, đếm số dòng `- [ ]` (chưa xong) và `- [x]`/`- [X]` (đã xong) cho từng checklist. Hiển thị bảng trạng thái:

   ```text
   | Checklist       | Tổng | Đã xong | Chưa xong | Trạng thái |
   |-----------------|------|---------|-----------|------------|
   | requirements.md | 12   | 12      | 0         | ✓ ĐẠT      |
   ```

   - Nếu còn checklist chưa hoàn tất: dừng lại và hỏi người dùng "Một số checklist chưa hoàn tất. Bạn có muốn tiếp tục thi công không? (có/không)". Chỉ tiếp tục khi người dùng xác nhận "có".
   - Nếu tất cả đã đạt: tự động tiếp tục sang bước 2.

2. **Nạp toàn bộ ngữ cảnh** từ `.specify/specs/$1/`:
   - **Bắt buộc**: `tasks.md`, `plan.md`
   - **Nếu có**: `data-model.md`, `contracts/`, `research.md`, `quickstart.md`, `.specify/memory/constitution.md`

3. **Kiểm tra thiết lập dự án**: xác định loại dự án (Node.js, Python, .NET, Go...) dựa trên plan.md và các file cấu hình có sẵn (package.json, requirements.txt, *.csproj, go.mod...). Đảm bảo các file ignore cần thiết (.gitignore, .dockerignore...) tồn tại và có pattern phù hợp với công nghệ đang dùng; nếu thiếu thì tạo, nếu đã có thì chỉ bổ sung pattern còn thiếu chứ không ghi đè toàn bộ.

4. **Phân tích tasks.md**: đọc từng pha (Setup, Foundational, User Story..., Polish), xác định:
   - Task nào tuần tự, task nào có thể chạy song song (`[P]`)
   - Task nào đã đánh dấu `[x]`/`[X]` (bỏ qua, không làm lại)

5. **Thi công theo từng pha, đúng thứ tự**:
   - Hoàn thành trọn vẹn một pha trước khi sang pha kế tiếp.
   - Tôn trọng phụ thuộc: task tuần tự làm theo đúng thứ tự; các task `[P]` có thể xử lý cùng lúc nếu không đụng chung file.
   - Nếu tasks.md có task kiểm thử, viết và chạy test trước khi cài đặt phần tương ứng (TDD).
   - Task cùng đụng vào một file phải làm tuần tự, không song song.
   - Sau mỗi task hoàn thành, **đánh dấu `[X]`** ngay trong tasks.md.

6. **Xử lý lỗi khi thi công**:
   - Nếu một task tuần tự thất bại → dừng lại, báo lỗi cụ thể kèm ngữ cảnh để debug, không tự ý bỏ qua sang task sau.
   - Nếu một task `[P]` thất bại trong khi các task song song khác thành công → tiếp tục với các task thành công, báo cáo rõ task nào thất bại và lý do.
   - Đề xuất bước khắc phục tiếp theo nếu không thể tiếp tục.

7. **Xác minh khi hoàn tất**:
   - Xác nhận toàn bộ task bắt buộc đã được đánh dấu `[X]`.
   - Đối chiếu kết quả cài đặt với spec.md để đảm bảo đúng yêu cầu.
   - Chạy test (nếu có) và xác nhận pass.
   - Báo cáo tổng kết cuối cùng: số task hoàn thành/tổng số, các file đã tạo/sửa, kết quả test, các vấn đề còn tồn đọng (nếu có).

Nếu `tasks.md` chưa đầy đủ hoặc không tìm thấy pha nào hợp lệ, dừng lại và đề xuất chạy `/sora-task $1` để tạo lại danh sách task.
