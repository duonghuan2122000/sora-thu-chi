# Kịch bản khởi động nhanh — PBI 14 (Màn thêm/sửa danh mục)

**Mã PBI**: 14 — **Ngày**: 2026-09-05

Nhóm QA A–I đối chiếu acceptance/FR/SC spec 14. Chạy `flutter test` (toàn bộ) + `flutter analyze` trước; QA tay emulator theo dưới (DB fresh v4 — seed danh mục có sẵn).

**Cách vào**: Cài đặt → **Danh mục** (màn `01`). FAB "+" → Thêm; chạm **danh mục cấp 1 không con** → Sửa. (Điểm sửa danh mục con nằm ở màn danh mục con `03` — PBI sau; đợt này phủ bằng widget test trực tiếp.)

## A — Bố cục màn Thêm (acceptance 1, SC-001/002)
- Tab **Chi tiêu** đang mở → FAB "+" → màn "Thêm danh mục": app bar teal + back + chữ **Lưu** góc phải; pill Chi tiêu/Thu nhập (**Chi tiêu** chọn sẵn); ô TÊN rỗng; bộ BIỂU TƯỢNG & MÀU SẮC có mục chọn sẵn; ô DANH MỤC CHA = "Không có — là danh mục gốc"; công tắc "Ẩn khỏi danh sách nhanh" **tắt**; nút chính "Lưu danh mục" cuối màn; **không** bottom nav.
- FAB từ tab **Thu nhập** → loại mặc định "Thu nhập" (acceptance 2). Về lại, chuyển loại trước lưu được.
- Màn mở hiển thị nhanh (< 1 s), cuộn êm.

## B — Thêm thành công, vào cuối nhóm (acceptance 3, SC-003)
- FAB (chi) → nhập tên "Ăn vặt", chọn icon + màu → Lưu → về danh sách, **"Ăn vặt" xuất hiện cuối nhóm chi** (không refresh tay). Vào lại Cài đặt → Danh mục → thấy giữ.
- Lặp cho tab thu (VD "Lãi tiết kiệm") → về cuối nhóm thu.

## C — Trùng tên bị chặn (acceptance 4, SC-004)
- FAB (chi) → tên **"Ăn uống"** → bấm lưu → **lỗi ngay dưới ô tên**, không lưu. Đổi tên khác → lưu được.
- Trùng bản **ẩn**: sửa 1 danh mục chi (không con, VD "Di chuyển") → bật "Ẩn…" → Lưu → nó hiện "Đã ẩn". FAB (chi) tên "Di chuyển" → vẫn báo trùng (bản ẩn vẫn tính).

## D — Đổi loại lọc danh sách cha (acceptance 5)
- FAB (chi) → chọn cha = một danh mục chi (VD "Nhà ở") → chuyển pill sang **Thu nhập** → ô cha về "Không có — là danh mục gốc"; mở danh sách cha → chỉ toàn **danh mục gốc thu**, không lẫn chi.

## E — Sửa danh mục gốc không con (acceptance 6/9/14, SC-006/007)
- Chọn 1 danh mục chi **không con, chưa có giao dịch** (thử đổi loại xem còn mở khóa — nếu khóa tức đã có gd, chọn danh mục khác) → màn "Sửa danh mục", mọi trường **điền sẵn 100%** (tên/icon/màu/cha/ẩn), loại = loại hiện tại.
- Đổi tên + icon + màu → Lưu → về danh sách phản ánh ngay.
- Sửa lại → bật "Ẩn…" → Lưu → dòng hiện "Đã ẩn" + mờ (quy ước PBI 13). Sửa danh mục ẩn → công tắc bật sẵn → tắt → Lưu → hết "Đã ẩn".
- Back trước khi lưu → không đổi gì. Chạm **Lưu** (app bar) cũng lưu được như nút chính.

## F — Khóa đổi loại khi đã gắn giao dịch (acceptance 8, SC-005)
- Tạo 1 giao dịch chi gắn danh mục "Mua sắm" (màn Giao dịch → FAB). Về Cài đặt → Danh mục → sửa "Mua sắm" → ô loại **khóa** (không đổi được); tên/icon/màu/ẩn vẫn sửa.
- Đổi loại danh mục gốc **sạch** (chưa gd) từ chi → thu → lưu → chuyển về cuối nhóm thu, không còn tab chi (acceptance 7).
- (Khóa "có con"/"là con": điểm vào chưa mở đợt này — cover widget test, quickstart mục QA widget.)

## G — Tên trống / quá dài (acceptance 12, edge 30 ký tự)
- Để trống tên hoặc nhập toàn khoảng trắng → Lưu → "Tên danh mục không được để trống".
- Nhập đúng 30 ký tự → hợp lệ lưu được; nhập thêm quá 30 → không gõ thêm được.
- Sửa **giữ nguyên tên** → không báo trùng chính nó, lưu bình thường (edge).

## H — Cỡ chữ lớn / safe area (SC-008)
- Bật cỡ chữ hệ thống lớn nhất → màn cuộn tới cuối đầy đủ, nút "Lưu danh mục" không bị che, không overflow/vỡ bố cục.

## QA widget (phủ điểm entry chưa mở tay)
- Sửa **danh mục con** ("Cà phê") qua pump trực tiếp form → loại khóa (con cùng loại cha); đổi cha/bỏ cha lưu đúng nhóm (acceptance 10).
- Sửa danh mục **có con** qua pump → loại khóa + ô cha không mở được (FR-008, acceptance 11).
- Lưu chạm nhanh nhiều lần → chỉ ghi 1 lần (FR-011/SC-007, acceptance edge).
- Trạng thái "Đã ẩn" qua toggle sửa (E) — verify UI; tắt/hiện lại lưu.

## Giới hạn biết trước
- Danh mục con & danh mục có con **không** sửa được bằng tay đợt này (điểm vào ở màn `03` — PBI sau); màn sửa dựng đủ và test widget trực tiếp.
- Giao dịch cũ của DB nâng cấp `< v4` giữ `category_id = null` → danh mục chỉ được text snapshot tham chiếu không khóa loại (chấp nhận dev-DB; DB fresh v4 luôn set `category_id` — quickstart dùng DB mới).
