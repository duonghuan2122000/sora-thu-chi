# Kế hoạch triển khai: Chuẩn hoá điều hướng giữa màn hình

**Mã PBI**: 46
**Liên kết spec**: .specify/specs/46/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (repo `app/sora_thu_chi/`) |
| Framework / Thư viện chính | Flutter `Navigator`/`MaterialPageRoute` (không thêm dependency) |
| Lưu trữ dữ liệu | Không liên quan (thay đổi thuần điều hướng UI, không đụng drift/schema) |
| Kiểm thử | `flutter analyze` + `flutter test` (bộ test widget/unit hiện có) |
| Nền tảng triển khai | Android/iOS (không đổi) |
| Ràng buộc hiệu năng | Không áp dụng |
| Ràng buộc khác | Không đổi hành vi/UX — chỉ thêm khai báo kiểu generic tường minh |

## Kiểm tra theo hiến pháp dự án

Không có `.specify/memory/constitution.md` trong repo — bỏ qua bước đối chiếu, áp dụng trực tiếp quy ước ở `CLAUDE.md` (đã tuân thủ: không thêm dependency, không đổi UX ngoài phạm vi spec).

## Giai đoạn 0 — Kết quả nghiên cứu

Xem `research.md`. Tóm tắt:

- **Quyết định**: thêm `<T>` khớp kiểu đang dùng thực tế vào 21 điểm `MaterialPageRoute(` còn thiếu generic (32 điểm khác đã đúng chuẩn, không đổi). **Lý do**: kiểu suy được trực tiếp từ cách dùng giá trị trả về ở nơi gọi, không cần đoán. **Phương án khác**: named routes toàn app — loại vì ngoài phạm vi spec.
- **Quyết định**: giữ nguyên cơ chế `popUntil` + `onSelectTab` (5 màn). **Lý do**: đã nhất quán, chủ đích thiết kế (research R1), không phải lệch chuẩn thật. **Phương án khác**: đổi sang trả-kết-quả-qua-pop như audit gốc đề xuất — loại vì không áp dụng được cho điều hướng liên-tab qua `AppShell`.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: không áp dụng — không có thực thể dữ liệu mới/đổi.
- **Hợp đồng giao diện**: không áp dụng — không có API/CLI công khai, thay đổi nằm hoàn toàn trong `lib/`.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — `flutter analyze` + `flutter test` + 8 kịch bản tay đại diện các nhóm kiểu đã đổi (`bool`, `Category`, `List<String>`, `Wallet`, `TxnSearchFilter`, `String`, `ScanStepResult`, `void`).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

Không đổi so với trước thiết kế — thay đổi vẫn thuần nội bộ, không vi phạm ràng buộc nào trong `CLAUDE.md`.

## Cấu trúc dự án dự kiến

Chỉ sửa các file đã liệt kê trong `research.md` (Quyết định 2) — 12 file, 21 điểm sửa:

```text
lib/core/widgets/txn_row_tile.dart
lib/core/app_shell.dart
lib/core/scan/scan_flow.dart
lib/screens/budget_overview_screen.dart
lib/screens/budget_form_screen.dart
lib/screens/budget_detail_screen.dart
lib/screens/add_transaction_screen.dart
lib/screens/transaction_screen.dart
lib/screens/transaction_detail_screen.dart
lib/screens/wallet_detail_screen.dart
lib/screens/scan/scan_confirm_screen.dart
lib/screens/scan/scan_processing_screen.dart
```

Không tạo file mới, không đổi schema, không đổi widget tree.

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: thêm generic sai kiểu ở 1 điểm có thể gây lỗi biên dịch (không phải lỗi runtime ẩn) — an toàn hơn trạng thái hiện tại vì lộ ngay lúc `flutter analyze`/build, không lọt xuống runtime.
- **Ngoại lệ có lý do**: không sửa cơ chế `popUntil` + `onSelectTab` dù audit gốc từng nhắc tới — đã ghi rõ lý do ở Quyết định 3 (`research.md`) và mục "Giả định"/"Ngoài phạm vi" (`spec.md`).
