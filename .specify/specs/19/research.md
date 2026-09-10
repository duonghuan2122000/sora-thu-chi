# Nghiên cứu kỹ thuật: PBI 19 — Chọn ngôn ngữ hiển thị (Tiếng Việt / English)

**Ngày tạo**: 2026-09-10
**Liên kết spec**: [spec.md](./spec.md)

Mọi mục `NEEDS CLARIFICATION` trong spec đã được giải quyết; 2 điểm cần người dùng chốt đã hỏi trực tiếp (ghi ở R7/R8).

---

## R1 — Cơ chế i18n: GetX Translations, **khóa = chuỗi tiếng Việt**

- **Quyết định**: dùng cơ chế i18n tích hợp của GetX (`GetMaterialApp(translations: …)` + `'nhãn'.tr`), với **khóa dịch chính là chuỗi tiếng Việt đang hiển thị hôm nay** (`'Ăn uống'`, `'Tiền mặt'`…). Bản đồ dịch chỉ có nhánh `'en'`.
- **Lý do**:
  1. `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md` §2.1 đã **chốt** dùng GetX translations — không cần cân nhắc lại.
  2. Khóa = tiếng Việt ⇒ **hành vi test hiện tại không đổi**: `String.tr` trả về chính khóa khi `Get.locale == null` (đọc mã nguồn `get_utils/src/extensions/internacionalization.dart:88` — `if (Get.locale?.languageCode == null) return this;`). 436 test hiện có pump bằng `MaterialApp` thường, không set locale ⇒ mọi assert chuỗi tiếng Việt vẫn xanh, **không phải sửa file test nào**.
  3. `.tr` **không cần `BuildContext`** ⇒ dịch được cả những chỗ sinh nhãn ngoài widget — `date_label.dart`, `theme_mode.dart: themeModeLabel`, `transaction_list.dart`, `wallet.dart` (getter `hiddenName`), `transaction_filter.dart`. Nếu chọn `flutter gen-l10n` (`AppLocalizations.of(context)`) thì toàn bộ các hàm thuần này phải nhận thêm tham số `context`/`l10n`, kéo theo sửa cả test của chúng — diff lớn hơn nhiều lần mà không thêm giá trị.
- **Phương án khác đã xem xét**:
  - `flutter_localizations` + `gen-l10n` + file `.arb`: chuẩn Flutter, cập nhật theo dependency chính xác, nhưng (a) mọi widget phải có `context`, (b) ~30 file test màn phải bọc delegate, (c) phải dựng thêm `l10n.yaml` + codegen.
  - Tự viết map tra cứu thủ công: không có cơ chế rebuild, tự chế lại bánh xe.

## R2 — "Đổi ngay lập tức" (FR-005): **phải gọi `Get.updateLocale()`** — đã kiểm chứng bằng thực nghiệm

- **Quyết định**: khi người dùng chọn ngôn ngữ → gán `Rx<Locale>` (cho radio + hàng màn `01`) **và** gọi `Get.updateLocale(locale)` (không `await`) để GetX reassemble toàn app.
- **Lý do — bằng chứng đo được** (probe tạm, đã xoá sau khi đo):
  - Probe 1: pump `MaterialApp(locale: vi)` → push route chứa widget thuần → đổi `locale` sang `en` → **`LEAF BUILDS before=1 after=1`**: route đang mở **không** rebuild khi `MaterialApp.locale` đổi. Nghĩa là chỉ hạ `locale:` xuống `GetMaterialApp` là **không đủ** cho yêu cầu FR-005 (nhãn màn đang mở và mọi màn khác phải đổi ngay).
  - Probe 2: `GetMaterialApp(translations: …, locale: vi)` → push route có `Text('Xin chào'.tr)` → gọi `Get.updateLocale(Locale('en'))` → sau 2 lần `pump`: `TRUOC vi=2 en=0` → `SAU vi=0 en=2`. Cơ chế chạy đúng, **và test được trong `flutter test`**.
- **Chi tiết bắt buộc**:
  - `Get.updateLocale` là `Future<void>`; trong test **không được `await`** — đã thử và test treo (fake async không bao giờ hoàn tất reassemble). Gọi kiểu bắn-và-quên rồi `pump` là đủ.
  - `Get.updateLocale` gán `Get.locale` **đồng bộ** trước khi reassemble (`extension_navigation.dart:1041`) ⇒ lần build kế tiếp đã đọc đúng từ điển mới.
- **Phương án khác đã xem xét**:
  - Bọc `Obx` đọc `Rx<Locale>` ở từng màn (~15 màn): không cần reassemble nhưng thêm boilerplate khắp nơi và **quên một màn là hỏng âm thầm** (SC-006 đòi 100%) → loại.
  - Gắn `Key` theo ngôn ngữ lên `GetMaterialApp`: remount cả cây ⇒ **mất stack điều hướng**, người dùng đang đứng ở màn `03` sẽ bị đẩy về shell — vi phạm luồng chính bước 4–6 → loại.

## R3 — Nơi lưu lựa chọn: row `locale` trong `AppSettings` (schema v5, **không migration**)

- **Quyết định**: key `'locale'`, giá trị `'vi'` / `'en'`; vắng row = mặc định `'vi'`. Bám đúng khuôn `themeMode` (`core/theme/theme_mode.dart` + `data/theme_store_drift.dart`).
- **Lý do**: bảng `AppSettings` (drift v5) đã là chỗ chứa cài đặt tiện ích, chú thích trong `app_database.dart:87-90` ghi rõ "PBI sau chỉ thêm row, không thêm migration". Thêm giá trị `'vi'`/`'en'` ngoài 2 chuỗi hợp lệ → rơi về mặc định, không ném (bám `themeModeFromStorage`).
- **Phương án khác đã xem xét**: `flutter_secure_storage` (đang dùng cho PIN) — sai chỗ, đây không phải bí mật; cột mới trong bảng khác — cần migration vô ích.

## R4 — Chỉ viết bản đồ `'en'`, **không** viết bản đồ `'vi'`

- **Quyết định**: `SoraTranslations.keys => {'en': {…}}` — không có nhánh `'vi'`, không set `fallbackLocale`.
- **Lý do**: khóa là tiếng Việt (R1) nên thiếu nhánh ⇒ `.tr` rơi xuống nhánh cuối và **trả về khóa = chuỗi tiếng Việt** (`internacionalization.dart:112`). Viết nhánh `'vi'` là 430 dòng lặp y hệt khóa, không kiểm chứng được gì.
- **Phương án khác đã xem xét**: bản đồ `vi` tường minh để "đủ cặp" — chỉ tạo cảm giác đầy đủ, thêm 430 dòng phải bảo trì gấp đôi khi sửa nhãn.

## R5 — Thêm `flutter_localizations` + `supportedLocales [vi, en]`

- **Quyết định**: khai báo `flutter_localizations` (SDK, không phải package ngoài) và truyền 3 delegate (`GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`) + `supportedLocales: [Locale('vi'), Locale('en')]` cho `GetMaterialApp`.
- **Lý do**: hiện app **không set locale** ⇒ `MaterialLocalizations` luôn tiếng Anh; khi ta ép locale `vi` mà thiếu delegate, Flutter in cảnh báo `"A MaterialLocalizations delegate that supports the vi locale was not found"` (đã thấy trong probe 1 khi chạy test). Có delegate ⇒ hộp thoại/date picker/nhãn chọn văn bản của Flutter tự theo ngôn ngữ — đúng phạm vi FR-008 ("thông báo/hộp thoại trong app") và không phải tự dịch lại chuỗi hệ thống.
- **Rủi ro kiểm chứng được**: đổi ngôn ngữ mặc định của các widget Material từ Anh → Việt. Không test nào hiện tại bấm nút hộp thoại hệ thống (`grep showDatePicker` + `'OK'` trong `test/` = 0 kết quả), nên không vỡ test.
- **Phương án khác đã xem xét**: bỏ qua delegate (giữ cảnh báo + hộp thoại tiếng Anh lẫn lộn) — vi phạm tinh thần FR-008; tự viết `LocalizationsDelegate` riêng cho chuỗi Material — thừa.

## R6 — Tên **danh mục mặc định**: dịch ở tầng hiển thị, không đụng DB/seed (FR-009, FR-010)

- **Quyết định**: giữ nguyên seed trong DB (tiếng Việt); khi hiển thị thì gọi `.tr` trên chuỗi tên — tức `category.name.tr`, và với dòng giao dịch là `t.category.tr` (cột `category` là **snapshot tên danh mục**). Bản đồ `'en'` chứa đủ 15 tên trong `CategorySource`.
- **Lý do**: khớp key = tên ⇒ **tự động thoả FR-010**: danh mục người dùng tự tạo hoặc đã đổi tên không khớp key nào ⇒ `.tr` trả nguyên văn. Không cần cột `slug`, không cần migrate, không cần cờ `isSystem` cho việc này.
- **Hệ quả đã cân nhắc**: giao dịch cũ giữ snapshot tên tiếng Việt nên ở chế độ English sẽ hiện nhãn tiếng Anh của danh mục mặc định — đúng tinh thần SC-006 ("không còn nhãn tĩnh tiếng Việt"), không phải sửa dữ liệu.
- **Phương án khác đã xem xét**: thêm cột `slug`/`name_key` + migration v6 — thay đổi schema cho một việc thuần hiển thị; dịch lúc seed (ghi thẳng tiếng Anh vào DB) — sai, làm hỏng dữ liệu và không đổi lại được.

## R7 — Tên **ví mẫu**: KHÔNG dịch (người dùng đã chốt)

- **Quyết định**: `'Tiền mặt'`, `'Vietcombank'`, `'Thẻ tín dụng VIB'`, `'Momo'`, `'Sổ tiết kiệm'` giữ nguyên ở mọi ngôn ngữ. **Không** thêm bản đồ tên ví.
- **Lý do**: người dùng chọn "coi là dữ liệu" — ví là dữ liệu do người dùng sở hữu (và bộ ví mẫu này sẽ bị gỡ khi có dữ liệu thật). Bảng `wallets` cũng không có cờ "do app tạo" như `categories.is_system`, nên muốn dịch sẽ phải khớp theo chuỗi tên — giòn và vô ích.
- **Hệ quả chấp nhận**: chế độ English vẫn còn 2 nhãn ví tiếng Việt ("Tiền mặt", "Sổ tiết kiệm") — đã ghi nhận là ngoại lệ có lý do của SC-006 (dữ liệu, không phải nhãn giao diện). `Vietcombank`/`Momo`/`VIB` vốn là tên riêng, không tính.

## R8 — Màn `03`: tên hàng & dòng phụ **cố định**, không theo `.tr` (người dùng đã chốt)

- **Quyết định**: 4 chuỗi trên 2 hàng là hằng số, không đổi theo ngôn ngữ giao diện:
  - hàng 1: mã `VI`, tên `Tiếng Việt`, dòng phụ `Vietnamese`
  - hàng 2: mã `EN`, tên `English`, dòng phụ `Tiếng Anh`
  Chỉ **tiêu đề app bar** và **ghi chú cuối màn** đi qua `.tr`.
- **Lý do**: mockup `docs/tool/03-ngon-ngu.svg` ghi đúng 4 chuỗi này; quy tắc của nó là "tên ngôn ngữ viết bằng chính ngôn ngữ đó + tên ngôn ngữ kia ở dòng phụ", nên 4 chuỗi bất biến. Người dùng đã chốt phương án "cố định như mockup" (`Tiếng Việt`/`Tiếng Anh` ở đây là **tên riêng của ngôn ngữ**, không tính là nhãn tĩnh sót tiếng Việt theo SC-006).
- **Phương án khác đã xem xét**: dịch tên hàng theo UI (English → hàng 1 thành "Vietnamese") — lệch mockup `03`, và dòng phụ hàng 1 thành "Tiếng Việt" trùng tên hàng.

## R9 — Không dịch: hằng dùng làm `ValueKey`, dữ liệu seed/mẫu, định dạng ngày & tiền

- **Quyết định**:
  - Mọi chuỗi dùng làm `ValueKey`/`Key` **giữ nguyên** (VD `ValueKey('category-child-${child.name}')`, `ValueKey('theme-option-…')`, `ValueKey('category-chip-$name')`) — test đang `find.byKey` theo chúng.
  - `core/transaction/transaction_source.dart`, `core/wallet/wallet_source.dart`, `core/wallet/wallet_presets.dart` (dữ liệu mẫu: tên giao dịch, ghi chú) — **không đụng**: là dữ liệu, không phải nhãn.
  - `core/money_format.dart` (`'đ'`, dấu `.` nghìn) — **không đụng** (FR-011).
- **Lý do**: FR-010 + FR-011 + tránh vỡ test theo key. `date_label.dart` chỉ dịch phần chữ (`'Hôm nay'`, `'Hôm qua'`, `'HÔM NAY'`, `'HÔM QUA'`), giữ nguyên phần `dd/MM/yyyy` — số/ngày không đổi định dạng.

## R10 — Không thêm dependency bên thứ ba

- **Quyết định**: chỉ thêm `flutter_localizations` (SDK). Không thêm `intl`, không thêm package i18n nào.
- **Lý do**: `'đ'` + `dd/MM/yyyy` đã tự viết trong `money_format.dart`/`date_label.dart`; `intl` chỉ cần khi làm màn `04` (Định dạng & Tiền tệ — PBI sau, khi đó `intl` sẽ được thêm kèm `DateFormat`/`NumberFormat`).

## R11 — Kiểm tra phủ bản dịch 100% (SC-006) bằng test, không bằng mắt

- **Quyết định**: thêm `test/sora_translations_test.dart` làm 2 việc:
  1. Quét `lib/**/*.dart` bằng `dart:io`, regex mọi literal gắn `.tr`/`.trArgs`/`.trParams` (VD `'…'` ngay trước `.tr`), assert **mọi khóa đều có bản dịch `'en'`** (bắt lỗi gõ thiếu/đặt sai khóa).
  2. Assert **cả 15 tên trong `CategorySource`** đều có bản dịch `'en'` (các tên này gọi `.tr` qua biến, regex ở bước 1 không bắt được).
- **Lý do**: SC-006 đòi "100% nhãn tĩnh được dịch". Regex bắt được đúng loại lỗi hay xảy ra (quên thêm khóa vào bản đồ). Loại lỗi "quên gắn `.tr`" thì regex không bắt được ⇒ **vẫn phải QA tay** đi hết các màn ở chế độ English (ghi trong `quickstart.md`), không thể thay bằng test.
- **Phương án khác đã xem xét**: test so khớp toàn bộ chuỗi tiếng Việt xuất hiện trong `lib/` với bản đồ — bắt cả comment/dữ liệu seed/`ValueKey` ⇒ đỏ giả liên tục, không dùng được.

## R12 — Màn `03` dựng theo khuôn màn `02` (ThemeScreen)

- **Quyết định**: `LanguageScreen` là bản sao cấu trúc của `ThemeScreen`: `SubPageScaffold` (app bar thương hiệu + back, không bottom nav) + `ListView` card bo `10px`, vòng tròn mã ngôn ngữ, tên + dòng phụ, radio tự dựng cuối hàng, ghi chú cuối màn. Khác biệt: 2 hàng thay vì 3, vòng tròn chứa **chữ mã** (`VI`/`EN`) thay cho icon, và không có dòng phụ mô tả dài.
- **Lý do**: cùng một loại màn "chọn 1 trong N" đã có sẵn khuôn, token màu qua `SoraColors` (đã hỗ trợ dark mode PBI 18), radio tự dựng đã là quy ước của repo. Sao chép khuôn = ít rủi ro bố cục nhất và giữ nhất quán thị giác với màn `02`.
- **Phương án khác đã xem xét**: tách widget "option card" dùng chung cho `02` + `03` — hai màn khác nhau ở ruột vòng tròn (icon vs mã chữ) và số dòng phụ; tách sớm sẽ thành abstraction nửa vời, để nguyên hai bản khi màn thứ ba xuất hiện.

---

## Tổng hợp `NEEDS CLARIFICATION`

| Điểm mở | Trạng thái | Chốt |
|---|---|---|
| Tên ví mẫu có dịch không | ✅ đã hỏi người dùng 2026-09-10 | **Không dịch** — coi là dữ liệu (R7) |
| Tên/dòng phụ 2 hàng màn `03` ở chế độ English | ✅ đã hỏi người dùng 2026-09-10 | **Cố định như mockup** (R8) |
| Cơ chế đổi ngay không cần restart | ✅ giải quyết bằng thực nghiệm | `Get.updateLocale()` (R2) |
| Nơi lưu lựa chọn | ✅ giải quyết | row `locale` trong `AppSettings` (R3) |
