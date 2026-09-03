---
name: sora-wiki
description: Tạo và duy trì wiki dự án theo pattern LLM-wiki — một bộ markdown liên kết chéo do LLM biên soạn và cập nhật dần từ nguồn tài liệu thô (raw sources), thay vì RAG truy xuất lại từ đầu mỗi lần hỏi. Dùng skill này khi user nhờ: tạo wiki mới cho dự án, thêm/ingest nguồn tài liệu vào wiki, hỏi hoặc tổng hợp kiến thức dựa trên wiki, kiểm tra sức khỏe wiki (lint), cập nhật index/log. Kích hoạt cả khi user chỉ nói "gắn vào wiki", "lưu vào knowledge base", "tóm tắt tài liệu này vào wiki", "wiki dự án", "hỏi gì đó từ tài liệu" — không cần gọi đích danh tên skill.
---

# sora-wiki

Skill biên soạn và bảo trì một **wiki bền vững (compounding)** cho dự án, theo tư tưởng LLM-wiki. Khác RAG: thay vì truy xuất lại từ tài liệu thô mỗi lần hỏi, bạn đọc nguồn mới, tích hợp kiến thức vào wiki — tạo/cập nhật page, ghi chú mâu thuẫn, thắt cross-reference. Kiến thức được biên soạn một lần rồi giữ mới, càng ngày càng đầy đủ.

Tài liệu tham khảo đầy đủ về tư tưởng: đọc `llm-wiki/workflow.md` khi cần bối cảnh hoặc muốn điều chỉnh thiết kế. SKILL.md này là phần vận hành.

## Ba tầng

- **Raw sources** — tài liệu gốc (bài viết, paper, transcript, data). Bất biến: LLM chỉ đọc, không sửa. Là nguồn sự thật.
- **The wiki** — markdown do LLM tạo/duy trì: summary page, entity page, concept page, so sánh, tổng hợp, index, log. LLM sở hữu toàn bộ tầng này.
- **The schema** — file `CLAUDE.md` nằm trong thư mục wiki, ghi rõ cấu trúc wiki, quy ước, workflow ingest/query/lint cho riêng domain này. Là file cấu hình then chốt: nó biến bạn thành người giữ wiki có kỷ luật thay vì chatbot generic.

Con người (user) lo: chọn nguồn, định hướng phân tích, hỏi đúng câu. Bạn lo: toàn bộ phần còn lại — tóm tắt, cross-reference, đối chiếu mâu thuẫn, cập nhật index/log.

## Định vị wiki

1. Tìm wiki root: thư mục có cả `index.md`, `log.md` và `CLAUDE.md` (chứa từ khóa LLM-wiki) chính là wiki. Tìm trong cwd và thư mục con `wiki/`. Nếu thấy nhiều, hỏi user chọn.
2. Nếu chưa có → **bootstrap** (bên dưới).

### Bootstrap wiki mới

Khi user muốn tạo wiki hoặc chưa tồn tại:

1. Hỏi vị trí wiki root (đề xuất `wiki/` trong project root nếu chưa rõ).
2. Tạo cấu trúc:
   - `wiki/raw/` — nơi chứa nguồn tài liệu
   - `wiki/index.md` — catalog toàn bộ page (mục "Index" bên dưới)
   - `wiki/log.md` — nhật ký theo dòng thời gian (mục "Log" bên dưới)
   - `wiki/CLAUDE.md` — schema: tự sinh bản tối thiểu, hỏi user vài câu để khớp domain (loại nguồn, loại page, output format hay dùng, Obsidian hay không). Mời user cùng tinh chỉnh khi wiki lớn dần.
3. Hỏi user có nguồn nào cần ingest ngay không; nếu có, chạy Ingest.
4. Ghi entry đầu tiên vào `log.md`.

## Thao tác cốt lõi

### Ingest

User đưa nguồn mới (file trong `raw/`, URL, hoặc nội dung dán). Quy trình:

1. **Đọc** source. Nếu là markdown có inline image, đọc text trước rồi xem từng ảnh tham chiếu để có thêm ngữ cảnh (LLM không đọc inline image trong một lần).
2. **Thảo luận** nhanh takeaway chính với user (ingest lẻ từng nguồn) — để user định hướng nhấn mạnh gì. Với batch nhiều nguồn, làm ít giám sát hơn.
3. **Viết summary page** cho nguồn.
4. **Cập nhật index.md** — thêm entry.
5. **Cập nhật các page liên quan** trên toàn wiki: entity/concept page có liên quan thì sửa synthesis, thêm cross-reference, và đánh dấu rõ khi dữ liệu mới mâu thuẫn claim cũ. Một nguồn có thể chạm 10-15 page — đừng bỏ qua.
6. **Append log.md**: `## [YYYY-MM-DD] ingest | <tiêu đề nguồn>`
7. Báo user các page đã đụng tới để họ duyệt.

### Query

User hỏi dựa trên kiến thức wiki:

1. **Đọc index.md trước**, chọn page liên quan, rồi đọc sâu vào page đó — không quét raw sources.
2. **Tổng hợp có citation** (trỏ về page nguồn).
3. Output format theo yêu cầu: page markdown, bảng so sánh, slide (Marp), chart (matplotlib), canvas — tự do.
4. Nếu câu trả lời có giá trị (một phân tích, một so sánh, một mối liên hệ) → **đề xuất file lại thành page mới trong wiki**, để khám phá tích lũy giống như nguồn ingest. Đừng để đáp án hay chìm vào chat history.

### Lint

User nhờ kiểm tra sức khỏe wiki. Quét và báo:

- Mâu thuẫn giữa các page.
- Claim lỗi thời mà nguồn mới hơn đã thay thế.
- Orphan page (không có inbound link).
- Khái niệm quan trọng được nhắc tới nhưng chưa có page riêng.
- Thiếu cross-reference.
- Data gap có thể lấp bằng web search.
- Đề xuất câu hỏi mới cần nghiên cứu và nguồn mới nên tìm.

Áp dụng các sửa được đồng ý, ghi log.

## Quy ước

### Page

- Markdown, có frontmatter YAML (title, date, tags, sources) — tương thích Obsidian Dataview.
- Mỗi page một entity/concept/chủ đề; không nhồi nhiều chủ đề vào một file.
- Tên file theo chủ đề, liên kết chéo bằng `[[Tên Page]]` (Obsidian) hoặc relative link.
- Nếu nguồn dùng ảnh, tải ảnh local vào `raw/assets/` để LLM đọc được và không phụ thuộc URL hỏng.

### Index

Catalog theo category (entities, concepts, sources...), mỗi page một dòng:

```markdown
## Concepts
- [[TCP Backoff]] — giải thích exponential backoff và vì sao dùng
```

### Log

Append-only, prefix chuẩn để quét được bằng unix tool (`grep "^## \[" log.md | tail -5`):

```markdown
## [2026-08-14] ingest | Bài: Vì sao TCP giảm tốc độ
```

## Lưu ý

- Wiki là git repo của markdown — được version history, branch, collaboration miễn phí. Git commit theo nhịp cập nhật wiki.
- Không sửa raw sources. Chỉ đọc.
- Khi gặp điều gì chưa rõ về cấu trúc domain, đọc `CLAUDE.md` trong wiki root trước khi quyết định.
