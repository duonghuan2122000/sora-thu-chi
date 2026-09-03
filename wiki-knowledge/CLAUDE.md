# CLAUDE.md — Wiki Knowledge Sora Thu Chi

Wiki kiểu LLM-wiki (compounding): kiến thức được biên soạn một lần từ nguồn thô, giữ mới, thắt cross-reference. Không phải RAG.

## Ba tầng

- **Raw sources** — bất biến, chỉ đọc. Nằm tại `../docs/` (đã version trong repo gốc). **Không copy vào wiki** (tránh hai bản lệch nhau); tài liệu này là nguồn sự thật. Nguồn mới dán tay/URL (không nằm `docs/`) → lưu `raw/`.
- **Wiki** — markdown do LLM duy trì trong thư mục này. Chia 2 loại page:
  - `entity/` — một thực thể nghiệp vụ (Ví, Giao dịch, Danh mục, Ngân sách, Hồ sơ/Bảo mật).
  - `concept/` — kiến thức xuyên module tổng hợp (nguyên tắc nghiệp vụ, lộ trình, stack, design system).
- **Schema** — chính file này.

## Quy ước page

- Frontmatter YAML: `title`, `date`, `tags`, `sources` (đường dẫn tương đối tới `../docs/...`).
- Liên kết chéo bằng wikilink `[[Tên Page]]` (Obsidian) — tên trùng tên file.
- Tiếng Việt có dấu. Viết dạng chốt: kernel kiến thức + ràng buộc + link chéo, không chép lại toàn văn doc thô.
- **Điểm mở / mâu thuẫn chưa chốt** giữa nguồn → đánh dấu `⚠ QUYẾT ĐỊNH MỞ` và gom vào [[Lộ trình phát triển]].
- Nguồn chứa mâu thuẫn claim cũ → sửa claim, ghi rõ nguồn mới thay thế.

## Thao tác

- **Ingest** nguồn mới: đọc → tạo/cập nhật page entity/concept liên quan → thêm cross-ref → append `log.md` → cập nhật `index.md`.
- **Query**: đọc `index.md` trước, vào page chọn lọc — không quét lại `docs/`.
- **Lint**: quét mâu thuẫn giữa page, orphan page (không inbound link), claim lỗi thời, thiếu cross-ref, `⚠ QUYẾT ĐỊNH MỞ` chưa đóng, data gap lấp bằng web.
- Sau mỗi đợt đổi: cập nhật `index.md` + append `log.md`.

## Đặc thù domain

- Ứng dụng **offline hoàn toàn**, không tài khoản server → không đăng nhập/đồng bộ; "bảo mật" = khóa app (PIN/sinh trắc) + mã hóa local.
- Trước khi trả lời về module nào, đối chiếu page entity + concept/nguyen-tac-nghiep-vu (nhiều ràng buộc lặp lại xuyên module).
