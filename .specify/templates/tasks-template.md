# Danh sách Task: [TÊN TÍNH NĂNG]

**Mã PBI**: [số]
**Nguồn**: plan.md, spec.md (và data-model.md / contracts/ / research.md nếu có)

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish

## Pha 1: Setup

- [ ] T001 Khởi tạo cấu trúc dự án theo plan.md
- [ ] T002 [P] Cài đặt phụ thuộc / công cụ cần thiết

## Pha 2: Foundational

*(Các task bắt buộc phải xong trước khi bắt đầu bất kỳ user story nào)*

- [ ] T003 ...

## Pha 3: User Story 1 - [Tên] (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: [mô tả]
**Tiêu chí kiểm thử độc lập**: [làm sao xác nhận story này hoạt động độc lập]

- [ ] T004 [P] [US1] ...
- [ ] T005 [US1] ...

## Pha 4: User Story 2 - [Tên] (Ưu tiên: P2)

**Mục tiêu**: [mô tả]
**Tiêu chí kiểm thử độc lập**: ...

- [ ] T006 [P] [US2] ...

## Pha N: Polish & Cross-cutting

- [ ] T0xx Dọn dẹp, tối ưu, cập nhật tài liệu

## Sơ đồ phụ thuộc

```text
Setup → Foundational → US1 → US2 → ... → Polish
```

## Ví dụ chạy song song

```text
# Trong US1, các task sau có thể chạy cùng lúc:
T004 [P] [US1] ...
T00x [P] [US1] ...
```

## Chiến lược triển khai

- **MVP**: chỉ User Story 1
- **Giao hàng tăng dần**: US1 → US2 → US3 (mỗi story là một bản release độc lập được)
