# Hướng Dẫn Sử Dụng Terminal AI Tools với Ollama

Hướng dẫn chi tiết về cách tích hợp và sử dụng các công cụ terminal AI với Ollama local models.

## 1. OTerm - Terminal UI cho Ollama

OTerm là một terminal UI đơn giản và hiệu quả để tương tác với Ollama models.

### Cài đặt

```bash
# Clone repository
git clone https://github.com/ggozad/oterm.git
cd oterm

# Cài đặt dependencies (yêu cầu Python ≥ 3.10)
pip install -r requirements.txt

# Hoặc cài đặt trực tiếp từ PyPI
pip install oterm
```

### Cấu hình

1. **Tạo file cấu hình**

```bash
mkdir -p ~/.config/oterm
cat > ~/.config/oterm/config.yaml << EOF
ollama_host: http://localhost:11434
default_model: codellama
models:
  - codellama
  - qwen2.5-coder
  - deepseek-coder
  - llama3.1
history_file: ~/.local/share/oterm/history.json
EOF
```

2. **Cấu hình model-specific settings**

```yaml
# ~/.config/oterm/config.yaml
model_configs:
  codellama:
    context_size: 4096
    temperature: 0.7
    top_p: 0.9
  qwen2.5-coder:
    context_size: 2048
    temperature: 0.5
```

### Sử dụng Cơ bản

1. **Khởi động OTerm**

```bash
oterm
```

2. **Commands trong OTerm**

```
/model codellama    # Chuyển đổi model
/clear             # Xóa chat history
/save filename     # Lưu conversation
/load filename     # Load conversation
/exit              # Thoát OTerm
/help              # Xem tất cả commands
```

### Tips Sử dụng

1. **Code Generation**
```
/model codellama
> Generate a Go struct for User with MongoDB BSON tags
```

2. **Context Switching**
```
/model qwen2.5-coder  # For code review
> Review this code for security issues:
[paste code here]

/model deepseek-coder  # For architecture suggestions
> Suggest microservices architecture for an e-commerce system
```

3. **Custom Prompts**
```bash
# Tạo alias trong ~/.zshrc hoặc ~/.bashrc
alias code-review='oterm --model codellama --prompt "Review this code for:\n- Performance\n- Security\n- Best practices\n\nCode:\n"'
```

### Troubleshooting OTerm

1. **Connection Issues**
```bash
# Kiểm tra Ollama service
curl http://localhost:11434/api/tags

# Kiểm tra log
tail -f ~/.local/share/oterm/oterm.log
```

2. **Model Loading**
```bash
# Verify model availability
ollama list

# Pull model if needed
ollama pull codellama
```

## 2. Parllama - CLI Tool cho Local LLMs

Parllama là một CLI tool mạnh mẽ để tương tác với Local LLMs thông qua terminal.

### Cài đặt

```bash
# Clone repository
git clone https://github.com/paulrobello/parllama.git
cd parllama

# Install dependencies
pip install -e .
```

### Cấu hình

1. **Initial Setup**

```bash
# Tạo config directory
mkdir -p ~/.config/parllama

# Tạo file config
cat > ~/.config/parllama/config.yaml << EOF
api:
  endpoint: http://localhost:11434
  timeout: 30

default_model: codellama
models:
  codellama:
    context_length: 4096
    temperature: 0.7
  qwen2.5-coder:
    context_length: 2048
    temperature: 0.5

output:
  format: markdown
  syntax_highlight: true
  
history:
  enabled: true
  path: ~/.local/share/parllama/history
EOF
```

2. **Custom Prompts Configuration**

```yaml
# ~/.config/parllama/prompts.yaml
prompts:
  code-review:
    template: |
      Review this code for:
      1. Performance issues
      2. Security vulnerabilities
      3. Best practices
      4. Error handling
      
      Code:
      {code}
    
  optimize-mongo:
    template: |
      Optimize this MongoDB query for performance:
      {query}
```

### Sử Dụng Cơ bản

1. **Quick Commands**

```bash
# Chat mode
parllama chat

# Single query
parllama ask "Write a Go function to connect to MongoDB"

# Code review
parllama review "path/to/file.go"
```

2. **Advanced Features**

```bash
# Stream mode (real-time responses)
parllama --stream ask "Explain ACID properties"

# Using different models
parllama --model qwen2.5-coder ask "Optimize this function"

# Save output
parllama ask "Create API documentation" --save docs.md
```

### Shell Integration

1. **Alias Setup**

```bash
# Add to ~/.zshrc or ~/.bashrc
alias pll='parllama'
alias plr='parllama review'
alias pla='parllama ask'
alias plc='parllama chat'
```

2. **Function Integration**

```bash
# Add to ~/.zshrc or ~/.bashrc
function review() {
    parllama review "$1" --model codellama
}

function optimize() {
    parllama --model qwen2.5-coder ask "Optimize this code: $(cat "$1")"
}
```

### Use Cases

1. **Code Review Workflow**
```bash
# Review single file
plr path/to/file.go

# Review git changes
git diff | pla "Review these changes"
```

2. **Database Operations**
```bash
# Optimize queries
echo "db.users.find({status: 'active'}).sort({created: -1})" | \
pla "Optimize this MongoDB query"

# Generate indexes
pla "Suggest indexes for this schema: $(cat schema.json)"
```

3. **Documentation**
```bash
# Generate API docs
plc --model codellama --prompt "Generate API documentation for:"

# Update README
pla "Update this README with new features: $(cat README.md)"
```

### Troubleshooting Parllama

1. **Common Issues**

```bash
# Reset configuration
rm -rf ~/.config/parllama/*
parllama --init

# Debug mode
parllama --debug ask "Your query"

# Check logs
tail -f ~/.local/share/parllama/parllama.log
```

2. **Performance Issues**
```bash
# Clear cache
parllama cache clear

# Reduce context length
parllama --context 1024 ask "Your query"
```

## Tích Hợp Cả Hai Tools

### Workflow Example

1. **Code Development**
```bash
# Use OTerm for interactive development
oterm --model codellama

# Use Parllama for quick queries
pla "Write a unit test for this function"
```

2. **Code Review Process**
```bash
# Initial review with OTerm
oterm --model deepseek-coder

# Detailed analysis with Parllama
plr path/to/file.go --detailed
```

### Performance Tips

1. **Model Selection**
- CodeLlama: Code generation & review
- Qwen2.5-coder: Quick completions
- Deepseek-coder: Architecture & optimization

2. **Resource Usage**
```bash
# Monitor resource usage
htop

# Check Ollama memory
ps aux | grep ollama
```

## Maintenance

### Updates

```bash
# Update OTerm
pip install --upgrade oterm

# Update Parllama
cd path/to/parllama
git pull
pip install -e .

# Update Ollama models
ollama pull codellama:latest
ollama pull qwen2.5-coder:latest
```

### Cleanup

```bash
# Clear history
rm ~/.local/share/oterm/history.json
parllama cache clear

# Reset configurations
rm -rf ~/.config/oterm
rm -rf ~/.config/parllama
```

## Resources

- [OTerm GitHub](https://github.com/ggozad/oterm)
- [Parllama GitHub](https://github.com/paulrobello/parllama)
- [Ollama Documentation](https://ollama.ai/docs)
