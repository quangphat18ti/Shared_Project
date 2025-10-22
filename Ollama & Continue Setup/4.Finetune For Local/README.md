# ⚡ Hướng Dẫn Mô Hình Nhẹ - Tối Ưu Autocomplete
## Chiến lược Local AI cho RTX 4060 8GB

---

## 🎯 Vấn đề của bạn

- **Qwen2.5-7B chạy chậm** trên RTX 4060 8GB
- **Cần autocomplete nhanh** (real-time)
- **GPU memory hạn chế** (8GB VRAM)
- **Deep analysis dùng Cloud AI** (Claude, GPT-4, v.v.)

## ✅ Giải pháp: Multi-Model Strategy

### Chiến lược phân tầng:

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 1: Ultra-Fast (Autocomplete & Quick Tasks)      │
│  Models: 1.3B - 3B                                      │
│  Response: < 100ms                                      │
│  VRAM: 1-3GB                                            │
└─────────────────────────────────────────────────────────┘
              ↓ (Nếu cần thêm context)
┌─────────────────────────────────────────────────────────┐
│  LAYER 2: Medium Speed (Chat & Review)                 │
│  Models: 3B - 7B                                        │
│  Response: 200-500ms                                    │
│  VRAM: 3-5GB                                            │
└─────────────────────────────────────────────────────────┘
              ↓ (Nếu cần deep analysis)
┌─────────────────────────────────────────────────────────┐
│  LAYER 3: Cloud AI (Architecture & Complex Tasks)      │
│  Models: Claude Sonnet, GPT-4, etc.                    │
│  Response: 1-3s                                         │
│  Cost: Pay per use                                      │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 So sánh Mô hình Nhẹ

### Performance Benchmark (RTX 4060 8GB)

| Model | Size | VRAM | Speed (tokens/s) | Quality | Use Case |
|-------|------|------|------------------|---------|----------|
| **qwen2.5-coder:1.5b** | 1.5B | ~1GB | ⚡⚡⚡⚡⚡ (50-80) | ⭐⭐⭐⭐ | **Autocomplete chính** |
| **deepseek-coder:1.3b** | 1.3B | ~1GB | ⚡⚡⚡⚡⚡ (60-100) | ⭐⭐⭐ | Ultra-fast fallback |
| **codegemma:2b** | 2B | ~1.5GB | ⚡⚡⚡⚡ (45-70) | ⭐⭐⭐⭐ | Google's lightweight |
| **starcoder2:3b** | 3B | ~2GB | ⚡⚡⚡⚡ (40-60) | ⭐⭐⭐⭐⭐ | **Best code quality** |
| **qwen2.5-coder:3b** | 3B | ~2.5GB | ⚡⚡⚡ (35-55) | ⭐⭐⭐⭐⭐ | **Chat + inline edit** |
| **phi3.5:3.8b** | 3.8B | ~3GB | ⚡⚡⚡ (30-50) | ⭐⭐⭐⭐ | Microsoft's efficient |
| qwen2.5-coder:7b | 7B | ~5.5GB | ⚡⚡ (20-35) | ⭐⭐⭐⭐⭐ | Slow on your machine |

### Recommendation Matrix

```
🎯 YOUR OPTIMAL SETUP:

Autocomplete (Tab):        qwen2.5-coder:1.5b     (1GB VRAM)
Inline Edit (Ctrl+I):      qwen2.5-coder:3b       (2.5GB VRAM)
Quick Chat:                starcoder2:3b          (2GB VRAM)
Code Completion:           starcoder2:3b          (2GB VRAM)
Ultra-Fast Explain:        deepseek-coder:1.3b    (1GB VRAM)
Embedding (Search):        nomic-embed-text       (274MB)

TOTAL VRAM nếu load hết: ~7-8GB (fit perfectly!)
```

---

## 🚀 Chi tiết từng Mô hình

### 1️⃣ **Qwen2.5-Coder 1.5B** - AUTOCOMPLETE KING

**Điểm mạnh:**
- ⚡ Cực kỳ nhanh (50-80 tokens/s)
- 💾 Chỉ dùng 1GB VRAM
- 🎯 Đủ thông minh cho autocomplete
- 🔄 Context 4K tokens (đủ cho hầu hết cases)

**Khi nào dùng:**
```
✅ Tab autocomplete trong VSCode
✅ Quick code completion
✅ Simple inline edits
✅ Generate boilerplate code
```

**Config tối ưu:**
```json
{
  "model": "qwen2.5-coder:1.5b",
  "completionOptions": {
    "temperature": 0.05,    // Rất thấp cho consistency
    "topP": 0.75,
    "topK": 20,             // Giảm để faster
    "numPredict": 128,      // Chỉ complete ngắn
    "numThread": 8,         // Tận dụng CPU
    "numGpu": 20            // Offload 1 phần lên GPU
  }
}
```

**Test command:**
```bash
# Test speed
time ollama run qwen2.5-coder:1.5b "complete this: func GetUser"

# Expected: < 1 second cho 50-100 tokens
```

---

### 2️⃣ **StarCoder2 3B** - CODE QUALITY CHAMPION

**Điểm mạnh:**
- 📝 Chất lượng code tốt nhất trong segment 3B
- 🎓 Train trên nhiều ngôn ngữ lập trình
- 🔧 Đặc biệt tốt cho code completion
- ⚡ Vẫn rất nhanh (40-60 tokens/s)

**Khi nào dùng:**
```
✅ Code completion với context phức tạp
✅ Generate functions với nhiều logic
✅ Refactoring suggestions
✅ Code transformation
```

**Example use case:**
```go
// Bạn gõ:
// Complete this CRUD handler for User

// StarCoder2 sẽ generate:
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var user User
    if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    // ... full implementation với error handling tốt
}
```

---

### 3️⃣ **Qwen2.5-Coder 3B** - BALANCED PERFORMER

**Điểm mạnh:**
- ⚖️ Balance tốt giữa speed và quality
- 💬 Tốt cho chat + coding
- 🔄 Context 16K tokens (khá lớn)
- 🧠 Hiểu Go và MongoDB tốt

**Khi nào dùng:**
```
✅ Quick chat về code
✅ Inline editing (Ctrl+I)
✅ Code review nhanh
✅ Explain code
✅ Generate với nhiều context
```

**Perfect for:**
```
Ctrl+I commands như:
- "Add error handling"
- "Add context timeout"  
- "Optimize this query"
- "Add validation"
```

---

### 4️⃣ **DeepSeek-Coder 1.3B** - ULTRA-FAST BACKUP

**Điểm mạnh:**
- 🚀 Nhanh nhất (60-100 tokens/s)
- 💾 Nhẹ nhất (1GB VRAM)
- 📦 Tốt cho simple tasks

**Khi nào dùng:**
```
✅ Ultra-fast explain
✅ Simple code generation
✅ Fallback khi GPU memory đầy
✅ Quick questions
```

**Giới hạn:**
- ⚠️ Quality thấp hơn Qwen/StarCoder
- ⚠️ Context nhỏ (4K)
- ⚠️ Không tốt cho complex logic

---

## ⚙️ Config Continue Tối Ưu

### VSCode Settings (settings.json)

```json
{
  // Continue extension settings
  "continue.enableTabAutocomplete": true,
  "continue.telemetryEnabled": false,
  
  // Disable conflicting extensions
  "github.copilot.enable": {
    "*": false
  },
  "tabnine.experimentalAutoImports": false,
  
  // Editor settings for better autocomplete UX
  "editor.quickSuggestions": {
    "other": true,
    "comments": false,
    "strings": false
  },
  "editor.suggestOnTriggerCharacters": true,
  "editor.acceptSuggestionOnCommitCharacter": true,
  "editor.tabCompletion": "on",
  "editor.wordBasedSuggestions": false,
  
  // Performance
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/node_modules/**": true,
    "**/.continue/**": false
  }
}
```

### Continue Config Strategy

```json
{
  "models": [
    {
      "title": "💬 Quick Chat (3B)",
      "provider": "ollama",
      "model": "qwen2.5-coder:3b",
      "description": "Fast chat for quick questions"
    },
    {
      "title": "🔧 Code Expert (3B)",
      "provider": "ollama", 
      "model": "starcoder2:3b",
      "description": "Best for code generation"
    },
    {
      "title": "⚡ Ultra Fast (1.3B)",
      "provider": "ollama",
      "model": "deepseek-coder:1.3b",
      "description": "Instant responses"
    }
  ],
  
  "tabAutocompleteModel": {
    "title": "Tab Complete",
    "provider": "ollama",
    "model": "qwen2.5-coder:1.5b",
    "completionOptions": {
      "temperature": 0.05,
      "numPredict": 128,
      "numThread": 8
    }
  }
}
```

---

## 🎮 Workflow Thực Tế

### Scenario 1: Viết Function Mới

```
Step 1: Gõ function signature + comment
        Model: qwen2.5-coder:1.5b (Tab autocomplete)
        Time: ~0.5s

Step 2: Nếu cần adjust logic
        Ctrl+I: "Add validation"
        Model: qwen2.5-coder:3b
        Time: ~1-2s

Step 3: Code review
        Command: /quick-review
        Model: qwen2.5-coder:3b
        Time: ~2-3s

Step 4: Deep architecture review (nếu cần)
        → Dùng Claude Cloud API
        Time: ~5s nhưng quality cao
```

### Scenario 2: Debug Code

```
Step 1: Quick explain error
        "@Terminal Why this error?"
        Model: deepseek-coder:1.3b
        Time: ~0.5s

Step 2: Nếu chưa rõ, chat detail
        Model: qwen2.5-coder:3b
        Time: ~2s

Step 3: Fix suggestion
        Ctrl+I: "Fix this error"
        Model: starcoder2:3b
        Time: ~1-2s
```

### Scenario 3: Autocomplete Workflow

```go
// Gõ comment và signature
// Function to fetch users from MongoDB with pagination

func GetUsers(ctx context.Context, page int, limit int) ([]User, error) {
    // [Nhấn Tab ở đây]
    
// Qwen 1.5B sẽ instant complete:
func GetUsers(ctx context.Context, page int, limit int) ([]User, error) {
    skip := (page - 1) * limit
    
    cursor, err := collection.Find(ctx, bson.M{}, options.Find().
        SetSkip(int64(skip)).
        SetLimit(int64(limit)))
    if err != nil {
        return nil, err
    }
    defer cursor.Close(ctx)
    
    var users []User
    if err := cursor.All(ctx, &users); err != nil {
        return nil, err
    }
    
    return users, nil
}
```

---

## 🔥 Tips & Tricks

### Tip 1: Concurrent Model Loading

```bash
# Load 2-3 models cùng lúc vào VRAM
# Ollama tự động manage memory

# Terminal 1
ollama run qwen2.5-coder:1.5b

# Terminal 2  
ollama run qwen2.5-coder:3b

# Terminal 3
ollama run starcoder2:3b

# Total VRAM: ~1GB + 2.5GB + 2GB = 5.5GB
# Còn ~2.5GB free cho system
```

### Tip 2: Keyboard Shortcuts Setup

**File: `.vscode/keybindings.json`**
```json
[
  {
    "key": "alt+1",
    "command": "continue.selectModel",
    "args": { "modelTitle": "Quick Chat (3B)" }
  },
  {
    "key": "alt+2", 
    "command": "continue.selectModel",
    "args": { "modelTitle": "Code Expert (3B)" }
  },
  {
    "key": "alt+3",
    "command": "continue.selectModel", 
    "args": { "modelTitle": "Ultra Fast (1.3B)" }
  },
  {
    "key": "ctrl+alt+c",
    "command": "continue.focusContinueInput"
  }
]
```

### Tip 3: Smart Model Selection Script

```bash
#!/bin/bash
# save as: ~/.local/bin/ai-switch

case "$1" in
  "fast")
    echo "🚀 Switching to Ultra-Fast mode"
    pkill -f "qwen2.5-coder:3b"
    ollama run qwen2.5-coder:1.5b &
    ;;
  "balanced")
    echo "⚖️ Switching to Balanced mode"
    pkill -f "qwen2.5-coder:1.5b"
    ollama run qwen2.5-coder:3b &
    ;;
  "quality")
    echo "💎 Switching to Quality mode"
    ollama run starcoder2:3b &
    ;;
  *)
    echo "Usage: ai-switch {fast|balanced|quality}"
    ;;
esac
```

### Tip 4: Monitor GPU Usage

```bash
# Real-time GPU monitoring
watch -n 1 nvidia-smi

# Or use this script
#!/bin/bash
while true; do
  clear
  echo "=== GPU Status ==="
  nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader
  echo ""
  echo "=== Ollama Models ==="
  ollama list
  sleep 2
done
```

### Tip 5: Preload Models at Startup

**Linux/Mac: `~/.bashrc` or `~/.zshrc`**
```bash
# Preload AI models on shell startup
if command -v ollama &> /dev/null; then
  # Check if Ollama is running
  if ! pgrep -x "ollama" > /dev/null; then
    ollama serve &
    sleep 2
  fi
  
  # Preload lightweight models
  (ollama run qwen2.5-coder:1.5b "test" > /dev/null 2>&1 &)
  (ollama run qwen2.5-coder:3b "test" > /dev/null 2>&1 &)
fi
```

---

## 📈 Performance Optimization

### CPU Optimization

```json
{
  "completionOptions": {
    "numThread": 8,        // Số CPU threads (i7-13620H có 10 cores)
    "numGpu": 25,          // Layers offload to GPU (balance CPU/GPU)
    "numa": false          // Disable NUMA trên laptop
  }
}
```

### Memory Management

```bash
# Config Ollama environment variables
export OLLAMA_NUM_PARALLEL=2        # Max 2 concurrent requests
export OLLAMA_MAX_LOADED_MODELS=3   # Keep max 3 models in VRAM
export OLLAMA_FLASH_ATTENTION=1     # Enable flash attention

# Add to ~/.bashrc or system environment
```

### Context Window Tuning

```
Small models nên giảm context để faster:

qwen2.5-coder:1.5b  → 2048 tokens  (autocomplete)
deepseek-coder:1.3b → 2048 tokens  (quick tasks)
starcoder2:3b       → 4096 tokens  (code gen)
qwen2.5-coder:3b    → 8192 tokens  (chat)
```

---

## 🎯 Benchmark Tests

### Test Script

```bash
#!/bin/bash
# test-models.sh

MODELS=("qwen2.5-coder:1.5b" "deepseek-coder:1.3b" "starcoder2:3b" "qwen2.5-coder:3b")
PROMPT="Complete this Go function: func GetUser(ctx context.Context, id string) (*User, error) {"

echo "=== Model Speed Benchmark ==="
for model in "${MODELS[@]}"; do
  echo ""
  echo "Testing: $model"
  time ollama run $model "$PROMPT" --verbose 2>&1 | grep "tokens per second"
done
```

### Expected Results (RTX 4060 8GB)

```
qwen2.5-coder:1.5b
  Speed: 50-80 tok/s
  Latency: 100-200ms
  VRAM: 1.2GB
  
deepseek-coder:1.3b
  Speed: 60-100 tok/s
  Latency: 80-150ms
  VRAM: 1.0GB
  
starcoder2:3b
  Speed: 40-60 tok/s
  Latency: 150-250ms
  VRAM: 2.1GB
  
qwen2.5-coder:3b
  Speed: 35-55 tok/s
  Latency: 200-300ms
  VRAM: 2.6GB
```

---

## 🚨 Common Issues & Solutions

### Issue 1: Autocomplete lag

**Symptoms:** Tab completion takes > 1s

**Solutions:**
```bash
# 1. Reduce context in Continue config
"maxPromptTokens": 512  # From 1024

# 2. Enable GPU layers
"numGpu": 30  # Increase from 20

# 3. Reduce prediction length
"numPredict": 64  # From 128

# 4. Check if other models running
ollama ps
# Kill unused models
```

### Issue 2: Out of Memory

**Symptoms:** CUDA out of memory error

**Solutions:**
```bash
# 1. Use smaller model
Switch to qwen2.5-coder:1.5b or deepseek-coder:1.3b

# 2. Reduce concurrent models
export OLLAMA_MAX_LOADED_MODELS=2

# 3. Monitor memory
nvidia-smi

# 4. Restart Ollama
pkill ollama && ollama serve
```

### Issue 3: Poor code quality

**Symptoms:** Generated code has bugs

**Solutions:**
```json
// 1. Increase temperature slightly
"temperature": 0.1  // From 0.05

// 2. Use better model for the task
Autocomplete: qwen2.5-coder:1.5b
Generation: starcoder2:3b
Chat: qwen2.5-coder:3b

// 3. Add more context
Use @Code, @Codebase in prompts
```

### Issue 4: Slow first response

**Symptoms:** First request takes 5-10s

**Solutions:**
```bash
# Preload models on startup
# Add to ~/.bashrc
ollama run qwen2.5-coder:1.5b "warm up" > /dev/null 2>&1 &

# Or use systemd service (Linux)
# /etc/systemd/system/ollama-preload.service
```

---

## 📊 Cost-Benefit Analysis

### Local AI (Small Models)

**Pros:**
- ✅ Free unlimited usage
- ✅ Fast response (< 1s)
- ✅ Privacy (code không ra khỏi máy)
- ✅ Offline working
- ✅ No API limits

**Cons:**
- ⚠️ Giới hạn GPU memory
- ⚠️ Quality thấp hơn GPT-4/Claude
- ⚠️ Không tốt cho complex reasoning

**Best for:**
- Autocomplete
- Simple code generation
- Quick refactoring
- Code completion
- Boilerplate generation

---

### Cloud AI (GPT-4, Claude, etc.)

**Pros:**
- ✅ Highest quality
- ✅ Best reasoning
- ✅ Large context (200K+)
- ✅ Multimodal (images, docs)

**Cons:**
- ⚠️ Cost per request
- ⚠️ Slower (network latency)
- ⚠️ Privacy concerns
- ⚠️ Requires internet

**Best for:**
- Architecture design
- Complex debugging
- Code review (deep)
- Learning new concepts
- System design

---

## 🎓 Recommended Workflow

### Daily Coding (95% of time)

```
1. Tab Autocomplete
   → qwen2.5-coder:1.5b (instant)

2. Inline Edit (Ctrl+I)
   → qwen2.5-coder:3b (fast)

3. Quick Chat
   → starcoder2:3b (balanced)

4. Simple Explain
   → deepseek-coder:1.3b (ultra-fast)
```

### Weekly Architecture Review (5% of time)

```
1. Design new feature
   → Claude Sonnet 4 (cloud)

2. Review complex logic
   → GPT-4 (cloud)

3. Learn new patterns
   → Claude + Web search
```

---

## 📝 Checklist Setup

### Phase 1: Download Models (Google Colab)
- [ ] Run Colab script để download
- [ ] Verify models trong Google Drive
- [ ] Download về máy local

### Phase 2: Import Models
- [ ] Run import script
- [ ] Verify với `ollama list`
- [ ] Test speed: `time ollama run qwen2.5-coder:1.5b "test"`

### Phase 3: Configure Continue
- [ ] Apply config.json
- [ ] Test tab autocomplete
- [ ] Test inline edit (Ctrl+I)
- [ ] Test custom commands

### Phase 4: Optimization
- [ ] Setup keyboard shortcuts
- [ ] Config VSCode settings
- [ ] Preload models script
- [ ] Monitor GPU usage

### Phase 5: Integrate Cloud AI (Optional)
- [ ] Setup Claude API in Continue
- [ ] Create hybrid workflow
- [ ] Test fallback scenarios

---

## 🎉 Expected Results

### Before (Qwen 7B only)
```
Autocomplete: 1-2s delay ❌
Inline Edit: 3-5s ❌
Chat: 5-10s ⚠️
GPU Usage: 80-90% 🔥
```

### After (Multi-model)
```
Autocomplete: 0.1-0.5s ✅
Inline Edit: 1-2s ✅
Chat: 2-3s ✅
GPU Usage: 40-60% 😎
```

### Productivity Gains
```
Time saved per day: ~2-3 hours
Code quality: Same or better
Learning curve: 1-2 days
ROI: Immediate
```

---

## 🔗 Resources

### Documentation
- Ollama Models Library: https://ollama.com/library
- Continue Docs: https://continue.dev/docs
- Qwen2.5-Coder: https://huggingface.co/Qwen
- StarCoder2: https://huggingface.co/bigcode/starcoder2

### Community
- Ollama Discord: https://discord.gg/ollama
- Continue Discord: https://discord.gg/continue
- Reddit: r/LocalLLaMA

### Tools
- GPU Monitor: `nvtop` (Linux), `nvidia-smi`
- Model Manager: Ollama CLI
- VSCode Extension: Continue

---

## 💡 Pro Tips

1. **Không cần download tất cả models ngay**
   - Start với: qwen2.5-coder:1.5b + qwen2.5-coder:3b + nomic-embed-text
   - Thêm dần khi cần

2. **Test từng model trước khi config Continue**
   ```bash
   ollama run qwen2.5-coder:1.5b "write hello world in go"
   ```

3. **Sử dụng @Code và @Codebase nhiều**
   - Model nhỏ cần context rõ ràng
   - Attach relevant files

4. **Combine local + cloud**
   - Local cho 90% tasks
   - Cloud cho 10% complex tasks
   - Best of both worlds!

5. **Monitor và adjust**
   - Track speed với `nvidia-smi`
   - Adjust config dựa trên usage
   - Optimize theo workflow cá nhân

---

**🎯 Tóm lại: Với setup này, bạn sẽ có autocomplete siêu nhanh, tiết kiệm VRAM, và vẫn giữ được quality tốt cho daily coding!**

*Last updated: 2025-10-21*