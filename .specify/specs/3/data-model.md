# Mô hình dữ liệu: Khóa ứng dụng bằng mã PIN

**Mã PBI**: 3

Thực thể duy nhất từ spec: **Mã PIN thiết bị** — trạng thái bảo mật gắn với 1 bản cài đặt app trên 1 thiết bị, **độc lập với dữ liệu ví/giao dịch** (thiết lập/mở khóa không đụng dữ liệu tài chính). Không phải entity drift; lưu qua `flutter_secure_storage` (xem `research.md`).

## Lưu trữ (2 key trong flutter_secure_storage)

### 1. Bí mật PIN — key `pin_salt_hash`
| Trường | Kiểu | Mô tả |
|---|---|---|
| `salt` | base64 (16 byte ngẫu nhiên) | muối cho hash |
| `hash` | base64(SHA-256(salt + pin)) | không lưu PIN dạng đọc được (FR-011) |

Giá trị lưu dạng chuỗi `"{saltB64}.{hashB64}"`. Key **tồn tại** = mã PIN đã được thiết lập xong (ghi **một lần duy nhất**, khi 2 lần nhập khớp ở luồng thiết lập). Không có luồng xóa PIN trong đợt này (không tắt khóa).

### 2. Trạng thái chống dò — key `lock_state` (JSON 1 dòng)
| Trường | Kiểu | Mô tả |
|---|---|---|
| `streak` | int | số lần thử **sai hoàn chỉnh** liên tiếp, chưa có lần đúng nào xen giữa |
| `lockUntilEpochMs` | int \| null | mốc hết thời gian chặn (epoch ms giờ thiết bị); `null` = không bị chặn |

## Luật & chuyển trạng thái

Ladder chặn: `[30s, 1p, 5p, 15p]` (ms: `30000, 60000, 300000, 900000`), trần 15p.

| Sự kiện | Điều kiện | Hành động |
|---|---|---|
| Thiết lập hoàn tất | lần 1 == lần 2 (đủ 4 số) | ghi `pin_salt_hash`; `streak=0`, `lockUntil=null`; phiên mở, vào app |
| Thiết lập lệch | lần 2 != lần 1 | báo lỗi, **chưa ghi gì**; nhập lại từ đầu (thoát app giữa chừng → không có key → lần sau vẫn bắt thiết lập) |
| PIN yếu được xác nhận | PIN ∈ dãy dễ đoán + user chọn "Tiếp tục" | như thiết lập hoàn tất (không chặn cứng) |
| Mở khóa đúng | hash khớp | `streak=0`, `lockUntil=null`; pop màn khóa → đúng màn trước khi khóa |
| Mở khóa sai (đủ 4 số) | sai hoàn chỉnh | `streak += 1`; nếu `streak >= 5` → `lockUntil = now + ladder[min(streak - 5, 3)]`; báo "mã PIN không đúng" chung, xóa ký tự đã nhập |
| Chưa đủ 4 số | người dùng còn gõ | **không** tăng streak, không kiểm tra |
| Đang bị chặn | `now < lockUntil` | keypad khóa cứng, hiện đếm ngược; hết chặn chỉ **mở lại nhập**, không tự mở khóa |
| Khởi động app giữa chừng bị chặn | đọc lại từ store | `lockUntil` còn hiệu lực → tiếp tục chặn (đếm ngược phần còn lại) |
| Đổi giờ hệ thống | — | rủi ro chấp nhận (xem `research.md` Quyết định 5) |

## Quy tắc nhập (dùng chung màn thiết lập & màn khóa)
- Nhập tối đa 4 ký tự số; hiển thị dạng chấm tròn, không lộ chữ số (FR-003).
- Backspace xóa ký tự cuối; chỉ xử lý khi đủ 4 số.
- Chuỗi sai chỉ tính khi gõ trọn 4 số rồi kiểm tra.

## Quan hệ
- Không liên kết với thực thể tài chính nào (ví/giao dịch/danh mục/ngân sách).
- Độc lập với hồ sơ cá nhân; sinh trắc học (PBI sau) là lớp bổ sung phía trên PIN, không đổi mô hình này.
