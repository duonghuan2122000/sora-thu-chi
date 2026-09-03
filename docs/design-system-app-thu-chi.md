# DESIGN SYSTEM: APP QUẢN LÝ THU CHI

> Tổng hợp từ bộ mockup SVG (Material Design, Flutter Mobile) — dùng làm tài liệu tham chiếu khi triển khai UI thực tế.

---

## 1. Nguyên tắc thiết kế chung

- **Phong cách:** Material Design, phẳng (flat), không đổ bóng nặng, không gradient — ưu tiên rõ ràng, dễ đọc số liệu tài chính.
- **Mật độ thông tin:** Vừa phải — mỗi màn hình tập trung 1 tác vụ chính (nhập PIN, xem tổng quan, chỉnh 1 nhóm cài đặt).
- **Bo góc:** Card/section bo góc `10px`; khung điện thoại/màn hình bo `24–28px`; nút bấm số (numpad) và avatar dùng hình tròn (`50%`).
- **Khoảng cách:** Padding ngang màn hình `20–24px`; khoảng cách giữa các dòng trong danh sách `~40px` chiều cao dòng.

---

## 2. Bố cục màn hình (Layout)

### 2.1. Khung điều hướng chính (App Shell)
- **Bottom Navigation Bar** cố định, 5 vùng, 4 tab hiển thị + 1 nút hành động nổi (FAB) ở giữa:

| Vị trí | Tab | Icon gợi ý |
|---|---|---|
| 1 | Tổng quan (Dashboard) | home |
| 2 | Giao dịch | list |
| — | **FAB: Thêm giao dịch nhanh** | plus (nổi giữa, đè lên thanh nav) |
| 3 | Báo cáo | chart-pie |
| 4 | Cài đặt | settings |

- FAB đặt **giữa thanh bottom nav**, nhô lên trên (`translateY` âm), hình tròn, nền màu thương hiệu, icon dấu cộng màu trắng — vì "Thêm giao dịch" là hành động lõi, tần suất dùng cao nhất.
- Tab đang chọn: icon + label đổi sang màu thương hiệu (teal), có thể in đậm label. Tab chưa chọn: màu xám trung tính.

### 2.2. Cấu trúc màn hình theo loại
| Loại màn hình | Cấu trúc |
|---|---|
| Màn hình chính (trong app) | Header màu thương hiệu (chứa tiêu đề/số liệu tổng) + nội dung cuộn + bottom nav |
| Sub-page (từ Cài đặt) | App bar màu thương hiệu có nút back + tiêu đề, không hiện bottom nav |
| Màn hình bảo mật (Khóa PIN, Sinh trắc học) | Toàn màn hình, không app bar, không bottom nav — độc lập, chạy trước khi vào app |

### 2.3. Danh sách cài đặt (Settings list)
- Nhóm theo section, mỗi section có tiêu đề nhỏ viết hoa, màu xám nhạt (VD: "TÀI KHOẢN", "KHÁC").
- Mỗi dòng dạng `ListTile`: icon trái (tùy chọn) + label + giá trị/chevron/toggle bên phải, có đường kẻ phân cách mảnh giữa các dòng.

### 2.4. Bàn phím số (PIN Keypad)
- Lưới `3 cột x 4 hàng`, nút tròn đường kính ~48–52px, viền mảnh, không nền (trừ khi nhấn).
- Hàng cuối: góc trái là icon phụ (vân tay, nếu màn khóa chính) hoặc để trống (nếu là màn đổi PIN), giữa là số `0`, phải là icon xóa (backspace).
- Dot indicator hiển thị số ký tự đã nhập, đặt phía trên bàn phím, chấm tròn nhỏ (đường kính ~12px): đã nhập = tô đặc màu thương hiệu, chưa nhập = viền rỗng màu xám.

---

## 3. Bộ màu (Color Palette)

| Vai trò | Mã màu | Sử dụng |
|---|---|---|
| **Màu thương hiệu chính (Teal)** | `#0F6E56` | App bar, FAB, nút chính (primary button), icon/label tab đang chọn, dot PIN đã nhập, toggle bật |
| **Teal nhạt (nền nhấn)** | `#E1F5EE` | Nền icon vòng tròn (khóa, vân tay), khối nhấn nhẹ |
| **Teal trung (avatar)** | `#3D8C77` | Nền avatar mặc định (chữ viết tắt tên) |
| **Coral (cảnh báo/chi tiêu)** | `#D85A30` | Icon mũi tên "Chi tiêu", các cảnh báo liên quan chi tiêu vượt mức |
| **Chữ chính** | `#1A1A1A` | Tiêu đề, số liệu quan trọng, nhãn trên nền trắng |
| **Chữ phụ** | `#5F5E5A` | Label mô tả trong danh sách cài đặt |
| **Chữ phụ nhạt hơn** | `#6B6B6B` | Phụ đề dưới tiêu đề (VD: "Mở khóa Sora Thu Chi") |
| **Chữ mờ / tab chưa chọn** | `#9B9B9B` | Icon/label tab chưa chọn, tiêu đề section viết hoa |
| **Viền/chấm chưa nhập** | `#B4B2A9` | Viền dot PIN rỗng |
| **Nền khối phụ** | `#F1EFE8` | Nền card thống kê nhanh (thu/chi tháng này) |
| **Đường kẻ phân cách** | `#E0E0E0` / `#EFEFEF` | Viền numpad, đường kẻ giữa các dòng danh sách |
| **Nền trắng** | `#FFFFFF` | Nền màn hình mặc định |
| **Chữ/icon trên nền teal** | `#FFFFFF` (đặc), `rgba(255,255,255,0.8–0.85)` (phụ) | Text trên header/app bar teal |

**Quy tắc phối màu:**
- Chỉ dùng **1 màu thương hiệu (teal)** cho toàn bộ hành động chính và trạng thái "đang chọn/đang bật" — tránh loang màu để giữ tính nhất quán thương hiệu.
- Màu **coral** chỉ dành riêng cho ngữ cảnh "chi tiêu"/cảnh báo, không dùng cho mục đích trang trí khác — để người dùng liên tưởng nhất quán thu (xanh teal) – chi (cam coral).
- Nền màu (teal đậm) luôn đi kèm chữ trắng; không dùng chữ đen trên nền teal.

---

## 4. Kiểu chữ (Typography)

| Cấp độ | Kích thước | Độ đậm | Dùng cho |
|---|---|---|---|
| Tiêu đề số liệu lớn | 22–24px | 600 (semibold) | Số dư tổng, số tiền chính |
| Tiêu đề màn hình / app bar | 15–16px | 600 | "Tổng quan", "Cài đặt", "Đổi mã PIN" |
| Nội dung chính | 13–14px | 400–600 | Tên hiển thị, nút bấm, giá trị cài đặt |
| Phụ đề / mô tả | 11–12px | 400 | Mô tả dưới tiêu đề, label trong danh sách |
| Nhãn nhỏ / section header | 9–11px | 400–600, viết hoa | Label tab, tiêu đề nhóm cài đặt |

- Font family: sans-serif hệ thống (Roboto trên Android theo chuẩn Material).
- Số tiền luôn căn phải trong danh sách, định dạng phân cách nghìn bằng dấu chấm, đơn vị "đ" phía sau (VD: `42.500.000 đ`).

---

## 5. Thành phần giao diện (Component Style)

| Thành phần | Style |
|---|---|
| **Nút chính (Primary button)** | Nền teal đặc, chữ trắng, bo góc `8px`, cao `44px` |
| **Nút phụ (Secondary button)** | Nền trắng, viền `#E0E0E0`, chữ đen, bo góc `8px` |
| **FAB** | Hình tròn `48–52px`, nền teal, icon trắng, nổi trên bottom nav |
| **Toggle/Switch** | Track bo pill, nền teal khi bật + chấm tròn trắng nằm bên phải; nền xám khi tắt + chấm bên trái |
| **Avatar** | Hình tròn, nền teal trung, chữ viết tắt tên màu trắng, hoặc ảnh thật nếu người dùng chọn |
| **Card thống kê nhanh** | Nền `#F1EFE8`, bo góc `10px`, icon trạng thái (mũi tên lên/xuống) + label + giá trị căn phải |
| **App bar (sub-page)** | Nền teal, icon back trắng bên trái, tiêu đề trắng cạnh icon |
| **Numpad button** | Hình tròn, viền `#E0E0E0`, không nền, chữ đen |
| **Dot PIN indicator** | Chấm tròn nhỏ, đặc teal (đã nhập) / viền xám rỗng (chưa nhập) |

---

## 6. Icon

- Sử dụng bộ icon dạng outline (line icon), nét mảnh, nhất quán độ dày trên toàn app — phù hợp phong cách Material phẳng.
- Icon trạng thái/hành động dùng màu ngữ cảnh (teal cho hành động chính, coral cho chi tiêu, xám cho trung tính/chưa chọn).
- Kích thước icon trong danh sách: ~15–16px; icon trong vòng tròn lớn (khóa, vân tay): ~28–32px trong khối nền 44–64px.

---

## 7. Áp dụng nhất quán

- Mọi **sub-page** truy cập từ Cài đặt (Đổi PIN, Quản lý ví, Danh mục...) đều dùng chung mẫu app bar teal + nút back — đảm bảo cảm giác điều hướng thống nhất.
- Màn hình **bảo mật** (khóa PIN, sinh trắc học) tách biệt hoàn toàn khỏi app shell (không bottom nav) để nhấn mạnh đây là lớp bảo vệ trước khi vào ứng dụng.
- Màu **teal** là hằng số xuyên suốt nhận diện thương hiệu: xuất hiện ở app bar, FAB, trạng thái chọn/bật, không thay đổi theo từng màn hình.
