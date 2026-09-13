# Mô hình dữ liệu: Cấu hình nhắc nhập giao dịch hằng ngày (màn 02)

**Mã PBI**: 29
**Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)
**Ngày tạo**: 2026-09-13

> **Không đổi schema drift** (giữ **v8**, PBI 24): không bảng, không cột, không
> migration, **không** `build_runner`. Dữ liệu duy nhất được ghi vẫn là **một row
> JSON** `AppSettings(key='notificationPrefs')` (PBI 28) — PBI này **thêm 1 khoá**
> vào chính object đó (research R1). **Không** đọc/ghi bảng nghiệp vụ nào.

---

## 1. Thực thể

### 1.1. `NotificationPrefs` — bổ sung phần tham số của nhắc hàng ngày

Class bất biến sẵn có (PBI 28, 16 trường). PBI 29 **thêm 1 trường**; 15 trường còn
lại **giữ nguyên** giá trị, miền hợp lệ và mặc định.

| Trường | Kiểu | Miền hợp lệ | Mặc định | Hiển thị ở |
|---|---|---|---|---|
| `dailyWeekdays` | `List<int>` | **khác rỗng**, phần tử ∈ `1…7`, **đã sắp tăng**, không trùng | `const [1,2,3,4,5,6,7]` | 7 chip màn `02` + dòng phụ hàng nhắc hàng ngày ở màn `01` |

Quy ước ngày: **`1` = Thứ Hai … `7` = Chủ Nhật** (ISO-8601, tuần bắt đầu Thứ Hai —
đồng bộ `budget_view`/`report_view`). Nhãn hiển thị: `1→T2, 2→T3, … 6→T7, 7→CN`
(EN: `Mon…Sun`) — research R11.

Trường `dailyHour`, `dailyMinute`, `dailyOnlyIfNoTxnToday`, `dailyEnabled` (PBI 28)
**không đổi** định nghĩa; màn `02` chỉ **đọc/ghi** 3 trường đầu (màn `02` **không**
có công tắc `dailyEnabled` — bật/tắt vẫn ở hàng công tắc màn `01`).

**Thành phần mới của model**

| Thành phần | Vai trò |
|---|---|
| `bool isEveryDay` | `dailyWeekdays.length == 7` — chọn chuỗi dòng phụ "mỗi ngày" (FR-011) |
| `bool isDayEnabled(int weekday)` | `dailyWeekdays.contains(weekday)` — trạng thái 1 chip (FR-004) |
| `NotificationPrefs toggleDay(int weekday)` | Bật ⇄ tắt **một** ngày; nếu phép tắt làm tập **rỗng** → trả về **chính object cũ** (`identical`) — bất biến "luôn ≥1 ngày" (FR-009) |

### 1.2. Bảng hàng & điều khiển màn `02` (FR-002…FR-006)

| # | Khối | Nội dung | Điều khiển | Đọc/ghi |
|---|---|---|---|---|
| 1 | *(app bar)* | Tiêu đề **"Nhắc nhập giao dịch"** + nút back; **không** bottom nav, **không** FAB | — | — |
| 2 | **THỜI GIAN NHẮC** | Khối nền `softCardBg` bo 10 chứa 2 cột giờ / phút ngăn bởi dấu `:` | mũi tên ▲/▼ mỗi cột (±1, quay vòng) | `dailyHour` 0–23, `dailyMinute` 0–59 |
| 3 | **LẶP LẠI VÀO CÁC NGÀY** | 7 chip tròn 36 px, thứ tự T2 → CN | chạm chip = đảo trạng thái ngày đó | `dailyWeekdays` |
| 4 | *(hàng công tắc)* | "Chỉ nhắc nếu chưa ghi giao dịch" + dòng phụ "Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập" | `Switch` bên phải | `dailyOnlyIfNoTxnToday` |
| 5 | **XEM TRƯỚC THÔNG BÁO** | Thẻ bo 10: vòng tròn `'S'` + tên app + câu nội dung + **giờ góc phải** | *(không có — chỉ hiển thị)* | `dailyHour`/`dailyMinute` (đọc) |
| 6 | *(đáy màn)* | Nút **"Lưu thay đổi"** (ghim đáy, 44 px, teal, bo 8) | chạm = ghi rồi về màn `01` | cả 4 trường ở trên |

Bất biến bố cục: **đủ 4 khối có nhãn nhóm** theo thứ tự trên; **đúng 1 công tắc**
duy nhất trên màn (khối 4); khối 2 và 5 **không** có điều khiển riêng ngoài mũi tên
ở khối 2.

Trạng thái hiển thị của khối 5 (giờ) **là một hàm của `_draft`** — không có bản sao
giá trị nào khác trong màn (SC-004).

### 1.3. Hình dạng JSON row (FR-007, FR-012, FR-013)

Row: `AppSettings(key = 'notificationPrefs', value = <JSON>)` — **vẫn 1 row**, thêm
1 khoá so với PBI 28:

```json
{"dailyEnabled":true,"dailyHour":20,"dailyMinute":30,"dailyOnlyIfNoTxnToday":true,
 "dailyWeekdays":[1,2,3,4,5,6,7],
 "budgetEnabled":true,"budgetEarlyPercent":80,"budgetOverPercent":100,
 "recurringEnabled":true,"recurringDaysBefore":3,"goalEnabled":false,
 "weeklyEnabled":true,"weeklyHour":20,"weeklyMinute":0,
 "monthlyEnabled":true,"monthlyHour":20,"monthlyMinute":0}
```

- Ghi: **upsert 1 row** `insertOnConflictUpdate` — không xoá row `AppSettings` nào
  khác (`hideBalance`, `amountCalculatorEnabled`, 4 khoá quét…).
- `dailyWeekdays` ghi ra **luôn** đã chuẩn hoá: lọc `int` ∈ 1…7, bỏ trùng, **sắp
  tăng**; tập rỗng ⇒ ghi cả 7 ngày (không bao giờ ghi `[]`).
- Row **cũ** (PBI 28, chưa có `dailyWeekdays`) ⇒ `[1,2,3,4,5,6,7]` — **không** mất
  `dailyHour`/`dailyMinute`/`dailyOnlyIfNoTxnToday` (FR-013/kịch bản 16), **không**
  cần code migrate.

### 1.4. Seam `NotificationStore` — **không đổi**

```dart
abstract class NotificationStore {
  Future<NotificationPrefs> load();            // row vắng / JSON hỏng → mặc định
  Future<void> save(NotificationPrefs prefs);  // upsert 1 row, không xoá row khác
}
```

Màn `02` **dùng lại** seam này (nhận `NotificationStore? store`, màn `01` truyền
store của nó khi push — research R9); test bơm `FakeNotificationStore` sẵn có (PBI
28) — **không** cần sqlite native. **Không** thêm phương thức nào vào seam.

---

## 2. Luật bất biến (kiểm được bằng test)

**Mặc định & parse chịu lỗi của tập ngày (FR-008, FR-013)**

1. Row vắng (`kKeyNotificationPrefs` không có) → **cả bộ mặc định**, trong đó
   `dailyWeekdays == [1,2,3,4,5,6,7]`.
2. JSON parse được nhưng **thiếu khoá** `dailyWeekdays` (row PBI 28) → trường này
   nhận `[1..7]`, **các trường khác giữ đúng giá trị trong row** (giờ/cờ không đổi).
3. `dailyWeekdays` **sai kiểu** (không phải `List`, `null`, chuỗi, object) →
   `[1..7]`.
4. `dailyWeekdays` là list nhưng có phần tử lạ → **lọc bỏ** phần tử sai (không phải
   `int`, hoặc ngoài `1…7`); nếu còn ≥1 phần tử hợp lệ → dùng tập đã lọc, **không**
   rơi về mặc định.
5. `dailyWeekdays` là list **rỗng** hoặc **toàn phần tử sai** → `[1..7]` (không tồn
   tại trạng thái 0 ngày — FR-009).
6. `dailyWeekdays` có phần tử **trùng** → bỏ trùng; thứ tự ghi ra **luôn sắp tăng**
   (`[5,1,5]` → `[1,5]`).
7. Parse **không bao giờ ném** với mọi đầu vào (kể cả list chứa `null`, số thực,
   `"T2"`).

**Round-trip (FR-012)**

8. `fromSettings(toSettings(p)) == p` với mọi `p` hợp lệ (đối chiếu cả
   `dailyWeekdays`, kể cả khi tập ngày chỉ còn 1 phần tử).
9. `save(p)` rồi `load()` → đúng `p`.

**Đảo trạng thái ngày (FR-004, FR-009)**

10. `toggleDay(d)` với `d` **đang tắt** → tập có thêm `d`, **đã sắp tăng**; các
    phần tử cũ giữ nguyên.
11. `toggleDay(d)` với `d` **đang bật** và tập còn ≥2 phần tử → tập có `d` bị bỏ.
12. `toggleDay(d)` với `d` là **ngày bật cuối cùng** (tập còn đúng 1 phần tử `d`)
    → trả về **chính object cũ** (`identical(prefs, prefs.toggleDay(d))`), tập vẫn
    `[d]` — **không** có trạng thái 0 ngày.
13. `toggleDay` **chỉ** chạm `dailyWeekdays`: `dailyHour`, `dailyMinute`,
    `dailyOnlyIfNoTxnToday` và **5 loại nhắc còn lại** giữ nguyên (FR-010).
14. `isEveryDay` ⇔ `dailyWeekdays.length == 7` — chỉ đúng với tập đủ 7 ngày, không
    đúng với 6 ngày.

**Đọc/ghi của màn (FR-007, FR-010, SC-014)**

15. Mở màn `02`: **chỉ** `load()` — store **không** bị ghi (`storedPrefs` không đổi
    sau khi màn mở, khác màn `01`).
16. Đổi giờ/ngày/cờ rồi **back**: store **không** đổi giá trị nào (thay đổi bị bỏ —
    Q2=A), và mở lại màn `02` thấy **đúng giá trị cũ**.
17. Bấm **"Lưu thay đổi"**: store nhận **đúng** bộ `_draft` (giờ, phút, tập ngày,
    cờ) rồi màn pop; `dailyEnabled` và **5 loại nhắc còn lại** không đổi.
18. Bấm "Lưu thay đổi" khi **không** đổi gì: store nhận đúng bộ đang có (giá trị
    bằng nhau), màn pop, **không** thông báo (kịch bản 22).
19. `dailyEnabled == false` (tắt ở màn `01`) **không** ảnh hưởng màn `02`: mở màn
    `02` vẫn thấy đủ giờ/ngày/cờ cũ (luồng phụ 1) và bấm Lưu **không** bật lại cờ đó.

**Dòng phụ màn `01` (FR-011)**

20. Tập đủ 7 ngày → dòng phụ dùng chuỗi **"@giờ mỗi ngày"** (giữ nguyên PBI 28) +
    hậu tố " · chỉ nhắc nếu chưa ghi" khi cờ bật.
21. Tập thiếu ngày → dòng phụ dùng **"@giờ vào @ngày"**, `@ngày` = nén dải liên
    tiếp dài **≥3** (`[1..6]` → `T2–T7`; `[1..7]` không vào nhánh này), ngày rời
    liệt kê riêng, phân cách `, ` (`[1,2,3,5]` → `T2–T4, T5`; `[1,7]` → `T2, CN`).
22. Dòng phụ **đọc lại mỗi lần màn `01` mở** (state nạp trong `initState`) — không
    hằng cứng, không cache giữa hai lần mở.

**Không đụng dữ liệu khác (FR-018, SC-010)**

23. Màn `02` chỉ gọi `NotificationStore`; **không** hàm nào chạm
    `transactions`/`wallets`/`categories`/`budgets`/`scan_sessions`.
24. **0** lời gọi plugin/quyền thông báo: không import `flutter_local_notifications`,
    không `zonedSchedule`, không `requestPermission` (FR-014, SC-009).

---

## 3. Vòng đời giá trị

| Sự kiện | Row `notificationPrefs` | Màn `02` hiển thị |
|---|---|---|
| Row cũ từ PBI 28 (thiếu `dailyWeekdays`) | không đổi khi **mở** màn | giờ + cờ đúng giá trị cũ; **cả 7 chip bật** |
| Máy mới / row vắng | không đổi khi **mở** màn | 20:30, cờ bật, 7 chip bật |
| Đổi giờ / chip / cờ | **không** ghi | đổi ngay (kể cả giờ ở khối xem trước) |
| Back khi chưa lưu | **không** ghi | thay đổi **bị bỏ**; mở lại thấy giá trị cũ |
| Bấm "Lưu thay đổi" | **upsert** row (23 khoá JSON) | pop về màn `01`; dòng phụ đọc lại theo giá trị mới |
| Bấm Lưu khi không đổi gì | upsert giá trị y hệt (idempotent) | pop, không thông báo |
| Tắt chip cuối cùng | — | chip **vẫn bật** (không có trạng thái 0 ngày) |
| Lỗi **đọc** DB | không đổi | nhánh lỗi "Không đọc được cài đặt." + nút **Thử lại** |
| Lỗi **ghi** DB khi Lưu | không đổi | bỏ qua lỗi, vẫn pop (đồng bộ cách chịu lỗi màn `01`) |
| Tắt/bật công tắc ở màn `01` | row không bị reset giờ/ngày/cờ | mở màn `02` thấy đúng tham số cũ (SC-007) |
| Xoá app / cài lại | row mất | về bộ mặc định (20:30, cờ bật, 7 ngày) |

---

## 4. Truy vết yêu cầu → luật / thành phần

| FR / SC | Luật / thành phần |
|---|---|
| FR-001, SC-002 | Hai vùng chạm: `InkWell` chỉ bọc cụm icon + tiêu đề/dòng phụ ở hàng nhắc hàng ngày (research R9) |
| FR-002 | `SubPageScaffold` (app bar teal + back; 0 bottom nav, 0 FAB) |
| FR-003, SC-003 | §1.2 khối 2 — `_step(delta)` quay vòng `% 24` / `% 60` (research R4) |
| FR-004, SC-005 | Luật 10–13; §1.2 khối 3 (chip tròn 36 px, đảo trạng thái tức thì) |
| FR-005 | §1.2 khối 4 (`Switch` ← `dailyOnlyIfNoTxnToday`, dòng phụ cố định) |
| FR-006, SC-004 | §1.2 khối 5 — giờ đọc từ `_draft` trong `build` (research R12) |
| FR-007, SC-014 | Luật 15–18, 21 — bản nháp + chỉ ghi khi bấm Lưu (research R8) |
| FR-008 | §1.1 cột Mặc định + luật 1 |
| FR-009, edge "chip cuối" | Luật 12 + `toggleDay` trả `this` |
| FR-010 | Luật 13, 17, 19 |
| FR-011, SC-007 | Luật 20–22 + hàm nén dải (research R10) |
| FR-012, SC-006 | Luật 8–9 + §1.3 (1 row, upsert) |
| FR-013, SC-008 | Luật 1–7 (đặc biệt luật 2: row thiếu khoá) |
| FR-014, SC-009 | Luật 24 (0 plugin, 0 quyền, 0 lịch) |
| FR-015, SC-011 | Nhãn chip literal trước `.tr` + khoá mới ở nhánh `_en` (research R11) |
| FR-016, SC-011 | Token `SoraColors` (light/dark) + `AppColors.teal` cho chip/nút chọn |
| FR-017, SC-012 | Nút ghim đáy (research R7) + `Wrap` cho chip (R6) + 2 dải nền theo ô giá trị (R5) |
| FR-018, SC-010 | Luật 23 |

---

## 5. Ngoài mô hình dữ liệu này (PBI sau)

Bảng `NotificationRule` / `NotificationLog` (doc §3.1) vẫn **không** dựng: chúng
phục vụ **engine** (lên lịch, `lastFiredAt` chống bắn trùng) và **màn `03`** —
ngoài phạm vi. `dailyWeekdays` **là** phần `config.weekdays` mà doc mô tả, nhưng
nằm trong row JSON đã có (research R1); khi engine ra đời, row này là **nguồn** để
đọc/migrate, không phải dữ liệu của engine.
