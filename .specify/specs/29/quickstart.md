# Khởi động nhanh & kiểm thử tay: Cấu hình nhắc nhập giao dịch hằng ngày

**Mã PBI**: 29
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md) · [data-model.md](./data-model.md) · [research.md](./research.md)
**Ngày tạo**: 2026-09-13

---

## 1. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get            # KHÔNG có dependency mới — không sửa pubspec.yaml
flutter analyze            # phải sạch
flutter test               # mốc trước PBI: 1004 pass + 1 test đỏ CÓ SẴN (xem §5)
flutter run                # chọn emulator/máy thật
```

**Trạng thái cần có để QA đủ nhóm**:

| Thứ cần có | Cách tạo | Dùng cho nhóm |
|---|---|---|
| App mới cài, **chưa từng mở** màn Thông báo & nhắc nhở | Gỡ app rồi cài lại (`flutter run` sạch dữ liệu) | G (mặc định lần đầu) |
| **DB cũ kiểu PBI 28** (row `notificationPrefs` **thiếu** khoá `dailyWeekdays`) | Cài bản trước PBI 29 → dùng qua màn `01` → cập nhật lên bản này; **hoặc** `sqlite3 <documents>/sora_thu_chi.sqlite "UPDATE app_settings SET value = json_remove(value,'$.dailyWeekdays') WHERE key='notificationPrefs';"` | G (kịch bản 16 / FR-013) |
| Vài giao dịch + 1 ví + 1 danh mục + 1 ngân sách | Nhập tay | J (không ảnh hưởng chức năng khác) |
| Ngôn ngữ = **English** | Cài đặt → Tiện ích & Cá nhân hóa → Ngôn ngữ | K |
| Giao diện = **Tối** | Cài đặt → Tiện ích & Cá nhân hóa → Giao diện | L |
| Cỡ chữ hệ thống = **lớn nhất** | Cài đặt hệ điều hành → Cỡ chữ | M |
| Mockup để đối chiếu | Mở `docs/notification/02-cau-hinh-nhac-nhap-giao-dich.svg` | B |

---

## 2. Kịch bản kiểm thử tay

### Nhóm A — Điểm vào & hai vùng chạm (FR-001, FR-002, SC-002)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| A1 | Cài đặt → Thông báo & nhắc nhở → chạm **vùng tiêu đề/dòng phụ** hàng "Nhắc nhập giao dịch hằng ngày" (đúng 1 lần chạm) | Màn **"Nhắc nhập giao dịch"** mở ra: app bar **teal**, nút back, **không** bottom nav, **không** nút thêm giao dịch |
| A2 | Quay lại, chạm **công tắc** của cùng hàng đó | Công tắc đổi bật/tắt; **màn `02` KHÔNG mở** |
| A3 | Chạm **icon** và **dòng phụ** của hàng đó (không phải công tắc) | Màn `02` mở ra (cả hàng trừ công tắc đều là vùng chạm — giả định của spec) |
| A4 | Ở màn `02`, chạm nút back | Về màn `01`; **6 công tắc** và các hàng khác của màn `01` **không đổi** |
| A5 | Hàng "Nhắc nhập giao dịch hằng ngày" ở màn `01` | **Không** có chevron (mockup `01` không đổi — Q1=B) |

### Nhóm B — Đối chiếu mockup `02` (FR-002…FR-006, SC-001)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| B1 | Đếm khối có nhãn nhóm | **Đủ 3 nhãn** đúng thứ tự: **THỜI GIAN NHẮC** → **LẶP LẠI VÀO CÁC NGÀY** → **XEM TRƯỚC THÔNG BÁO**, cộng **hàng công tắc** (không nhãn nhóm) nằm giữa khối 2 và 3, và nút **"Lưu thay đổi"** dưới cùng |
| B2 | Xem khối THỜI GIAN NHẮC | Nền nhạt bo góc chứa **2 trục** ngăn bởi dấu **":"**; mỗi trục có **mũi tên ▲ trên, ▼ dưới**; giá trị đang chọn **lớn + teal** ở giữa; giá trị lân cận **mờ hơn**; có **dải nền nhạt** ở hàng đang chọn |
| B3 | Xem 7 chip | Đủ **T2 T3 T4 T5 T6 T7 CN** đúng thứ tự, **cách đều**, không cắt; chip chọn = **nền teal chữ trắng**, chip không chọn = **nền trắng viền xám chữ xám** |
| B4 | Xem hàng công tắc | Tiêu đề **"Chỉ nhắc nếu chưa ghi giao dịch"** + dòng phụ **"Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập"** + công tắc bên phải |
| B5 | Xem khối xem trước | Thẻ bo góc: **vòng tròn `S`** + **"Sora Thu Chi"** + **"Đừng quên ghi lại thu chi hôm nay nhé!"** + **giờ ở góc phải** |
| B6 | So trực tiếp với mockup | Bố cục, thứ tự khối, màu ngữ nghĩa (teal **chỉ** cho giá trị đang chọn / chip đang chọn / nút chính) **khớp** — 2 lệch nhỏ về dải nền và vị trí nút xem §4 |

### Nhóm C — Trục giờ/phút & xem trước tức thì (FR-003, FR-006, SC-003, SC-004)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| C1 | Từ 20:30 chạm ▲ trục **giờ** | Giờ → **21**, **phút vẫn 30** |
| C2 | Nhìn khối **XEM TRƯỚC** ngay sau C1 | Giờ hiển thị **21:30 ngay lập tức** (không cần bấm Lưu, không rời màn) |
| C3 | Chạm ▼ trục **giờ** liên tục từ **00** | 00 → **23** (quay vòng, không kẹt) |
| C4 | Chạm ▲ trục **giờ** liên tục từ **23** | 23 → **00** |
| C5 | Chạm ▼ trục **phút** từ **00**; ▲ từ **59** | 00 → **59**; 59 → **00** |
| C6 | Chạm liên tục 20–30 lần vào cả 4 mũi tên | Giá trị luôn trong **0–23** / **0–59**, không nhảy ngoài miền, không treo, không lỗi |
| C7 | Đổi phút thành **05** | Ô đang chọn và khối xem trước hiển thị **07:05** (pad 2 chữ số) |

### Nhóm D — Chip ngày (FR-004, FR-009, SC-005)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| D1 | Máy mới: mở màn `02` | **Cả 7 chip** ở trạng thái **đang chọn** (teal) |
| D2 | Chạm chip **CN** (đang chọn) | **Chỉ** CN về trạng thái không chọn; **6 chip còn lại giữ nguyên** |
| D3 | Chạm lại chip **CN** | CN bật lại; các chip khác **không đổi** |
| D4 | Lần lượt tắt **6 chip**, còn đúng **1 chip** đang chọn, rồi chạm **chip cuối** đó | Chip **vẫn đang chọn** (không tắt được); **không** hộp thoại, **không** thông báo lỗi |
| D5 | Đối chiếu từng chip một (bật/tắt 7 lượt) | **0 sai lệch** — mỗi lần chạm chỉ đổi đúng chip đó |

### Nhóm E — Công tắc "chỉ nhắc nếu chưa ghi" (FR-005)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| E1 | Mở màn `02` lần đầu | Công tắc **bật** (khớp mặc định PBI 28) |
| E2 | Tắt công tắc | Công tắc xám, chấm sang trái; **dòng phụ vẫn hiển thị**; khối xem trước **không đổi** nội dung |
| E3 | Chỉ tắt công tắc rồi bấm **Lưu** → mở lại màn `02` | Công tắc **vẫn tắt**; giờ và tập ngày **không** bị ảnh hưởng |
| E4 | Bật lại công tắc | Trở lại trạng thái bật như cũ |

### Nhóm F — Lưu / back bỏ thay đổi (FR-007, SC-014)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| F1 | Đổi giờ 20:30 → 21:00, tắt chip CN, rồi chạm **back** (không bấm Lưu) | Về màn `01`; **không** hộp thoại hỏi lại, **không** thông báo; dòng phụ vẫn ghi **20:30 mỗi ngày** |
| F2 | Mở lại màn `02` | Giờ **20:30**, **cả 7 chip bật**, công tắc bật — thay đổi ở F1 **đã bị bỏ** |
| F3 | Đổi vài giá trị rồi bấm **"Lưu thay đổi"** | Quay về màn `01`; **không** thông báo; dòng phụ hàng nhắc hàng ngày hiển thị **giờ mới + tập ngày mới** |
| F4 | Mở lại màn `02` | Đúng các giá trị vừa lưu |
| F5 | Mở màn `02`, **không** đổi gì, bấm **"Lưu thay đổi"** | Nút **luôn bấm được**; quay về màn `01`; **không** thông báo; không giá trị nào bị đổi (kịch bản 22) |
| F6 | Ở màn `02`, đổi giá trị rồi thoát app hẳn (kill) → mở lại | Màn `02` hiển thị giá trị **cũ** (thay đổi chưa lưu bị bỏ) |

### Nhóm G — Mặc định, lưu bền, dữ liệu cũ (FR-008, FR-012, FR-013, SC-006…SC-008)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| G1 | Máy mới, mở màn `02` lần đầu | **20:30**, cờ bật, **7 chip bật**; dòng phụ màn `01` ghi **"20:30 mỗi ngày · chỉ nhắc nếu chưa ghi"** |
| G2 | Lưu vài giá trị → thoát app hẳn → mở lại → mở màn `02` | **Đúng** giờ, tập ngày, cờ đã đặt (0 giá trị về mặc định) |
| G3 | **Khởi động lại thiết bị** → mở màn `02` | Vẫn đúng các giá trị đã đặt |
| G4 | Ở màn `01`: **tắt** công tắc nhắc hàng ngày → mở màn `02` | Giờ/ngày/cờ **vẫn nguyên giá trị cũ** (không reset mặc định) |
| G5 | Bật lại công tắc ở màn `01` → mở màn `02` | Vẫn **đúng tham số cũ** |
| G6 | Với **DB cũ kiểu PBI 28** (thiếu khoá `dailyWeekdays`): mở màn `02` | Màn **không** trắng, **không** lỗi: giờ và cờ **đúng giá trị đã lưu từ trước**; **cả 7 chip bật** (mặc định Q3) |
| G7 | Sửa tay row thành JSON hỏng (VD cắt cụt chuỗi) → mở màn `02` | Màn dùng **mặc định từng trường**, không trắng màn, không ném lỗi |
| G8 | Sửa `dailyWeekdays` thành `[]` hoặc `[0,9,"x"]` → mở màn `02` | Hiển thị **7 chip bật** (không tồn tại trạng thái 0 ngày) |
| G9 | Sau khi dùng màn, kiểm row trong DB | Đúng **1 row** `notificationPrefs` (JSON **17 khoá**), các row khác (`hideBalance`, `scanEnabled`…) còn nguyên |

### Nhóm H — Dòng phụ màn `01` theo tập ngày (FR-011)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| H1 | Đủ 7 ngày được chọn | Dòng phụ: **"20:30 mỗi ngày"** (+ " · chỉ nhắc nếu chưa ghi" nếu cờ bật) |
| H2 | Bỏ chip CN (còn T2–T7) → Lưu | Dòng phụ: **"20:30 vào T2–T7"** (dải liên tiếp nén thành dải) |
| H3 | Bỏ thêm T5 (còn T2,T3,T4,T6,T7) → Lưu | Dòng phụ liệt kê **"T2–T4, T6–T7"** |
| H4 | Chỉ chọn T2 và CN → Lưu | Dòng phụ: **"20:30 vào T2, CN"** (2 ngày rời, không nén) |
| H5 | Bật lại đủ 7 ngày → Lưu | Dòng phụ quay về **"20:30 mỗi ngày"** |
| H6 | Đổi giờ ở màn `02` rồi Lưu, không đổi ngày | Dòng phụ hiển thị **giờ mới**, tập ngày giữ nguyên dạng cũ |

### Nhóm I — Không bắn thông báo, không xin quyền (FR-014, SC-009)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| I1 | Đổi giờ/ngày ở màn `02`, bấm Lưu, rồi dùng app cả ngày (thêm giao dịch, xem báo cáo, để nền) | **0** thông báo nào được bắn ra |
| I2 | Trong suốt quá trình trên | **0** lần app hỏi quyền thông báo; màn `02` **không** dòng nào nhắc tới quyền hệ thống |
| I3 | Đặt giờ nhắc = **giờ hiện tại + 2 phút**, lưu, để app ở nền | **Không** có thông báo nào xuất hiện (engine chưa thuộc phạm vi) |

### Nhóm J — Không ảnh hưởng dữ liệu & loại nhắc khác (FR-010, FR-018, SC-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| J1 | Ghi lại số bản ghi giao dịch/ví/danh mục/ngân sách trước và sau khi dùng màn `02` | **0** thay đổi |
| J2 | Về màn `01`, kiểm **5 loại nhắc còn lại** (ngân sách, định kỳ, mục tiêu, tổng kết tuần/tháng) | Trạng thái + dòng phụ **không đổi** (80%/100%, 3 ngày, 20:00…) |
| J3 | Đổi giờ/ngày ở màn `02` rồi Lưu, kiểm công tắc nhắc hàng ngày ở màn `01` | Trạng thái bật/tắt **giữ nguyên** như trước |
| J4 | Tìm công tắc "bật/tắt tất cả" trên màn `02` | **Không** tồn tại; màn **không** có công tắc bật/tắt loại nhắc này (giả định của spec) |

### Nhóm K — Tiếng Anh (FR-015, SC-011)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| K1 | Ngôn ngữ = **English** → mở màn `02` | Tiêu đề app bar, **3 nhãn nhóm**, tiêu đề hàng công tắc, dòng phụ, câu nội dung xem trước, nút "Save changes" đều **tiếng Anh**; **0** nhãn tĩnh tiếng Việt sót |
| K2 | Xem 7 chip | Nhãn **Mon Tue Wed Thu Fri Sat Sun** (tiếng Anh), **không** còn T2…CN |
| K3 | Xem giờ | Định dạng **HH:mm không đổi** (`20:30`, `07:05`), tên app **"Sora Thu Chi"** không dịch |
| K4 | Quay về màn `01` ở English | Dòng phụ (kể cả dạng liệt kê ngày) **tiếng Anh**, không lẫn tiếng Việt |

### Nhóm L — Chế độ Tối (FR-016, SC-011)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| L1 | Giao diện = **Tối** → mở màn `02` | Nền tối, không vùng trắng chói; nhãn nhóm, chữ, khối thời gian, thẻ xem trước đọc được |
| L2 | Xem chip đang chọn / không chọn | Chip chọn (nền teal, chữ trắng) và chip không chọn (nền surface tối, viền mờ) **phân biệt rõ**; dải nền hàng đang chọn vẫn thấy |
| L3 | Xem giá trị đang chọn ở khối thời gian | **Teal sáng của theme tối** (`tealOnNeutral`), đủ tương phản trên nền `softCardBg` tối |
| L4 | Đổi lại giao diện = Sáng | Về đúng bộ màu sáng, không lẫn màu tối |

### Nhóm M — Cỡ chữ lớn & màn hẹp (FR-017, SC-012)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| M1 | Cỡ chữ hệ thống **lớn nhất** + màn hình nhỏ → mở màn `02` | **7 chip không bị cắt/tràn** (cho phép xuống hàng); nhãn chip vẫn đọc được |
| M2 | Cuộn nội dung | Khối thời gian và thẻ xem trước **không đè nhau**, không overflow; nút **"Lưu thay đổi"** luôn thấy ở đáy |
| M3 | Ở cỡ chữ lớn, xem khối thời gian | Giá trị đang chọn và lân cận **không chồng lên nhau**; dải nền đúng hàng |
| M4 | Xoay ngang (nếu máy hỗ trợ) | Không vỡ bố cục, không tràn ngang |

---

## 3. Kiểm thử tự động (kỳ vọng)

| File test | Nội dung chính |
|---|---|
| `test/date_label_test.dart` (**sửa**) | `dayLabel`: `1`→`T2` … `7`→`CN` (ngoài miền → chuỗi rỗng); `daysLabel`: `[1..7]`→`T2–T7, CN`, `[1..6]`→`T2–T7`, `[1,2,3,5]`→`T2–T4, T5`, `[1,7]`→`T2, CN`, `[3]`→`T3`, `[]`→`''` |
| `test/notification_prefs_test.dart` (**sửa**) | Luật §2 data-model: mặc định `dailyWeekdays == [1..7]`; parse tolerant (thiếu khoá/rỗng/sai kiểu/phần tử ngoài miền/trùng/null/số thực → chuẩn hoá đúng); thứ tự ghi luôn sắp tăng; round-trip giữ tập ngày; `isEveryDay`; `toggleDay` thêm/bớt/`identical` khi còn 1 ngày/không chạm 15 trường khác |
| `test/daily_reminder_config_screen_test.dart` (**mới**) | Màn `02` với `FakeNotificationStore`: đủ 3 nhãn nhóm + hàng công tắc + nút Lưu; 2 trục giờ/phút (giá trị đang chọn + 2 lân cận); mũi tên tăng/giảm + quay vòng 23↔00, 00↔59; **xem trước đổi ngay** cùng nhịp chạm mà **store không bị ghi**; chạm chip chỉ đổi chip đó; chip cuối **không** tắt được; **back không ghi store**; bấm Lưu ghi đúng `_draft` + pop; bấm Lưu khi không đổi gì vẫn pop; nhánh lỗi đọc + nút **Thử lại**; cỡ chữ 2.0 + màn 360×640 không tràn/overflow |
| `test/notification_settings_screen_test.dart` (**sửa**) | Hàng nhắc hàng ngày: chạm vùng tiêu đề/dòng phụ → mở màn `02` (đúng 1 route); chạm **công tắc** → chỉ đổi trạng thái, **0** route mới; dòng phụ theo tập ngày (`[1..7]` → "mỗi ngày"; `[1..6]` → `T2–T7`; `[1,2,3,5]` → `T2–T4, T5`); 5 hàng công tắc còn lại **không** mở màn nào |
| `test/dark_theme_smoke_test.dart` (**sửa**) | Thêm màn `02` vào danh sách smoke theme tối: không overflow, token tối thật sự áp (nền/`softCardBg`) |
| `test/fakes/fake_notification_store.dart` | **Tái dùng nguyên trạng** (đã có `storedPrefs` + `failLoad` từ PBI 28) — chỉ sửa nếu thiếu khả năng assert |

---

## 4. Lệch nhỏ đã biết (có lý do)

1. **Nút "Lưu thay đổi" ghim ở đáy màn** (mockup vẽ ở cuối nội dung): khuôn 4 màn
   form đã QA của app (`wallet_form`, `budget_form`, `category_form`,
   `add_transaction`) + FR-017/SC-012 chỉ đòi "cuộn tới được nút Lưu" — nút ghim thì
   **luôn** tới được, kể cả ở cỡ chữ lớn nhất (research R7).
2. **Dải nền nhạt tách theo ô giá trị của từng trục** (mockup vẽ 1 dải liền chạy
   ngang qua cả dấu `:`): FR-003 chỉ đòi "dải nền nhạt đánh dấu hàng đang chọn";
   cách này không dùng toạ độ cứng nên **không vỡ khi cỡ chữ lớn** (research R5).
3. **Nhãn chip ngày bị chặn cỡ chữ tối đa 1.4×**: giữ 7 vòng tròn 36 px nằm gọn
   trên một hàng ở màn 360 px (7×36 + 6×10 = 312 < 320) — chấp nhận được theo edge
   case "chip xuống hàng hoặc thu nhỏ khoảng cách nhưng không cắt nhãn" (research R6).
4. **2 hàng chevron ở màn `01` không còn phản hồi mực khi chạm đúng icon chevron**:
   vùng chạm của hàng nay là phần nội dung (icon + tiêu đề + dòng phụ), chevron nằm
   ngoài để **tách vùng chạm** của hàng nhắc hàng ngày (FR-001). Hành vi "chạm
   không mở gì" **không đổi** (PBI 28 vẫn đúng).
5. **Dòng phụ dạng nén dải** (`T2–T7, CN`) thay vì liệt kê rời: bám đúng ví dụ ở
   kịch bản chấp nhận 13; 2 ngày rời thì không nén (`T2, CN`) — research R10.

---

## 5. Mốc test trước PBI

```
flutter test   →   1004 pass + 1 FAIL CÓ SẴN
                   (test/transactions_dao_test.dart — "addTransaction: income/expense
                    bù đúng balance + dòng đúng dấu/id/tên", tồn tại từ PBI 11,
                    KHÔNG liên quan PBI 29)
```

Mục tiêu: **pass tăng**, **đỏ không tăng** (vẫn đúng 1). Test đỏ khác
`transactions_dao_test` ⇒ hồi quy của PBI này.

---

## 6. Kiểm tra schema & dữ liệu không bị đụng

```bash
# Sau khi dùng màn, đối chiếu DB (tuỳ chọn, cần sqlite3):
#   sqlite3 <documents>/sora_thu_chi.sqlite \
#     "SELECT key, value FROM app_settings WHERE key = 'notificationPrefs';"
#   → đúng 1 row JSON, 17 khoá (16 khoá cũ + dailyWeekdays)
#   → các row khác (hideBalance, amountCalculatorEnabled, scanEnabled…) còn nguyên
```

- `schemaVersion` **vẫn 8** — không migration, không bảng mới, không `build_runner`.
- Số bản ghi `transactions`/`wallets`/`categories`/`budgets` **không đổi** (nhóm J1).
