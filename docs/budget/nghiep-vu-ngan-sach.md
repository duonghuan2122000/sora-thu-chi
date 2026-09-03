# TÀI LIỆU NGHIỆP VỤ CHI TIẾT: NGÂN SÁCH (BUDGETING)

> Mở rộng chi tiết từ mục 5 — "Ngân sách (Budgeting)" trong tài liệu tổng hợp tính năng nghiệp vụ App Quản lý Thu Chi (Flutter Mobile). Dùng làm tài liệu tham chiếu khi thiết kế database, API nội bộ (local) và UI.

---

## 1. Mục tiêu nghiệp vụ

Cho phép người dùng đặt giới hạn chi tiêu cho một khoảng thời gian nhất định (theo danh mục hoặc tổng thể), theo dõi mức độ sử dụng so với giới hạn đó theo thời gian thực, và nhận cảnh báo khi chi tiêu tiến gần/vượt ngưỡng — nhằm hỗ trợ kiểm soát tài chính cá nhân chủ động thay vì chỉ ghi chép thụ động.

## 2. Phạm vi

**Trong phạm vi (đã liệt kê ở tài liệu gốc):**
- Ngân sách theo danh mục
- Ngân sách tổng theo tháng/tuần/năm
- Theo dõi tiến độ sử dụng (progress bar)
- Cảnh báo gần/vượt ngân sách
- So sánh dự kiến vs thực tế
- Sao chép ngân sách tháng trước sang tháng mới
- Ngân sách theo từng ví riêng biệt (tùy chọn)

**Ngoài phạm vi giai đoạn hiện tại:**
- Ngân sách dùng chung nhiều người (phụ thuộc "Chia sẻ & Cộng tác" — chưa triển khai)
- Ngân sách tự động điều chỉnh bằng AI/machine learning

---

## 3. Mô hình dữ liệu (Data Model)

### 3.1. Đối tượng `Budget`

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `id` | string (UUID) | ✓ | Định danh duy nhất |
| `name` | string | | Tên gợi nhớ, tự sinh nếu để trống (VD: "Ăn uống — Tháng 9/2026") |
| `scope` | enum: `category` \| `total` | ✓ | Ngân sách theo danh mục hay ngân sách tổng |
| `categoryId` | string (nullable) | Bắt buộc nếu `scope = category` | Tham chiếu danh mục áp dụng |
| `walletIds` | array\<string\> (nullable) | | Danh sách ví áp dụng; rỗng/null = áp dụng toàn bộ ví |
| `amount` | decimal | ✓ | Số tiền giới hạn |
| `currency` | string | ✓ | Theo tiền tệ mặc định của người dùng (không cho chọn tiền tệ khác trong ngân sách, để tránh sai lệch khi quy đổi) |
| `period` | enum: `weekly` \| `monthly` \| `yearly` | ✓ | Chu kỳ ngân sách |
| `periodStartRule` | int (ngày trong tháng, mặc định 1) | | Cho phép đặt kỳ tài chính lệch (VD: bắt đầu ngày 25, đồng bộ với mục 12 — "kỳ tài chính bắt đầu từ ngày 25") |
| `startDate` | date | ✓ | Ngày bắt đầu áp dụng ngân sách |
| `endDate` | date (nullable) | | Nếu null = lặp lại vô thời hạn theo `period` |
| `isRecurring` | boolean | ✓ | Tự động tạo kỳ ngân sách mới khi kỳ hiện tại kết thúc |
| `alertThresholds` | array\<int\> | | Danh sách % ngưỡng cảnh báo, mặc định `[80, 100]` |
| `rolloverUnused` | boolean | | Cộng dồn phần chưa dùng hết sang kỳ sau (mặc định `false`) |
| `status` | enum: `active` \| `archived` \| `deleted` | ✓ | Trạng thái |
| `createdAt` / `updatedAt` | datetime | ✓ | Audit |

### 3.2. Đối tượng `BudgetPeriodSnapshot` (dữ liệu tổng hợp theo từng kỳ, tính toán/cache)

| Trường | Kiểu | Mô tả |
|---|---|---|
| `budgetId` | string | Tham chiếu `Budget` |
| `periodStart` / `periodEnd` | date | Mốc thời gian của kỳ cụ thể |
| `plannedAmount` | decimal | Số tiền giới hạn của kỳ (bao gồm rollover nếu có) |
| `actualSpent` | decimal | Tổng chi tiêu thực tế đã ghi nhận trong kỳ (tính từ giao dịch Chi thuộc `categoryId`/`walletIds` khớp điều kiện) |
| `remaining` | decimal | `plannedAmount - actualSpent` |
| `usagePercent` | decimal | `actualSpent / plannedAmount * 100` |
| `lastAlertTriggered` | int (nullable) | Ngưỡng % cảnh báo gần nhất đã bắn, tránh bắn lặp |

> Snapshot được tính lại (recompute) mỗi khi có giao dịch Chi mới/sửa/xóa thuộc phạm vi ngân sách, hoặc khi mở màn hình Ngân sách (lazy recompute).

---

## 4. Quy tắc nghiệp vụ (Business Rules)

### 4.1. Xác định giao dịch thuộc về một ngân sách
- Giao dịch phải là loại **Chi (Expense)** — Thu và Chuyển khoản không tính vào ngân sách.
- Nếu `scope = category`: giao dịch khớp khi `transaction.categoryId == budget.categoryId` **hoặc** thuộc danh mục con (subcategory) của `categoryId` đó.
- Nếu `scope = total`: mọi giao dịch Chi đều tính, trừ các danh mục người dùng đánh dấu "loại trừ khỏi ngân sách tổng" (tùy chọn nâng cao, mặc định không có danh mục nào bị loại trừ).
- Nếu `walletIds` được chỉ định: chỉ tính giao dịch phát sinh trên các ví đó.
- Ngày giao dịch (`transaction.date`, không phải ngày tạo bản ghi) phải nằm trong khoảng `[periodStart, periodEnd]` của kỳ đang xét.

### 4.2. Không cho phép chồng lấn ngân sách cùng phạm vi
- Không được tạo 2 ngân sách **cùng `categoryId`** và **cùng `period`** có khoảng thời gian hiệu lực chồng lấn nhau (tránh nhầm lẫn khi tính `actualSpent` được cộng vào ngân sách nào).
- Cho phép tồn tại song song: 1 ngân sách tổng (`scope = total`) + nhiều ngân sách theo danh mục — chi tiêu của 1 giao dịch vẫn được trừ vào cả ngân sách danh mục tương ứng *và* ngân sách tổng (không loại trừ lẫn nhau), vì đây là hai góc nhìn khác nhau trên cùng dữ liệu.
- Khi người dùng cố tạo ngân sách trùng phạm vi/thời gian, hệ thống cảnh báo và gợi ý chỉnh sửa ngân sách hiện có thay vì tạo mới.

### 4.3. Vòng đời kỳ ngân sách (Period Lifecycle)
- Khi `isRecurring = true` và ngày hiện tại vượt qua `periodEnd` của kỳ đang active: hệ thống tự động sinh `BudgetPeriodSnapshot` mới cho kỳ tiếp theo, giữ nguyên `plannedAmount` gốc (trừ khi có `rolloverUnused`).
- Nếu `rolloverUnused = true`: `plannedAmount` kỳ mới = `amount` gốc + `remaining` dương của kỳ trước (nếu `remaining` âm — tức đã vượt ngân sách — thì không trừ ngược vào kỳ mới, `plannedAmount` kỳ mới vẫn = `amount` gốc, tránh phạt kép người dùng).
- Nếu `isRecurring = false` hoặc đã qua `endDate`: kỳ ngân sách kết thúc, không tự sinh kỳ mới; ngân sách chuyển trạng thái hiển thị "Đã kết thúc" nhưng vẫn giữ lịch sử để xem báo cáo.

### 4.4. Sao chép ngân sách tháng trước sang tháng mới
- Áp dụng khi người dùng **không** bật `isRecurring` nhưng muốn tái lập thủ công (hoặc dùng để tạo nhanh một bộ ngân sách nhiều danh mục cho kỳ mới).
- Hành động "Sao chép" nhân bản toàn bộ các `Budget` đang active của kỳ trước sang kỳ hiện tại, giữ nguyên `amount`, `categoryId`, `scope`, `walletIds`; đặt lại `startDate`/`endDate` theo kỳ mới; `actualSpent` bắt đầu lại từ 0.
- Cho phép chỉnh sửa từng khoản trước khi xác nhận sao chép hàng loạt (không sao chép "mù").

### 4.5. Cảnh báo ngân sách
- So khớp `usagePercent` với từng giá trị trong `alertThresholds` (mặc định `[80, 100]`, có thể tùy chỉnh, VD thêm mốc `100+` cho "đã vượt").
- Mỗi ngưỡng chỉ bắn cảnh báo **một lần** trong 1 kỳ (dùng `lastAlertTriggered` để chặn lặp) — tránh spam thông báo khi có nhiều giao dịch nhỏ liên tiếp đẩy % lên từ từ.
- Khi `usagePercent >= 100`: hiển thị trạng thái "Đã vượt ngân sách" bằng màu coral (theo Design System), kèm số tiền vượt = `actualSpent - plannedAmount`.
- Thông báo đẩy (push notification) nội dung gợi ý: "Bạn đã dùng {usagePercent}% ngân sách {tên danh mục} tháng này ({actualSpent}/{plannedAmount})."
- Tổng kết cuối kỳ (liên kết mục 9 — Thông báo & Nhắc nhở): so sánh % vượt/tiết kiệm so với kỳ trước cho từng ngân sách.

### 4.6. So sánh Dự kiến vs Thực tế
- Với ngân sách đang active: hiển thị `plannedAmount` (dự kiến) cạnh `actualSpent` (thực tế) theo dạng biểu đồ cột đôi hoặc thanh chồng.
- Với ngân sách đã kết thúc (lịch sử nhiều kỳ): cho phép xem biểu đồ xu hướng `actualSpent` qua các kỳ liên tiếp so với đường `plannedAmount` cố định — giúp nhận diện danh mục thường xuyên vượt ngân sách.
- Chỉ số phụ trợ: "Tốc độ tiêu" — dự đoán tuyến tính `actualSpent` đến hết kỳ dựa trên tỷ lệ số ngày đã qua/số ngày còn lại của kỳ (VD: đã dùng 60% ngân sách nhưng mới qua 40% thời gian kỳ → cảnh báo tốc độ tiêu nhanh hơn dự kiến, kể cả khi `usagePercent` chưa chạm ngưỡng cảnh báo).

### 4.7. Xóa / Lưu trữ (Archive) ngân sách
- Xóa ngân sách không xóa các giao dịch liên quan — chỉ ngừng theo dõi giới hạn từ thời điểm xóa trở đi.
- Ngân sách có lịch sử nhiều kỳ nên ưu tiên "Lưu trữ" (ẩn khỏi danh sách active, giữ dữ liệu cho báo cáo) thay vì xóa cứng; xóa cứng chỉ áp dụng khi ngân sách chưa có kỳ nào ghi nhận chi tiêu.

### 4.8. Ràng buộc với Ví (Wallets)
- Nếu ngân sách giới hạn theo `walletIds` và một ví trong danh sách đó bị người dùng xóa: hệ thống tự động gỡ ví khỏi `walletIds` của ngân sách, không xóa cả ngân sách.
- Nếu `walletIds` trở thành rỗng sau khi gỡ (tất cả ví áp dụng đều đã bị xóa): ngân sách chuyển về áp dụng toàn bộ ví (coi như `walletIds = null`) và thông báo cho người dùng về thay đổi này.

---

## 5. Luồng nghiệp vụ chính (Use Case Flows)

### UC-1: Tạo ngân sách theo danh mục
1. Người dùng vào màn hình Ngân sách → chọn "Thêm ngân sách".
2. Chọn phạm vi: Theo danh mục.
3. Chọn danh mục từ danh sách (hỗ trợ tìm kiếm nhanh).
4. Nhập số tiền giới hạn.
5. Chọn chu kỳ: Tuần/Tháng/Năm.
6. (Tùy chọn) Chọn ví áp dụng — mặc định "Tất cả ví".
7. (Tùy chọn) Bật "Lặp lại tự động mỗi kỳ".
8. (Tùy chọn) Điều chỉnh ngưỡng cảnh báo (mặc định 80%/100%).
9. Xác nhận → hệ thống kiểm tra chồng lấn (mục 4.2) → lưu → tính toán snapshot ban đầu (thường `actualSpent = 0` nếu tạo đầu kỳ, hoặc cộng dồn giao dịch đã có nếu tạo giữa kỳ).

### UC-2: Theo dõi tiến độ ngân sách
1. Vào màn hình Tổng quan Ngân sách.
2. Xem thẻ tổng: tổng đã chi / tổng ngân sách tất cả danh mục, thanh tiến độ tổng.
3. Xem danh sách từng ngân sách theo danh mục, mỗi dòng có thanh tiến độ riêng, đổi màu coral khi ≥ ngưỡng cảnh báo.
4. Chạm vào 1 dòng → xem Chi tiết ngân sách (UC-3).

### UC-3: Xem chi tiết & so sánh dự kiến vs thực tế
1. Từ danh sách, chọn 1 ngân sách.
2. Xem: số đã dùng/tổng, số ngày còn lại của kỳ, tốc độ tiêu dự đoán, biểu đồ so sánh dự kiến–thực tế theo các kỳ gần nhất.
3. Xem danh sách giao dịch Chi thuộc phạm vi ngân sách trong kỳ hiện tại (liên kết trực tiếp tới màn hình Giao dịch đã lọc sẵn).
4. Có thể chỉnh sửa/lưu trữ ngân sách ngay từ màn hình này.

### UC-4: Sao chép ngân sách sang kỳ mới
1. Cuối kỳ (hoặc đầu kỳ mới), hệ thống gợi ý banner "Sao chép ngân sách tháng trước?" nếu phát hiện kỳ mới chưa có ngân sách nào được tạo.
2. Người dùng chọn "Sao chép" → xem trước danh sách các ngân sách sẽ được nhân bản, có thể bỏ chọn từng khoản hoặc sửa số tiền.
3. Xác nhận → tạo hàng loạt ngân sách mới cho kỳ hiện tại.

### UC-5: Nhận cảnh báo vượt ngân sách
1. Người dùng thêm giao dịch Chi mới.
2. Hệ thống tính lại snapshot của (các) ngân sách liên quan ngay lập tức.
3. Nếu `usagePercent` vừa vượt qua một ngưỡng trong `alertThresholds` chưa từng bắn trong kỳ này → gửi push notification + cập nhật badge/màu cảnh báo trên UI.

---

## 6. Trạng thái hiển thị & quy tắc màu (liên kết Design System)

| Điều kiện `usagePercent` | Màu thanh tiến độ | Ý nghĩa |
|---|---|---|
| `< 80%` | Teal (`#0F6E56`) | Bình thường |
| `80% – 99%` | Vàng/cam cảnh báo trung gian (gợi ý bổ sung, không có trong bảng màu gốc — có thể dùng sắc độ pha giữa teal và coral, hoặc thống nhất dùng coral nhạt) | Sắp đạt giới hạn |
| `≥ 100%` | Coral (`#D85A30`) | Đã vượt ngân sách |

> Theo nguyên tắc phối màu trong Design System (mục 3): coral chỉ dành cho ngữ cảnh chi tiêu/cảnh báo — hoàn toàn phù hợp để biểu diễn trạng thái vượt ngân sách. Với mốc "sắp đạt" (80–99%), nếu muốn giữ đúng 2 màu gốc, có thể dùng coral ở dạng nhạt (opacity thấp hơn) thay vì thêm màu thứ ba, để không phá vỡ hệ thống màu nhất quán.

---

## 7. Trường hợp đặc biệt (Edge Cases)

- **Tạo ngân sách giữa kỳ:** `actualSpent` khởi tạo bằng tổng giao dịch Chi đã tồn tại từ `periodStart` đến hiện tại (không phải 0), để phản ánh đúng thực tế.
- **Sửa `amount` giữa kỳ:** áp dụng ngay cho kỳ hiện tại, không hồi tố các kỳ trước.
- **Xóa danh mục đang gắn với ngân sách:** ngân sách chuyển trạng thái "Không hợp lệ" (invalid), hiển thị nhắc người dùng gán lại danh mục khác hoặc xóa ngân sách.
- **Giao dịch chi tiêu bị sửa/xóa sau khi đã bắn cảnh báo:** snapshot tính lại; nếu `usagePercent` giảm xuống dưới ngưỡng đã bắn, không thu hồi thông báo đã gửi nhưng không bắn cảnh báo "giảm" tương ứng (chỉ cảnh báo chiều tăng).
- **Ngân sách theo tuần khi kỳ tài chính lệch ngày (`periodStartRule`):** chỉ áp dụng `periodStartRule` cho chu kỳ tháng/năm; chu kỳ tuần luôn tính theo ngày trong tuần cấu hình chung của ứng dụng (mục 12 — đầu tuần tài chính).
- **Đa tiền tệ:** nếu ví áp dụng có tiền tệ khác tiền tệ mặc định, giao dịch được quy đổi tỷ giá tại thời điểm giao dịch trước khi cộng vào `actualSpent` (đồng bộ nguyên tắc quy đổi ở mục 2 — Quản lý Ví).

---

## 8. Giai đoạn triển khai (bám theo roadmap gốc)

Theo tài liệu gốc, Ngân sách thuộc **Giai đoạn 2**, triển khai sau MVP, cùng đợt với Giao dịch định kỳ, Nhắc nhở, và Xuất báo cáo Excel/PDF — vì Ngân sách phụ thuộc dữ liệu Giao dịch + Danh mục (đã có ở MVP) và cần module Thông báo (Giai đoạn 2) để cảnh báo hoạt động đầy đủ.

Đề xuất chia nhỏ trong Giai đoạn 2:
1. **2a:** Tạo/sửa/xóa ngân sách theo danh mục, theo dõi tiến độ cơ bản (không cảnh báo push).
2. **2b:** Ngân sách tổng, ngân sách theo ví, cảnh báo push, sao chép ngân sách.
3. **2c:** So sánh dự kiến–thực tế nhiều kỳ, tốc độ tiêu dự đoán (phụ thuộc đủ dữ liệu lịch sử ≥ 2 kỳ để có ý nghĩa).

---

## 9. Stack kỹ thuật liên quan (kế thừa từ tài liệu gốc)

- **Local DB:** `drift` — bảng `budgets` + `budget_period_snapshots` (snapshot có thể tính runtime thay vì lưu bảng riêng nếu khối lượng dữ liệu nhỏ; khuyến nghị vẫn cache để tránh tính lại toàn bộ lịch sử giao dịch mỗi lần mở màn hình).
- **State management:** `GetX` — controller riêng `BudgetController` quản lý danh sách active + snapshot hiện tại.
- **Biểu đồ so sánh dự kiến/thực tế:** `fl_chart` (bar chart đôi hoặc line chart chồng).
- **Thông báo cảnh báo:** `flutter_local_notifications`, kích hoạt từ tầng service tính snapshot sau mỗi lần ghi nhận giao dịch Chi.
