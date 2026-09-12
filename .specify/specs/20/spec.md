# Đặc tả tính năng: Tổng quan Ngân sách (ngân sách theo danh mục)

**Mã PBI**: 20
**Ngày tạo**: 2026-09-12
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Người dùng cần **đặt giới hạn chi tiêu cho một danh mục trong một kỳ** (tuần/tháng/năm) và **nhìn thấy ngay mình đã dùng bao nhiêu phần trăm** giới hạn đó, thay vì chỉ ghi chép giao dịch một cách thụ động. PBI này dựng **2 màn đầu tiên của module Ngân sách** theo đúng thiết kế `docs/budget/man-hinh-01-tong-quan-ngan-sach.svg` và `docs/budget/man-hinh-02-them-ngan-sach.svg`: **màn Tổng quan Ngân sách** (mở từ tab **Báo cáo**, xem tổng đã chi so với tổng giới hạn và tiến độ từng danh mục theo kỳ đang chọn) và **màn Thêm/Sửa ngân sách** (chọn danh mục, nhập số tiền giới hạn, chọn chu kỳ). Tiến độ được tính lại từ dữ liệu **giao dịch Chi** đã có — tạo ngân sách giữa kỳ thì phần đã chi phản ánh đúng số đã tiêu, không bắt đầu từ 0. Ngân sách chu kỳ **Tuần** hoặc **Năm** vẫn nằm chung danh sách, mỗi dòng hiển thị tiến độ **kỳ hiện tại của chính nó** kèm nhãn chu kỳ; bộ chọn kỳ theo tháng điều khiển các ngân sách chu kỳ **Tháng**.

Đợt này chỉ làm **ngân sách theo danh mục** (chia nhỏ **2a** trong `docs/budget/nghiep-vu-ngan-sach.md` §8): có tạo/sửa, có theo dõi tiến độ; **chưa** có ngân sách tổng, ngân sách theo ví, cộng dồn phần chưa dùng, sao chép kỳ trước, cảnh báo đẩy (push) và màn Chi tiết ngân sách.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Tạo ngân sách cho một danh mục rồi theo dõi tiến độ

1. Người dùng ở tab **Báo cáo** (màn hiện là khung), chạm điểm vào **"Ngân sách"** → màn **Tổng quan Ngân sách** mở ra theo mockup `01`: app bar màu thương hiệu, tiêu đề "Ngân sách", nút **"+"** ở góc phải; **thanh điều hướng đáy vẫn hiện và tab "Báo cáo" đang được chọn**; giữa app bar là bộ chọn kỳ **"Tháng 9, 2026"** kèm 2 mũi tên trước/sau.
2. Lần đầu chưa có ngân sách nào trong kỳ → thân màn hiển thị **trạng thái rỗng** (chưa có thẻ tổng, chưa có danh sách) kèm lời nhắc và nút **"Thêm ngân sách"**.
3. Người dùng chạm nút **"+"** (hoặc nút trong trạng thái rỗng) → màn **Thêm ngân sách** mở ra theo mockup `02`: app bar thương hiệu có nút quay lại, tiêu đề "Thêm ngân sách"; **không** có thanh điều hướng đáy.
4. Nhóm **"Phạm vi ngân sách"** hiển thị 2 lựa chọn **"Theo danh mục"** (đang chọn sẵn) và **"Tổng cộng"**; đợt này chỉ **"Theo danh mục"** có hiệu lực.
5. Người dùng chạm hàng **"Danh mục"** → mở danh sách chọn danh mục; chọn **"Ăn uống"** → hàng danh mục hiển thị icon + tên "Ăn uống" đúng mockup.
6. Người dùng nhập **số tiền giới hạn** `3.000.000` (ô nhập hiển thị số đã phân tách nghìn, đơn vị `đ` đặt sau).
7. Nhóm **"Chu kỳ"** có 3 lựa chọn **Tuần / Tháng / Năm**; mặc định **"Tháng"** đang chọn.
8. Các hàng còn lại hiển thị đúng mockup `02`: **"Ví áp dụng" = "Tất cả ví"**, công tắc **"Lặp lại tự động mỗi kỳ"** đang **bật**, công tắc **"Cộng dồn phần chưa dùng hết"** đang tắt, hàng **"Ngưỡng cảnh báo" = "80% và 100%"**.
9. Người dùng chạm **"Lưu ngân sách"** → hệ thống kiểm tra hợp lệ (đã chọn danh mục, số tiền > 0, không chồng lấn với ngân sách cùng danh mục cùng chu kỳ) → lưu → quay lại màn **Tổng quan Ngân sách**.
10. Màn Tổng quan hiển thị ngay: **thẻ tổng** ("Tổng ngân sách tháng này" = tổng đã chi / tổng giới hạn, thanh tiến độ tổng, "Còn lại … đ", "… ngày còn lại") và **danh sách danh mục** có ngân sách — mỗi dòng: icon danh mục, tên, "đã chi / giới hạn", **% đã dùng**, thanh tiến độ đổi màu theo ngưỡng.
11. Nếu danh mục đó đã có giao dịch Chi trong kỳ (kể cả ghi trước khi tạo ngân sách), dòng ngân sách hiển thị **đúng số đã chi đó** ngay — không bắt đầu từ 0.
12. Người dùng thêm một giao dịch Chi thuộc "Ăn uống" → quay lại màn Tổng quan, dòng "Ăn uống" và thẻ tổng đã **cập nhật theo số mới**.
13. Người dùng chạm vào dòng một ngân sách → mở lại màn **Thêm ngân sách ở chế độ sửa** (tiêu đề "Sửa ngân sách", các trường điền sẵn giá trị hiện tại); sửa số tiền rồi lưu → màn Tổng quan cập nhật theo giá trị mới, **chỉ áp dụng cho kỳ hiện tại**, không làm thay đổi số liệu các kỳ đã qua.

### Kịch bản chấp nhận

1. **Given** người dùng ở tab Báo cáo **When** chạm điểm vào "Ngân sách" **Then** màn Tổng quan Ngân sách mở đúng bố cục mockup `01`: app bar màu thương hiệu + tiêu đề "Ngân sách" + nút "+", bộ chọn kỳ ở giữa, **thanh điều hướng đáy vẫn hiển thị và tab "Báo cáo" đang được chọn**.
2. **Given** màn Tổng quan đang mở **When** nhìn thân màn **Then** thấy thẻ tổng gồm nhãn "Tổng ngân sách tháng này", cặp số "đã chi / tổng giới hạn", thanh tiến độ tổng, dòng "Còn lại … đ" và dòng "… ngày còn lại" của kỳ đang xem.
3. **Given** màn Tổng quan đang mở **When** nhìn nhóm danh sách **Then** thấy tiêu đề nhóm và liên kết "Sao chép tháng trước" ở bên phải; mỗi dòng ngân sách có icon danh mục, tên danh mục, "đã chi / giới hạn", % đã dùng ở cuối dòng và thanh tiến độ bên dưới.
4. **Given** một ngân sách có mức sử dụng dưới 80% **When** xem dòng của nó **Then** % và thanh tiến độ hiển thị màu **teal**; **Given** mức sử dụng từ 80% đến 99% **Then** thanh tiến độ hiển thị **coral nhạt** và % hiển thị màu coral; **Given** mức sử dụng từ 100% trở lên **Then** thanh tiến độ hiển thị **coral đậm** và % hiển thị màu coral.
5. **Given** người dùng bấm "+" **When** màn Thêm ngân sách mở **Then** app bar thương hiệu có nút quay lại + tiêu đề "Thêm ngân sách", không có thanh điều hướng đáy; "Theo danh mục" đang chọn, chu kỳ "Tháng" đang chọn, công tắc "Lặp lại tự động mỗi kỳ" đang bật, "Cộng dồn phần chưa dùng hết" đang tắt, "Ví áp dụng" = "Tất cả ví", "Ngưỡng cảnh báo" = "80% và 100%".
6. **Given** màn Thêm ngân sách đang mở **When** chưa chọn danh mục hoặc số tiền để trống/bằng 0 **Then** không lưu được, hệ thống báo rõ trường còn thiếu; **When** đã chọn danh mục và nhập số tiền > 0 rồi chạm "Lưu ngân sách" **Then** ngân sách được lưu và quay về màn Tổng quan với dữ liệu đã cập nhật.
7. **Given** danh mục "Ăn uống" đã có giao dịch Chi trong kỳ hiện tại **When** người dùng tạo ngân sách cho "Ăn uống" **Then** dòng ngân sách hiển thị đã chi bằng **tổng các giao dịch Chi đã có** trong kỳ (không phải 0), % và màu thanh tiến độ tính theo số đó.
8. **Given** đã có ngân sách cho "Ăn uống" chu kỳ Tháng **When** người dùng tạo thêm ngân sách cho "Ăn uống" chu kỳ Tháng có thời gian hiệu lực chồng lấn **Then** hệ thống **không lưu**, báo đã tồn tại ngân sách cho danh mục này và gợi ý sửa ngân sách đang có.
9. **Given** một ngân sách đang hiển thị ở màn Tổng quan **When** người dùng chạm vào dòng của nó **Then** màn Thêm ngân sách mở ở **chế độ sửa** với các giá trị hiện tại điền sẵn; sửa và lưu **Then** màn Tổng quan cập nhật theo giá trị mới.
10. **Given** chi tiêu của một danh mục chỉ tính giao dịch Chi **When** có giao dịch Thu hoặc chuyển khoản nội bộ thuộc danh mục đó trong kỳ **Then** các giao dịch này **không** được cộng vào đã chi của ngân sách.
11. **Given** ngân sách cho danh mục cha **When** phát sinh giao dịch Chi ở **danh mục con** của nó trong kỳ **Then** giao dịch đó **được cộng** vào đã chi của ngân sách danh mục cha.
12. **Given** màn Tổng quan đang ở tháng hiện tại **When** người dùng chạm mũi tên để xem tháng trước **Then** bộ chọn kỳ đổi sang tháng trước, thẻ tổng và danh sách tính lại theo đúng kỳ đó; chạm mũi tên còn lại quay về tháng hiện tại.
13. **Given** kỳ chưa có ngân sách nào **When** xem màn Tổng quan **Then** không hiện thẻ tổng rỗng hay danh sách trống trơ, mà hiện trạng thái rỗng có lời nhắc và nút "Thêm ngân sách" để bắt đầu.
14. **Given** ngân sách **không** bật "Lặp lại tự động mỗi kỳ" **When** kỳ của nó đã kết thúc **Then** ngân sách không tiếp tục sinh kỳ mới và màn Tổng quan thể hiện rõ trạng thái đã kết thúc (không tính vào thẻ tổng của kỳ đang xem).
15. **Given** app đang ở English (PBI 19) **When** mở 2 màn Ngân sách **Then** toàn bộ nhãn tĩnh (tiêu đề, nhãn nhóm, nút, chuỗi trạng thái rỗng, thông báo lỗi) hiển thị bằng tiếng Anh, không còn sót tiếng Việt.
16. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** người dùng xem 2 màn Ngân sách **Then** màn không vỡ bố cục, thẻ tổng và từng dòng ngân sách hiển thị đủ nội dung, cuộn tới được phần tử cuối.
17. **Given** người dùng có ngân sách chu kỳ **Tuần** cho "Cà phê" **When** xem màn Tổng quan **Then** dòng "Cà phê" hiển thị tiến độ của **tuần hiện tại** (kèm nhãn chu kỳ Tuần) và giữ nguyên khi người dùng đổi kỳ tháng đang xem; trong khi đó các dòng ngân sách chu kỳ **Tháng** tính lại theo tháng được chọn.
18. **Given** một ngân sách đã vượt giới hạn (VD 107%) **When** xem dòng của nó ở màn Tổng quan **Then** dòng chỉ hiển thị **% đã dùng** và thanh tiến độ coral, **không** hiển thị số tiền vượt (số tiền vượt thuộc màn Chi tiết ngân sách — PBI sau).

### Trường hợp biên

- Tạo ngân sách **giữa kỳ** → đã chi khởi tạo bằng tổng giao dịch Chi đã có từ đầu kỳ đến hiện tại, không phải 0.
- Sửa **số tiền giữa kỳ** → áp dụng ngay cho kỳ hiện tại; số liệu các kỳ trước đã qua không bị tính lại.
- Sửa **danh mục** của ngân sách → đã chi tính lại theo danh mục mới (kể cả danh mục con), và vẫn phải qua kiểm tra chồng lấn.
- Giao dịch Chi bị **sửa hoặc xóa** sau khi đã ghi nhận → dòng ngân sách và thẻ tổng cập nhật lại theo số mới (kể cả khi % giảm xuống).
- Danh mục của ngân sách **bị xóa** ở module Danh mục → màn Tổng quan thể hiện ngân sách ở trạng thái "không hợp lệ" kèm nhắc gán lại danh mục khác, không tự ý xóa ngân sách.
- Ngân sách chu kỳ **Tuần** hoặc **Năm** đang tồn tại → vẫn nằm trong danh sách ở màn Tổng quan, mỗi dòng hiển thị tiến độ **kỳ hiện tại của chính nó** (kèm nhãn chu kỳ) và **không** đổi theo bộ chọn kỳ tháng; ngân sách chu kỳ **Tháng** thì đổi theo kỳ đang chọn.
- Người dùng **không bật lặp lại** rồi mở lại app ở kỳ sau → ngân sách hiển thị "đã kết thúc", không sinh kỳ mới, không tính vào thẻ tổng.
- Chưa có danh mục Chi nào để chọn → màn Thêm ngân sách nhắc người dùng tạo danh mục trước, không cho lưu ngân sách.
- Số tiền giới hạn quá lớn hoặc nhập ký tự không phải số → ô nhập chỉ nhận số, hiển thị theo định dạng phân tách nghìn, không lưu giá trị không hợp lệ.
- Ví đang bị ẩn (module Ví) → không ảnh hưởng: đợt này ngân sách áp dụng cho **tất cả ví**.
- Nhiều ngân sách cùng danh mục nhưng **khác chu kỳ** (VD Tháng và Năm) → được phép tồn tại song song, hiển thị thành 2 dòng riêng, không coi là chồng lấn.

## Yêu cầu chức năng

- **FR-001**: Tab **Báo cáo** PHẢI có điểm vào **"Ngân sách"** dẫn tới màn **Tổng quan Ngân sách**; màn này mở theo đúng mockup `01` — app bar màu thương hiệu với tiêu đề "Ngân sách" và nút "+" ở góc phải, bộ chọn kỳ ở giữa, **thanh điều hướng đáy vẫn hiển thị với tab "Báo cáo" đang được chọn**.
- **FR-002**: Màn Tổng quan PHẢI có bộ chọn **kỳ đang xem** dạng "Tháng 9, 2026" kèm mũi tên chuyển kỳ trước/kỳ sau; mặc định là **kỳ hiện tại** chứa ngày hôm nay; đổi kỳ PHẢI tính lại thẻ tổng và danh sách theo đúng kỳ đó. Bộ chọn kỳ này điều khiển các ngân sách chu kỳ **Tháng**; ngân sách chu kỳ **Tuần** hoặc **Năm** PHẢI luôn hiển thị tiến độ **kỳ hiện tại của chính nó** kèm **nhãn chu kỳ** trên dòng và KHÔNG đổi theo kỳ tháng đang chọn.
- **FR-003**: Thẻ tổng PHẢI hiển thị nhãn "Tổng ngân sách tháng này", cặp số **tổng đã chi / tổng giới hạn**, **thanh tiến độ tổng**, dòng **"Còn lại … đ"** và dòng **số ngày còn lại** của kỳ đang xem; tổng PHẢI cộng dồn **các ngân sách đang hiển thị trong danh sách**.
- **FR-004**: Danh sách ngân sách PHẢI có tiêu đề nhóm **"DANH MỤC"** và liên kết **"Sao chép tháng trước"** ở bên phải; **mỗi dòng** gồm: icon của danh mục, tên danh mục, cặp số "đã chi / giới hạn", **% đã dùng** ở cuối dòng và **thanh tiến độ** bên dưới.
- **FR-005**: Quy tắc màu tiến độ PHẢI theo mockup `01`: **dưới 80%** → thanh và % màu **teal**; **từ 80% đến dưới 100%** → thanh màu **coral nhạt** (cùng tông coral, độ đậm giảm) và % màu coral; **từ 100% trở lên** → thanh **coral đậm** và % màu coral. Dòng ngân sách đã vượt giới hạn PHẢI thể hiện qua **% và màu coral**, KHÔNG hiển thị số tiền vượt ở màn Tổng quan (số tiền vượt thuộc màn Chi tiết ngân sách — PBI sau).
- **FR-006**: "Đã chi" của một ngân sách PHẢI là tổng các giao dịch **Chi** có `date` nằm trong kỳ đang xét và **khớp phạm vi danh mục** — khớp khi giao dịch thuộc **chính danh mục đó hoặc bất kỳ danh mục con** của nó. Giao dịch **Thu** và **chuyển khoản nội bộ** PHẢI bị loại trừ hoàn toàn.
- **FR-007**: Màn Tổng quan PHẢI hiển thị **đúng số đã chi tại thời điểm mở màn**, kể cả khi ngân sách được tạo **giữa kỳ** (đã chi tính từ đầu kỳ, KHÔNG bắt đầu từ 0) và kể cả khi giao dịch Chi phát sinh/sửa/xóa **sau** khi ngân sách đã tồn tại.
- **FR-008**: Nút **"+"** (và nút trong trạng thái rỗng) PHẢI mở màn **Thêm ngân sách** theo mockup `02`: app bar thương hiệu + nút quay lại + tiêu đề "Thêm ngân sách", KHÔNG có thanh điều hướng đáy.
- **FR-009**: Màn Thêm ngân sách PHẢI có nhóm **"Phạm vi ngân sách"** gồm 2 lựa chọn **"Theo danh mục"** và **"Tổng cộng"**, trong đó **"Theo danh mục"** được chọn sẵn và là lựa chọn duy nhất có hiệu lực trong đợt này.
- **FR-010**: Người dùng PHẢI chọn được **đúng một danh mục** cho ngân sách qua hàng "Danh mục" (mở danh sách chọn danh mục, hiển thị icon + tên danh mục đã chọn); danh mục là trường **bắt buộc**. Danh mục chọn được là **danh mục Chi** (cả danh mục cha lẫn danh mục con).
- **FR-011**: Người dùng PHẢI nhập được **số tiền giới hạn** — trường **bắt buộc**, chỉ nhận số, giá trị **lớn hơn 0**, hiển thị theo định dạng phân tách nghìn và đơn vị `đ` đặt sau (VD `3.000.000 đ`).
- **FR-012**: Màn Thêm ngân sách PHẢI cho chọn **chu kỳ** với đúng 3 lựa chọn **Tuần / Tháng / Năm**, chọn được **một** giá trị, mặc định là **Tháng**.
- **FR-013**: Màn Thêm ngân sách PHẢI có công tắc **"Lặp lại tự động mỗi kỳ"** (bật sẵn theo mockup `02`): khi **bật**, ngân sách tự tiếp tục ở kỳ kế tiếp với cùng giới hạn; khi **tắt**, ngân sách chỉ áp dụng cho kỳ hiện tại rồi **kết thúc**, không sinh kỳ mới.
- **FR-014**: Màn Thêm ngân sách PHẢI hiển thị đúng mockup `02` các hàng **"Ví áp dụng" = "Tất cả ví"**, **"Cộng dồn phần chưa dùng hết"** (đang tắt) và **"Ngưỡng cảnh báo" = "80% và 100%"**; các mục này **chưa có hiệu lực** trong đợt này.
- **FR-015**: Nút **"Lưu ngân sách"** PHẢI kiểm tra hợp lệ trước khi lưu: có danh mục, số tiền > 0, **không chồng lấn** với ngân sách hiện có. Khi thiếu/không hợp lệ → **không lưu**, hiển thị thông báo rõ trường cần sửa. Khi hợp lệ → lưu và **quay về màn Tổng quan với dữ liệu đã cập nhật**.
- **FR-016**: Hệ thống PHẢI **ngăn tạo 2 ngân sách cùng danh mục và cùng chu kỳ có thời gian hiệu lực chồng lấn nhau**; khi người dùng cố lưu, hệ thống báo đã tồn tại ngân sách cho danh mục này và gợi ý **sửa ngân sách đang có**. Ngân sách cùng danh mục nhưng **khác chu kỳ** được phép tồn tại song song.
- **FR-017**: Chạm vào một dòng ngân sách ở màn Tổng quan PHẢI mở màn Thêm ngân sách ở **chế độ sửa** (tiêu đề "Sửa ngân sách", điền sẵn giá trị hiện tại: danh mục, số tiền, chu kỳ, lặp lại); sau khi lưu, màn Tổng quan PHẢI cập nhật theo giá trị mới.
- **FR-018**: Việc **sửa ngân sách PHẢI chỉ áp dụng cho kỳ hiện tại**, KHÔNG hồi tố số liệu các kỳ đã qua; sửa danh mục PHẢI tính lại đã chi theo danh mục mới.
- **FR-019**: Khi kỳ đang xem **chưa có ngân sách nào**, màn Tổng quan PHẢI hiển thị **trạng thái rỗng** có lời nhắc và nút "Thêm ngân sách" thay vì thẻ tổng/danh sách rỗng trơ.
- **FR-020**: Ngân sách **không bật lặp lại** khi kỳ đã kết thúc PHẢI được thể hiện là **đã kết thúc** và KHÔNG tính vào thẻ tổng của kỳ đang xem; ngân sách **bật lặp lại** khi sang kỳ mới PHẢI tiếp tục được theo dõi với cùng giới hạn.
- **FR-021**: Ngân sách có danh mục **bị xóa** ở module Danh mục PHẢI hiển thị ở trạng thái **không hợp lệ** kèm nhắc gán lại danh mục khác; hệ thống KHÔNG tự xóa ngân sách.
- **FR-022**: Danh sách ngân sách ở màn Tổng quan PHẢI sắp xếp để người dùng thấy ngay mức độ căng thẳng: **giảm dần theo % đã dùng**.
- **FR-023**: Toàn bộ **nhãn giao diện tĩnh** của 2 màn mới (tiêu đề, nhãn nhóm, nút, chuỗi trạng thái rỗng, thông báo lỗi) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19), không sót tiếng Việt khi app ở English.
- **FR-024**: Cả 2 màn PHẢI hiển thị đúng thiết kế và **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; nội dung dài phải cuộn được tới phần tử cuối.

## Tiêu chí thành công

- **SC-001**: Từ tab Báo cáo, người dùng mở được màn Tổng quan Ngân sách trong **không quá 2 lần chạm**.
- **SC-002**: Đối chiếu trực quan với `man-hinh-01-tong-quan-ngan-sach.svg`: **100%** các thành phần (app bar, nút "+", bộ chọn kỳ, thẻ tổng, tiêu đề nhóm + liên kết "Sao chép tháng trước", cấu trúc từng dòng, thanh điều hướng đáy) hiển thị đúng vị trí và nội dung.
- **SC-003**: Đối chiếu trực quan với `man-hinh-02-them-ngan-sach.svg`: **100%** các thành phần (app bar + nút quay lại, nhóm phạm vi, hàng danh mục, ô số tiền, 3 lựa chọn chu kỳ, hàng ví áp dụng, 2 công tắc, hàng ngưỡng cảnh báo, nút lưu) hiển thị đúng vị trí và nội dung.
- **SC-004**: Người dùng hoàn tất việc tạo một ngân sách (từ lúc mở màn Thêm ngân sách đến khi lưu thành công) trong **dưới 60 giây** mà không cần hướng dẫn.
- **SC-005**: Với một kỳ có ngân sách, **100%** dòng ngân sách hiển thị đúng cặp "đã chi / giới hạn" và % đã dùng tính từ giao dịch Chi của kỳ đó; giao dịch Thu và chuyển khoản **không** làm thay đổi số đã chi (kiểm chứng bằng 0 sai lệch trên **100%** trường hợp thử).
- **SC-006**: Tạo ngân sách giữa kỳ cho danh mục đã có chi tiêu → số đã chi hiển thị **khớp** tổng chi tiêu thực tế của danh mục trong kỳ, sai lệch **0 đ** (không hiển thị 0).
- **SC-007**: **100%** lần cố tạo ngân sách trùng danh mục + trùng chu kỳ chồng thời gian đều bị chặn kèm thông báo rõ ràng; **100%** lần tạo ngân sách cùng danh mục khác chu kỳ đều thành công.
- **SC-008**: Màu thanh tiến độ đúng theo 3 dải ngưỡng ở **100%** số dòng hiển thị (kiểm chứng ở các mức sử dụng đại diện: 45%, 84%, 96%, 107%).
- **SC-009**: Thêm một giao dịch Chi thuộc danh mục có ngân sách rồi quay lại màn Tổng quan → dòng ngân sách và thẻ tổng phản ánh số mới ngay trong lần mở đó, **100%** trường hợp thử.
- **SC-010**: Sửa số tiền một ngân sách đang chạy → kỳ hiện tại dùng giá trị mới, và **không** kỳ nào đã qua bị thay đổi số liệu (kiểm chứng bằng so sánh trước/sau: 0 khác biệt).
- **SC-011**: Khi app ở English, **0** nhãn tĩnh tiếng Việt còn sót lại trên 2 màn Ngân sách.
- **SC-012**: Với cỡ chữ lớn nhất và màn hình nhỏ, 2 màn không vỡ bố cục, không cắt chữ, cuộn tới được phần tử cuối ở **100%** lần kiểm tra.
- **SC-013**: Với một ngân sách chu kỳ Tuần và một ngân sách chu kỳ Tháng cùng tồn tại, đổi kỳ tháng đang xem → **100%** lần, ngân sách Tháng tính lại theo tháng được chọn còn ngân sách Tuần giữ nguyên tiến độ tuần hiện tại và luôn hiển thị nhãn chu kỳ.
- **SC-014**: Thẻ tổng luôn khớp **100%** với tổng giới hạn và tổng đã chi của các ngân sách đang hiển thị trong danh sách (không lệch, không tính ngân sách đã kết thúc).

## Thực thể chính

- **Ngân sách**: giới hạn chi tiêu do người dùng đặt, gắn với **một danh mục** (cha hoặc con), gồm **số tiền giới hạn** và **chu kỳ** (Tuần/Tháng/Năm), cờ **lặp lại tự động mỗi kỳ**, ngày bắt đầu áp dụng và trạng thái (đang hoạt động / đã kết thúc / không hợp lệ). Một danh mục + một chu kỳ chỉ được có **một ngân sách hiệu lực tại một thời điểm** (không chồng lấn); cùng danh mục nhưng khác chu kỳ là hai ngân sách độc lập. Đợt này ngân sách áp dụng cho **tất cả ví**.
- **Kỳ ngân sách** (đại lượng **tính toán**, không phải dữ liệu người dùng nhập): khoảng thời gian cụ thể của một ngân sách (VD tháng 9/2026) với **số tiền giới hạn** của kỳ, **đã chi**, **còn lại**, **% đã dùng** và **số ngày còn lại**. Được tính lại từ dữ liệu giao dịch Chi mỗi khi có giao dịch Chi trong phạm vi thay đổi hoặc khi người dùng mở màn Tổng quan.
- **Danh mục áp dụng** (liên kết tới module Danh mục): danh mục Chi mà ngân sách giới hạn; giao dịch thuộc **danh mục này hoặc danh mục con** của nó đều tính vào ngân sách. Danh mục bị xóa làm ngân sách chuyển sang trạng thái không hợp lệ (không xóa ngân sách).

## Giả định

- **Chỉ ngân sách theo danh mục trong đợt này** (chia nhỏ **2a** của tài liệu nghiệp vụ): lựa chọn "Tổng cộng" ở màn Thêm ngân sách, hàng "Ví áp dụng", công tắc "Cộng dồn phần chưa dùng hết" và hàng "Ngưỡng cảnh báo" **hiển thị theo mockup nhưng chưa có hiệu lực** — theo nếp đã dùng ở các PBI trước (giữ đúng mockup, phần chưa làm thì chưa kích hoạt).
- **Chưa có cảnh báo đẩy (push notification)**: module Thông báo chưa được dựng (GĐ2), nên đợt này cảnh báo chỉ thể hiện bằng **màu sắc và % trên giao diện**, không có thông báo hệ thống.
- **Màu dải 80–99% = coral nhạt**: mockup `01` vẽ thanh tiến độ của dòng 84% và 96% bằng **coral với độ đậm giảm** và % màu coral — đây là cách hiện thực hóa gợi ý "coral nhạt (opacity)" trong tài liệu nghiệp vụ §6, giữ đúng hệ 2 màu teal/coral của Design System. (Điểm mở tương ứng trong wiki nay có câu trả lời từ mockup.)
- **Thứ tự danh sách giảm dần theo % đã dùng**: mockup `01` không thể hiện thứ tự rõ ràng; chọn giảm dần để ngân sách căng nhất lên đầu — nếu muốn giữ thứ tự tạo thì cần chốt lại.
- **Chu kỳ mặc định là Tháng, lặp lại mặc định bật, ngưỡng cảnh báo mặc định 80%/100%**: lấy đúng trạng thái hiển thị trong mockup `02` và mặc định trong tài liệu nghiệp vụ §3.1.
- **Ngân sách chỉ áp dụng cho tất cả ví**: `walletIds` để trống trong đợt này (ngân sách theo ví thuộc 2b).
- **Màn Chi tiết ngân sách (`man-hinh-03`) và sao chép ngân sách chưa thuộc PBI này**: màn Tổng quan vẫn hiển thị liên kết "Sao chép tháng trước" theo mockup nhưng chưa hoạt động; tương tự, chạm dòng ngân sách mở **chế độ sửa** của màn Thêm ngân sách (chưa có màn chi tiết).
- **Chưa có xóa/lưu trữ ngân sách trong đợt này** (tài liệu nghiệp vụ đặt thao tác này ở màn Chi tiết ngân sách): người dùng sửa được ngân sách nhưng chưa xóa/lưu trữ.
- **Không có cài đặt kỳ tài chính lệch ngày (`periodStartRule`) trong đợt này**: màn "Định dạng & Tiền tệ" (màn con `04` nhóm Tiện ích) chưa dựng, nên kỳ Tháng/Tuần/Năm tính theo **mốc mặc định** (tháng dương lịch, tuần theo đầu tuần chung của app).
- **Đa tiền tệ không phát sinh**: mọi ví đang dùng cùng tiền tệ mặc định; ngân sách không cho chọn tiền tệ khác (tài liệu nghiệp vụ §3.1).
- **Tên danh mục hiển thị theo ngôn ngữ đang chọn** với danh mục mặc định chưa đổi tên — kế thừa quy tắc PBI 19.

## Quyết định đã chốt

- **Phạm vi đợt này: màn Tổng quan Ngân sách (`01`) + màn Thêm/Sửa ngân sách (`02`)** — đủ vòng để dùng được (tạo ngân sách rồi thấy tiến độ). Màn Chi tiết ngân sách (`03`) để PBI sau. (chốt 2026-09-12)
- **Điểm vào: từ tab Báo cáo** — khớp mockup `01` (thanh điều hướng đáy đang chọn tab "Báo cáo"). (chốt 2026-09-12)
- **Chỉ ngân sách theo danh mục (2a)** — chưa có ngân sách tổng, ngân sách theo ví, cộng dồn, sao chép kỳ trước, cảnh báo đẩy. (chốt 2026-09-12)
- **Màu dải 80–99% dùng coral nhạt, không thêm màu thứ ba** — theo mockup `01`. (chốt 2026-09-12)
- **Ngân sách chu kỳ Tuần/Năm hiển thị tiến độ kỳ hiện tại của chính nó** (kèm nhãn chu kỳ), không đổi theo bộ chọn kỳ tháng; thẻ tổng cộng dồn các ngân sách đang hiển thị. (chốt 2026-09-12)
- **Màn Tổng quan chỉ hiển thị % đã dùng, không hiển thị số tiền vượt** — số tiền vượt để màn Chi tiết ngân sách (`03`) ở PBI sau; giữ đúng mockup `01`. (chốt 2026-09-12)

## Ngoài phạm vi

- Màn **Chi tiết ngân sách** (`man-hinh-03`): biểu đồ so sánh dự kiến vs thực tế, "tốc độ tiêu" dự đoán, danh sách giao dịch thuộc ngân sách, lưu trữ/xóa ngân sách.
- **Ngân sách tổng** (`scope = total`), **ngân sách theo ví** (`walletIds`), **cộng dồn phần chưa dùng hết** (`rolloverUnused`), tùy chỉnh **ngưỡng cảnh báo**.
- **Sao chép ngân sách kỳ trước** sang kỳ mới (link ở màn Tổng quan chỉ hiển thị, chưa hoạt động).
- **Cảnh báo đẩy / thông báo** gần–vượt ngân sách, badge trên app, tổng kết cuối kỳ (phụ thuộc module Thông báo — chưa dựng).
- **Xóa / lưu trữ ngân sách**, gộp hoặc di trú ngân sách khi danh mục bị gộp.
- **Kỳ tài chính lệch ngày** (`periodStartRule` — theo màn "Định dạng & Tiền tệ" chưa dựng) và **đa tiền tệ / quy đổi tỷ giá**.
- Nội dung cho tab **Báo cáo** (biểu đồ thu/chi, phân bổ danh mục, xuất báo cáo) — PBI 20 chỉ thêm điểm vào "Ngân sách" trong tab này.
- Hiệu ứng của công tắc **"Ẩn số dư"** (PBI 17) đối với số tiền ngân sách.
