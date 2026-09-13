# Kế hoạch triển khai: Loại bỏ dữ liệu mẫu khi cài mới

**Mã PBI**: 32
**Liên kết spec**: .specify/specs/32/spec.md
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (theo CLAUDE.md gốc) |
| Framework / Thư viện chính | GetX, drift (không đổi) |
| Lưu trữ dữ liệu | drift/sqlite local — schema **giữ nguyên v10**, không thêm migration |
| Kiểm thử | `flutter test` — sửa 2 file test phụ thuộc seed cũ (`wallets_dao_test.dart`, `budgets_dao_test.dart`) |
| Nền tảng triển khai | Android/iOS (không đổi) |
| Ràng buộc hiệu năng | Không phát sinh — bớt việc (không insert seed) |
| Ràng buộc khác | Không được xoá dữ liệu người dùng đã có khi nâng cấp (FR-006) |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md` trong repo — bỏ qua bước này, dùng nguyên tắc kiến trúc/nghiệp vụ đã chốt trong `CLAUDE.md` gốc và `wiki-knowledge/` làm chuẩn đối chiếu (đã đọc trước khi lập kế hoạch: danh mục là cấu hình nghiệp vụ giữ nguyên, không phải "dữ liệu mẫu").

## Giai đoạn 0 — Nghiên cứu

Xem `research.md`. Tóm tắt quyết định chính:

- **Xoá lệnh gọi seed**: gỡ `_seedSampleWallets()`/`_seedSampleTransactions()` khỏi `onCreate` và nhánh `onUpgrade from < 2` trong [app_database.dart](../../../app/sora_thu_chi/lib/data/db/app_database.dart), xoá luôn 2 hàm này + import `WalletSource`/`TransactionSource` không dùng nữa. `_seedCategories()` giữ nguyên.
- **Không đụng schema/migration khác**: mọi `createTable`/`addColumn` cho v2→v10 giữ nguyên — tự động thoả FR-006 (không có bước xoá nào sẵn có).
- **Không sửa trước code màn hình rỗng**: rà nhanh cho thấy các màn đã có nhánh rỗng; xác nhận thật bằng QA tay ở bước implement, không đoán lỗi trước.
- **2 file test cần sửa cùng đợt**: `wallets_dao_test.dart`, `budgets_dao_test.dart` (assertion cứng `.length == 5`/`== 11` dựa trên seed cũ) + rà thêm test khác nếu `flutter test` báo đỏ sau khi gỡ seed.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: không đổi — không tạo `data-model.md` (schema drift giữ nguyên v10, không thêm/bớt bảng/cột).
- **Hợp đồng giao diện**: không có — tính năng thuần nội bộ (app offline, không API/CLI công khai), không tạo `contracts/`.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — 2 kịch bản QA tay (cài mới sạch; nâng cấp từ bản có dữ liệu) + hồi quy `flutter analyze`/`flutter test`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

Không áp dụng (không có constitution.md). Đối chiếu CLAUDE.md/wiki: thiết kế không đổi stack, không đổi design system, không đổi luồng nghiệp vụ cốt lõi (số dư ví vẫn là đại lượng suy ra) — chỉ ngừng nạp dữ liệu giả. Phù hợp.

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/data/db/app_database.dart      # sửa: gỡ seed ví/giao dịch mẫu (onCreate + onUpgrade from<2)
└── test/
    ├── wallets_dao_test.dart          # sửa: assertion không còn phụ thuộc seed 5 ví/11 giao dịch
    └── budgets_dao_test.dart          # sửa: tương tự, dựng fixture tự chèn thay vì trông cậy seed
```

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: có thể còn test khác (ngoài 2 file đã xác định) ngầm định seed có sẵn, chỉ lộ ra khi chạy `flutter test` sau khi sửa — xử lý theo lỗi đỏ thực tế ở bước implement, không chặn plan.
- **Không có ngoại lệ vi phạm nguyên tắc dự án nào cần biện minh** — thay đổi thuần loại bỏ code seed, không đổi kiến trúc/stack/design system.
