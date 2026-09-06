# Kịch bản khởi động nhanh — PBI 15 (Màn hình danh sách danh mục con)

**Mã PBI**: 15 — **Ngày**: 2026-09-06

Nhóm QA A–H đối chiếu acceptance/FR/SC spec 15. Chạy `flutter test` (toàn bộ) + `flutter analyze` trước; QA tay emulator theo dưới (DB fresh v4 — seed chỉ có "Ăn uống" mang 3 con sẵn: Cà phê, Ăn ngoài, Đi chợ).

**Cách vào**: Cài đặt → **Danh mục** (màn `01`) → chạm **danh mục có con** ("Ăn uống") → màn "Danh mục con". (Cha không con — VD "Di chuyển" — chạm vẫn mở màn Sửa trực tiếp, không đổi luồng PBI 13/14.)

## A — Bố cục màn danh sách con (acceptance 1, SC-002)
- Cài đặt → Danh mục → chạm **"Ăn uống"** → màn mở: app bar **teal**, nút **quay lại** (trái); tiêu đề 2 dòng **"Ăn uống"** (to) + **"Danh mục con"** (nhỏ phía dưới); nút **"+"** (phải); **không** bottom nav, **không** số tiền.
- Danh sách chỉ gồm 3 con: **Cà phê, Ăn ngoài, Đi chợ** — đúng thứ tự, mỗi dòng bubble icon+màu, tên, chevron phải; **không** dòng phụ "N danh mục con".
- Cuối danh sách có hàng **"+ Thêm danh mục con"** (teal). Màn mở hiển thị < 1 s.

## B — Chỉ con của cha đang xem, không lẫn (acceptance 2, SC-003)
- Trước tiên tạo cha thứ hai có con: ở màn `01` FAB "+" → tên "Nhà hàng" → **Danh mục cha = "Ăn uống"** → Lưu (→ đây là con của Ăn uống). Lại FAB → tên "Sửa nhà" → **Danh mục cha = "Nhà ở"** → Lưu (con của Nhà ở).
- Vào màn con của "Ăn uống" → chỉ thấy 3 con seed + "Nhà hàng", **không** thấy "Sửa nhà" (con cha khác). Vào màn con của "Nhà ở" (giờ có 1 con) → chỉ thấy "Sửa nhà".
- (Con thu nhập lẫn vào: seed không có; lọc theo loại — không thể xảy ra vì con luôn cùng loại cha.)

## C — Sắp xếp & tên dài (acceptance 3, SC-003)
- Thứ tự 3 con seed ổn định Cà phê → Ăn ngoài → Đi chợ giữa các lần mở.
- Sửa "Ăn ngoài" → đổi tên thành chuỗi ~30 ký tự → Lưu → dòng không tràn/không cắt chevron, list cuộn mượt.

## D — Con ẩn vẫn hiện + phân biệt được (acceptance 4, SC-004)
- Sửa "Đi chợ" (chạm dòng) → bật **"Ẩn khỏi danh sách nhanh"** → Lưu → về màn con: "Đi chợ" vẫn ở đúng vị trí nhưng **mờ + nhãn "Đã ẩn"**; phân biệt rõ với con đang hoạt động.
- Chạm lại "Đi chợ" → Sửa → công tắc bật sẵn → tắt → Lưu → hết "Đã ẩn".

## E — Sửa danh mục con (acceptance 5, SC-005)
- Chạm "Cà phê" → màn **"Sửa danh mục"** mọi trường **điền sẵn** (tên/icon/màu/ẩn); ô **Loại = Chi tiêu và bị khóa** (readonly — con cùng loại cha); ô "Danh mục cha" hiển thị "Ăn uống".
- Đổi tên "Cà phê" → "Cà phê sữa" + đổi icon/màu → Lưu → về màn con thấy dòng đổi ngay, **không refresh tay**.
- Chạm "Cà phê sữa" → **đổi cha** sang "Nhà ở" (hoặc "Không có — là danh mục gốc") → Lưu → về màn con của "Ăn uống": "Cà phê sữa" **không còn** (đã thuộc nhóm khác — FR-010). Về màn `01`: "Ăn uống" còn 2 con (hoặc 3 nếu có "Nhà hàng"), "Nhà ở" tăng lên.
- Back trước khi lưu → không đổi gì.

## F — Thêm danh mục con (acceptance 6/7, SC-006)
- Từ màn con của "Ăn uống": chạm nút **"+"** (app bar) → màn **"Thêm danh mục"** với ô "Danh mục cha" **= "Ăn uống"** (chọn sẵn) + loại Chi tiêu; chỉ nhập tên "Cà phê sữa", chọn icon/màu → Lưu → về màn con, **"Cà phê sữa" xuất hiện cuối nhóm**, không refresh tay.
- Thử hàng **"Thêm danh mục con"** cuối danh sách → cũng mở Thêm với cha preset như trên.
- Thêm nhanh liên tiếp nhiều lần → mỗi lần 1 danh mục, không trùng lặp; số dòng phản ánh đúng.

## G — Vùng tiêu đề = sửa danh mục cha (acceptance 9/10, SC-009)
- Ở màn con của "Ăn uống", chạm **vùng tiêu đề** (khối "Ăn uống / Danh mục con", giữa back và "+") → màn **"Sửa danh mục"** của "Ăn uống": ô **Loại khóa** (có con), ô **"Danh mục cha" không mở** được (giữ cây 2 cấp), sửa được tên/icon/màu/ẩn.
- Đổi tên "Ăn uống" → "Ăn uống & uống" → Lưu → về màn con: **tiêu đề hiển thị tên mới**, danh sách con **giữ nguyên**.
- Chạm **quay lại** → về màn `01` tại đúng **tab đang mở** ("Chi tiêu"); dòng cha hiện **tên mới** + số con đúng.
- Kiểm vùng chạm không đè nút: chạm sát back → quay lại (không mở Sửa); chạm "+" → mở Thêm (không mở Sửa cha).

## H — Rỗng phòng thủ / cỡ chữ lớn / safe area (edge, FR-012/SC-008)
- Không còn con: chuyển toàn bộ con của "Ăn uống" sang cha khác (E) → màn con hiện hướng dẫn "Chưa có danh mục con" + vẫn có "+"/"Thêm danh mục con" để thêm lại, không lỗi. (Từ màn `01`, cha không con giờ chạm mở Sửa — đúng luồng; empty của màn con là phòng thủ.)
- Bật cỡ chữ hệ thống lớn nhất → màn con cuộn tới cuối, hàng "Thêm danh mục con" không bị che, tiêu đề không vỡ/tràn; an toàn ở vùng có notch.

## QA widget (phủ case khó tạo bằng tay)
- Cha thu có con (income) → màn con income đúng loại (tạo trước bằng cách thêm con dưới "Lương" qua form PBI 14).
- Con đang ẩn vẫn đếm/sắp đúng vị trí; nhiều con ẩn không tạo empty giả.
- Lưu chạm nhanh 2 lần qua form → chỉ ghi 1 lần (PBI 14 đã chặn — xác nhận không hồi quy khi vào từ màn con).

## Giới hạn biết trước
- Seed mặc định chỉ "Ăn uống" có con sẵn; muốn QA nhóm/loại khác → tạo cha-có-con bằng form (đặt "Danh mục cha" khi Thêm) như mục B.
- Màn sắp xếp lại (`04`) và xóa/gộp danh mục ngoài phạm vi (spec 15) — không QA đợt này.
