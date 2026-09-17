# Kế hoạch triển khai: Cập nhật giao diện màn Thêm giao dịch

**Mã PBI**: 38
**Liên kết spec**: .specify/specs/38/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (bản SDK hiện tại của repo `app/sora_thu_chi`) |
| Framework / Thư viện chính | Flutter Material; GetX chỉ dùng cho i18n (`.tr`), **không** dùng cho state màn này (giữ đúng quy ước R11 hiện có — `StatefulWidget` + inject `WalletRepository`); `image_picker` (đã là dependency, dùng lại `ImageSource.camera`/`.gallery`) |
| Lưu trữ dữ liệu | SQLite qua `drift` — **không đổi schema, không bump version**; tái dùng cột `tags`/`receipt_image` đã có từ schema v3 (trước đây `addTransaction` luôn ghi rỗng); ảnh hóa đơn lưu file qua seam có sẵn `ScanImageStore`/`LocalScanImageStore` (`<appDocuments>/receipts/`) |
| Kiểm thử | `flutter test` — unit test hàm thuần (`distinctTags`/`joinTags`), widget test `AddTransactionScreen` (đổi cách nhập số tiền, 2 dòng mới) + `TagPickerScreen` mới |
| Nền tảng triển khai | Android/iOS, Flutter, offline hoàn toàn (không đổi) |
| Ràng buộc hiệu năng | Không đáng kể — thao tác cục bộ, dữ liệu cá nhân quy mô nhỏ |
| Ràng buộc khác | 0 dependency mới; xóa `AmountKeypad` sau khi không còn nơi dùng (tránh dead code); giữ nguyên màu sắc/token theo `design-system-app-thu-chi.md` |

Không có mục `NEEDS CLARIFICATION` còn lại — 2 điểm mở đã chốt ở bước `/sora-spec` (1A: chỉ cập nhật UI Thêm giao dịch, không xây luồng Sửa; 2B: màn chọn tag riêng).

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Dự án chưa có file `.specify/memory/constitution.md`. Đối chiếu thay bằng các nguyên tắc ghi trong `CLAUDE.md` gốc và nếp làm đã thiết lập qua các PBI trước (ghi trong wiki `Stack kỹ thuật`/`Design system`):

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không thêm dependency ngoài cần thiết | ✅ | 0 dependency mới — tái dùng `image_picker`, `path_provider` (qua `ScanImageStore`) đã có |
| Không đổi schema tùy tiện — additive khi cần | ✅ | Không migration; dùng đúng 2 cột đã tồn tại từ v3 |
| Đúng design system (teal/coral, ListTile, bo góc) | ✅ | Dòng Tag/Ảnh hóa đơn dùng lại style `_fieldRow` đã có; màn chọn tag theo khuôn `CategoryPickerScreen` |
| Seam test cho state màn (không GetX cho màn tác vụ một lần) | ✅ | Giữ nguyên constructor `repository` inject như `AddTransactionScreen`/`CategoryPickerScreen` hiện có |

## Giai đoạn 0 — Nghiên cứu

Xem `research.md`. Tóm tắt các quyết định chính:

- **Quyết định**: Đổi ô Số tiền sang `TextField` bàn phím số hệ thống, xóa `AmountKeypad`. **Lý do**: đúng mockup v2, giảm code tự vẽ. **Phương án khác**: giữ numpad — loại vì lệch mockup.
- **Quyết định**: Tag không có bảng riêng — suy ra từ cột `tags` các giao dịch hiện có (`parseTags` + khử trùng). **Lý do**: quy mô dữ liệu nhỏ, tránh migration/bảng thừa. **Phương án khác**: bảng `tags` + bảng nối nhiều-nhiều — loại vì over-engineering cho nhu cầu hiện tại.
- **Quyết định**: Ảnh hóa đơn dùng `ImagePicker` (camera + gallery) + seam `ScanImageStore` có sẵn, không OCR. **Lý do**: 0 dependency mới, tái dùng seam đã kiểm thử. **Phương án khác**: dựng lại `ScanCameraScreen` — loại vì nặng hơn nhu cầu chỉ đính kèm.
- **Quyết định**: Thêm `TagPickerScreen` mới theo khuôn `CategoryPickerScreen`. **Lý do**: chốt 2B, nhất quán điều hướng với dòng Danh mục/Ví cùng màn.
- **Quyết định**: Mở rộng `addTransaction` thêm 2 tham số optional `tags`/`receiptImage` (default `''`). **Lý do**: cột đã có, tránh trùng lặp logic bù số dư + insert.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — không đổi cấu trúc bảng, chỉ mở seam ghi + 2 hàm thuần `distinctTags`/`joinTags`.
- **Hợp đồng giao diện**: không áp dụng — app offline, không có API/CLI công khai.
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không thêm dependency ngoài cần thiết | ✅ | Xác nhận lại sau thiết kế — vẫn 0 dependency mới |
| Không đổi schema tùy tiện | ✅ | `data-model.md` xác nhận không migration |
| Đúng design system | ✅ | Giữ style `_fieldRow`, teal/coral theo ngữ cảnh loại giao dịch |
| Tránh trùng lặp / dead code | ✅ | Có kế hoạch xóa `AmountKeypad` + test cũ liên quan khi không còn dùng |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/lib/
  screens/
    add_transaction_screen.dart      # SỬA: bỏ AmountKeypad, TextField số tiền hệ thống,
                                      #      thêm dòng "Tag" + "Ảnh hóa đơn", note field cao hơn
    tag_picker_screen.dart           # MỚI: màn chọn/tạo tag (khuôn CategoryPickerScreen)
  core/
    transaction/
      transaction_detail.dart        # SỬA: thêm distinctTags()/joinTags() cạnh parseTags()
      add_form.dart                  # (không đổi, hoặc bổ sung nếu cần helper mới)
    widgets/
      amount_keypad.dart             # XÓA sau khi AddTransactionScreen hết dùng
  data/
    wallet_repository.dart           # SỬA: addTransaction thêm tham số tags/receiptImage
    wallet_repository_drift.dart     # SỬA: ghi 2 cột tags/receipt_image khi addTransaction

app/sora_thu_chi/test/
  add_transaction_screen_test.dart   # SỬA: cập nhật theo TextField mới, thêm ca Tag/Ảnh hóa đơn
  tag_picker_screen_test.dart        # MỚI
  core/transaction/... (tùy vị trí)  # MỚI/SỬA: test distinctTags/joinTags
  amount_keypad_test.dart            # XÓA nếu tồn tại và không còn widget để test
```

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: Đổi ô Số tiền sang `TextField` cần tự viết `TextInputFormatter` để giữ format "1.250.000" khi gõ — dễ sai vị trí con trỏ nếu làm ẩu. Giảm rủi ro bằng cách tái dùng `formatMoney`/logic parse số nguyên đã có, viết unit test cho formatter trước khi gắn vào widget.
- **Rủi ro**: Suy tag từ toàn bộ giao dịch (quét cột `tags`) sẽ chậm dần nếu dữ liệu rất lớn về sau — chấp nhận được ở quy mô cá nhân hiện tại; ghi `ponytail:` comment tại hàm `distinctTags` nêu trần chấp nhận + hướng nâng cấp (bảng tag riêng) nếu sau này cần.
- **Không có ngoại lệ vi phạm nguyên tắc dự án** — cả 2 bảng Constitution Check trước/sau thiết kế đều ✅.
