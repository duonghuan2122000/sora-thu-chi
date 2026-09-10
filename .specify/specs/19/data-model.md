# Mô hình dữ liệu: PBI 19 — Chọn ngôn ngữ hiển thị

**Ngày tạo**: 2026-09-10
**Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)

## Tóm tắt: KHÔNG đổi schema

Schema drift **giữ nguyên v5**. Lựa chọn ngôn ngữ là **một row mới** trong bảng key-value `AppSettings` (đã có từ PBI 17, `lib/data/db/app_database.dart:91-98`) — đúng chú thích sẵn có của bảng: "PBI sau chỉ thêm row, không thêm migration". Không thêm cột, không thêm bảng, không seed.

---

## Thực thể 1 — Cài đặt ngôn ngữ (lựa chọn của người dùng)

| Thuộc tính | Kiểu | Ghi chú |
|---|---|---|
| `key` | `String` (PK) | hằng `kKeyLocale = 'locale'` — khai trong `lib/core/locale/locale_prefs.dart`, cùng chỗ với `kKeyThemeMode` |
| `value` | `String` | `'vi'` hoặc `'en'` — viết thường, khớp `Locale.languageCode` (bám cách lưu `themeModeToStorage`) |

**Luật hợp lệ**
- Row **vắng mặt** = người dùng chưa từng đổi ngôn ngữ ⇒ giá trị hiệu lực là **`vi`** (FR-004). Tầng domain quyết định mặc định, không ghi row mặc định xuống DB.
- Chuỗi đọc lên ngoài `'vi'`/`'en'` (dữ liệu lạ/hỏng) ⇒ rơi về `vi`, **không ném** (bám `themeModeFromStorage`).
- Ghi là **upsert chỉ key `locale`**, không xoá/đè các row cài đặt khác (`themeMode`, `hideBalance`, `amountCalculatorEnabled`) — FR-012 (độc lập với theme & các công tắc khác).

**Chuyển trạng thái**

| Từ | Hành động | Đến | Ghi xuống DB |
|---|---|---|---|
| chưa có row (hiệu lực `vi`) | mở màn `03`, không chạm | `vi` | không ghi |
| `vi` | chạm hàng `English` | `en` | upsert `locale='en'` |
| `en` | chạm hàng `Tiếng Việt` | `vi` | upsert `locale='vi'` |
| `vi` | chạm lại hàng `Tiếng Việt` | `vi` | không ghi (hàng đang chọn ⇒ no-op, bám `ThemeController.setMode`) |

## Thực thể 2 — Bộ nhãn dịch (`SoraTranslations`)

| Thuộc tính | Kiểu | Ghi chú |
|---|---|---|
| `keys` | `Map<String, Map<String, String>>` | **chỉ nhánh `'en'`**; khóa = chuỗi tiếng Việt đang hiển thị (R1/R4) |

**Luật**
- Tra khóa: `'<nhãn tiếng Việt>'.tr`. Kết quả: `en` + có khóa → nhãn tiếng Anh; còn lại (locale `vi`, thiếu khóa, `Get.locale == null`) → **trả về chính khóa tiếng Việt**.
- Vì mặc định là `vi` và không có nhánh `vi`, **không cần bản đồ tiếng Việt** (R4).
- Không chứa: dữ liệu seed (tên giao dịch/ghi chú mẫu), `ValueKey`, tên riêng/thương hiệu, ký hiệu định dạng (`đ`, `dd/MM/yyyy`) — R9.
- Chuỗi có nội dung động dùng `trParams`/`trArgs` (VD `'Thử lại sau @giây giây.'`), không nối chuỗi.

## Thực thể 3 — Ánh xạ tên danh mục mặc định

Không phải bảng mới — là **các khóa trong bản đồ `'en'`** trùng đúng **15 tên** trong `CategorySource` (8 cha chi, 4 cha thu, 3 con của "Ăn uống"): `Ăn uống, Di chuyển, Nhà ở, Hóa đơn, Mua sắm, Giải trí, Sức khỏe, Giáo dục, Lương, Thưởng, Đầu tư, Khác, Cà phê, Ăn ngoài, Đi chợ`.

| Trường hợp | Tên trong DB | Hiển thị ở chế độ `en` |
|---|---|---|
| Danh mục mặc định chưa đổi tên | `'Ăn uống'` | `'Food & Drink'` (khớp khóa ⇒ dịch — FR-009) |
| Danh mục mặc định **đã đổi tên** | `'Ăn ngoài cùng đồng nghiệp'` | nguyên văn tên người dùng đặt (không khớp khóa — FR-010) |
| Danh mục người dùng tự tạo | `'Trà sữa'` | nguyên văn (FR-010) |
| Snapshot trên dòng giao dịch (`transactions.category`) | `'Ăn uống'` | `'Food & Drink'` — cùng khóa, cùng kết quả |

**Luật**: dịch **chỉ ở tầng hiển thị**; DB giữ nguyên tên tiếng Việt đã seed. Đổi ngôn ngữ **không** ghi/đổi/xoá bất kỳ dòng dữ liệu nào (FR-010).

## Thực thể 4 — Cặp ngôn ngữ hiển thị trên màn `03` (hằng số giao diện)

| Mã | Tên (endonym) | Dòng phụ (tên ngôn ngữ kia) | `Locale` |
|---|---|---|---|
| `VI` | `Tiếng Việt` | `Vietnamese` | `Locale('vi')` |
| `EN` | `English` | `Tiếng Anh` | `Locale('en')` |

Bốn chuỗi này **bất biến** ở cả hai chế độ giao diện (R8 — người dùng đã chốt, mockup `03`). Chỉ tiêu đề app bar (`'Ngôn ngữ'` → `'Language'`) và ghi chú cuối màn đi qua `.tr`.

## Ngoài mô hình dữ liệu

- Không có trạng thái "đang tải" nào cần lưu: màn `03` đọc lựa chọn từ `LocaleController` trong bộ nhớ.
- Không có quan hệ tới ví/giao dịch/danh mục: ngôn ngữ **không** làm thay đổi bất kỳ bản ghi nào (FR-010, FR-011).
