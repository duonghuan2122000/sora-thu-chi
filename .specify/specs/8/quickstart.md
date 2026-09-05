# Kịch bản khởi động nhanh — PBI 8: Chuyển tiền giữa các ví

Chạy trên emulator (dữ liệu seed PBI 7: Tiền mặt 3.200.000 đ, Vietcombank 14.800.000 đ, Thẻ tín dụng VIB, Momo 1.450.000 đ, Sổ tiết kiệm 9.000.000 đ — ẩn). Mở app → mở khóa PIN → Cài đặt → Ví → Vietcombank.

## Nhóm QA-A — Luồng chuyển tiền cơ bản (acceptance 1–7, SC-001/002)

1. Mở chi tiết **Vietcombank** → chạm **Chuyển tiền** (1 chạm) → màn "Chuyển tiền giữa ví" mở, ô **Từ ví** = Vietcombank kèm "Số dư: 14.800.000 đ", ô **Đến ví** trống.
2. Chạm ô **Đến ví** → danh sách hiện các ví hoạt động cùng tiền tệ (khác Vietcombank, **không** có thẻ tín dụng VIB, **không** có Sổ tiết kiệm ẩn): phải có Tiền mặt, Momo. Chọn **Momo** → ô Đến ví = Momo kèm 1.450.000 đ.
3. Chạm nút **hoán đổi** giữa hai ô → Từ ví = Momo, Đến ví = Vietcombank, số dư hai ô đổi theo. Hoán đổi lại để nguồn về Vietcombank.
4. Chạm trường **Số tiền chuyển**, gõ `2000000` → ô hiển thị `2.000.000`, hậu tố `đ`. **Ngày giờ** mặc định hiện tại; đổi sang hôm qua rồi đổi lại cho đúng (để QA số dư trực tiếp).
5. Dòng **Số dư sau chuyển** hiển thị đúng `12.800.000 đ / 3.450.000 đ` (SC-002, đối chiếu tính tay).
6. Chạm **Xác nhận chuyển tiền** → quay về màn chi tiết Vietcombank, số dư **12.800.000 đ**; màn chi tiết **Momo** số dư **3.450.000 đ** (mở từ danh sách). Cả hai màn, nhóm "GIAO DỊCH GẦN ĐÂY" có dòng khoản chuyển màu **trung tính** (không teal/coral), tiêu đề là ghi chú (hoặc "Chuyển khoản").
7. **Tổng thu/chi toàn app không đổi** (SC-003): đối chiếu màn Tổng quan / Báo cáo trước & sau chuyển — không con số nào đổi.

## Nhóm QA-B — Biên danh sách ví đích (acceptance 2/3, FR-003/011/018/019)

1. Màn chi tiết **Thẻ tín dụng VIB** → chạm **Chuyển tiền** → **không mở** màn chuyển; thông báo rõ "thẻ tín dụng chưa dùng để chuyển tiền" (acceptance 10). Không lỗi.
2. Từ chi tiết Vietcombank: danh sách đích **không** chứa chính Vietcombank (không chọn trùng), **không** chứa ví ẩn, **không** chứa thẻ tín dụng.
3. Từ chi tiết **Sổ tiết kiệm** (hiện đang ẩn → bỏ ẩn trước khi test, hoặc tạo ví savings mới): chạm Chuyển tiền → ô Từ ví nạp sẵn Sổ tiết kiệm, danh sách đích gồm ví hoạt động khác → chuyển được (sổ tiết kiệm như ví thường).
4. Tạo (hoặc dùng) thiết bị **chỉ còn một ví hoạt động**: mở Chuyển tiền → thông báo rõ "chưa có ví đích" (spec biên), không treo/kẹt ở nút vô hiệu. (Khó QA tay vì seed 4 ví hoạt động → có thể phủ bằng test tự động widget/unit, xem bên dưới.)

## Nhóm QA-C — Validation & cảnh báo (acceptance 4–6, FR-005/008/009/010, SC-004/005)

1. Chưa chọn **Đến ví** → nút Xác nhận vô hiệu (hoặc báo cần chọn đủ hai ví).
2. Số tiền để trống / `0` → chạm Xác nhận → bị chặn, báo lỗi **tại trường số tiền**, không tạo khoản chuyển.
3. Ngày giờ để trống/không hợp lệ → báo lỗi tại trường ngày giờ.
4. Nguồn số dư ít hơn tiền chuyển (ví dụ Từ ví Tiền mặt 3.200.000, chuyển `5.000.000`) → dòng Số dư sau chuyển hiện `−1.800.000 đ / …` + cảnh báo mềm "Số dư sau chuyển sẽ âm"; nút Xác nhận **vẫn hoạt động**; xác nhận → số dư âm đúng (SC-005).
5. Nhập số rất lớn (nhiều chữ số) → hiển thị đúng, phân tách nghìn chính xác, không tràn/tràn định dạng.

## Nhóm QA-D — Toàn vẹn & chống trùng (acceptance 8/9, FR-012/015, SC-006)

1. **Quay lại giữa chừng**: soạn một phần (đã nhập tiền/ghi chú) → chạm nút back chưa xác nhận → không tạo khoản chuyển, về chi tiết ví như cũ.
2. **Chạm đúp**: bấm nhanh hai lần **Xác nhận chuyển tiền** → chỉ đúng **một** khoản chuyển (không trùng): kiểm tra số dư hai ví và số dòng trong "GIAO DỊCH GẦN ĐÂY".
3. **Không lệch một phía**: chỉ tạo được trạng thái hai ví cùng đổi hoặc không đổi gì — thao tác QA cơ bản kiểm số dư hai ví sau khi chuyển luôn khớp tổng tiền.
4. **Restart app** → số dư hai ví và khoản chuyển trong "GIAO DỊCH GẦN ĐÂY" còn đúng (persist drift) — kiểm điểm mới của đợt này.

## Nhóm QA-E — Bố cục & chữ lớn / safe area (acceptance 11, FR-016/017, SC-007/008)

1. Bật **cỡ chữ lớn nhất** trong thiết lập hệ thống → mở màn chuyển tiền: mọi trường, dòng "Số dư sau chuyển" và nút Xác nhận hiển thị đầy đủ, màn **cuộn được**, không vỡ/tràn.
2. Xem trên màn hình có notch/vùng an toàn (emulator có tai thỏ) → không tràn vào vùng an toàn.
3. Đối chiếu trực quan mockup `docs/wallet/wallet-transfer-screen.svg`: bố cục, nhãn ("Từ ví", "Đến ví", "Số tiền chuyển", "Ngày giờ", "Ghi chú", "Số dư sau chuyển", "Xác nhận chuyển tiền"), màu thương hiệu teal, định dạng tiền tệ (SC-008).

## Nhóm QA-F — Khóa app (FR-017)

Khóa app (PIN) đang hiệu lực → màn chuyển tiền chỉ mở sau khi mở khóa; không lộ số dư ví qua màn hình khóa. (Hạ tầng PBI 3 — kiểm tra không hồi quy.)

## Kiểm thử tự động (đi kèm)

- Unit thuần: `transfer_rules` (lọc đích: loại credit/ẩn/khác tiền tệ/trùng nguồn; chỉ một ví hoạt động; nguồn credit chặn), `parseAmount` (phân tách nghìn ngược), format dòng "Số dư sau chuyển".
- Controller/repository với `FakeWalletRepository`: transfer ghi qua repo → reload; đúng 2 vế + đổi balance.
- DAO drift (`NativeDatabase.memory()`): migration v2 tạo bảng + seed 11 dòng; `performTransfer` atomic — ghi 2 dòng `transfer_group_id` chung + trừ/cộng đúng balance; rollback khi lỗi giữa chừng (skip-guard nếu host thiếu sqlite).
- Widget: màn chuyển tiền (chọn đích, hoán đổi, preview số dư, cảnh báo âm, lỗi đúng trường, chạm đúp chỉ 1 lần gọi); màn chi tiết ví cập nhật danh sách sau khi trở về; chặn credit.

## Tiêu chí pass

Mọi nhóm A–F chạy đúng như kỳ vọng, `flutter analyze` sạch, `flutter test` xanh. Nếu thiếu thiết bị cỡ chữ lớn/safe area thật → phủ bằng widget test; nếu host thiếu sqlite → DAO skip-guard + QA emulator.
