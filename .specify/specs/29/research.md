# Nghiên cứu kỹ thuật: Cấu hình nhắc nhập giao dịch hằng ngày (màn 02)

**Mã PBI**: 29
**Liên kết spec**: [spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

> Spec đã "Đã làm rõ" (Q1=B, Q2=A, Q3=A — chốt 2026-09-13) ⇒ **không còn
> `NEEDS CLARIFICATION`**. Các mục dưới đây là quyết định triển khai còn lại.

---

## R1 — Nơi lưu tập ngày trong tuần

- **Quyết định**: thêm **1 khoá nữa vào chính row JSON đang có**
  (`AppSettings(key='notificationPrefs')`, PBI 28): `"dailyWeekdays":[1,2,3,4,5,6,7]`.
  **Không** schema mới, **không** migration (giữ **v8**), **không** `build_runner`.
- **Lý do**: row đó đã là "cấu hình của loại nhắc hàng ngày" — ngày trong tuần là
  tham số của **cùng loại nhắc** đó (doc §3.1 gom `weekdays` vào `config` của
  `NotificationRule`). Ghi cùng row ⇒ 1 upsert nguyên khối, không có trạng thái
  nửa vời (giờ lưu mới mà ngày còn cũ). Parse tolerant sẵn có (PBI 28 R4) tự lo
  phần "row cũ thiếu khoá" ⇒ **đúng FR-013/kịch bản 16** mà không cần code migrate.
- **Phương án khác đã xem xét**: (a) row `notificationPrefsWeekdays` riêng — 2 lần
  đọc/ghi, có thể lệch nhau, không lợi gì; (b) bảng drift `notification_rules`
  (doc §3.1) — v9 + migration + `build_runner` cho dữ liệu mà **chưa engine nào
  đọc** (ngoài phạm vi, Q1 của PBI 28); (c) `shared_preferences` — package mới,
  lệch quy ước "mọi cài đặt nằm trong drift".

## R2 — Kiểu dữ liệu của tập ngày: `List<int>` chứ không `Set<int>`

- **Quyết định**: `List<int> dailyWeekdays` — **đã sắp tăng**, **khác rỗng**, phần
  tử ∈ `1…7` (`1` = Thứ Hai … `7` = Chủ Nhật, ISO-8601 — cùng quy ước tuần bắt đầu
  Thứ Hai của `budget_view`/`report_view`).
- **Lý do**: (a) `Set` không có equality theo giá trị ⇒ `NotificationPrefs.==`/
  `hashCode` (đang viết tay) phải sort/copy mỗi lần so; (b) danh sách đã sắp là
  dạng cần cho **nén dải liên tiếp** ở dòng phụ màn `01` (R10) — không phải sắp
  lại lúc hiển thị; (c) JSON round-trip giữ nguyên thứ tự, test round-trip đơn
  giản. Miền 7 phần tử ⇒ `contains` O(7) không thành vấn đề.
- **Phương án khác đã xem xét**: `Set<int>` (equality thủ công, thứ tự JSON không
  ổn định ⇒ round-trip phải sort hai đầu); bitmask `int` (khó đọc trong DB, khó
  debug khi sửa tay — DB là dữ liệu người dùng); 7 cờ `bool` riêng (28 trường cho
  một class, `copyWith` phình, dòng phụ phải gom lại 7 cờ).

## R3 — Bất biến "luôn ≥1 ngày" đặt ở tầng nào

- **Quyết định**: ở **tầng model**, bằng phương thức `toggleDay(int)` trên
  `NotificationPrefs`: ngày đang bật → bỏ khỏi tập; ngày đang tắt → thêm vào; nếu
  phép bỏ sẽ làm tập **rỗng** → trả về **chính object hiện tại** (`identical`), 0
  thay đổi. Thêm `bool isEveryDay` cho dòng phụ màn `01`.
- **Lý do**: FR-009 là bất biến của **dữ liệu** ("không tồn tại trạng thái 0
  ngày"), không phải của widget — để trong model thì mọi đường ghi (màn hôm nay,
  engine/backup sau này) đều không tạo được dữ liệu sai, và test tầng thuần kiểm
  được không cần binding. `identical` cho phép UI biết "không có gì đổi".
- **Phương án khác đã xem xét**: chặn ở `onTap` của chip (mỗi đường ghi mới phải
  nhớ chặn lại, và dữ liệu hỏng sửa tay vẫn vào được); hiện hộp thoại/thông báo
  (FR-009 cấm); cho phép rỗng rồi coi rỗng = "mỗi ngày" (hai nghĩa cho một trạng
  thái, dòng phụ phải diễn giải lại — bẫy).

## R4 — Khối chọn giờ: mũi tên bấm, không phải trục cuộn quán tính

- **Quyết định**: mỗi cột (giờ, phút) là **1 `Column` tĩnh**: mũi tên **tăng** →
  giá trị **lân cận trên** → giá trị **đang chọn** (lớn, teal) → giá trị **lân cận
  dưới** → mũi tên **giảm**; bấm mũi tên đổi **1 đơn vị**, quay vòng bằng
  `(v + delta + n) % n`. Lân cận **cũng quay vòng** (`23 → 00`).
- **Lý do**: mockup vẽ **đúng** mũi tên trên/dưới (không có dấu hiệu trục cuộn tự
  do), và **mọi tiêu chí đo được** (SC-003 miền 0–23/0–59 + quay vòng hai đầu; edge
  case "chạm liên tục → không nhảy ngoài miền") đều thoả bằng phép `%` thuần —
  không cần `ScrollController`, animation cuộn, hay canh giữa item. Nút bấm còn có
  vùng chạm ≥40 px sẵn (tốt hơn trục cuộn cho người dùng lớn tuổi).
- **Phương án khác đã xem xét**: `ListWheelScrollView`/`CupertinoPicker` (thêm
  controller + canh giữa + `onSelectedItemChanged` + xử lý quán tính; giá trị
  "đang chọn" khó đọc chính xác khi cỡ chữ lớn — rủi ro FR-017); `showTimePicker`
  của hệ điều hành (**spec cấm** — giả định "màn tự dựng khối chọn giờ/phút");
  `TextField` số (không giống mockup, phải validate tay).

## R5 — "Dải nền nhạt" đánh dấu hàng đang chọn

- **Quyết định**: dải = **nền của chính ô giá trị đang chọn** (mỗi cột một dải,
  hai cột cùng bề rộng cố định nên hai dải thẳng hàng nhau), màu
  `AppColors.teal.withValues(alpha: 0.08)`, bo góc 6. **Không** dùng
  `Stack`/`Positioned` với toạ độ cứng cho một dải chạy ngang qua cả hai cột.
- **Lý do**: mockup vẽ một dải liền `x=60…330` (đè cả dấu `:`), nhưng đó là **chi
  tiết đồ hoạ**, còn FR-003 chỉ đòi "có dải nền nhạt đánh dấu hàng đang chọn". Dải
  theo ô giá trị đạt đúng mục đích đó mà **không phụ thuộc chiều cao cố định của
  từng hàng** ⇒ không vỡ khi `textScaleFactor` lớn (FR-017/SC-012) — đây chính là
  chỗ toạ độ cứng sẽ vỡ (số 26 px thành 52 px).
- **Phương án khác đã xem xét**: `Stack` + `Positioned(top: hằng số)` (vỡ ở cỡ chữ
  lớn); kẻ `Divider` ngang qua khối như mockup (thêm 1 chi tiết nữa cũng không
  được FR nào yêu cầu); tô nền cả khối thời gian (mất tương phản dải đang chọn).

## R6 — Chip ngày: `Wrap` + vòng tròn tự vẽ, không dùng `ChoiceChip`

- **Quyết định**: 7 chip = `InkWell` bọc `Container` **tròn 36 px** (mockup
  `r=18`), nhãn 12 px w600, đặt trong `Wrap(spacing: 10, runSpacing: 10)`. Đang
  chọn: nền `AppColors.teal`, chữ `AppColors.white`; không chọn: nền
  `colors.surface`, viền `colors.divider`, chữ `colors.tabInactive`. Nhãn chip
  bọc `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.4)`.
- **Lý do**: mockup là vòng tròn **đặc** đổi màu — không phải chip Material (viền
  pill/`checkmark`/padding riêng của `ChoiceChip` sẽ lệch hình); vòng tròn tự vẽ
  cho đúng màu và đúng "chạm là đổi ngay" (FR-004). `Wrap` thoả FR-017/edge case
  "chip xuống hàng khi màn hẹp" mà không cần tính bề rộng. Clamp 1.4 giữ nhãn 2 ký
  tự nằm gọn trong vòng 36 px ở cỡ chữ hệ thống lớn nhất (7 chip vẫn đủ chỗ trên
  1 hàng ở 360 px: 7×36 + 6×10 = 312 < 320).
- **Phương án khác đã xem xét**: `ChoiceChip`/`FilterChip` (hình và màu theo
  Material theme, phải override nhiều thứ để giống mockup); `Row` cứng (tràn ở
  màn hẹp / cỡ chữ lớn — chính là rủi ro FR-017 nêu tên); vòng tròn co giãn theo
  `Flexible` (chip méo, không còn tròn).

## R7 — Vị trí nút "Lưu thay đổi"

- **Quyết định**: ghim ở **đáy màn** qua `bottomNavigationBar` của
  `SubPageScaffold` (`SafeArea` + `Padding(20,10,20,12)` + `SizedBox(height: 44,
  width: double.infinity)` + `ElevatedButton` nền `AppColors.teal`, chữ trắng, bo
  8) — **nguyên khuôn** `wallet_form_screen`, `budget_form_screen`,
  `category_form_screen`, `add_transaction_screen`.
- **Lý do**: (a) FR-017/SC-012 đòi "cuộn tới được nút Lưu" — nút ghim thì **luôn**
  tới được, kể cả cỡ chữ lớn nhất, không phụ thuộc việc cuộn hết danh sách; (b) 4
  màn form đã QA của app đều ghim nút chính ở đáy ⇒ người dùng thấy cùng một chỗ;
  (c) mockup vẽ nút cuối nội dung, nhưng màn 360×640 của mockup **không có**
  trường hợp cỡ chữ lớn — mockup không phải nguồn cho hành vi cuộn.
- **Phương án khác đã xem xét**: đặt nút trong `ListView` (giống mockup tuyệt đối,
  nhưng ở cỡ chữ lớn nhất người dùng phải cuộn mới thấy nút, và QA phải cuộn mới
  kiểm được — SC-012 chỉ "đạt được" chứ không "thấy ngay"); `FloatingActionButton`
  (FR-002 cấm FAB ở màn con này).

## R8 — Ngữ nghĩa ghi: bản nháp, chỉ ghi khi bấm Lưu

- **Quyết định**: màn `02` giữ **một** field `NotificationPrefs _draft` (nạp 1 lần
  từ `store.load()`); mọi thao tác (mũi tên, chip, công tắc) chỉ `setState` đổi
  `_draft`; **chỉ** `_save()` khi bấm "Lưu thay đổi" mới gọi `store.save(_draft)`
  rồi `Get.back()`. Back giữa chừng **không** ghi gì. **Không** ghi lại bộ vừa đọc
  khi mở màn (khác màn `01` — PBI 28 R2 ghi để seed mặc định; ở đây **không cần
  seed**: mặc định đã được màn `01` ghi từ PBI 28, và row cũ thiếu khoá ngày vẫn
  đọc ra đúng nhờ parse tolerant R1).
- **Lý do**: FR-007/SC-014 nói rõ "chỉ ghi khi bấm Lưu" và "back bỏ thay đổi,
  không hỏi lại" (Q2=A) — mô hình bản nháp là cách diễn đạt trực tiếp nhất, **0**
  cờ `dirty`, **0** hộp thoại xác nhận, **0** nhánh khôi phục. Dùng một
  `NotificationPrefs` làm bản nháp ⇒ tái dùng `copyWith`/`toggleDay` đã có test,
  không phải giữ 4 biến rời (`_hour`, `_minute`, `_days`, `_onlyIfNoTxn`) rồi ghép
  lại lúc lưu.
- **Phương án khác đã xem xét**: ghi ngay mỗi thao tác như màn `01` (**sai**
  FR-007/SC-014: back phải bỏ thay đổi); hộp thoại "bỏ thay đổi?" khi back
  (ngoài phạm vi — Q2=A nói rõ không hỏi); 4 biến rời + hàm ghép (thêm code, dễ
  lệch trường).
- **Nhánh lỗi**: giữ **khuôn 3 nhánh** của màn `01`/PBI 17 — `_loading` → spinner;
  lỗi đọc → "Không đọc được cài đặt." + nút **Thử lại** (tái dùng khoá dịch sẵn
  có); ghi lỗi → bỏ qua rồi vẫn `back` (đồng bộ cách chịu lỗi của màn `01`: lần
  lưu sau ghi lại toàn trạng thái, không có nửa vời).

## R9 — Hai vùng chạm của hàng "Nhắc nhập giao dịch hằng ngày" (FR-001)

- **Quyết định**: sửa `_itemRow` ở màn `01`: **vùng chạm** = hàng **trừ** phần
  `trailing` — bọc `InkWell` quanh cụm `[vòng tròn icon + cột tiêu đề/dòng phụ]`,
  để `trailing` (công tắc) **ngoài** `InkWell`. `_switchRow` thêm tham số
  `onTap` (mặc định null ⇒ hành vi cũ y nguyên cho 5 hàng công tắc còn lại).
- **Lý do**: hiện `_itemRow` bọc `InkWell` quanh **cả** `Row` — nếu chỉ truyền
  `onTap` cho hàng nhắc hàng ngày thì chạm công tắc sẽ **vừa** đổi trạng thái **vừa**
  mở màn `02` (vi phạm FR-001 + kịch bản chấp nhận 1). Tách vùng chạm ngay trong
  widget dùng chung của màn là sửa **một chỗ** cho cả hàng này lẫn 2 hàng chevron
  (chevron chỉ mất phản hồi mực ở đúng 12 px của icon — không đổi hành vi "chạm
  không mở gì" đã QA ở PBI 28).
- **Phương án khác đã xem xét**: dựng riêng một hàng mới chỉ cho nhắc hàng ngày
  (nhân đôi `_itemRow` ~50 dòng, dễ lệch giao diện với các hàng khác); cho
  `Switch` chặn sự kiện bằng `GestureDetector` bao ngoài (phụ thuộc thứ tự
  hit-test, mong manh); thêm hàng chevron riêng dưới hàng công tắc (mockup `01`
  **không** đổi — Q1=B chốt rõ).
- **Điều hướng**: `Get.to(() => DailyReminderConfigScreen(store: _store))` — truyền
  **chính** store của màn `01` (không gọi lại `ensureNotificationStore()`), giữ
  đúng 1 connection drift và cho test bơm fake qua màn `01`.

## R10 — Dòng phụ màn `01` khi tập ngày không phải cả tuần (FR-011)

- **Quyết định**: đủ 7 ngày → giữ **nguyên** chuỗi cũ `'@giờ mỗi ngày'` (hành vi
  PBI 28 không đổi, kịch bản 15). Thiếu ngày → chuỗi mới
  `'@giờ vào @ngày'` với `@ngày` dựng bởi hàm thuần: **nén dải liên tiếp có độ dài
  ≥3** thành `T2–T7`, các ngày lẻ liệt kê rời, phân cách `, ` (VD `T2–T7, CN` —
  đúng ví dụ ở kịch bản chấp nhận 13; `T2–T4, T6` cho tập `[1,2,3,5]`). Hậu tố
  `' · chỉ nhắc nếu chưa ghi'` giữ nguyên khi cờ bật.
- **Lý do**: FR-011 đòi "liệt kê các ngày đang chọn"; kịch bản 13 đưa **ví dụ** ở
  dạng dải `T2–T7, CN` ⇒ bám ví dụ để QA đối chiếu được, vẫn đúng tinh thần "liệt
  kê" khi tập ngày rời rạc. Ngưỡng nén **≥3** là mức tối thiểu để `T2–T7` xuất
  hiện mà không biến `T2, T3` (2 ngày) thành `T2–T3` (dài bằng, khó đọc hơn).
- **Phương án khác đã xem xét**: liệt kê rời hết (`T2, T3, T4, T5, T6, T7, CN` —
  dài, lệch ví dụ kịch bản 13); nén **mọi** dải ≥2 (`T2–T3` cho 2 ngày — lệch ví
  dụ, khó đọc); nén ở **tầng model** (model sinh chuỗi hiển thị = trộn i18n vào
  dữ liệu — trái khuôn `NotificationPrefs` đang thuần dữ liệu).
- **Vị trí code**: đặt **cùng chỗ** với các hàm nhãn khác — `lib/core/date_label.dart`
  (nhà sẵn có của `formatClock`/`relativeDayLabel`, đã import `get`), thành 2 hàm
  thuần `dayLabel(int)` + `daysLabel(List<int>)`. **Lý do**: **hai màn** cùng cần
  nhãn ngày (màn `01` dòng phụ, màn `02` nhãn chip) — chép 9 dòng ở hai file là
  đúng kiểu trùng lặp khó đồng bộ; và ở `date_label.dart` thì unit test cạnh
  `date_label_test.dart` sẵn có, không cần widget test chỉ để kiểm chuỗi.
- **Nhãn ngày** sinh bằng `switch` **literal trước `.tr`** (`'T2'.tr`…) để
  `sora_translations_test` còn ràng buộc được (R11).

## R11 — i18n: nhãn ngày và các khoá mới

- **Quyết định**: nhãn chip ngày sinh trong `switch` **literal trước `.tr`**:
  `1 => 'T2'.tr, 2 => 'T3'.tr, … 7 => 'CN'.tr`. Thêm vào nhánh `_en`:
  `T2…CN` → `Mon Tue Wed Thu Fri Sat Sun`; các nhãn tĩnh mới của màn (`'Nhắc nhập
  giao dịch'`, `'THỜI GIAN NHẮC'`, `'LẶP LẠI VÀO CÁC NGÀY'`, `'Chỉ nhắc nếu chưa
  ghi giao dịch'`, `'Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập'`, `'XEM TRƯỚC THÔNG
  BÁO'`, `'Đừng quên ghi lại thu chi hôm nay nhé!'`, `'Lưu thay đổi'`, `'@giờ vào
  @ngày'`). **Không** dịch: `'Sora Thu Chi'` (thương hiệu), giờ `HH:mm`, dấu `:`,
  dấu `–`/`, `.
- **Lý do**: `sora_translations_test` chỉ bắt literal **ngay trước** `.tr` ⇒ gom
  nhãn vào một `const List` chuỗi sẽ **lọt lưới** test (thiếu bản dịch EN vẫn
  xanh) — đúng lỗi mà PBI 19 dựng test để chặn. `switch` vừa giữ được ràng buộc,
  vừa là 7 dòng.
- **Phương án khác đã xem xét**: `const Map<int, String>` (lọt lưới test); dùng
  tên ngày đầy đủ (`'Thứ Hai'` — mockup dùng nhãn ngắn `T2`, và chip 36 px không
  chứa nổi); `intl`/`DateFormat.E` (thêm package cho 7 nhãn cố định — trái "0
  dependency mới").

## R12 — Khối "Xem trước thông báo": mô phỏng tĩnh, giờ động

- **Quyết định**: `Container` bo 10, viền `colors.divider`, nền `colors.surface`;
  bên trong: vòng tròn 28 px nền `colors.tealLightBg` + chữ **`'S'`** màu
  `colors.tealOnNeutral`; cột `[tên app 'Sora Thu Chi' (không dịch) + câu nội dung
  dịch]`; giờ `formatClock(_draft.dailyHour, _draft.dailyMinute)` **căn phải, cùng
  hàng tên app** (mockup `x=320`). Giờ đọc trực tiếp từ `_draft` trong `build` ⇒
  đổi ngay trong cùng nhịp chạm (SC-004), không cần cờ riêng, không cần rebuild
  thủ công.
- **Lý do**: mockup là **mô phỏng** một thông báo hệ thống — nội dung tĩnh (spec
  giả định: câu nội dung **không** đổi theo cờ hay tập ngày). Chữ `'S'` thay vì
  ảnh logo: logo thật (`assets/brand/coin_flow_logo.png`, PBI 25) được thiết kế
  cho **nền teal** (kèm vòng trắng) nên đặt trên vòng `tealLightBg` sẽ lệch hệ màu;
  mockup cũng vẽ chữ `'S'`.
- **Phương án khác đã xem xét**: dùng `Image.asset` logo (lệch màu như trên, thêm
  phụ thuộc asset vào màn); icon Material `notifications` (mockup không vẽ vậy);
  cho câu nội dung đổi theo cờ "chỉ nhắc nếu chưa ghi" (spec giả định **không** —
  và engine mới là nơi quyết định nội dung thật).

## R13 — Không chạm engine/quyền (FR-014, SC-009)

- **Quyết định**: **0** dependency mới, **0** plugin native, **0** dòng code xin
  quyền/lên lịch (`flutter_local_notifications` **không** được import). Màn chỉ
  gọi `NotificationStore`.
- **Lý do**: FR-014 + SC-009 đo "0 thông báo, 0 lần hỏi quyền, 0 lịch"; engine là
  PBI sau (đồng bộ Q1 của PBI 28). Tránh cả việc vô tình kéo package thông báo vào
  (`pubspec.yaml` không đổi).
- **Phương án khác đã xem xét**: xin quyền trước cho "sẵn sàng" (SC-009 **đỏ**,
  và trái UX soft-ask của doc §3.3); lên lịch thử một nhắc (ngoài phạm vi, cần
  `timezone` + channel + quyền).

## R14 — Kiểm thử

- **Quyết định**: **1 file mới** (`daily_reminder_config_screen_test.dart`;
  `test/fakes/fake_notification_store.dart` đã có sẵn từ PBI 28 — **tái dùng**,
  chỉ sửa nếu thiếu khả năng assert), **4 file sửa**: `date_label_test.dart`
  (`dayLabel`/`daysLabel` — 4 tập ngày mẫu), `notification_prefs_test.dart` (luật
  tập ngày), `notification_settings_screen_test.dart` (2 vùng chạm + dòng phụ theo
  tập ngày), `dark_theme_smoke_test.dart` (màn `02` vào smoke tối).
- **Lý do**: đúng khuôn PBI 28 (tầng thuần test luật; màn test bằng store giả —
  không cần sqlite native nên chạy được cả trên host Windows).
- **Chi tiết từng file**: xem [quickstart.md](./quickstart.md) §3.

## R15 — Bàn giao & xếp lớp file

- **Quyết định**: màn `02` = `lib/screens/daily_reminder_config_screen.dart`
  (class `DailyReminderConfigScreen`), nhận `NotificationStore? store` (khuôn màn
  `01`); màn `01` truyền store của nó khi push (R9). **Không** thêm file core,
  **không** thêm controller, **không** thêm widget dùng chung.
- **Lý do**: đặt cùng thư mục `screens/` như màn `01` (module Thông báo chưa có
  thư mục riêng); state cục bộ đủ vì chỉ **một** màn tiêu thụ bản nháp, và dữ liệu
  bền duy nhất là row JSON sẵn có.
- **Phương án khác đã xem xét**: GetX controller cho bản nháp (màn duy nhất dùng —
  trái khuôn PBI 17/28, thêm file + vòng đời phải tự quản); thư mục
  `lib/screens/notification/` (chỉ 2 file, đổi đường dẫn file cũ = diff nhiễu).

## R16 — Không làm (ngoài phạm vi, giữ nguyên trong spec)

Engine bắn thông báo + `flutter_local_notifications`/`timezone`; xin quyền &
channel; màn `03` Trung tâm thông báo, màn `04` mẫu thông báo; nhiều khung giờ /
nhắc lặp trong ngày / nhắc theo khoảng; sửa nội dung thông báo; hộp thoại xác nhận
bỏ thay đổi; đưa cấu hình vào backup/restore JSON (GĐ3); bảng
`NotificationRule`/`NotificationLog` (doc §3.1 — chỉ có nghĩa khi engine tồn tại).
