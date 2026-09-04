# Khởi động nhanh — Kiểm thử Thêm/sửa ví (PBI 7)

**Mã PBI**: 7
**Môi trường**: `app/sora_thu_chi/`, emulator Android (kiểm chứng chính). Yêu cầu đã chạy `flutter pub get` + codegen drift (`dart run build_runner build --delete-conflicting-outputs`) sau khi thêm dependency.

## Chuẩn bị

1. Chạy app: `flutter run`. Lần đầu mở: đặt PIN (PBI 3) → vào shell.
2. Vào **Cài đặt → Quản lý ví** — danh sách 5 ví mẫu (Tiền mặt Mặc định, Vietcombank, Thẻ tín dụng VIB, Momo, Sổ tiết kiệm đã ẩn), tổng `19.450.000 đ`.
3. **Reset dữ liệu** (khi cần chạy lại từ đầu, seed nạp lại): trên emulator, Cài đặt hệ thống → Apps → Sora Thu Chi → **Clear storage** → mở lại app → đặt PIN → về bước 2.

> Ghi chú: DB lưu file thật (drift). Ví tạo ở lần chạy này **còn lại** khi thoát/mở lại app — điểm khác biệt chính so với các PBI trước (bộ mẫu trong bộ nhớ).

## Nhóm QA

### A. Tạo ví tiền mặt — luồng chính (SC-001/003, acceptance 1/2)
- Từ **Quản lý ví**, chạm **+ Thêm ví mới** → màn "Thêm ví mới" (sub-page teal, có nút back, **không** bottom nav).
- Nhập tên "Quỹ chi tiêu hàng ngày", loại **Tiền mặt** (chip), số dư ban đầu `3.200.000`, chọn icon + màu bất kỳ, **không** bật mặc định.
- Chạm **Lưu ví** → về danh sách: ví mới hiển thị, số dư `3.200.000 đ`, tổng = `19.450.000 + 3.200.000 = 22.650.000 đ`, "N ví đang hoạt động" tăng 1 (Tiền mặt vẫn là Mặc định).
- Chạm vào ví mới → màn chi tiết hero `3.200.000 đ`, nhóm giao dịch rỗng ("Chưa có giao dịch nào.").

### B. Bền qua restart — điểm mới của PBI này (SC-003)
- Sau bước A, thoát app hoàn toàn → mở lại → mở khóa PIN → **Quản lý ví**: ví "Quỹ chi tiêu hàng ngày" **vẫn còn** với số dư đúng; tổng vẫn `22.650.000 đ`.

### C. Tạo từng loại & trường riêng (FR-002/003/004, SC-002, acceptance 2/8)
- **Thẻ tín dụng**: loại Thẻ tín dụng → hiện khối **Hạn mức tín dụng** (+ Ngày sao kê, Ngày đến hạn tùy chọn, chọn bằng date picker). Để hạn mức trống hoặc nhập `0` → chạm **Lưu** → **bị chặn**, lỗi rõ tại trường hạn mức, không tạo ví. Nhập `20.000.000` → lưu được. Mở chi tiết thẻ mới → hiển thị dạng "Đã dùng 0 / 20.000.000 đ".
- **Sổ tiết kiệm**: hiện **Kỳ hạn** (tháng) + **Ngày đáo hạn** tùy chọn.
- **Ngân hàng**: hiện **Ngân hàng** + **Số cuối tài khoản** (nhập vài số cuối, chỉ hiển thị).
- **Ví điện tử**: nhãn **Tổ chức** (VD Momo, ZaloPay) + Số cuối.
- **Tiền mặt**: không trường riêng.
- Khi đang ở loại Thẻ nhập hạn mức rồi **đổi sang loại khác chưa lưu** → giá trị trường riêng loại cũ được bỏ, form hiển thị trường loại mới (edge).

### D. Validation & lỗi đúng trường (FR-005, SC-006, acceptance 6/8 + edge)
- Tên rỗng / chỉ khoảng trắng → Lưu chặn, lỗi tại **tên**.
- Số dư ban đầu bỏ trống (khi tạo) → chặn tại trường số dư. Nhập `0` → **hợp lệ** (lưu được).
- Nút **Lưu** cố định chân màn luôn với tới; khi có lỗi, dữ liệu đã nhập **giữ nguyên** trên form (không mất, FR-014).
- **Back chưa lưu** (acceptance 9): chỉnh vài trường rồi back → không tạo/sửa gì, về màn trước đúng trạng thái.

### E. Ví mặc định — bất biến (FR-007/008, acceptance 4, SC-005)
- Từ danh sách mở ví **Vietcombank** (đang không mặc định) → **Sửa ví** → bật **"Đặt làm ví mặc định"** → Lưu → về chi tiết; vào danh sách: Vietcombank mang nhãn **Mặc định**, **Tiền mặt hết mặc định** — chỉ đúng 1 nhãn Mặc định.
- Sửa lại Vietcombank **tắt** cờ → Lưu → hệ thống **tự chọn** một ví active khác làm Mặc định (ví active đầu danh sách); vẫn chỉ 1 Mặc định.
- Sửa **Tiền mặt** (đang là Mặc định) khi ngoài nó còn ví active khác: nút bật cờ ở trạng thái bật; **tắt** → lưu → Tiền mặt không còn mặc định, một ví khác được chọn (đúng edge "tự chọn thay thế").
- Sửa ví default **duy nhất**: xem mục F — tạo ví mới mà không bật mặc định vẫn **không** tạo ra 2 default.

### F. "Ví đầu tiên tự mặc định" (acceptance 3)
- Trên thiết bị luôn có ví mẫu (seed) nên **không QA tay** được trạng thái "0 ví" — phủ bằng **unit test nghiệp vụ** `wallet_rules_test` (danh sách rỗng → tạo → ví mới `isDefault=true`, đúng 1 default).

### G. Sửa ví đã có giao dịch — khóa trường (FR-009/010, acceptance 5/6, SC-004)
- Mở **Vietcombank** (đã có giao dịch mock) → **Sửa ví** → toàn bộ trường nạp đúng giá trị hiện tại.
- **Số dư ban đầu, Tiền tệ, Loại ví**: hiển thị **không chỉnh được** (disabled + ghi chú "Muốn đổi số dư → tạo giao dịch Điều chỉnh số dư"); không có ô nhập "số dư hiện tại".
- Sửa **tên** thành "Vietcombank CN" + đổi icon/màu → Lưu → về chi tiết tên mới hiện ngay; vào chi tiết trước đó: số dư `14.800.000 đ` & danh sách giao dịch **không đổi** (SC-004); danh sách tổng không đổi.
- Thẻ tín dụng VIB: sửa được **hạn mức** (trường riêng) dù đã có giao dịch; type/balance khóa.

### H. Sửa ví chưa có giao dịch — sửa số dư (FR-011, acceptance 7)
- Mở ví mới tạo ở bước A (chưa giao dịch) → **Sửa ví**: sửa được hết, đổi **số dư ban đầu** `3.200.000` → `2.000.000` → Lưu → chi tiết/danh sách hiển thị đúng `2.000.000 đ`.

### I. Cỡ chữ lớn & vùng an toàn (SC-007, acceptance 10)
- Bật cỡ chữ lớn nhất hệ thống (hoặc textScale test) → mở form thêm/sửa: mọi trường + nút **Lưu** hiển thị đủ, body cuộn mượt, không vỡ/tràn.
- Màn có notch/vùng an toàn: form hiển thị đầy đủ (bọc `SafeArea` đúng chỗ).
- Tên ví rất dài → trường nhập không vỡ bố cục.

### J. Khóa PIN che nội dung (kế thừa PBI 3 — regression)
- Đang mở form thêm/sửa ví → đưa app xuống nền → mở lại → màn khóa PIN che toàn bộ; mở khóa → về đúng form còn nguyên dữ liệu đã nhập.

## Chạy tự động

- `flutter analyze` sạch (0 warning).
- `flutter test` toàn bộ pass — gồm: unit `wallet_rules_test` (mặc định), controller test (create/update/đọc qua fake repo), widget test list/detail/form, DAO drift tích hợp (skip nếu host thiếu sqlite — research Q12), và toàn bộ test PBI 2–6 không hồi quy.
