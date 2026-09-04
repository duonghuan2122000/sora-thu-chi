# Kịch bản kiểm thử: Màn hình danh sách ví

**Mã PBI**: 5

Chạy nhanh trên thiết bị/emulator (Android là nền tảng kiểm chứng chính):

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze        # phải sạch
flutter test           # toàn bộ test pass (shell PBI 2 + PIN PBI 3 + settings PBI 4/5 + wallet PBI 5)
flutter run            # chạy app
```

> PIN bắt buộc lần đầu (PBI 3): bản cài cũ → gỡ app/xóa dữ liệu → đặt PIN → mới vào được. Vào màn list ví: **Cài đặt → hàng "Quản lý ví"**.
>
> Đợt này chưa có luồng tạo ví nên màn hiển thị **5 ví mẫu** cố định (3 ví thường + 1 thẻ tín dụng + 1 ví ẩn, khớp SC-003). Số liệu mẫu:
>
> | Ví | Loại | balance | Ghi chú |
> |---|---|---|---|
> | Tiền mặt | cash | 3.200.000 | **Mặc định** |
> | Vietcombank | bank | 14.800.000 | |
> | Thẻ tín dụng VIB | credit | limit 20.000.000 / used 6.500.000 | |
> | Momo | eWallet | 1.450.000 | |
> | Sổ tiết kiệm | savings | 9.000.000 | **ẩn** |
>
> Tổng dự kiến: **19.450.000 đ** (3.200.000 + 14.800.000 + 1.450.000 — thẻ & ví ẩn không góp) — nhãn phụ **"4 ví đang hoạt động"**.

## Nhóm A — Điều hướng & bố cục chung (FR-001..004, SC-001/002)

1. Vào **Cài đặt** → chạm **"Quản lý ví"** → màn list ví mở ra (app bar teal tiêu đề **"Quản lý ví"** + nút back, **không** bottom nav). *(SC-001, FR-001/002)*
2. Đầu màn: card nền xám nhạt bo 10 — nhãn **"TỔNG SỐ DƯ TẤT CẢ VÍ"**, số **"19.450.000 đ"** (căn trái trong card, cỡ lớn 22), dòng phụ **"4 ví đang hoạt động"**. *(FR-003/004, SC-003)*
3. Dưới card: tiêu đề nhóm **"VÍ CỦA BẠN"** (viết hoa xám) + từng hàng ví có icon tròn, tên, dòng phụ, số dư **căn phải** định dạng `đ`. Đối chiếu bố cục `docs/wallet/wallet-list-screen.svg`. *(SC-002)*

## Nhóm B — Thẻ tín dụng & ví ẩn (FR-007/008, SC-003/004)

4. Hàng **"Thẻ tín dụng VIB"**: dòng phụ **"Đã dùng 6.500.000 / 20.000.000 đ"** màu **coral**, phía phải **"32%"** coral (không hiển thị số dư dương thông thường). *(FR-007, SC-004)*
5. Hàng **"Sổ tiết kiệm (đã ẩn)"**: toàn hàng **xám/mờ**, dòng phụ **"Không tính vào tổng"**, số dư "9.000.000 đ" vẫn hiện nhưng **không** làm đổi tổng card (tổng vẫn 19.450.000). *(FR-008, SC-003)*
6. Hàng **"Tiền mặt"**: có nhãn **"Mặc định"** và chỉ đúng 1 hàng mang nhãn này. Các hàng thường còn lại hiện tên loại (Tài khoản ngân hàng / Ví điện tử). *(FR-006)*

## Nhóm C — Chế độ chỉ hiển thị (FR-010, SC-005/008)

7. Chạm lần lượt **toàn bộ** các hàng ví + nút **"+ Thêm ví mới"** (kể cả chạm nhanh liên tục) → **không mở màn mới**, **0 lỗi**, không thay đổi dữ liệu (quay lại màn sau đó thấy số liệu y nguyên). *(SC-005/008)*
8. Nút **"+ Thêm ví mới"** (teal, đầy đủ, chân màn) **luôn hiển thị** dù danh sách cuộn tới đâu. *(FR-013)*

## Nhóm D — Cuộn, cỡ chữ lớn & vùng an toàn (FR-014, SC-007)

9. Cuộn danh sách hết cỡ → mọi hàng hiển thị đủ; nút thêm không bị che.
10. Bật cỡ chữ **lớn nhất** + màn hình có vùng an toàn (notch/nút cử chỉ) → app bar, card tổng, từng hàng, nút thêm hiển thị đầy đủ, **không vỡ/tràn/che**. *(SC-007)*

## Nhóm E — Quay lại đúng trạng thái (SC-001, FR-001)

11. Từ màn list ví chạm nút **back** → trở về **tab Cài đặt** đúng vị trí cuộn/trạng thái lúc rời đi (IndexedStack giữ tab sống). Đi lại nhiều lần → ổn định, không chồng màn. *(SC-001)*

## Nhóm F — Không lộ sau màn khóa (FR-015)

12. Đang ở màn list ví → đưa app xuống nền rồi mở lại → hiện **màn khóa PIN** che toàn bộ (không lộ nội dung ví). Nhập đúng PIN → về đúng màn list ví lúc rời đi. *(FR-015 — PBI 3 đã đảm bảo cơ chế, kiểm chứng lại không hồi quy)*

## Trạng thái rỗng — lưu ý kiểm chứng

- Trên thiết bị **không tạo được** trạng thái 0 ví (chưa có luồng tạo/xóa) → SC-006 (rỗng: "Chưa có ví nào." + nút thêm còn) được phủ bằng **widget test** bơm danh sách rỗng. Đánh giá QA: xác nhận test pass + màn chính không lỗi.
- Số dư **âm** (ví cash bị chi quá tay) cũng phủ bằng widget test bơm balance âm — kiểm định dấu trừ không gãy định dạng.

## Phạm vi KHÔNG kiểm tra đợt này

Tạo/sửa/ẩn/xóa ví, chi tiết ví, chuyển tiền giữa ví, kéo-thả sắp xếp, đa tiền tệ, privacy "ẩn số dư" — ngoài phạm vi (spec §Ngoài phạm vi); các hàng/nút tương ứng là điểm vào chưa kích hoạt.
