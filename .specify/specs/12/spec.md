# Đặc tả tính năng: Tìm kiếm & lọc giao dịch

**Mã PBI**: 12
**Ngày tạo**: 2026-09-05
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Khi danh sách giao dịch dài dần, người dùng khó tìm một khoản đã ghi hoặc muốn xem nhanh dòng tiền theo tiêu chí (thu/chi, thời gian, danh mục, ví, biên độ số tiền). Tính năng này dựng luồng **"Tìm kiếm & Lọc"** theo thiết kế `docs/transaction/05-tim-kiem-loc.svg` — mở từ icon lọc ở màn "Giao dịch" (điểm vào đã dựng ở PBI 9). Màn con này là **form lọc**: ô tìm kiếm ngay trong app bar, chip lọc nhanh loại giao dịch (Tất cả/Thu/Chi/Chuyển khoản), các bộ lọc nâng cao (Khoảng thời gian, Danh mục, Ví, Khoảng số tiền, Sắp xếp theo) và dòng tóm tắt "N kết quả · Tổng: X đ" cho biết tập khớp bộ lọc. Khi người dùng chạm **"Áp dụng"**, màn đóng và **màn danh sách "Giao dịch" hiển thị tập giao dịch đã lọc** (kèm chỉ báo bộ lọc đang bật và số kết quả/tổng tiền); chạm **"Đặt lại"** đưa các điều kiện về mặc định. Mọi tiêu chí kết hợp đồng thời (phép AND). Tính năng chỉ **đọc và lọc** dữ liệu giao dịch đã có; không tạo, sửa hay xóa giao dịch.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng ở màn "Giao dịch" (PBI 9), chạm **icon lọc** trên app bar → mở màn con "Tìm kiếm & Lọc" theo `05`: app bar teal chứa sẵn **ô tìm kiếm** dạng pill (kính lúp, placeholder "Tìm kiếm giao dịch...") cùng nút quay lại; bên dưới là hàng **chip lọc nhanh** (Tất cả/Thu/Chi/Chuyển khoản), nhãn "BỘ LỌC NÂNG CAO", các dòng bộ lọc (Khoảng thời gian, Danh mục, Ví, Khoảng số tiền, Sắp xếp theo); chân màn có hai nút "Đặt lại" và "Áp dụng". Bộ lọc nạp sẵn mặc định: chip "Tất cả", **Khoảng thời gian = tháng hiện tại**, Ví "Tất cả các ví", sắp xếp "Ngày mới nhất".
2. Người dùng **gõ từ khóa** trong ô tìm kiếm → **dòng tóm tắt** "N kết quả · Tổng: X đ" cập nhật tức thời khi gõ (phản hồi ngay số lượng khớp ghi chú/tên danh mục/tag), không cần bấm nút.
3. Người dùng chạm **chip loại** (Thu / Chi / Chuyển khoản) → dòng tóm tắt chỉ tính các giao dịch đúng loại đó; chạm lại "Tất cả" để bỏ lọc loại.
4. Người dùng mở từng **bộ lọc nâng cao**: **Khoảng thời gian** (preset Hôm nay/Tuần này/Tháng này/Toàn bộ hoặc khoảng tùy chỉnh), **Danh mục** (chọn nhiều, hiện chip đã chọn trong dòng), **Ví** (một ví cụ thể hoặc tất cả), **Khoảng số tiền** (min–max), **Sắp xếp theo** (ngày mới/cũ nhất, số tiền tăng/giảm dần). Chúng dùng đồng thời với từ khóa và chip loại.
5. Người dùng chạm **"Áp dụng"** → màn con đóng, quay về màn "Giao dịch": danh sách hiển thị **đúng tập giao dịch khớp toàn bộ điều kiện** (kèm chỉ báo bộ lọc đang bật, số kết quả và tổng tiền ở đầu danh sách). Từ đây người dùng xem/cuộn, chạm một dòng để mở chi tiết (PBI 10), hoặc ghi giao dịch mới bằng FAB như bình thường.
6. Khi muốn xóa lọc, người dùng bỏ lọc qua chỉ báo trên màn "Giao dịch" (hoặc mở lại màn lọc và chọn preset "Toàn bộ"/bỏ điều kiện rồi Áp dụng) → danh sách về lại toàn bộ giao dịch.

### Kịch bản chấp nhận

1. **Given** người dùng đang ở màn "Giao dịch" **When** chạm icon lọc **Then** mở màn "Tìm kiếm & Lọc" đúng bố cục `05`: app bar teal có ô tìm kiếm pill + nút quay lại, chip "Tất cả" đang chọn, Khoảng thời gian hiển thị tháng hiện tại, Ví "Tất cả các ví", Sắp xếp "Ngày mới nhất", các dòng bộ lọc nâng cao còn lại và hai nút "Đặt lại"/"Áp dụng"; màn không có thanh điều hướng đáy.
2. **Given** thiết bị có giao dịch chi "Ăn uống – 85.000 đ – ghi chú 'Ăn trưa'" **When** gõ "ăn trưa" vào ô tìm kiếm **Then** dòng tóm tắt cập nhật tức thời về số kết quả khớp; không cần bấm nút.
3. **Given** người dùng chọn chip "Chi", khoảng số tiền "Từ 0 đ Đến 100.000 đ", đã gõ từ khóa "ăn" **When** xem dòng tóm tắt **Then** số kết quả và tổng chỉ tính các giao dịch thoả đồng thời: loại chi, tiền trong khoảng 0–100.000 đ, khớp từ khóa (các điều kiện kết hợp theo phép hội, không phải "hoặc").
4. **Given** có 12 giao dịch khớp toàn bộ bộ lọc, tổng các khoản chi = 1.240.000 đ **When** xem dòng tóm tắt **Then** hiển thị đúng "12 kết quả · Tổng: -1.240.000 đ" (thu tính dương, chi tính âm; con số đúng dữ liệu thực).
5. **Given** người dùng đã đặt các điều kiện lọc **When** chạm "Áp dụng" **Then** màn con đóng về màn "Giao dịch", danh sách chỉ còn các giao dịch khớp đúng bộ lọc, có chỉ báo bộ lọc đang bật kèm "N kết quả · Tổng: X đ".
6. **Given** màn "Giao dịch" đang hiển thị tập đã lọc **When** người dùng bỏ lọc (qua chỉ báo trên màn) **Then** danh sách về lại toàn bộ giao dịch như trước khi lọc.
7. **Given** người dùng đã thay đổi một số điều kiện **When** chạm "Đặt lại" **Then** từ khóa trống, chip về "Tất cả", Khoảng thời gian về tháng hiện tại, các bộ lọc khác về mặc định (Ví tất cả, số tiền trống, sắp xếp ngày mới nhất).
8. **Given** người dùng mở màn lọc, thay đổi điều kiện nhưng chưa "Áp dụng" **When** nhấn nút quay lại **Then** rời màn lọc, màn "Giao dịch" giữ nguyên tập đang hiển thị (không bị ảnh hưởng bởi thay đổi chưa áp dụng).
9. **Given** người dùng chọn danh mục cha "Ăn uống" **When** áp dụng **Then** danh sách gồm cả giao dịch của các danh mục con của "Ăn uống" (Cà phê, Ăn ngoài, Đi chợ).
10. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** mở màn tìm kiếm & lọc **Then** app bar, ô tìm kiếm, hàng chip, từng dòng bộ lọc, dòng tóm tắt và hai nút ở chân màn hiển thị đầy đủ, cuộn được, không vỡ hay tràn.

### Trường hợp biên

- Không có giao dịch nào khớp → dòng tóm tắt "0 kết quả"; sau khi Áp dụng, màn "Giao dịch" hiển thị trạng thái danh sách rỗng phù hợp với bộ lọc (có thể bỏ lọc để quay lại), không báo lỗi.
- Kết hợp nhiều bộ lọc dẫn đến 0 kết quả → không tác dụng phụ; dùng "Đặt lại" hoặc bớt điều kiện để mở rộng.
- Nhập từ khóa không khớp gì → "0 kết quả"; gõ liên tục/nhanh không treo, không giật.
- Khoảng số tiền: bỏ trống một đầu (không giới hạn đầu đó); nhập min > max → hệ thống ngăn hoặc coi là vô hiệu, không trả kết quả sai.
- Khoảng thời gian tùy chỉnh có ngày bắt đầu sau ngày kết thúc → picker ngăn tạo khoảng vô lý.
- Giao dịch thuộc ví đã ẩn / danh mục đã ẩn → vẫn xuất hiện trong tập lọc theo lịch sử (nhất quán PBI 9), trừ khi điều kiện lọc loại chúng ra.
- Giao dịch chuyển khoản và "điều chỉnh số dư" → xuất hiện khi khớp điều kiện nhưng không cộng vào tổng thu/chi của dòng tóm tắt (theo quy ước hiển thị của app).
- Số tiền rất lớn, chuỗi tìm kiếm dài → hiển thị đầy đủ đúng định dạng, không tràn vùng chứa.
- Khóa app đang có hiệu lực → màn lọc chỉ hiển thị sau khi mở khóa, không lộ số tiền qua màn hình khóa.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở màn "Tìm kiếm & Lọc" khi người dùng chạm icon lọc trên app bar của màn "Giao dịch" (PBI 9); màn là màn con theo đúng bố cục `docs/transaction/05-tim-kiem-loc.svg` — app bar thương hiệu chứa ô tìm kiếm và nút quay lại, KHÔNG có thanh điều hướng đáy.
- **FR-002**: Ô tìm kiếm PHẢI nằm trong app bar dạng pill (kính lúp, placeholder "Tìm kiếm giao dịch..."); từ khóa PHẢI so khớp trên nội dung **ghi chú**, **tên danh mục** và **tag** của giao dịch, không phân biệt chữ hoa/thường và không phân biệt dấu tiếng Việt ("an uong" tìm thấy "Ăn uống").
- **FR-003**: Dòng tóm tắt "N kết quả · Tổng: X đ" trong màn lọc PHẢI cập nhật **tức thời** khi người dùng gõ từ khóa hoặc đổi chip loại, thể hiện số lượng và tổng tiền của tập giao dịch sẽ khớp; không yêu cầu bấm nút.
- **FR-004**: Hệ thống PHẢI cung cấp hàng **chip lọc loại** cuộn ngang "Tất cả / Thu / Chi / Chuyển khoản", chip đang chọn tô màu thương hiệu, còn lại nền trắng viền; mặc định "Tất cả". Chọn một loại PHẢI chỉ giữ giao dịch thuộc loại đó trong tập khớp.
- **FR-005**: Hệ thống PHẢI cung cấp bộ lọc **Khoảng thời gian** với preset Hôm nay / Tuần này / Tháng này / Toàn bộ và khoảng **tùy chỉnh** (ngày bắt đầu–kết thúc); dòng bộ lọc PHẢI hiển thị khoảng đang chọn (ví dụ "01/09/2026 - 30/09/2026") và có nút mở để đổi; hệ thống PHẢI ngăn khoảng vô lý (bắt đầu sau kết thúc). **Mặc định là tháng hiện tại**.
- **FR-006**: Hệ thống PHẢI cung cấp bộ lọc **Danh mục** chọn nhiều (multi-select): dòng bộ lọc PHẢI hiển thị danh mục đã chọn dạng chip + ô "+ Thêm" để mở danh sách chọn. Chọn danh mục **cha** PHẢI tự tính gồm cả giao dịch của các danh mục con của nó; danh sách danh mục để chọn PHẢI phù hợp loại giao dịch đang lọc (đang chip "Chi" thì hiện danh mục chi).
- **FR-007**: Hệ thống PHẢI cung cấp bộ lọc **Ví**: mặc định "Tất cả các ví"; người dùng PHẢI chọn được một ví cụ thể để chỉ xem giao dịch của ví đó, nhất quán nguyên tắc "ẩn giữ lịch sử" (giao dịch ví ẩn vẫn đếm trong "Tất cả các ví").
- **FR-008**: Hệ thống PHẢI cung cấp bộ lọc **Khoảng số tiền** gồm ô "Từ … đ" và "Đến … đ" giới hạn biên độ số tiền (giá trị tuyệt đối, người dùng nhập số dương); PHẢI xử lý đúng khi bỏ trống một đầu và khi min > max (không trả kết quả sai, không lỗi).
- **FR-009**: Hệ thống PHẢI cung cấp **Sắp xếp theo**: Ngày mới nhất / Ngày cũ nhất / Số tiền tăng dần / Số tiền giảm dần; mặc định "Ngày mới nhất"; tập kết quả PHẢI được sắp xếp theo lựa chọn.
- **FR-010**: Hệ thống PHẢI áp dụng **đồng thời** mọi điều kiện đang chọn (từ khóa, chip loại, khoảng thời gian, danh mục, ví, khoảng số tiền) theo phép hội (AND) khi tạo tập kết quả.
- **FR-011**: Dòng tóm tắt PHẢI hiển thị tổng tiền theo quy ước màu/dấu của app: thu dương, chi âm; giao dịch chuyển khoản và điều chỉnh số dư PHẢI nằm trong số lượng kết quả nhưng KHÔNG cộng vào tổng thu/chi.
- **FR-012**: Khi người dùng chạm **"Áp dụng"**, hệ thống PHẢI đóng màn lọc và làm màn "Giao dịch" hiển thị đúng tập giao dịch khớp toàn bộ điều kiện — mỗi giao dịch xuất hiện đúng một lần, đúng sắp xếp đã chọn, dòng giao dịch giữ nguyên cấu trúc và màu thu/chi/chuyển khoản của màn danh sách; danh sách vẫn cuộn được, chạm dòng mở chi tiết và FAB ghi giao dịch mới hoạt động như bình thường.
- **FR-013**: Khi bộ lọc đang áp dụng, màn "Giao dịch" PHẢI hiển thị **chỉ báo bộ lọc đang bật** (kèm số kết quả và tổng tiền) và PHẢI cho người dùng **bỏ lọc** để đưa danh sách về toàn bộ giao dịch.
- **FR-014**: Nút **"Đặt lại"** PHẢI đưa mọi điều kiện về mặc định: từ khóa trống, chip "Tất cả", Khoảng thời gian = tháng hiện tại, Ví "Tất cả các ví", khoảng số tiền trống, sắp xếp "Ngày mới nhất".
- **FR-015**: Khi người dùng nhấn nút quay lại ở màn lọc mà chưa "Áp dụng" bộ lọc mới, màn "Giao dịch" PHẢI giữ nguyên tập đang hiển thị; mở lại màn lọc PHẢI hiện đúng các điều kiện của bộ lọc đang áp dụng (hoặc mặc định nếu chưa áp dụng lần nào).
- **FR-016**: Khi không có giao dịch nào khớp, hệ thống PHẢI thể hiện rõ trạng thái rỗng ("0 kết quả" ở màn lọc; trạng thái danh sách rỗng kèm gợi ý bỏ lọc ở màn "Giao dịch"), không xảy ra lỗi.
- **FR-017**: Màn lọc và danh sách đã lọc PHẢI hiển thị đầy đủ, cuộn được, không vỡ bố cục trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau (điện thoại).
- **FR-018**: Hai màn PHẢI chỉ hiển thị khi app đã được mở khóa; không được lộ số tiền qua màn hình khóa.

## Tiêu chí thành công

- **SC-001**: Từ màn "Giao dịch", mở màn lọc và đặt được một tổ hợp lọc (ví dụ Chi + danh mục + khoảng tiền) rồi Áp dụng trong chưa đầy 30 giây với người dùng đã quen.
- **SC-002**: Với bộ dữ liệu mẫu, danh sách sau "Áp dụng" và dòng tóm tắt đối chiếu khớp 100% với lọc thủ công theo từng tiêu chí và theo tổ hợp nhiều tiêu chí (không thừa, không thiếu giao dịch).
- **SC-003**: Dòng tóm tắt cập nhật ngay khi gõ từ khóa (không cần nút); gõ tìm không làm app treo/giật trên bộ dữ liệu tới vài nghìn giao dịch.
- **SC-004**: Tìm kiếm không phân biệt hoa/thường và dấu tiếng Việt cho đúng kết quả người dùng mong đợi.
- **SC-005**: Các preset Hôm nay/Tuần này/Tháng này/Toàn bộ và khoảng tùy chỉnh lấy đúng mốc thời gian: đủ giao dịch trong khoảng, loại đúng giao dịch ngoài khoảng.
- **SC-006**: Chạm "Đặt lại" đưa toàn bộ màn lọc về trạng thái mặc định (chip Tất cả, tháng hiện tại, ...), không cần thao tác thêm.
- **SC-007**: Bộ lọc còn hiệu lực đúng qua các lần ra/vào màn "Giao dịch" và mở lại màn lọc (điều kiện không bị mất hoặc nhân đôi); bỏ lọc đưa danh sách về đúng trạng thái ban đầu.
- **SC-008**: Chọn danh mục cha hiển thị đúng tập gồm cả danh mục con; chọn danh mục con chỉ lấy đúng danh mục đó (không lẫn nhánh khác).
- **SC-009**: Đối chiếu trực quan với `05-tim-kiem-loc.svg`: app bar + ô tìm kiếm pill, hàng chip, nhãn "BỘ LỌC NÂNG CAO", từng dòng bộ lọc (giá trị + chevron), dòng tóm tắt và hai nút "Đặt lại"/"Áp dụng" hiển thị đúng vị trí, đúng màu thương hiệu cho trạng thái chọn, đúng định dạng tiền tệ khi dữ liệu đầu vào tương ứng.
- **SC-010**: Mọi tổ hợp lọc không bao giờ làm lộ giao dịch không khớp, không tạo giao dịch trùng, không mất/sửa bất kỳ giao dịch nào trong dữ liệu (tính năng chỉ đọc).
- **SC-011**: Với cỡ chữ lớn nhất và vùng an toàn khác nhau, màn lọc hiển thị đầy đủ, cuộn được, không vỡ bố cục hay cắt mất nút "Đặt lại"/"Áp dụng".

## Thực thể chính

- **Giao dịch (transaction)**: dữ liệu nguồn được tìm kiếm/lọc/hiển thị. Gồm loại (thu / chi / chuyển khoản / điều chỉnh), số tiền, ngày giờ, ví chứa, danh mục (với thu/chi) hoặc cặp ví nguồn–đích (với chuyển khoản), ghi chú và tag. Tính năng này chỉ đọc giao dịch.
- **Danh mục (category)**: tiêu chí lọc — cung cấp tên (so khớp từ khóa) và cây danh mục cha-con để chọn nhiều (chọn cha gộp các con).
- **Ví (wallet)**: tiêu chí lọc — chọn một ví hoặc để "Tất cả các ví".

## Giả định

- Điểm vào là icon lọc trên màn "Giao dịch" (PBI 9); màn `05` là màn con form lọc, không có bottom nav (nhất quán màn con khác như chi tiết giao dịch PBI 10). Danh sách kết quả đầy đủ hiển thị ngay trên màn "Giao dịch" sau khi "Áp dụng" (đã chốt).
- Mặc định bộ lọc khi mở màn = tháng hiện tại cho Khoảng thời gian (đúng mockup `05`), chip "Tất cả", Ví "Tất cả", khoảng tiền trống, sắp xếp "Ngày mới nhất" (đã chốt). Có preset "Toàn bộ" để lọc không giới hạn thời gian.
- "Áp dụng" ghi nhận toàn bộ điều kiện và đưa về màn "Giao dịch" hiển thị tập đã lọc; chỉ báo bộ lọc trên màn "Giao dịch" cho phép bỏ lọc về toàn bộ (đã chốt). Dòng tóm tắt trong màn lọc đóng vai trò phản hồi tức thời cho tìm kiếm/chip (FR-003).
- Chọn danh mục cha trong lọc tự gộp giao dịch của các danh mục con (đã chốt). Danh mục hiển thị để chọn trong lọc thích ứng loại giao dịch đang chọn (chip Thu → danh mục thu, chip Chi → danh mục chi).
- "Tổng" trong dòng tóm tắt: thu dương, chi âm; chuyển khoản và điều chỉnh số dư có trong số lượng kết quả nhưng không cộng vào tổng. Các con số mockup chỉ minh họa; dữ liệu lấy trực tiếp từ thiết bị.
- Khoảng số tiền lọc theo biên độ giá trị tuyệt đối (chi 85.000 đ thuộc khoảng "0–100.000 đ"); người dùng nhập số dương không dấu.
- Giao dịch ví ẩn/danh mục ẩn vẫn trong tập lọc "Tất cả" (giữ lịch sử, nhất quán PBI 9).
- Tìm kiếm tức thời có độ trễ nhỏ khi gõ (debounce) để tránh giật trên dữ liệu lớn — hành vi kỹ thuật; người dùng chỉ thấy "tóm tắt cập nhật khi gõ".
- App dùng chủ yếu chiều dọc trên điện thoại, giao diện tiếng Việt; tablet/đa ngôn ngữ chưa phải mục tiêu đợt này.

## Quyết định đã chốt

- **Màn `05` là form lọc; "Áp dụng" đưa về màn "Giao dịch" hiển thị tập đã lọc** — danh sách kết quả đầy đủ (cuộn được, có bottom nav/FAB, chạm dòng mở chi tiết) nằm trên màn "Giao dịch", không dựng danh sách thứ hai ngay trong `05`. Màn `05` có dòng tóm tắt "N kết quả · Tổng" làm phản hồi tức thời. Màn "Giao dịch" khi đang lọc hiển thị chỉ báo bộ lọc + cách bỏ lọc.
- **Mặc định Khoảng thời gian = tháng hiện tại** (đúng mockup `05`); có preset "Toàn bộ" cho lọc không giới hạn; "Đặt lại" về mặc định này, "bỏ lọc" trên màn Giao dịch đưa danh sách về toàn bộ.
- **Chọn danh mục cha tự gộp giao dịch của danh mục con** — người dùng chọn "Ăn uống" để xem mọi chi tiêu ăn uống mà không cần liệt kê từng con.

## Ngoài phạm vi

- Lưu bộ lọc thành mục yêu thích/tái sử dụng; ghim bộ lọc lên màn danh sách.
- Báo cáo/thống kê đồ thị từ tập kết quả (thuộc module Báo cáo).
- Quản lý danh mục (tạo/sửa/ẩn) ngay trong bộ lọc — chỉ chọn từ danh mục có sẵn.
- Đa tiền tệ/quy đổi, dark mode, chế độ riêng tư che số tiền.
- Tìm kiếm gợi ý/tự sửa lỗi chính tả; import/OCR; giao dịch định kỳ; lọc "đã đồng bộ"/trạng thái nguồn gốc khác.
