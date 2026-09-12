---
title: "Báo cáo"
date: 2026-09-12
tags: [module, report, entity]
sources:
  - ../docs/report/bao-cao-thong-ke-giai-phap.md
  - ../docs/report/man-hinh-01-bao-cao-tong-quan.svg
  - ../docs/report/man-hinh-02-chi-tiet-danh-muc.svg
  - ../docs/report/man-hinh-03-so-sanh-ky.svg
  - ../docs/report/man-hinh-04-xuat-bao-cao.svg
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../../.specify/specs/22/spec.md
  - ../../.specify/specs/23/spec.md
---

# Báo cáo

Module **thống kê/trực quan hoá** thu chi — biến dữ liệu đã ghi thành cái nhìn tổng thể (tiền vào/ra, phân bổ theo danh mục, xu hướng). Tab **Báo cáo** trên app shell; màn Tổng quan là **cửa vào của cả module** (hiện chứa luôn lối vào [[Ngân sách]]).

**Trạng thái:** **màn `01` Tổng quan (PBI 22) + màn `02` Chi tiết theo danh mục (PBI 23) — đã triển khai**. Còn lại của module: So sánh Kỳ (`03`), Xuất báo cáo PDF/Excel/CSV (`04`) — PBI sau. Xem [[Lộ trình phát triển]].

## Mô hình dữ liệu — KHÔNG có schema riêng

Màn báo cáo **chỉ đọc** bảng `transactions` + `categories` (schema **v7** giữ nguyên, kế thừa PBI 21 — **không** thêm bảng/cột, **không** migration). Mọi con số là **đại lượng tính toán** trong RAM:

- **Một lần nạp khi mở tab** (`ReportController.load()`): `allTransactions()` + `categoriesIncludingHidden(expense)`; sau đó **đổi kỳ tính lại từ RAM, KHÔNG đọc DB** (SC-007 < 1 giây).
- **Không bảng tổng hợp/cache** (`report_monthly_summary` mà doc §2.2/§7 gợi ý **không** làm): doc cho phép tính runtime khi dữ liệu nhỏ; hệ quả tốt — sửa/xoá giao dịch là số liệu tự khớp, không hồi tố, không phải đụng mọi đường ghi giao dịch. Chỉ cân nhắc lại nếu đo thấy chậm.
- Module thuần: `lib/core/report/report_view.dart` (toàn bộ số liệu) + `lib/core/report/report_controller.dart` (nạp & kỳ đang chọn) + seam `lib/data/report_deps.dart`. **Không** thêm method `WalletRepository`, không repository mới.
- `DateRange` (khoảng **nửa mở** `[start, end)`) nay ở `lib/core/date_range.dart` — kiểu **dùng chung** Ngân sách ↔ Báo cáo; `budget_view.dart` **re-export** nên mọi import cũ không phải sửa.

## Quy tắc nghiệp vụ (đã chốt)

1. **Loại `transfer` + `adjustment` khỏi MỌI con số** — 2 số tổng, 6 cột, phân bổ, top. Chốt thành **một phép lọc duy nhất** `reportTotals(transactions, range)`; **đừng viết bộ lọc thứ hai** (mọi số liệu đi qua nó ⇒ không lệch số — SC-003/SC-004). Kỳ **chỉ có chuyển khoản** được coi là **kỳ rỗng**.
2. `amount` trong DB **có dấu**: Thu `+`, Chi `−` ⇒ `income` cộng `+amount`, `expense` cộng `−amount`.
3. **Mốc kỳ dương lịch, khoảng nửa mở**: Ngày `[d, d+1)`, **Tuần `[Thứ Hai, +7 ngày)`**, Tháng `[mùng 1, mùng 1 sau)`, Năm `[1/1, 1/1 năm sau)`. Tháng/Năm giải bằng **số học ngày**, không cộng `Duration`. Giao dịch đúng ngày `end` **không** thuộc kỳ (không giao dịch nào thuộc 2 kỳ liền kề).
4. **Biểu đồ = 6 đơn vị liên tiếp kết thúc ở kỳ đang chọn** (phần tử cuối = kỳ đang chọn, in đậm). Kỳ **không có giao dịch vẫn có mặt** với 2 cột `0` (FR-006). Đợt này **không** kéo/vuốt xem thêm kỳ.
5. **Giao dịch có ngày TƯƠNG LAI nhưng nằm trong kỳ vẫn được tính** (khác thói quen "chỉ tính tới hôm nay").
6. **Phân bổ gộp theo danh mục CHA**: khóa nhóm = `category.parentId ?? category.id`, tên/icon/màu lấy từ **cha**; tiền của mọi con tính vào cha. **Top 5** danh mục + nhóm **"Khác"** xếp **cuối** (nhận phần ngoài top 5 **và** tiền chi `categoryId == null`), chỉ hiện **khi có phần dư**. Danh mục **ẩn vẫn tính**; con trỏ tới cha không còn tồn tại ⇒ nhóm theo **chính nó** (không vào "Khác").
7. **Chia % theo `percentSplit` (phần dư lớn nhất)** ⇒ `Σ%` của các lát cắt = **đúng 100**, từng dòng khớp tỉ lệ thật. `Σ tiền các lát = tổng chi của kỳ`.
8. Thẻ **Top danh mục** tối đa **5** dòng, **không** có dòng "Khác" (khác vòng tròn: top là danh mục thật); `percent` ở đây là tỉ lệ trên tổng chi **để vẽ thanh**, không cần cộng = 100. Cùng nguồn nhóm với vòng tròn ⇒ số tiền hai thẻ **khớp nhau**.
9. **Đồng hạng** (cùng số tiền) sắp theo **tên tăng dần** — so bằng chữ đã bỏ dấu (`normalizeSearch`), so code-unit thuần sẽ xếp "Nhà" trước "Ăn".
10. **Trạng thái rỗng theo KỲ ĐANG CHỌN** (không xét cả cửa sổ 6 đơn vị — R10), 2 thông điệp phân biệt:
    - không có Thu/Chi nào ⇒ **cả 3 thẻ** "Chưa có giao dịch nào trong kỳ này" + 2 số tổng `0 đ`;
    - **chỉ có Thu** ⇒ biểu đồ **vẫn vẽ đủ 6 đơn vị**, **riêng** thẻ phân bổ + thẻ top "Chưa có chi tiêu nào trong kỳ này".
11. **Chạm một danh mục → mở tab Giao dịch đã lọc sẵn**: `TxnSearchFilter` (Chi + `dateStart = range.start` + `dateEnd = range.end − 1 ngày` + `categoryIds = {id cha}` + sort ngày mới nhất) rồi `onSelectTab(1)`. Màn Báo cáo **là** tab nên chỉ đổi tab, **không** `popUntil`. Bộ lọc PBI 12 **tự mở rộng cha → con** ⇒ danh sách khớp đúng số trên lát cắt. Nhóm **"Khác"** (`categoryId == null`) **không có đích** ⇒ không chạm được.
12. **Màn `02` liệt kê ĐẦY ĐỦ danh mục** (khác màn `01` cắt top 5): **mọi** danh mục có chi tiêu đều có dòng + lát riêng, **không** gộp phần ngoài top 5. Hệ quả — dòng **"Khác"** ở màn `02` **chỉ** chứa tiền chi **không gắn danh mục** (`categoryId == null`), **không** nuốt phần ngoài top 5 (khác nghĩa "Khác" ở màn `01`). Cùng một hàm nhóm `_breakdown`, chỉ khác chỗ lấy nhóm.
13. **Màu định tính gán theo THỨ HẠNG và LẶP CHU KỲ**: `chartPalette[rank % 5]`, "Khác" (`rank == -1`) = `chartPalette[5]`. Từ danh mục thứ 6 trở đi màu **trùng lại** hạng 1 — chấp nhận, phân biệt bằng **tên + thứ tự** (không dùng `Category.color`, không coral). Chấm màu và thanh tiến độ của một dòng lấy từ **cùng một biến `rank`** ⇒ luôn trùng màu lát cắt tương ứng.
14. **Chip kỳ ở màn `02` là NHÃN TĨNH** — chỉ hiển thị loại kỳ + mốc, **không** bấm được, **không** mũi tên/menu chọn kỳ (khác biệt **cố ý** so với mockup `02`; bộ lọc thời gian nâng cao vẫn ngoài phạm vi). Màn `02` **không** có trạng thái kỳ riêng: luôn kế thừa kỳ đang xem ở màn `01`; back về màn `01` **không** đổi kỳ.
15. **Trạng thái rỗng của màn `02` là TOÀN MÀN**: `total == 0` ⇒ chỉ thông điệp (`hasAnyTxn` ? "Chưa có chi tiêu nào trong kỳ này" : "Chưa có giao dịch nào trong kỳ này"), **không** vẽ vòng tròn rỗng, **không** tiêu đề nhóm rỗng.

## Khi nào số liệu được tính lại

| Sự kiện | Kết quả |
|---|---|
| Mở/chọn lại tab Báo cáo | `AppShell._onTabSelected` gọi `load()` — đọc lại DB (FR-016) |
| Đổi lựa chọn kỳ (Ngày/Tuần/Tháng/Năm) | Dựng lại từ dữ liệu **đã nạp trong RAM**, **không** đọc DB (SC-007) |
| Ghi giao dịch qua FAB **khi đang ở tab Báo cáo** | `AppShell._openAddTransaction` nạp lại controller báo cáo (FAB hiện trên mọi tab — R11/SC-008) |
| Sửa/xoá giao dịch ở màn Giao dịch rồi quay lại tab | Nạp lại theo lần chọn tab |
| Đang mở màn mà dữ liệu đổi ở nơi khác | **Không** tự cập nhật (không có đẩy/lắng nghe) |
| Mất mạng | Không ảnh hưởng — toàn bộ số liệu tính từ dữ liệu trên máy |

## Màn `01` — Tổng quan (đã triển khai)

Bố cục theo mockup `01`, thứ tự từ trên xuống:

1. **Khu đầu màn teal** (`ScreenHeader` với `bottom`): tiêu đề "Báo cáo" + **segmented control 4 kỳ** (mặc định **Tháng**, lựa chọn đang chọn = pill trắng chữ teal) + **2 số tổng** chữ trắng (↑ Thu / ↓ Chi) bọc `FittedBox` chống tràn số lớn. **Không** có nút biểu tượng lịch (khoảng ngày tuỳ chỉnh — PBI sau).
2. **Hàng điều hướng "Ngân sách"** — giữ nguyên từ PBI 20, đặt **trước** các thẻ số liệu (quyết định đã chốt 2026-09-12: không chuyển sang Cài đặt).
3. **Thẻ "Dòng tiền 6 \<đơn vị\> gần đây"** — chú giải Thu (chấm teal) / Chi (chấm coral); cột ghép đôi, **chạm một cột hiện số tiền đã định dạng** (tooltip), không điều hướng. Nhãn trục: `dd/MM` (Ngày/Tuần) · `T@{tháng}` (Tháng) · `{năm}` (Năm).
4. **Thẻ "Phân bổ chi tiêu theo danh mục"** — vòng tròn (donut) màu lấy từ bảng màu **định tính** `SoraColors.chartPalette` (xem [[Design system]]) + nhãn **"Tổng chi" + số tiền phủ giữa vòng tròn** (`fl_chart` không vẽ chữ ở tâm ⇒ phải `Stack`); bên phải là danh sách chú giải (chấm màu, tên, `%`) sắp giảm dần.
5. **Thẻ "Top danh mục chi tiêu"** — tối đa 5 dòng: bubble icon danh mục + tên + số tiền + **thanh tiến độ** (một màu teal, bề rộng `percent/100`). Hàng tiêu đề có liên kết **"Xem tất cả"** (chỉ hiện khi kỳ có chi tiêu) → mở màn `02`.

- **Kỳ đang chọn sống trong controller singleton** ⇒ rời sang Ngân sách rồi quay lại **vẫn giữ kỳ**.
- `ValueKey` cho QA/test: `report-period-<day|week|month|year>`, `report-entry-budget`, `report-flow-chart`, `report-donut`, `report-slice-<id|other>`, `report-legend-<id|other>`, `report-top-<id>`, `report-see-all`.

## Màn `02` — Chi tiêu theo danh mục (đã triển khai, PBI 23)

**Màn con đè shell** (`SubPageScaffold`: app bar teal + nút back, **không** bottom nav, **không** FAB) — vào bằng liên kết **"Xem tất cả"** ở thẻ Top màn `01` (1 lần chạm), nên **kỳ luôn kế thừa** màn `01`. Thứ tự trên xuống:

1. **Chip kỳ** — nhãn tĩnh `Ngày 12/09/2026` · `Tuần 07/09–13/09/2026` (năm theo **ngày cuối kỳ**) · `Tháng 9/2026` · `Năm 2026`; ghép danh từ kỳ **đã có bản dịch** với chuỗi ngày không phụ thuộc ngôn ngữ.
2. **Vòng tròn 200×200** — nhãn giữa = `Tổng chi ngày/tuần/tháng/năm` + tổng chi (`Stack` phủ tâm + `FittedBox` chống tràn số lớn).
3. **Tiêu đề nhóm `DANH MỤC (n)`** với `n = số dòng` (danh mục + "Khác" nếu có).
4. **Mỗi dòng**: chấm màu (theo hạng) + tên (cắt ellipsis) + số tiền căn phải + `%` + **thanh tiến độ cùng màu chấm**.
5. **Dòng gợi ý** cuối danh sách "Chạm vào một danh mục để xem các giao dịch" — chữ tĩnh.

- **Drill-down**: chạm **dòng** hoặc **lát cắt** (cùng hành vi) → đặt `TxnSearchFilter` như màn `01` rồi **`popUntil(isFirst)`** (vì màn `02` là route **đè** shell) **rồi** `onSelectTab(1)`. Dòng "Khác" `onTap: null`.
- **Không đọc DB**: số liệu dựng lại mỗi lần build từ **bản chụp RAM** của `ReportController` qua `categoryDetail()` (trả `null` khi chưa nạp — màn chỉ mở được từ màn `01` đã có dữ liệu) ⇒ hai màn **không thể lệch số**, không phát sinh phép đọc nào (SC-008 < 1 giây giữ nguyên).
- **Đứng trong màn `02` thì số liệu KHÔNG tự nhảy** (kế thừa hành vi PBI 22); muốn số mới → quay lại tab Báo cáo (nạp lại) rồi mở lại.
- **Hàng tỉ / màn nhỏ**: lệch bố cục thì giảm `centerSpaceRadius`/cỡ chữ — điều chỉnh **một chỗ** trong màn `02`.
- `ValueKey` cho QA/test: `report-detail-chip`, `report-detail-donut`, `report-detail-row-<id|other>`, `report-detail-empty`, `report-see-all` (màn `01`).

## Giới hạn đã biết (đừng tưởng là bug)

- **Đa tiền tệ chưa quy đổi**: màn cộng theo **số tiền ghi trên giao dịch**, giả định một tiền tệ mặc định. Ví tiền tệ khác ⇒ số tổng có thể lệch (nguồn tỷ giá offline vẫn là ⚠ quyết định mở).
- **Kỳ tài chính lệch ngày** chưa hỗ trợ (màn con `04` nhóm Tiện ích chưa dựng).
- **Công tắc "Ẩn số dư"** (PBI 17) **chưa** che số tiền trên màn Báo cáo.
- **Dữ liệu nâng cấp từ trước schema v4** có thể lệch: giao dịch `category_id = null` nhưng tên danh mục khớp cha được vòng tròn xếp vào **"Khác"**, còn màn Giao dịch lọc theo cha vẫn khớp **theo tên** (`_normalizedNames`) ⇒ tổng danh sách **lớn hơn** số trên lát cắt. Chấp nhận hành vi sẵn có của bộ lọc PBI 12, **không** sửa trong PBI 22.
- **Kỳ đang chọn nằm trong controller dùng chung**: hiện chỉ **một** màn dùng; nếu sau này có màn thứ hai đọc `ReportController` thì phải tách kỳ ra tham số màn.

## Ngoài phạm vi (đợt này)

Bộ lọc báo cáo nâng cao (khoảng ngày tuỳ chỉnh, theo ví/danh mục/tag, ghi nhớ bộ lọc), biểu đồ xu hướng (line) + đường trung bình động, báo cáo dòng tiền theo từng ví, insight tự động, toggle "xem theo danh mục con", màn So sánh kỳ (`03`) + Xuất báo cáo (`04`), kéo/vuốt biểu đồ quá 6 đơn vị, bảng tổng hợp/cache số liệu.

## Liên kết

- [[Giao dịch]] — nguồn dữ liệu + màn đích của drill-down (bộ lọc điền sẵn).
- [[Danh mục]] — gộp cha–con, danh mục ẩn vẫn tính, màu/icon hiển thị.
- [[Ngân sách]] — nằm **trong** tab Báo cáo (hàng điều hướng đầu màn).
- [[Design system]] — bảng màu định tính `chartPalette`, màu teal/coral cho cột.
- [[Nguyên tắc nghiệp vụ]] — số dư suy ra, transfer không là thu/chi, ẩn-vs-xoá.
