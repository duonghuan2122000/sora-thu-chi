# Kịch bản khởi động nhanh: Loại bỏ dữ liệu mẫu khi cài mới

**Mã PBI**: 32

## A. Cài mới trên thiết bị/emulator sạch (SC-001, SC-002, SC-003)

1. Gỡ app khỏi thiết bị/emulator nếu đã cài trước đó (xoá luôn dữ liệu local): `flutter clean` không đủ — phải uninstall app trên thiết bị/emulator để xoá file sqlite cũ.
2. `flutter run` cài lại từ đầu.
3. Vào màn **Tổng quan**: kỳ vọng 0 ví, 0 giao dịch, không lỗi, không số liệu/biểu đồ giả.
4. Vào màn **Ví**: danh sách trống, có lối tạo ví mới.
5. Vào màn **Giao dịch**: danh sách trống, đúng trạng thái rỗng.
6. Nhấn FAB **Thêm giao dịch** khi chưa có ví nào: kỳ vọng được dẫn tới tạo ví trước (không crash, không chọn ví rỗng ngầm định) — FR-005.
7. Vào **Cài đặt → Danh mục**: danh mục thu/chi mặc định (Ăn uống, Di chuyển, Lương...) vẫn đầy đủ — FR-003.
8. Vào màn **Báo cáo** / **Ngân sách**: đúng trạng thái rỗng, không lỗi.
9. Tạo 1 ví mới → tạo 1 giao dịch → xác nhận số dư/danh sách cập nhật đúng bình thường (không còn dữ liệu mẫu cũ trộn lẫn).

## B. Nâng cấp từ bản cũ đã có dữ liệu (SC-004)

1. Cài bản app *trước* PBI 32 (còn seed) lên thiết bị/emulator, mở app một lần để tạo DB kèm 5 ví/11 giao dịch mẫu.
2. Tự tạo thêm 1 ví thật + 1 giao dịch thật (mô phỏng dữ liệu người dùng đã dùng app trước khi nâng cấp).
3. Cài đè bản app *sau* PBI 32 (không uninstall — giữ nguyên dữ liệu local).
4. Mở app: xác nhận **toàn bộ** ví/giao dịch trước đó (mẫu cũ + dữ liệu thật vừa tạo) vẫn còn nguyên — không bị xoá, không bị thêm mới ngoài ý muốn.

## C. Hồi quy nhanh

- `flutter analyze` sạch.
- `flutter test` toàn bộ pass (đặc biệt `wallets_dao_test.dart`, `budgets_dao_test.dart` — 2 file có assertion phụ thuộc seed cũ, xem `research.md` mục 4).
