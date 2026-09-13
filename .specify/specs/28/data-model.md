# Mô hình dữ liệu: Cài đặt Thông báo & nhắc nhở (màn Cài đặt)

**Mã PBI**: 28
**Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)
**Ngày tạo**: 2026-09-13

> Đợt này **không đổi schema drift** (giữ **v8**, PBI 24): không bảng, không cột,
> không migration, **không** chạy `build_runner`. Dữ liệu duy nhất được ghi là
> **một row JSON** trong bảng key-value `AppSettings` đã có từ PBI 17.
> **Không** ghi/đọc bảng nghiệp vụ nào (giao dịch, ví, danh mục, ngân sách, quét).

---

## 1. Thực thể

### 1.1. `NotificationPrefs` — cấu hình thông báo của người dùng (FR-007…FR-010)

Bất biến (mọi thay đổi qua `copyWith`), 16 trường, đủ cho 8 hàng của mockup `01`.

| Trường | Kiểu | Miền hợp lệ | Mặc định | Hiển thị ở |
|---|---|---|---|---|
| `dailyEnabled` | `bool` | — | `true` | Công tắc hàng "Nhắc nhập giao dịch hằng ngày" |
| `dailyHour` | `int` | 0–23 | `20` | Dòng phụ hàng đó (`20:30 mỗi ngày`) |
| `dailyMinute` | `int` | 0–59 | `30` | Dòng phụ hàng đó |
| `dailyOnlyIfNoTxnToday` | `bool` | — | `true` | Dòng phụ hàng đó (`· chỉ nhắc nếu chưa ghi`) |
| `budgetEnabled` | `bool` | — | `true` | Công tắc hàng "Cảnh báo vượt ngân sách" |
| `budgetEarlyPercent` | `int` | 0–100 | `80` | Dòng phụ 2 hàng nhóm Ngân sách |
| `budgetOverPercent` | `int` | 0–100 | `100` | Dòng phụ 2 hàng nhóm Ngân sách |
| `recurringEnabled` | `bool` | — | `true` | Công tắc hàng "Nhắc hóa đơn sắp đến hạn" |
| `recurringDaysBefore` | `int` | 0–30 | `3` | Dòng phụ hàng "Nhắc trước" |
| `goalEnabled` | `bool` | — | `false` | Công tắc hàng "Nhắc đóng góp mục tiêu" |
| `weeklyEnabled` | `bool` | — | `true` | Công tắc hàng "Tổng kết cuối tuần" |
| `weeklyHour` | `int` | 0–23 | `20` | Dòng phụ hàng "Tổng kết cuối tuần" |
| `weeklyMinute` | `int` | 0–59 | `0` | Dòng phụ hàng "Tổng kết cuối tuần" |
| `monthlyEnabled` | `bool` | — | `true` | Công tắc hàng "Tổng kết cuối tháng" |
| `monthlyHour` | `int` | 0–23 | `20` | Dòng phụ hàng "Tổng kết cuối tháng" |
| `monthlyMinute` | `int` | 0–59 | `0` | Dòng phụ hàng "Tổng kết cuối tháng" |

Mặc định lấy **nguyên** theo mockup `01` + doc §2 + FR-008 (nhắc mục tiêu là công
tắc **duy nhất** vẽ ở trạng thái tắt).

**Không** lưu (hoãn có lý do — research R3): danh sách ngày trong tuần của nhắc
hàng ngày, chu kỳ/mốc % của mục tiêu (per-mục-tiêu, GĐ3), thứ của tổng kết tuần
(mockup cố định Chủ nhật), ngưỡng riêng từng ngân sách (ngoài phạm vi), múi giờ.

### 1.2. Hàng trên màn — 5 nhóm / 8 hàng (FR-003…FR-005)

| # | Nhóm (nhãn viết hoa) | Hàng | Icon | Sắc icon | Trailing |
|---|---|---|---|---|---|
| 1 | NHẮC NHỞ HÀNG NGÀY | Nhắc nhập giao dịch hằng ngày | `notifications_none` | teal | **công tắc** ← `dailyEnabled` |
| 2 | NGÂN SÁCH | Cảnh báo vượt ngân sách | `warning_amber_rounded` | **coral** | **công tắc** ← `budgetEnabled` |
| 3 | NGÂN SÁCH | Ngưỡng cảnh báo | `warning_amber_rounded` | **coral** | chevron (no-op) |
| 4 | GIAO DỊCH ĐỊNH KỲ | Nhắc hóa đơn sắp đến hạn | `event_outlined` | teal | **công tắc** ← `recurringEnabled` |
| 5 | GIAO DỊCH ĐỊNH KỲ | Nhắc trước | `event_outlined` | teal | chevron (no-op) |
| 6 | MỤC TIÊU TIẾT KIỆM | Nhắc đóng góp mục tiêu | `track_changes` | teal | **công tắc** ← `goalEnabled` |
| 7 | TỔNG KẾT TỰ ĐỘNG | Tổng kết cuối tuần | `pie_chart_outline` | teal | **công tắc** ← `weeklyEnabled` |
| 8 | TỔNG KẾT TỰ ĐỘNG | Tổng kết cuối tháng | `pie_chart_outline` | teal | **công tắc** ← `monthlyEnabled` |

Bất biến: **mỗi hàng có đúng một** phần tử điều khiển (công tắc **hoặc** chevron —
không hàng nào có cả hai, không hàng nào trống); tổng **6 công tắc + 2 chevron**.

### 1.3. Khoá lưu & hình dạng JSON (FR-007)

- Row: `AppSettings(key = 'notificationPrefs', value = <JSON>)` — tiền lệ
  `scanDeviceCheck` (PBI 24) dùng cùng cách cho một object phức.
- JSON: object phẳng 16 khoá, tên khoá = tên trường ở §1.1. Ví dụ:

  ```json
  {"dailyEnabled":true,"dailyHour":20,"dailyMinute":30,"dailyOnlyIfNoTxnToday":true,
   "budgetEnabled":true,"budgetEarlyPercent":80,"budgetOverPercent":100,
   "recurringEnabled":true,"recurringDaysBefore":3,"goalEnabled":false,
   "weeklyEnabled":true,"weeklyHour":20,"weeklyMinute":0,
   "monthlyEnabled":true,"monthlyHour":20,"monthlyMinute":0}
  ```

- Ghi: **upsert 1 row**, `insertOnConflictUpdate` (không xoá row nào khác —
  khoá `hideBalance`/`amountCalculatorEnabled` của PBI 17 và 4 khoá quét của
  PBI 24 phải nguyên vẹn).
- Giá trị ghi ra **luôn** đã clamp về miền hợp lệ (bảng §1.1).

### 1.4. Seam `NotificationStore` (hợp đồng nội bộ duy nhất mới)

```dart
abstract class NotificationStore {
  Future<NotificationPrefs> load();            // key vắng → cả bộ mặc định
  Future<void> save(NotificationPrefs prefs);  // upsert 1 row, không xoá row khác
}
```

Impl thật `DriftNotificationStore(AppDatabase)`; đăng ký **một** instance qua
`ensureNotificationStore()` (GetX singleton — tránh 2 connection drift trên cùng
file sqlite); test bơm `FakeNotificationStore` (bộ nhớ) — không cần sqlite native.

---

## 2. Luật bất biến (kiểm được bằng test)

**Parse / mặc định (FR-007, FR-008)**

1. Key `notificationPrefs` **vắng** trong bảng → trả **đủ 16 trường mặc định** §1.1.
2. Value **không parse được** thành JSON object (chuỗi rác, `null`, mảng) → **cả
   bộ mặc định**; **không ném**.
3. JSON thiếu khoá → trường thiếu nhận **mặc định của riêng nó**, các trường có
   mặt giữ nguyên giá trị.
4. Trường sai kiểu (bool ≠ bool, số không phải số) → mặc định của trường đó.
5. Trường ngoài miền (giờ 24, phút 60, % 150, ngày âm) → mặc định của trường đó.
6. Parse **không bao giờ ném** với mọi đầu vào chuỗi (kể cả rỗng).

**Round-trip (FR-007)**

7. `fromJson(toJson(p)) == p` với mọi `p` hợp lệ.
8. `save(p)` rồi `load()` → đúng `p` (không mất trường, không đổi giá trị).
9. `save` **không** xoá/đổi row `AppSettings` khác (`hideBalance`, `scanEnabled`…).

**Ghi mặc định lần mở đầu (FR-007 + kịch bản 6)**

10. Sau lần **mở màn đầu tiên** trên DB chưa có khoá, bảng đã có row
    `notificationPrefs` mang **đúng bộ mặc định** (màn gọi `save` ngay sau `load`
    — research R2). Trước khi mở màn: **không** có row nào (không seed ở DB).

**Bất biến khi bật/tắt (FR-006, FR-010, kịch bản 7)**

11. `copyWith(xEnabled: v)` **chỉ** đổi trường của loại `x`; **15 trường còn lại
    không đổi** (không có nhánh nào chạm hai loại cùng lúc ⇒ không có cơ chế
    "bật/tắt tất cả").
12. Tắt một loại **không** chạm tham số của loại đó: `copyWith(dailyEnabled:
    false)` giữ nguyên `dailyHour`/`dailyMinute`/`dailyOnlyIfNoTxnToday`; bật lại
    đọc ra **đúng tham số cũ** (0 trường hợp reset mặc định).
13. Tắt cả 6 công tắc vẫn là một `NotificationPrefs` hợp lệ — không có trạng thái
    "không hợp lệ", không có giá trị đặc biệt nào bật lại.

**Dòng phụ (FR-009, FR-015)**

14. Dòng phụ dựng **từ prefs đang giữ trong state** (state nạp mỗi lần mở màn),
    không có hằng số sao chép trong widget: đổi `dailyHour`/`budgetEarlyPercent`/
    `recurringDaysBefore`/`weeklyHour`/`monthlyHour` → dòng phụ tương ứng đổi theo.
15. Giờ hiển thị `HH:mm` 24 (0–23 pad 2 chữ số), `formatClock(20, 5)` → `'20:05'`;
    **không** đổi theo ngôn ngữ.
16. Hậu tố `' · chỉ nhắc nếu chưa ghi'` **chỉ** xuất hiện khi
    `dailyOnlyIfNoTxnToday == true`.

**Không đụng dữ liệu khác (FR-018)**

17. Màn chỉ gọi `NotificationStore` (1 row `AppSettings`); **không** hàm nào của
    module này chạm `transactions`/`wallets`/`categories`/`budgets`/`scan_sessions`.

---

## 3. Vòng đời giá trị

| Sự kiện | Row `notificationPrefs` | Màn hiển thị |
|---|---|---|
| DB mới tạo (onCreate) | **không** có row (không seed) | — (màn chưa mở) |
| Mở màn lần đầu | `load` → mặc định; màn `save` → **có row mặc định** | Bộ mặc định FR-008 |
| Chạm 1 công tắc | upsert row với prefs mới (16 trường) | Chỉ hàng đó đổi |
| Đóng app rồi mở lại | row còn nguyên | Đúng trạng thái đã đặt |
| Mở màn lại (kể cả không đổi gì) | `save` lại bộ vừa đọc (idempotent) | Đúng cấu hình đang lưu |
| Dữ liệu hỏng trong row | lần mở kế tiếp chuẩn hoá về giá trị hợp lệ | Không trắng màn, không ném |
| DB lỗi (mở/ghi thất bại) | không đổi | Nhánh lỗi "Không đọc được cài đặt." + nút **Thử lại** (khuôn PBI 17) |
| Xoá app / cài lại | không còn row | Về bộ mặc định (đúng kịch bản 6) |

---

## 4. Truy vết yêu cầu → luật

| FR / SC | Luật / thành phần |
|---|---|
| FR-001, SC-002 | Hàng điểm vào mới ở màn Cài đặt (§1.2 ngoài màn) + seam `onManageNotificationsTap` |
| FR-002 | `SubPageScaffold` (app bar teal + back; không bottom nav, không FAB) |
| FR-003, FR-004, FR-005, SC-001 | §1.2 (5 nhóm, 8 hàng, icon + sắc theo nhóm, đúng 1 điều khiển/hàng) |
| FR-006, SC-003 | Luật 11 |
| FR-007, SC-004 | Luật 7–10, 13; §1.3 |
| FR-008 | §1.1 (cột Mặc định) + Luật 1 |
| FR-009, SC-006 | Luật 14–16 |
| FR-010, SC-005 | Luật 12 |
| FR-011, SC-008 | §1.2 (2 hàng chevron) + handler rỗng (research R11) |
| FR-012, SC-007 | Không có mã nào gọi plugin thông báo/quyền (research R14) |
| FR-013, SC-009 | Luật 17 + màn không chặn gì |
| FR-014 | §1.2 (nhóm MỤC TIÊU/GIAO DỊCH ĐỊNH KỲ vẫn là công tắc thật; mặc định `goalEnabled=false`) |
| FR-015, SC-010 | Luật 15 + khoá dịch cho mọi nhãn tĩnh (research R10) |
| FR-016, SC-010 | Token `SoraColors` (teal/coral light + dark) — research R8 |
| FR-017, SC-011 | `ListView` cuộn + tiêu đề ellipsis + dòng phụ wrap (research R7) |
| FR-018, SC-012 | Luật 17 |

---

## 5. Ngoài mô hình dữ liệu này (PBI sau)

Bảng `NotificationRule` (doc §3.1: `type`, `enabled`, `config`, `lastFiredAt`) và
bảng `NotificationLog` (lịch sử cho Trung tâm thông báo) **không** dựng ở đợt này:
chúng phục vụ **engine** và **màn `03`** — chưa thuộc phạm vi (Q1=A). Khi engine ra
đời, row `notificationPrefs` này là nguồn để migrate/đọc tiếp; `lastFiredAt` (chống
bắn trùng) là dữ liệu **của engine**, không phải cấu hình người dùng.
