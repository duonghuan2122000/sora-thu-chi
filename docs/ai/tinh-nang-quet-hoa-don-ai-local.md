# TÍNH NĂNG BỔ SUNG: QUÉT HÓA ĐƠN BẰNG AI LOCAL (OCR & TRÍCH XUẤT THÔNG TIN)

> Bổ sung cho mục "3. Quản lý Giao dịch" trong tài liệu nghiệp vụ gốc. Toàn bộ xử lý chạy **on-device**, không gửi ảnh/dữ liệu lên server nào — giữ đúng nguyên tắc "offline hoàn toàn" của app.

---

## 1. Mục tiêu

- Giảm thao tác nhập tay: người dùng chụp/chọn ảnh hóa đơn → app tự trích xuất **số tiền, ngày giờ, tên cửa hàng, danh mục gợi ý** → người dùng chỉ cần xác nhận hoặc sửa nhẹ.
- Giữ nguyên tắc bảo mật & quyền riêng tư của app: không có tài khoản, không mạng, dữ liệu không rời khỏi thiết bị.
- Ưu tiên dùng **LLM chạy on-device (local)** làm bộ não phân tích chính vì hiểu ngữ cảnh tự do tốt hơn nhiều so với regex (đọc hiểu hóa đơn viết tắt, SMS đủ kiểu ngân hàng, email trình bày khác nhau...) — nhưng vì LLM tốn RAM/CPU, tính năng này **chỉ bật khi máy đáp ứng đủ cấu hình tối thiểu** (xem mục 11); máy không đạt sẽ tự dùng bộ phân tích theo quy tắc (rule-based) làm phương án dự phòng, tính năng vẫn hoạt động được cho mọi máy chứ không "khoá cứng".

## 2. Kiến trúc AI Local

```
Ảnh hóa đơn / Văn bản dán
   │
   ▼
[1] Tiền xử lý ảnh  (crop, xoay, tăng tương phản)   ── (bỏ qua nếu là "Dán văn bản")
   │
   ▼
[2] OCR on-device    (google_mlkit_text_recognition)
   │  → văn bản thô (raw text) + tọa độ từng dòng
   ▼
[3] Bộ phân tích — chọn 1 trong 2 nhánh tùy kết quả kiểm tra cấu hình máy (mục 11):
   │
   ├─ (A) Đạt cấu hình → LLM Local (engine chính)
   │      1 lần gọi model, tự nhận diện loại nguồn (hóa đơn/SMS/email...) + trích xuất
   │      toàn bộ field ra JSON có cấu trúc, kèm độ tin cậy từng field
   │
   └─ (B) Không đạt cấu hình → Bộ phân tích theo quy tắc (Rule-based, thuần Dart)
          Source classifier + bộ luật regex/dictionary riêng cho từng loại nguồn
   │
   ▼
[4] Màn hình xác nhận & chỉnh sửa (luôn bắt buộc, dù dùng engine nào)
   │
   ▼
[5] Lưu giao dịch + ảnh gốc + text OCR thô + kết quả phân tích + engine đã dùng
```

**Vì sao vẫn giữ nhánh dự phòng (B) thay vì bắt buộc LLM:**
- LLM local (model quantize ~0.5B–3B) cần tối thiểu vài GB RAM trống và chip đủ mạnh mới chạy mượt trong vài giây; ép chạy trên máy yếu sẽ giật/treo/hết pin nhanh — trải nghiệm tệ hơn không có AI.
- App vẫn phải hoạt động tốt trên máy cấu hình thấp (nguyên tắc offline, không giới hạn thiết bị của app) → bắt buộc có phương án B luôn sẵn sàng, không cần tải gì thêm.
- Cả 2 nhánh đều cho **cùng một định dạng kết quả đầu ra** (amount, date, merchant, category, type, confidence) nên màn hình xác nhận (mục 3.6) dùng chung, người dùng không cảm nhận sự khác biệt ngoài việc LLM thường chính xác hơn với nội dung phức tạp/không theo mẫu.

### 2.1. Giới hạn cần lưu ý
- ML Kit Text Recognition (bản Latin) nhận diện tiếng Việt có dấu ở mức tương đối (chữ không dấu/số rất chính xác, chữ có dấu đôi khi sai) → ưu tiên trích xuất **số** (số tiền, ngày) vì độ chính xác cao nhất, tên cửa hàng chỉ mang tính gợi ý và luôn cho sửa tay. Cả 2 engine (LLM lẫn rule-based) đều nhận input từ cùng bước OCR này nên giới hạn OCR áp dụng chung.
- Ảnh mờ, thiếu sáng, hóa đơn nhăn/nhàu → tỷ lệ nhận sai tăng → bắt buộc có bước xác nhận thủ công, không tự động lưu giao dịch khi chưa qua màn hình xác nhận, dù dùng engine nào.
- LLM local suy luận chậm hơn rule-based vài giây (thường 2–6 giây tùy máy) → luôn hiện màn hình "Đang xử lý" (mục 3, màn `scan-03-processing.svg`) để người dùng biết máy đang tính toán, không phải bị treo.

---

## 3. Luồng nghiệp vụ chi tiết

### 3.1. Điểm truy cập (Entry points)
- Nút **FAB (+)** ở bottom nav → bottom sheet "Thêm giao dịch nhanh" có thêm lựa chọn **"📷 Quét hóa đơn"** bên cạnh "Thu" / "Chi" / "Chuyển khoản".
- Trong màn hình **Thêm giao dịch thủ công**: icon máy ảnh cạnh ô "Ảnh hóa đơn đính kèm" → cho phép quét bổ sung vào giao dịch đang tạo.
- Từ danh sách Giao dịch: menu "..." → "Quét hóa đơn mới".

### 3.2. Chụp ảnh / chọn ảnh
- Mở camera toàn màn hình với khung viền gợi ý (guide frame) hình chữ nhật để người dùng canh hóa đơn vào khung.
- Tùy chọn: bật/tắt đèn flash, chọn ảnh có sẵn từ thư viện.
- Cho phép **quét nhiều hóa đơn liên tiếp** (chế độ hàng loạt) — sau khi chụp 1 ảnh, hỏi "Quét thêm hóa đơn khác?" để xử lý nhiều hóa đơn trong 1 phiên (hữu ích khi nhập bù nhiều hóa đơn cũ).

### 3.3. Tiền xử lý ảnh (tự động)
- Tự động phát hiện & crop theo biên hóa đơn (edge detection cơ bản); nếu không phát hiện được biên rõ ràng, dùng nguyên ảnh và cho phép người dùng tự kéo 4 góc để crop thủ công.
- Tự động xoay ảnh về đúng chiều dựa vào hướng dòng chữ.
- Tăng tương phản / chuyển ảnh xám (grayscale) trước khi đưa vào OCR để tăng độ chính xác.

### 3.4. OCR trích xuất văn bản thô
- Chạy `TextRecognizer` on-device, trả về danh sách các khối văn bản (text blocks) kèm tọa độ (bounding box) trên ảnh — tọa độ này dùng để highlight vùng tương ứng khi người dùng chạm vào 1 field ở màn hình xác nhận ("tại sao app đọc ra số này" → khoanh vùng trên ảnh gốc).

### 3.5. Bộ phân tích văn bản (Local Parser)
Áp dụng bộ luật (rule-based) theo thứ tự ưu tiên:

| Trường | Cách nhận diện | Độ ưu tiên |
|---|---|---|
| **Tổng tiền** | Tìm dòng chứa từ khóa: "TỔNG CỘNG", "TỔNG TIỀN", "THANH TOÁN", "TOTAL", "T.TIỀN"; lấy số tiền lớn nhất/gần cuối hóa đơn khớp định dạng tiền tệ | Cao |
| **Ngày giờ** | Regex các định dạng `dd/mm/yyyy`, `dd-mm-yyyy`, `yyyy-mm-dd`, kèm giờ `hh:mm`; nếu không tìm thấy → mặc định thời điểm hiện tại | Cao |
| **Tên cửa hàng (merchant)** | Dòng đầu tiên có cỡ chữ lớn nhất trong phần đầu hóa đơn (dựa theo chiều cao bounding box), hoặc dòng chứa "Cửa hàng", "CN", "Chi nhánh" | Trung bình |
| **Danh mục gợi ý** | Đối chiếu tên cửa hàng với **từ điển từ khóa → danh mục** cục bộ (VD: "Circle K", "Highlands", "Phúc Long" → Ăn uống; "Petrolimex", "Grab" → Di chuyển; "Điện máy Xanh" → Mua sắm) | Thấp (chỉ gợi ý) |
| **Danh sách mặt hàng (line items)** | Các dòng có dạng `tên hàng ... số lượng ... đơn giá ... thành tiền` — trích xuất nếu bố cục rõ ràng | Thấp — tính năng nâng cao |
| **Mã số thuế / VAT** | Regex 10–14 chữ số sau nhãn "MST"/"Mã số thuế" | Thấp — thông tin phụ, hiển thị trong ghi chú |

- **Học theo người dùng (local learning):** khi người dùng sửa danh mục gợi ý cho 1 merchant, app lưu lại cặp `tên cửa hàng (chuẩn hóa) → danh mục` vào bảng ánh xạ cục bộ; lần quét sau gặp cùng merchant sẽ áp dụng đúng danh mục đó mà không cần đoán lại.
- Mỗi field trả về kèm **mức độ tin cậy (confidence)**: Cao / Trung bình / Thấp — dùng để tô màu chỉ báo ở màn hình xác nhận (xem mục 4 – màn hình thiết kế).

### 3.6. Màn hình xác nhận & chỉnh sửa (bắt buộc, không auto-save)
- Hiển thị ảnh hóa đơn thu nhỏ ở trên, các trường trích xuất được ở dưới dạng form có thể sửa: Số tiền, Ngày giờ, Cửa hàng/Ghi chú, Danh mục (dropdown, đã có gợi ý sẵn), Ví áp dụng (mặc định theo ví mặc định đã cấu hình).
- Field có độ tin cậy **Thấp** hoặc **để trống** → viền cảnh báo màu coral + gợi ý "Vui lòng kiểm tra lại".
- Chạm vào 1 field → khoanh vùng tương ứng trên ảnh gốc (dựa vào bounding box đã lưu ở bước OCR) để người dùng đối chiếu nhanh.
- Nút "Lưu giao dịch" chỉ bấm được khi trường **Số tiền** đã có giá trị hợp lệ (bắt buộc); các trường khác có thể để trống/sửa sau.

### 3.7. Lưu dữ liệu
- Giao dịch được tạo với cờ `nguồn = "AI Scan"` (khác với `nguồn = "Thủ công"`) để sau này lọc/thống kê được giao dịch nào tạo qua quét hóa đơn.
- Ảnh hóa đơn gốc lưu vào thư mục đính kèm cục bộ, gắn vào field "Ảnh hóa đơn/chứng từ đính kèm" đã có sẵn trong tính năng Giao dịch.
- Text OCR thô + kết quả parser (JSON) lưu kèm bản ghi quét (Scan History) để phục vụ tra cứu/gỡ lỗi và làm dữ liệu cải thiện bộ luật phân tích sau này.

### 3.8. Xử lý lỗi & trường hợp đặc biệt
| Tình huống | Xử lý |
|---|---|
| OCR không đọc được chữ nào (ảnh quá mờ/tối) | Thông báo "Không nhận diện được nội dung hóa đơn. Vui lòng chụp lại hoặc nhập tay." + nút "Nhập tay" chuyển sang form thêm giao dịch trống |
| Đọc được văn bản nhưng không tìm ra số tiền | Để trống trường Số tiền, đánh dấu bắt buộc nhập tay trước khi lưu |
| Hóa đơn viết tay / hóa đơn nước ngoài (không phải VND) | Cho phép chọn lại đơn vị tiền tệ thủ công ở màn hình xác nhận |
| Người dùng huỷ giữa chừng | Không lưu bất kỳ dữ liệu nào; ảnh tạm bị xoá khỏi bộ nhớ đệm |
| Quét trùng hóa đơn đã nhập trước đó | Cảnh báo nhẹ nếu số tiền + ngày giờ trùng khớp với 1 giao dịch đã có trong vòng 24h (gợi ý tránh nhập trùng) |

---

## 4. Cấu trúc dữ liệu bổ sung

**Bảng `scan_history` (mới):**
| Trường | Kiểu | Ghi chú |
|---|---|---|
| id | string | khóa chính |
| transaction_id | string (nullable) | liên kết giao dịch đã lưu (null nếu huỷ) |
| image_path | string | đường dẫn ảnh gốc trong local storage |
| raw_ocr_text | text | văn bản thô do OCR trả về |
| parsed_json | text | kết quả phân tích (amount, date, merchant, category, type, confidence) |
| engine_used | string | `"llm_tier_a"` \| `"llm_tier_b"` \| `"rule_based"` — engine nào đã xử lý lần quét này |
| created_at | datetime | |

**Bảng `merchant_category_mapping` (mới — dữ liệu học cục bộ):**
| Trường | Kiểu | Ghi chú |
|---|---|---|
| merchant_name_normalized | string | tên cửa hàng đã chuẩn hóa (chữ thường, bỏ dấu) |
| category_id | string | danh mục người dùng đã chọn/sửa |
| updated_at | datetime | |

---

## 5. Cài đặt liên quan (trong Cài đặt > Quét hóa đơn AI)
- Bật/tắt tính năng quét hóa đơn.
- Ngôn ngữ ưu tiên khi OCR: Việt / Anh / Tự động.
- Tự động tăng độ nét/tương phản ảnh trước khi quét (bật/tắt).
- **Trạng thái AI Local (LLM):** hiển thị engine đang dùng (LLM Tier A/B hoặc "Chế độ cơ bản"), dung lượng model đã tải, nút "Kiểm tra lại cấu hình máy" — chi tiết ở mục 11.
- Xem & xoá danh sách ánh xạ Cửa hàng → Danh mục đã học.
- Xem lịch sử các lần quét (Scan History), kể cả lần huỷ.

## 6. Quyền riêng tư & bảo mật
- Toàn bộ ảnh, văn bản OCR, kết quả phân tích chỉ lưu & xử lý **trên thiết bị**, không có bước upload lên server/API bên ngoài nào.
- Ảnh hóa đơn tuân theo cùng cơ chế mã hóa lưu trữ local đã áp dụng cho các file đính kèm khác trong app.
- Quyền camera/thư viện ảnh chỉ xin khi người dùng thực sự mở tính năng quét (không xin quyền lúc mở app lần đầu).

## 7. Gợi ý triển khai theo giai đoạn
| Giai đoạn | Nội dung |
|---|---|
| **MVP AI Scan** | Chụp/chọn ảnh → OCR → parser cơ bản (số tiền, ngày, merchant) → màn hình xác nhận sửa tay → lưu giao dịch |
| **Giai đoạn 2** | Gợi ý danh mục theo từ điển + học theo người dùng (merchant mapping), quét hàng loạt nhiều hóa đơn, Scan History |
| **Giai đoạn 3 (tùy chọn nâng cao)** | Trích xuất danh sách mặt hàng (line items), chế độ "AI nâng cao" dùng model local lớn hơn cho hóa đơn phức tạp/viết tay |

## 8. Stack kỹ thuật bổ sung (Flutter)
- **OCR on-device:** `google_mlkit_text_recognition`
- **Chụp ảnh / chọn ảnh:** `camera`, `image_picker`
- **Tiền xử lý ảnh (crop, xoay, contrast):** `image`, `image_cropper`
- **Phân tích văn bản:** module Dart thuần (regex + dictionary nội bộ), không phụ thuộc thư viện ngoài
- **LLM local (engine chính, có gating cấu hình):**
  - **Gemini Nano** — qua ML Kit GenAI APIs / Android AICore, chỉ khả dụng trên các máy Android được Google hỗ trợ AICore (Pixel 8+, Samsung Galaxy S24+...); model do hệ thống quản lý, app **không cần tự tải**, hiệu năng tốt nhất và không tốn dung lượng cài đặt riêng.
  - **Gemma 3n E2B** — model mở, "effective 2B" (kiến trúc MatFormer giúp footprint bộ nhớ nhỏ dù chất lượng tương đương model lớn hơn), chạy đa nền tảng Android & iOS qua Google AI Edge / MediaPipe LLM Inference API (`.task` bundle, quantized int4, ~1.5–2GB) — dùng cho máy không có Gemini Nano nhưng vẫn đủ cấu hình.
- **Kiểm tra cấu hình thiết bị:** `device_info_plus` (RAM, model máy, OS) kết hợp platform channel riêng để đọc dung lượng trống, khả năng hỗ trợ AICore (Android) và hỗ trợ NNAPI/GPU delegate hoặc Neural Engine (iOS) cho Gemma 3n E2B
- **Lưu trữ kết quả quét:** `drift` (bảng `scan_history`, `merchant_category_mapping` — theo đúng local DB đã dùng cho toàn app)

## 9. Danh sách màn hình thiết kế (SVG đính kèm)
1. `scan-01-quick-add-sheet.svg` — Bottom sheet "Thêm giao dịch nhanh" có lựa chọn Quét hóa đơn
2. `scan-02-camera-capture.svg` — Màn hình chụp hóa đơn (khung guide, flash, chọn từ thư viện)
3. `scan-03-processing.svg` — Màn hình đang xử lý OCR/AI
4. `scan-04-confirm-result.svg` — Màn hình xác nhận & chỉnh sửa kết quả trích xuất (màn hình chính, nguồn: hóa đơn giấy)
5. `scan-05-settings.svg` — Màn hình Cài đặt tính năng Quét hóa đơn AI
6. `scan-06-source-select.svg` — Bottom sheet chọn **nguồn trích xuất** (hóa đơn giấy / tin nhắn-thông báo ngân hàng / email sao kê / dán văn bản)
7. `scan-07-paste-text.svg` — Màn hình dán văn bản SMS/thông báo để phân tích (không cần OCR)
8. `scan-08-confirm-bank-sms.svg` — Màn hình xác nhận giao dịch trích xuất từ tin nhắn/thông báo ngân hàng
9. `scan-09-statement-multi-select.svg` — Màn hình chọn & nhập hàng loạt giao dịch trích xuất từ email sao kê

> Tất cả màn hình tuân thủ đúng Design System đã có: teal `#0F6E56` làm màu thương hiệu, coral `#D85A30` cho cảnh báo/chi tiêu, bo góc `10px` cho card, `24–28px` cho khung điện thoại, font Roboto, số tiền căn phải định dạng `xxx.xxx đ`.

---

## 10. Mở rộng: Trích xuất từ Tin nhắn/Thông báo Ngân hàng & Email Sao kê

Ngoài hóa đơn giấy, tính năng AI Local mở rộng để nhận diện **3 nguồn ảnh chụp màn hình khác**, vì đây là nguồn phổ biến nhất mà người dùng Việt Nam thường có sẵn (screenshot SMS ngân hàng báo biến động số dư, thông báo app ngân hàng/ví điện tử, hoặc bảng sao kê từ email). Kiến trúc pipeline (OCR on-device → parser cục bộ → màn hình xác nhận) giữ nguyên như mục 2–3; phần khác biệt là **bộ nhận diện nguồn (source classifier)** và **bộ luật phân tích riêng cho từng loại**.

### 10.1. Các nguồn được hỗ trợ

| Nguồn | Mô tả | Kết quả |
|---|---|---|
| **Hóa đơn giấy** (đã có ở mục 1–9) | Ảnh chụp hóa đơn từ cửa hàng, quán ăn... | 1 giao dịch |
| **Tin nhắn SMS ngân hàng** | Ảnh chụp SMS dạng "TK 19029xxx: -85,000VND lúc 12/09 08:24. Số dư: 1,234,000VND..." | 1 giao dịch, tự nhận Thu/Chi theo dấu +/- |
| **Thông báo app Ngân hàng/Ví điện tử** | Ảnh chụp push notification hoặc màn hình chi tiết giao dịch trong app (Momo, ZaloPay, Vietcombank, Techcombank, MB Bank...) | 1 giao dịch |
| **Email sao kê / bảng liệt kê giao dịch** | Ảnh chụp email hoặc bảng sao kê có **nhiều dòng giao dịch** | Nhiều giao dịch — cho chọn để nhập hàng loạt |
| **Dán văn bản (Paste text)** | Người dùng copy nội dung SMS/email rồi dán trực tiếp vào app (không qua ảnh/OCR) | Chính xác hơn OCR vì không phải "đoán" chữ |

### 10.2. Điểm truy cập
- Bottom sheet "Thêm giao dịch nhanh" đổi mục **"Quét hóa đơn (AI)"** thành mục cha **"Trích xuất bằng AI"**, khi chạm vào mở ra bottom sheet con với 4 lựa chọn: *Chụp hóa đơn giấy · Chụp tin nhắn/thông báo ngân hàng · Chụp email sao kê · Dán văn bản*.
- Với 3 lựa chọn dùng ảnh, luồng chụp/chọn ảnh và xử lý OCR (mục 3.2–3.4) áp dụng chung.
- Với "Dán văn bản": bỏ qua bước ảnh/OCR, mở màn hình có ô nhập, người dùng dán nội dung đã copy → đưa thẳng vào bước phân tích (mục 3.5).

### 10.3. Bộ nhận diện nguồn (Source Classifier) — chạy trên văn bản OCR/text đã có
Chạy **trước** bộ phân tích chi tiết, dựa hoàn toàn trên từ khóa/mẫu câu (rule-based, không cần model riêng):

| Nếu văn bản chứa... | Phân loại là |
|---|---|
| Tên ngân hàng (Vietcombank, Techcombank, MB Bank, ACB, BIDV, Agribank, TPBank, VPBank...) + mẫu số dư ("Số dư:", "SD:", "Available balance") + số tiền có dấu `+`/`-` | **Tin nhắn SMS ngân hàng** |
| Cụm "Giao dịch thành công", "Bạn đã chuyển", "Bạn đã nhận tiền từ", "Thanh toán thành công" + logo/tên ví điện tử (Momo, ZaloPay, VNPay, ShopeePay) | **Thông báo ví điện tử/app ngân hàng** |
| Nhiều dòng lặp lại theo cấu trúc `ngày – mô tả – số tiền` (≥ 3 dòng giống mẫu) | **Email sao kê / bảng nhiều giao dịch** |
| Không khớp mẫu nào ở trên | **Hóa đơn giấy** (mặc định, theo mục 3.5) |

- Người dùng luôn có thể **sửa tay loại nguồn** ở đầu màn hình xác nhận nếu app đoán sai (dropdown "Loại nguồn: ...").
- Việc phân loại chỉ ảnh hưởng đến **bộ luật trích xuất field nào ứng với vị trí nào**, không ảnh hưởng tới nguyên tắc chung: luôn qua màn hình xác nhận trước khi lưu.

### 10.4. Bộ luật trích xuất riêng cho từng nguồn

**a) Tin nhắn SMS ngân hàng / Thông báo ví điện tử (1 giao dịch):**

| Trường | Cách nhận diện |
|---|---|
| Số tiền | Số đi kèm dấu `+`/`-` hoặc từ khóa "ghi nợ"/"ghi có", "-VND"/"+VND" |
| Loại (Thu/Chi) | Dấu `-` hoặc "ghi nợ"/"trừ tiền" → Chi; dấu `+` hoặc "ghi có"/"nhận tiền" → Thu |
| Ngân hàng/Ví | Đối chiếu tên thương hiệu xuất hiện trong text với danh sách ngân hàng/ví nội bộ |
| Số tài khoản/thẻ (4 số cuối) | Regex tìm chuỗi số cuối cùng sau "TK", "STK", "thẻ ****" |
| Số dư sau giao dịch | Số theo sau "Số dư:", "SD:" |
| Mã tham chiếu giao dịch | Chuỗi chữ+số sau "Mã GD", "Ref", "FT..." — lưu vào ghi chú để đối chiếu sau này, không hiển thị làm trường chính |
| Nội dung chuyển khoản | Phần text sau "ND:", "Nội dung:" — dùng làm gợi ý Ghi chú và để đoán Danh mục (VD: nội dung "chuyen tien an trua" → gợi ý Ăn uống) |
| Ví áp dụng | Gợi ý theo ví đã gắn với ngân hàng/thẻ đó trước đây (nếu người dùng từng chọn) |

**b) Email sao kê / bảng nhiều giao dịch (nhiều giao dịch):**
- Tách văn bản OCR thành từng **dòng bảng** dựa theo mẫu lặp lại (ngày → mô tả → số tiền → số dư, mỗi dòng 1 giao dịch).
- Mỗi dòng phát sinh 1 bản ghi tạm: Ngày, Mô tả (dùng đoán danh mục), Số tiền, Ghi nợ/Ghi có.
- Đối chiếu với giao dịch đã có trong app theo (ngày + số tiền) trong khoảng ±1 ngày → nếu trùng, **tự bỏ chọn sẵn** dòng đó ở màn hình chọn để tránh nhập trùng, kèm nhãn "Có thể đã tồn tại".
- Người dùng tick chọn các dòng muốn nhập → bấm "Thêm N giao dịch đã chọn" → tạo hàng loạt cùng lúc, mỗi giao dịch gắn `nguồn = "AI Scan - Sao kê"`.

**c) Dán văn bản (Paste text):**
- Dùng lại đúng bộ phân tích ở (a) hoặc (b) tùy nội dung dán khớp mẫu SMS đơn lẻ hay bảng nhiều dòng — bỏ qua hoàn toàn bước OCR nên độ chính xác ký tự gần như tuyệt đối, chỉ còn phụ thuộc bộ luật phân tích.

### 10.5. Cập nhật cấu trúc dữ liệu
Bổ sung trường `source_type` vào bảng `scan_history` (mục 4):
```
source_type: "paper_receipt" | "bank_sms" | "ewallet_notification" | "statement_email" | "pasted_text"
```
Với `statement_email`, một bản ghi `scan_history` có thể liên kết tới **nhiều `transaction_id`** (danh sách) thay vì 1 giao dịch duy nhất.

### 10.6. Lưu ý về độ chính xác & quyền riêng tư
- Ảnh chụp màn hình SMS/thông báo thường có nền đơn giản, chữ rõ nét hơn hóa đơn giấy → độ chính xác OCR cao hơn đáng kể; vẫn giữ nguyên tắc **luôn xác nhận trước khi lưu**.
- Khuyến khích dùng "Dán văn bản" khi có thể (copy tin nhắn) thay vì chụp ảnh, vì bỏ qua hoàn toàn bước OCR dễ sai.
- Toàn bộ nội dung SMS/email chứa số tài khoản, số dư... chỉ xử lý và lưu **cục bộ trên thiết bị**, không đồng bộ hay upload lên bất kỳ đâu — đúng nguyên tắc riêng tư đã nêu ở mục 6.

### 10.7. Cập nhật lộ trình triển khai
| Giai đoạn | Nội dung bổ sung |
|---|---|
| **Giai đoạn 2** (mở rộng) | Nhận diện tin nhắn SMS ngân hàng + thông báo ví điện tử (1 giao dịch/lần), tính năng "Dán văn bản" |
| **Giai đoạn 3** | Nhận diện email sao kê / bảng nhiều giao dịch, chọn & nhập hàng loạt, tự phát hiện trùng lặp |

---

## 11. Kiểm tra cấu hình thiết bị & Cơ chế bật LLM Local (Gemini Nano / Gemma 3n E2B)

Vì LLM chạy on-device chỉ nên bật khi máy đủ khả năng, app **luôn kiểm tra cấu hình trước khi cho phép dùng LLM**; nếu không đạt, tính năng vẫn hoạt động bình thường ở "Chế độ cơ bản" (rule-based, mục 3.5).

### 11.1. Thời điểm kiểm tra
- Lần đầu người dùng mở tính năng "Trích xuất bằng AI" (mục 10.2), hoặc lần đầu bật toggle liên quan trong Cài đặt.
- Người dùng có thể chủ động bấm **"Kiểm tra lại cấu hình máy"** trong Cài đặt bất cứ lúc nào (khi đổi máy, cập nhật hệ điều hành, hoặc dọn thêm bộ nhớ trống).
- Tự động kiểm tra lại (âm thầm, không hiện màn hình) mỗi khi mở tính năng nếu lần kiểm tra gần nhất đã quá 30 ngày — phòng trường hợp máy đã đổi trạng thái (VD: hết dung lượng trống).

### 11.2. Các bước kiểm tra & phân loại (Tier)
Kiểm tra theo thứ tự ưu tiên, chỉ mất khoảng 2–3 giây, hoàn toàn cục bộ:

| Bước | Kiểm tra | Kết quả |
|---|---|---|
| 1 | Máy có hỗ trợ **Gemini Nano** qua Android AICore không? (danh sách thiết bị do Google công bố, ví dụ dòng Pixel 8 trở lên, Samsung Galaxy S24 trở lên...) | Có → **Tier A**, dừng kiểm tra |
| 2 | Nếu không có AICore: RAM tổng ≥ 4GB **và** dung lượng trống ≥ 2GB **và** chip hỗ trợ GPU delegate/NNAPI (Android) hoặc Neural Engine từ chip A12/Bionic trở lên (iOS) | Đạt → **Tier B** (dùng Gemma 3n E2B) |
| 3 | Không thỏa điều kiện ở bước 1 và 2 | **Tier C** — không dùng LLM, dùng "Chế độ cơ bản" (rule-based) |

| Tier | Model sử dụng | Cần tải về? | Ghi chú |
|---|---|---|---|
| **A** | Gemini Nano (qua ML Kit GenAI APIs / AICore) | Không — hệ thống Android quản lý | Nhanh nhất, không tốn thêm dung lượng cài đặt của app |
| **B** | Gemma 3n E2B (quantized, qua MediaPipe LLM Inference) | Có — khoảng 1.5–2GB, khuyến nghị tải qua Wifi | Chạy được cả Android & iOS |
| **C** | — (Rule-based / Chế độ cơ bản) | Không | Không có bước "đọc hiểu ngữ cảnh" thông minh, chỉ trích xuất theo mẫu cố định như mục 3.5 |

### 11.3. Luồng bật LLM (màn hình `scan-10-device-check.svg`)
1. Người dùng bấm bật/kiểm tra → hiển thị màn hình đang quét cấu hình máy (RAM, dung lượng trống, chip/AICore) với animation.
2. Hiển thị kết quả:
   - **Đạt Tier A:** thông báo "Máy của bạn hỗ trợ Gemini Nano — sẵn sàng dùng ngay, không cần tải gì thêm" → kích hoạt luôn.
   - **Đạt Tier B:** thông báo "Máy của bạn đủ điều kiện dùng AI nâng cao (Gemma 3n E2B)" + nút "Tải model (~1.8GB) qua Wifi" → sau khi tải xong mới kích hoạt.
   - **Tier C (không đạt):** liệt kê rõ tiêu chí chưa đạt (VD: "RAM 3GB — cần tối thiểu 4GB") + thông báo "Bạn vẫn dùng được tính năng trích xuất ở Chế độ cơ bản, không cần AI nâng cao".
3. Kết quả kiểm tra + Tier được lưu cục bộ (`device_check_result`), không cần chạy lại kiểm tra đầy đủ mỗi lần mở tính năng (trừ khi quá 30 ngày hoặc người dùng chủ động kiểm tra lại).

### 11.4. Vận hành khi đã bật LLM
- Với Tier A/B, bước phân tích văn bản (mục 3.5 nhánh A) gọi LLM **1 lần duy nhất** với văn bản OCR (hoặc văn bản dán) làm đầu vào, yêu cầu model trả về JSON có cấu trúc: loại nguồn, số tiền, ngày giờ, cửa hàng/nội dung, danh mục gợi ý, loại thu/chi, độ tin cậy — gộp luôn bước "nhận diện nguồn" (mục 10.3) vào cùng 1 lần gọi thay vì tách riêng như nhánh rule-based.
- Nếu LLM lỗi/timeout khi đang suy luận (hết bộ nhớ, bị hệ điều hành thu hồi tài nguyên...) → tự động chuyển sang bộ phân tích rule-based **cho riêng lần quét đó**, không làm gián đoạn trải nghiệm, có ghi chú `engine_used = "rule_based"` để biết đây là lần bị fallback.
- Gemma 3n E2B sau khi tải về hoạt động **hoàn toàn offline**, không cần mạng lại trừ khi xoá và tải lại; Gemini Nano hoạt động qua module hệ thống nên không phát sinh lưu lượng mạng từ phía app.

### 11.5. Cập nhật Cài đặt (mục 5)
Trong Cài đặt > Quét hóa đơn AI > mục "Trạng thái AI Local", hiển thị:
- Tier hiện tại (A/B/C) và model đang dùng (Gemini Nano / Gemma 3n E2B / Chế độ cơ bản).
- Với Tier B: dung lượng model đã chiếm (VD: "Gemma 3n E2B — 1.8GB"), nút "Xoá model" (giải phóng dung lượng, quay về Chế độ cơ bản, có thể tải lại sau) và nút "Kiểm tra cập nhật model".
- Nút "Kiểm tra lại cấu hình máy" — chạy lại luồng ở mục 11.3.

### 11.6. Cập nhật cấu trúc dữ liệu
Bảng cài đặt cục bộ bổ sung:
```
device_check_result: {
  tier: "A" | "B" | "C",
  ram_gb: number,
  free_storage_gb: number,
  supports_aicore: boolean,
  supports_gpu_delegate: boolean,
  checked_at: datetime
}
ai_engine_mode: "gemini_nano" | "gemma_3n_e2b" | "rule_based"   // engine đang active, suy ra từ tier
```

### 11.7. Cập nhật danh sách màn hình thiết kế
10. `scan-10-device-check.svg` — Màn hình đang kiểm tra cấu hình máy + kết quả (đạt Tier A/B hoặc không đạt)
11. `scan-11-settings-ai-status.svg` — Cập nhật màn Cài đặt: khối "Trạng thái AI Local" hiển thị Tier, model, dung lượng, nút kiểm tra lại
