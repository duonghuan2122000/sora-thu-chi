# Kế hoạch triển khai: Dọn màn Tiện ích & Cá nhân hóa

**Mã PBI**: 45
**Liên kết spec**: .specify/specs/45/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (Android/iOS) |
| Framework / Thư viện chính | Flutter Material, GetX (`.tr` i18n, `Obx`) — theo `CLAUDE.md` stack đã chốt |
| Lưu trữ dữ liệu | Không đổi — vẫn `UtilitiesStore`/`AppSettings` (drift), tính năng này không chạm schema |
| Kiểm thử | `flutter_test` — widget test trên `utilities_screen.dart` |
| Nền tảng triển khai | App di động offline, không server |
| Ràng buộc hiệu năng | Không đáng kể — chỉ bớt widget dựng UI |
| Ràng buộc khác | Giữ nguyên `SubPageScaffold`, `SoraColors`, cấu trúc nhóm/hàng hiện có; không đổi hành vi 5 hàng còn lại |

Không có `NEEDS CLARIFICATION` — toàn bộ ngữ cảnh đã rõ từ `CLAUDE.md` và mã nguồn hiện có (`app/sora_thu_chi/lib/screens/utilities_screen.dart`).

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Dự án chưa có `.specify/memory/constitution.md` — bỏ qua bước đối chiếu hiến pháp, dùng trực tiếp ràng buộc trong `CLAUDE.md` (design system, kiến trúc) làm chuẩn.

| Nguyên tắc (từ CLAUDE.md) | Tuân thủ? | Ghi chú |
|---|---|---|
| Sub-page dùng `SubPageScaffold` | ✅ | Không đổi, màn đã dùng đúng |
| 1 màu thương hiệu teal cho hành động chính | ✅ | Không đổi style hàng còn lại |
| Không thêm state/abstraction không cần thiết | ✅ | Quyết định 1/2 ở `research.md` chọn xoá code tĩnh, không thêm cờ |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem `research.md`. Tóm tắt:

- **Quyết định 1**: Xoá thẳng 3 lời gọi `_navRow` (không dùng cờ ẩn/hiện). **Lý do**: ẩn tĩnh vĩnh viễn, không cần state runtime.
- **Quyết định 2**: Xoá luôn `_SectionLabel` + block nhóm "DỮ LIỆU & TÌM KIẾM" (không dùng `if (isNotEmpty)` runtime). **Lý do**: nhóm rỗng là sự thật biết trước lúc build.
- **Quyết định 3**: Giữ nguyên hàng "Widget màn hình chính". **Lý do**: đã chốt ở spec — dialog là hành vi thật.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: không áp dụng — không có thực thể/schema mới hoặc thay đổi.
- **Hợp đồng giao diện**: không áp dụng — thay đổi hoàn toàn nội bộ UI, không có API/CLI/endpoint.
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không thêm abstraction/state thừa | ✅ | Thiết kế cuối cùng chỉ xoá code, không thêm field/class mới |
| Giữ nguyên hành vi 5 hàng thật | ✅ | Không đổi handler/seam (`UtilitiesStore`, `ThemeController`, `LocaleController`) |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/lib/screens/utilities_screen.dart   # sửa: xoá 3 _navRow + block nhóm rỗng trong _body()
app/sora_thu_chi/test/screens/utilities_screen_test.dart   # sửa: cập nhật/thêm test khớp danh sách hàng mới (nếu file test đã tồn tại), thêm assertion "không còn 3 hàng cũ" + "không còn nhãn nhóm DỮ LIỆU & TÌM KIẾM"
```

Không tạo file/module mới — toàn bộ nằm trong 1 file UI hiện có + test tương ứng.

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: test hiện tại (nếu có) assert đủ 8 hàng/3 nhóm — sẽ đỏ sau khi xoá, cần cập nhật cùng lúc trong PBI này (không để test đỏ mới).
- Không có ngoại lệ vi phạm nguyên tắc dự án cần biện minh.
