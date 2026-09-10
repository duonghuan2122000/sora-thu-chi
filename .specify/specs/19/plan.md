# Kế hoạch triển khai: Chọn ngôn ngữ hiển thị (Tiếng Việt / English)

**Mã PBI**: 19
**Liên kết spec**: [.specify/specs/19/spec.md](./spec.md)
**Ngày tạo**: 2026-09-10
**Ngữ cảnh kỹ thuật bổ sung từ người dùng**: "viết giải pháp thi công chi tiết cho PBI 19"

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app offline hoàn toàn |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng, DI, state, **và i18n**), Material |
| Thư viện i18n | `flutter_localizations` (SDK) — thêm mới, chỉ để lấy delegate chuẩn cho `vi`/`en`. **Không** thêm package bên thứ ba (R10) |
| Lưu trữ dữ liệu | drift `^2.34.4` + sqlite local. Lựa chọn ngôn ngữ = row `locale` trong bảng key-value `AppSettings` (schema **v5 giữ nguyên**, không migration) |
| Kiểm thử | `flutter_test` — 436 test hiện có; bổ sung test cho tầng locale + màn `03` |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc thù |
| Ràng buộc hiệu năng | Đổi ngôn ngữ phải có hiệu lực **ngay**, không khởi động lại (FR-005). Cơ chế được chọn là reassemble toàn app — chấp nhận một nhịp giật ngắn cho một thao tác hiếm (xem "Rủi ro & ngoại lệ có lý do") |
| Ràng buộc khác | Ngôn ngữ + tài liệu + commit message: tiếng Việt có dấu. Bám Design System (`docs/design-system-app-thu-chi.md`): teal `#0F6E56` cho hành động chính, card bo `10px`, token màu qua `SoraColors` để chạy đúng cả dark mode (PBI 18) |
| Nguồn chân lý nghiệp vụ | `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md` §2 (§2.1 chốt GetX translations; §2.2 chốt ngôn ngữ **tách bạch** với định dạng ngày/số) + mockup `docs/tool/03-ngon-ngu.svg` |

*Không còn mục `NEEDS CLARIFICATION`: 2 điểm mở của spec đã được người dùng chốt (R7, R8 trong `research.md`).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** ⇒ đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Thuần local; chỉ thêm 1 row sqlite |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi tài liệu, comment, commit của PBI này bằng tiếng Việt |
| Stack đã chốt: i18n dùng GetX (§2.1 tài liệu giải pháp) | ✅ | Dùng đúng `GetMaterialApp(translations:)` + `.tr`, không phát minh cơ chế mới |
| Design system: 1 màu thương hiệu teal, card bo `10px`, không hex cứng trong widget | ✅ | Màn `03` dùng token `SoraColors` + `AppColors.teal`, radio tự dựng bám khuôn màn `02` |
| Màn con của shell: app bar thương hiệu + back, **không** bottom nav | ✅ | `SubPageScaffold` — đúng FR-001 |
| Ngôn ngữ **không** đổi định dạng ngày/số (§2.2) | ✅ | Không đụng `money_format.dart`; `date_label.dart` chỉ dịch phần chữ |
| Không sửa dữ liệu người dùng | ✅ | Dịch ở tầng hiển thị; DB không đổi (FR-010) |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Cơ chế i18n** — **Quyết định**: GetX `translations` + `.tr`, **khóa là chuỗi tiếng Việt**. **Lý do**: §2.1 tài liệu đã chốt GetX; khóa tiếng Việt làm 436 test hiện có xanh nguyên vẹn (`String.tr` trả khóa khi `Get.locale == null`). **Phương án khác**: `gen-l10n`/`.arb` — phải luồn `BuildContext` vào cả các hàm sinh nhãn thuần (`date_label`, `theme_mode`, `transaction_list`, `wallet`), kéo theo sửa ~30 file test.
- **Đổi ngôn ngữ tức thì** — **Quyết định**: `Get.updateLocale(locale)` (reassemble), gọi kiểu bắn-và-quên. **Lý do**: đo thực nghiệm — route đang mở **không** tự rebuild khi `MaterialApp.locale` đổi (`LEAF BUILDS before=1 after=1`), còn `Get.updateLocale` thì có (`vi=2 en=0` → `vi=0 en=2`). **Phương án khác**: `Obx` từng màn (boilerplate, dễ sót) · đổi `Key` gốc app (mất stack điều hướng).
- **Nơi lưu** — **Quyết định**: row `locale` = `'vi'`/`'en'` trong `AppSettings`. **Lý do**: bảng đã ghi rõ "PBI sau chỉ thêm row, không thêm migration". **Phương án khác**: secure storage (không phải bí mật) · cột mới (cần migrate vô ích).
- **Bản đồ dịch** — **Quyết định**: chỉ nhánh `'en'`. **Lý do**: khóa đã là tiếng Việt, thiếu nhánh ⇒ `.tr` trả khóa. **Phương án khác**: nhánh `'vi'` 430 dòng lặp y hệt khóa.
- **Chuỗi hệ thống của Flutter** — **Quyết định**: thêm `flutter_localizations` + `supportedLocales [vi, en]` + 3 delegate. **Lý do**: hiện app không set locale nên `MaterialLocalizations` luôn tiếng Anh; đây là phần "hộp thoại/nhãn hệ thống" trong FR-008. **Phương án khác**: bỏ qua (hộp thoại Anh–Việt lẫn lộn, có cảnh báo debug).
- **Tên danh mục mặc định** — **Quyết định**: dịch ở tầng hiển thị bằng `.tr` trên tên (tên mặc định = khóa). **Lý do**: tự động thoả FR-010 (đổi tên/tự tạo ⇒ không khớp khóa ⇒ nguyên văn), không cần cột `slug`/migration. **Phương án khác**: thêm cột khóa + migrate v6 · dịch lúc seed (làm hỏng dữ liệu).
- **Tên ví mẫu** — **Quyết định (người dùng chốt)**: **không dịch**. **Lý do**: ví là dữ liệu; bảng ví không có cờ "do app tạo"; bộ ví mẫu sẽ bị gỡ khi có dữ liệu thật.
- **Nhãn 2 hàng màn `03`** — **Quyết định (người dùng chốt)**: cố định như mockup (`Tiếng Việt`/`Vietnamese`, `English`/`Tiếng Anh`). **Lý do**: đúng mockup ở cả hai chế độ; đây là tên riêng của ngôn ngữ.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — **không đổi schema v5**; 1 row `AppSettings('locale')`; 3 thực thể logic (cài đặt ngôn ngữ, bộ nhãn dịch, ánh xạ tên danh mục mặc định).
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app offline, không có API/CLI/endpoint nào lộ ra ngoài. Hợp đồng nội bộ duy nhất là 2 seam `LocaleStore` (load/save) và `SoraTranslations.keys`, mô tả ngay trong `data-model.md` và trong plan này.
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — 12 nhóm kiểm thử tay A–L, phủ FR-001…FR-013 và SC-001…SC-010.

### Kiến trúc chi tiết

**1. Tầng locale (mới — bám đúng khuôn tầng theme của PBI 18)**

| File mới | Vai trò | Khuôn tham chiếu |
|---|---|---|
| `lib/core/locale/locale_prefs.dart` | `kKeyLocale = 'locale'`; `localeToStorage`/`localeFromStorage` (`'vi'`/`'en'`, giá trị lạ ⇒ `vi`); hằng cặp ngôn ngữ cho màn `03` (mã `VI`/`EN`, endonym, tên ngôn ngữ kia) | `core/theme/theme_mode.dart` |
| `lib/core/locale/locale_store.dart` | `abstract class LocaleStore { Future<Locale?> load(); Future<void> save(Locale); }` — seam bơm fake khi test | `core/theme/theme_store.dart` |
| `lib/core/locale/locale_controller.dart` | `LocaleController extends GetxController`: `Rx<Locale> locale` (mặc định `vi`), `load()`, `setLocale(Locale)` = gán Rx → `Get.updateLocale(locale)` (**không await**) → ghi nối đuôi `_saveTail` (chạm nhanh liên tiếp thì lần cuối thắng) | `core/theme/theme_controller.dart` |
| `lib/core/locale/sora_translations.dart` | `class SoraTranslations extends Translations { keys => {'en': {…}} }` — bản đồ tiếng Anh cho **toàn bộ** nhãn tĩnh | mới |
| `lib/data/locale_store_drift.dart` | `DriftLocaleStore` — upsert đúng key `locale`, không xoá row khác | `data/theme_store_drift.dart` |
| `lib/data/locale_deps.dart` | `ensureLocaleStore()` / `ensureLocaleController()` (Get singleton) | `data/theme_deps.dart` |

**2. Nối vào gốc app (`lib/app.dart`)**

- Tham số mới `localeStore` (seam test, như `themeStore`); `initState` đăng ký `LocaleController` + `load()`.
- Trong `Obx` sẵn có: `GetMaterialApp(translations: SoraTranslations(), locale: localeCtl.locale.value, supportedLocales: [Locale('vi'), Locale('en')], localizationsDelegates: [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate], …)`.
- `load()` chỉ gọi `Get.updateLocale` khi giá trị đã lưu **khác** mặc định ⇒ mở app lần đầu (hoặc đang ở `vi`) không tốn nhịp reassemble, và test không dính reassemble ngoài ý muốn.

**3. Màn `03` — `lib/screens/language_screen.dart` (mới)**

- Dựng theo khuôn `ThemeScreen`: `SubPageScaffold(title: 'Ngôn ngữ'.tr)` + `ListView` 2 card; mỗi card: vòng tròn mã (`VI`/`EN`, hàng đang chọn nền teal chữ trắng, hàng kia nền nhạt chữ xám) → tên + dòng phụ (4 chuỗi **cố định**, R8) → radio tự dựng (chấm teal + tick trắng).
- Trạng thái chọn đọc `Obx` từ `LocaleController.locale` → chạm hàng gọi `setLocale`. `ValueKey('language-option-vi'/'language-option-en')` cho test.
- Ghi chú cuối màn: bản dịch của "Áp dụng ngay cho toàn bộ giao diện, nhãn danh mục mặc định và định dạng ngày/số vẫn giữ theo cài đặt Định dạng & Tiền tệ."
- `SafeArea(top: false)` + `padding` như màn `02`; tên/dòng phụ dùng `maxLines`/`ellipsis` để chịu cỡ chữ lớn (FR-013).

**4. Nối màn `01` (`utilities_screen.dart`)**

- Hàng "Ngôn ngữ": `name: 'Ngôn ngữ'.tr`, `subtitle: 'Ngôn ngữ hiển thị trong ứng dụng'.tr`, `trailing` = `Obx` đọc `LocaleController.locale` → hiện endonym (`Tiếng Việt`/`English`), `onTap: _openLanguageScreen` (điểm vào no-op của PBI 17 nay kích hoạt — FR-001/FR-007).

**5. Dịch toàn bộ nhãn tĩnh còn lại (FR-008) — ~430 chuỗi, 36 file**

| Nhóm | File | Ghi chú riêng |
|---|---|---|
| Shell & điều hướng | `core/widgets/app_bottom_nav_bar.dart` (4), `core/app_shell.dart`, `core/widgets/screen_header.dart` | 4 nhãn nav đổi sang `Overview`/`Transactions`/`Reports`/`Settings` |
| Cài đặt & Tiện ích | `screens/settings_screen.dart` (13), `screens/utilities_screen.dart` (43), `screens/theme_screen.dart` (11), `core/theme/theme_mode.dart` (4), `core/utilities/utilities.dart` (5) | `themeModeLabel` dịch 3 giá trị Sáng/Tối/Theo hệ thống (FR-008 nêu đích danh); dialog hướng dẫn widget (nhiều dòng, có nhánh Android/iOS) dịch cả |
| Ví | `screens/wallet_list_screen.dart` (16), `wallet_detail_screen.dart` (16), `wallet_form_screen.dart` (40), `wallet_transfer_screen.dart` (22), `core/wallet/wallet.dart` (7) | `wallet.dart:93` `'Đã dùng X / Y đ'` → `trParams`; `:96` `'$name (đã ẩn)'` → hậu tố dịch. **Tên ví không dịch** (R7) |
| Giao dịch | `screens/add_transaction_screen.dart` (28), `transaction_screen.dart` (21), `transaction_detail_screen.dart` (22), `core/transaction/transaction_list.dart` (22), `transaction_filter.dart` (15), `transaction_detail.dart` (8), `core/date_label.dart` (13) | `date_label`: dịch `'Hôm nay'`/`'Hôm qua'`/`'HÔM NAY'`/`'HÔM QUA'`, giữ `dd/MM/yyyy`; `transaction_list`: fallback `'Ví'` + tên danh mục hiển thị phải đi qua `.tr` (R6) |
| Danh mục | `screens/category_list_screen.dart` (17), `category_form_screen.dart` (29), `category_child_list_screen.dart` (12), `category_sort_screen.dart` (9), `category_picker_screen.dart` (12), `core/widgets/category_row.dart` (3), `core/category/category_form.dart` (5) | Chuỗi đếm dùng `trParams` (`'@n danh mục con'`, `'Chưa có danh mục @loại nào.'`, `'Không có danh mục @loại nào để sắp xếp.'`, `'@tên (gồm con)'`); tên danh mục hiển thị → `name.tr`; nhãn `'Đã ẩn'` dịch |
| Bảo mật | `screens/pin/pin_setup_screen.dart` (8), `pin/pin_lock_screen.dart` (4) | `'… thử lại sau @giây giây.'` → `trParams` |
| Khung Tổng quan/Báo cáo | `screens/dashboard_screen.dart` (1), `screens/report_screen.dart` (1) | Chỉ tiêu đề màn (chưa có nội dung nghiệp vụ) |

**Quy tắc khi dịch (bắt buộc tuân thủ, tránh vỡ test & sai phạm vi)**
- **Không** dịch: chuỗi dùng làm `ValueKey`/`Key`; `*_source.dart` (dữ liệu seed/mẫu); `money_format.dart` (`đ`, dấu `.`); tên riêng/thương hiệu; tên ví (R7); 4 chuỗi cố định màn `03` (R8); nội dung `'Sora Thu Chi'` (brand).
- Chuỗi có nội dung động → `trParams({'x': …})`, không nối chuỗi thủ công.
- `const Text('…')` mất `const` khi gắn `.tr` — chấp nhận, không dùng mẹo giữ `const`.
- Dịch xong mỗi nhóm → thêm khóa tương ứng vào `SoraTranslations` **ngay trong cùng bước**, không để nợ.

**6. Test (mới + sửa tối thiểu)**

| File | Nội dung |
|---|---|
| `test/locale_prefs_test.dart` (mới) | map `'vi'/'en'` ↔ `Locale`; giá trị lạ/`null` ⇒ `vi`; hằng cặp ngôn ngữ đúng mockup |
| `test/locale_store_drift_test.dart` (mới) | Ghi rồi đọc lại 1 row `locale`; **không xoá** row `themeMode` khác (FR-012) |
| `test/locale_controller_test.dart` (mới) | `load()` đọc đúng; `setLocale` đổi Rx + gọi save; chạm nhanh liên tiếp → lần cuối thắng; `setLocale` cùng giá trị ⇒ no-op |
| `test/language_screen_test.dart` (mới) | 2 hàng đúng thứ tự + nội dung; mặc định radio Tiếng Việt; chạm `English` → radio chuyển + `Get.locale` = `en` **và nhãn một route khác đang mở đổi theo** (FR-005, dùng lại kỹ thuật probe 2); quay lại màn `01` → hàng Ngôn ngữ hiện `English` (FR-007) |
| `test/sora_translations_test.dart` (mới) | Quét `lib/**/*.dart` tìm literal gắn `.tr`/`.trArgs`/`.trParams` → mọi khóa phải có bản dịch `'en'`; cả 15 tên `CategorySource` phải có bản dịch (R11) |
| `test/utilities_screen_test.dart` (sửa) | Thêm: hàng Ngôn ngữ mở được `LanguageScreen`; phần cuối hàng đổi theo lựa chọn |
| `test/pin_flow_test.dart` (sửa) | `SoraApp(store: …, themeStore: …, localeStore: FakeLocaleStore())` — tránh chạm drift thật khi boot |
| `test/fakes/fake_locale_store.dart` (mới) | Fake bám `fake_theme_store.dart` |

Test hygiene: các test đụng `Get.locale`/translations phải khôi phục trong `addTearDown` (`Get.locale = null`), tránh rò rỉ ngôn ngữ sang test khác trong cùng file.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline, không server | ✅ | Chỉ thêm row sqlite + package SDK |
| Không đổi dữ liệu người dùng (FR-010) | ✅ | Dịch ở tầng hiển thị; DB không có thao tác ghi nào ngoài row `locale` |
| Định dạng ngày/số tách khỏi ngôn ngữ (§2.2) | ✅ | `money_format.dart` không đụng; `date_label` chỉ dịch phần chữ |
| Không phá vỡ test hiện có | ✅ (có kiểm chứng) | Khóa = tiếng Việt ⇒ `.tr` trả khóa khi `Get.locale == null`; chỉ 2 file test phải sửa (do boot app/injection) |
| Design system + dark mode (PBI 18) | ✅ | Màn `03` dùng `SoraColors`/`AppColors`, không hex cứng |
| Không thêm dependency bên thứ ba | ✅ | Chỉ `flutter_localizations` (SDK) |
| YAGNI / không abstraction sớm | ✅ | Không tách widget card dùng chung `02`+`03`; không bảng ánh xạ riêng cho danh mục; không nhánh `vi` thừa |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── pubspec.yaml                                  # + flutter_localizations (SDK)
├── lib/
│   ├── app.dart                                  # SỬA: translations + locale + delegates + LocaleController
│   ├── core/
│   │   ├── locale/                               # MỚI (4 file)
│   │   │   ├── locale_prefs.dart
│   │   │   ├── locale_store.dart
│   │   │   ├── locale_controller.dart
│   │   │   └── sora_translations.dart            # bản đồ 'en' (~430 khóa)
│   │   │   └── (SỬA) date_label.dart · theme/theme_mode.dart · utilities/utilities.dart
│   │   │   └── (SỬA) transaction/*.dart · category/*.dart · wallet/wallet.dart · widgets/*.dart
│   ├── data/
│   │   ├── locale_store_drift.dart               # MỚI
│   │   └── locale_deps.dart                      # MỚI
│   └── screens/
│       ├── language_screen.dart                  # MỚI — màn 03
│       └── (SỬA) settings · utilities · theme · wallet_* · category_* · transaction_* · search_filter · dashboard · report · pin/*
└── test/
    ├── fakes/fake_locale_store.dart              # MỚI
    ├── locale_prefs_test.dart · locale_store_drift_test.dart · locale_controller_test.dart
    ├── language_screen_test.dart · sora_translations_test.dart   # MỚI
    └── (SỬA) utilities_screen_test.dart · pin_flow_test.dart
```

Không tạo `contracts/`: dự án thuần nội bộ, không có giao diện lộ ra ngoài.

## Rủi ro & ngoại lệ có lý do

1. **Ngoại lệ có lý do — reassemble toàn app khi đổi ngôn ngữ.** `Get.updateLocale()` gọi `reassembleApplication()`, dựng lại toàn bộ cây widget (giữ state, không mất stack điều hướng) thay vì chỉ rebuild phần phụ thuộc. Đây là **ngoại lệ có lý do** so với nguyên tắc "rebuild tối thiểu": bằng chứng thực nghiệm cho thấy Flutter **không** rebuild route đang mở khi `locale` đổi (probe: `LEAF BUILDS before=1 after=1`), nên nếu không reassemble thì FR-005 (nhãn đổi ngay ở màn đang mở và mọi màn khác) không đạt được nếu không rải `Obx` khắp ~15 màn. Thao tác này chỉ xảy ra khi người dùng chủ động đổi ngôn ngữ (rất hiếm), không nằm trên đường đi nóng. **Giảm nhẹ**: chỉ gọi khi giá trị thật sự đổi (no-op nếu chạm lại hàng đang chọn), và chỉ gọi khi giá trị đã lưu khác mặc định lúc boot.
2. **Sót nhãn tĩnh** (quên gắn `.tr`) — test quét literal (R11) chỉ bắt được lỗi "gắn `.tr` mà thiếu khóa", **không** bắt được lỗi "quên gắn `.tr`". Đây là rủi ro cao nhất của PBI (SC-006 đòi 100%) ⇒ bắt buộc QA tay nhóm K của `quickstart.md` đi hết mọi màn ở chế độ English, gạch đầu dòng từng màn.
3. **Rò rỉ `Get.locale` giữa các test** — biến toàn cục của GetX. Nếu một test để lại `en`, các assert chuỗi Việt phía sau trong **cùng file** sẽ đỏ. Giảm nhẹ: mọi test đụng locale phải khôi phục trong `addTearDown`. (Mỗi file test chạy trong isolate riêng nên không lây sang file khác.)
4. **Reassemble trong môi trường test** — `await Get.updateLocale(...)` làm test **treo** (fake async không bao giờ hoàn tất). Giảm nhỉ: gọi bắn-và-quên rồi `pump`; ghi rõ trong test để người sau không `await`.
5. **Test boot app phải bơm `localeStore`** — quên bơm ⇒ `ensureLocaleStore()` tạo drift thật ⇒ `getApplicationDocumentsDirectory()` ném `MissingPluginException`. Chỉ ảnh hưởng `pin_flow_test` (đã liệt kê trong danh sách sửa).
6. **Chất lượng bản dịch tiếng Anh** — nội dung do đội dự án biên soạn (giả định của spec), không kiểm duyệt chuyên nghiệp. Rủi ro: thuật ngữ không nhất quán giữa các màn (VD "Giao dịch" lúc `Transactions` lúc `Transactions list`). Giảm nhẹ: chốt thuật ngữ theo bảng nhãn điều hướng + tiêu đề màn ngay từ nhóm đầu, dùng lại đúng từ đó cho các màn con.
7. **Nhãn tiếng Anh dài hơn tiếng Việt** ở cỡ chữ lớn → tràn/cắt. Giảm nhỉ: giữ `maxLines`/`ellipsis`/`FittedBox` sẵn có, không bỏ; màn `03` bọc `Expanded` + `maxLines` như màn `02`; QA nhóm J.
8. **Cỡ chữ/ngôn ngữ hệ thống của widget Material đổi hành vi** khi thêm `flutter_localizations` (hộp thoại, date picker chuyển từ tiếng Anh sang tiếng Việt ở chế độ mặc định). Đã kiểm: không test nào bấm nút hộp thoại hệ thống ⇒ không vỡ test; QA nhóm K bao gồm cả date picker.

## Việc bàn giao kèm (ngoài code)

- Cập nhật `spec.md` mục "Điểm cần làm rõ": đánh dấu 2 điểm đã chốt (tên ví mẫu — không dịch; nhãn 2 hàng màn `03` — cố định như mockup) và tick lại checklist `checklists/requirements.md`.
- Đồng bộ wiki (`wiki-knowledge/`) sau khi thi công: page **Hồ sơ & Bảo mật** (cài đặt tiện ích: thêm ngôn ngữ, row `AppSettings('locale')`), page **Lộ trình phát triển** (đóng mục mở tương ứng, ghi PBI 19 đã xong), page **Danh mục** (quy tắc dịch tên danh mục mặc định ở tầng hiển thị) + append `wiki-knowledge/log.md` — theo skill `sora-wiki`.
