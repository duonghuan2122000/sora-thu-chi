# Kịch bản kiểm thử: Màn hình Cài đặt

**Mã PBI**: 4

Chạy nhanh trên thiết bị/emulator (Android là nền tảng kiểm chứng chính):

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze        # phải sạch
flutter test           # toàn bộ test pass (shell PBI 2 + PIN PBI 3 + settings PBI 4)
flutter run            # chạy app
```

> Vì PBI 3 bắt buộc đặt PIN lần đầu, trên máy đã có dữ liệu cũ: gỡ app hoặc xóa dữ liệu → đặt PIN rồi mới vào tab Cài đặt kiểm theo nhóm bên dưới.

## Nhóm A — Bố cục & dữ liệu hiển thị lần đầu (SC-001, SC-002, FR-001..005)

1. Bản cài sạch → đặt PIN → vào **tab Cài đặt** → thấy đúng thiết kế `04-ho-so-ca-nhan.svg`:
   - Header teal: tiêu đề **"Cài đặt"** + khối hồ sơ: avatar tròn (nền teal trung) chữ **"ND"**, tên **"Người dùng"**, dòng phụ **"Chạm để đổi ảnh đại diện"**. *(SC-001, SC-002)*
   - Nhóm **TÀI KHOẢN**: hàng **"Tiền tệ mặc định"** + giá trị **"VND"** (phải, đậm); **"Đổi mã PIN"** (chevron); **"Mở khóa sinh trắc học"** (công tắc **tắt**).
   - Nhóm **KHÁC**: hàng **"Quản lý ví"** (chevron). *(SC-002)*
   - Tab **Cài đặt** ở thanh đáy được tô teal (đang chọn).
2. Không có ô trống/vỡ bố cục khi chưa đặt tên, chưa đổi tiền tệ. *(SC-001)*

## Nhóm B — Các hàng chưa kích hoạt & công tắc sinh trắc (SC-003, FR-006/007)

3. Chạm lần lượt: hàng "Đổi mã PIN", hàng "Quản lý ví", vùng ảnh/khối hồ sơ → **không mở màn hình nào**, **không lỗi**. *(SC-003)*
4. Chạm vào công tắc "Mở khóa sinh trắc học" nhiều lần (kể cả chạm nhanh) → công tắc **giữ nguyên tắt**, không bật lên. *(FR-007, SC-003)*
5. Chạm hàng "Tiền tệ mặc định" → không có phản hồi/luồng nào (đổi tiền tệ ngoài phạm vi).

## Nhóm C — Giữ vị trí cuộn khi chuyển tab (SC-004, FR-009)

6. Bật cỡ chữ lớn (hệ thống) để nội dung danh sách dài hơn màn → cuộn tab Cài đặt xuống giữa chừng.
7. Chuyển sang Giao dịch/Báo cáo rồi quay lại Cài đặt, lặp **≥ 5 lần** → trở về **đúng vị trí cuộn** lúc rời đi, không reset về đầu. *(SC-004)*

## Nhóm D — Layout cỡ chữ lớn & vùng an toàn (SC-005, FR-008/010)

8. Bật cỡ chữ **lớn nhất** hỗ trợ + xem trên màn hình có vùng an toàn (notch/tai thỏ hoặc nút cử chỉ) → mọi thành phần (khối hồ sơ, section, hàng, thanh đáy) hiển thị đầy đủ, **không vỡ/tràn/che**; thanh điều hướng đáy giữ nguyên, không che hàng cuối. *(SC-005)*

## Nhóm E — Chế độ chỉ hiển thị (SC-006, định tính)

9. Sau các thao tác ở nhóm A–D, rời tab rồi quay lại → không có giá trị nào trên màn đổi khác đi (tên vẫn "Người dùng", tiền tệ "VND", công tắc vẫn tắt) — xác nhận không thao tác nào ghi dữ liệu hồ sơ. *(SC-006)*

## Nhóm F — Không lộ sau màn khóa (FR-011)

10. Đang đứng ở tab Cài đặt → đưa app xuống nền rồi mở lại → hiện **màn khóa PIN** che toàn bộ (không thấy nội dung Cài đặt). Nhập đúng PIN → về đúng tab Cài đặt với trạng thái như trước. *(FR-011)*

## Phạm vi KHÔNG kiểm tra đợt này

Luồng Đổi mã PIN, bật sinh trắc học, nội dung Quản lý ví, sửa tên/ảnh hồ sơ, đổi tiền tệ mặc định — đều ngoài phạm vi (spec §Ngoài phạm vi); hàng tương ứng chỉ là điểm vào trạng thái treo.
