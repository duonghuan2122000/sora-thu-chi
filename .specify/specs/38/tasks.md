# Danh sách Task: Cập nhật giao diện màn Thêm giao dịch

**Mã PBI**: 38
**Nguồn**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Pha 1: Setup

Không cần task Setup riêng — 0 dependency mới (`image_picker`/`path_provider` đã có sẵn trong `pubspec.yaml`), không cấu trúc thư mục mới cần khởi tạo trước. Bắt đầu thẳng từ Pha 3.

## Pha 2: Foundational

Không có task nền tảng dùng chung bắt buộc trước mọi User Story — 3 story bên dưới độc lập về file chạm tới (US1 chỉ sửa `AddTransactionScreen`+xóa keypad; US2/US3 mỗi story tự mở rộng `addTransaction` bằng 1 tham số optional riêng, không đụng tham số của nhau).

## Pha 3: User Story 1 - Nhập số tiền bằng bàn phím hệ thống (Ưu tiên: P1)

**Mục tiêu**: Ô Số tiền dùng bàn phím số của thiết bị thay bàn phím tùy chỉnh; ô Ghi chú có không gian nhập rộng hơn (FR-001, FR-002, FR-010).
**Tiêu chí kiểm thử độc lập**: Mở màn Thêm giao dịch, chạm ô Số tiền thấy bàn phím hệ thống hiện lên, gõ số → hiển thị đúng format `1.250.000`; lưu giao dịch Thu/Chi thành công như luồng cũ; ô Ghi chú cao hơn trước.

- [X] T001 [US1] ~~Viết unit test parse/format số tiền mới~~ — **bỏ, tái dùng**: `formatAmount`/`parseAmount` (`app/sora_thu_chi/lib/core/money_format.dart`) đã tồn tại + đã có test đầy đủ ở `money_format_test.dart`, đúng hệt nhu cầu (lọc non-digit, đối xứng format/parse). Không viết lại.
- [X] T002 [US1] ~~Thêm hàm thuần parse số tiền~~ — **bỏ, tái dùng**: dùng thẳng `formatAmount`/`parseAmount` có sẵn (như T001); phát hiện `wallet_transfer_screen.dart` đã có đúng pattern `_onAmountChanged` (TextField số hệ thống + auto-format) — sao chép logic đó thay vì viết mới.
- [X] T003 [US1] Sửa `app/sora_thu_chi/lib/screens/add_transaction_screen.dart`: bỏ `AmountKeypad` khỏi `body`; `_amount` đổi thành getter `parseAmount(_amountCtrl.text)`; thêm `TextField(key: 'amount-field', keyboardType: number)` + `_onAmountChanged` (bám mẫu `wallet_transfer_screen.dart`) với `OutlineInputBorder` màu theo `_amountAccent` (giữ nguyên teal/coral theo loại); tăng ô Ghi chú lên `minLines: 3, maxLines: 6`.
- [X] T004 [US1] Cập nhật `app/sora_thu_chi/test/add_transaction_screen_test.dart`: bỏ `tapDigits`/phím `,`/backspace-icon, thay bằng helper `enterAmount` (`enterText` trên `amount-field`); `_amountAccent` đọc màu border của `TextField` thay `Container` underline cũ; sửa case (a)/(b)/(g) theo hiển thị mới (`'1.250.000'` không kèm `' đ'` — suffix tách riêng).
- [X] T005 [US1] ~~Xóa `amount_keypad.dart`~~ — **giữ nguyên, không xóa**: kiểm tra lại thấy `scan_confirm_screen.dart` và `search_filter_screen.dart` vẫn dùng `AmountKeypad` — file này ngoài phạm vi PBI 38 (chỉ đổi màn Thêm giao dịch).

**Checkpoint**: `flutter analyze` sạch, `flutter test` pass — màn Thêm giao dịch dùng bàn phím hệ thống, chưa có Tag/Ảnh hóa đơn (2 story sau thêm).

## Pha 4: User Story 2 - Gắn Tag cho giao dịch (Ưu tiên: P2)

**Mục tiêu**: Người dùng chọn/tạo tag qua màn riêng và lưu vào giao dịch (FR-003, FR-004, FR-005, FR-006, phần Tag của FR-009/FR-011).
**Tiêu chí kiểm thử độc lập**: Từ màn Thêm giao dịch, chạm dòng Tag → màn `TagPickerScreen` mở, tạo tag mới hoặc chọn tag có sẵn → quay lại thấy tag hiển thị trên dòng Tag → Lưu giao dịch → mở Chi tiết giao dịch thấy đúng tag đã gắn. Không chọn tag vẫn lưu được bình thường.

- [X] T006 [P] [US2] Viết unit test cho `distinctTags`/`joinTags` tại `app/sora_thu_chi/test/transaction_detail_test.dart` (cạnh test `parseTags`).
- [X] T007 [US2] Thêm `distinctTags(List<Transaction>)` và `joinTags(List<String>)` vào `app/sora_thu_chi/lib/core/transaction/transaction_detail.dart`, cạnh `parseTags` đã có.
- [X] T008 [US2] ~~Thêm `allTransactions()`~~ — **bỏ, đã có sẵn**: `WalletRepository.allTransactions()` đã tồn tại (dùng cả ở `FakeWalletRepository`, test hiện có) — `TagPickerScreen` gọi thẳng.
- [X] T009 [US2] Viết widget test màn chọn tag tại `app/sora_thu_chi/test/tag_picker_screen_test.dart` (6 ca: tạo mới khi trống, gợi ý từ giao dịch cũ, chọn nhiều + xác nhận, chặn tên rỗng, chặn trùng không phân biệt hoa/thường, tick sẵn khi mở lại).
- [X] T010 [US2] Tạo `app/sora_thu_chi/lib/screens/tag_picker_screen.dart` (`TagPickerScreen`) theo khuôn `CategoryPickerScreen`: app bar + back "Chọn tag", `FilterChip` chọn nhiều, ô + nút tạo tag mới, nút "Xác nhận" trả `List<String>`.
- [X] T011 [US2] Mở rộng `addTransaction` (interface `wallet_repository.dart`) thêm tham số optional `String tags = ''` (gộp cùng `receiptImage` luôn — 1 lần sửa chữ ký cho cả US2/US3, thay vì 2 lần).
- [X] T012 [US2] Ghi cột `tags` khi insert trong `addTransaction` tại `wallet_repository_drift.dart` + cập nhật `FakeWalletRepository.addTransaction` (test) tương ứng.
- [X] T013 [US2] Sửa `add_transaction_screen.dart`: thêm dòng "Tag" (`_fieldRow`, icon `sell_outlined`) mở `TagPickerScreen`, lưu `_tags` vào state, hiển thị `_tags.join(', ')`, truyền `tags: joinTags(_tags)` vào `addTransaction`.
- [X] T014 [US2] Thêm case (m)/(n) vào `add_transaction_screen_test.dart`: chạm dòng Tag → mở màn → tạo tag → xác nhận → hiện lại trên dòng → Lưu → giao dịch mang đúng `tags`; không chọn Tag vẫn lưu bình thường (`tags: ''`).

**Checkpoint**: `flutter analyze` sạch, `flutter test` pass — gắn tag hoạt động đầu-cuối, không phá story US1.

## Pha 5: User Story 3 - Đính kèm Ảnh hóa đơn (Ưu tiên: P3)

**Mục tiêu**: Người dùng chụp/chọn ảnh hóa đơn ngay tại màn Thêm giao dịch, ảnh được lưu và gắn vào giao dịch khi lưu; hủy màn không để lại file rác (FR-007, FR-008, phần Ảnh hóa đơn của FR-009/FR-011).
**Tiêu chí kiểm thử độc lập**: Chạm dòng Ảnh hóa đơn → chọn "Chụp ảnh"/"Chọn từ thư viện" → thumbnail hiện tại dòng → Lưu giao dịch → mở Chi tiết thấy đúng ảnh. Thoát màn không lưu → file ảnh đã chụp bị xóa khỏi `receipts/`. Không đính kèm vẫn lưu được bình thường.

- [X] T015 [US3] ~~Mở rộng `addTransaction` thêm `receiptImage`~~ — **đã làm chung với T011** (1 lần sửa chữ ký cho cả `tags`+`receiptImage`).
- [X] T016 [US3] ~~Ghi cột `receipt_image`~~ — **đã làm chung với T012** (`wallet_repository_drift.dart` + `FakeWalletRepository`).
- [X] T017 [US3] Sửa `add_transaction_screen.dart`: thêm dòng "Ảnh hóa đơn" (`_receiptImageRow`, thumbnail `Image.file` khi có, icon khi chưa có), chạm mở `_ReceiptImageSourceSheet` (2 `ListTile` "Chụp ảnh"/"Chọn từ thư viện") → `ImagePicker`/`ScanImageStore` qua 2 seam constructor mới `pickImage`/`imageStore` (typedef `ReceiptImagePicker`), mặc định `ImagePicker().pickImage`/`LocalScanImageStore()`.
- [X] T018 [US3] Dọn file khi rời màn không lưu: `_discardPendingReceiptImage()` gọi từ cả 2 nhánh `_requestClose` (pop thẳng lẫn sau "Thoát"); **mở rộng `isDirty`** (`add_form.dart`) thêm `hasTags`/`hasReceiptImage` để đính-kèm-ảnh-mà-chưa-đổi-gì-khác vẫn được coi là dirty (không bị pop thẳng bỏ qua xác nhận + bỏ qua dọn file).
- [X] T019 [US3] Truyền `receiptImage: _receiptImagePath ?? ''` vào `addTransaction` trong `_save()`; set `_receiptImagePath = null` ngay sau khi gọi thành công (tránh dọn nhầm ảnh đã gắn giao dịch nếu có thao tác sau đó).
- [X] T020 [US3] Thêm case (o)/(p)/(q) vào `add_transaction_screen_test.dart` + `_FakeImageStore` (seam test mới): chụp ảnh → thumbnail hiện + lưu đúng `receiptImage`; không đính kèm vẫn lưu bình thường; đính kèm rồi "Thoát" không lưu → `ScanImageStore.delete` được gọi đúng path.

**Checkpoint**: `flutter analyze` sạch, `flutter test` pass — đính kèm ảnh hóa đơn hoạt động đầu-cuối, không phá US1/US2.

## Pha cuối: Polish & Cross-cutting

- [X] T021 Cập nhật docblock đầu `add_transaction_screen.dart` — phản ánh bàn phím hệ thống + 6 trường (thêm Tag/Ảnh hóa đơn).
- [X] T022 Chạy toàn bộ `flutter analyze` + `flutter test`: **sạch, 1352 test pass** (baseline trước PBI 38 là 1330 theo memory PBI 37 + 22 test mới của PBI 38). Phát hiện thêm khi chạy full suite (ngoài phạm vi 3 file test đã sửa riêng lẻ): `sora_translations_test.dart` thiếu bản dịch `en` cho 8 chuỗi mới (`Chọn tag`, `Tạo tag mới`, `Xác nhận`, `Thêm tag (tùy chọn)`, `Chưa có tag nào — tạo tag mới ở ô trên.`, `Đính kèm ảnh (tùy chọn)`, `Đã đính kèm`, `Chọn từ thư viện`) → đã bổ sung vào `sora_translations.dart`; và `widget_test.dart` (luồng FAB → lưu giao dịch) còn gõ số theo numpad cũ (`find.text('9')`) → đã sửa sang `enterText` trên `amount-field`.
- [~] T023 QA tay theo `quickstart.md` — **smoke test một phần đã chạy** trên emulator (`emulator-5554`, `flutter run` + adb screenshot): xác nhận trực quan bàn phím số hệ thống hiện đúng (viền coral, cursor sống), dòng Tag + dòng Ảnh hóa đơn hiện đúng vị trí, chạm Ảnh hóa đơn mở đúng bottom sheet "Chụp ảnh"/"Chọn từ thư viện". **Chưa chạy hết 10 bước** — app có khóa PIN từ phiên dùng trước (không phải của PBI 38) chặn mở lại sau khi restart tiến trình; cần người dùng còn biết mã PIN thực hiện nốt trên máy/emulator.

## Sơ đồ phụ thuộc

- Pha 3 (US1) không phụ thuộc Pha 4/5 — làm trước, là nền hiển thị của toàn màn.
- Pha 4 (US2) và Pha 5 (US3) đều sửa `add_transaction_screen.dart` và `wallet_repository*.dart` nhưng ở các tham số/dòng khác nhau — có thể làm sau US1 theo thứ tự bất kỳ, khuyến nghị US2 trước US3 theo đúng mức ưu tiên P2 > P3; tránh chạy đồng thời hai story trên cùng `add_transaction_screen.dart` để giảm xung đột merge.
- Pha cuối chạy sau khi cả 3 story xong.

## Ví dụ chạy song song

Trong Pha 4, T006 (`[P]`, viết test thuần cho `distinctTags`/`joinTags`) có thể làm song song với T009 (viết widget test `TagPickerScreen`) vì khác file và không phụ thuộc nhau — cả hai đều nên có trước T007/T010 tương ứng (bám thứ tự Test → Model → UI) nhưng có thể triển khai cùng lúc bởi 2 người/2 phiên khác nhau.

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 (bàn phím số hệ thống) — tự thân đã khớp phần lớn giá trị mockup mới và không phụ thuộc 2 story sau.
- **Thứ tự giao hàng tăng dần**: US1 → US2 (Tag) → US3 (Ảnh hóa đơn) → Polish. Mỗi story chốt xong đều `flutter analyze` + `flutter test` sạch trước khi sang story kế.
