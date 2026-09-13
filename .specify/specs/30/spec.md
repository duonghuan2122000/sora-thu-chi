# Đặc tả tính năng: Trung tâm thông báo trong app (màn `03`)

**Mã PBI**: 30
**Ngày tạo**: 2026-09-13
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Doc nghiệp vụ thông báo (`docs/notification/notification-solution.md` §1, §3.2) chốt app có **2 tầng**: **Notification Engine** (tính toán + bắn thông báo) và **Notification Center** — "hộp thư thông báo" trong app, lưu lại lịch sử để người dùng **xem lại được kể cả khi bỏ lỡ hoặc đã tắt thông báo hệ thống**. PBI 28/29 đã dựng xong 2 màn cấu hình (`01`, `02`); **tầng Trung tâm chưa có gì**.

PBI này dựng **màn Trung tâm thông báo** theo mockup `docs/notification/03-trung-tam-thong-bao.svg`: trang con với app bar màu thương hiệu (nút back, tiêu đề "Thông báo", icon bánh răng mở màn cấu hình thông báo), **2 tab lọc "Tất cả" / "Chưa đọc"**, danh sách thông báo **nhóm theo thời gian** (HÔM NAY / TUẦN NÀY / …), **chấm teal đánh dấu chưa đọc**, icon tròn theo loại (chuông / cảnh báo coral / lịch / bullseye / biểu đồ tròn), **chạm một mục → đánh dấu đã đọc và mở màn hình liên quan**.

Nguyên tắc nền: **lịch sử thông báo thuộc về người dùng, nằm hoàn toàn trên thiết bị** — không có server, không đồng bộ; người dùng **tắt hết thông báo hệ thống vẫn xem lại được lịch sử**; và màn này **không bao giờ** chặn hay làm hỏng việc ghi chép thu chi.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Mở Trung tâm và xử lý một thông báo

1. Người dùng ở màn **Tổng quan** → chạm **biểu tượng chuông** ở vùng tiêu đề (đang có **chấm đỏ** vì còn thông báo chưa đọc) → màn **Thông báo** mở ra theo mockup `03`: app bar màu thương hiệu có **nút back**, tiêu đề **"Thông báo"**, và **icon bánh răng** ở góc phải.
2. Màn hiện 2 tab lọc **"Tất cả"** (đang chọn, có gạch chân màu thương hiệu) và **"Chưa đọc"**; danh sách bên dưới **nhóm theo thời gian** với nhãn viết hoa mờ: **HÔM NAY**, **TUẦN NÀY**, (và các nhóm cũ hơn nếu có).
3. Mỗi mục gồm: **chấm teal** bên trái (chỉ có khi **chưa đọc**), **icon tròn nền nhạt** theo loại thông báo, **tiêu đề đậm** + **1–2 dòng mô tả kèm số liệu cụ thể**, và **nhãn thời gian** ở góc phải.
4. Người dùng chạm mục **"Sắp vượt ngân sách Ăn uống"** (đang chưa đọc) → mục **mất chấm teal**, tiêu đề chuyển sang sắc mờ (đã đọc), **và** app mở màn **Chi tiết ngân sách** của danh mục Ăn uống.
5. Người dùng bấm **back** từ màn Chi tiết ngân sách → quay lại **Trung tâm thông báo**; mục vừa chạm **vẫn ở trạng thái đã đọc**.
6. Người dùng chuyển sang tab **"Chưa đọc"** → danh sách chỉ còn các mục chưa đọc, **giữ nguyên cách nhóm theo thời gian**; các mục đã đọc biến mất khỏi danh sách này (nhưng vẫn còn ở tab "Tất cả").
7. Người dùng chạm **icon bánh răng** → mở màn **Thông báo & nhắc nhở** (PBI 28).

### Luồng phụ — Chưa có thông báo nào

1. Người dùng mở Trung tâm khi lịch sử **rỗng** → màn hiển thị **trạng thái rỗng**: một hình/biểu tượng trung tính, dòng chính **"Chưa có thông báo nào"** và dòng phụ giải thích ngắn (thông báo sẽ xuất hiện ở đây); **không** có danh sách, **không** nhãn nhóm thời gian, **không** lỗi, **không** nút "sắp có".
2. Tab **"Chưa đọc"** khi **mọi mục đều đã đọc** → trạng thái rỗng riêng cho tab ("Không có thông báo chưa đọc"), **không** dùng lại câu của trạng thái rỗng chung.

## Yêu cầu chức năng

- **FR-001**: Màn **Tổng quan** PHẢI có **biểu tượng chuông** ở vùng tiêu đề (ô nút tròn, vùng chạm đủ lớn), mở màn Trung tâm thông báo bằng **đúng 1 lần chạm**; biểu tượng PHẢI **luôn bấm được**, kể cả khi chưa có thông báo nào. Chuông PHẢI hiển thị **chấm đỏ** khi còn **ít nhất một** mục chưa đọc, và **không** hiển thị chấm khi mọi mục đã đọc (hoặc lịch sử rỗng); chấm PHẢI biến mất **ngay** sau khi mục chưa đọc cuối cùng được đọc. [Q2 chọn A]
- **FR-002**: Màn Trung tâm PHẢI là **trang con** theo mockup `03`: app bar **màu thương hiệu** có **nút back**, tiêu đề **"Thông báo"**, và **icon bánh răng** mở màn **Thông báo & nhắc nhở**; **không** có thanh điều hướng đáy và **không** có nút thêm giao dịch.
- **FR-003**: Màn PHẢI có **2 tab lọc** — **"Tất cả"** và **"Chưa đọc"** — với tab đang chọn được đánh dấu rõ (chữ + gạch chân màu thương hiệu); đổi tab PHẢI **lọc lại danh sách ngay**, không tải lại màn.
- **FR-004**: Danh sách PHẢI **nhóm theo thời gian** với nhãn nhóm viết hoa mờ phân biệt được với tiêu đề mục; tối thiểu có nhóm **HÔM NAY** và **TUẦN NÀY**, và PHẢI có nhóm cho các mục **cũ hơn** (thứ tự mới nhất trước).
- **FR-005**: Mỗi mục PHẢI gồm: **chấm teal** (chỉ khi chưa đọc), **icon tròn nền nhạt theo loại thông báo**, **tiêu đề**, **dòng mô tả**, **nhãn thời gian**. **Mục chưa đọc** PHẢI phân biệt được với **mục đã đọc** bằng cả **chấm** lẫn **độ đậm/màu chữ** (không chỉ dựa vào màu đơn thuần).
- **FR-006**: **Icon theo loại** PHẢI đúng mockup: nhắc nhập giao dịch → **chuông** (teal); cảnh báo/vượt ngân sách → **cảnh báo** (**coral** — ngữ cảnh cảnh báo chi tiêu); nhắc đến hạn định kỳ → **lịch** (teal); nhắc mục tiêu tiết kiệm → **bullseye** (teal); tổng kết kỳ → **biểu đồ tròn** (teal).
- **FR-007**: **Chạm một mục** PHẢI: (a) đánh dấu mục đó **đã đọc** nếu đang chưa đọc, và (b) **điều hướng tới màn hình liên quan** của loại thông báo đó. Nhãn thời gian và các mục khác PHẢI giữ nguyên.
- **FR-008**: **Đích điều hướng** theo loại PHẢI là: nhắc nhập giao dịch → **màn Thêm giao dịch**; cảnh báo ngân sách → **màn Chi tiết ngân sách** của đúng danh mục; tổng kết kỳ → **màn Báo cáo**; nhắc đến hạn định kỳ → màn chi tiết khoản định kỳ; nhắc mục tiêu → màn chi tiết mục tiêu. Loại nào **chưa có màn đích** trong app thì chạm chỉ **đánh dấu đã đọc**, **không** điều hướng và **không** báo lỗi/khung "sắp có".
- **FR-009**: Trạng thái **đã đọc / chưa đọc** PHẢI được **lưu bền trên thiết bị** và khôi phục đúng sau khi đóng/mở lại app hay khởi động lại thiết bị; **một mục chỉ chuyển một chiều** chưa đọc → đã đọc, **không** tự quay lại chưa đọc.
- **FR-010**: Lịch sử thông báo (tiêu đề, nội dung, loại, thời điểm, liên kết tới đối tượng liên quan, trạng thái đã đọc) PHẢI được **lưu bền trên thiết bị** và vẫn còn **sau khi app bị đóng hoặc thiết bị khởi động lại**. Lịch sử PHẢI **giữ tối đa 200 mục gần nhất** theo thời điểm phát sinh; khi vượt trần, các mục **cũ nhất bị dọn tự động** (không hỏi, không báo) và số mục lưu **không bao giờ vượt 200**. [Q3 chọn A]
- **FR-019**: Màn Trung tâm **KHÔNG** có nút/thao tác **"đánh dấu tất cả đã đọc"**, **KHÔNG** có thao tác xoá một mục hay xoá cả lịch sử — cách duy nhất để chuyển sang đã đọc là **chạm vào mục** (FR-007). [Q2 chọn A]
- **FR-011**: Ở **trạng thái rỗng**, màn PHẢI hiển thị hình/biểu tượng trung tính + dòng chính + dòng phụ giải thích ngắn; tab **"Chưa đọc"** rỗng PHẢI có **thông điệp riêng**, không dùng lại câu của trạng thái rỗng chung; **KHÔNG** hiển thị nhãn nhóm thời gian khi nhóm không có mục nào.
- **FR-012**: Màn PHẢI **chỉ đọc và cập nhật trạng thái đã đọc** của lịch sử thông báo — **KHÔNG** được tạo, sửa hay xoá **bất kỳ** dữ liệu nghiệp vụ nào (giao dịch, ví, danh mục, ngân sách, báo cáo), **KHÔNG** đổi cấu hình thông báo của màn `01`/`02`.
- **FR-013**: Màn PHẢI **không** xin quyền thông báo hệ thống, **không** bắn thông báo nào, và hiển thị **giống nhau** dù quyền thông báo của hệ điều hành được cấp hay bị chặn.
- **FR-014**: Mọi **nhãn tĩnh** của màn (tiêu đề app bar, 2 nhãn tab, các nhãn nhóm thời gian, câu trạng thái rỗng, nhãn trợ năng của chuông) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19); **nội dung thông báo đã lưu** (tiêu đề/dòng mô tả do hệ thống sinh ở thời điểm bắn) PHẢI giữ **nguyên văn như lúc lưu**, **không** dịch lại khi đổi ngôn ngữ; giờ và định dạng ngày/số KHÔNG đổi theo ngôn ngữ.
- **FR-015**: Màn PHẢI hiển thị đúng bộ màu của **chế độ Sáng/Tối** đang chọn (PBI 18) — nền, chữ, nhãn nhóm, icon, chấm chưa đọc, đường phân cách — đảm bảo đủ tương phản; **sắc coral chỉ** dùng cho ngữ cảnh cảnh báo chi tiêu/ngân sách.
- **FR-016**: Màn PHẢI **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; **tiêu đề và dòng mô tả dài** PHẢI xuống dòng gọn, **không** đè lên icon hay nhãn thời gian; danh sách PHẢI **cuộn được** tới mục cuối.
- **FR-017**: Màn PHẢI **không** làm chậm hay chặn luồng chính: mở màn và đổi tab PHẢI phản hồi tức thì kể cả khi lịch sử có **nhiều mục**.
- **FR-018**: Màn PHẢI hoạt động **đầy đủ khi không có mạng** — không có phần tử nào phụ thuộc server hay đồng bộ.

## Tiêu chí thành công

- **SC-001**: Đối chiếu trực quan với `03-trung-tam-thong-bao.svg`: **100%** thành phần (app bar teal + back + tiêu đề + bánh răng, 2 tab, nhãn nhóm thời gian, mục có chấm/icon/tiêu đề/mô tả/nhãn thời gian, phân biệt đọc–chưa đọc) hiển thị đúng vị trí, đúng màu ngữ nghĩa (coral **chỉ** ở loại cảnh báo ngân sách).
- **SC-002**: Từ màn Tổng quan, người dùng tới được Trung tâm bằng **đúng 1 lần chạm**; từ Trung tâm tới màn cấu hình thông báo bằng **đúng 1 lần chạm**; quay lại bằng **1 lần chạm**.
- **SC-003**: Sau khi mở app lại và khởi động lại thiết bị, **100%** trạng thái đã đọc được giữ đúng (**0** mục tự quay về chưa đọc, **0** mục đã đọc bị mất).
- **SC-004**: **0** mục nào bị mất khỏi lịch sử sau khi đóng/mở lại app (đối chiếu số mục trước và sau).
- **SC-005**: Tab **"Chưa đọc"** hiển thị **đúng** tập mục chưa đọc và **không** hiển thị mục đã đọc nào — kiểm chứng bằng cách đọc lần lượt từng mục và đối chiếu (0 sai lệch).
- **SC-006**: Chạm một mục: **100%** trường hợp mục đó chuyển sang đã đọc **và** mở đúng màn hình liên quan; các mục khác **0** thay đổi.
- **SC-007**: Khi lịch sử rỗng, màn hiển thị trạng thái rỗng **đúng câu, không nhãn nhóm, không lỗi**; tab "Chưa đọc" rỗng hiển thị **câu riêng** (0 lần dùng nhầm câu của trạng thái rỗng chung).
- **SC-008**: Sau khi dùng màn: **0** thay đổi về số bản ghi giao dịch/ví/danh mục/ngân sách, và **0** thay đổi cấu hình thông báo của màn `01`/`02`.
- **SC-009**: Dùng màn trong ngày: **0** thông báo được bắn ra, **0** lần app hỏi quyền thông báo.
- **SC-010**: Ở **English**, **0** nhãn tĩnh tiếng Việt còn sót; nội dung thông báo đã lưu hiển thị **nguyên văn** như lúc lưu (**0** mục bị dịch lại). Ở **chế độ Tối**, **100%** chữ và phần tử đạt tương phản đọc được.
- **SC-011**: Với **cỡ chữ lớn nhất** và **màn hình nhỏ**, màn không vỡ bố cục, không cắt chữ, không đè icon/nhãn thời gian, và cuộn tới được mục cuối ở **100%** lần kiểm tra.
- **SC-012**: Với lịch sử nhiều mục, thao tác mở màn và đổi tab hoàn tất **dưới 1 giây**, không khựng.
- **SC-013**: Chấm đỏ trên chuông phản ánh **đúng** trạng thái: **0** lần hiển thị chấm khi mọi mục đã đọc, **0** lần mất chấm khi vẫn còn mục chưa đọc, và chấm mất **ngay** sau thao tác đọc mục cuối.
- **SC-014**: Sau khi lịch sử vượt **200** mục: số mục xem được **≤ 200**, và **200** mục còn lại là **mới nhất** (0 mục cũ hơn chen vào, 0 mục mới bị dọn).

## Thực thể chính

- **Bản ghi thông báo (lịch sử)** — một bản ghi cho mỗi thông báo đã phát sinh, lưu bền trên thiết bị: **loại thông báo** (nhắc nhập giao dịch / cảnh báo ngân sách / nhắc đến hạn định kỳ / nhắc mục tiêu tiết kiệm / tổng kết kỳ), **tiêu đề**, **nội dung** (kèm số liệu cụ thể), **thời điểm phát sinh**, **trạng thái đã đọc** (kèm thời điểm đọc), và **liên kết tới đối tượng liên quan** (danh mục ngân sách / khoản định kỳ / mục tiêu / kỳ báo cáo) để điều hướng khi chạm.
- **Quan hệ**: mỗi bản ghi tham chiếu tới **đúng một** đối tượng nghiệp vụ đã có (hoặc tới một kỳ báo cáo); bản ghi **không** sở hữu và **không** sửa được đối tượng đó — xoá/ẩn đối tượng nghiệp vụ **không** làm mất lịch sử thông báo.

## Giả định

- **PBI này dựng tầng Trung tâm (UI + lịch sử + trạng thái đã đọc); tầng Notification Engine vẫn chưa thuộc đợt này** (Q1 chọn A) — đồng bộ với quyết định Q1 của PBI 28 (engine là PBI sau). Hệ quả: trong đợt này **chưa có gì ghi vào lịch sử**, nên màn sẽ ở **trạng thái rỗng** cho tới khi engine ra đời; PBI này bàn giao **đúng điểm nối** để engine ghi lịch sử + đẩy màn cập nhật.
- **Màn vẫn được dựng đầy đủ và kiểm thử được** dù lịch sử rỗng: các kịch bản đọc/chưa đọc, lọc tab, nhóm thời gian và điều hướng được kiểm chứng bằng dữ liệu lịch sử có sẵn trên thiết bị (kể cả dữ liệu do QA tạo), **không** dựng cơ chế seed dữ liệu mẫu trong app.
- **Điểm vào là biểu tượng chuông ở vùng tiêu đề màn Tổng quan** (ô `trailing` của `ScreenHeader`) — doc nghiệp vụ §5 chốt "biểu tượng chuông ở màn hình Tổng quan"; mockup `03` không vẽ màn Tổng quan nên vị trí lấy theo tiền lệ các icon vùng tiêu đề của màn Báo cáo (PBI 26/27).
- **Icon bánh răng ở app bar màn Trung tâm mở màn "Thông báo & nhắc nhở" (PBI 28)** — mockup `03` vẽ bánh răng ở góc phải; đây là lối tắt hợp lý thay vì mở màn cài đặt chung.
- **Nhãn thời gian dùng giờ `HH:mm` cho mục trong ngày**, **tên thứ** cho mục trong tuần này, **ngày/tháng** cho mục cũ hơn. *Lệch mockup có chủ ý*: mockup vẽ một mục trong ngày là "2 giờ trước" (tương đối) trong khi các mục khác là giờ tuyệt đối — chốt dùng **giờ tuyệt đối đồng nhất** cho dễ đọc và dễ kiểm thử.
- **Nhóm thời gian**: HÔM NAY (cùng ngày), TUẦN NÀY (7 ngày gần nhất, không tính hôm nay), và **TRƯỚC ĐÓ** cho phần còn lại — mockup chỉ vẽ 2 nhóm đầu, nhóm thứ ba là mở rộng bắt buộc để lịch sử cũ vẫn xem được.
- **Chạm mục là hành vi duy nhất để đánh dấu đã đọc** (Q2 chọn A); màn **không** có nút "đánh dấu tất cả đã đọc" và **không** có thao tác xoá một mục hay xoá cả lịch sử — mockup không vẽ và doc nghiệp vụ không yêu cầu.
- **Trạng thái đã đọc là một chiều** (chưa đọc → đã đọc) và gắn với **bản ghi lịch sử**, không phải với **loại** thông báo: hai thông báo cùng loại có trạng thái đọc độc lập.
- **Múi giờ dùng theo thiết bị**, cả khi ghi thời điểm phát sinh lẫn khi tính nhóm thời gian; mốc "tuần này" bắt đầu **Thứ Hai** (đồng bộ module Báo cáo).
- **Nội dung thông báo đã lưu là ảnh chụp tại thời điểm phát sinh** — không tính lại số liệu khi mở màn (VD cảnh báo "đã dùng 82%" vẫn ghi 82% dù sau đó đã chi thêm).
- **Loại thông báo "chưa có màn đích"** (nhắc đến hạn định kỳ, nhắc mục tiêu — hai module chưa tồn tại) vẫn **hiển thị bình thường** trong lịch sử nếu có bản ghi; chạm chỉ đánh dấu đã đọc, **không** điều hướng, không lỗi — đồng bộ tiền lệ PBI 28 Q3 (không ghi "sắp có", không vô hiệu hoá).
- **Khoá app (PIN) không ảnh hưởng màn này**: màn chỉ mở được sau khi đã mở khóa app (PBI 3).
- **Trần lưu 200 mục** (Q3 chọn A) áp dụng **theo thời điểm phát sinh, bất kể đã đọc hay chưa** — không có ngoại lệ "giữ mục chưa đọc"; con số 200 là hằng số đặt trước, **không** phải cấu hình người dùng chỉnh.
- **Không có đồng bộ/tài khoản**: lịch sử chỉ nằm trên thiết bị này, **không** đi kèm backup/restore JSON (GĐ3).

## Ngoài phạm vi

- **Toàn bộ Notification Engine** (đồng bộ PBI 28 Q1 chọn A — PBI sau): tính toán điều kiện cho 5 loại thông báo, lên lịch theo giờ cố định, bắn cảnh báo ngay sau khi lưu giao dịch chi tiêu vượt ngưỡng, cơ chế chống bắn trùng theo tần suất tối đa, quy tắc "không bắn khi đang ở đúng màn liên quan", **nội dung thông báo kèm số liệu**.
- **Thông báo đẩy của hệ điều hành** (mẫu ở mockup `04`) và **mọi thứ liên quan tới quyền thông báo**: xin quyền (kể cả soft-ask onboarding), cảnh báo khi bị chặn quyền, notification channel riêng theo loại trên Android, hướng dẫn autostart cho máy bị tối ưu pin, **deep link từ thông báo hệ thống vào app**.
- **Việc ghi lịch sử khi một loại thông báo được kích hoạt** — đợt này chỉ định nghĩa cấu trúc lịch sử + màn đọc nó; **nguồn ghi** do engine cung cấp ở PBI sau.
- **Màn `04` mẫu thông báo đẩy** — chỉ là hình minh hoạ, không phải màn hình cần dựng.
- **Chỉnh cấu hình thông báo từ trong màn này**: màn `03` chỉ có lối tắt (bánh răng) sang màn cấu hình; **không** nhúng công tắc/tham số cấu hình vào danh sách thông báo.
- **Xoá lịch sử thông báo, đánh dấu tất cả đã đọc, ghim/ưu tiên thông báo, tìm kiếm trong lịch sử, xem chi tiết một thông báo ở màn riêng** — doc nghiệp vụ và mockup không yêu cầu.
- **Widget màn hình chính hiển thị thông báo** (quyết định mở #6 của dự án).
- **Ghi nhớ lịch sử thông báo vào file backup/restore JSON** (GĐ3).

## Quyết định đã chốt

- **Q1 — chọn A: đợt này chỉ dựng Trung tâm thông báo** (màn `03` + lưu lịch sử + trạng thái đã đọc + điều hướng), **chưa làm engine sinh thông báo** — engine (lên lịch, bắn cảnh báo, chống trùng, nội dung, quyền hệ thống, deep link từ thông báo hệ thống) là PBI sau. Hệ quả đã chấp nhận: trên app thật màn sẽ **ở trạng thái rỗng** cho tới khi engine ra đời. (chốt 2026-09-13)
- **Q2 — chọn A: chuông ở màn Tổng quan có chấm đỏ khi còn mục chưa đọc; màn Trung tâm KHÔNG có nút "đánh dấu tất cả đã đọc"** và không có thao tác xoá. Cách duy nhất để đọc là chạm vào mục. (chốt 2026-09-13)
- **Q3 — chọn A: lịch sử giữ tối đa 200 mục gần nhất, tự dọn mục cũ nhất khi vượt trần.** (chốt 2026-09-13)
