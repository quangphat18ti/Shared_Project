# Terminal & UI Tools Integration with Local AI Models

Hướng dẫn tích hợp AI Assistant vào các công cụ phát triển Backend phổ biến, sử dụng Ollama làm engine chạy locally.

## Mục lục

- [Terminal Tools](#terminal-tools)
  - [Shell GPT](#shell-gpt)
  - [Ollama CLI](#ollama-cli)
  - [OhMyZsh AI Plugin](#ohmyzsh-ai-plugin)
- [IDE & Editor Integration](#ide--editor-integration)
  - [VS Code Extensions](#vs-code-extensions)
  - [Neovim Integration](#neovim-integration)
- [Database Tools](#database-tools)
  - [MongoDB Compass AI](#mongodb-compass-ai)
  - [Database Query Optimization](#database-query-optimization)
- [API Development](#api-development)
  - [Postman Integration](#postman-integration)
  - [Swagger AI Assistant](#swagger-ai-assistant)
- [Git Tools](#git-tools)
  - [Git Copilot CLI](#git-copilot-cli)
  - [Commit Message Assistant](#commit-message-assistant)

## Terminal Tools

### Shell GPT

Shell-GPT là công cụ giúp bạn tương tác với AI Assistant ngay trong terminal.

#### Cài đặt

```bash
pip install shell-gpt
```

#### Cấu hình với Ollama

```bash
# Tạo file config
mkdir -p ~/.config/shell-gpt
cat > ~/.config/shell-gpt/config.yaml << EOF
model: codellama
provider: ollama
api_base: http://localhost:11434
EOF
```

#### Sử dụng

```bash
# Generate shell commands
sgpt "create a new Go project with MongoDB"

# Giải thích command
sgpt "explain: docker ps -a --format '{{.Names}}: {{.Status}}'"

# Debug errors
sgpt "fix error: context deadline exceeded in MongoDB connection"
```

### Ollama CLI

Sử dụng Ollama CLI để quản lý và tương tác với models.

```bash
# List models
ollama list

# Chat với model
ollama run codellama

# Execute prompt
ollama run codellama "Optimize this Go function:
func getData(ctx context.Context, id string) (*Data, error) {
    return repo.FindById(id)
}"
```

### OhMyZsh AI Plugin

Tích hợp AI vào ZSH shell.

#### Cài đặt

```bash
# Clone plugin
git clone https://github.com/TamCore/oh-my-zsh-ai ~/.oh-my-zsh/custom/plugins/ai

# Enable trong ~/.zshrc
plugins=(... ai)
```

#### Sử dụng

```bash
# Ask AI
ai "how to profile Go application memory usage"

# Generate commands
ai "create docker network for MongoDB replica set"
```

## IDE & Editor Integration

### VS Code Extensions

1. **Continue** - AI Assistant sử dụng Ollama
   - Đã setup ở phần trước
   - Shortcuts:
     - `Cmd/Ctrl + L`: Mở Continue sidebar
     - `Cmd/Ctrl + I`: Inline edit
     - `/`: Custom commands

2. **MongoDB for VS Code**
   - Features:
     - Query intelligence
     - Schema suggestions
     - Index recommendations
   - Integration với Continue:
     ```yaml
     # Trong config.yaml
     customCommands:
       - name: optimize-query
         description: "Optimize MongoDB query"
         prompt: |
           Analyze and optimize this MongoDB query:
           {{{ input }}}
     ```

3. **Thunder Client + AI**
   - API testing với AI assistance
   - Tự động generate tests
   - Response validation

### Neovim Integration

Tích hợp Ollama vào Neovim thông qua plugins.

```lua
-- Init.lua
require('ollama').setup({
    url = "http://localhost:11434",
    model = "codellama"
})
```

## Database Tools

### MongoDB Compass AI

Tích hợp AI vào MongoDB Compass để tối ưu queries.

#### Cấu hình

1. Cài đặt MongoDB Compass
2. Enable AI Features
3. Connect với Ollama:
   ```json
   {
     "ai_endpoint": "http://localhost:11434",
     "model": "codellama"
   }
   ```

#### Features

- Query suggestions
- Index recommendations
- Aggregation pipeline builder
- Schema optimization

### Database Query Optimization

Sử dụng AI để tối ưu queries:

```bash
# Via Continue
/optimize-mongo "db.users.aggregate([
  {$match: {status: 'active'}},
  {$lookup: {from: 'orders',...}},
  {$sort: {createdAt: -1}}
])"

# Via Shell-GPT
sgpt "optimize mongodb query: db.users.find({email: {$regex: '@gmail.com'}})"
```

## API Development

### Postman Integration

Tích hợp AI vào Postman workflow.

1. Cài đặt Postman AI Extension
2. Configure Ollama endpoint
3. Features:
   - Test generation
   - Schema validation
   - Documentation generation
   - Response analysis

### Swagger AI Assistant

Generate và maintain API documentation với AI.

```bash
# Generate OpenAPI spec
sgpt "generate openapi spec for Go HTTP handler:
func CreateUser(w http.ResponseWriter, r *http.Request) {
    // ...
}"

# Validate Swagger
/validate-swagger "openapi: 3.0.0..."
```

## Git Tools

### Git Copilot CLI

Tool CLI cho Git operations với AI assistance.

#### Cài đặt

```bash
npm install -g @gitcop/cli
```

#### Cấu hình Ollama

```bash
gitcop config set model codellama
gitcop config set endpoint http://localhost:11434
```

#### Sử dụng

```bash
# Generate commit message
gitcop commit

# Explain changes
gitcop explain

# Review PR
gitcop review
```

### Commit Message Assistant

Tích hợp AI vào Git commit workflow.

1. Cài đặt Git hook:
```bash
#!/bin/bash
# .git/hooks/prepare-commit-msg

# Get staged changes
DIFF=$(git diff --cached)

# Generate commit message
MSG=$(ollama run codellama "Generate commit message for changes:
$DIFF")

# Update commit message
echo "$MSG" > "$1"
```

2. Sử dụng:
```bash
chmod +x .git/hooks/prepare-commit-msg
git commit # AI sẽ tự generate message
```

## Best Practices

1. **Performance**
   - Cache kết quả AI responses
   - Sử dụng lightweight models cho tasks đơn giản
   - Batch requests khi có thể

2. **Security**
   - Không gửi sensitive data tới AI
   - Review AI suggestions trước khi apply
   - Giới hạn AI access tới codebase

3. **Development Workflow**
   - Sử dụng AI cho tasks lặp lại
   - Code review với AI assistance
   - Document AI decisions

4. **Model Selection**
   - CodeLlama: Code generation & analysis
   - DeepSeek: Architecture & optimization
   - Qwen: Quick completions & reviews

## Troubleshooting

Common issues và solutions:

1. **Ollama Connection**
   ```bash
   # Check Ollama service
   curl http://localhost:11434/api/tags
   
   # Restart service
   ollama serve
   ```

2. **Model Loading**
   ```bash
   # Pull model lại
   ollama pull codellama
   
   # Clear cache
   ollama rm codellama
   ollama pull codellama
   ```

3. **Integration Issues**
   - Check endpoints trong config
   - Verify model availability
   - Review error logs

## Resources

- [Ollama Documentation](https://ollama.ai/docs)
- [Shell-GPT Guide](https://github.com/TheR1D/shell_gpt)
- [Continue Docs](https://continue.dev/docs)
- [MongoDB AI Features](https://www.mongodb.com/products/platform/ai)
- [VS Code Extensions](https://marketplace.visualstudio.com)

## Updates & Maintenance

Để update tools và models:

```bash
# Update Ollama
curl https://ollama.ai/install.sh | sh

# Update models
ollama pull codellama:latest
ollama pull deepseek-coder:latest

# Update Shell-GPT
pip install --upgrade shell-gpt

# Update Continue
code --install-extension continue.continue --force
```

---

**Note**: Điều chỉnh các config và commands theo environment và requirements cụ thể của project.
