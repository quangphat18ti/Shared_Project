# OpenAI Codex Tutorial

Hướng dẫn nhanh để dùng Codex cho workflow lập trình hằng ngày: hỏi về codebase, sửa code, review, chạy command, và đẩy task dài hơn lên cloud.

## Mục lục

- [Codex là gì](#codex-là-gì)
- [Chuẩn bị](#chuẩn-bị)
- [Cài đặt Codex CLI](#cài-đặt-codex-cli)
- [Đăng nhập](#đăng-nhập)
- [Dùng Codex trong terminal](#dùng-codex-trong-terminal)
- [Chế độ làm việc](#chế-độ-làm-việc)
- [Approval và sandbox](#approval-và-sandbox)
- [Cấu hình cơ bản](#cấu-hình-cơ-bản)
- [Customize Codex cho backend dev](#customize-codex-cho-backend-dev)
- [Dùng Codex với IDE](#dùng-codex-với-ide)
- [Codex cloud tasks](#codex-cloud-tasks)
- [Prompt mẫu](#prompt-mẫu)
- [Best practices](#best-practices)
- [Xử lý lỗi thường gặp](#xử-lý-lỗi-thường-gặp)
- [Tài liệu tham khảo](#tài-liệu-tham-khảo)

## Codex là gì

Codex là coding agent của OpenAI, có thể đọc codebase, đề xuất kế hoạch, sửa file, chạy command, review thay đổi, và hỗ trợ debug. Bạn có thể dùng Codex qua ChatGPT app, IDE extension, terminal CLI, hoặc cloud tasks.

## Chuẩn bị

- Tài khoản ChatGPT/OpenAI có quyền dùng Codex.
- Node.js và npm nếu muốn dùng Codex CLI.
- Git repo local nếu muốn Codex đọc/sửa code theo context.
- Project có test/lint rõ ràng để Codex có thể verify sau khi sửa.

Kiểm tra nhanh:

```bash
node --version
npm --version
git status
```

## Cài đặt Codex CLI

Cài đặt CLI bằng npm:

```bash
npm install -g @openai/codex
```

Kiểm tra:

```bash
codex --version
```

Chạy Codex trong thư mục project:

```bash
cd path/to/your-project
codex
```

## Đăng nhập

Chạy:

```bash
codex login
```

Sau đó làm theo hướng dẫn trên trình duyệt. Nếu môi trường không mở được browser, CLI sẽ hiển thị cách đăng nhập thay thế.

## Dùng Codex trong terminal

Mở Codex tại root của repo:

```bash
codex
```

Ví dụ task:

```text
Explain the authentication flow in this repo and point me to the key files.
```

```text
Fix the failing user service tests. Keep the change minimal and run the relevant test command.
```

```text
Add validation for the create-order endpoint and update the nearest tests.
```

Với task lớn, yêu cầu Codex lập kế hoạch trước:

```text
Investigate how billing is implemented, then propose a concise implementation plan for adding coupon support. Do not edit files yet.
```

## Chế độ làm việc

Codex thường được dùng theo 3 kiểu:

1. Chat: hỏi đáp, giải thích code, không cần sửa file.
2. Plan: đọc codebase, điều tra bug, lập kế hoạch trước khi implement.
3. Agent: sửa file, chạy command, verify bằng test/lint.

Nên dùng Chat/Plan khi task chưa rõ scope. Dùng Agent khi yêu cầu đã rõ và có cách verify.

## Approval và sandbox

Codex CLI có cơ chế approval và sandbox để kiểm soát hành động:

- File edits nên nằm trong workspace hiện tại.
- Lệnh có network, ghi ra ngoài workspace, hoặc có rủi ro cao có thể cần approval.
- Không yêu cầu Codex chạy lệnh phá hủy như `git reset --hard` nếu chưa chắc chắn.
- Đọc kỹ diff trước khi commit.

Khi prompt, nói rõ giới hạn:

```text
Only edit files under internal/user/. Do not change public API behavior. Run the user package tests.
```

## Cấu hình cơ bản

Codex CLI sử dụng file config trong thư mục home của Codex. Các tùy chọn có thể thay đổi theo phiên bản, vì vậy nên tham khảo docs chính thức trước khi chia sẻ config cho team.

Ví dụ các loại cấu hình thường gặp:

- Model mặc định.
- Mức reasoning.
- Sandbox mode.
- Approval policy.
- Project instructions.
- MCP/tool integrations.

Codex có thể đọc config ở nhiều tầng:

- User config: `~/.codex/config.toml`, dùng cho preference cá nhân.
- Project config: `.codex/config.toml`, dùng cho repo cụ thể và chỉ load khi project được trust.
- CLI flags hoặc `--config`, dùng cho override tạm thời.

Ví dụ config cá nhân cho backend dev:

```toml
# ~/.codex/config.toml
model = "gpt-5.5"
model_reasoning_effort = "medium"
model_verbosity = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
web_search = "cached"
file_opener = "vscode"

[sandbox_workspace_write]
network_access = false
```

Không nên bật `sandbox_mode = "danger-full-access"` hoặc `approval_policy = "never"` cho repo production, trừ khi bạn đang chạy trong môi trường cô lập.

---
## Customize Codex cho backend dev

Codex dùng `AGENTS.md` để nhận instructions bền vững cho project, tương tự `CLAUDE.md` trong Claude Code hoặc file rules/instructions trong Cursor. Đây là nơi bạn mô tả cách team build, test, review, migrate database, xử lý API contract, và những giới hạn không được phá.

### Cách Codex đọc instructions

Codex đọc instructions khi bắt đầu session:

1. Global: `~/.codex/AGENTS.override.md` nếu có, nếu không thì `~/.codex/AGENTS.md`.
2. Project: từ root repo xuống thư mục hiện tại, mỗi cấp đọc `AGENTS.override.md`, rồi `AGENTS.md`.
3. File gần thư mục làm việc hơn có độ ưu tiên cao hơn vì được ghép vào sau.

Nên dùng:

- `~/.codex/AGENTS.md`: phong cách làm việc cá nhân của bạn.
- `AGENTS.md` ở root repo: quy ước chung của team.
- `services/payment/AGENTS.md` hoặc `AGENTS.override.md`: rule riêng cho service/module nhạy cảm.

Kiểm tra Codex đã load instruction nào:

```bash
codex --ask-for-approval never "Summarize the current instructions and list the instruction files you loaded."
```

### Global AGENTS.md cho cá nhân

Tạo file:

```bash
mkdir -p ~/.codex
touch ~/.codex/AGENTS.md
```

Nội dung gợi ý:

```markdown
# Personal Codex Instructions

## Communication

- Trả lời ngắn gọn, trực tiếp, ưu tiên thông tin có thể hành động.
- Khi review code, đưa findings trước, sắp xếp theo mức độ nghiêm trọng.
- Khi thiếu context, tự đọc repo trước khi hỏi lại.

## Engineering style

- Ưu tiên thay đổi nhỏ, dễ review.
- Không thêm dependency production nếu chưa giải thích lý do và trade-off.
- Luôn nêu rõ test/lint đã chạy hoặc lý do không chạy được.
- Không sửa file unrelated.
- Không động vào secrets, `.env`, private keys, hoặc credential files.
```

### Repo AGENTS.md cho backend team

Đặt file `AGENTS.md` ở root repo:

```markdown
# AGENTS.md

## Project overview

- Đây là backend service. Ưu tiên correctness, maintainability, observability, và backward compatibility.
- Đọc `README.md`, docs trong `docs/`, và package/module gần task trước khi sửa.
- Giữ thay đổi nhỏ, đúng scope task. Không refactor rộng nếu không cần.

## Architecture rules

- Tôn trọng layer hiện có: handler/controller -> service/usecase -> repository/client.
- Business logic không đặt trực tiếp trong HTTP handler nếu project đã có service/usecase layer.
- Không bỏ qua validation, authorization, idempotency, transaction boundary, timeout, hoặc context cancellation.
- Không thay đổi public API contract nếu task không yêu cầu.
- Với breaking change, phải cập nhật docs, migration notes, và tests liên quan.

## Database and migrations

- Không sửa migration đã chạy ở production. Tạo migration mới.
- Migration phải có hướng rollback nếu project đang dùng rollback.
- Với schema/index change, nêu rõ ảnh hưởng tới dữ liệu hiện có và query plan.
- Không chạy destructive SQL trên dữ liệu thật.

## API and contracts

- Giữ response shape tương thích ngược.
- Validate request ở boundary.
- Trả lỗi theo format hiện có của project.
- Cập nhật OpenAPI/proto/schema nếu API contract thay đổi.

## Testing

- Chạy test gần nhất trước, sau đó mở rộng nếu thay đổi có rủi ro cross-module.
- Với bug fix, thêm regression test nếu có thể.
- Với code có concurrency, transaction, retry, cache, auth, hoặc money flow, ưu tiên test edge cases.
- Nếu không chạy được test, ghi rõ command đã thử và lỗi/blocker.

## Observability

- Log phải có context đủ để debug nhưng không log secrets hoặc PII.
- Với flow quan trọng, cân nhắc metrics/tracing theo convention hiện có.

## Security

- Không hard-code secrets.
- Không log token, password, API key, session, hoặc full authorization header.
- Kiểm tra authorization khi thêm/sửa endpoint.
- Với input từ user, kiểm tra injection, path traversal, SSRF, và unsafe deserialization nếu liên quan.

## Git workflow

- Trước khi sửa, kiểm tra worktree để tránh ghi đè thay đổi của người khác.
- Không revert thay đổi unrelated.
- Không chạy destructive command như `git reset --hard`, `git clean -fd`, hoặc xóa migration nếu chưa được yêu cầu rõ.
```

### AGENTS.md theo từng service

Với mono-repo hoặc backend nhiều service, thêm instructions gần module:

```text
repo-root/
  AGENTS.md
  services/
    payment/
      AGENTS.md
    user/
      AGENTS.md
```

Ví dụ `services/payment/AGENTS.md`:

```markdown
# Payment Service Instructions

- Đây là service nhạy cảm về tiền. Ưu tiên correctness hơn tốc độ.
- Không thay đổi rounding, currency handling, idempotency key, hoặc retry behavior nếu task không yêu cầu.
- Mọi thay đổi liên quan charge/refund phải có test cho duplicate request, timeout, provider error, và partial failure.
- Không log card data, payment token, provider secret, hoặc full webhook payload nếu payload có PII.
- Chạy `make test-payment` sau khi sửa payment code.
```

### Dùng fallback filename nếu repo đã có file khác

Nếu repo đã có `CLAUDE.md`, `Agent.md`, hoặc `TEAM_GUIDE.md`, bạn có thể cấu hình Codex đọc như instruction fallback:

```toml
# ~/.codex/config.toml
project_doc_fallback_filenames = ["CLAUDE.md", "Agent.md", "TEAM_GUIDE.md"]
project_doc_max_bytes = 65536
```

Thứ tự đọc ở mỗi thư mục sẽ là `AGENTS.override.md`, `AGENTS.md`, rồi các fallback filename ở trên. Dù vậy, nếu team dùng Codex lâu dài, nên tạo `AGENTS.md` riêng để tránh trộn rule của nhiều agent khác nhau.

### Rules cho command approval

Rules dùng để kiểm soát command nào được chạy ngoài sandbox. Ví dụ cho phép test/lint quen thuộc nhưng vẫn prompt với lệnh deploy:

```text
# ~/.codex/rules/default.rules
prefix_rule(
    pattern = ["go", "test"],
    decision = "allow",
    justification = "Go tests are safe for local backend verification",
    match = ["go test ./...", "go test ./internal/user"],
)

prefix_rule(
    pattern = ["kubectl"],
    decision = "prompt",
    justification = "Cluster commands require explicit review",
    match = ["kubectl get pods"],
)

prefix_rule(
    pattern = ["rm", "-rf"],
    decision = "forbidden",
    justification = "Destructive deletion must be done manually by the developer",
    match = ["rm -rf build"],
)
```

Không nên allow rộng cho `bash -c`, `sh -c`, `python`, `node`, `rm`, `kubectl`, `terraform apply`, hoặc `docker system prune`.

### Backend prompt patterns chuyên nghiệp

Điều tra flow:

```text
Trace the request flow for POST /orders. Identify handler, validation, service logic, repository writes, external calls, transaction boundaries, and tests. Do not edit files yet.
```

Fix bug có kiểm soát:

```text
Investigate why duplicate payment webhooks create duplicate ledger entries. Find the root cause, make the smallest safe fix, add a regression test, and run the payment tests.
```

Thêm endpoint:

```text
Add GET /users/{id}/sessions. Follow existing handler/service/repository patterns, preserve error format, add authorization checks, update OpenAPI if present, and add focused tests.
```

Review thay đổi backend:

```text
Review the current diff as a senior backend engineer. Focus on correctness, API compatibility, data consistency, authz/authn, migrations, observability, concurrency, and missing tests. Findings first with file/line references.
```

Tối ưu performance:

```text
Analyze the slow user search path. Identify query patterns, indexes, N+1 calls, cache behavior, and timeout handling. Propose a plan before editing.
```

## Dùng Codex với IDE

Nếu dùng VS Code, Cursor, Windsurf, hoặc editor có terminal tích hợp:

1. Mở project root.
2. Mở terminal trong IDE.
3. Chạy `codex`.
4. Yêu cầu Codex sửa code và verify.
5. Review diff trong IDE.

Workflow đề xuất:

```text
Read the selected module, explain the current behavior, then implement the smallest change needed for the requested feature.
```

## Codex cloud tasks

Với task dài hơn, bạn có thể giao việc cho Codex trên cloud từ ChatGPT/Codex UI:

- Sửa bug có mô tả rõ.
- Implement feature trong repo đã kết nối.
- Review pull request.
- Chạy investigation và đề xuất patch.

Nên viết task cloud theo format:

```text
Goal:
Add pagination to the admin users endpoint.

Constraints:
- Preserve current response fields.
- Default page size: 20.
- Maximum page size: 100.

Verification:
- Add or update endpoint tests.
- Run the backend test suite for the users package.
```

## Prompt mẫu

### Hiểu codebase

```text
Map the request flow for creating an order. Include the main files, functions, and database writes.
```

### Fix bug

```text
Investigate why checkout returns 500 when the cart is empty. Find the root cause, make the smallest fix, and run the relevant tests.
```

### Thêm feature

```text
Add email validation to user registration. Match the existing validation style and update the nearest tests.
```

### Review code

```text
Review the current diff for bugs, regressions, and missing tests. Prioritize concrete findings with file and line references.
```

### Refactor

```text
Refactor the duplicated retry logic in the payment clients. Keep behavior unchanged and run existing payment tests.
```

### Viết test

```text
Add focused tests for the password reset expiry behavior. Do not rewrite unrelated tests.
```

## Best practices

- Mở Codex tại root của repo để agent thấy đủ context.
- Prompt nên có goal, constraints, và verification.
- Yêu cầu Codex đọc code trước với task phức tạp.
- Yêu cầu thay đổi nhỏ, reviewable.
- Chạy test gần nhất trước, test rộng hơn sau nếu có rủi ro.
- Commit riêng từng task.
- Không paste secrets vào prompt.
- Nếu output sai hướng, dừng lại và sửa prompt bằng yêu cầu cụ thể hơn.

## Xử lý lỗi thường gặp

### `codex: command not found`

Kiểm tra npm global bin có trong `PATH`:

```bash
npm bin -g
echo $PATH
```

Cài lại nếu cần:

```bash
npm install -g @openai/codex
```

### Không đăng nhập được

Thử lại:

```bash
codex logout
codex login
```

Nếu đang dùng terminal remote, copy login URL sang browser local nếu CLI yêu cầu.

### Codex không thấy đúng context

- Chạy `codex` tại project root.
- Đảm bảo file không bị ignore nếu cần agent đọc.
- Nói rõ file/module cần xem trong prompt.

### Command bị chặn approval

Đọc lý do CLI đưa ra. Nếu command hợp lý, approve trong UI/terminal. Nếu không chắc, yêu cầu Codex giải thích command trước:

```text
Explain why this command is needed and what files or services it can affect before running it.
```

## Tài liệu tham khảo

- OpenAI Codex docs: https://developers.openai.com/codex/
- Codex customization: https://developers.openai.com/codex/concepts/customization
- Codex AGENTS.md: https://developers.openai.com/codex/guides/agents-md
- Codex config basics: https://developers.openai.com/codex/config-basic
- Codex rules: https://developers.openai.com/codex/rules
- Codex CLI on npm: https://www.npmjs.com/package/@openai/codex
- OpenAI help center for Codex: https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started
